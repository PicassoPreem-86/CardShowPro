import SwiftUI
import SwiftData
import CardShowProFeature

@main
struct CardShowProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [InventoryCard.self, Contact.self, WantListItem.self, CachedPrice.self])
    }
}
