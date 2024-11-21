import SwiftUI

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            ScanReceiptView(modelContext: modelContext)
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }

            KitchenView()
                .tabItem {
                    Label("Kitchen", systemImage: "cart")
                }
        }
    }

}

