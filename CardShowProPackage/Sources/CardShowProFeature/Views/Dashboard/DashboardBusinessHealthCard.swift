import SwiftUI
import SwiftData
import Charts

struct DashboardBusinessHealthCard: View {
    @Binding var selectedTab: String
    @Binding var selectedPeriod: String
    @Query private var inventoryCards: [InventoryCard]
    @Query private var transactions: [Transaction]
    @State private var analyticsService = AnalyticsService()

    private var activeCards: [InventoryCard] {
        inventoryCards.filter { $0.isAvailable }
    }

    private var totalValue: Double {
        activeCards.reduce(0.0) { $0 + $1.marketValue }
    }

    private var totalCost: Double {
        activeCards.reduce(0.0) { $0 + ($1.purchaseCost ?? 0) }
    }

    private var unrealizedProfit: Double {
        totalValue - totalCost
    }

    private var trendPoints: [TimeSeriesDataPoint] {
        let data = analyticsService.computeAnalytics(cards: inventoryCards, transactions: transactions)
        let points = data.portfolioTrend.dataPoints
        switch selectedPeriod {
        case "1D": return Array(points.suffix(1))
        case "7D": return Array(points.suffix(7))
        case "1M": return Array(points.suffix(30))
        case "3M": return Array(points.suffix(90))
        case "6M": return points
        case "MAX": return points
        default: return Array(points.suffix(30))
        }
    }

    private var recentChange: Double {
        let saleTxns = transactions.filter { $0.transactionType == .sale }
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentSales = saleTxns.filter { $0.date >= sevenDaysAgo }
        return recentSales.reduce(0.0) { $0 + $1.profit }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with toggle
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = selectedTab == "Overview" ? "Performance" : "Overview"
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(selectedTab)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(selectedTab == "Performance" ? 180 : 0))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Switch to \(selectedTab == "Overview" ? "Performance" : "Overview")")
                .accessibilityHint("Toggles between Overview and Performance tabs")

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 8, height: 8)
                    Text("USD")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)

            // Main content
            VStack(alignment: .leading, spacing: 8) {
                if selectedTab == "Overview" {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Portfolio")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            Text("Main")
                                .font(.subheadline)
                                .foregroundStyle(.cyan)
                                .fontWeight(.semibold)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(formatCurrency(totalValue))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }

                        let changeText = recentChange >= 0
                            ? "+\(formatCurrency(recentChange)) in the last 7 days"
                            : "\(formatCurrency(recentChange)) in the last 7 days"
                        Text(changeText)
                            .font(.subheadline)
                            .foregroundStyle(.cyan)
                    }
                    .frame(height: 140, alignment: .top)
                    .padding(.horizontal, 20)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Portfolio")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                Text("Main")
                                    .font(.subheadline)
                                    .foregroundStyle(.cyan)
                                    .fontWeight(.semibold)
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                Text("Unrealized")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(formatSignedCurrency(unrealizedProfit))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(unrealizedProfit >= 0 ? .cyan : DesignSystem.Colors.error)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }

                        HStack(spacing: 16) {
                            Text("Paid \(formatCurrency(totalCost))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Market Value \(formatCurrency(totalValue))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 140, alignment: .top)
                    .padding(.horizontal, 20)
                }

                // Real area chart using Swift Charts
                if trendPoints.count > 1 {
                    Chart(trendPoints) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.cyan.opacity(0.3),
                                    Color.cyan.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(Color.cyan)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 160)
                    .padding(.horizontal, 20)
                } else {
                    // Placeholder when no trend data
                    Rectangle()
                        .fill(DesignSystem.Colors.cardBackground.opacity(0.5))
                        .frame(height: 160)
                        .overlay {
                            Text("Add cards to see chart")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                        }
                        .padding(.horizontal, 20)
                }

                // Time period selector
                HStack(spacing: 16) {
                    ForEach(["1D", "7D", "1M", "3M", "6M", "MAX"], id: \.self) { period in
                        PeriodButton(title: period, isSelected: selectedPeriod == period) {
                            selectedPeriod = period
                        }
                        .accessibilityAddTraits(selectedPeriod == period ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    // MARK: - Formatting

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func formatSignedCurrency(_ value: Double) -> String {
        let formatted = formatCurrency(abs(value))
        return value >= 0 ? "+\(formatted)" : "-\(formatted)"
    }
}
