import SwiftUI

/// Main view for comparing two sets of cards in a trade
struct TradeAnalyzerView: View {
    @State private var viewModel = TradeAnalyzerViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Two-column layout
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Your Cards Column
                        TradeColumnView(
                            title: "Your Cards",
                            accentColor: DesignSystem.Colors.electricBlue,
                            cards: viewModel.yourCards,
                            total: viewModel.analysis.yourTotal,
                            onAddCard: {
                                viewModel.addCard(to: .yours)
                            },
                            onRemoveCard: { card in
                                viewModel.removeCard(card, from: .yours)
                            }
                        )
                        .frame(width: geometry.size.width / 2)

                        // Vertical Divider
                        Rectangle()
                            .fill(DesignSystem.Colors.borderPrimary)
                            .frame(width: 1)

                        // Their Cards Column
                        TradeColumnView(
                            title: "Their Cards",
                            accentColor: Color(hex: "#FF9F0A"), // Amber
                            cards: viewModel.theirCards,
                            total: viewModel.analysis.theirTotal,
                            onAddCard: {
                                viewModel.addCard(to: .theirs)
                            },
                            onRemoveCard: { card in
                                viewModel.removeCard(card, from: .theirs)
                            }
                        )
                        .frame(width: geometry.size.width / 2)
                    }
                }
                .padding(.bottom, 120) // Space for fairness indicator

                // Fairness Indicator (fixed at bottom)
                FairnessIndicatorView(analysis: viewModel.analysis)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.bottom, DesignSystem.Spacing.md)
            }
            .navigationTitle("Trade Analyzer")
            .navigationBarTitleDisplayMode(.inline)
            .background(DesignSystem.Colors.backgroundPrimary)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            loadMockData()
                        } label: {
                            Label("Load Sample Trade", systemImage: "arrow.down.doc.fill")
                        }

                        Button(role: .destructive) {
                            clearAllCards()
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddYourCard) {
                // Show manual entry directly - inventory picker coming soon
                ManualCardEntrySheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingAddTheirCard) {
                // Show manual entry directly - inventory picker coming soon
                ManualCardEntrySheet(viewModel: viewModel)
            }
        }
    }

    private func loadMockData() {
        withAnimation(DesignSystem.Animation.springSmooth) {
            viewModel.yourCards = TradeCard.mockYourCards
            viewModel.theirCards = TradeCard.mockTheirCards
        }
    }

    private func clearAllCards() {
        withAnimation(DesignSystem.Animation.springSmooth) {
            viewModel.yourCards.removeAll()
            viewModel.theirCards.removeAll()
        }
    }
}
