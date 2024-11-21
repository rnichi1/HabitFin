import SwiftUI
import SwiftData

@main
struct HabitFinApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Item.self, Receipt.self])
    }
}
