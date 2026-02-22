import SwiftUI
import SwiftData
import CardShowProFeature

@main
struct CardShowProApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                InventoryCard.self,
                Transaction.self,
                Contact.self,
                Event.self,
                WishlistItem.self,
                PriceCacheEntry.self,
                ListingTemplate.self,
                TradeRecord.self
            ])
            let config = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(
                for: schema,
                configurations: config
            )
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
