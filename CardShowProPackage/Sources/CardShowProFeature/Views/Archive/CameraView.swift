import SwiftUI
import SwiftData
import AVFoundation
import PhotosUI

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var cameraManager = CameraManager()
    @State private var scanSession = ScanSession()
    @State private var selectedMode: ScanMode = .negotiator
    @State private var selectedGame: CardGame = .pokemon

    // Card recognition services
    @State private var recognitionService = CardRecognitionService.shared
    @State private var pricingService = PricingService.shared

    // Confirmation view state
    @State private var showConfirmation = false
    @State private var pendingCardImage: UIImage?
    @State private var pendingRecognition: RecognitionResult?
    @State private var pendingPricing: CardPricing?

    // Photo picker state
    @State private var selectedPhotoItem: PhotosPickerItem?

    // Loading state
    @State private var isInitializing = true
    @State private var isRecognizing = false
    @State private var loadingStatus = "Recognizing card..."

    // Success state
    @State private var showSuccessAnimation = false
    @State private var showSessionSuccess = false

    // Tutorial state
    @State private var showTutorial = false
    @State private var pulseButton = false

    // Error state
    @State private var showErrorOverlay = false
    @State private var errorType: CameraError?
    @State private var showCameraPermissionAlert = false

    enum CameraError {
        case cardNotFound
        case cameraFailed
    }

    var body: some View {
        ZStack {
            // MARK: - Camera Feed
            if let previewLayer = cameraManager.previewLayer {
                let _ = print("✅ DEBUG [CameraView]: Preview layer exists, rendering CameraPreviewView")
                CameraPreviewView(previewLayer: previewLayer)
                    .ignoresSafeArea()
            } else if case .failed = cameraManager.sessionState {
                let _ = print("❌ DEBUG [CameraView]: Session state is .failed, showing error UI")
                // Camera setup failed - show error with retry
                Color.black
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.yellow)

                            Text("Camera Setup Failed")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text("Please check permissions in Settings")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))

                            Button {
                                Task {
                                    await setupCamera()
                                }
                            } label: {
                                Text("Retry")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                    }
            } else {
                let _ = print("⚠️ DEBUG [CameraView]: Preview layer is NIL, showing placeholder. Session state: \(cameraManager.sessionState)")
                // Placeholder for simulator or no camera access
                Color.black
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 16) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.6))
                            Text("Camera not available")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.8))
                            Text("Testing on device required")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            Text("State: \(String(describing: cameraManager.sessionState))")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
            }

            // MARK: - Main UI Overlay
            VStack(spacing: 0) {
                // Top Bar
                topBar

                Spacer()

                // Instruction Text
                if scanSession.cardCount == 0 {
                    instructionText
                        .padding(.bottom, 20)
                }

                // Bottom Panel
                bottomPanel
            }

            // MARK: - Close and Flash Buttons
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(DesignSystem.Typography.heading4)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(DesignSystem.Spacing.md)

                    Spacer()

                    // Flash Toggle
                    if cameraManager.hasFlash {
                        Button {
                            cameraManager.toggleFlash()
                            HapticManager.shared.light()
                        } label: {
                            Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(DesignSystem.Typography.heading4)
                                .fontWeight(.semibold)
                                .foregroundStyle(cameraManager.isFlashOn ? DesignSystem.Colors.thunderYellow : DesignSystem.Colors.textPrimary)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(DesignSystem.Spacing.md)
                    }
                }
                Spacer()
            }

            // MARK: - Initialization Loading
            if isInitializing {
                CleanLoadingView(status: "Initializing camera...")
                    .transition(.opacity)
            }

            // MARK: - Recognition Loading
            if isRecognizing {
                CleanLoadingView(status: loadingStatus)
                    .transition(.opacity)
            }

            // MARK: - Success Animation
            if showSuccessAnimation {
                QuickSuccessFeedback {
                    handleSuccessAnimationComplete()
                }
                .transition(.opacity)
            }

            // MARK: - Error Overlay
            if showErrorOverlay, let errorType = errorType {
                SimpleErrorModal(
                    errorType: mapToSimpleErrorType(errorType),
                    onPrimaryAction: {
                        handleErrorDismiss()
                    },
                    onSecondaryAction: nil
                )
                .transition(.opacity)
            }

            // MARK: - Tutorial Overlay
            if showTutorial {
                CleanTutorialOverlay {
                    dismissTutorial()
                }
                .transition(.opacity)
            }
        }
        .statusBarHidden()
        .toolbar(.hidden, for: .tabBar)
        .task {
            await setupCamera()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .sheet(isPresented: $showConfirmation, onDismiss: {
            // Defensive state reset when sheet dismisses
            isRecognizing = false
            showSuccessAnimation = false
            scanSession.isProcessing = false
        }) {
            if let cardImage = pendingCardImage,
               let recognition = pendingRecognition {
                CardConfirmationView(
                    cardImage: cardImage,
                    recognitionResult: recognition,
                    pricing: pendingPricing,
                    onConfirm: { confirmedRecognition, confirmedPricing in
                        saveConfirmedCard(recognition: confirmedRecognition, pricing: confirmedPricing, image: cardImage)
                    },
                    onRescan: {
                        // Reset all pending and loading state for rescan
                        pendingCardImage = nil
                        pendingRecognition = nil
                        pendingPricing = nil
                        isRecognizing = false
                        showSuccessAnimation = false
                        scanSession.isProcessing = false
                    }
                )
            }
        }
        .sheet(isPresented: $showSessionSuccess) {
            ScanSessionSuccessView(
                cardCount: scanSession.cardCount,
                totalValue: scanSession.totalValue
            ) {
                showSessionSuccess = false
                dismiss()
            }
        }
        .alert("Camera Access Required", isPresented: $showCameraPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("CardShowPro needs camera access to scan cards. Please enable it in Settings.")
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 20)

            HStack {
                // Game Selector (left side)
                Menu {
                    ForEach(CardGame.supported, id: \.self) { game in
                        Button {
                            selectedGame = game
                            HapticManager.shared.light()
                        } label: {
                            Label(game.displayName, systemImage: game.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: selectedGame.icon)
                            .font(.headline)
                        Text(selectedGame.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                }

                Spacer()

                // Mode Picker (right side)
                Menu {
                    ForEach(ScanMode.allCases, id: \.self) { mode in
                        Button {
                            selectedMode = mode
                            HapticManager.shared.light()
                        } label: {
                            Label(mode.title, systemImage: mode.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: selectedMode.icon)
                            .font(.headline)
                        Text(selectedMode.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.5), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Instruction Text
    private var instructionText: some View {
        Text("Position card in frame, then tap to capture")
            .font(DesignSystem.Typography.body)
            .foregroundStyle(DesignSystem.Colors.textPrimary.opacity(0.9))
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(Color.black.opacity(0.5))
            .clipShape(Capsule())
    }

    // MARK: - Bottom Panel
    private var bottomPanel: some View {
        VStack(spacing: 0) {
            if scanSession.cardCount > 0 {
                scannedCardsCarousel
                    .padding(.top, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Action Bar
            HStack(spacing: 40) {
                // Gallery Button
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        await loadSelectedPhoto(newItem)
                    }
                }

                // Capture Button (Manual Only)
                Button {
                    manualCapture()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 68, height: 68)
                    }
                }
                .scaleEffect(pulseButton ? 1.15 : 1.0)
                .disabled(scanSession.isProcessing)

                // Done Button
                Button {
                    finishSession()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(scanSession.cardCount > 0 ? .green : .white.opacity(0.5))
                        .frame(width: 44, height: 44)
                        .background(scanSession.cardCount > 0 ? Color.white : Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .disabled(scanSession.cardCount == 0)
            }
            .padding(.vertical, 20)
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Scanned Cards Carousel
    private var scannedCardsCarousel: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Scanned: \(scanSession.cardCount) cards")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(scanSession.scannedCards) { card in
                        ScannedCardThumbnail(card: card) {
                            scanSession.removeCard(card)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            .frame(height: 100)

            // Total Value with design system
            HStack {
                Text("Total Value:")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Spacer()
                Text("$\(String(format: "%.2f", scanSession.totalValue))")
                    .font(DesignSystem.Typography.heading3)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.cyan)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.xxxs)
        }
        .padding(.bottom, DesignSystem.Spacing.sm)
        .background(Color.black.opacity(0.4))
    }

    // MARK: - Actions
    private func setupCamera() async {
        print("📱 DEBUG [CameraView]: setupCamera() called")
        // Prepare haptic generators
        HapticManager.shared.prepare()

        // Check camera permission
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("📱 DEBUG [CameraView]: Camera authorization status: \(status)")

        switch status {
        case .authorized:
            print("📱 DEBUG [CameraView]: Camera authorized, configuring...")
            await configureAndStartCamera()
        case .notDetermined:
            print("📱 DEBUG [CameraView]: Camera permission not determined, requesting...")
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            print("📱 DEBUG [CameraView]: Permission granted: \(granted)")
            if granted {
                await configureAndStartCamera()
            } else {
                showCameraPermissionAlert = true
                HapticManager.shared.error()
            }
        case .denied, .restricted:
            print("❌ DEBUG [CameraView]: Camera permission denied or restricted")
            showCameraPermissionAlert = true
            HapticManager.shared.error()
        @unknown default:
            print("❌ DEBUG [CameraView]: Unknown camera permission status")
            showCameraPermissionAlert = true
            HapticManager.shared.error()
        }
    }

    private func configureAndStartCamera() async {
        print("📱 DEBUG [CameraView]: configureAndStartCamera() called")
        print("📱 DEBUG [CameraView]: Calling cameraManager.setupCaptureSession()...")
        await cameraManager.setupCaptureSession()
        print("📱 DEBUG [CameraView]: setupCaptureSession() returned")

        // Wait for preview layer to be created (with timeout)
        var attempts = 0
        print("📱 DEBUG [CameraView]: Waiting for preview layer creation...")
        while cameraManager.previewLayer == nil && attempts < 20 {
            print("📱 DEBUG [CameraView]: Attempt \(attempts + 1)/20 - preview layer still nil")
            try? await Task.sleep(for: .milliseconds(100))
            attempts += 1
        }

        // Only start session if preview layer exists
        guard cameraManager.previewLayer != nil else {
            print("❌ DEBUG [CameraView]: Preview layer is STILL NIL after \(attempts) attempts - giving up")
            print("❌ DEBUG [CameraView]: Session state: \(cameraManager.sessionState)")
            // Camera setup failed - hide loading
            withAnimation(.easeOut(duration: 0.3)) {
                isInitializing = false
            }
            return
        }

        print("✅ DEBUG [CameraView]: Preview layer created successfully after \(attempts) attempts")
        print("📱 DEBUG [CameraView]: Calling cameraManager.startSession()...")
        cameraManager.startSession()

        // Wait briefly for camera to stabilize
        try? await Task.sleep(for: .milliseconds(300))
        print("📱 DEBUG [CameraView]: Camera stabilization delay complete")

        // Hide initialization loading
        withAnimation(.easeOut(duration: 0.3)) {
            isInitializing = false
        }
        print("✅ DEBUG [CameraView]: Initialization loading hidden")

        // Haptic: Camera ready
        HapticManager.shared.light()

        // Check if tutorial should be shown
        let hasSeenTutorial = UserDefaults.standard.bool(forKey: "hasSeenCameraTutorial")
        if !hasSeenTutorial {
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(.easeIn(duration: 0.3)) {
                showTutorial = true
            }
        }
    }

    private func manualCapture() {
        performCapture()
    }

    private func performCapture() {
        scanSession.isProcessing = true

        // Haptic: Capture (light for minimal feedback)
        HapticManager.shared.light()

        // Perform card recognition with real API
        Task {
            do {
                // Show loading overlay
                isRecognizing = true
                loadingStatus = "Capturing photo..."

                // Step 1: Capture high-quality photo
                let image = try await cameraManager.capturePhoto()

                // Update loading status
                loadingStatus = "Recognizing card..."

                // Step 2: Recognize card from image
                let recognition = try await recognitionService.recognizeCard(from: image, game: selectedGame)

                // Update loading status
                loadingStatus = "Fetching prices..."

                // Step 3: Fetch pricing (in parallel with showing confirmation)
                async let pricing = try? await pricingService.fetchPricing(
                    cardName: recognition.cardName,
                    setName: recognition.setName,
                    cardNumber: recognition.cardNumber
                )

                // Hide loading overlay
                isRecognizing = false

                // Step 4: Show success animation
                withAnimation {
                    showSuccessAnimation = true
                }

                // Store pending data for confirmation
                pendingCardImage = image
                pendingRecognition = recognition
                pendingPricing = await pricing

                scanSession.isProcessing = false
            } catch {
                // Handle capture or recognition error
                print("Capture/Recognition error: \(error.localizedDescription)")

                // Hide loading
                isRecognizing = false

                // Show error overlay
                errorType = .cardNotFound
                withAnimation {
                    showErrorOverlay = true
                }

                // Haptic: Error
                HapticManager.shared.error()

                scanSession.isProcessing = false
            }
        }
    }

    private func saveConfirmedCard(recognition: RecognitionResult, pricing: CardPricing?, image: UIImage) {
        // Create scanned card for session
        let scannedCard = ScannedCard(
            image: image,
            cardName: recognition.cardName,
            cardNumber: recognition.cardNumber,
            setName: recognition.setName,
            estimatedValue: pricing?.estimatedValue ?? 0.0,
            confidence: recognition.confidence
        )

        // Add to scan session (temporary)
        scanSession.addCard(scannedCard)

        // Save to SwiftData for persistence
        let inventoryCard = InventoryCard(from: scannedCard)
        modelContext.insert(inventoryCard)

        // Save context
        do {
            try modelContext.save()
        } catch {
            print("Error saving card: \(error)")
        }

        // Haptic: Card saved
        HapticManager.shared.success()
    }

    private func handleSuccessAnimationComplete() {
        // Hide success animation
        withAnimation {
            showSuccessAnimation = false
        }

        // Show confirmation sheet after success animation
        showConfirmation = true
    }

    private func handleErrorDismiss() {
        withAnimation {
            showErrorOverlay = false
        }
        errorType = nil
    }

    private func dismissTutorial() {
        UserDefaults.standard.set(true, forKey: "hasSeenCameraTutorial")

        withAnimation(.easeOut(duration: 0.3)) {
            showTutorial = false
        }

        // Pulse button 3 times
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            await pulseButtonThreeTimes()
        }
    }

    private func pulseButtonThreeTimes() async {
        for _ in 0..<3 {
            withAnimation(.easeInOut(duration: 0.5)) {
                pulseButton = true
            }
            HapticManager.shared.light()

            try? await Task.sleep(for: .seconds(0.5))

            withAnimation(.easeInOut(duration: 0.5)) {
                pulseButton = false
            }

            try? await Task.sleep(for: .seconds(0.5))
        }
    }

    private func mapToSimpleErrorType(_ error: CameraError) -> SimpleErrorModal.ErrorType {
        switch error {
        case .cardNotFound:
            return .cardNotFound
        case .cameraFailed:
            return .cardNotFound // Use cardNotFound as fallback for camera errors
        }
    }

    private func finishSession() {
        // Show success message if cards were scanned
        if scanSession.cardCount > 0 {
            showSessionSuccess = true
        } else {
            dismiss()
        }
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                return
            }

            // Process the selected image through recognition
            await processImageFromGallery(image)
        } catch {
            print("Error loading photo: \(error)")
        }

        // Reset selection
        selectedPhotoItem = nil
    }

    private func processImageFromGallery(_ image: UIImage) async {
        scanSession.isProcessing = true
        isRecognizing = true
        loadingStatus = "Recognizing card..."

        do {
            // Recognize card from gallery image
            let recognition = try await recognitionService.recognizeCard(from: image, game: selectedGame)

            loadingStatus = "Fetching prices..."

            // Fetch pricing
            async let pricing = try? await pricingService.fetchPricing(
                cardName: recognition.cardName,
                setName: recognition.setName,
                cardNumber: recognition.cardNumber
            )

            // Hide loading
            isRecognizing = false

            // Show confirmation
            pendingCardImage = image
            pendingRecognition = recognition
            pendingPricing = await pricing
            showConfirmation = true

            scanSession.isProcessing = false
        } catch {
            print("Recognition error from gallery: \(error.localizedDescription)")

            // Fall back to manual entry
            let fallbackRecognition = RecognitionResult(
                cardName: "Unknown Card",
                setName: "Unknown Set",
                cardNumber: "???",
                confidence: 0.0,
                game: selectedGame,
                rarity: nil,
                cardType: nil,
                subtype: nil,
                supertype: nil
            )

            pendingCardImage = image
            pendingRecognition = fallbackRecognition
            pendingPricing = nil
            showConfirmation = true

            scanSession.isProcessing = false
            isRecognizing = false
        }
    }
}

// MARK: - Scan Modes
enum ScanMode: String, CaseIterable {
    case negotiator
    case inventory
    case sell

    var title: String {
        switch self {
        case .negotiator: return "Negotiator"
        case .inventory: return "Add to Inventory"
        case .sell: return "Sell"
        }
    }

    var icon: String {
        switch self {
        case .negotiator: return "magnifyingglass.circle.fill"
        case .inventory: return "square.stack.3d.up.fill"
        case .sell: return "dollarsign.circle.fill"
        }
    }
}

// MARK: - Scanned Card Thumbnail
struct ScannedCardThumbnail: View {
    let card: ScannedCard
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            ZStack(alignment: .topTrailing) {
                // Card Image
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(width: 70, height: 70)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }

                // Delete button
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .background(Circle().fill(DesignSystem.Colors.error))
                }
                .offset(x: 6, y: -6)
            }

            // Card info
            VStack(spacing: DesignSystem.Spacing.xxxs) {
                Text("$\(String(format: "%.0f", card.estimatedValue))")
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.cyan)

                Text(card.cardName)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
    }
}
