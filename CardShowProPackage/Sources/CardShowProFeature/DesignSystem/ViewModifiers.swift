import SwiftUI

// MARK: - Button Style Modifiers

/// Primary button style modifier
/// Applies Thunder Yellow background with dark text, shadow, and press animation
@MainActor
struct PrimaryButtonStyleModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .font(DesignSystem.ComponentStyles.PrimaryButtonStyle.font)
            .foregroundStyle(DesignSystem.ComponentStyles.PrimaryButtonStyle.foregroundColor)
            .padding(DesignSystem.ComponentStyles.PrimaryButtonStyle.padding)
            .background(DesignSystem.ComponentStyles.PrimaryButtonStyle.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.ComponentStyles.PrimaryButtonStyle.cornerRadius))
            .shadow(
                color: DesignSystem.ComponentStyles.PrimaryButtonStyle.shadow.color,
                radius: DesignSystem.ComponentStyles.PrimaryButtonStyle.shadow.radius,
                x: DesignSystem.ComponentStyles.PrimaryButtonStyle.shadow.x,
                y: DesignSystem.ComponentStyles.PrimaryButtonStyle.shadow.y
            )
            .scaleEffect(isPressed ? DesignSystem.ComponentStyles.PrimaryButtonStyle.pressedScale : 1.0)
            .opacity(isPressed ? DesignSystem.ComponentStyles.PrimaryButtonStyle.pressedOpacity : 1.0)
            .animation(DesignSystem.Animation.springSnappy, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

/// Secondary button style modifier
/// Applies bordered style with Electric Blue border
@MainActor
struct SecondaryButtonStyleModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .font(DesignSystem.ComponentStyles.SecondaryButtonStyle.font)
            .foregroundStyle(DesignSystem.ComponentStyles.SecondaryButtonStyle.foregroundColor)
            .padding(DesignSystem.ComponentStyles.SecondaryButtonStyle.padding)
            .background(DesignSystem.ComponentStyles.SecondaryButtonStyle.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.ComponentStyles.SecondaryButtonStyle.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.ComponentStyles.SecondaryButtonStyle.cornerRadius)
                    .stroke(DesignSystem.ComponentStyles.SecondaryButtonStyle.borderColor, lineWidth: DesignSystem.ComponentStyles.SecondaryButtonStyle.borderWidth)
            )
            .shadow(
                color: DesignSystem.ComponentStyles.SecondaryButtonStyle.shadow.color,
                radius: DesignSystem.ComponentStyles.SecondaryButtonStyle.shadow.radius,
                x: DesignSystem.ComponentStyles.SecondaryButtonStyle.shadow.x,
                y: DesignSystem.ComponentStyles.SecondaryButtonStyle.shadow.y
            )
            .scaleEffect(isPressed ? DesignSystem.ComponentStyles.SecondaryButtonStyle.pressedScale : 1.0)
            .animation(DesignSystem.Animation.springSnappy, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Card Style Modifiers

/// Standard card style modifier
/// Applies card background, corner radius, padding, and shadow
@MainActor
struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.ComponentStyles.CardStyle.padding)
            .background(DesignSystem.ComponentStyles.CardStyle.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.ComponentStyles.CardStyle.cornerRadius))
            .shadow(
                color: DesignSystem.ComponentStyles.CardStyle.shadow.color,
                radius: DesignSystem.ComponentStyles.CardStyle.shadow.radius,
                x: DesignSystem.ComponentStyles.CardStyle.shadow.x,
                y: DesignSystem.ComponentStyles.CardStyle.shadow.y
            )
    }
}

/// Premium card style modifier
/// Applies premium styling with gold border and enhanced shadow
@MainActor
struct PremiumCardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.ComponentStyles.PremiumCardStyle.padding)
            .background(DesignSystem.ComponentStyles.PremiumCardStyle.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.ComponentStyles.PremiumCardStyle.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.ComponentStyles.PremiumCardStyle.cornerRadius)
                    .stroke(DesignSystem.ComponentStyles.PremiumCardStyle.borderColor, lineWidth: DesignSystem.ComponentStyles.PremiumCardStyle.borderWidth)
            )
            .shadow(
                color: DesignSystem.ComponentStyles.PremiumCardStyle.shadow.color,
                radius: DesignSystem.ComponentStyles.PremiumCardStyle.shadow.radius,
                x: DesignSystem.ComponentStyles.PremiumCardStyle.shadow.x,
                y: DesignSystem.ComponentStyles.PremiumCardStyle.shadow.y
            )
    }
}

// MARK: - Shadow Elevation Modifier

/// Shadow elevation modifier
/// Applies consistent shadow based on elevation level (0-5)
@MainActor
struct ShadowElevationModifier: ViewModifier {
    let level: Int

    func body(content: Content) -> some View {
        let shadowData = shadowForLevel(level)
        return content
            .shadow(
                color: shadowData.color,
                radius: shadowData.radius,
                x: shadowData.x,
                y: shadowData.y
            )
    }

    private func shadowForLevel(_ level: Int) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        switch level {
        case 0: return DesignSystem.Shadows.level0
        case 1: return DesignSystem.Shadows.level1
        case 2: return DesignSystem.Shadows.level2
        case 3: return DesignSystem.Shadows.level3
        case 4: return DesignSystem.Shadows.level4
        case 5: return DesignSystem.Shadows.level5
        default: return DesignSystem.Shadows.level2
        }
    }
}

// MARK: - Skeleton Loader Modifier

/// Skeleton loading modifier
/// Shows shimmer loading effect when isLoading is true
@MainActor
struct SkeletonLoaderModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isLoading ? 0.0 : 1.0)
            .overlay {
                if isLoading {
                    SkeletonView()
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply primary button styling
    ///
    /// Usage:
    /// ```swift
    /// Text("Submit")
    ///     .primaryButtonStyle()
    /// ```
    public func primaryButtonStyle() -> some View {
        modifier(PrimaryButtonStyleModifier())
    }

    /// Apply secondary button styling
    ///
    /// Usage:
    /// ```swift
    /// Text("Cancel")
    ///     .secondaryButtonStyle()
    /// ```
    public func secondaryButtonStyle() -> some View {
        modifier(SecondaryButtonStyleModifier())
    }

    /// Apply standard card styling
    ///
    /// Usage:
    /// ```swift
    /// VStack { ... }
    ///     .cardStyle()
    /// ```
    public func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }

    /// Apply premium card styling
    ///
    /// Usage:
    /// ```swift
    /// VStack { ... }
    ///     .premiumCardStyle()
    /// ```
    public func premiumCardStyle() -> some View {
        modifier(PremiumCardStyleModifier())
    }

    /// Apply shadow elevation
    ///
    /// - Parameter level: Elevation level from 0 (no shadow) to 5 (maximum shadow)
    ///
    /// Usage:
    /// ```swift
    /// Text("Elevated")
    ///     .shadowElevation(3)
    /// ```
    public func shadowElevation(_ level: Int) -> some View {
        modifier(ShadowElevationModifier(level: level))
    }

    /// Apply skeleton loading effect
    ///
    /// - Parameter isLoading: Whether to show skeleton loader
    ///
    /// Usage:
    /// ```swift
    /// Text("Content")
    ///     .skeletonLoader(isLoading: viewModel.isLoading)
    /// ```
    public func skeletonLoader(isLoading: Bool) -> some View {
        modifier(SkeletonLoaderModifier(isLoading: isLoading))
    }
}
