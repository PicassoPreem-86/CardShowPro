import SwiftUI
import SwiftData

/// Collapsible section showing recent scans from current session
/// Features running total of prices for bulk scanning scenarios
/// Designed to work as a sliding overlay panel with thumbnail strip
struct RecentScansSection: View {
    @Binding var isExpanded: Bool
    @State private var scannedCardsManager = ScannedCardsManager.shared
    @State private var selectedCard: ScannedCard?
    @Environment(\.modelContext) private var modelContext

    let onLoadPrevious: () -> Void

    private let accentGreen = Color(red: 0.5, green: 1.0, blue: 0.0)

    var body: some View {
        VStack(spacing: 0) {
            // Section header (always visible)
            sectionHeader

            // Content based on expansion state
            if isExpanded {
                expandedContent
            } else {
                collapsedContent
            }
        }
        .fullScreenCover(item: $selectedCard) { card in
            ScannedCardDetailView(card: card)
                .environment(\.modelContext, modelContext)
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Text("Recent scans")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            if scannedCardsManager.hasCards {
                Text("\(scannedCardsManager.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray)
                    .clipShape(Capsule())
            }

            Spacer()

            // Running total badge
            HStack(spacing: 4) {
                if scannedCardsManager.cardsWithPrices < scannedCardsManager.count {
                    ProgressView()
                        .tint(accentGreen)
                        .scaleEffect(0.6)
                }
                Text(scannedCardsManager.formattedTotal)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accentGreen)
                Text("total")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Collapsed Content (Thumbnail Strip)

    private var collapsedContent: some View {
        Group {
            if scannedCardsManager.hasCards {
                thumbnailStrip
            } else {
                collapsedEmptyHint
            }
        }
    }

    private var collapsedEmptyHint: some View {
        Text("Scanned cards will appear here")
            .font(.system(size: 13))
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(scannedCardsManager.cards) { card in
                    CardThumbnailView(card: card)
                        .onTapGesture {
                            selectedCard = card
                            HapticManager.shared.light()
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Expanded Content (Full List)

    private var expandedContent: some View {
        Group {
            if scannedCardsManager.hasCards {
                ScrollView {
                    VStack(spacing: 0) {
                        // Thumbnail strip at top when expanded too
                        thumbnailStrip
                            .padding(.bottom, 8)

                        Divider()
                            .background(Color.white.opacity(0.1))

                        // Full card list
                        scansList
                    }
                }
            } else {
                expandedEmptyState
            }
        }
    }

    // MARK: - Expanded Empty State

    private var expandedEmptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "viewfinder")
                .font(.system(size: 44))
                .foregroundStyle(.gray.opacity(0.5))

            Text("No scans yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Text("Tap the camera area above to scan a card")
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Scans List (for expanded state)

    private var scansList: some View {
        LazyVStack(spacing: 0) {
            ForEach(scannedCardsManager.cards) { card in
                scanRow(card)
                    .onTapGesture {
                        selectedCard = card
                        HapticManager.shared.light()
                    }

                if card.id != scannedCardsManager.cards.last?.id {
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }

            // Clear all button
            if scannedCardsManager.count > 0 {
                Button {
                    withAnimation {
                        scannedCardsManager.clearAll()
                    }
                    HapticManager.shared.light()
                } label: {
                    Text("Clear All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(.vertical, 16)
                }
            }

            // Bottom padding for safe area
            Spacer()
                .frame(height: 20)
        }
        .padding(.horizontal, 16)
    }

    private func scanRow(_ card: ScannedCard) -> some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let url = card.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    case .failure, .empty:
                        placeholderThumbnail
                    @unknown default:
                        placeholderThumbnail
                    }
                }
            } else {
                placeholderThumbnail
            }

            // Card info
            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(card.setName)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }

            Spacer()

            // Price and time
            VStack(alignment: .trailing, spacing: 2) {
                if card.isLoadingPrice {
                    ProgressView()
                        .tint(accentGreen)
                        .scaleEffect(0.7)
                } else {
                    Text(card.formattedPrice)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(card.displayPrice != nil ? accentGreen : .gray)
                }

                Text(card.timeAgo)
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }

            // Chevron for detail
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(.gray.opacity(0.5))
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.1))
            .frame(width: 40, height: 56)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            )
    }
}

// MARK: - Card Thumbnail View

/// Individual card thumbnail for the horizontal strip
struct CardThumbnailView: View {
    @Bindable var card: ScannedCard

    private let accentGreen = Color(red: 0.5, green: 1.0, blue: 0.0)

    var body: some View {
        VStack(spacing: 6) {
            // Card image
            ZStack {
                if let url = card.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure, .empty:
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
            }
            .frame(width: 60, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )

            // Price
            if card.isLoadingPrice {
                ProgressView()
                    .tint(accentGreen)
                    .scaleEffect(0.6)
                    .frame(height: 16)
            } else {
                Text(card.formattedPrice)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(card.displayPrice != nil ? accentGreen : .gray)
                    .lineLimit(1)
            }
        }
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(white: 0.15))
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 16))
                    .foregroundStyle(.gray.opacity(0.5))
            )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Empty State") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()
            RecentScansSection(
                isExpanded: .constant(true),
                onLoadPrevious: {}
            )
        }
    }
}

#Preview("With Cards - Collapsed") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            RecentScansSection(
                isExpanded: .constant(false),
                onLoadPrevious: {}
            )
            .onAppear {
                let manager = ScannedCardsManager.shared
                // Add mock cards
                let card1 = ScannedCard(
                    cardID: "base1-4",
                    name: "Charizard",
                    setName: "Base Set",
                    setID: "base1",
                    cardNumber: "4",
                    imageURL: URL(string: "https://images.pokemontcg.io/base1/4.png")
                )
                card1.marketPrice = 350.00
                manager.addCard(card1)

                let card2 = ScannedCard(
                    cardID: "base1-58",
                    name: "Pikachu",
                    setName: "Base Set",
                    setID: "base1",
                    cardNumber: "58",
                    imageURL: URL(string: "https://images.pokemontcg.io/base1/58.png")
                )
                card2.marketPrice = 25.00
                manager.addCard(card2)
            }
        }
    }
}

#Preview("With Cards - Expanded") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            RecentScansSection(
                isExpanded: .constant(true),
                onLoadPrevious: {}
            )
        }
    }
}
#endif
