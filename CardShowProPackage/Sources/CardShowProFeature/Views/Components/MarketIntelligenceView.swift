import SwiftUI
import Charts

/// Market intelligence panel showing 7-day price range and trends
/// Acts as "comps" data to help sellers make buying decisions
struct MarketIntelligenceView: View {
    let card: ScannedCard
    let onViewHistory: () -> Void

    private let accentGreen = Color(red: 0.5, green: 1.0, blue: 0.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with trend badge
            HStack {
                Text("Market Intelligence")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                // Trend badge
                if let change7d = card.priceChange7d {
                    trendBadge(change: change7d, trend: card.priceTrend)
                }
            }

            VStack(spacing: 0) {
                // 7-day price range section
                if let conditionPrices = card.conditionPrices,
                   let nmPrice = conditionPrices.nearMint {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("7-Day Price Range (Near Mint)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.gray)

                        // Price range bars
                        priceRangeSection(nmPrice: nmPrice)

                        // View history button
                        if card.priceHistory != nil {
                            Divider()
                                .background(Color.white.opacity(0.1))

                            Button(action: onViewHistory) {
                                HStack {
                                    Text("View 30-Day & 90-Day History")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(accentGreen)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(accentGreen)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }
                    }
                    .padding(16)
                } else {
                    // Loading or unavailable state
                    VStack(spacing: 12) {
                        if card.isLoadingPrice {
                            ProgressView()
                                .tint(accentGreen)
                            Text("Loading market data...")
                                .font(.system(size: 14))
                                .foregroundStyle(.gray)
                        } else {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 32))
                                .foregroundStyle(.gray.opacity(0.5))

                            Text("Market intelligence coming soon")
                                .font(.system(size: 14))
                                .foregroundStyle(.gray)

                            Text("7-day price range data will help you make better buying decisions")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 16)
                }
            }
            .background(Color(white: 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helper Views

    private func trendBadge(change: Double, trend: PriceTrend) -> some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.system(size: 10, weight: .semibold))

            Text(trend.displayText)
                .font(.system(size: 12, weight: .semibold))

            Text("\(change >= 0 ? "+" : "")\(change, specifier: "%.1f")%")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(trend == .rising ? .black : .white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(trend.color)
        .clipShape(Capsule())
    }

    private func priceRangeSection(nmPrice: Double) -> some View {
        VStack(spacing: 12) {
            // Current price (large)
            VStack(spacing: 4) {
                Text("Current Price")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)

                Text(nmPrice.formatted(.currency(code: "USD")))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(accentGreen)
            }

            // Note: JustTCG provides avgPrice7d, minPrice7d, maxPrice7d in the variant data
            // These are available through card.conditionPrices if fetched from JustTCG
            // For now, show a simplified view with the current price as the primary data point

            Text("Price trends and historical ranges help identify good buying opportunities")
                .font(.system(size: 11))
                .foregroundStyle(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With Trends") {
    MarketIntelligenceView(
        card: ScannedCard.mockCharizard,
        onViewHistory: {}
    )
    .padding()
    .background(Color.black)
}

#Preview("Loading") {
    MarketIntelligenceView(
        card: ScannedCard.mockLoading,
        onViewHistory: {}
    )
    .padding()
    .background(Color.black)
}

#Preview("No Data") {
    @Previewable @State var card = {
        let card = ScannedCard.mockPikachu
        card.conditionPrices = nil
        card.priceChange7d = nil
        return card
    }()

    MarketIntelligenceView(
        card: card,
        onViewHistory: {}
    )
    .padding()
    .background(Color.black)
}
#endif
