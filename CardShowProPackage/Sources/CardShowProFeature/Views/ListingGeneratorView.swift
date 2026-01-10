import SwiftUI
import SwiftData

/// Root coordinator view for the Listing Generator feature
struct ListingGeneratorView: View {
    @State private var state = ListingGeneratorState()
    @State private var service = ListingGeneratorService()

    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundPrimary
                .ignoresSafeArea()

            Group {
                switch state.currentPhase {
                case .input:
                    InputPhaseView(state: state, service: service)
                case .generating:
                    GenerationPhaseView(state: state)
                case .output:
                    OutputPhaseView(state: state)
                }
            }
            .transition(.opacity)
        }
        .navigationTitle("Listing Generator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if state.currentPhase != .generating {
                    Button("Reset") {
                        withAnimation {
                            state.reset()
                        }
                    }
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .animation(.easeInOut(duration: DesignSystem.Animation.normal), value: state.currentPhase)
    }
}
