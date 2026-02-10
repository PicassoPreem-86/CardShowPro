import SwiftUI

/// Search bar with gradient border (blue → orange)
/// Features optional back button on left and search input with magnifying glass icon
struct GradientSearchBar: View {
    @Binding var text: String
    let showBackButton: Bool
    let onBack: () -> Void
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    // Gradient colors matching reference design
    private let gradientColors: [Color] = [
        Color(red: 0.0, green: 0.75, blue: 1.0),   // Cyan blue #00BFFF
        Color(red: 1.0, green: 0.65, blue: 0.0)    // Orange #FFA500
    ]

    init(text: Binding<String>, showBackButton: Bool = true, onBack: @escaping () -> Void, onSubmit: @escaping () -> Void) {
        self._text = text
        self.showBackButton = showBackButton
        self.onBack = onBack
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: 12) {
            // Back button (conditionally shown)
            if showBackButton {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Go back")
            }

            // Search input with gradient border
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundStyle(.gray.opacity(0.8))

                TextField("Search card name...", text: $text)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit(onSubmit)

                // Clear button when text exists
                if !text.isEmpty {
                    Button {
                        text = ""
                        HapticManager.shared.light()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.gray.opacity(0.8))
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview("With Back Button") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            GradientSearchBar(
                text: .constant(""),
                showBackButton: true,
                onBack: {},
                onSubmit: {}
            )

            GradientSearchBar(
                text: .constant("pikachu"),
                showBackButton: true,
                onBack: {},
                onSubmit: {}
            )
        }
    }
}

#Preview("No Back Button") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            GradientSearchBar(
                text: .constant(""),
                showBackButton: false,
                onBack: {},
                onSubmit: {}
            )

            GradientSearchBar(
                text: .constant("charizard"),
                showBackButton: false,
                onBack: {},
                onSubmit: {}
            )
        }
    }
}
