import SwiftUI

/// Zoom level options for camera
enum ZoomLevel: Double, CaseIterable {
    case x1_5 = 1.5
    case x2 = 2.0
    case x3 = 3.0

    var displayText: String {
        switch self {
        case .x1_5: return "1.5x"
        case .x2: return "2x"
        case .x3: return "3x"
        }
    }
}

/// Horizontal pill buttons for zoom control: 1.5x, 2x, 3x
struct ZoomControlsView: View {
    @Binding var selectedZoom: ZoomLevel
    let onZoomChange: (ZoomLevel) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ZoomLevel.allCases, id: \.self) { level in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedZoom = level
                    }
                    onZoomChange(level)
                    HapticManager.shared.light()
                } label: {
                    Text(level.displayText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selectedZoom == level ? .black : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedZoom == level ? .white : Color.white.opacity(0.2))
                        )
                }
                .accessibilityLabel("Zoom \(level.displayText)")
                .accessibilityAddTraits(selectedZoom == level ? .isSelected : [])
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            ZoomControlsView(
                selectedZoom: .constant(.x1_5),
                onZoomChange: { _ in }
            )

            ZoomControlsView(
                selectedZoom: .constant(.x2),
                onZoomChange: { _ in }
            )

            ZoomControlsView(
                selectedZoom: .constant(.x3),
                onZoomChange: { _ in }
            )
        }
    }
}
