import SwiftUI
import SwiftData

/// Success view shown after adding a single card via manual entry
struct AddCardSuccessView: View {
    let card: InventoryCard
    @Bindable var state: ScanFlowState
    @Environment(AppState.self) private var appState
    @Query private var inventoryCards: [InventoryCard]

    @State private var showContent = false
    @State private var autoDismissTask: Task<Void, Never>?

    private var totalCards: Int {
        inventoryCards.count
    }

    private var totalValue: Double {
        inventoryCards.reduce(0) { $0 + $1.marketValue }
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success Icon with animated scale-in
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
            }
            .scaleEffect(showContent ? 1.0 : 0.3)
            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showContent)
            .accessibilityLabel("Card added successfully")

            // Success Message
            VStack(spacing: 12) {
                Text("Card Added!")
                    .font(.title)
                    .fontWeight(.bold)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: showContent)

                Text(card.cardName)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: showContent)
            }

            // Card Preview
            if let image = card.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 10)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
            }

            // Price
            Text("$\(String(format: "%.2f", card.marketValue))")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.green)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25), value: showContent)

            // Stats Update with animated numbers
            VStack(spacing: 8) {
                HStack {
                    Text("Total Cards:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(totalCards)")
                            .fontWeight(.bold)
                        Text("(+1)")
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }
                }

                Divider()

                HStack {
                    Text("Total Value:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("$\(String(format: "%.2f", totalValue))")
                            .fontWeight(.bold)
                        Text("(+$\(String(format: "%.2f", card.marketValue)))")
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
            .padding(.horizontal, 32)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
                Button {
                    cancelAutoDismiss()
                    state.resetFlow()
                } label: {
                    Text("Add Another Card")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("Add another card")

                Button {
                    cancelAutoDismiss()
                    appState.selectedTab = .inventory
                    state.resetFlow()
                } label: {
                    Text("View Inventory")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("View inventory")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.35), value: showContent)
        }
        .onAppear {
            triggerAnimations()
            startAutoDismissTimer()
        }
        .onDisappear {
            cancelAutoDismiss()
        }
    }

    private func triggerAnimations() {
        // Trigger success haptic
        HapticManager.shared.success()

        // Start animations
        withAnimation {
            showContent = true
        }
    }

    private func startAutoDismissTimer() {
        autoDismissTask = Task {
            try? await Task.sleep(for: .seconds(3))

            guard !Task.isCancelled else { return }

            // Auto-dismiss by resetting to search
            await MainActor.run {
                state.resetFlow()
            }
        }
    }

    private func cancelAutoDismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var state = ScanFlowState()
    @Previewable @State var appState = AppState()

    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: InventoryCard.self, configurations: config)

    // Create sample cards
    let card1 = InventoryCard(
        cardName: "Pikachu",
        cardNumber: "25",
        setName: "Base Set",
        marketValue: 150.00
    )

    let card2 = InventoryCard(
        cardName: "Charizard",
        cardNumber: "4",
        setName: "Base Set",
        marketValue: 500.00
    )

    // Insert cards into context
    let _ = {
        container.mainContext.insert(card1)
        container.mainContext.insert(card2)
    }()

    return AddCardSuccessView(card: card1, state: state)
        .modelContainer(container)
        .environment(appState)
}
