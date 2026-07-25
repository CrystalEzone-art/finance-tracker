import SwiftUI

struct ContentView: View {
    @State private var reloadToken = UUID()
    @State private var isShowingCover = true

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            FinanceWebView(reloadToken: reloadToken)
                .ignoresSafeArea(edges: .bottom)

            if isShowingCover {
                launchCover
                    .transition(.opacity.combined(with: .scale(scale: 1.03)))
                    .zIndex(2)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation(.easeInOut(duration: 0.45)) {
                isShowingCover = false
            }
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

    private var launchCover: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.97)
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("BrandIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132, height: 132)

                VStack(spacing: 7) {
                    Text("Finance Tracker")
                        .font(.system(size: 30, weight: .semibold))
                    Text("Your money, clearly organized.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    ContentView()
}
