import SwiftUI
import SwiftData

struct CardDetailView: View {
    let card: InventoryCard
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false
    @State private var showZoomView = false
    @State private var showSellSheet = false
    @State private var showListedSheet = false
    @State private var showSaveError = false

    private var purchasePrice: Double {
        card.purchaseCost ?? 0
    }

    private var profit: Double {
        card.profit
    }

    private var roi: Double {
        card.roi
    }

    private var category: CardCategory { card.cardCategory }

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

                    // Lifecycle status & actions
                    lifecycleSection

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
        .sheet(isPresented: $showSellSheet) {
            SellCardView(card: card)
        }
        .sheet(isPresented: $showListedSheet) {
            MarkAsListedView(card: card)
        }
        .fullScreenCover(isPresented: $showZoomView) {
            if let image = card.image {
                ZoomableImageView(image: image)
            }
        }
        .alert("Save Failed", isPresented: $showSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The change could not be saved. Please try again.")
        }
    }

    // MARK: - Hero Image
    private var heroImage: some View {
        ZStack(alignment: .bottomTrailing) {
            if let image = card.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 400)
                    .clipped()
                    .onTapGesture {
                        showZoomView = true
                    }
                    .accessibilityLabel("Card image")
                    .accessibilityHint("Double tap to view full screen")

                // Tap to expand badge
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(DesignSystem.Typography.captionSmall)
                    Text("Tap to expand")
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, DesignSystem.Spacing.xs)
                .padding(.vertical, 6)
                .background(.black.opacity(0.6))
                .clipShape(Capsule())
                .padding(DesignSystem.Spacing.sm)
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
                    Text("$\(String(format: "%.2f", card.marketValue))")
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
                    value: category.rawValue
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
                    value: formatDate(card.acquiredDate)
                )

                Divider()
                    .padding(.leading, 44)

                HStack(spacing: 16) {
                    Image(systemName: confidenceIcon(for: card.confidence))
                        .font(.title3)
                        .foregroundStyle(confidenceColor(for: card.confidence))
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Confidence")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            Text("\(Int(card.confidence * 100))%")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)

                            // Confidence badge
                            Text(confidenceLevel(for: card.confidence))
                                .font(DesignSystem.Typography.captionBold)
                                .foregroundStyle(confidenceColor(for: card.confidence))
                                .padding(.horizontal, DesignSystem.Spacing.xxs)
                                .padding(.vertical, 2)
                                .background(confidenceColor(for: card.confidence).opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    Spacer()
                }
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

                Text("Card added via scanning. Market data accurate as of \(formatDate(card.acquiredDate)).")
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

    // MARK: - Lifecycle Section

    private var lifecycleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Current Status Header
            HStack {
                Text("STATUS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                StatusBadge(status: card.cardStatus)
            }

            VStack(spacing: 12) {
                switch card.cardStatus {
                case .inStock:
                    inStockActions
                case .listed:
                    listedInfo
                    listedActions
                case .sold:
                    soldDetails
                    soldActions
                case .shipped:
                    shippedDetails
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    // MARK: - In Stock Actions

    private var inStockActions: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Button {
                showListedSheet = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "tag.fill")
                        .font(.headline)
                    Text("Mark as Listed")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.electricBlue)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }

            Button {
                showSellSheet = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.headline)
                    Text("Mark as Sold")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.success)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    // MARK: - Listed Info

    private var listedInfo: some View {
        VStack(spacing: 8) {
            if let platform = card.platform {
                HStack {
                    Text("Platform")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(platform)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
            }

            if let listingPrice = card.listingPrice {
                HStack {
                    Text("Listing Price")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", listingPrice))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.electricBlue)
                }
            }

            if let listedDate = card.listedDate {
                HStack {
                    Text("Listed On")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatDate(listedDate))
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }

            Divider()
        }
    }

    // MARK: - Listed Actions

    private var listedActions: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Button {
                showSellSheet = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.headline)
                    Text("Mark as Sold")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.success)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }

            Button {
                returnToStock()
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.subheadline)
                    Text("Return to Stock")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    // MARK: - Sold Details

    private var soldDetails: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(DesignSystem.Colors.success)
                Text("SOLD")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.success)
                Spacer()
                if let soldDate = card.soldDate {
                    Text(formatDate(soldDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            if let soldPrice = card.soldPrice {
                HStack {
                    Text("Sold Price")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", soldPrice))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.success)
                }
            }

            if let platform = card.platform {
                HStack {
                    Text("Platform")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(platform)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
            }

            if let saleProfit = card.saleProfit {
                Divider()
                HStack {
                    Text("Profit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(saleProfit >= 0 ? "+$\(String(format: "%.2f", saleProfit))" : "-$\(String(format: "%.2f", abs(saleProfit)))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(saleProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                }
            }
        }
    }

    // MARK: - Sold Actions

    private var soldActions: some View {
        Button {
            markAsShipped()
        } label: {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: "paperplane.fill")
                    .font(.headline)
                Text("Mark as Shipped")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    // MARK: - Shipped Details

    private var shippedDetails: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Text("SHIPPED")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.success)
                Text("Complete")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.success)
            }

            Divider()

            if let soldPrice = card.soldPrice {
                HStack {
                    Text("Sold Price")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", soldPrice))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.success)
                }
            }

            if let platform = card.platform {
                HStack {
                    Text("Platform")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(platform)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
            }

            if let soldDate = card.soldDate {
                HStack {
                    Text("Sold Date")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatDate(soldDate))
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }

            if let saleProfit = card.saleProfit {
                Divider()
                HStack {
                    Text("Profit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(saleProfit >= 0 ? "+$\(String(format: "%.2f", saleProfit))" : "-$\(String(format: "%.2f", abs(saleProfit)))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(saleProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                }
            }
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
    private var categoryColor: Color { category.color }

    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func returnToStock() {
        card.status = CardStatus.inStock.rawValue
        card.platform = nil
        card.listingPrice = nil
        card.listedDate = nil

        do {
            try modelContext.save()
            HapticManager.shared.light()
        } catch {
            #if DEBUG
            print("Failed to save return to stock: \(error)")
            #endif
            showSaveError = true
        }
    }

    private func markAsShipped() {
        card.status = CardStatus.shipped.rawValue

        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            #if DEBUG
            print("Failed to save shipped status: \(error)")
            #endif
            showSaveError = true
        }
    }

    private func deleteCard() {
        modelContext.delete(card)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            #if DEBUG
            print("Failed to save after delete: \(error)")
            #endif
            showSaveError = true
        }
    }

    // MARK: - Confidence Helpers
    private func confidenceLevel(for confidence: Double) -> String {
        switch confidence {
        case 0.9...1.0: return "Very High"
        case 0.75..<0.9: return "High"
        case 0.5..<0.75: return "Medium"
        default: return "Low"
        }
    }

    private func confidenceColor(for confidence: Double) -> Color {
        switch confidence {
        case 0.9...1.0: return DesignSystem.Colors.success
        case 0.75..<0.9: return DesignSystem.Colors.electricBlue
        case 0.5..<0.75: return DesignSystem.Colors.warning
        default: return DesignSystem.Colors.error
        }
    }

    private func confidenceIcon(for confidence: Double) -> String {
        switch confidence {
        case 0.9...1.0: return "checkmark.seal.fill"
        case 0.75..<0.9: return "checkmark.circle.fill"
        case 0.5..<0.75: return "exclamationmark.triangle.fill"
        default: return "xmark.octagon.fill"
        }
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
