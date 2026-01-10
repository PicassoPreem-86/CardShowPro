import SwiftUI
import SwiftData

struct CardDetailView: View {
    let card: InventoryCard
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false

    // Mock data for demo - will come from card in future
    private var purchasePrice: Double {
        card.estimatedValue * 0.65 // Mock: 65% of market value
    }

    private var profit: Double {
        card.estimatedValue - purchasePrice
    }

    private var roi: Double {
        (profit / purchasePrice) * 100
    }

    private var category: String {
        // Mock category based on confidence - will be real field later
        if card.confidence > 0.9 {
            return "Graded"
        } else if card.estimatedValue > 200 {
            return "Raw Singles"
        } else if card.cardName.contains("Box") || card.cardName.contains("Pack") {
            return "Sealed"
        } else {
            return "Raw Singles"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Card Image
                heroImage

                // Content Sections
                VStack(spacing: 20) {
                    // Value & Pricing
                    valueSectionCard

                    // Details
                    detailsSectionCard

                    // Notes
                    if !card.cardNumber.isEmpty {
                        notesSectionCard
                    }

                    // Actions
                    actionsSection
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(card.cardName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Text("Edit")
                        .fontWeight(.semibold)
                        .foregroundStyle(.cyan)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddEditItemView(cardToEdit: card)
        }
        .alert("Delete Card", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteCard()
            }
        } message: {
            Text("Are you sure you want to delete \(card.cardName)? This action cannot be undone.")
        }
    }

    // MARK: - Hero Image
    private var heroImage: some View {
        ZStack {
            if let image = card.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 400)
                    .clipped()
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.systemGray6),
                                Color(.systemGray5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 400)
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            Text("No Image Available")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
            }
        }
    }

    // MARK: - Value Section
    private var valueSectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("VALUE & PRICING")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                // Market Value - Hero
                VStack(alignment: .leading, spacing: 4) {
                    Text("Market Value")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("$\(String(format: "%.2f", card.estimatedValue))")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Purchase Price & Profit
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Purchase Price")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("$\(String(format: "%.2f", purchasePrice))")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("$\(String(format: "%.2f", profit))")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // ROI Badge
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                        Text("ROI: \(String(format: "%.0f", roi))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.15))
                    )
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    // MARK: - Details Section
    private var detailsSectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DETAILS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                DetailRow(
                    icon: "square.stack.3d.up.fill",
                    iconColor: categoryColor,
                    label: "Category",
                    value: category
                )

                Divider()
                    .padding(.leading, 44)

                DetailRow(
                    icon: "rectangle.stack.fill",
                    iconColor: .blue,
                    label: "Set",
                    value: card.setName
                )

                Divider()
                    .padding(.leading, 44)

                DetailRow(
                    icon: "number",
                    iconColor: .purple,
                    label: "Card Number",
                    value: card.cardNumber
                )

                Divider()
                    .padding(.leading, 44)

                DetailRow(
                    icon: "calendar",
                    iconColor: .orange,
                    label: "Date Added",
                    value: formatDate(card.timestamp)
                )

                Divider()
                    .padding(.leading, 44)

                DetailRow(
                    icon: "sparkle",
                    iconColor: .cyan,
                    label: "Confidence",
                    value: "\(Int(card.confidence * 100))%"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    // MARK: - Notes Section
    private var notesSectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("NOTES")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Additional Information")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                Text("Card added via scanning. Market data accurate as of \(formatDate(card.timestamp)).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Share Button
            Button {
                showShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline)
                    Text("Share Card Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.cyan)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Delete Button
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.headline)
                    Text("Delete Card")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helper Views
    private var categoryColor: Color {
        switch category {
        case "Graded": return .yellow
        case "Raw Singles": return .purple
        case "Sealed": return .orange
        case "Misc": return .gray
        default: return .blue
        }
    }

    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func deleteCard() {
        modelContext.delete(card)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }

            Spacer()
        }
    }
}
