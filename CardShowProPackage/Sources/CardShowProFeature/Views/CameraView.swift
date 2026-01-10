import SwiftUI
import SwiftData
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var cameraManager = CameraManager()
    @State private var scanSession = ScanSession()
    @State private var selectedMode: ScanMode = .negotiator
    @State private var showSettings = false
    @State private var autoCapture = true
    @State private var captureTimer: Timer?

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
                    CardDetectionFrame(
                        frame: frame,
                        geometrySize: geometry.size,
                        detectionState: cameraManager.detectionState
                    )
                }
                .ignoresSafeArea()
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

            // MARK: - Close Button
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
                }
                Spacer()
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
                Button {
                    // Pick from gallery
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
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

            // Total Value
            HStack {
                Text("Total Value:")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("$\(String(format: "%.2f", scanSession.totalValue))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.cyan)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
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

        captureTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                if self.cameraManager.detectionState == .readyToCapture,
                   !self.scanSession.isProcessing {
                    self.performCapture()
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

        // Simulate AI card recognition (replace with real API call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let mockCard = ScannedCard(
                image: image,
                cardName: "Pikachu VMAX",
                cardNumber: "#044",
                setName: "Vivid Voltage",
                estimatedValue: Double.random(in: 50...500),
                confidence: 0.92
            )

            // Add to scan session (temporary)
            scanSession.addCard(mockCard)

            // IMPORTANT: Save to SwiftData for persistence
            let inventoryCard = InventoryCard(from: mockCard)
            modelContext.insert(inventoryCard)

            // Automatically save
            do {
                try modelContext.save()
            } catch {
                print("Error saving card: \(error)")
            }

            scanSession.isProcessing = false

            // Brief delay before ready for next capture
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                cameraManager.detectionState = .searching
            }
        }
    }

    private func finishSession() {
        // Process all scanned cards
        dismiss()
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
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.cyan)

                Text(card.cardName)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
    }
}
