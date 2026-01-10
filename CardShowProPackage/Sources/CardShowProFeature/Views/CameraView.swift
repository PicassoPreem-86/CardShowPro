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
    @State private var showSettings = false
    @State private var autoCapture = true
    @State private var captureTimer: Timer?

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
    @State private var isRecognizing = false
    @State private var loadingStatus = "Recognizing card..."

    // Success state
    @State private var showSessionSuccess = false

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
            if cameraManager.isCardDetected, let frame = cameraManager.detectedCardFrame {
                GeometryReader { geometry in
                    ZStack {
                        // Background dimming
                        BackgroundDimming(
                            detectionFrame: frame,
                            geometrySize: geometry.size
                        )

                        // Detection frame
                        CardDetectionFrame(
                            frame: frame,
                            geometrySize: geometry.size,
                            detectionState: cameraManager.detectionState
                        )
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

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
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()

                    Spacer()

                    // Flash Toggle
                    if cameraManager.hasFlash {
                        Button {
                            cameraManager.toggleFlash()
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        } label: {
                            Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(cameraManager.isFlashOn ? .yellow : .white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                }
                Spacer()
            }

            // MARK: - Loading Overlay
            if isRecognizing {
                ScannerLoadingOverlay(status: loadingStatus)
            }
        }
        .statusBarHidden()
        .task {
            cameraManager.startSession()
            startAutoCapture()
        }
        .onDisappear {
            cameraManager.stopSession()
            captureTimer?.invalidate()
        }
        .sheet(isPresented: $showSettings) {
            settingsSheet
        }
        .sheet(isPresented: $showConfirmation) {
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
                        // Reset pending state for rescan
                        pendingCardImage = nil
                        pendingRecognition = nil
                        pendingPricing = nil
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
    }

    // MARK: - Top Bar
    private var topBar: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 20)

            HStack {
                Spacer()

                // Mode Picker
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

                Spacer()
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
        VStack(spacing: 8) {
            if cameraManager.isCardDetected {
                Text(cameraManager.detectionState.message)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(cameraManager.detectionState.color.opacity(0.9))
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text("Position card in frame")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
            }
        }
        .animation(.spring(response: 0.3), value: cameraManager.isCardDetected)
        .animation(.spring(response: 0.3), value: cameraManager.detectionState)
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
        VStack(spacing: 12) {
            HStack {
                Text("Scanned: \(scanSession.cardCount) cards")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(scanSession.scannedCards) { card in
                        ScannedCardThumbnail(card: card) {
                            scanSession.removeCard(card)
                        }
                    }
                }
                .padding(.horizontal, 20)
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
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.xxxs)
        }
        .padding(.bottom, 12)
        .background(Color.black.opacity(0.3))
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
    private func startAutoCapture() {
        guard autoCapture else { return }

        // Check every 0.5s if card is ready to capture
        // This gives user 1-2 seconds of "ready" state before auto-capture
        captureTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                if self.cameraManager.detectionState == .readyToCapture,
                   !self.scanSession.isProcessing {
                    // Add small delay to prevent instant capture
                    try? await Task.sleep(for: .seconds(1.0))

                    // Re-check state after delay (card might have moved)
                    if self.cameraManager.detectionState == .readyToCapture,
                       !self.scanSession.isProcessing {
                        self.performCapture()
                    }
                }
            }
        }
    }

    private func manualCapture() {
        performCapture()
    }

    private func performCapture() {
        guard let image = cameraManager.capturePhoto() else { return }

        scanSession.isProcessing = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Perform card recognition with real API
        Task {
            // Show loading overlay
            isRecognizing = true
            loadingStatus = "Recognizing card..."

            do {
                // Step 1: Recognize card from image
                let recognition = try await recognitionService.recognizeCard(from: image)

                // Update loading status
                loadingStatus = "Fetching prices..."

                // Step 2: Fetch pricing (in parallel with showing confirmation)
                async let pricing = try? await pricingService.fetchPricing(
                    cardName: recognition.cardName,
                    setName: recognition.setName,
                    cardNumber: recognition.cardNumber
                )

                // Hide loading overlay
                isRecognizing = false

                // Step 3: Show confirmation view
                pendingCardImage = image
                pendingRecognition = recognition
                pendingPricing = await pricing
                showConfirmation = true

                scanSession.isProcessing = false
            } catch {
                // Handle recognition error
                print("Recognition error: \(error.localizedDescription)")

                // Show error feedback
                let errorGenerator = UINotificationFeedbackGenerator()
                errorGenerator.notificationOccurred(.error)

                // Fall back to manual entry or show error
                // For now, create a card with low confidence
                let fallbackRecognition = RecognitionResult(
                    cardName: "Unknown Card",
                    setName: "Unknown Set",
                    cardNumber: "???",
                    confidence: 0.0,
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

            // Reset detection state after brief delay
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

        // Success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
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
            let recognition = try await recognitionService.recognizeCard(from: image)

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
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                // Card Image
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 70, height: 70)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }

                // Delete button
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .background(Circle().fill(Color.red))
                }
                .offset(x: 6, y: -6)
            }

            // Card info
            VStack(spacing: 2) {
                Text("$\(String(format: "%.0f", card.estimatedValue))")
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.cyan)

                Text(card.cardName)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
    }
}
