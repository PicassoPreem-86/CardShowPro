@preconcurrency import AVFoundation
import SwiftUI

/// Simplified camera manager for manual photo capture only.
/// No auto-detection, no frame processing - just camera preview and high-quality photo capture.
@MainActor
@Observable
final class CameraManager: NSObject, @unchecked Sendable {
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
        print("🎥 DEBUG: Starting setupCaptureSession")
        print("🎥 DEBUG: Authorization status: \(authorizationStatus)")

        guard authorizationStatus == .authorized else {
            print("❌ DEBUG: Authorization not granted - status: \(authorizationStatus)")
            await MainActor.run {
                sessionState = .failed(NSError(domain: "CameraManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Camera not authorized"]))
            }
            return
        }

        print("✅ DEBUG: Authorization granted, proceeding with setup")
        await MainActor.run {
            sessionState = .configuring
        }
        print("🎥 DEBUG: Session state set to .configuring")

        // Run configuration on session queue
        print("🎥 DEBUG: Entering session queue for configuration")
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                print("🎥 DEBUG: Inside sessionQueue.async")
                guard let self = self else {
                    print("❌ DEBUG: self is nil in sessionQueue")
                    continuation.resume()
                    return
                }

                print("🎥 DEBUG: Beginning session configuration")
                self.captureSession.beginConfiguration()
                self.captureSession.sessionPreset = .photo

                // Add video input
                print("🎥 DEBUG: Looking for back camera device...")
                guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                    print("❌ DEBUG: Back camera NOT found!")
                    self.captureSession.commitConfiguration()
                    Task { @MainActor in
                        self.sessionState = .failed(NSError(domain: "CameraManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Camera not available"]))
                    }
                    continuation.resume()
                    return
                }
                print("✅ DEBUG: Back camera found: \(camera.localizedName)")

                do {
                    print("🎥 DEBUG: Creating AVCaptureDeviceInput...")
                    let input = try AVCaptureDeviceInput(device: camera)
                    print("✅ DEBUG: AVCaptureDeviceInput created")

                    if self.captureSession.canAddInput(input) {
                        print("🎥 DEBUG: Adding video input to session...")
                        self.captureSession.addInput(input)
                        print("✅ DEBUG: Video input added successfully")
                        Task { @MainActor in
                            self.currentCamera = camera
                        }
                    } else {
                        print("❌ DEBUG: canAddInput returned false - session cannot accept input")
                    }
                } catch {
                    print("❌ DEBUG: Error creating camera input: \(error.localizedDescription)")
                    self.captureSession.commitConfiguration()
                    Task { @MainActor in
                        self.sessionState = .failed(error)
                    }
                    continuation.resume()
                    return
                }

                // Add photo output for high-quality capture
                print("🎥 DEBUG: Adding photo output...")
                if self.captureSession.canAddOutput(self.photoOutput) {
                    self.captureSession.addOutput(self.photoOutput)
                    print("✅ DEBUG: Photo output added successfully")

                    // Configure photo output for highest quality
                    self.photoOutput.isHighResolutionCaptureEnabled = true
                    if #available(iOS 17.0, *) {
                        self.photoOutput.maxPhotoDimensions = camera.activeFormat.supportedMaxPhotoDimensions.first ?? CMVideoDimensions(width: 0, height: 0)
                    }
                    print("🎥 DEBUG: Photo output configured for high resolution")
                } else {
                    print("❌ DEBUG: canAddOutput returned false - cannot add photo output")
                }

                print("🎥 DEBUG: Committing session configuration...")
                self.captureSession.commitConfiguration()
                print("✅ DEBUG: Session configuration committed")

                // Configuration complete
                Task { @MainActor in
                    self.sessionState = .configured
                    print("🎥 DEBUG: Session state set to .configured")
                }

                continuation.resume()
                print("🎥 DEBUG: Continuation resumed - exiting sessionQueue")
            }
        }

        // Create preview layer on main thread
        print("🎥 DEBUG: Creating AVCaptureVideoPreviewLayer...")
        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        print("🎥 DEBUG: Preview layer created with videoGravity: \(preview.videoGravity)")
        print("🎥 DEBUG: Assigning preview layer to self.previewLayer...")
        previewLayer = preview
        print("✅ DEBUG: Preview layer assigned! previewLayer = \(String(describing: previewLayer))")
        print("🎥 DEBUG: setupCaptureSession() complete")
    }

    // MARK: - Session Control
    nonisolated func startSession() {
        Task { @MainActor in
            print("🎥 DEBUG: startSession() called")
            guard !self.isSessionRunning else {
                print("⚠️ DEBUG: Session already running, skipping")
                return
            }

            print("🎥 DEBUG: Dispatching captureSession.startRunning() to sessionQueue...")
            self.sessionQueue.async { [captureSession] in
                print("🎥 DEBUG: Inside sessionQueue - calling startRunning()...")
                captureSession.startRunning()
                print("🎥 DEBUG: startRunning() called")
                print("🎥 DEBUG: Session isRunning: \(captureSession.isRunning)")

                Task { @MainActor [weak self] in
                    guard let self = self else {
                        print("❌ DEBUG: self is nil when setting isSessionRunning")
                        return
                    }
                    self.isSessionRunning = true
                    self.sessionState = .running
                    print("✅ DEBUG: Session state set to .running, isSessionRunning = true")
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
                    print("Error toggling flash: \(error)")
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
                    print("Error setting flash: \(error)")
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
