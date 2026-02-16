import SwiftUI

/// A full-screen zoomable image view with pinch-to-zoom, drag-to-pan, and double-tap gestures
struct ZoomableImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0

    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()

            // Zoomable image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(magnificationGesture)
                .simultaneousGesture(dragGesture)
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.3)) {
                        resetZoom()
                    }
                }
                .accessibilityLabel("Card image - Double tap to reset zoom")
                .accessibilityHint("Pinch to zoom, drag to pan when zoomed")

            // Close button
            VStack {
                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white, .black.opacity(0.5))
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                    .padding(DesignSystem.Spacing.md)
                }
                .accessibilityLabel("Close")

                Spacer()
            }
        }
    }

    // MARK: - Magnification Gesture
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                let newScale = scale * delta
                scale = min(max(newScale, minScale), maxScale)
            }
            .onEnded { _ in
                lastScale = 1.0

                // Snap back to min if close
                if scale < minScale * 1.1 {
                    withAnimation(.spring(response: 0.3)) {
                        scale = minScale
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
    }

    // MARK: - Drag Gesture
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only allow dragging when zoomed in
                if scale > minScale {
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    // MARK: - Reset Zoom
    private func resetZoom() {
        scale = minScale
        offset = .zero
        lastOffset = .zero
        lastScale = 1.0
    }
}

// MARK: - Preview
#Preview {
    ZoomableImageView(image: UIImage(systemName: "photo") ?? UIImage())
}
