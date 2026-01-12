import SwiftUI
import SwiftData

/// Coordinator view for the 3-step manual card entry flow
struct ManualEntryFlow: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var flowState = ScanFlowState()

    var body: some View {
        NavigationStack {
            contentView
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch flowState.currentStep {
        case .search:
            PokemonSearchView(state: flowState)

        case .setSelection(let pokemonName):
            SetSelectionView(
                pokemonName: pokemonName,
                state: flowState
            )

        case .cardEntry(let pokemonName, let setName, let setID):
            CardEntryView(
                pokemonName: pokemonName,
                setName: setName,
                setID: setID,
                state: flowState
            )
            .environment(\.modelContext, modelContext)

        case .success(let card):
            AddCardSuccessView(card: card, state: flowState)
                .environment(appState)
        }
    }
}

#Preview {
    ManualEntryFlow()
        .modelContainer(for: InventoryCard.self, inMemory: true)
        .environment(AppState())
}
