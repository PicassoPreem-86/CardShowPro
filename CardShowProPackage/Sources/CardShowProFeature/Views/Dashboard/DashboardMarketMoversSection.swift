import SwiftUI

struct DashboardMarketMoversSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Market Movers")
                .font(.headline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    MarketMoverCard(
                        cardName: "Charizard VMAX",
                        setName: "Champion's Path",
                        currentPrice: "$450.00",
                        priceChange: "+$45.50",
                        percentChange: "+11.2%",
                        isPositive: true,
                        imageURL: "https://assets.pokemon.com/static-assets/content-assets/cms2/img/cards/web/SWSH35/SWSH35_EN_74.png"
                    )

                    MarketMoverCard(
                        cardName: "Pikachu VMAX",
                        setName: "Vivid Voltage",
                        currentPrice: "$125.00",
                        priceChange: "+$12.50",
                        percentChange: "+8.5%",
                        isPositive: true,
                        imageURL: "https://assets.pokemon.com/static-assets/content-assets/cms2/img/cards/web/SWSH4/SWSH4_EN_44.png"
                    )

                    MarketMoverCard(
                        cardName: "Lugia V",
                        setName: "Silver Tempest",
                        currentPrice: "$89.00",
                        priceChange: "-$5.00",
                        percentChange: "-5.3%",
                        isPositive: false,
                        imageURL: "https://assets.pokemon.com/static-assets/content-assets/cms2/img/cards/web/SWSH12/SWSH12_EN_186.png"
                    )

                    MarketMoverCard(
                        cardName: "Mewtwo GX",
                        setName: "Shining Legends",
                        currentPrice: "$215.00",
                        priceChange: "+$28.00",
                        percentChange: "+15.0%",
                        isPositive: true,
                        imageURL: "https://assets.pokemon.com/static-assets/content-assets/cms2/img/cards/web/SM35/SM35_EN_78.png"
                    )

                    MarketMoverCard(
                        cardName: "Rayquaza VMAX",
                        setName: "Evolving Skies",
                        currentPrice: "$340.00",
                        priceChange: "+$52.00",
                        percentChange: "+18.1%",
                        isPositive: true,
                        imageURL: "https://assets.pokemon.com/static-assets/content-assets/cms2/img/cards/web/SWSH7/SWSH7_EN_111.png"
                    )
                }
                .padding(.horizontal)
            }
        }
    }
}
