import SwiftUI
import SwiftData
import CardShowProFeature

@main
struct CardShowProApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema(versionedSchema: SchemaV1.self)
            let config = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: CardShowProMigrationPlan.self,
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
