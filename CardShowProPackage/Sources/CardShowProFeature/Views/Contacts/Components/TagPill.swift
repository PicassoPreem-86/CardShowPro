import SwiftUI

/// Tag display pill (read-only for now)
/// Features: Capsule shape with backgroundTertiary, used to display tags on contacts
@MainActor
struct TagPill: View {
    let tag: String

    var body: some View {
        Text(tag)
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .padding(.vertical, DesignSystem.Spacing.xxxs + 2) // 6pt vertical
            .background(DesignSystem.Colors.backgroundTertiary)
            .clipShape(Capsule())
    }
}

// MARK: - Previews

#Preview("Single Tag") {
    TagPill(tag: "vintage")
        .padding()
        .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Multiple Tags") {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
        Text("Contact Tags")
            .font(DesignSystem.Typography.heading3)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

        // Horizontal flow layout
        FlowLayout(spacing: DesignSystem.Spacing.xs) {
            TagPill(tag: "vintage")
            TagPill(tag: "pokemon")
            TagPill(tag: "high-value")
            TagPill(tag: "collector")
            TagPill(tag: "regular")
        }
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Long Tag Names") {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
        TagPill(tag: "short")
        TagPill(tag: "medium-length-tag")
        TagPill(tag: "very-long-tag-name-example")
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("In Card Context") {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
        // Contact name
        Text("John Smith")
            .font(DesignSystem.Typography.heading2)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

        // Tags section
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("TAGS")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            FlowLayout(spacing: DesignSystem.Spacing.xs) {
                TagPill(tag: "vintage")
                TagPill(tag: "pokemon")
                TagPill(tag: "vip")
            }
        }
    }
    .padding(DesignSystem.Spacing.md)
    .background(DesignSystem.Colors.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

// MARK: - Flow Layout Helper

/// Simple flow layout for wrapping tags
private struct FlowLayout: Layout {
    var spacing: CGFloat

    nonisolated func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    nonisolated func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)

                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += subviewSize.width + spacing
                lineHeight = max(lineHeight, subviewSize.height)
            }

            size = CGSize(
                width: maxWidth,
                height: currentY + lineHeight
            )
        }
    }
}
