import SwiftUI
import SwiftData
import CardShowProFeature

@main
struct CardShowProApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: InventoryCard.self, Transaction.self, Contact.self, Event.self)
            MockDataSeeder.seedIfNeeded(context: modelContainer.mainContext)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        }
        .modelContainer(modelContainer)
    }
}
