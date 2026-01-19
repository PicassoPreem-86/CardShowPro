import SwiftUI
import SwiftData
import AVFoundation

/// Redesigned camera-first card scanning view with seamless flow
/// Features: Search bar, contained camera preview with corner brackets,
/// zoom controls, frame mode selector, and thumbnail strip for recent scans
///
/// Seamless Flow: Tap to scan → auto-identify + price → thumbnail appears
struct ScanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Navigation configuration
    let showBackButton: Bool

    @State private var cameraManager = CameraManager()
    @State private var ocrService = CardOCRService.shared
    @State private var scannedCardsManager = ScannedCardsManager.shared
    private let pokemonService = PokemonTCGService.shared

    // Search state
    @State private var searchText: String = ""

    // Camera state
    @State private var selectedZoom: ZoomLevel = .x1_5
    @State private var selectedFrameMode: FrameMode = .raw

    // Processing state (seamless flow)
    @State private var isCapturing = false
    @State private var isProcessing = false
    @State private var processingStatus: String = ""

    // UI state - false = camera large (default), true = recent scans expanded
    @State private var isRecentScansExpanded = false

    // Sheet states (for manual entry fallback)
    @State private var showManualEntry = false

    // Toast/error state
    @State private var toastMessage: String?
    @State private var showToast = false

    // Error alert state
    @State private var errorMessage: String?
    @State private var showError = false

    init(showBackButton: Bool = false) {
        self.showBackButton = showBackButton
    }

    // Height for the recent scans overlay when expanded
    private var recentScansExpandedHeight: CGFloat {
        UIScreen.main.bounds.height * 0.70
    }

    // Height for collapsed recent scans (just header + thumbnail strip)
    private let recentScansCollapsedHeight: CGFloat = 140

    var body: some View {
        ZStack(alignment: .bottom) {
            // Base layer: Full camera view
            VStack(spacing: 0) {
                // 1. Top bar with optional back + search
                GradientSearchBar(
                    text: $searchText,
                    showBackButton: showBackButton,
                    onBack: { dismiss() },
                    onSubmit: {
                        // Pre-fill search and open manual entry
                        showManualEntry = true
                    }
                )
                .padding(.top, 8)
                .padding(.bottom, 12)

                // 2. Camera container card - fills remaining space
                cameraCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, recentScansCollapsedHeight + 8) // Space for collapsed overlay
            }

            // Overlay: Recent scans sliding panel
            recentScansOverlay

            // Toast overlay
            if showToast, let message = toastMessage {
                toastView(message: message)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showManualEntry) {
            CardPriceLookupView()
        }
        .alert("Camera Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
            if cameraManager.authorizationStatus == .denied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            startCamera()
            // Apply initial zoom
            cameraManager.setZoom(selectedZoom.rawValue)
        }
        .onDisappear {
            stopCamera()
        }
    }

    // MARK: - Camera Card

    private var cameraCard: some View {
        ZStack {
            // Dark card background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.12))

            VStack(spacing: 0) {
                // Camera preview area - fills available space
                ZStack {
                    // Camera preview or placeholder
                    cameraPreviewContent
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(12)

                    // Corner brackets overlay
                    CardAlignmentGuide(
                        frameMode: selectedFrameMode,
                        isCapturing: isCapturing || isProcessing
                    )
                    .padding(12)

                    // Center instruction text (when idle)
                    if !isCapturing && !isProcessing {
                        Text("Tap Anywhere to Scan")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    // Processing overlay
                    if isProcessing {
                        processingOverlay
                    }
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    captureAndProcess()
                }

                // Bottom controls row
                HStack {
                    // Zoom controls
                    ZoomControlsView(
                        selectedZoom: $selectedZoom,
                        onZoomChange: { level in
                            cameraManager.animateZoom(to: level.rawValue)
                        }
                    )

                    Spacer()

                    // Frame mode selector
                    FrameModeSelector(selectedMode: $selectedFrameMode)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Recent Scans Overlay

    private var recentScansOverlay: some View {
        VStack(spacing: 0) {
            // Drag handle / chevron
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isRecentScansExpanded.toggle()
                }
                HapticManager.shared.light()
            } label: {
                VStack(spacing: 6) {
                    // Pill drag indicator
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 36, height: 5)

                    Image(systemName: isRecentScansExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }
            .accessibilityLabel(isRecentScansExpanded ? "Collapse recent scans" : "Expand recent scans")

            // Recent scans content
            RecentScansSection(
                isExpanded: $isRecentScansExpanded,
                onLoadPrevious: {
                    // Could load from persistence in future
                }
            )
            .environment(\.modelContext, modelContext)
        }
        .frame(height: isRecentScansExpanded ? recentScansExpandedHeight : recentScansCollapsedHeight)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(white: 0.08))
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isRecentScansExpanded)
    }

    // MARK: - Camera Preview Content

    private var cameraPreviewContent: some View {
        Group {
            if let previewLayer = cameraManager.previewLayer {
                CameraPreviewView(previewLayer: previewLayer)
            } else {
                cameraPlaceholder
            }
        }
    }

    private var cameraPlaceholder: some View {
        ZStack {
            Color(white: 0.08)

            VStack(spacing: DesignSystem.Spacing.md) {
                switch cameraManager.authorizationStatus {
                case .notDetermined:
                    ProgressView()
                        .tint(.white)
                    Text("Requesting camera access...")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))

                case .denied, .restricted:
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Camera Access Required")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Enable camera access in Settings")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.5, green: 1.0, blue: 0.0))
                    .clipShape(Capsule())

                case .authorized:
                    if case .failed(let error) = cameraManager.sessionState {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(DesignSystem.Colors.warning)
                        Text("Camera Error")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(error.localizedDescription)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        ProgressView()
                            .tint(.white)
                        Text("Setting up camera...")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                @unknown default:
                    Text("Camera unavailable")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 12) {
                ProgressView()
                    .tint(Color(red: 0.5, green: 1.0, blue: 0.0))
                    .scaleEffect(1.3)

                Text(processingStatus.isEmpty ? "Processing..." : processingStatus)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .padding(12)
    }

    // MARK: - Toast View

    private func toastView(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(white: 0.2))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        .padding(.top, 100) // Position below status bar
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Camera Control

    private func startCamera() {
        cameraManager.startSession()
    }

    private func stopCamera() {
        cameraManager.stopSession()
    }

    // MARK: - Seamless Capture Flow

    private func captureAndProcess() {
        guard !isCapturing && !isProcessing else { return }
        guard cameraManager.previewLayer != nil else { return }

        isCapturing = true
        HapticManager.shared.medium()

        Task {
            do {
                // 1. Capture photo
                processingStatus = "Capturing..."
                let image = try await cameraManager.capturePhoto()

                isCapturing = false
                isProcessing = true

                // 2. OCR
                processingStatus = "Reading card..."
                let ocrResult = try await ocrService.recognizeText(from: image)

                guard let cardName = ocrResult.cardName, !cardName.isEmpty else {
                    // Show toast and allow retry
                    await showErrorToast("Couldn't read card name. Try again or use manual search.")
                    return
                }

                // 3. Search for card
                processingStatus = "Searching..."
                let matches = try await pokemonService.searchCardFuzzy(
                    name: cardName,
                    number: ocrResult.cardNumber
                )

                guard let bestMatch = matches.first else {
                    await showErrorToast("No cards found for '\(cardName)'. Try manual search.")
                    return
                }

                // 4. Add to scanned cards (pricing fetched automatically by manager)
                await MainActor.run {
                    scannedCardsManager.addCard(from: bestMatch)
                    HapticManager.shared.success()
                }

                // 5. Reset state
                await MainActor.run {
                    isProcessing = false
                    processingStatus = ""
                }

            } catch {
                await MainActor.run {
                    isCapturing = false
                    isProcessing = false
                    processingStatus = ""
                }
                await showErrorToast("Scan failed. Try again.")
                HapticManager.shared.error()
            }
        }
    }

    @MainActor
    private func showErrorToast(_ message: String) async {
        isCapturing = false
        isProcessing = false
        processingStatus = ""

        toastMessage = message
        withAnimation(.easeInOut(duration: 0.3)) {
            showToast = true
        }

        // Auto-dismiss after 3 seconds
        try? await Task.sleep(for: .seconds(3))

        withAnimation(.easeInOut(duration: 0.3)) {
            showToast = false
        }
    }
}

// MARK: - Preview

#Preview("Tab Navigation (No Back)") {
    ScanView(showBackButton: false)
}

#Preview("Sheet Presentation (With Back)") {
    NavigationStack {
        ScanView(showBackButton: true)
    }
}
