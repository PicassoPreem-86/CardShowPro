import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Query private var inventoryCards: [InventoryCard]
    @State private var showCamera = false
    @State private var showSettings = false

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
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Actions Section
                    quickActionsSection

                    // Total Inventory Value
                    totalInventorySection

                    // Stats Grid
                    statsGridSection

                    // Top Items Grid
                    topItemsSection
                }
                .padding()
            }
            .navigationTitle("CardShow Pro")
            .navigationBarTitleDisplayMode(.large)
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

    // MARK: - Total Inventory Value
    private var totalInventorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Inventory Value")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("$\(String(format: "%.2f", totalValue))")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Stats Row
            HStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Total Items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let topCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("$\(String(format: "%.0f", topCard.estimatedValue))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                        Text("Highest Value")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Stats Grid
    private var statsGridSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatsCard(
                icon: "square.stack.3d.up.fill",
                iconColor: .blue,
                value: "\(totalCount)",
                label: "Total Cards"
            )

            StatsCard(
                icon: "dollarsign.circle.fill",
                iconColor: .green,
                value: "$\(String(format: "%.0f", totalValue))",
                label: "Total Value"
            )

            StatsCard(
                icon: "calendar",
                iconColor: .purple,
                value: recentCardsCount,
                label: "Added This Week"
            )

            StatsCard(
                icon: "chart.bar.fill",
                iconColor: .cyan,
                value: averageValue,
                label: "Avg Card Value"
            )
        }
    }

    private var recentCardsCount: String {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let count = inventoryCards.filter { $0.timestamp >= weekAgo }.count
        return "\(count)"
    }

    private var averageValue: String {
        guard !inventoryCards.isEmpty else { return "$0" }
        let avg = totalValue / Double(totalCount)
        return "$\(String(format: "%.0f", avg))"
    }

    // MARK: - Top Items
    private var topItemsSection: some View {
        let topCards = inventoryCards.sorted { $0.estimatedValue > $1.estimatedValue }.prefix(4)

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            if !topCards.isEmpty {
                ForEach(Array(topCards.enumerated()), id: \.element.id) { index, card in
                    TopItemCard(
                        title: "Top Card #\(index + 1)",
                        itemName: card.cardName,
                        value: "$\(String(format: "%.0f", card.estimatedValue))",
                        icon: "photo",
                        iconColor: topCardColor(for: index)
                    )
                }
            } else {
                TopItemCard(
                    title: "No Cards Yet",
                    itemName: "Start Scanning",
                    value: "$0",
                    icon: "camera.fill",
                    iconColor: .gray
                )
            }
        }
    }

    private func topCardColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .orange
        case 2: return .purple
        default: return .cyan
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

// MARK: - Top Item Card
struct TopItemCard: View {
    let title: String
    let itemName: String
    let value: String
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

                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}
