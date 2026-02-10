import SwiftUI

struct DashboardActiveEventSection: View {
    var body: some View {
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
                .background(DesignSystem.Colors.cardBackground)
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
}
