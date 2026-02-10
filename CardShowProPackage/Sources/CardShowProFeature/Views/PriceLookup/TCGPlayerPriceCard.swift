import SwiftUI

struct TCGPlayerPriceCard: View {
    let pricing: DetailedTCGPlayerPricing

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)

                Text("TCGPlayer Pricing")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()
            }

            // Price Cards Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.sm) {
                ForEach(pricing.availableVariants, id: \.name) { variant in
                    variantPriceCard(variantName: variant.name, pricing: variant.pricing)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }

    private func variantPriceCard(variantName: String, pricing: DetailedTCGPlayerPricing.PriceBreakdown) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Variant Name
            Text(variantName)
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Divider()

            // Pricing Details
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                if let market = pricing.market {
                    HStack {
                        Text("Market:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text("$\(String(format: "%.2f", market))")
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(DesignSystem.Colors.success)
                    }
                }

                if let low = pricing.low {
                    HStack {
                        Text("Low:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text("$\(String(format: "%.2f", low))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                }

                if let mid = pricing.mid {
                    HStack {
                        Text("Mid:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text("$\(String(format: "%.2f", mid))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                }

                if let high = pricing.high {
                    HStack {
                        Text("High:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text("$\(String(format: "%.2f", high))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.borderSecondary, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(variantName), Market: \(pricing.market.map { "$\(String(format: "%.2f", $0))" } ?? "unavailable")")
    }
}
