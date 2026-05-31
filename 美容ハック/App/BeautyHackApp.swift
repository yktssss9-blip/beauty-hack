import SwiftUI
import SwiftData

@main
struct BeautyHackApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                BeautyCategory.self,
                BeautyRecord.self,
                BeautyPhoto.self,
                BeautyReminder.self,
            ])
            let config = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .automatic
            )
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("ModelContainerの初期化に失敗: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupPresets()
                }
        }
        .modelContainer(container)
    }

    private func setupPresets() {
        let context = container.mainContext
        for preset in BeautyCategory.presets() {
            let name = preset.name
            let descriptor = FetchDescriptor<BeautyCategory>(
                predicate: #Predicate { $0.name == name && $0.isPreset == true }
            )
            let existing = (try? context.fetch(descriptor)) ?? []
            if existing.isEmpty {
                context.insert(preset)
            }
        }
        try? context.save()
    }
}
