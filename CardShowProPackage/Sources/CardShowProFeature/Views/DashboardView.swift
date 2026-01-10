import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Query private var inventoryCards: [InventoryCard]
    @State private var showCamera = false
    @State private var showSettings = false
    @State private var selectedPeriod = "1M"
    @State private var selectedTab = "Overview"

    // Calculated stats from inventory
    private var totalValue: Double {
        inventoryCards.reduce(0) { $0 + $1.estimatedValue }
    }

    private var totalCount: Int {
        inventoryCards.count
    }

    private var topCard: InventoryCard? {
        inventoryCards.max(by: { $0.estimatedValue < $1.estimatedValue })
    }

    var body: some View {
        @Bindable var appState = appState

        NavigationStack {
            VStack(spacing: 0) {
                // Quick Actions Section - Fixed at top
                quickActionsSection
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 4)
                    .background(Color(.systemBackground))

                // Scrollable content below
                ScrollView {
                    VStack(spacing: 24) {
                        // Business Health Overview
                        businessHealthSection

                        // Active Event Status (Show Mode)
                        if appState.isShowModeActive {
                            activeEventSection
                        }

                        // Category Breakdown
                        categoryBreakdownSection
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(isShowModeActive: $appState.isShowModeActive)
            }
        }
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Trade\nAnalyzer",
                    icon: "arrow.triangle.2.circlepath",
                    color: .blue
                ) {
                    // Action
                }

                QuickActionButton(
                    title: "Pro Market\nAgent",
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    color: .cyan
                ) {
                    // Action
                }

                QuickActionButton(
                    title: "Sales\nCalculator",
                    icon: "dollarsign.circle.fill",
                    color: .green
                ) {
                    // Action
                }

                QuickActionButton(
                    title: "Add",
                    icon: "plus",
                    color: Color(.systemGray4)
                ) {
                    // Action
                }
            }
        }
    }

    // MARK: - Business Health Overview
    private var businessHealthSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with toggle
            HStack {
                // Toggle button
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

                Spacer()

                // Currency indicator
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
                    // Overview tab content
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
                            Text("$18,920")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Button(action: {}) {
                                Image(systemName: "eye.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text("+$1,247.50 in the last 7 days")
                            .font(.subheadline)
                            .foregroundStyle(.cyan)
                    }
                    .frame(height: 140, alignment: .top)
                    .padding(.horizontal, 20)
                } else {
                    // Performance tab content
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

                            // Unrealized dropdown
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
                            Text("+$356.91")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.cyan)

                            Button(action: {}) {
                                Image(systemName: "eye.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack(spacing: 16) {
                            Text("Paid $1,295.00")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Market Value $1,651.91")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 140, alignment: .top)
                    .padding(.horizontal, 20)
                }

                // Area chart placeholder
                VStack(spacing: 0) {
                    GeometryReader { geometry in
                        ZStack(alignment: .bottom) {
                            // Gradient fill
                            Path { path in
                                let width = geometry.size.width
                                let height = geometry.size.height

                                path.move(to: CGPoint(x: 0, y: height * 0.7))
                                path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.5))
                                path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.3))
                                path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.4))
                                path.addLine(to: CGPoint(x: width, y: height * 0.2))
                                path.addLine(to: CGPoint(x: width, y: height))
                                path.addLine(to: CGPoint(x: 0, y: height))
                                path.closeSubpath()
                            }
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.cyan.opacity(0.3),
                                        Color.cyan.opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            // Line
                            Path { path in
                                let width = geometry.size.width
                                let height = geometry.size.height

                                path.move(to: CGPoint(x: 0, y: height * 0.7))
                                path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.5))
                                path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.3))
                                path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.4))
                                path.addLine(to: CGPoint(x: width, y: height * 0.2))
                            }
                            .stroke(Color.cyan, lineWidth: 2.5)
                        }
                    }
                    .frame(height: 160)
                }
                .padding(.horizontal, 20)

                // Time period selector
                HStack(spacing: 16) {
                    ForEach(["1D", "7D", "1M", "3M", "6M", "MAX"], id: \.self) { period in
                        PeriodButton(title: period, isSelected: selectedPeriod == period) {
                            selectedPeriod = period
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    // MARK: - Active Event Status
    private var activeEventSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Event")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Card Show at Convention Center")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Started 2h 15m ago")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "bolt.circle.fill")
                        .font(.title)
                        .foregroundStyle(.orange)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 5)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    EventMetricCard(
                        label: "Cards Scanned",
                        value: "47",
                        icon: "camera.fill",
                        iconColor: .blue
                    )

                    EventMetricCard(
                        label: "Event Sales",
                        value: "$892",
                        icon: "cart.fill",
                        iconColor: .green
                    )

                    EventMetricCard(
                        label: "Event Profit",
                        value: "$234",
                        icon: "chart.bar.fill",
                        iconColor: .orange
                    )

                    EventMetricCard(
                        label: "Transactions",
                        value: "12",
                        icon: "creditcard.fill",
                        iconColor: .purple
                    )
                }
            }
        }
    }

    // MARK: - Sales Performance
    private var salesPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sales Performance")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatsCard(
                    icon: "dollarsign.circle.fill",
                    iconColor: .green,
                    value: "$2,340",
                    label: "Revenue This Week"
                )

                StatsCard(
                    icon: "cart.fill",
                    iconColor: .blue,
                    value: "18",
                    label: "Transactions"
                )

                StatsCard(
                    icon: "chart.bar.fill",
                    iconColor: .cyan,
                    value: "$130",
                    label: "Average Sale"
                )

                StatsCard(
                    icon: "percent",
                    iconColor: .orange,
                    value: "34%",
                    label: "Profit Margin"
                )
            }
        }
    }

    // MARK: - Inventory Health
    private var inventoryHealthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inventory Health")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatsCard(
                    icon: "square.stack.3d.up.fill",
                    iconColor: .blue,
                    value: "$18,920",
                    label: "Total Value"
                )

                StatsCard(
                    icon: "dollarsign.square.fill",
                    iconColor: .purple,
                    value: "$12,450",
                    label: "Cost Basis"
                )

                StatsCard(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: .cyan,
                    value: "2.3x",
                    label: "Turnover Rate"
                )

                StatsCard(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    value: "12",
                    label: "Dead Stock Alert"
                )
            }
        }
    }

    // MARK: - Top Business Performers
    private var topPerformersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Performers")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                PerformerCard(
                    title: "Most Profitable",
                    itemName: "Charizard VMAX",
                    value: "$450",
                    subtitle: "profit",
                    icon: "trophy.fill",
                    iconColor: .yellow
                )

                PerformerCard(
                    title: "Best Moving",
                    itemName: "Graded PSA 10s",
                    value: "15",
                    subtitle: "sold this month",
                    icon: "flame.fill",
                    iconColor: .orange
                )

                PerformerCard(
                    title: "Top Set",
                    itemName: "Base Set Unlimited",
                    value: "$1,200",
                    subtitle: "total profit",
                    icon: "star.fill",
                    iconColor: .cyan
                )

                PerformerCard(
                    title: "Best Source",
                    itemName: "Local Pickups",
                    value: "67%",
                    subtitle: "margin",
                    icon: "location.fill",
                    iconColor: .green
                )
            }
        }
    }

    // MARK: - Market Movers
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Market Movers")
                .font(.headline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    MarketMoverCard(
                        cardName: "Charizard VMAX",
                        setName: "Champion's Path",
                        currentPrice: "$450.00",
                        priceChange: "+$45.50",
                        percentChange: "+11.2%",
                        isPositive: true,
                        imageURL: "https://assets.pokemon.com/static-assets/content-assets/cms2/img/cards/web/SWSH35/SWSH35_EN_74.png"
                    )

                    MarketMoverCard(
                        cardName: "Pikachu VMAX",
                        setName: "Vivid Voltage",
                        currentPrice: "$125.00",
                        priceChange: "+$12.50",
                        percentChange: "+8.5%",
                        isPositive: true,
                        imageURL: "https://assets.pokemon.com/static-assets/content-assets/cms2/img/cards/web/SWSH4/SWSH4_EN_44.png"
                    )

                    MarketMoverCard(
                        cardName: "Lugia V",
                        setName: "Silver Tempest",
                        currentPrice: "$89.00",
                        priceChange: "-$5.00",
                        percentChange: "-5.3%",
                        isPositive: false,
                        imageURL: "https://assets.pokemon.com/static-assets/content-assets/cms2/img/cards/web/SWSH12/SWSH12_EN_186.png"
                    )

                    MarketMoverCard(
                        cardName: "Mewtwo GX",
                        setName: "Shining Legends",
                        currentPrice: "$215.00",
                        priceChange: "+$28.00",
                        percentChange: "+15.0%",
                        isPositive: true,
                        imageURL: "https://assets.pokemon.com/static-assets/content-assets/cms2/img/cards/web/SM35/SM35_EN_78.png"
                    )

                    MarketMoverCard(
                        cardName: "Rayquaza VMAX",
                        setName: "Evolving Skies",
                        currentPrice: "$340.00",
                        priceChange: "+$52.00",
                        percentChange: "+18.1%",
                        isPositive: true,
                        imageURL: "https://assets.pokemon.com/static-assets/content-assets/cms2/img/cards/web/SWSH7/SWSH7_EN_111.png"
                    )
                }
                .padding(.horizontal)
            }
        }
    }

}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
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
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - Event Metric Card
struct EventMetricCard: View {
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
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(itemName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(iconColor)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
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
        isPositive ? Color.cyan : Color.red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Real Pokemon Card Image
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .empty:
                    // Loading placeholder
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                        .frame(width: 130, height: 180)
                        .overlay {
                            ProgressView()
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 130, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                case .failure:
                    // Error placeholder
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                        .frame(width: 130, height: 180)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    EmptyView()
                }
            }

            // Card Details
            VStack(alignment: .leading, spacing: 6) {
                // Card name with rarity
                HStack(spacing: 4) {
                    Text(cardName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.yellow)
                }

                // Set name
                Text(setName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()
                    .frame(height: 6)

                // Current price
                Text(currentPrice)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                // Price change percentage
                Text(percentChange)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(changeColor)

                // Gain amount
                Text("Gain: \(priceChange)")
                    .font(.caption)
                    .foregroundStyle(changeColor)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .frame(width: 130)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}
