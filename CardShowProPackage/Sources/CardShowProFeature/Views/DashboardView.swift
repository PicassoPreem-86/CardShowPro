import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var showCamera = false
    @State private var showSettings = false

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
                Text("$24,580")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                    Text("+13.2%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.green)
            }

            // Stats Row
            HStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("1,793")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Total Items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("$26,100")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                    Text("Monthly Sales")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.caption2)
                        Text("+$3,450")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.green)
                    Text("vs Last Month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                value: "1,247",
                label: "Total Raw Cards"
            )

            StatsCard(
                icon: "sparkle",
                iconColor: .purple,
                value: "342",
                label: "Total Graded Cards"
            )

            StatsCard(
                icon: "shippingbox.fill",
                iconColor: .purple,
                value: "48",
                label: "Total Sealed Products"
            )

            StatsCard(
                icon: "square.grid.2x2.fill",
                iconColor: .cyan,
                value: "156",
                label: "Total Misc"
            )
        }
    }

    // MARK: - Top Items
    private var topItemsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            TopItemCard(
                title: "Top Raw Card",
                itemName: "Charizard ex",
                value: "$450",
                icon: "photo",
                iconColor: .orange
            )

            TopItemCard(
                title: "Top Graded",
                itemName: "Charizard\nPSA 10",
                value: "$8,500",
                icon: "star.fill",
                iconColor: .yellow
            )

            TopItemCard(
                title: "Top Sealed Product",
                itemName: "151 Booster Box",
                value: "$285",
                icon: "shippingbox.fill",
                iconColor: .purple
            )

            TopItemCard(
                title: "Top Misc Seller",
                itemName: "Card Sleeves",
                value: "$25",
                icon: "briefcase.fill",
                iconColor: .cyan
            )
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
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
