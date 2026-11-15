import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm: AppViewModel

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Авто", systemImage: "car.fill") }
            POISearchView()
                .tabItem { Label("Google POI", systemImage: "mappin.and.ellipse") }
            DestinationsView()
                .tabItem { Label("Destinations", systemImage: "paperplane.fill") }
            SettingsView()
                .tabItem { Label("Налаштування", systemImage: "gearshape.fill") }
        }
        .tint(.white)
    }
}
