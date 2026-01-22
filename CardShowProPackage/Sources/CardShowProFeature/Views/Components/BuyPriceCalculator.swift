import SwiftUI

/// Calculator for sellers to determine buy price and profit potential
/// Shows ROI, profit margins, and deal quality indicators
struct BuyPriceCalculator: View {
    @Bindable var card: ScannedCard
    @FocusState private var isFocused: Bool

    private let accentGreen = Color(red: 0.5, green: 1.0, blue: 0.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Buy Price Calculator")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                // Buy price input section
                VStack(alignment: .leading, spacing: 12) {
                    Text("What will you pay for this card?")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)

                    HStack(spacing: 12) {
                        Text("$")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white)

                        TextField("0.00", value: $card.buyPrice, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white)
                            .focused($isFocused)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(white: 0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(16)

                // Calculations section (only show if buy price is entered)
                if let buyPrice = card.buyPrice, buyPrice > 0 {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    VStack(spacing: 12) {
                        // Market value
                        calculationRow(
                            label: "Market Value (NM):",
                            value: card.displayPrice,
                            color: .gray
                        )

                        // Buy price echo
                        calculationRow(
                            label: "Your Buy Price:",
                            value: buyPrice,
                            color: .gray
                        )

                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.vertical, 4)

                        // Profit potential
                        if let profit = card.profitPotential {
                            calculationRow(
                                label: "Profit Potential:",
                                value: profit,
                                color: profit >= 0 ? .green : .red,
                                isBold: true
                            )
                        }

                        // ROI
                        if let roi = card.roi {
                            HStack {
                                Text("ROI:")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)

                                Spacer()

                                HStack(spacing: 6) {
                                    Text("\(roi, specifier: "%.1f")%")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(card.roiQuality.color)

                                    // Quality indicator badge
                                    Text(card.roiQuality.displayText)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(card.roiQuality.color)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color(white: 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Helper text
            if card.buyPrice == nil || card.buyPrice == 0 {
                Text("Enter your offer price to calculate potential profit and ROI")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray.opacity(0.7))
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isFocused = false
        }
    }

    // MARK: - Helper Views

    private func calculationRow(label: String, value: Double?, color: Color, isBold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: isBold ? .bold : .medium))
                .foregroundStyle(.white)

            Spacer()

            if let value = value {
                Text(value.formatted(.currency(code: "USD")))
                    .font(.system(size: 15, weight: isBold ? .bold : .medium))
                    .foregroundStyle(color)
            } else {
                Text("--")
                    .font(.system(size: 15))
                    .foregroundStyle(.gray)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With Buy Price") {
    @Previewable @State var card = {
        let card = ScannedCard.mockCharizard
        card.buyPrice = 250.0  // $250 buy on $350 market = $100 profit, 40% ROI
        return card
    }()

    BuyPriceCalculator(card: card)
        .padding()
        .background(Color.black)
}

#Preview("Empty State") {
    BuyPriceCalculator(card: ScannedCard.mockCharizard)
        .padding()
        .background(Color.black)
}

#Preview("Low ROI") {
    @Previewable @State var card = {
        let card = ScannedCard.mockCharizard
        card.buyPrice = 320.0  // $320 buy on $350 market = $30 profit, 9.4% ROI
        return card
    }()

    BuyPriceCalculator(card: card)
        .padding()
        .background(Color.black)
}
#endif
