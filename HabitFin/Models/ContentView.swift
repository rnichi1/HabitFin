import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddReceiptModal = false

    var body: some View {
        ZStack {
            // TabView for Receipts and Kitchen views
            TabView {
                ReceiptView(modelContext: modelContext, showingAddReceiptModal: $showingAddReceiptModal)
                    .tabItem {
                        Label("Receipts", systemImage: "doc.text.viewfinder")
                    }

                KitchenView()
                    .tabItem {
                        Label("Kitchen", systemImage: "fork.knife")
                    }
            }

            // Floating plus button in the middle of the tab bar
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button(action: {
                        showingAddReceiptModal = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                            .background(Circle().foregroundColor(.white))
                    }
                    .padding(.bottom, 25) // Adjust as needed to align with the tab bar
                    .sheet(isPresented: $showingAddReceiptModal) {
                        AddReceiptModalView(viewModel: ScanReceiptViewModel(modelContext: modelContext), showingAddReceiptModal: $showingAddReceiptModal)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    ContentView()
}
