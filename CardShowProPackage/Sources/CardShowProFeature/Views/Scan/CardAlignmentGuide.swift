import SwiftUI

/// Frame mode for different card types
enum FrameMode: String, CaseIterable {
    case raw = "Raw"
    case graded = "Graded"
    case bulk = "Bulk"

    /// Aspect ratio for each mode
    var aspectRatio: CGFloat {
        switch self {
        case .raw:
            return 5.0 / 7.0      // Standard trading card (2.5" x 3.5")
        case .graded:
            return 3.0 / 5.0      // PSA/BGS slab shape (taller profile)
        case .bulk:
            return 16.0 / 9.0     // Wide/full for bulk photos
        }
    }

    /// Description for accessibility
    var description: String {
        switch self {
        case .raw: return "Standard trading card frame"
        case .graded: return "Graded slab frame"
        case .bulk: return "Wide bulk scanning frame"
        }
    }
}

/// Visual guide overlay for camera view showing where to position the card
/// - Raw/Graded modes: Frosted overlay outside frame + green corner brackets
/// - Bulk mode: Full camera, no overlay, no brackets
struct CardAlignmentGuide: View {
    let frameMode: FrameMode
    let isCapturing: Bool


    // Bright green color for corner brackets (#7FFF00 / lime green)
    private let bracketColor = Color(red: 0.5, green: 1.0, blue: 0.0)

    // Frosted overlay opacity
    private let frostedOpacity: Double = 0.6

    init(frameMode: FrameMode = .raw, isCapturing: Bool = false) {
        self.frameMode = frameMode
        self.isCapturing = isCapturing
    }

    // Legacy initializer for compatibility
    init(isCardDetected: Bool = false, isCapturing: Bool = false) {
        self.frameMode = .raw
        self.isCapturing = isCapturing
    }

    var body: some View {
        GeometryReader { geometry in
            let guideSize = calculateGuideSize(in: geometry.size)

            ZStack {
                // Bulk mode: No overlay, no brackets - full camera view
                if frameMode == .bulk {
                    // Empty - full camera access
                } else {
                    // Raw/Graded: Frosted overlay with cutout + corner brackets
                    frostedOverlay(size: guideSize, in: geometry.size)

                    cornerBrackets(size: guideSize)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                }
            }
        }
    }

    // MARK: - Frosted Overlay

    private func frostedOverlay(size: CGSize, in viewSize: CGSize) -> some View {
        Canvas { context, canvasSize in
            // Fill entire canvas with semi-transparent black
            let fullRect = CGRect(origin: .zero, size: canvasSize)
            context.fill(Path(fullRect), with: .color(.black.opacity(frostedOpacity)))

            // Cut out the card frame area (clear rectangle in center)
            let cutoutRect = CGRect(
                x: (canvasSize.width - size.width) / 2,
                y: (canvasSize.height - size.height) / 2,
                width: size.width,
                height: size.height
            )
            context.blendMode = .destinationOut
            context.fill(Path(cutoutRect), with: .color(.white))
        }
        .compositingGroup()
        .allowsHitTesting(false)
    }

    // MARK: - Corner Brackets

    private func cornerBrackets(size: CGSize) -> some View {
        let bracketSize: CGFloat = 40  // Larger brackets as per design

        return ZStack {
            // Top-left corner
            CornerBracket(corner: .topLeft, size: bracketSize)
                .offset(
                    x: -size.width / 2 + bracketSize / 2,
                    y: -size.height / 2 + bracketSize / 2
                )

            // Top-right corner
            CornerBracket(corner: .topRight, size: bracketSize)
                .offset(
                    x: size.width / 2 - bracketSize / 2,
                    y: -size.height / 2 + bracketSize / 2
                )

            // Bottom-left corner
            CornerBracket(corner: .bottomLeft, size: bracketSize)
                .offset(
                    x: -size.width / 2 + bracketSize / 2,
                    y: size.height / 2 - bracketSize / 2
                )

            // Bottom-right corner
            CornerBracket(corner: .bottomRight, size: bracketSize)
                .offset(
                    x: size.width / 2 - bracketSize / 2,
                    y: size.height / 2 - bracketSize / 2
                )
        }
        .frame(width: size.width, height: size.height)
        .foregroundStyle(isCapturing ? .white : bracketColor)
        .animation(.easeInOut(duration: 0.15), value: isCapturing)
    }

    // MARK: - Layout Calculations

    private func calculateGuideSize(in viewSize: CGSize) -> CGSize {
        // Fill nearly all of the capture area
        let maxWidth = viewSize.width * 0.92
        let maxHeight = viewSize.height * 0.88

        // Calculate based on aspect ratio from frame mode
        let widthFromHeight = maxHeight * frameMode.aspectRatio
        let heightFromWidth = maxWidth / frameMode.aspectRatio

        if widthFromHeight <= maxWidth {
            return CGSize(width: widthFromHeight, height: maxHeight)
        } else {
            return CGSize(width: maxWidth, height: heightFromWidth)
        }
    }

}

// MARK: - Corner Bracket Component

private struct CornerBracket: View {
    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    let corner: Corner
    let size: CGFloat

    var body: some View {
        Path { path in
            switch corner {
            case .topLeft:
                // Vertical line going down
                path.move(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: 0, y: 0))
                // Horizontal line going right
                path.addLine(to: CGPoint(x: size, y: 0))

            case .topRight:
                // Horizontal line going left
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size, y: 0))
                // Vertical line going down
                path.addLine(to: CGPoint(x: size, y: size))

            case .bottomLeft:
                // Vertical line going up
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: size))
                // Horizontal line going right
                path.addLine(to: CGPoint(x: size, y: size))

            case .bottomRight:
                // Horizontal line going left
                path.move(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: size, y: size))
                // Vertical line going up
                path.addLine(to: CGPoint(x: size, y: 0))
            }
        }
        .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview("Raw Mode") {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        CardAlignmentGuide(frameMode: .raw)
    }
}

#Preview("Graded Mode") {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        CardAlignmentGuide(frameMode: .graded)
    }
}

#Preview("Bulk Mode - No Overlay") {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        Text("Full Camera View")
            .foregroundStyle(.white)
        CardAlignmentGuide(frameMode: .bulk)
    }
}

#Preview("Capturing") {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        CardAlignmentGuide(frameMode: .raw, isCapturing: true)
    }
}
