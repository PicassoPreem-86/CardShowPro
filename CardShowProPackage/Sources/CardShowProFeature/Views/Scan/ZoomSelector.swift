import SwiftUI

/// Horizontal zoom level selector with 1.5x, 2x, 3x options
struct ZoomSelector: View {
    @Binding var selectedZoom: Double
    let onZoomChange: (Double) -> Void

    private let zoomLevels: [Double] = [1.5, 2.0, 3.0]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(zoomLevels, id: \.self) { zoom in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedZoom = zoom
                    }
                    onZoomChange(zoom)
                    HapticManager.shared.light()
                } label: {
                    Text(zoomLabel(for: zoom))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(selectedZoom == zoom ? .black : .white)
                        .frame(width: 36, height: 28)
                        .background(
                            Capsule()
                                .fill(selectedZoom == zoom ? Color(red: 0.5, green: 1.0, blue: 0.0) : Color.white.opacity(0.2))
                        )
                }
                .accessibilityLabel("\(zoomLabel(for: zoom)) zoom")
                .accessibilityAddTraits(selectedZoom == zoom ? .isSelected : [])
            }
        }
    }

    private func zoomLabel(for zoom: Double) -> String {
        if zoom == 1.5 {
            return "1.5x"
        } else if zoom == 2.0 {
            return "2x"
        } else if zoom == 3.0 {
            return "3x"
        } else {
            return "\(Int(zoom))x"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            ZoomSelector(selectedZoom: .constant(1.5)) { _ in }
            ZoomSelector(selectedZoom: .constant(2.0)) { _ in }
            ZoomSelector(selectedZoom: .constant(3.0)) { _ in }
        }
    }
}
