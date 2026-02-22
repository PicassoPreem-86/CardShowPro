import SwiftUI
import SwiftData

struct TransactionHistoryView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedType: TypeFilter = .all
    @State private var selectedPeriod: PeriodFilter = .allTime

    // MARK: - Filter Enums

    enum TypeFilter: String, CaseIterable {
        case all = "All"
        case purchases = "Purchases"
        case sales = "Sales"
        case trades = "Trades"
        case refunds = "Refunds"
    }

    enum PeriodFilter: String, CaseIterable {
        case sevenDays = "7D"
        case thirtyDays = "30D"
        case ninetyDays = "90D"
        case allTime = "All"
    }

    // MARK: - Computed Properties

    private var filteredTransactions: [Transaction] {
        var result = allTransactions

        // Type filter
        switch selectedType {
        case .all:
            break
        case .purchases:
            result = result.filter { $0.transactionType == .purchase }
        case .sales:
            result = result.filter { $0.transactionType == .sale }
        case .trades:
            result = result.filter { $0.transactionType == .trade || $0.transactionType == .consignment }
        case .refunds:
            result = result.filter { $0.transactionType == .refund }
        }

        // Period filter
        let now = Date()
        switch selectedPeriod {
        case .sevenDays:
            let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
            result = result.filter { $0.date >= cutoff }
        case .thirtyDays:
            let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
            result = result.filter { $0.date >= cutoff }
        case .ninetyDays:
            let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: now) ?? now
            result = result.filter { $0.date >= cutoff }
        case .allTime:
            break
        }

        // Search filter
        if !searchText.isEmpty {
            result = result.filter { tx in
                tx.cardName.localizedCaseInsensitiveContains(searchText) ||
                tx.cardSetName.localizedCaseInsensitiveContains(searchText) ||
                (tx.contactName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return result
    }

    private var totalRevenue: Double {
        filteredTransactions
            .filter { $0.transactionType == .sale }
            .reduce(0) { $0 + $1.netAmount }
    }

    private var totalSpent: Double {
        filteredTransactions
            .filter { $0.transactionType == .purchase }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalRefunds: Double {
        filteredTransactions
            .filter { $0.transactionType == .refund }
            .reduce(0) { $0 + $1.amount }
    }

    private var netProfit: Double {
        totalRevenue - totalSpent - totalRefunds
    }

    private var transactionCount: Int {
        filteredTransactions.count
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            NebulaBackgroundView()

            VStack(spacing: 0) {
                // Summary header
                summaryHeader
                    .padding(.horizontal)
                    .padding(.top, DesignSystem.Spacing.xs)

                // Type filter
                typeFilterPills
                    .padding(.top, DesignSystem.Spacing.sm)

                // Period filter
                periodFilterPills
                    .padding(.top, DesignSystem.Spacing.xxs)
                    .padding(.bottom, DesignSystem.Spacing.xxs)

                // Transaction list
                if filteredTransactions.isEmpty {
                    emptyState
                } else {
                    transactionList
                }
            }
        }
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Search by card name...")
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            SummaryStatPill(
                label: "Revenue",
                value: totalRevenue.formatted(.currency(code: "USD")),
                color: DesignSystem.Colors.success
            )
            SummaryStatPill(
                label: "Spent",
                value: totalSpent.formatted(.currency(code: "USD")),
                color: DesignSystem.Colors.error
            )
            SummaryStatPill(
                label: "Profit",
                value: netProfit.formatted(.currency(code: "USD")),
                color: netProfit >= 0 ? DesignSystem.Colors.cyan : DesignSystem.Colors.warning
            )
            SummaryStatPill(
                label: "Count",
                value: "\(transactionCount)",
                color: DesignSystem.Colors.textSecondary
            )
        }
    }

    // MARK: - Type Filter

    private var typeFilterPills: some View {
        Picker("Type", selection: $selectedType) {
            ForEach(TypeFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    // MARK: - Period Filter

    private var periodFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                ForEach(PeriodFilter.allCases, id: \.self) { period in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.rawValue)
                            .font(DesignSystem.Typography.label)
                            .fontWeight(selectedPeriod == period ? .semibold : .regular)
                            .foregroundStyle(selectedPeriod == period ? DesignSystem.Colors.backgroundPrimary : DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, DesignSystem.Spacing.xs)
                            .padding(.vertical, DesignSystem.Spacing.xxxs + 2)
                            .background(
                                Capsule()
                                    .fill(selectedPeriod == period ? DesignSystem.Colors.cyan : DesignSystem.Colors.cardBackground)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedPeriod == period ? .isSelected : [])
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Transaction List

    private var transactionList: some View {
        List {
            ForEach(filteredTransactions) { transaction in
                TransactionRow(transaction: transaction)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Spacer()

            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 56))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No Transactions")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Transactions will appear here when you buy or sell cards.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)

            Spacer()
        }
    }
}

// MARK: - Summary Stat Pill

private struct SummaryStatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(DesignSystem.Typography.captionSmall)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
    }
}
