import SwiftUI

/// Premium card component with gold border and enhanced styling
///
/// Usage:
/// ```swift
/// PremiumCard {
///     VStack {
///         Text("Premium Content")
///     }
/// }
/// ```
@MainActor
public struct PremiumCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .premiumCardStyle()
    }
}
