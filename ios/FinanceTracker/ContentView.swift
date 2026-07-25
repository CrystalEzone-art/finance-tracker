import SwiftUI

struct ContentView: View {
    @State private var reloadToken = UUID()

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            FinanceWebView(reloadToken: reloadToken)
                .ignoresSafeArea(edges: .bottom)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reload", systemImage: "arrow.clockwise") {
                    reloadToken = UUID()
                }
                .accessibilityHint("Reloads the finance tracker")
            }
        }
    }
}

#Preview {
    ContentView()
}
