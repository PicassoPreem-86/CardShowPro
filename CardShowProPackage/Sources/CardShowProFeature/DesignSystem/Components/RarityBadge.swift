import SwiftUI

/// Rarity badge component for displaying card rarity levels
///
/// Usage:
/// ```swift
/// RarityBadge(rarity: .ultraRare)
/// ```
@MainActor
public struct RarityBadge: View {
    public enum Rarity: String, CaseIterable {
        case common = "Common"
        case uncommon = "Uncommon"
        case rare = "Rare"
        case ultraRare = "Ultra Rare"
        case secretRare = "Secret Rare"

        var color: Color {
            switch self {
            case .common: return DesignSystem.Colors.rarityCommon
            case .uncommon: return DesignSystem.Colors.rarityUncommon
            case .rare: return DesignSystem.Colors.rarityRare
            case .ultraRare: return DesignSystem.Colors.rarityUltraRare
            case .secretRare: return DesignSystem.Colors.raritySecretRare
            }
        }

        var icon: String {
            switch self {
            case .common: return "circle.fill"
            case .uncommon: return "diamond.fill"
            case .rare: return "star.fill"
            case .ultraRare: return "sparkles"
            case .secretRare: return "crown.fill"
            }
        }
    }

    private let rarity: Rarity

    public init(rarity: Rarity) {
        self.rarity = rarity
    }

    public var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxxs) {
            Image(systemName: rarity.icon)
                .font(DesignSystem.Typography.captionSmall)

            Text(rarity.rawValue)
                .font(DesignSystem.ComponentStyles.BadgeStyle.font)
        }
        .foregroundStyle(rarity.color)
        .padding(DesignSystem.ComponentStyles.BadgeStyle.padding)
        .background(rarity.color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.ComponentStyles.BadgeStyle.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.ComponentStyles.BadgeStyle.cornerRadius)
                .stroke(rarity.color.opacity(0.3), lineWidth: 1)
        )
    }
}
