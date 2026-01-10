@preconcurrency import AVFoundation
import SwiftUI
@preconcurrency import Vision

/// Manages camera capture session and card detection
@MainActor
@Observable
final class CameraManager: NSObject, @unchecked Sendable {
    // MARK: - Camera Properties
    private let captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.cardshowpro.camera")
    private var currentCamera: AVCaptureDevice?

    // MARK: - State
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
        guard authorizationStatus == .authorized else { return }

        sessionQueue.sync {
            captureSession.beginConfiguration()
            captureSession.sessionPreset = .photo

            // Add video input
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                captureSession.commitConfiguration()
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    currentCamera = camera
                }
            } catch {
                print("Error setting up camera input: \(error)")
                captureSession.commitConfiguration()
                return
            }

            // Add video output
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]

            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }

            // Configure video connection
            if let connection = videoOutput.connection(with: .video) {
                if #available(iOS 17.0, *) {
                    connection.videoRotationAngle = 90
                } else {
                    connection.videoOrientation = .portrait
                }
            }

            captureSession.commitConfiguration()
        }

        // Create preview layer
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
    func capturePhoto() -> UIImage? {
        return lastCapturedImage
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
        // Convert sample buffer to image
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = UIImage(cgImage: cgImage)

        // Update last captured image on main thread
        Task { @MainActor in
            self.lastCapturedImage = image
        }

        // Perform card detection
        detectCard(in: imageBuffer)
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
