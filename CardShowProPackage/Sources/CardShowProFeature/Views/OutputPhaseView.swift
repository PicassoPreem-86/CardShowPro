import SwiftUI
import UIKit

/// Output phase view for previewing and copying generated listing
struct OutputPhaseView: View {
    @Bindable var state: ListingGeneratorState

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Success Header
                SuccessHeader()

                // SEO Score Card
                if let listing = state.generatedListing {
                    SEOScoreCard(score: listing.optimizationScore)
                }

                // Generated Title
                if let listing = state.generatedListing {
                    TitlePreviewCard(listing: listing)
                }

                // Generated Description
                if let listing = state.generatedListing {
                    DescriptionPreviewCard(listing: listing)
                }

                // SEO Keywords
                if let listing = state.generatedListing {
                    SEOKeywordsCard(keywords: listing.seoKeywords)
                }

                // Action Buttons
                ActionButtons(state: state)
            }
            .padding(DesignSystem.Spacing.md)
        }
        .overlay(alignment: .top) {
            if state.showCopyToast {
                ToastView(message: "Copied to clipboard!")
                    .padding(.top, DesignSystem.Spacing.md)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                state.showCopyToast = false
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Success Header

private struct SuccessHeader: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(DesignSystem.Colors.success)

            Text("Listing Generated!")
                .font(DesignSystem.Typography.heading2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Review your optimized listing below")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.lg)
    }
}

// MARK: - SEO Score Card

private struct SEOScoreCard: View {
    let score: Int

    private var scoreColor: Color {
        if score >= 80 { return DesignSystem.Colors.success }
        if score >= 60 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.error
    }

    private var scoreLabel: String {
        if score >= 80 { return "Excellent" }
        if score >= 60 { return "Good" }
        return "Needs Improvement"
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100.0)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(DesignSystem.Typography.heading2)
                        .foregroundStyle(scoreColor)
                    Text("/ 100")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            // Score Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("SEO Optimization Score")
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(scoreLabel)
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(scoreColor)
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                    .padding(.vertical, DesignSystem.Spacing.xxxs)
                    .background(scoreColor.opacity(0.2))
                    .clipShape(Capsule())

                Text("Your listing is optimized for search")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level3.color,
            radius: DesignSystem.Shadows.level3.radius,
            x: DesignSystem.Shadows.level3.x,
            y: DesignSystem.Shadows.level3.y
        )
    }
}

// MARK: - Title Preview Card

private struct TitlePreviewCard: View {
    let listing: GeneratedListing

    private var charCountColor: Color {
        if listing.isTitleOverLimit {
            return DesignSystem.Colors.error
        }
        if listing.titleCharCount > listing.platform.titleCharLimit - 10 {
            return DesignSystem.Colors.warning
        }
        return DesignSystem.Colors.success
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header
            HStack {
                Text("Title")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                // Character count
                Text("\(listing.titleCharCount) / \(listing.platform.titleCharLimit)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(charCountColor)
            }

            // Title Text
            Text(listing.title)
                .font(DesignSystem.Typography.bodyLarge)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

            if listing.isTitleOverLimit {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Title exceeds \(listing.platform.rawValue) character limit")
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundStyle(DesignSystem.Colors.error)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
    }
}

// MARK: - Description Preview Card

private struct DescriptionPreviewCard: View {
    let listing: GeneratedListing

    private var charCountColor: Color {
        if listing.isDescriptionOverLimit {
            return DesignSystem.Colors.error
        }
        if listing.descriptionCharCount > listing.platform.descriptionCharLimit - 100 {
            return DesignSystem.Colors.warning
        }
        return DesignSystem.Colors.success
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header
            HStack {
                Text("Description")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                // Character count
                Text("\(listing.descriptionCharCount) / \(listing.platform.descriptionCharLimit)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(charCountColor)
            }

            // Description Text
            Text(listing.description)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

            if listing.isDescriptionOverLimit {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Description exceeds \(listing.platform.rawValue) character limit")
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundStyle(DesignSystem.Colors.error)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
    }
}

// MARK: - SEO Keywords Card

private struct SEOKeywordsCard: View {
    let keywords: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("SEO Keywords")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            FlowLayout(spacing: DesignSystem.Spacing.xs) {
                ForEach(keywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, DesignSystem.Spacing.xxxs)
                        .background(DesignSystem.Colors.electricBlue.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(
            color: DesignSystem.Shadows.level2.color,
            radius: DesignSystem.Shadows.level2.radius,
            x: DesignSystem.Shadows.level2.x,
            y: DesignSystem.Shadows.level2.y
        )
    }
}

// MARK: - Action Buttons

private struct ActionButtons: View {
    @Bindable var state: ListingGeneratorState

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Copy Button
            Button {
                copyListing()
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.title3)
                    Text("Copy Listing")
                        .font(DesignSystem.Typography.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.thunderYellow)
                .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                .shadow(
                    color: DesignSystem.Shadows.level3.color,
                    radius: DesignSystem.Shadows.level3.radius,
                    x: DesignSystem.Shadows.level3.x,
                    y: DesignSystem.Shadows.level3.y
                )
            }

            // New Listing Button
            Button {
                withAnimation {
                    state.startNewListing()
                }
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Generate Another")
                        .font(DesignSystem.Typography.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.backgroundTertiary)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    private func copyListing() {
        guard let listing = state.generatedListing else { return }
        UIPasteboard.general.string = listing.fullText

        withAnimation {
            state.showCopyToast = true
        }
    }
}

// MARK: - Flow Layout

/// Simple flow layout for keyword tags
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Toast View (Reusing from SalesCalculatorView)
