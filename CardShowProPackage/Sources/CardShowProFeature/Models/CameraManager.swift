@preconcurrency import AVFoundation
import SwiftUI
import OSLog

/// Simplified camera manager for manual photo capture only.
/// No auto-detection, no frame processing - just camera preview and high-quality photo capture.
@MainActor
@Observable
final class CameraManager: NSObject, @unchecked Sendable {
    // MARK: - Logging
    private let logger = Logger(subsystem: "com.cardshowpro.camera", category: "CameraManager")

    // MARK: - Camera Properties
    private nonisolated(unsafe) let captureSession = AVCaptureSession()
    private nonisolated(unsafe) var photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.cardshowpro.camera")
    private var currentCamera: AVCaptureDevice?

    // Photo capture state
    private var photoContinuation: CheckedContinuation<UIImage, Error>?

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
    var isFlashOn = false

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
        logger.debug("Starting setupCaptureSession")
        logger.debug("Authorization status: \(String(describing: self.authorizationStatus))")

        guard authorizationStatus == .authorized else {
            logger.error("Authorization not granted - status: \(String(describing: self.authorizationStatus))")
            await MainActor.run {
                sessionState = .failed(NSError(domain: "CameraManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Camera not authorized"]))
            }
            return
        }

        logger.info("Authorization granted, proceeding with setup")
        await MainActor.run {
            sessionState = .configuring
        }
        logger.debug("Session state set to .configuring")

        // Run configuration on session queue
        logger.debug("Entering session queue for configuration")
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }

                Task { @MainActor in
                    self.logger.debug("Inside sessionQueue.async")
                    self.logger.debug("Beginning session configuration")
                }

                self.captureSession.beginConfiguration()
                self.captureSession.sessionPreset = .photo

                // Add video input
                Task { @MainActor in
                    self.logger.debug("Looking for back camera device...")
                }
                guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                    Task { @MainActor in
                        self.logger.error("Back camera NOT found!")
                    }
                    self.captureSession.commitConfiguration()
                    Task { @MainActor in
                        self.sessionState = .failed(NSError(domain: "CameraManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Camera not available"]))
                    }
                    continuation.resume()
                    return
                }
                Task { @MainActor in
                    self.logger.info("Back camera found: \(camera.localizedName)")
                }

                do {
                    Task { @MainActor in
                        self.logger.debug("Creating AVCaptureDeviceInput...")
                    }
                    let input = try AVCaptureDeviceInput(device: camera)
                    Task { @MainActor in
                        self.logger.info("AVCaptureDeviceInput created")
                    }

                    if self.captureSession.canAddInput(input) {
                        Task { @MainActor in
                            self.logger.debug("Adding video input to session...")
                        }
                        self.captureSession.addInput(input)
                        Task { @MainActor in
                            self.logger.info("Video input added successfully")
                            self.currentCamera = camera
                        }
                    } else {
                        Task { @MainActor in
                            self.logger.error("canAddInput returned false - session cannot accept input")
                        }
                    }
                } catch {
                    Task { @MainActor in
                        self.logger.error("Error creating camera input: \(error.localizedDescription)")
                    }
                    self.captureSession.commitConfiguration()
                    Task { @MainActor in
                        self.sessionState = .failed(error)
                    }
                    continuation.resume()
                    return
                }

                // Add photo output for high-quality capture
                Task { @MainActor in
                    self.logger.debug("Adding photo output...")
                }
                if self.captureSession.canAddOutput(self.photoOutput) {
                    self.captureSession.addOutput(self.photoOutput)
                    Task { @MainActor in
                        self.logger.info("Photo output added successfully")
                    }

                    // Configure photo output for highest quality
                    self.photoOutput.isHighResolutionCaptureEnabled = true
                    if #available(iOS 17.0, *) {
                        self.photoOutput.maxPhotoDimensions = camera.activeFormat.supportedMaxPhotoDimensions.first ?? CMVideoDimensions(width: 0, height: 0)
                    }
                    Task { @MainActor in
                        self.logger.debug("Photo output configured for high resolution")
                    }
                } else {
                    Task { @MainActor in
                        self.logger.error("canAddOutput returned false - cannot add photo output")
                    }
                }

                Task { @MainActor in
                    self.logger.debug("Committing session configuration...")
                }
                self.captureSession.commitConfiguration()
                Task { @MainActor in
                    self.logger.info("Session configuration committed")
                }

                // Configuration complete
                Task { @MainActor in
                    self.sessionState = .configured
                    self.logger.debug("Session state set to .configured")
                }

                continuation.resume()
                Task { @MainActor in
                    self.logger.debug("Continuation resumed - exiting sessionQueue")
                }
            }
        }

        // Create preview layer on main thread
        logger.debug("Creating AVCaptureVideoPreviewLayer...")
        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        logger.debug("Preview layer created with videoGravity: \(String(describing: preview.videoGravity))")
        logger.debug("Assigning preview layer to self.previewLayer...")
        previewLayer = preview
        logger.info("Preview layer assigned! previewLayer = \(String(describing: self.previewLayer))")
        logger.debug("setupCaptureSession() complete")
    }

    // MARK: - Session Control
    nonisolated func startSession() {
        Task { @MainActor in
            self.logger.debug("startSession() called")
            guard !self.isSessionRunning else {
                self.logger.warning("Session already running, skipping")
                return
            }

            self.logger.debug("Dispatching captureSession.startRunning() to sessionQueue...")
            self.sessionQueue.async { [captureSession, logger] in
                Task { @MainActor in
                    logger.debug("Inside sessionQueue - calling startRunning()...")
                }
                captureSession.startRunning()
                Task { @MainActor in
                    logger.debug("startRunning() called")
                    logger.debug("Session isRunning: \(captureSession.isRunning)")
                }

                Task { @MainActor [weak self] in
                    guard let self = self else {
                        logger.error("self is nil when setting isSessionRunning")
                        return
                    }
                    self.isSessionRunning = true
                    self.sessionState = .running
                    self.logger.info("Session state set to .running, isSessionRunning = true")
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
                // Respect device's max quality prioritization to avoid crash
                // QualityPrioritization raw values: balanced=0, speed=1, quality=2
                let desiredQuality: AVCapturePhotoOutput.QualityPrioritization = .quality
                let maxSupported = photoOutput.maxPhotoQualityPrioritization

                if desiredQuality.rawValue <= maxSupported.rawValue {
                    settings.photoQualityPrioritization = desiredQuality
                } else {
                    settings.photoQualityPrioritization = maxSupported
                }
            }

            // Configure flash based on isFlashOn state
            if photoOutput.supportedFlashModes.contains(isFlashOn ? .on : .off) {
                settings.flashMode = isFlashOn ? .on : .off
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
    nonisolated func toggleFlash() {
        Task { @MainActor in
            guard let camera = self.currentCamera, camera.hasTorch else { return }

            // Run camera configuration on background queue to avoid blocking UI
            self.sessionQueue.async {
                do {
                    try camera.lockForConfiguration()

                    if camera.torchMode == .off {
                        camera.torchMode = .on
                        Task { @MainActor [weak self] in
                            self?.isFlashOn = true
                        }
                    } else {
                        camera.torchMode = .off
                        Task { @MainActor [weak self] in
                            self?.isFlashOn = false
                        }
                    }

                    camera.unlockForConfiguration()
                } catch {
                    Task { @MainActor [weak self] in
                        self?.logger.error("Error toggling flash: \(error)")
                    }
                }
            }
        }
    }

    nonisolated func setFlash(enabled: Bool) {
        Task { @MainActor in
            guard let camera = self.currentCamera, camera.hasTorch else { return }

            // Run camera configuration on background queue to avoid blocking UI
            self.sessionQueue.async {
                do {
                    try camera.lockForConfiguration()
                    camera.torchMode = enabled ? .on : .off
                    Task { @MainActor [weak self] in
                        self?.isFlashOn = enabled
                    }
                    camera.unlockForConfiguration()
                } catch {
                    Task { @MainActor [weak self] in
                        self?.logger.error("Error setting flash: \(error)")
                    }
                }
            }
        }
    }

    var hasFlash: Bool {
        currentCamera?.hasTorch ?? false
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
