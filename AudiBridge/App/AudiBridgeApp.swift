import SwiftUI

@main
struct AudiBridgeApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    if url.scheme == "audibridge", url.host == "car-mode" {
                        Task { await viewModel.enableCarMode() }
                    }
                }
        }
    }
}
