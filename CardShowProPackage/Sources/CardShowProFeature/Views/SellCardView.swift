import SwiftUI
import SwiftData

struct SellCardView: View {
    let card: InventoryCard
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var salePrice: String = ""
    @State private var shippingCost: String = "0"
    @State private var buyerName: String = ""
    @State private var eventName: String = ""
    @State private var selectedPlatform: SellPlatform = .ebay
    @State private var selectedPaymentMethod: PaymentMethod = .cash
    @State private var showSaveError = false
    @State private var platformPreferences = UserPlatformPreferences()
    @State private var showContactSuggestions = false
    @Query(sort: \Contact.name) private var allContacts: [Contact]
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case salePrice, shipping, buyer, event
    }

    /// Contacts matching the buyer name input
    private var matchingContacts: [Contact] {
        guard !buyerName.isEmpty else { return [] }
        let query = buyerName.lowercased()
        return allContacts.filter { $0.name.lowercased().contains(query) }.prefix(5).map { $0 }
    }

    /// Whether this buyer is a repeat customer (has previous transactions)
    private var isRepeatCustomer: Bool {
        guard !buyerName.isEmpty else { return false }
        let query = buyerName.lowercased()
        return allContacts.contains { contact in
            contact.name.lowercased() == query && contact.contactTypeEnum == .customer
        }
    }

    enum SellPlatform: String, CaseIterable, Identifiable {
        case ebay = "eBay"
        case tcgplayer = "TCGPlayer"
        case facebook = "Facebook Marketplace"
        case whatnot = "Whatnot"
        case mercari = "Mercari"
        case heritageAuctions = "Heritage Auctions"
        case cardmarket = "Cardmarket"
        case localCash = "Local/Cash"
        case event = "Event"
        case other = "Other"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .ebay: return "bag.fill"
            case .tcgplayer: return "creditcard.fill"
            case .facebook: return "person.2.fill"
            case .whatnot: return "video.fill"
            case .mercari: return "shippingbox.fill"
            case .heritageAuctions: return "building.columns.fill"
            case .cardmarket: return "globe.europe.africa.fill"
            case .localCash: return "banknote.fill"
            case .event: return "ticket.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }

        var fees: PlatformFees {
            switch self {
            case .ebay:
                return PlatformFees(
                    platformFeePercentage: 0.1295,
                    paymentFeePercentage: 0.029,
                    paymentFeeFixed: 0.30,
                    description: "eBay Managed Payments"
                )
            case .tcgplayer:
                return PlatformFees(
                    platformFeePercentage: 0.1285,
                    paymentFeePercentage: 0.029,
                    paymentFeeFixed: 0.30,
                    description: "TCGPlayer Mid-Tier"
                )
            case .facebook:
                return PlatformFees(
                    platformFeePercentage: 0.05,
                    paymentFeePercentage: 0.00,
                    paymentFeeFixed: 0.40,
                    description: "Facebook Checkout"
                )
            case .whatnot:
                return PlatformFees(
                    platformFeePercentage: 0.08,
                    paymentFeePercentage: 0.029,
                    paymentFeeFixed: 0.30,
                    description: "Whatnot Live Sales"
                )
            case .mercari:
                return PlatformFees(
                    platformFeePercentage: 0.10,
                    paymentFeePercentage: 0.00,
                    paymentFeeFixed: 0.00,
                    description: "Mercari Flat Fee"
                )
            case .heritageAuctions:
                return PlatformFees(
                    platformFeePercentage: 0.15,
                    paymentFeePercentage: 0.00,
                    paymentFeeFixed: 0.00,
                    description: "Heritage Seller Fee (approx)"
                )
            case .cardmarket:
                return PlatformFees(
                    platformFeePercentage: 0.05,
                    paymentFeePercentage: 0.029,
                    paymentFeeFixed: 0.35,
                    description: "Cardmarket EU Marketplace"
                )
            case .localCash, .event:
                return PlatformFees(
                    platformFeePercentage: 0.00,
                    paymentFeePercentage: 0.00,
                    paymentFeeFixed: 0.00,
                    description: "No Fees"
                )
            case .other:
                return PlatformFees(
                    platformFeePercentage: 0.10,
                    paymentFeePercentage: 0.029,
                    paymentFeeFixed: 0.30,
                    description: "Estimated Fees"
                )
            }
        }
    }

    // MARK: - Computed Fee Calculations

    private var effectiveFees: PlatformFees {
        platformPreferences.getEffectiveFees(for: selectedPlatform.rawValue)
    }

    private var salePriceValue: Double {
        Double(salePrice) ?? 0
    }

    private var shippingValue: Double {
        Double(shippingCost) ?? 0
    }

    private var platformFeeAmount: Double {
        salePriceValue * effectiveFees.platformFeePercentage
    }

    private var paymentFeeAmount: Double {
        (salePriceValue * effectiveFees.paymentFeePercentage) + effectiveFees.paymentFeeFixed
    }

    private var totalFees: Double {
        guard salePriceValue > 0 else { return 0 }
        return platformFeeAmount + paymentFeeAmount
    }

    private var netProceeds: Double {
        salePriceValue - totalFees - shippingValue
    }

    private var totalCost: Double {
        (card.purchaseCost ?? 0) + (card.gradingCost ?? 0)
    }

    private var profit: Double {
        netProceeds - totalCost
    }

    private var roiPercent: Double {
        guard totalCost > 0 else { return 0 }
        return (profit / totalCost) * 100
    }

    private var canConfirm: Bool {
        salePriceValue > 0
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    cardHeader
                    salePriceSection
                    platformPicker
                    paymentMethodPicker
                    shippingSection
                    optionalFieldsSection
                    summarySection
                    confirmButton
                }
                .padding(DesignSystem.Spacing.sm)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Sell Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.cyan)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { focusedField = nil }
                }
            }
            .onAppear {
                salePrice = String(format: "%.2f", card.marketValue)
                if let defaultPlatform = platformPreferences.defaultPlatform,
                   let platform = SellPlatform(rawValue: defaultPlatform) {
                    selectedPlatform = platform
                }
                if selectedPlatform == .localCash || selectedPlatform == .event {
                    shippingCost = "0"
                }
            }
            .alert("Save Failed", isPresented: $showSaveError) {
                Button("Try Again") { confirmSale() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("The sale could not be saved. Please try again.")
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

    // MARK: - Sale Price

    private var salePriceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("SALE PRICE")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("$")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                TextField("0.00", text: $salePrice)
                    .font(DesignSystem.Typography.heading2.monospacedDigit())
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .salePrice)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(
                        focusedField == .salePrice ? DesignSystem.Colors.electricBlue : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }

    // MARK: - Platform Picker

    private var platformPicker: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("PLATFORM")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    ForEach(SellPlatform.allCases) { platform in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPlatform = platform
                                if platform == .localCash || platform == .event {
                                    shippingCost = "0"
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: platform.icon)
                                    .font(.caption)
                                Text(platform.rawValue)
                                    .font(DesignSystem.Typography.captionBold)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.xs)
                            .padding(.vertical, DesignSystem.Spacing.xxs)
                            .background(
                                selectedPlatform == platform
                                    ? DesignSystem.Colors.cyan.opacity(0.2)
                                    : DesignSystem.Colors.backgroundTertiary
                            )
                            .foregroundStyle(
                                selectedPlatform == platform
                                    ? DesignSystem.Colors.cyan
                                    : DesignSystem.Colors.textSecondary
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedPlatform == platform
                                            ? DesignSystem.Colors.cyan.opacity(0.5)
                                            : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if totalFees > 0 {
                Text(effectiveFees.description)
                    .font(DesignSystem.Typography.captionSmall)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
    }

    // MARK: - Payment Method Picker

    private var paymentMethodPicker: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("PAYMENT METHOD")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    ForEach(PaymentMethod.allCases, id: \.rawValue) { method in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPaymentMethod = method
                            }
                        } label: {
                            Text(method.displayName)
                                .font(DesignSystem.Typography.captionBold)
                                .padding(.horizontal, DesignSystem.Spacing.xs)
                                .padding(.vertical, DesignSystem.Spacing.xxs)
                                .background(
                                    selectedPaymentMethod == method
                                        ? DesignSystem.Colors.electricBlue.opacity(0.2)
                                        : DesignSystem.Colors.backgroundTertiary
                                )
                                .foregroundStyle(
                                    selectedPaymentMethod == method
                                        ? DesignSystem.Colors.electricBlue
                                        : DesignSystem.Colors.textSecondary
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            selectedPaymentMethod == method
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
    }

    // MARK: - Shipping

    private var shippingSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("SHIPPING COST")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("$")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                TextField("0.00", text: $shippingCost)
                    .font(DesignSystem.Typography.heading3.monospacedDigit())
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .shipping)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(
                        focusedField == .shipping ? DesignSystem.Colors.electricBlue : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }

    // MARK: - Optional Fields

    private var optionalFieldsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("OPTIONAL")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            VStack(spacing: DesignSystem.Spacing.xs) {
                VStack(spacing: 0) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                            .frame(width: 24)
                        TextField("Buyer Name", text: $buyerName)
                            .font(DesignSystem.Typography.body)
                            .focused($focusedField, equals: .buyer)
                            .onChange(of: buyerName) {
                                showContactSuggestions = !matchingContacts.isEmpty && focusedField == .buyer
                            }

                        if isRepeatCustomer {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 9))
                                Text("Repeat")
                                    .font(.system(size: 9, weight: .semibold))
                            }
                            .foregroundStyle(DesignSystem.Colors.success)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(DesignSystem.Colors.success.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))

                    // Contact autocomplete suggestions
                    if showContactSuggestions && focusedField == .buyer {
                        VStack(spacing: 0) {
                            ForEach(matchingContacts) { contact in
                                Button {
                                    buyerName = contact.name
                                    showContactSuggestions = false
                                    focusedField = nil
                                } label: {
                                    HStack(spacing: DesignSystem.Spacing.xs) {
                                        ContactAvatarView(
                                            initials: contact.initials,
                                            size: CGSize(width: 28, height: 28),
                                            color: contact.contactTypeEnum.color
                                        )
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(contact.name)
                                                .font(DesignSystem.Typography.label)
                                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                                            if let subtitle = contact.subtitle {
                                                Text(subtitle)
                                                    .font(DesignSystem.Typography.captionSmall)
                                                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        Spacer()
                                        ContactTypeBadge(type: contact.contactTypeEnum)
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.sm)
                                    .padding(.vertical, DesignSystem.Spacing.xs)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(DesignSystem.Colors.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                    }
                }

                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "ticket.fill")
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .frame(width: 24)
                    TextField("Event Name", text: $eventName)
                        .font(DesignSystem.Typography.body)
                        .focused($focusedField, equals: .event)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("SALE SUMMARY")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            VStack(spacing: DesignSystem.Spacing.xs) {
                summaryRow(label: "Sale Price", value: salePriceValue, color: DesignSystem.Colors.textPrimary)

                if totalFees > 0 {
                    summaryRow(label: "Platform Fees", value: -platformFeeAmount, color: DesignSystem.Colors.error)
                    summaryRow(label: "Payment Fees", value: -paymentFeeAmount, color: DesignSystem.Colors.error)
                }

                if shippingValue > 0 {
                    summaryRow(label: "Shipping", value: -shippingValue, color: DesignSystem.Colors.error)
                }

                Divider()
                    .overlay(DesignSystem.Colors.borderPrimary)

                summaryRow(label: "Net Proceeds", value: netProceeds, color: DesignSystem.Colors.cyan, bold: true)

                if totalCost > 0 {
                    summaryRow(label: "Total Cost", value: -totalCost, color: DesignSystem.Colors.textSecondary)

                    Divider()
                        .overlay(DesignSystem.Colors.borderPrimary)

                    summaryRow(
                        label: "Profit",
                        value: profit,
                        color: profit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error,
                        bold: true
                    )

                    HStack {
                        Text("ROI")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text("\(String(format: "%.1f", roiPercent))%")
                            .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                            .foregroundStyle(profit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                    }
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    private func summaryRow(label: String, value: Double, color: Color, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? DesignSystem.Typography.labelLarge : DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(value < 0 ? "-$\(String(format: "%.2f", abs(value)))" : "$\(String(format: "%.2f", value))")
                .font((bold ? DesignSystem.Typography.labelLarge : DesignSystem.Typography.body).monospacedDigit())
                .foregroundStyle(color)
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            confirmSale()
        } label: {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.headline)
                Text("Confirm Sale")
                    .font(DesignSystem.Typography.heading4)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.sm)
            .background(canConfirm ? DesignSystem.Colors.success : DesignSystem.Colors.success.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .disabled(!canConfirm)
        .padding(.top, DesignSystem.Spacing.xxs)
    }

    // MARK: - Confirm Sale Action

    private func confirmSale() {
        let transaction = Transaction.recordSale(
            card: card,
            salePrice: salePriceValue,
            platform: selectedPlatform.rawValue,
            fees: totalFees,
            shipping: shippingValue,
            contactName: buyerName.isEmpty ? nil : buyerName,
            eventName: eventName.isEmpty ? nil : eventName
        )
        transaction.paymentMethod = selectedPaymentMethod.rawValue
        transaction.buyerName = buyerName.isEmpty ? nil : buyerName

        // Link to existing contact if buyer name matches
        if !buyerName.isEmpty {
            let query = buyerName.lowercased()
            if let matchedContact = allContacts.first(where: { $0.name.lowercased() == query }) {
                transaction.contactId = matchedContact.id
                matchedContact.lastContactedAt = Date()
            }
        }

        modelContext.insert(transaction)

        card.status = CardStatus.sold.rawValue
        card.soldPrice = salePriceValue
        card.soldDate = Date()
        card.platform = selectedPlatform.rawValue

        // Remember platform preference
        platformPreferences.defaultPlatform = selectedPlatform.rawValue

        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            #if DEBUG
            print("Failed to save sale: \(error)")
            #endif
            showSaveError = true
        }
    }
}
