import SwiftUI

/// Minimal detection frame with clean outline and muted colors
///
/// Shows a simple rectangular outline around detected cards with three states:
/// - Searching (muted red): No card detected
/// - Detecting (muted amber): Card detected but not stable
/// - Ready (muted green): Card stable and ready to capture
struct MinimalDetectionFrame: View {
    enum State {
        case searching
        case detecting(CGRect)
        case ready(CGRect)
    }

    let state: State
    let geometrySize: CGSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { _ in
            ZStack {
                switch state {
                case .searching:
                    searchingFrame

                case .detecting(let frame):
                    detectionFrame(at: frame, color: .amber)

                case .ready(let frame):
                    detectionFrame(at: frame, color: .green)
                }
            }
        }
    }

    // MARK: - Searching Frame
    private var searchingFrame: some View {
        VStack {
            Spacer()

            // Center guide frame
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                .frame(width: geometrySize.width * 0.7, height: geometrySize.height * 0.5)
                .overlay {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.6))

                        Text("Position card in frame")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Searching for card. Position card in frame")
    }

    // MARK: - Detection Frame
    private func detectionFrame(at rect: CGRect, color: DetectionColor) -> some View {
        let scaledRect = CGRect(
            x: rect.minX * geometrySize.width,
            y: rect.minY * geometrySize.height,
            width: rect.width * geometrySize.width,
            height: rect.height * geometrySize.height
        )

        let frameColor: Color = {
            switch color {
            case .amber:
                return Color.orange.opacity(0.7) // Muted amber
            case .green:
                return Color.green.opacity(0.7) // Muted green
            }
        }()

        return ZStack {
            // Main outline
            RoundedRectangle(cornerRadius: 8)
                .stroke(frameColor, lineWidth: 3)
                .frame(width: scaledRect.width, height: scaledRect.height)
                .position(x: scaledRect.midX, y: scaledRect.midY)
                .shadow(color: frameColor.opacity(0.5), radius: 8)

            // Corner markers (top-left, top-right, bottom-left, bottom-right)
            ForEach(0..<4) { index in
                cornerMarker(at: index, in: scaledRect, color: frameColor)
            }
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: scaledRect)
        .accessibilityLabel("\(color == .green ? "Ready to capture" : "Card detected, hold steady")")
    }

    // MARK: - Corner Markers
    private func cornerMarker(at index: Int, in rect: CGRect, color: Color) -> some View {
        let markerLength: CGFloat = 20
        let markerThickness: CGFloat = 4

        let position: CGPoint = {
            switch index {
            case 0: return CGPoint(x: rect.minX, y: rect.minY) // Top-left
            case 1: return CGPoint(x: rect.maxX, y: rect.minY) // Top-right
            case 2: return CGPoint(x: rect.minX, y: rect.maxY) // Bottom-left
            default: return CGPoint(x: rect.maxX, y: rect.maxY) // Bottom-right
            }
        }()

        return ZStack {
            // Horizontal marker
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: markerLength, height: markerThickness)
                .offset(
                    x: index % 2 == 0 ? markerLength / 2 : -markerLength / 2,
                    y: 0
                )

            // Vertical marker
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: markerThickness, height: markerLength)
                .offset(
                    x: 0,
                    y: index < 2 ? markerLength / 2 : -markerLength / 2
                )
        }
        .position(position)
    }

    enum DetectionColor {
        case amber
        case green
    }
}

// MARK: - Preview
#Preview("Searching") {
    ZStack {
        Color.black.ignoresSafeArea()

        GeometryReader { geometry in
            MinimalDetectionFrame(
                state: .searching,
                geometrySize: geometry.size
            )
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Detecting") {
    ZStack {
        Color.black.ignoresSafeArea()

        GeometryReader { geometry in
            MinimalDetectionFrame(
                state: .detecting(CGRect(x: 0.15, y: 0.25, width: 0.7, height: 0.5)),
                geometrySize: geometry.size
            )
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Ready") {
    ZStack {
        Color.black.ignoresSafeArea()

        GeometryReader { geometry in
            MinimalDetectionFrame(
                state: .ready(CGRect(x: 0.15, y: 0.25, width: 0.7, height: 0.5)),
                geometrySize: geometry.size
            )
        }
    }
    .preferredColorScheme(.dark)
}
