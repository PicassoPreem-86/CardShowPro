import SwiftUI

/// CardShowPro Design System
///
/// A comprehensive Pokemon-inspired design system providing consistent colors, spacing,
/// typography, shadows, and component styles throughout the application.
///
/// ## Usage
/// ```swift
/// Text("Hello")
///     .foregroundStyle(DesignSystem.Colors.thunderYellow)
///     .padding(DesignSystem.Spacing.md)
/// ```
@MainActor
public enum DesignSystem {

    // MARK: - Colors

    /// Pokemon-inspired color palette with Thunder Yellow and Electric Blue accents
    public enum Colors {
        // MARK: Primary Colors

        /// Thunder Yellow - Primary brand color (#FFD700)
        public static let thunderYellow = Color(hex: "#FFD700")

        /// Electric Blue - Secondary brand color (#00A8E8)
        public static let electricBlue = Color(hex: "#00A8E8")

        // MARK: Accent Colors

        /// Vibrant cyan for interactive elements (#00D9FF)
        public static let cyan = Color(hex: "#00D9FF")

        /// Gold/Amber accent for minimal UI elements (#FFB84D)
        public static let goldAmber = Color(hex: "#FFB84D")

        /// Success green (#34C759)
        public static let success = Color(hex: "#34C759")

        /// Warning orange (#FF9500)
        public static let warning = Color(hex: "#FF9500")

        /// Error red (#FF3B30)
        public static let error = Color(hex: "#FF3B30")

        /// Premium gold (#FFD700)
        public static let premium = thunderYellow

        // MARK: Background Colors

        /// Rich dark background - Primary (#0A0E27)
        public static let backgroundPrimary = Color(hex: "#0A0E27")

        /// Rich dark background - Secondary (#121629)
        public static let backgroundSecondary = Color(hex: "#121629")

        /// Rich dark background - Tertiary (#1A1F3A)
        public static let backgroundTertiary = Color(hex: "#1A1F3A")

        /// Card background with slight elevation (#1E2442)
        public static let cardBackground = Color(hex: "#1E2442")

        /// Premium card background with gradient (#2A2F4A)
        public static let premiumCardBackground = Color(hex: "#2A2F4A")

        // MARK: Text Colors

        /// Primary text color - High contrast white (#FFFFFF)
        public static let textPrimary = Color.white

        /// Secondary text color - Medium contrast gray (#8E94A8)
        public static let textSecondary = Color(hex: "#8E94A8")

        /// Tertiary text color - Low contrast gray (#5A5F73)
        public static let textTertiary = Color(hex: "#5A5F73")

        /// Disabled text color (#3E4359)
        public static let textDisabled = Color(hex: "#3E4359")

        // MARK: Border Colors

        /// Primary border color (#2E3548)
        public static let borderPrimary = Color(hex: "#2E3548")

        /// Secondary border color (#404659)
        public static let borderSecondary = Color(hex: "#404659")

        /// Accent border color - Electric Blue
        public static let borderAccent = electricBlue

        // MARK: Rarity Colors

        /// Common rarity (#C0C0C0)
        public static let rarityCommon = Color(hex: "#C0C0C0")

        /// Uncommon rarity (#5CB85C)
        public static let rarityUncommon = Color(hex: "#5CB85C")

        /// Rare rarity (#5BC0DE)
        public static let rarityRare = Color(hex: "#5BC0DE")

        /// Ultra Rare rarity (#D9534F)
        public static let rarityUltraRare = Color(hex: "#D9534F")

        /// Secret Rare rarity (#FFD700)
        public static let raritySecretRare = Color(hex: "#FFD700")

        // MARK: Gradient Presets

        /// Premium gold gradient
        public static let premiumGradient = LinearGradient(
            colors: [thunderYellow, Color(hex: "#FFA500")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Electric blue gradient
        public static let electricGradient = LinearGradient(
            colors: [electricBlue, cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Dark background gradient
        public static let backgroundGradient = LinearGradient(
            colors: [backgroundPrimary, backgroundSecondary],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Spacing

    /// 4pt spacing system for consistent layout
    public enum Spacing {
        /// Extra extra extra small - 4pt
        public static let xxxs: CGFloat = 4

        /// Extra extra small - 8pt
        public static let xxs: CGFloat = 8

        /// Extra small - 12pt
        public static let xs: CGFloat = 12

        /// Small - 16pt
        public static let sm: CGFloat = 16

        /// Medium - 20pt
        public static let md: CGFloat = 20

        /// Large - 24pt
        public static let lg: CGFloat = 24

        /// Extra large - 32pt
        public static let xl: CGFloat = 32

        /// Extra extra large - 40pt
        public static let xxl: CGFloat = 40

        /// Extra extra extra large - 48pt
        public static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    /// Corner radius scale for consistent rounding
    public enum CornerRadius {
        /// Extra small radius - 4pt
        public static let xs: CGFloat = 4

        /// Small radius - 8pt
        public static let sm: CGFloat = 8

        /// Medium radius - 12pt
        public static let md: CGFloat = 12

        /// Large radius - 16pt
        public static let lg: CGFloat = 16

        /// Extra large radius - 20pt
        public static let xl: CGFloat = 20

        /// Extra extra large radius - 24pt
        public static let xxl: CGFloat = 24

        /// Pill/Capsule shape
        public static let pill: CGFloat = 9999
    }

    // MARK: - Shadows

    /// Shadow and elevation system (levels 0-5)
    public enum Shadows {
        /// No shadow
        public static let level0: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            .clear, 0, 0, 0
        )

        /// Level 1 - Subtle elevation
        public static let level1: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            .black.opacity(0.05), 2, 0, 1
        )

        /// Level 2 - Light elevation
        public static let level2: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            .black.opacity(0.1), 4, 0, 2
        )

        /// Level 3 - Medium elevation
        public static let level3: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            .black.opacity(0.15), 8, 0, 4
        )

        /// Level 4 - High elevation
        public static let level4: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            .black.opacity(0.2), 12, 0, 6
        )

        /// Level 5 - Maximum elevation
        public static let level5: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            .black.opacity(0.3), 20, 0, 10
        )
    }

    // MARK: - Typography

    /// Typography hierarchy using SF Pro with custom styles
    /// All tokens use `relativeTo:` scaling so they respond to Dynamic Type settings
    public enum Typography {
        // MARK: Display Styles

        /// Display Large - 48pt Bold, scales with .largeTitle
        public static let displayLarge = Font.system(size: 48, weight: .bold, design: .rounded).leading(.tight)

        /// Display Medium - 40pt Bold, scales with .largeTitle
        public static let displayMedium = Font.system(size: 40, weight: .bold, design: .rounded).leading(.tight)

        /// Display Small - 32pt Bold, scales with .title
        public static let displaySmall = Font.system(size: 32, weight: .bold, design: .rounded)

        // MARK: Heading Styles

        /// Heading 1 - 28pt Semibold, scales with .title
        public static let heading1 = Font.system(.title, design: .default, weight: .semibold)

        /// Heading 2 - 24pt Semibold, scales with .title2
        public static let heading2 = Font.system(.title2, design: .default, weight: .semibold)

        /// Heading 3 - 20pt Semibold, scales with .title3
        public static let heading3 = Font.system(.title3, design: .default, weight: .semibold)

        /// Heading 4 - 18pt Semibold, scales with .headline
        public static let heading4 = Font.system(.headline, design: .default, weight: .semibold)

        // MARK: Body Styles

        /// Body Large - 17pt Regular, scales with .body
        public static let bodyLarge = Font.system(.body, design: .default, weight: .regular)

        /// Body - 15pt Regular, scales with .subheadline
        public static let body = Font.system(.subheadline, design: .default, weight: .regular)

        /// Body Small - 13pt Regular, scales with .footnote
        public static let bodySmall = Font.system(.footnote, design: .default, weight: .regular)

        // MARK: Label Styles

        /// Label Large - 15pt Medium, scales with .callout
        public static let labelLarge = Font.system(.callout, design: .default, weight: .medium)

        /// Label - 13pt Medium, scales with .footnote
        public static let label = Font.system(.footnote, design: .default, weight: .medium)

        /// Label Small - 11pt Medium, scales with .caption2
        public static let labelSmall = Font.system(.caption2, design: .default, weight: .medium)

        // MARK: Caption Styles

        /// Caption - 12pt Regular, scales with .caption
        public static let caption = Font.system(.caption, design: .default, weight: .regular)

        /// Caption Bold - 12pt Semibold, scales with .caption
        public static let captionBold = Font.system(.caption, design: .default, weight: .semibold)

        /// Caption Small - 10pt Regular, scales with .caption2
        public static let captionSmall = Font.system(.caption2, design: .default, weight: .regular)
    }

    // MARK: - Animation

    /// Animation timing constants for consistent motion
    public enum Animation {
        /// Instant - 0.1s
        public static let instant: Double = 0.1

        /// Fast - 0.2s
        public static let fast: Double = 0.2

        /// Normal - 0.3s
        public static let normal: Double = 0.3

        /// Moderate - 0.4s
        public static let moderate: Double = 0.4

        /// Slow - 0.5s
        public static let slow: Double = 0.5

        /// Deliberate - 0.7s
        public static let deliberate: Double = 0.7

        // MARK: Spring Presets

        /// Bouncy spring animation
        public static let springBouncy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6)

        /// Smooth spring animation
        public static let springSmooth = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)

        /// Snappy spring animation
        public static let springSnappy = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.7)
    }

    // MARK: - Component Styles

    /// Pre-defined component style configurations
    public enum ComponentStyles {

        // MARK: Button Styles

        public struct PrimaryButtonStyle {
            public static let backgroundColor = Colors.thunderYellow
            public static let foregroundColor = Colors.backgroundPrimary
            public static let font = Typography.labelLarge
            public static let cornerRadius = CornerRadius.md
            public static let padding = EdgeInsets(top: Spacing.sm, leading: Spacing.lg, bottom: Spacing.sm, trailing: Spacing.lg)
            public static let shadow = Shadows.level3
            public static let pressedScale: CGFloat = 0.95
            public static let pressedOpacity: CGFloat = 0.8
        }

        public struct SecondaryButtonStyle {
            public static let backgroundColor = Colors.backgroundTertiary
            public static let foregroundColor = Colors.textPrimary
            public static let borderColor = Colors.borderAccent
            public static let borderWidth: CGFloat = 2
            public static let font = Typography.labelLarge
            public static let cornerRadius = CornerRadius.md
            public static let padding = EdgeInsets(top: Spacing.sm, leading: Spacing.lg, bottom: Spacing.sm, trailing: Spacing.lg)
            public static let shadow = Shadows.level2
            public static let pressedScale: CGFloat = 0.97
        }

        // MARK: Card Styles

        public struct CardStyle {
            public static let backgroundColor = Colors.cardBackground
            public static let cornerRadius = CornerRadius.lg
            public static let padding = Spacing.md
            public static let shadow = Shadows.level2
        }

        public struct PremiumCardStyle {
            public static let backgroundColor = Colors.premiumCardBackground
            public static let cornerRadius = CornerRadius.xl
            public static let padding = Spacing.lg
            public static let shadow = Shadows.level4
            public static let borderColor = Colors.premium
            public static let borderWidth: CGFloat = 1
            public static let gradient = Colors.premiumGradient
        }

        // MARK: Input Styles

        public struct InputStyle {
            public static let backgroundColor = Colors.backgroundTertiary
            public static let foregroundColor = Colors.textPrimary
            public static let placeholderColor = Colors.textTertiary
            public static let borderColor = Colors.borderPrimary
            public static let focusedBorderColor = Colors.borderAccent
            public static let borderWidth: CGFloat = 1
            public static let cornerRadius = CornerRadius.md
            public static let padding = Spacing.sm
            public static let font = Typography.body
        }

        // MARK: Badge Styles

        public struct BadgeStyle {
            public static let font = Typography.captionBold
            public static let cornerRadius = CornerRadius.xs
            public static let padding = EdgeInsets(top: Spacing.xxxs, leading: Spacing.xxs, bottom: Spacing.xxxs, trailing: Spacing.xxs)
        }

        // MARK: Loading Styles

        public struct LoadingStyle {
            public static let backgroundColor = Colors.backgroundSecondary.opacity(0.95)
            public static let overlayColor = Color.black.opacity(0.75)
            public static let spinnerColor = Colors.cyan
            public static let textColor = Colors.textPrimary
            public static let cornerRadius = CornerRadius.lg
            public static let padding = Spacing.xl
            public static let shadow = Shadows.level5
        }

        // MARK: Skeleton Loader Styles

        public struct SkeletonStyle {
            public static let baseColor = Colors.backgroundTertiary
            public static let shimmerColor = Colors.backgroundTertiary.opacity(0.4)
            public static let animationDuration = Animation.slow
            public static let cornerRadius = CornerRadius.sm
        }
    }
}

// MARK: - Color Extension for Hex Initialization

extension Color {
    /// Initialize Color from hex string
    /// Supports both 6-digit (#RRGGBB) and 8-digit (#RRGGBBAA) hex codes
    ///
    /// - Parameter hex: Hex color string (with or without # prefix)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8: // RGBA (32-bit)
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
