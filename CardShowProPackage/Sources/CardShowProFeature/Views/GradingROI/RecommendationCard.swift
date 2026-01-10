import SwiftUI

/// Displays "Grade It" or "Sell Raw" recommendation
struct RecommendationCard: View {
    let recommendation: GradingRecommendation

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Icon
            Image(systemName: recommendation.isPositive ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(recommendation.isPositive ? DesignSystem.Colors.success : DesignSystem.Colors.warning)

            // Title
            Text(recommendation.title)
                .font(DesignSystem.Typography.heading2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fontWeight(.bold)

            // Description
            Text(recommendation.description)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.lg)
        .background(
            recommendation.isPositive
                ? DesignSystem.Colors.success.opacity(0.1)
                : DesignSystem.Colors.warning.opacity(0.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .stroke(
                    recommendation.isPositive
                        ? DesignSystem.Colors.success.opacity(0.3)
                        : DesignSystem.Colors.warning.opacity(0.3),
                    lineWidth: 2
                )
        )
        .shadow(
            color: DesignSystem.Shadows.level3.color,
            radius: DesignSystem.Shadows.level3.radius,
            x: DesignSystem.Shadows.level3.x,
            y: DesignSystem.Shadows.level3.y
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        RecommendationCard(
            recommendation: .gradeIt(reason: "Strong ROI across multiple grades")
        )

        RecommendationCard(
            recommendation: .sellRaw
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}
