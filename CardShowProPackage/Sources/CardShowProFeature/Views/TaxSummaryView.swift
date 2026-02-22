import SwiftUI
import SwiftData

struct TaxSummaryView: View {
    @Query private var transactions: [Transaction]
    @Query private var cards: [InventoryCard]
    @Query private var events: [Event]
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedQuarter: Int? = nil
    @State private var showShareSheet = false
    @State private var shareText = ""

    private var availableYears: [Int] {
        let allDates = transactions.map(\.date) + cards.map(\.timestamp)
        guard !allDates.isEmpty else { return [selectedYear] }
        let years = Set(allDates.map { Calendar.current.component(.year, from: $0) })
        return years.sorted().reversed()
    }

    private var filteredTransactions: [Transaction] {
        transactions.filter { txn in
            let year = Calendar.current.component(.year, from: txn.date)
            guard year == selectedYear else { return false }
            if let quarter = selectedQuarter {
                let month = Calendar.current.component(.month, from: txn.date)
                let txnQuarter = (month - 1) / 3 + 1
                return txnQuarter == quarter
            }
            return true
        }
    }

    private var filteredEvents: [Event] {
        events.filter { event in
            let year = Calendar.current.component(.year, from: event.date)
            guard year == selectedYear else { return false }
            if let quarter = selectedQuarter {
                let month = Calendar.current.component(.month, from: event.date)
                let eventQuarter = (month - 1) / 3 + 1
                return eventQuarter == quarter
            }
            return true
        }
    }

    private var saleTxns: [Transaction] {
        filteredTransactions.filter { $0.transactionType == .sale }
    }

    // Revenue by platform
    private var platformRevenue: [(platform: String, revenue: Double, count: Int)] {
        let grouped = Dictionary(grouping: saleTxns, by: { $0.platform ?? "Unknown" })
        return grouped.map { platform, txns in
            (platform: platform, revenue: txns.reduce(0.0) { $0 + $1.amount }, count: txns.count)
        }
        .sorted { $0.revenue > $1.revenue }
    }

    private var grossRevenue: Double {
        saleTxns.reduce(0.0) { $0 + $1.amount }
    }

    // Deductions
    private var totalPlatformFees: Double {
        saleTxns.reduce(0.0) { $0 + $1.platformFees }
    }

    private var totalShippingCosts: Double {
        saleTxns.reduce(0.0) { $0 + $1.shippingCost }
    }

    private var totalGradingCosts: Double {
        let soldCards = cards.filter { $0.isSold }
        return soldCards.reduce(0.0) { $0 + ($1.gradingCost ?? 0) }
    }

    private var totalEventTableCosts: Double {
        filteredEvents.reduce(0.0) { $0 + $1.tableCost }
    }

    private var totalEventTravelCosts: Double {
        filteredEvents.reduce(0.0) { $0 + $1.travelCost }
    }

    private var totalDeductions: Double {
        totalPlatformFees + totalShippingCosts + totalGradingCosts + totalEventTableCosts + totalEventTravelCosts
    }

    // COGS
    private var costOfGoodsSold: Double {
        saleTxns.reduce(0.0) { $0 + $1.costBasis }
    }

    // Profit
    private var grossProfit: Double {
        grossRevenue - costOfGoodsSold
    }

    private var netProfitBeforeTax: Double {
        grossProfit - totalDeductions
    }

    private var estimatedSETax: Double {
        max(netProfitBeforeTax * 0.153, 0)
    }

    private var estimatedQuarterlyPayment: Double {
        estimatedSETax / 4.0
    }

    private var periodLabel: String {
        if let q = selectedQuarter {
            return "Q\(q) \(selectedYear)"
        }
        return "\(selectedYear)"
    }

    var body: some View {
        ZStack {
            NebulaBackgroundView()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    periodSelector
                    revenuePlatformSection
                    deductionsSection
                    profitSummarySection
                    exportSection
                }
                .padding(.horizontal)
                .padding(.vertical, DesignSystem.Spacing.sm)
            }
        }
        .navigationTitle("Tax Summary")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: shareText)
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Period")
                .font(DesignSystem.Typography.heading3)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack(spacing: DesignSystem.Spacing.sm) {
                Picker("Year", selection: $selectedYear) {
                    ForEach(availableYears, id: \.self) { year in
                        Text("\(year)").tag(year)
                    }
                }
                .pickerStyle(.menu)
                .tint(DesignSystem.Colors.cyan)

                HStack(spacing: DesignSystem.Spacing.xxs) {
                    quarterButton(label: "Full Year", quarter: nil)
                    quarterButton(label: "Q1", quarter: 1)
                    quarterButton(label: "Q2", quarter: 2)
                    quarterButton(label: "Q3", quarter: 3)
                    quarterButton(label: "Q4", quarter: 4)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    private func quarterButton(label: String, quarter: Int?) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedQuarter = quarter
            }
        } label: {
            Text(label)
                .font(DesignSystem.Typography.captionSmall)
                .fontWeight(selectedQuarter == quarter ? .bold : .regular)
                .foregroundStyle(selectedQuarter == quarter ? .black : DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.xxs)
                .padding(.vertical, DesignSystem.Spacing.xxxs)
                .background(
                    Capsule()
                        .fill(selectedQuarter == quarter ? DesignSystem.Colors.cyan : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Revenue by Platform

    private var revenuePlatformSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Revenue by Platform")
                .font(DesignSystem.Typography.heading3)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("For 1099 tracking")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            if platformRevenue.isEmpty {
                Text("No sales in this period")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.lg)
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Platform")
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Revenue")
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .frame(width: 90, alignment: .trailing)
                        Text("Count")
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xxs)

                    Divider().background(DesignSystem.Colors.borderPrimary)

                    ForEach(Array(platformRevenue.enumerated()), id: \.offset) { _, item in
                        HStack {
                            HStack(spacing: DesignSystem.Spacing.xxs) {
                                Text(item.platform)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                                if item.revenue >= 600 {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(DesignSystem.Typography.captionSmall)
                                        .foregroundStyle(DesignSystem.Colors.warning)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text(formatCurrency(item.revenue))
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.medium)
                                .foregroundStyle(item.revenue >= 600 ? DesignSystem.Colors.warning : DesignSystem.Colors.textPrimary)
                                .monospacedDigit()
                                .frame(width: 90, alignment: .trailing)

                            Text("\(item.count)")
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .frame(width: 50, alignment: .trailing)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                    }

                    Divider().background(DesignSystem.Colors.borderPrimary)

                    HStack {
                        Text("Total Gross Revenue")
                            .font(DesignSystem.Typography.labelLarge)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Spacer()
                        Text(formatCurrency(grossRevenue))
                            .font(DesignSystem.Typography.heading4)
                            .fontWeight(.bold)
                            .foregroundStyle(DesignSystem.Colors.cyan)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                }
            }

            if platformRevenue.contains(where: { $0.revenue >= 600 }) {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(DesignSystem.Colors.warning)
                    Text("Platforms over $600 may issue a 1099-K")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.warning)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.warning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    // MARK: - Deductions

    private var deductionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Deductions Summary")
                .font(DesignSystem.Typography.heading3)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            deductionRow(label: "Platform Fees", amount: totalPlatformFees, icon: "creditcard.fill")
            deductionRow(label: "Shipping Costs", amount: totalShippingCosts, icon: "shippingbox.fill")
            deductionRow(label: "Grading Costs", amount: totalGradingCosts, icon: "rosette")
            deductionRow(label: "Event Table Costs", amount: totalEventTableCosts, icon: "tablecells")
            deductionRow(label: "Event Travel Costs", amount: totalEventTravelCosts, icon: "car.fill")

            Divider().background(DesignSystem.Colors.borderPrimary)

            HStack {
                Text("Total Deductions")
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Text(formatCurrency(totalDeductions))
                    .font(DesignSystem.Typography.heading4)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.error)
                    .monospacedDigit()
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    private func deductionRow(label: String, amount: Double, icon: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .frame(width: 24)

            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            Text(formatCurrency(amount))
                .font(DesignSystem.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .monospacedDigit()
        }
        .padding(.vertical, DesignSystem.Spacing.xxxs)
    }

    // MARK: - Profit Summary

    private var profitSummarySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Profit Summary")
                .font(DesignSystem.Typography.heading3)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            profitRow(label: "Gross Revenue", amount: grossRevenue, color: DesignSystem.Colors.textPrimary)
            profitRow(label: "Cost of Goods Sold (COGS)", amount: -costOfGoodsSold, color: DesignSystem.Colors.textSecondary)

            Divider().background(DesignSystem.Colors.borderPrimary)

            profitRow(label: "Gross Profit", amount: grossProfit, color: grossProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error, bold: true)
            profitRow(label: "Total Deductions", amount: -totalDeductions, color: DesignSystem.Colors.textSecondary)

            Divider().background(DesignSystem.Colors.borderPrimary)

            profitRow(label: "Net Profit Before Tax", amount: netProfitBeforeTax, color: netProfitBeforeTax >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error, bold: true)

            Divider().background(DesignSystem.Colors.borderPrimary)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                profitRow(label: "Est. Self-Employment Tax (15.3%)", amount: -estimatedSETax, color: DesignSystem.Colors.warning)
                profitRow(label: "Est. Quarterly Payment", amount: estimatedQuarterlyPayment, color: DesignSystem.Colors.thunderYellow, bold: true)
            }

            HStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                Text("Tax estimates are for reference only. Consult a tax professional.")
                    .font(DesignSystem.Typography.captionSmall)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.top, DesignSystem.Spacing.xxs)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }

    private func profitRow(label: String, amount: Double, color: Color, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? DesignSystem.Typography.labelLarge : DesignSystem.Typography.body)
                .fontWeight(bold ? .semibold : .regular)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            Text(formatSignedCurrency(amount))
                .font(bold ? DesignSystem.Typography.heading4 : DesignSystem.Typography.body)
                .fontWeight(bold ? .bold : .medium)
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .padding(.vertical, DesignSystem.Spacing.xxxs)
    }

    // MARK: - Export

    private var exportSection: some View {
        Button {
            shareText = buildExportText()
            showShareSheet = true
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Export Tax Summary")
            }
            .font(DesignSystem.Typography.labelLarge)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.cyan)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func buildExportText() -> String {
        var lines: [String] = []
        lines.append("CardShowPro Tax Summary - \(periodLabel)")
        lines.append(String(repeating: "=", count: 40))
        lines.append("")

        lines.append("REVENUE BY PLATFORM")
        lines.append(String(repeating: "-", count: 30))
        for item in platformRevenue {
            let flag = item.revenue >= 600 ? " [1099]" : ""
            lines.append("\(item.platform): \(formatCurrency(item.revenue)) (\(item.count) sales)\(flag)")
        }
        lines.append("Total Gross Revenue: \(formatCurrency(grossRevenue))")
        lines.append("")

        lines.append("DEDUCTIONS")
        lines.append(String(repeating: "-", count: 30))
        lines.append("Platform Fees: \(formatCurrency(totalPlatformFees))")
        lines.append("Shipping Costs: \(formatCurrency(totalShippingCosts))")
        lines.append("Grading Costs: \(formatCurrency(totalGradingCosts))")
        lines.append("Event Table Costs: \(formatCurrency(totalEventTableCosts))")
        lines.append("Event Travel Costs: \(formatCurrency(totalEventTravelCosts))")
        lines.append("Total Deductions: \(formatCurrency(totalDeductions))")
        lines.append("")

        lines.append("PROFIT SUMMARY")
        lines.append(String(repeating: "-", count: 30))
        lines.append("Gross Revenue: \(formatCurrency(grossRevenue))")
        lines.append("COGS: \(formatCurrency(costOfGoodsSold))")
        lines.append("Gross Profit: \(formatCurrency(grossProfit))")
        lines.append("Total Deductions: \(formatCurrency(totalDeductions))")
        lines.append("Net Profit Before Tax: \(formatCurrency(netProfitBeforeTax))")
        lines.append("")
        lines.append("Est. SE Tax (15.3%): \(formatCurrency(estimatedSETax))")
        lines.append("Est. Quarterly Payment: \(formatCurrency(estimatedQuarterlyPayment))")
        lines.append("")
        lines.append("Note: Estimates only. Consult a tax professional.")

        return lines.joined(separator: "\n")
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func formatSignedCurrency(_ value: Double) -> String {
        let formatted = formatCurrency(abs(value))
        if value >= 0 {
            return formatted
        }
        return "-\(formatted)"
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
