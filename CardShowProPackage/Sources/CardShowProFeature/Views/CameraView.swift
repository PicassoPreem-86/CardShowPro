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
    @State private var showSettings = false
    @State private var autoCapture = true

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
    @State private var showPhotoPicker = false

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

    // Auto-capture state tracking
    @State private var stableDetectionCount = 0
    private let requiredStableFrames = 10 // At 15 FPS = ~0.67s

    // Low light detection
    @State private var lowConfidenceCount = 0
    private let lowConfidenceThreshold = 100 // ~6.6s at 15 FPS

    enum CameraError {
        case cardNotFound
        case lowLight
        case cameraFailed
    }

    var body: some View {
        ZStack {
            // MARK: - Camera Feed
            if let previewLayer = cameraManager.previewLayer {
                CameraPreviewView(previewLayer: previewLayer)
                    .ignoresSafeArea()
            } else {
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
                        }
                    }
            }

            // MARK: - Detection Overlay
            GeometryReader { geometry in
                MinimalDetectionFrame(
                    state: detectionFrameState,
                    geometrySize: geometry.size
                )
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // MARK: - Main UI Overlay
            VStack(spacing: 0) {
                // Top Bar
                topBar

                Spacer()

                // Instruction Text
                if !cameraManager.isCardDetected || scanSession.cardCount == 0 {
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
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
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
                    onSecondaryAction: shouldShowSecondaryAction(for: errorType) ? {
                        handleSecondaryAction(for: errorType)
                    } : nil
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
        .task {
            await setupCamera()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .sheet(isPresented: $showSettings) {
            settingsSheet
        }
        .sheet(isPresented: $showConfirmation, onDismiss: {
            // Defensive state reset when sheet dismisses (covers any edge cases)
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
                        cameraManager.detectionState = .searching
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
        .onChange(of: cameraManager.detectionState) { _, newState in
            handleDetectionStateChange(newState)
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
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
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
        VStack(spacing: DesignSystem.Spacing.xs) {
            if cameraManager.isCardDetected {
                Text(cameraManager.detectionState.message)
                    .font(DesignSystem.Typography.heading4)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(cameraManager.detectionState.color.opacity(0.9))
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text("Position card in frame")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary.opacity(0.9))
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
            }
        }
        .animation(DesignSystem.Animation.springSmooth, value: cameraManager.isCardDetected)
        .animation(DesignSystem.Animation.springSmooth, value: cameraManager.detectionState)
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

                // Settings Button
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }

                // Capture Button
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

    // MARK: - Settings Sheet
    private var settingsSheet: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Auto-Capture", isOn: $autoCapture)
                        .tint(.blue)
                } header: {
                    Text("Capture Settings")
                }

                Section {
                    Text("Flash: Auto")
                    Text("Resolution: High")
                } header: {
                    Text("Camera Settings")
                }
            }
            .navigationTitle("Scan Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showSettings = false
                    }
                }
            }
        }
    }

    // MARK: - Actions
    private func setupCamera() async {
        // Prepare haptic generators
        HapticManager.shared.prepare()

        // Check camera permission
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            await configureAndStartCamera()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                await configureAndStartCamera()
            } else {
                showCameraPermissionAlert = true
                HapticManager.shared.error()
            }
        case .denied, .restricted:
            showCameraPermissionAlert = true
            HapticManager.shared.error()
        @unknown default:
            showCameraPermissionAlert = true
            HapticManager.shared.error()
        }
    }

    private func configureAndStartCamera() async {
        await cameraManager.setupCaptureSession()
        cameraManager.startSession()

        // Wait for camera to be ready
        try? await Task.sleep(for: .seconds(0.5))

        // Hide initialization loading
        withAnimation(.easeOut(duration: 0.3)) {
            isInitializing = false
        }

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

            // Reset detection state and counters
            stableDetectionCount = 0
            lowConfidenceCount = 0
            try? await Task.sleep(for: .milliseconds(500))
            cameraManager.detectionState = .searching
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

    private func handleDetectionStateChange(_ newState: CameraManager.DetectionState) {
        // Event-driven auto-capture: track stable frames instead of polling with Timer
        guard autoCapture, !scanSession.isProcessing else { return }

        switch newState {
        case .readyToCapture:
            stableDetectionCount += 1
            if stableDetectionCount >= requiredStableFrames {
                // Perfect frame reached - subtle haptic feedback
                HapticManager.shared.light()
                performCapture()
                stableDetectionCount = 0
            }
        case .cardFound, .searching, .capturing:
            stableDetectionCount = 0
        }

        // Low light detection: track low confidence frames
        if case .searching = newState {
            lowConfidenceCount += 1
            if lowConfidenceCount >= lowConfidenceThreshold {
                showLowLightError()
                lowConfidenceCount = 0
            }
        } else {
            lowConfidenceCount = 0
        }
    }

    private func showLowLightError() {
        errorType = .lowLight
        withAnimation {
            showErrorOverlay = true
        }
        HapticManager.shared.warning()
    }

    private func handleErrorDismiss() {
        withAnimation {
            showErrorOverlay = false
        }
        errorType = nil
    }

    private func handleSecondaryAction(for error: CameraError) {
        switch error {
        case .lowLight:
            // Enable torch
            guard let device = AVCaptureDevice.default(for: .video),
                  device.hasTorch else { return }

            do {
                try device.lockForConfiguration()
                device.torchMode = .on
                device.unlockForConfiguration()
                cameraManager.isFlashOn = true
            } catch {
                print("Torch error: \(error)")
            }

            showErrorOverlay = false
            errorType = nil

        case .cardNotFound:
            // Could show manual entry sheet in future
            showErrorOverlay = false
            errorType = nil

        case .cameraFailed:
            showErrorOverlay = false
            errorType = nil
        }
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

    private var detectionFrameState: MinimalDetectionFrame.State {
        if let frame = cameraManager.detectedCardFrame {
            switch cameraManager.detectionState {
            case .searching:
                return .searching
            case .cardFound:
                return .detecting(frame)
            case .readyToCapture:
                return .ready(frame)
            case .capturing:
                return .ready(frame)
            }
        }
        return .searching
    }

    private func mapToSimpleErrorType(_ error: CameraError) -> SimpleErrorModal.ErrorType {
        switch error {
        case .cardNotFound:
            return .cardNotFound
        case .lowLight:
            return .lowLight
        case .cameraFailed:
            return .cardNotFound // Use cardNotFound as fallback for camera errors
        }
    }

    private func shouldShowSecondaryAction(for error: CameraError) -> Bool {
        switch error {
        case .lowLight:
            return true
        case .cardNotFound, .cameraFailed:
            return false
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

// MARK: - Card Detection Frame Overlay
struct CardDetectionFrame: View {
    let frame: CGRect
    let geometrySize: CGSize
    let detectionState: CameraManager.DetectionState

    var body: some View {
        let rect = convertedRect

        RoundedRectangle(cornerRadius: 20)
            .stroke(detectionState.color, lineWidth: 3)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .animation(.spring(response: 0.3), value: detectionState)
            .overlay {
                // Corner guides
                ForEach(0..<4) { index in
                    CornerGuide(color: detectionState.color)
                        .rotationEffect(.degrees(Double(index * 90)))
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
            }
    }

    private var convertedRect: CGRect {
        // Convert Vision framework normalized coordinates to screen coordinates
        let x = frame.origin.x * geometrySize.width
        let y = (1 - frame.origin.y - frame.height) * geometrySize.height
        let width = frame.width * geometrySize.width
        let height = frame.height * geometrySize.height

        return CGRect(x: x, y: y, width: width, height: height)
    }
}

struct CornerGuide: View {
    let color: Color

    var body: some View {
        VStack {
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 30, height: 4)
                Spacer()
            }
            Spacer()
        }
    }
}

// MARK: - Background Dimming
struct BackgroundDimming: View {
    let detectionFrame: CGRect
    let geometrySize: CGSize

    var body: some View {
        let rect = convertedRect

        ZStack {
            // Full screen dimming
            Color.black.opacity(0.5)

            // Cut out the detection area
            RoundedRectangle(cornerRadius: 20)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .animation(.easeInOut(duration: 0.3), value: detectionFrame)
    }

    private var convertedRect: CGRect {
        // Convert Vision framework normalized coordinates to screen coordinates
        let x = detectionFrame.origin.x * geometrySize.width
        let y = (1 - detectionFrame.origin.y - detectionFrame.height) * geometrySize.height
        let width = detectionFrame.width * geometrySize.width
        let height = detectionFrame.height * geometrySize.height

        return CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - Scanner Loading Overlay
struct ScannerLoadingOverlay: View {
    let status: String

    var body: some View {
        ZStack {
            // Semi-transparent background using design system
            DesignSystem.ComponentStyles.LoadingStyle.overlayColor
                .ignoresSafeArea()

            // Loading card with design system styling
            VStack(spacing: DesignSystem.Spacing.md) {
                // Spinner with design system color
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(DesignSystem.ComponentStyles.LoadingStyle.spinnerColor)

                // Status text with design system typography
                Text(status)
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(DesignSystem.ComponentStyles.LoadingStyle.textColor)

                // Subtext with design system typography
                Text("Please wait...")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .padding(DesignSystem.ComponentStyles.LoadingStyle.padding)
            .background(DesignSystem.ComponentStyles.LoadingStyle.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.ComponentStyles.LoadingStyle.cornerRadius))
            .shadowElevation(5)
        }
        .transition(.opacity)
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
