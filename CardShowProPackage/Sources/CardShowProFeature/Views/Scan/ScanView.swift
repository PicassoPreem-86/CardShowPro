import SwiftUI
import SwiftData
import AVFoundation

/// Progress states for scan feedback - gives users specific status updates
enum ScanProgress: Equatable {
    case idle
    case capturing
    case recognizingCard    // OCR text recognition in progress (~200ms)
    case searchingDatabase  // Local DB or API search in progress
    case cardNotRecognized  // Recognition failed
    case noMatchesFound(String)  // Search failed, includes attempted name

    var displayText: String {
        switch self {
        case .idle:
            return ""
        case .capturing:
            return "Capturing..."
        case .recognizingCard:
            return "Identifying card..."
        case .searchingDatabase:
            return "Fetching details..."
        case .cardNotRecognized:
            return "Card not recognized"
        case .noMatchesFound(let name):
            return "No matches for '\(name)'"
        }
    }

    var isProcessing: Bool {
        switch self {
        case .idle, .cardNotRecognized, .noMatchesFound:
            return false
        case .capturing, .recognizingCard, .searchingDatabase:
            return true
        }
    }
}

/// Redesigned camera-first card scanning view with seamless flow
/// Features: Search bar, contained camera preview with corner brackets,
/// zoom controls, frame mode selector, and thumbnail strip for recent scans
///
/// Seamless Flow: Tap to scan → auto-identify + price → thumbnail appears
///
/// NEW Architecture (V2):
/// - Local SQLite database with FTS5 for <50ms search
/// - Optional live video mode with auto-capture
/// - Card rectification for improved recognition
struct ScanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Navigation configuration
    let showBackButton: Bool

    @State private var cameraManager = CameraManager()
    @State private var ocrService = CardOCRService.shared  // Primary recognition method (~200ms)
    @State private var scannedCardsManager = ScannedCardsManager.shared
    private let pokemonService = PokemonTCGService.shared

    // NEW: Feature flags and local database
    @State private var featureFlags = FeatureFlags.shared
    private let localDB = LocalCardDatabase.shared
    private let rectifier = CardImageRectifier.shared

    // Search state
    @State private var searchText: String = ""

    // Camera state
    @State private var selectedFrameMode: FrameMode = .raw
    @State private var selectedZoom: Double = 2.0

    // Processing state (seamless flow with specific progress feedback)
    @State private var scanProgress: ScanProgress = .idle

    // UI state - false = camera large (default), true = recent scans expanded
    @State private var isRecentScansExpanded = false

    // Sheet states (for manual entry fallback)
    @State private var showManualEntry = false

    // Toast/error state
    @State private var toastMessage: String?
    @State private var showToast = false

    // Zoom indicator state
    @State private var showZoomIndicator = false
    @State private var currentZoomDisplay = "2x"

    // Error alert state
    @State private var errorMessage: String?
    @State private var showError = false

    // NEW: Ambiguity handling state
    @State private var ambiguousMatches: [LocalCardMatch] = []
    @State private var suggestedSets: [String] = []
    @State private var showAmbiguitySheet = false

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

            // Toast overlay (positioned using safe area)
            VStack {
                if showToast, let message = toastMessage {
                    toastView(message: message)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .zIndex(100)
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showManualEntry) {
            CardPriceLookupView()
        }
        .sheet(isPresented: $showAmbiguitySheet) {
            AmbiguousMatchSheet(
                candidates: ambiguousMatches,
                suggestedSets: suggestedSets,
                onSelect: { selectedCard in
                    // User selected a card from the ambiguity sheet
                    let cardMatch = selectedCard.toCardMatch()
                    scannedCardsManager.addCard(from: cardMatch)
                    HapticManager.shared.success()
                    scanProgress = .idle
                }
            )
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
            // Configure cache for faster repeat scans
            scannedCardsManager.configure(modelContext: modelContext)

            // Configure camera for initial zoom after short delay (camera needs to initialize)
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                cameraManager.setZoom(selectedZoom)
            }

            // Initialize local database for fast search
            Task {
                if await !localDB.isReady {
                    do {
                        try await localDB.initialize()
                    } catch {
                        // Local database init failed - will use remote API as fallback
                    }
                }
            }
        }
        .onDisappear {
            stopCamera()
        }
        .onChange(of: selectedFrameMode) { oldMode, newMode in
            // Set default zoom for each frame mode
            let defaultZoom: Double
            switch newMode {
            case .raw, .graded:
                defaultZoom = 2.0
            case .bulk:
                defaultZoom = 3.0
            }
            selectedZoom = defaultZoom
            cameraManager.setZoom(defaultZoom)

            // Show zoom indicator with haptic feedback
            withAnimation(.easeOut(duration: 0.3)) {
                currentZoomDisplay = "\(Int(defaultZoom))x"
                showZoomIndicator = true
            }

            HapticManager.shared.medium()

            // Auto-hide after 2 seconds
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeOut) {
                    showZoomIndicator = false
                }
            }
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
                        isCapturing: scanProgress.isProcessing
                    )
                    .padding(12)

                    // Zoom indicator (temporary badge on zoom change)
                    if showZoomIndicator {
                        VStack {
                            HStack {
                                Spacer()
                                Text(currentZoomDisplay)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(red: 0.5, green: 1.0, blue: 0.0))
                                    .clipShape(Capsule())
                                    .transition(.scale.combined(with: .opacity))
                                    .padding(.top, 16)
                                    .padding(.trailing, 16)
                            }
                            Spacer()
                        }
                    }

                    // Center instruction text (when idle)
                    if scanProgress == .idle {
                        VStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)

                            Text("Tap to Scan Card")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.75))
                                .shadow(color: .black.opacity(0.3), radius: 8)
                        )
                    }

                    // Processing overlay
                    if scanProgress.isProcessing {
                        processingOverlay
                            .accessibilityLabel(scanProgress.displayText)
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    captureAndProcess()
                }
                .accessibilityLabel("Camera viewfinder")
                .accessibilityHint("Tap anywhere to scan a card")
                .accessibilityAddTraits(.isButton)

                // Bottom controls
                VStack(spacing: 10) {
                    // Flash and Frame mode row
                    HStack {
                        // Flash toggle button
                        if cameraManager.hasFlash {
                            Button {
                                cameraManager.toggleFlash()
                                HapticManager.shared.light()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 14, weight: .medium))

                                    Text(cameraManager.isFlashOn ? "On" : "Off")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(cameraManager.isFlashOn ? .black : .white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(cameraManager.isFlashOn ? Color(red: 0.5, green: 1.0, blue: 0.0) : Color.white.opacity(0.2))
                                )
                            }
                            .frame(minHeight: 44)
                            .accessibilityLabel("Flash \(cameraManager.isFlashOn ? "on" : "off")")
                            .accessibilityHint("Tap to toggle flash")
                        }

                        Spacer()

                        // Frame mode selector
                        FrameModeSelector(selectedMode: $selectedFrameMode)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Recent Scans Overlay

    private var recentScansOverlay: some View {
        VStack(spacing: 0) {
            // Drag handle
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isRecentScansExpanded.toggle()
                }
                HapticManager.shared.light()
            } label: {
                VStack(spacing: 0) {
                    // Pill drag indicator
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.gray.opacity(0.7))
                        .frame(width: 36, height: 5)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .frame(minHeight: 44)
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
        VStack(spacing: 16) {
            // State-specific icon with animation
            Image(systemName: iconForScanProgress(scanProgress))
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(Color(red: 0.5, green: 1.0, blue: 0.0))
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: 4) {
                Text(scanProgress.displayText.isEmpty ? "Processing..." : scanProgress.displayText)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                // Optional subtitle for more detail
                if let subtitle = subtitleForScanProgress(scanProgress) {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(0.5), radius: 20)
        )
    }

    private func iconForScanProgress(_ progress: ScanProgress) -> String {
        switch progress {
        case .capturing:
            return "camera.fill"
        case .recognizingCard:
            return "text.magnifyingglass"
        case .searchingDatabase:
            return "magnifyingglass"
        case .cardNotRecognized, .noMatchesFound:
            return "exclamationmark.triangle.fill"
        case .idle:
            return "checkmark.circle.fill"
        }
    }

    private func subtitleForScanProgress(_ progress: ScanProgress) -> String? {
        switch progress {
        case .capturing:
            return "Hold steady"
        case .recognizingCard:
            return "Reading card text"
        case .searchingDatabase:
            return "Looking up details"
        default:
            return nil
        }
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
        .padding(.horizontal, 16)
    }

    // MARK: - Camera Control

    private func startCamera() {
        cameraManager.startSession()
    }

    private func stopCamera() {
        cameraManager.stopSession()
    }

    // MARK: - Seamless Capture Flow (OCR → Local DB Primary, Remote API Fallback)
    // FAST: OCR (~200ms) → Local SQLite FTS5 (<50ms) = sub-500ms total
    // Remote API only used when local database has no matches

    private func captureAndProcess() {
        guard scanProgress == .idle else { return }
        guard cameraManager.previewLayer != nil else { return }

        scanProgress = .capturing
        HapticManager.shared.medium()

        Task {
            do {
                // 1. Capture photo
                let originalImage = try await cameraManager.capturePhoto()
                var image = originalImage

                // 1b. OPTIONAL: Rectify image for better OCR accuracy
                var didRectify = false
                if await featureFlags.shouldRectifyImages {
                    let detector = CardQuadrilateralDetector()
                    if let detection = await detector.processImage(originalImage),
                       let rectified = rectifier.rectifyCard(from: originalImage, quadrilateral: detection) {
                        image = rectified
                        didRectify = true
                    }
                }

                // 2. OCR Recognition (Fast: ~200ms)
                await MainActor.run { scanProgress = .recognizingCard }

                var ocrResult = try await ocrService.recognizeText(from: image)

                // 2b. FALLBACK: If rectified image failed to find card name, retry with original
                // This helps with CJK cards where rectification downscaling loses detail
                if ocrResult.cardName == nil && didRectify {
                    print("🔤 DEBUG [Scan]: Rectified OCR failed, retrying with original high-res image...")
                    ocrResult = try await ocrService.recognizeText(from: originalImage)
                }

                // Extract OCR results
                let cardName = ocrResult.cardName
                let cardNumber = ocrResult.cardNumber

                // FALLBACK: If no name found but we have a number, try number-only search
                // This helps when OCR misreads CJK card names but gets the number right
                if (cardName == nil || cardName!.isEmpty) && (cardNumber == nil || cardNumber!.isEmpty) {
                    await MainActor.run { scanProgress = .cardNotRecognized }
                    await showErrorToast("Card not recognized. Try better lighting or manual search.")
                    return
                }

                // Map OCR detected language to CardLanguage for search
                let detectedLanguage: CardLanguage?
                switch ocrResult.detectedLanguage {
                case .japanese:
                    detectedLanguage = .japanese
                case .chineseTraditional:
                    detectedLanguage = .chineseTraditional
                case .english:
                    detectedLanguage = .english
                }

                if let name = cardName, !name.isEmpty {
                    print("🔍 OCR detected: '\(name)' #\(cardNumber ?? "none") (language: \(ocrResult.detectedLanguage.rawValue))")
                } else if let number = cardNumber {
                    print("🔍 OCR detected number only: #\(number) (name recognition failed, will search by number)")
                }

                // 3. CARD RESOLUTION using CardResolver (handles exact lookup, FTS, and ambiguity)
                await MainActor.run { scanProgress = .searchingDatabase }

                var matches: [CardMatch] = []
                let shouldUseLocal = await featureFlags.shouldUseLocalSearch
                let dbReady = await localDB.isReady

                if shouldUseLocal && dbReady {
                    do {
                        print("🔍 Using CardResolver for intelligent card resolution...")

                        // Build resolver input
                        let resolveInput = CardResolveInput(
                            language: detectedLanguage,
                            setCode: ocrResult.setCode,  // From OCR detection
                            number: cardNumber,
                            nameHint: cardName,
                            ximilarConfidence: nil  // Could add Ximilar result here if available
                        )

                        // Resolve using CardResolver
                        let resolution = try await CardResolver.shared.resolve(resolveInput)

                        switch resolution {
                        case .single(let match):
                            // Single match found - proceed
                            matches = [match.toCardMatch()]
                            print("✅ CardResolver found single match: \(match.cardName)")

                        case .ambiguous(let candidates, let reason, let sets):
                            // Multiple candidates - show set picker UI
                            print("❓ CardResolver found ambiguous results: \(reason)")
                            await MainActor.run {
                                self.ambiguousMatches = candidates
                                self.suggestedSets = sets
                                self.showAmbiguitySheet = true
                            }
                            return

                        case .none(let reason):
                            // No matches found in local database - will fall back to remote API
                            print("⚠️ CardResolver found no matches: \(reason) - will try remote API")
                            // Don't return here - let it fall through to remote API fallback
                        }
                    } catch {
                        print("⚠️ CardResolver failed: \(error.localizedDescription)")
                        // Will fall back to remote API
                    }
                }

                // 4. REMOTE API FALLBACK (only if local search found nothing and we have a valid name)
                if matches.isEmpty && cardName != nil && !cardName!.isEmpty {
                    print("🌐 Local DB empty, falling back to remote API...")

                    // Use fuzzy search since OCR can have slight errors
                    matches = try await pokemonService.searchCardFuzzy(name: cardName!, number: cardNumber)

                    // Try exact search as backup if fuzzy returns nothing
                    if matches.isEmpty {
                        matches = try await pokemonService.searchCard(name: cardName!, number: cardNumber)
                    }
                }

                guard let bestMatch = matches.first else {
                    let searchTerm = cardName ?? "#\(cardNumber ?? "unknown")"
                    await MainActor.run { scanProgress = .noMatchesFound(searchTerm) }
                    await showErrorToast("No cards found for '\(searchTerm)'. Try manual search.")
                    return
                }

                // 5. Add to scanned cards (pricing fetched automatically by manager)
                await MainActor.run {
                    scannedCardsManager.addCard(from: bestMatch)
                    HapticManager.shared.success()
                    scanProgress = .idle
                }

            } catch {
                await MainActor.run {
                    scanProgress = .idle
                }
                await showErrorToast("Scan failed: \(error.localizedDescription)")
                HapticManager.shared.error()
            }
        }
    }

    @MainActor
    private func showErrorToast(_ message: String) async {
        // Reset to idle after showing error state briefly
        try? await Task.sleep(for: .milliseconds(500))
        scanProgress = .idle

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
