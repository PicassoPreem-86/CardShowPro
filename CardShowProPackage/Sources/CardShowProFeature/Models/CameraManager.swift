@preconcurrency import AVFoundation
import SwiftUI
@preconcurrency import Vision

/// Manages camera capture session and card detection
@MainActor
@Observable
final class CameraManager: NSObject, @unchecked Sendable {
    // MARK: - Camera Properties
    private nonisolated(unsafe) let captureSession = AVCaptureSession()
    private nonisolated(unsafe) var videoOutput = AVCaptureVideoDataOutput()
    private nonisolated(unsafe) var photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.cardshowpro.camera")
    private var currentCamera: AVCaptureDevice?

    // Photo capture state
    private var photoContinuation: CheckedContinuation<UIImage, Error>?

    // MARK: - Frame Throttling
    private let frameThrottler = FrameThrottler(fps: 15.0)

    // MARK: - State
    enum SessionState {
        case notConfigured
        case configuring
        case configured
        case running
        case failed(Error)
    }

    var sessionState: SessionState = .notConfigured
    var previewLayer: AVCaptureVideoPreviewLayer?
    var isSessionRunning = false
    var authorizationStatus: AVAuthorizationStatus = .notDetermined
    var detectedCardFrame: CGRect?
    var cardDetectionConfidence: Float = 0.0
    var isCardDetected: Bool = false
    var lastCapturedImage: UIImage?
    var isFlashOn = false

    // MARK: - Detection State
    enum DetectionState {
        case searching
        case cardFound
        case readyToCapture
        case capturing

        var message: String {
            switch self {
            case .searching: return "Position card in frame"
            case .cardFound: return "Hold steady..."
            case .readyToCapture: return "Perfect! Auto-scanning..."
            case .capturing: return "Captured!"
            }
        }

        var color: Color {
            switch self {
            case .searching: return .red
            case .cardFound: return .yellow
            case .readyToCapture: return .green
            case .capturing: return .blue
            }
        }
    }

    var detectionState: DetectionState = .searching

    // MARK: - Initialization
    override init() {
        super.init()
        checkAuthorization()
    }

    // MARK: - Authorization
    func checkAuthorization() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch authorizationStatus {
        case .authorized:
            Task { await setupCaptureSession() }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    self?.authorizationStatus = granted ? .authorized : .denied
                    if granted {
                        await self?.setupCaptureSession()
                    }
                }
            }
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Setup
    func setupCaptureSession() async {
        guard authorizationStatus == .authorized else {
            await MainActor.run {
                sessionState = .failed(NSError(domain: "CameraManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Camera not authorized"]))
            }
            return
        }

        await MainActor.run {
            sessionState = .configuring
        }

        // Run configuration on session queue
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }

                self.captureSession.beginConfiguration()
                self.captureSession.sessionPreset = .photo

                // Add video input
                guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                    self.captureSession.commitConfiguration()
                    Task { @MainActor in
                        self.sessionState = .failed(NSError(domain: "CameraManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Camera not available"]))
                    }
                    continuation.resume()
                    return
                }

                do {
                    let input = try AVCaptureDeviceInput(device: camera)
                    if self.captureSession.canAddInput(input) {
                        self.captureSession.addInput(input)
                        Task { @MainActor in
                            self.currentCamera = camera
                        }
                    }
                } catch {
                    print("Error setting up camera input: \(error)")
                    self.captureSession.commitConfiguration()
                    Task { @MainActor in
                        self.sessionState = .failed(error)
                    }
                    continuation.resume()
                    return
                }

                // Add video output
                self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]

                if self.captureSession.canAddOutput(self.videoOutput) {
                    self.captureSession.addOutput(self.videoOutput)
                }

                // Configure video connection
                if let connection = self.videoOutput.connection(with: .video) {
                    if #available(iOS 17.0, *) {
                        connection.videoRotationAngle = 90
                    } else {
                        connection.videoOrientation = .portrait
                    }
                }

                // Add photo output for high-quality capture
                if self.captureSession.canAddOutput(self.photoOutput) {
                    self.captureSession.addOutput(self.photoOutput)

                    // Configure photo output for highest quality
                    self.photoOutput.isHighResolutionCaptureEnabled = true
                    if #available(iOS 17.0, *) {
                        self.photoOutput.maxPhotoDimensions = camera.activeFormat.supportedMaxPhotoDimensions.first ?? CMVideoDimensions(width: 0, height: 0)
                    }
                }

                self.captureSession.commitConfiguration()

                // Configuration complete
                Task { @MainActor in
                    self.sessionState = .configured
                }

                continuation.resume()
            }
        }

        // Create preview layer on main thread
        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        previewLayer = preview
    }

    // MARK: - Session Control
    nonisolated func startSession() {
        Task { @MainActor in
            guard !self.isSessionRunning else { return }

            self.sessionQueue.async { [captureSession] in
                captureSession.startRunning()
                Task { @MainActor [weak self] in
                    self?.isSessionRunning = true
                    self?.sessionState = .running
                }
            }
        }
    }

    nonisolated func stopSession() {
        Task { @MainActor in
            guard self.isSessionRunning else { return }

            self.sessionQueue.async { [captureSession] in
                captureSession.stopRunning()
                Task { @MainActor [weak self] in
                    self?.isSessionRunning = false
                }
            }
        }
    }

    // MARK: - Manual Capture
    func capturePhoto() async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            // Store continuation for delegate callback
            photoContinuation = continuation

            // Create photo settings
            let settings = AVCapturePhotoSettings()

            // Use highest quality format available
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                settings.photoQualityPrioritization = .quality
            }

            // Disable flash for now (can be enabled later if needed)
            if photoOutput.supportedFlashModes.contains(.off) {
                settings.flashMode = .off
            }

            // Enable high-resolution capture
            settings.isHighResolutionPhotoEnabled = true

            // Capture photo on session queue
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: NSError(
                        domain: "CameraManager",
                        code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "CameraManager deallocated"]
                    ))
                    return
                }
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    // MARK: - Flash Control
    func toggleFlash() {
        guard let camera = currentCamera, camera.hasTorch else { return }

        do {
            try camera.lockForConfiguration()

            if camera.torchMode == .off {
                camera.torchMode = .on
                isFlashOn = true
            } else {
                camera.torchMode = .off
                isFlashOn = false
            }

            camera.unlockForConfiguration()
        } catch {
            print("Error toggling flash: \(error)")
        }
    }

    func setFlash(enabled: Bool) {
        guard let camera = currentCamera, camera.hasTorch else { return }

        do {
            try camera.lockForConfiguration()
            camera.torchMode = enabled ? .on : .off
            isFlashOn = enabled
            camera.unlockForConfiguration()
        } catch {
            print("Error setting flash: \(error)")
        }
    }

    var hasFlash: Bool {
        currentCamera?.hasTorch ?? false
    }
}

// MARK: - Video Output Delegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Throttle to 15 FPS to reduce CPU usage
        Task {
            guard await frameThrottler.shouldProcess() else { return }

            // Convert sample buffer to image
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let context = CIContext()

            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
            let image = UIImage(cgImage: cgImage)

            // Update last captured image on main thread
            await MainActor.run {
                self.lastCapturedImage = image
            }

            // Perform card detection
            detectCard(in: imageBuffer)
        }
    }

    // MARK: - Card Detection with Vision
    private nonisolated func detectCard(in pixelBuffer: CVPixelBuffer) {
        let request = VNDetectRectanglesRequest { request, error in
            guard let results = request.results as? [VNRectangleObservation],
                  let firstRect = results.first else {
                DispatchQueue.main.async {
                    self.isCardDetected = false
                    self.detectionState = .searching
                    self.detectedCardFrame = nil
                }
                return
            }

            // Convert normalized coordinates to screen coordinates
            let boundingBox = firstRect.boundingBox
            let confidence = firstRect.confidence

            DispatchQueue.main.async {
                self.cardDetectionConfidence = confidence
                self.isCardDetected = confidence > 0.6
                self.detectedCardFrame = boundingBox

                // Update detection state based on confidence
                if confidence > 0.85 {
                    self.detectionState = .readyToCapture
                } else if confidence > 0.6 {
                    self.detectionState = .cardFound
                } else {
                    self.detectionState = .searching
                }
            }
        }

        // Configure rectangle detection for trading cards
        request.minimumAspectRatio = 0.5  // Cards are roughly 2.5:3.5 ratio
        request.maximumAspectRatio = 0.8
        request.minimumSize = 0.2  // Card should take up at least 20% of frame
        request.maximumObservations = 1

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}

// MARK: - Photo Capture Delegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        // Handle errors
        if let error = error {
            Task { @MainActor in
                self.photoContinuation?.resume(throwing: error)
                self.photoContinuation = nil
            }
            return
        }

        // Extract image data
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            Task { @MainActor in
                self.photoContinuation?.resume(throwing: NSError(
                    domain: "CameraManager",
                    code: -4,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to convert photo to UIImage"]
                ))
                self.photoContinuation = nil
            }
            return
        }

        // Correct orientation
        let orientedImage = image.fixedOrientation()

        // Resume continuation with captured image
        Task { @MainActor in
            self.photoContinuation?.resume(returning: orientedImage)
            self.photoContinuation = nil
        }
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        // Photo was captured, can add sound/haptic feedback here if needed
    }
}

// MARK: - UIImage Orientation Fix
private extension UIImage {
    func fixedOrientation() -> UIImage {
        // If image is already in correct orientation, return it
        guard imageOrientation != .up else { return self }

        // Create graphics context and draw image with correct orientation
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()

        return normalizedImage
    }
}
