import SwiftUI
import SwiftData

struct MarkAsListedView: View {
    let card: InventoryCard
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var listingPrice: String = ""
    @State private var selectedPlatform: ListingPlatform = .ebay
    @State private var showSaveError = false
    @FocusState private var priceFieldFocused: Bool

    enum ListingPlatform: String, CaseIterable, Identifiable {
        case ebay = "eBay"
        case tcgplayer = "TCGPlayer"
        case facebook = "Facebook Marketplace"
        case mercari = "Mercari"
        case local = "Local"
        case other = "Other"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .ebay: return "bag.fill"
            case .tcgplayer: return "creditcard.fill"
            case .facebook: return "person.2.fill"
            case .mercari: return "shippingbox.fill"
            case .local: return "mappin.circle.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }

    private var priceValue: Double {
        Double(listingPrice) ?? 0
    }

    private var canConfirm: Bool {
        priceValue > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    cardHeader
                    priceSection
                    platformSection
                    confirmButton
                }
                .padding(DesignSystem.Spacing.sm)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("List for Sale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.cyan)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { priceFieldFocused = false }
                }
            }
            .onAppear {
                listingPrice = String(format: "%.2f", card.marketValue)
            }
            .alert("Save Failed", isPresented: $showSaveError) {
                Button("Try Again") { confirmListing() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("The listing could not be saved. Please try again.")
            }
        }
    }

    // MARK: - Card Header

    private var cardHeader: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            if let image = card.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
            } else {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(DesignSystem.Colors.backgroundTertiary)
                    .frame(width: 50, height: 70)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(card.cardName)
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(card.setName)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Text("Market: $\(String(format: "%.2f", card.marketValue))")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.cyan)
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }

    // MARK: - Price Section

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("LISTING PRICE")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("$")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                TextField("0.00", text: $listingPrice)
                    .font(DesignSystem.Typography.heading2.monospacedDigit())
                    .keyboardType(.decimalPad)
                    .focused($priceFieldFocused)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(
                        priceFieldFocused ? DesignSystem.Colors.electricBlue : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }

    // MARK: - Platform Section

    private var platformSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("PLATFORM")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.xxs) {
                ForEach(ListingPlatform.allCases) { platform in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPlatform = platform
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: platform.icon)
                                .font(.caption)
                            Text(platform.rawValue)
                                .font(DesignSystem.Typography.captionBold)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(
                            selectedPlatform == platform
                                ? DesignSystem.Colors.electricBlue.opacity(0.2)
                                : DesignSystem.Colors.backgroundTertiary
                        )
                        .foregroundStyle(
                            selectedPlatform == platform
                                ? DesignSystem.Colors.electricBlue
                                : DesignSystem.Colors.textSecondary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                .stroke(
                                    selectedPlatform == platform
                                        ? DesignSystem.Colors.electricBlue.opacity(0.5)
                                        : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            confirmListing()
        } label: {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: "tag.fill")
                    .font(.headline)
                Text("List for Sale")
                    .font(DesignSystem.Typography.heading4)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.sm)
            .background(canConfirm ? DesignSystem.Colors.electricBlue : DesignSystem.Colors.electricBlue.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .disabled(!canConfirm)
        .padding(.top, DesignSystem.Spacing.xxs)
    }

    // MARK: - Confirm Listing

    private func confirmListing() {
        card.status = CardStatus.listed.rawValue
        card.platform = selectedPlatform.rawValue
        card.listingPrice = priceValue
        card.listedDate = Date()

        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            #if DEBUG
            print("Failed to save listing: \(error)")
            #endif
            showSaveError = true
        }
    }
}
