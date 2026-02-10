import SwiftUI
import SwiftData
import Charts

/// Rare Candy-style card detail page
/// Shows comprehensive pricing, history, and buying options for a scanned card
struct ScannedCardDetailView: View {
    @Bindable var card: ScannedCard
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var showAddToInventory = false
    @State private var showPriceHistory = false
    @State private var selectedCondition: PriceCondition = .nearMint

    // Green accent color matching the design
    private let accentGreen = Color(red: 0.5, green: 1.0, blue: 0.0)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero card image
                    cardImageSection
                        .padding(.top, 16)

                    // Tags row
                    tagsRow
                        .padding(.top, 16)
                        .padding(.horizontal, 16)

                    // Card name + number
                    cardTitleSection
                        .padding(.top, 12)
                        .padding(.horizontal, 16)

                    // Action buttons
                    actionButtons
                        .padding(.top, 20)
                        .padding(.horizontal, 16)

                    // Market value section
                    marketValueSection
                        .padding(.top, 24)
                        .padding(.horizontal, 16)

                    // Price history chart
                    if let history = card.priceHistory, !history.isEmpty {
                        priceHistorySection(history: history)
                            .padding(.top, 16)
                            .padding(.horizontal, 16)
                    }

                    // Condition price cards
                    if card.conditionPrices != nil {
                        conditionPricesSection
                            .padding(.top, 20)
                    }

                    // Attribution
                    attributionSection
                        .padding(.top, 16)
                        .padding(.horizontal, 16)

                    // Past sales section (placeholder)
                    pastSalesSection
                        .padding(.top, 24)
                        .padding(.horizontal, 16)

                    // Buy options section
                    buyOptionsSection
                        .padding(.top, 24)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                }
            }
            .background(Color.black)
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(white: 0.08), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("Back")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            // Bookmark action
                        } label: {
                            Image(systemName: "bookmark")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                        }
                        .accessibilityLabel("Bookmark")

                        Button {
                            shareCard()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                        }
                        .accessibilityLabel("Share card")
                    }
                }
            }
            .sheet(isPresented: $showAddToInventory) {
                addToInventorySheet
            }
            .sheet(isPresented: $showPriceHistory) {
                if let history = card.priceHistory {
                    PriceHistorySheet(
                        priceHistory: history,
                        cardName: card.name,
                        currentPrice: card.displayPrice,
                        priceChange7d: card.priceChange7d,
                        priceChange30d: card.priceChange30d
                    )
                }
            }
        }
    }

    // MARK: - Card Image Section

    private var cardImageSection: some View {
        VStack {
            if let imageURL = card.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                    case .failure, .empty:
                        cardPlaceholder
                    @unknown default:
                        cardPlaceholder
                    }
                }
            } else {
                cardPlaceholder
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var cardPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(white: 0.15))
            .frame(width: 200, height: 280)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                    Text("No Image")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            )
    }

    // MARK: - Tags Row

    private var tagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TagPillView(text: "Pokemon", color: .blue)

                TagPillView(text: card.setName, color: Color(white: 0.25))

                TagPillView(text: "EN", color: Color(white: 0.25))

                if let rarity = card.rarity {
                    TagPillView(text: rarity, color: .purple.opacity(0.8))
                }
            }
        }
    }

    // MARK: - Card Title Section

    private var cardTitleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(card.name) #\(card.cardNumber)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Add to Collection button
            Button {
                showAddToInventory = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 16, weight: .medium))
                    Text("ADD TO COLLECTION")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(white: 0.15))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // See Buying Options button
            Button {
                if let url = card.tcgPlayerBuyURL {
                    openURL(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "cart")
                        .font(.system(size: 16, weight: .medium))
                    Text("SEE BUYING OPTIONS")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(card.tcgPlayerBuyURL == nil)
            .opacity(card.tcgPlayerBuyURL == nil ? 0.5 : 1)
        }
    }

    // MARK: - Market Value Section

    private var marketValueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Market value")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.gray)

                Spacer()

                // Raw/Graded toggle (placeholder)
                Menu {
                    Button("Raw") { }
                    Button("Graded PSA 10") { }
                } label: {
                    HStack(spacing: 4) {
                        Text("Raw")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.white)
                }
            }

            // Price display
            if card.isLoadingPrice {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(accentGreen)
                    Text("Loading price...")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                }
            } else if let price = card.displayPrice {
                Text(price.formatted(.currency(code: "USD")))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(accentGreen)

                // Price changes
                VStack(alignment: .leading, spacing: 4) {
                    if let change7d = card.priceChange7d {
                        priceChangeRow(
                            change: change7d,
                            period: "this week"
                        )
                    }

                    if let change30d = card.priceChange30d {
                        priceChangeRow(
                            change: change30d,
                            period: "last 30 days"
                        )
                    }
                }
            } else if let error = card.pricingError {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Price unavailable")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.gray)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(.gray.opacity(0.7))
                }
            } else {
                Text("--")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.gray)
            }
        }
    }

    private func priceChangeRow(change: Double, period: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                .font(.system(size: 11, weight: .medium))
            Text("$\(abs(change), specifier: "%.2f") (\(abs(change / (card.displayPrice ?? 1) * 100), specifier: "%.1f")%)")
                .font(.system(size: 13, weight: .medium))
            Text(period)
                .font(.system(size: 13))
                .foregroundStyle(.gray)
        }
        .foregroundStyle(change >= 0 ? .green : .red)
    }

    // MARK: - Price History Section

    private func priceHistorySection(history: [PricePoint]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                showPriceHistory = true
            } label: {
                HStack {
                    Text("Price History")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.gray)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.gray)
                }
            }

            // Mini chart
            Chart {
                ForEach(history.suffix(30)) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.p)
                    )
                    .foregroundStyle(accentGreen)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.p)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentGreen.opacity(0.3), accentGreen.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Condition Prices Section

    private var conditionPricesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Condition Prices")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.gray)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PriceCondition.allCases) { condition in
                        ConditionPriceCard(
                            condition: condition,
                            price: card.conditionPrices?.price(for: condition),
                            isSelected: selectedCondition == condition,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCondition = condition
                                }
                                HapticManager.shared.selection()
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Attribution Section

    private var attributionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Market data from")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)

                Text("JustTCG")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.blue)

                Spacer()

                Button {
                    // Report action
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 10))
                        Text("Report")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.gray)
                }
            }

            Text("Prices are third-party estimates based on recent sales data.")
                .font(.system(size: 11))
                .foregroundStyle(.gray.opacity(0.7))
        }
    }

    // MARK: - Past Sales Section (Placeholder)

    private var pastSalesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Past Sales")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text("Coming Soon")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.15))
                    .clipShape(Capsule())
            }

            // Placeholder for past sales
            VStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 32))
                    .foregroundStyle(.gray.opacity(0.5))

                Text("eBay sales history coming soon")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)

                Text("Track actual sale prices to make better buying decisions")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color(white: 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Buy Options Section

    private var buyOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Buy Now")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                // TCGPlayer
                buyOptionRow(
                    name: "TCGPlayer",
                    icon: "cart.fill",
                    price: card.displayPrice,
                    action: {
                        if let url = card.tcgPlayerBuyURL {
                            openURL(url)
                        }
                    }
                )

                Divider()
                    .background(Color.white.opacity(0.1))

                // eBay
                buyOptionRow(
                    name: "eBay",
                    icon: "magnifyingglass",
                    price: nil,
                    subtitle: "View all listings",
                    action: {
                        let query = "\(card.name) \(card.setName) pokemon card".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "https://www.ebay.com/sch/i.html?_nkw=\(query)") {
                            openURL(url)
                        }
                    }
                )
            }
            .background(Color(white: 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Disclaimer
            Text("CardShow Pro may receive affiliate commissions from marketplace purchases.")
                .font(.system(size: 11))
                .foregroundStyle(.gray.opacity(0.6))
        }
    }

    private func buyOptionRow(
        name: String,
        icon: String,
        price: Double?,
        subtitle: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.gray)
                    .frame(width: 24)

                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)

                Spacer()

                if let price = price {
                    Text("from \(price.formatted(.currency(code: "USD")))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(accentGreen)
                } else if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                }

                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Add to Inventory Sheet

    private var addToInventorySheet: some View {
        NavigationStack {
            let scanState = ScanFlowState()
            let _ = {
                scanState.cardNumber = card.cardNumber
                scanState.cardImageURL = card.imageURL
            }()

            CardEntryView(
                pokemonName: card.name,
                setName: card.setName,
                setID: card.setID,
                state: scanState
            )
            .environment(\.modelContext, modelContext)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddToInventory = false
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func shareCard() {
        let text = """
        \(card.name) #\(card.cardNumber)
        Set: \(card.setName)
        \(card.displayPrice != nil ? "Price: \(card.formattedPrice)" : "")

        Scanned with CardShow Pro
        """

        // Note: In a real app, you'd use UIActivityViewController
        // For now, we'll just use the share URL if available
        if let url = card.tcgPlayerBuyURL {
            openURL(url)
        }
    }
}

// MARK: - Supporting Views

/// Tag pill for category display
struct TagPillView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color)
            .clipShape(Capsule())
    }
}

/// Condition price card for horizontal scroll
struct ConditionPriceCard: View {
    let condition: PriceCondition
    let price: Double?
    let isSelected: Bool
    let onTap: () -> Void

    private let accentGreen = Color(red: 0.5, green: 1.0, blue: 0.0)

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(condition.abbreviation)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .black : .white)

                if let price = price {
                    Text(price.formatted(.currency(code: "USD")))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isSelected ? .black.opacity(0.8) : accentGreen)
                } else {
                    Text("--")
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                }
            }
            .frame(width: 70)
            .padding(.vertical, 12)
            .background(isSelected ? accentGreen : Color(white: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? accentGreen : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Charizard Detail") {
    ScannedCardDetailView(card: .mockCharizard)
}

#Preview("Loading State") {
    ScannedCardDetailView(card: .mockLoading)
}
#endif
