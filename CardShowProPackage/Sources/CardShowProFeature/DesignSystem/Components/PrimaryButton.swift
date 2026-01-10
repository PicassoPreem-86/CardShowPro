import SwiftUI

/// Primary action button with Thunder Yellow background
///
/// Usage:
/// ```swift
/// PrimaryButton("Submit") {
///     // Handle action
/// }
/// ```
@MainActor
public struct PrimaryButton: View {
    private let title: String
    private let icon: String?
    private let action: () -> Void

    /// Initialize primary button with title only
    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.icon = nil
        self.action = action
    }

    /// Initialize primary button with title and icon
    public init(_ title: String, icon: String, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(DesignSystem.Typography.labelLarge)
                }

                Text(title)
            }
            .primaryButtonStyle()
        }
        .buttonStyle(.plain)
    }
}
