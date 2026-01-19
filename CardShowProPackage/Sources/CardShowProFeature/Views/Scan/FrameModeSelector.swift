import SwiftUI

/// Tappable pill that cycles through frame modes: Raw → Graded → Bulk → Raw...
struct FrameModeSelector: View {
    @Binding var selectedMode: FrameMode

    var body: some View {
        Button {
            cycleMode()
            HapticManager.shared.light()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 11, weight: .medium))

                Text("Scanning: \(selectedMode.rawValue)")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.2))
            )
        }
        .accessibilityLabel("Scanning mode: \(selectedMode.rawValue)")
        .accessibilityHint("Tap to change scanning mode")
    }

    private var iconName: String {
        switch selectedMode {
        case .raw: return "rectangle.portrait"
        case .graded: return "rectangle.portrait.inset.filled"
        case .bulk: return "rectangle.expand.vertical"
        }
    }

    private func cycleMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch selectedMode {
            case .raw:
                selectedMode = .graded
            case .graded:
                selectedMode = .bulk
            case .bulk:
                selectedMode = .raw
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            FrameModeSelector(selectedMode: .constant(.raw))
            FrameModeSelector(selectedMode: .constant(.graded))
            FrameModeSelector(selectedMode: .constant(.bulk))
        }
    }
}
