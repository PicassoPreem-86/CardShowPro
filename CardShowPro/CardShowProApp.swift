import SwiftUI
import SwiftData
import CardShowProFeature

@main
struct CardShowProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        }
        .modelContainer(for: [InventoryCard.self])
    }
}
