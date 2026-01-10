import SwiftUI

/// Success view shown after completing a scan session
struct ScanSessionSuccessView: View {
    let cardCount: Int
    let totalValue: Double
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Success Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                }

                // Success Message
                VStack(spacing: 12) {
                    Text("Scan Session Complete!")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Successfully added \(cardCount) card\(cardCount == 1 ? "" : "s") to your inventory")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Stats Cards
                HStack(spacing: 16) {
                    SessionStatCard(
                        icon: "square.stack.3d.up.fill",
                        iconColor: .blue,
                        value: "\(cardCount)",
                        label: "Cards Scanned"
                    )

                    SessionStatCard(
                        icon: "dollarsign.circle.fill",
                        iconColor: .green,
                        value: "$\(String(format: "%.2f", totalValue))",
                        label: "Total Value"
                    )
                }
                .padding(.horizontal)

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        onDismiss()
                    } label: {
                        Text("View in Inventory")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        onDismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Session Stat Card
struct SessionStatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)

            VStack(spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - Preview
#Preview {
    ScanSessionSuccessView(
        cardCount: 23,
        totalValue: 487.50
    ) {
        // Dismiss
    }
}
