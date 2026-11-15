import SwiftUI

struct DestinationsView: View {
    @EnvironmentObject private var vm: AppViewModel
    @State private var title = ""
    @State private var address = ""
    @State private var lat = ""
    @State private var lon = ""

    var body: some View {
        NavigationView {
            List {
                Section("Нова точка") {
                    TextField("Назва", text: $title)
                    TextField("Адреса", text: $address)
                    TextField("Latitude", text: $lat).keyboardType(.numbersAndPunctuation)
                    TextField("Longitude", text: $lon).keyboardType(.numbersAndPunctuation)
                    Button("Зберегти для myAudi bridge") {
                        guard let latitude = Double(lat), let longitude = Double(lon), !title.isEmpty else { return }
                        vm.destinations.add(SavedDestination(title: title, address: address, latitude: latitude, longitude: longitude))
                        title = ""; address = ""; lat = ""; lon = ""
                    }
                }

                Section("Черга destinations") {
                    if vm.destinations.items.isEmpty {
                        Text("Поки порожньо. Наступним кроком під’єднаємо цю чергу до нашого AudiConnectorWS backend.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(vm.destinations.items) { item in
                        VStack(alignment: .leading) {
                            Text(item.title).font(.headline)
                            Text(item.address).foregroundStyle(.secondary)
                            Text(String(format: "%.6f, %.6f", item.latitude, item.longitude))
                                .font(.caption.monospacedDigit())
                        }
                    }
                    .onDelete(perform: vm.destinations.remove)
                }
            }
            .navigationTitle("myAudi Destinations")
        }
    }
}
