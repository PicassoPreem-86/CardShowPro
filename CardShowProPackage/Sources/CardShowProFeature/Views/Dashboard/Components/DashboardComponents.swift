import SwiftUI

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)

                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .shadowElevation(isPressed ? 1 : 2)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(DesignSystem.Animation.springSnappy) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(DesignSystem.Animation.springSnappy) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(value)
                    .font(DesignSystem.Typography.heading4)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Business Metric Card
struct BusinessMetricCard: View {
    let label: String
    let value: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Event Metric Card
struct EventMetricCard: View {
    let label: String
    let value: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.heading4)
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(value)
                    .font(DesignSystem.Typography.heading4)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Performer Card
struct PerformerCard: View {
    let title: String
    let itemName: String
    let value: String
    let subtitle: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(iconColor)

                Spacer()
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text(itemName)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.xxxs) {
                    Text(value)
                        .font(DesignSystem.Typography.heading4)
                        .fontWeight(.bold)
                        .foregroundStyle(iconColor)

                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Portfolio Category Bar
struct PortfolioCategoryBar: View {
    let category: String
    let percentage: Double
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                Spacer()

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text("\(Int(percentage * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    // Filled bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? .white : .secondary)

                if isSelected {
                    Rectangle()
                        .fill(Color.cyan)
                        .frame(height: 3)
                        .clipShape(Capsule())
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 3)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Period Button
struct PeriodButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .black : .secondary)
                .frame(minWidth: 44, minHeight: 32)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Market Mover Card
struct MarketMoverCard: View {
    let cardName: String
    let setName: String
    let currentPrice: String
    let priceChange: String
    let percentChange: String
    let isPositive: Bool
    let imageURL: String

    var changeColor: Color {
        isPositive ? DesignSystem.Colors.cyan : DesignSystem.Colors.error
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Real Pokemon Card Image
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .empty:
                    // Loading placeholder with shimmer effect
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(DesignSystem.Colors.cardBackground)
                        .frame(width: 130, height: 180)
                        .overlay {
                            ProgressView()
                                .tint(DesignSystem.Colors.thunderYellow)
                        }
                        .skeletonLoader(isLoading: true)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 130, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                case .failure:
                    // Error placeholder
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(DesignSystem.Colors.cardBackground)
                        .frame(width: 130, height: 180)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                        }
                @unknown default:
                    EmptyView()
                }
            }

            // Card Details
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                // Card name with rarity
                HStack(spacing: DesignSystem.Spacing.xxxs) {
                    Text(cardName)
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)

                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(DesignSystem.Colors.thunderYellow)
                }

                // Set name
                Text(setName)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)

                Spacer()
                    .frame(height: DesignSystem.Spacing.xs)

                // Current price
                Text(currentPrice)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                // Price change percentage
                Text(percentChange)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(changeColor)

                // Gain amount
                Text("Gain: \(priceChange)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(changeColor)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.top, DesignSystem.Spacing.sm)
            .padding(.bottom, DesignSystem.Spacing.sm)
        }
        .frame(width: 130)
        .premiumCardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(cardName), \(setName), \(currentPrice), \(isPositive ? "up" : "down") \(percentChange)")
    }
}
