import SwiftUI
import Charts

/// A chart showing price history over time with duration picker
public struct PriceHistoryChart: View {
    let priceHistory: [PricePoint]
    let cardName: String

    @State private var selectedDuration: Duration = .sevenDays
    @State private var selectedPoint: PricePoint?

    public enum Duration: String, CaseIterable, Identifiable {
        case sevenDays = "7D"
        case thirtyDays = "30D"
        case ninetyDays = "90D"

        public var id: String { rawValue }

        var days: Int {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            case .ninetyDays: return 90
            }
        }

        var displayName: String {
            switch self {
            case .sevenDays: return "7 Days"
            case .thirtyDays: return "30 Days"
            case .ninetyDays: return "90 Days"
            }
        }
    }

    init(priceHistory: [PricePoint], cardName: String = "") {
        self.priceHistory = priceHistory
        self.cardName = cardName
    }

    // Filter data based on selected duration
    private var filteredHistory: [PricePoint] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedDuration.days, to: Date()) ?? Date()
        let cutoffTimestamp = Int(cutoffDate.timeIntervalSince1970)

        return priceHistory
            .filter { $0.t >= cutoffTimestamp }
            .sorted { $0.t < $1.t }
    }

    // Calculate statistics
    private var minPrice: Double {
        filteredHistory.map(\.p).min() ?? 0
    }

    private var maxPrice: Double {
        filteredHistory.map(\.p).max() ?? 0
    }

    private var avgPrice: Double {
        guard !filteredHistory.isEmpty else { return 0 }
        return filteredHistory.map(\.p).reduce(0, +) / Double(filteredHistory.count)
    }

    private var priceChange: Double? {
        guard let first = filteredHistory.first?.p,
              let last = filteredHistory.last?.p,
              first > 0 else {
            return nil
        }
        return ((last - first) / first) * 100
    }

    private var trend: PriceTrend {
        guard let change = priceChange else { return .stable }
        if change > 2.0 { return .rising }
        if change < -2.0 { return .falling }
        return .stable
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header with card name
            if !cardName.isEmpty {
                Text(cardName)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            // Duration picker
            Picker("Duration", selection: $selectedDuration) {
                ForEach(Duration.allCases) { duration in
                    Text(duration.rawValue).tag(duration)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Chart
            if filteredHistory.isEmpty {
                emptyStateView
            } else {
                chartView
            }

            // Statistics
            statisticsView
        }
        .padding()
    }

    // MARK: - Subviews

    @ViewBuilder
    private var chartView: some View {
        Chart {
            ForEach(filteredHistory) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Price", point.p)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Price", point.p)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .cyan.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            // Selected point indicator
            if let selected = selectedPoint {
                PointMark(
                    x: .value("Date", selected.date),
                    y: .value("Price", selected.p)
                )
                .foregroundStyle(.orange)
                .symbolSize(100)
            }
        }
        .chartYScale(domain: (minPrice * 0.95)...(maxPrice * 1.05))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let price = value.as(Double.self) {
                        Text("$\(price, specifier: "%.0f")")
                            .font(.caption)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x
                                if let date: Date = proxy.value(atX: x) {
                                    // Find closest point
                                    selectedPoint = filteredHistory.min(by: {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    })
                                }
                            }
                            .onEnded { _ in
                                // Keep selection for a moment then clear
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        selectedPoint = nil
                                    }
                                }
                            }
                    )
            }
        }
        .frame(height: 200)
        .padding(.horizontal, 8)

        // Selected point tooltip
        if let selected = selectedPoint {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selected.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(selected.p, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer()
            }
            .padding(.horizontal)
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private var statisticsView: some View {
        HStack(spacing: 20) {
            // Low
            VStack(alignment: .leading, spacing: 2) {
                Text("Low")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("$\(minPrice, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Divider()
                .frame(height: 30)

            // Average
            VStack(alignment: .leading, spacing: 2) {
                Text("Avg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("$\(avgPrice, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Divider()
                .frame(height: 30)

            // High
            VStack(alignment: .leading, spacing: 2) {
                Text("High")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("$\(maxPrice, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Divider()
                .frame(height: 30)

            // Change
            VStack(alignment: .leading, spacing: 2) {
                Text("Change")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let change = priceChange {
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.caption)
                        Text(String(format: "%+.1f%%", change))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(trend.color)
                } else {
                    Text("N/A")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No Price History")
                .font(.headline)

            Text("Price history data is not available for this time period.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Price History Sheet

/// Full-screen sheet for viewing price history
public struct PriceHistorySheet: View {
    @Environment(\.dismiss) private var dismiss

    let priceHistory: [PricePoint]
    let cardName: String
    let currentPrice: Double?
    let priceChange7d: Double?
    let priceChange30d: Double?

    init(
        priceHistory: [PricePoint],
        cardName: String,
        currentPrice: Double? = nil,
        priceChange7d: Double? = nil,
        priceChange30d: Double? = nil
    ) {
        self.priceHistory = priceHistory
        self.cardName = cardName
        self.currentPrice = currentPrice
        self.priceChange7d = priceChange7d
        self.priceChange30d = priceChange30d
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current price header
                    if let price = currentPrice {
                        currentPriceHeader(price: price)
                    }

                    // Chart
                    PriceHistoryChart(priceHistory: priceHistory, cardName: "")

                    // Price change cards
                    priceChangeCards
                }
                .padding()
            }
            .navigationTitle(cardName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func currentPriceHeader(price: Double) -> some View {
        VStack(spacing: 8) {
            Text("Current Market Price")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("$\(price, specifier: "%.2f")")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            // Trend indicator
            if let change = priceChange7d {
                let trend: PriceTrend = {
                    if change > 2.0 { return .rising }
                    if change < -2.0 { return .falling }
                    return .stable
                }()

                Label(
                    String(format: "%+.1f%% (7D)", change),
                    systemImage: trend.icon
                )
                .font(.subheadline)
                .foregroundStyle(trend.color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var priceChangeCards: some View {
        HStack(spacing: 12) {
            // 7-day change
            priceChangeCard(
                title: "7-Day Change",
                change: priceChange7d
            )

            // 30-day change
            priceChangeCard(
                title: "30-Day Change",
                change: priceChange30d
            )
        }
    }

    @ViewBuilder
    private func priceChangeCard(title: String, change: Double?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let change = change {
                let trend: PriceTrend = {
                    if change > 2.0 { return .rising }
                    if change < -2.0 { return .falling }
                    return .stable
                }()

                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.title3)
                    Text(String(format: "%+.1f%%", change))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(trend.color)
            } else {
                Text("N/A")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Price History Chart") {
    let mockHistory: [PricePoint] = (0..<30).map { day in
        PricePoint(
            p: 320.0 + Double.random(in: -20...30),
            t: Int(Date().timeIntervalSince1970) - ((29 - day) * 86400)
        )
    }

    return PriceHistoryChart(priceHistory: mockHistory, cardName: "Charizard Base Set")
        .padding()
}

#Preview("Price History Sheet") {
    let mockHistory: [PricePoint] = (0..<90).map { day in
        PricePoint(
            p: 320.0 + Double.random(in: -30...40),
            t: Int(Date().timeIntervalSince1970) - ((89 - day) * 86400)
        )
    }

    return PriceHistorySheet(
        priceHistory: mockHistory,
        cardName: "Charizard",
        currentPrice: 350.00,
        priceChange7d: 5.2,
        priceChange30d: 12.8
    )
}

#Preview("Empty State") {
    PriceHistoryChart(priceHistory: [], cardName: "No Data Card")
        .padding()
}
#endif
