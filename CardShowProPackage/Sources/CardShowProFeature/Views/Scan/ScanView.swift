import SwiftUI
import SwiftData
import AVFoundation

/// Redesigned camera-first card scanning view
/// Features: Search bar, contained camera preview with corner brackets,
/// zoom controls, frame mode selector, and recent scans section
struct ScanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Navigation configuration
    let showBackButton: Bool

    @State private var cameraManager = CameraManager()
    @State private var ocrService = CardOCRService.shared
    @State private var recentScansManager = RecentScansManager.shared

    // Search state
    @State private var searchText: String = ""

    // Camera state
    @State private var selectedZoom: ZoomLevel = .x1_5
    @State private var selectedFrameMode: FrameMode = .raw

    // Capture state
    @State private var capturedImage: UIImage?
    @State private var ocrResult: CardOCRService.OCRResult?
    @State private var isCapturing = false
    @State private var isProcessingOCR = false

    // UI state - false = camera large (default), true = recent scans expanded
    @State private var isRecentScansExpanded = false

    // Sheet states
    @State private var showScanResult = false
    @State private var showManualEntry = false
    @State private var showCardEntry = false
    @State private var selectedCardMatch: CardMatch?

    // Error state
    @State private var errorMessage: String?
    @State private var showError = false

    init(showBackButton: Bool = false) {
        self.showBackButton = showBackButton
    }

    // Height for the recent scans overlay when expanded
    private var recentScansExpandedHeight: CGFloat {
        UIScreen.main.bounds.height * 0.70
    }

    // Height for collapsed recent scans (just header peek)
    private let recentScansCollapsedHeight: CGFloat = 100

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
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showScanResult) {
            if let image = capturedImage, let result = ocrResult {
                ScanResultView(
                    capturedImage: image,
                    ocrResult: result,
                    onRetake: {
                        resetCapture()
                    },
                    onLookupComplete: { cardMatch in
                        selectedCardMatch = cardMatch
                        showScanResult = false

                        // Add to recent scans
                        addToRecentScans(cardMatch)

                        showCardEntry = true
                    }
                )
            }
        }
        .sheet(isPresented: $showManualEntry) {
            CardPriceLookupView()
        }
        .sheet(isPresented: $showCardEntry) {
            if let match = selectedCardMatch {
                cardEntrySheet(for: match)
            }
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
                        isCapturing: isCapturing
                    )
                    .padding(12)

                    // Center instruction text
                    if !isCapturing && !isProcessingOCR {
                        Text("Tap Anywhere to Scan")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    // Processing overlay
                    if isProcessingOCR {
                        processingOverlay
                    }
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    capturePhoto()
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

                Text("Analyzing card...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .padding(12)
    }

    // MARK: - Card Entry Sheet

    private func cardEntrySheet(for match: CardMatch) -> some View {
        NavigationStack {
            let scanState = ScanFlowState()
            let _ = {
                scanState.cardNumber = match.cardNumber
                scanState.cardImageURL = match.imageURL
            }()

            CardEntryView(
                pokemonName: match.cardName,
                setName: match.setName,
                setID: match.setID,
                state: scanState
            )
            .environment(\.modelContext, modelContext)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCardEntry = false
                        resetCapture()
                    }
                }
            }
        }
    }

    // MARK: - Camera Control

    private func startCamera() {
        cameraManager.startSession()
    }

    private func stopCamera() {
        cameraManager.stopSession()
    }

    // MARK: - Capture Flow

    private func capturePhoto() {
        guard !isCapturing && !isProcessingOCR else { return }
        guard cameraManager.previewLayer != nil else { return }

        isCapturing = true
        HapticManager.shared.medium()

        Task {
            do {
                // Capture photo
                let image = try await cameraManager.capturePhoto()
                capturedImage = image

                // Start OCR processing
                isCapturing = false
                isProcessingOCR = true

                // Perform OCR
                let result = try await ocrService.recognizeText(from: image)
                ocrResult = result

                // Pre-fill search with OCR result
                if let cardName = result.cardName, !cardName.isEmpty {
                    searchText = cardName
                }

                await MainActor.run {
                    isProcessingOCR = false
                    HapticManager.shared.success()
                    showScanResult = true
                }

            } catch {
                await MainActor.run {
                    isCapturing = false
                    isProcessingOCR = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticManager.shared.error()
                }
            }
        }
    }

    private func resetCapture() {
        capturedImage = nil
        ocrResult = nil
        selectedCardMatch = nil
        isCapturing = false
        isProcessingOCR = false
    }

    // MARK: - Recent Scans

    private func addToRecentScans(_ match: CardMatch) {
        // Note: CardMatch doesn't include price - it's retrieved later in CardEntryView
        // For now, add with price 0. Could be updated when price is fetched.
        recentScansManager.addScan(
            cardName: match.cardName,
            setName: match.setName,
            price: 0, // Price not available at scan time
            thumbnailURL: match.imageURL
        )
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
