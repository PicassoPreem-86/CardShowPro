import SwiftUI
import SwiftData

// MARK: - Search Result Category

private enum SearchCategory: String, CaseIterable {
    case all = "All"
    case cards = "Cards"
    case contacts = "Contacts"
    case events = "Events"
    case transactions = "Transactions"

    var icon: String {
        switch self {
        case .all: return "magnifyingglass"
        case .cards: return "rectangle.stack.fill"
        case .contacts: return "person.2.fill"
        case .events: return "calendar.circle.fill"
        case .transactions: return "arrow.left.arrow.right.circle.fill"
        }
    }
}

// MARK: - Unified Search View

struct UnifiedSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var cards: [InventoryCard]
    @Query private var contacts: [Contact]
    @Query private var events: [Event]
    @Query private var transactions: [Transaction]

    @State private var searchText = ""
    @State private var selectedCategory: SearchCategory = .all
    @FocusState private var isSearchFocused: Bool

    private var query: String {
        searchText.lowercased().trimmingCharacters(in: .whitespaces)
    }

    private var matchingCards: [InventoryCard] {
        guard !query.isEmpty else { return [] }
        return cards.filter { card in
            card.cardName.lowercased().contains(query) ||
            card.setName.lowercased().contains(query) ||
            card.cardNumber.lowercased().contains(query) ||
            card.notes.lowercased().contains(query)
        }.prefix(20).map { $0 }
    }

    private var matchingContacts: [Contact] {
        guard !query.isEmpty else { return [] }
        return contacts.filter { contact in
            contact.name.lowercased().contains(query) ||
            (contact.email?.lowercased().contains(query) == true) ||
            (contact.phone?.contains(query) == true) ||
            (contact.organization?.lowercased().contains(query) == true)
        }.prefix(20).map { $0 }
    }

    private var matchingEvents: [Event] {
        guard !query.isEmpty else { return [] }
        return events.filter { event in
            event.name.lowercased().contains(query) ||
            event.venue.lowercased().contains(query) ||
            event.notes.lowercased().contains(query)
        }.prefix(20).map { $0 }
    }

    private var matchingTransactions: [Transaction] {
        guard !query.isEmpty else { return [] }
        return transactions.filter { txn in
            txn.cardName.lowercased().contains(query) ||
            (txn.platform?.lowercased().contains(query) == true) ||
            (txn.eventName?.lowercased().contains(query) == true) ||
            (txn.buyerName?.lowercased().contains(query) == true) ||
            txn.notes.lowercased().contains(query)
        }.prefix(20).map { $0 }
    }

    private var totalResults: Int {
        switch selectedCategory {
        case .all:
            return matchingCards.count + matchingContacts.count + matchingEvents.count + matchingTransactions.count
        case .cards: return matchingCards.count
        case .contacts: return matchingContacts.count
        case .events: return matchingEvents.count
        case .transactions: return matchingTransactions.count
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search input
            searchBar

            // Category pills
            categoryPills

            // Results
            if query.isEmpty {
                recentSuggestionsView
            } else if totalResults == 0 {
                noResultsView
            } else {
                resultsList
            }
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            TextField("Search cards, contacts, events...", text: $searchText)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .focused($isSearchFocused)
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.top, DesignSystem.Spacing.sm)
    }

    // MARK: - Category Pills

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(SearchCategory.allCases, id: \.self) { category in
                    let count = countFor(category)
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.caption2)
                            Text(category.rawValue)
                                .font(.system(size: 13, weight: .medium))
                            if !query.isEmpty && count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(
                                        selectedCategory == category
                                            ? Color.white.opacity(0.2)
                                            : DesignSystem.Colors.backgroundTertiary
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundStyle(selectedCategory == category ? .white : DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(selectedCategory == category ? DesignSystem.Colors.electricBlue : DesignSystem.Colors.cardBackground)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    selectedCategory == category ? Color.clear : DesignSystem.Colors.borderPrimary,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                if (selectedCategory == .all || selectedCategory == .cards) && !matchingCards.isEmpty {
                    sectionHeader("Cards", count: matchingCards.count, icon: "rectangle.stack.fill")
                    ForEach(matchingCards, id: \.id) { card in
                        cardResultRow(card)
                    }
                }

                if (selectedCategory == .all || selectedCategory == .contacts) && !matchingContacts.isEmpty {
                    sectionHeader("Contacts", count: matchingContacts.count, icon: "person.2.fill")
                    ForEach(matchingContacts, id: \.id) { contact in
                        contactResultRow(contact)
                    }
                }

                if (selectedCategory == .all || selectedCategory == .events) && !matchingEvents.isEmpty {
                    sectionHeader("Events", count: matchingEvents.count, icon: "calendar.circle.fill")
                    ForEach(matchingEvents, id: \.id) { event in
                        eventResultRow(event)
                    }
                }

                if (selectedCategory == .all || selectedCategory == .transactions) && !matchingTransactions.isEmpty {
                    sectionHeader("Transactions", count: matchingTransactions.count, icon: "arrow.left.arrow.right.circle.fill")
                    ForEach(matchingTransactions, id: \.id) { txn in
                        transactionResultRow(txn)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, count: Int, icon: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            Text(title.uppercased())
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text("\(count)")
                .font(DesignSystem.Typography.captionSmall)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            Spacer()
        }
        .padding(.top, DesignSystem.Spacing.sm)
    }

    // MARK: - Result Rows

    private func cardResultRow(_ card: InventoryCard) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "rectangle.stack.fill")
                .font(.title3)
                .foregroundStyle(DesignSystem.Colors.electricBlue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(card.cardName)
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(card.setName)
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .lineLimit(1)

                    Text(card.cardStatus.rawValue)
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            Spacer()

            Text(card.marketValue.asCurrency)
                .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.cardName), \(card.setName), \(card.marketValue.asCurrency)")
    }

    private func contactResultRow(_ contact: Contact) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: contact.contactTypeEnum.icon)
                .font(.title3)
                .foregroundStyle(contact.contactTypeEnum.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(contact.name)
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(contact.contactTypeEnum.label)
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    if let org = contact.organization, !org.isEmpty {
                        Text(org)
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(contact.name), \(contact.contactTypeEnum.label)")
    }

    private func eventResultRow(_ event: Event) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: event.isActive ? "bolt.circle.fill" : "calendar.circle.fill")
                .font(.title3)
                .foregroundStyle(event.isActive ? DesignSystem.Colors.success : .purple)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(event.name)
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)

                    if event.isActive {
                        Text("LIVE")
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundStyle(DesignSystem.Colors.success)
                            .padding(.horizontal, DesignSystem.Spacing.xxs)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.success.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(event.venue)
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    Text(event.formattedDate)
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.name) at \(event.venue)")
    }

    private func transactionResultRow(_ txn: Transaction) -> some View {
        let isSale = txn.transactionType == .sale
        let isPurchase = txn.transactionType == .purchase

        return HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: isSale ? "arrow.down.circle.fill" : isPurchase ? "arrow.up.circle.fill" : "arrow.triangle.2.circlepath.circle.fill")
                .font(.title3)
                .foregroundStyle(isSale ? DesignSystem.Colors.success : isPurchase ? DesignSystem.Colors.electricBlue : .orange)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(txn.cardName.isEmpty ? "Unknown" : txn.cardName)
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(txn.transactionType.rawValue)
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    Text(txn.formattedDate)
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            Spacer()

            Text("\(isSale ? "+" : isPurchase ? "-" : "")\(txn.amount.asCurrency)")
                .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                .foregroundStyle(isSale ? DesignSystem.Colors.success : isPurchase ? DesignSystem.Colors.warning : DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(txn.transactionType.rawValue), \(txn.cardName), \(txn.amount.asCurrency)")
    }

    // MARK: - Empty States

    private var recentSuggestionsView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("Search Everything")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Find cards, contacts, events, and transactions across your entire business.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)

            // Quick stats
            HStack(spacing: DesignSystem.Spacing.lg) {
                quickStat(count: cards.count, label: "Cards", icon: "rectangle.stack.fill")
                quickStat(count: contacts.count, label: "Contacts", icon: "person.2.fill")
                quickStat(count: events.count, label: "Events", icon: "calendar")
            }
            .padding(.top, DesignSystem.Spacing.sm)

            Spacer()
        }
    }

    private func quickStat(count: Int, label: String, icon: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.xxxs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            Text("\(count)")
                .font(DesignSystem.Typography.heading4)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text(label)
                .font(DesignSystem.Typography.captionSmall)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
    }

    private var noResultsView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No results for \"\(searchText)\"")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Try a different search term or category.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()
        }
    }

    // MARK: - Helpers

    private func countFor(_ category: SearchCategory) -> Int {
        switch category {
        case .all: return matchingCards.count + matchingContacts.count + matchingEvents.count + matchingTransactions.count
        case .cards: return matchingCards.count
        case .contacts: return matchingContacts.count
        case .events: return matchingEvents.count
        case .transactions: return matchingTransactions.count
        }
    }
}

#Preview("Unified Search") {
    NavigationStack {
        UnifiedSearchView()
    }
    .modelContainer(for: [InventoryCard.self, Contact.self, Event.self, Transaction.self], inMemory: true)
}
