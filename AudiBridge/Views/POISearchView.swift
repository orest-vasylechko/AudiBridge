import SwiftUI

struct POISearchView: View {
    @EnvironmentObject private var vm: AppViewModel
    @State private var query = "кава"
    @State private var lat = "49.782666"
    @State private var lon = "24.054015"
    @State private var radius = 500.0
    @State private var showXML = false

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                VStack(spacing: 10) {
                    TextField("Що шукаємо", text: $query)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        TextField("Latitude", text: $lat)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numbersAndPunctuation)
                        TextField("Longitude", text: $lon)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numbersAndPunctuation)
                    }

                    HStack {
                        Text("Радіус")
                        Slider(value: $radius, in: 100...5000, step: 100)
                        Text("\(Int(radius)) м")
                            .monospacedDigit()
                            .frame(width: 70, alignment: .trailing)
                    }

                    HStack {
                        Button {
                            if let current = vm.locationManager.location {
                                lat = String(format: "%.7f", current.coordinate.latitude)
                                lon = String(format: "%.7f", current.coordinate.longitude)
                            }
                        } label: {
                            Label("Моя позиція", systemImage: "location.fill")
                        }
                        Spacer()
                        Button {
                            Task {
                                await vm.search(
                                    text: query,
                                    latitude: Double(lat),
                                    longitude: Double(lon),
                                    radius: radius
                                )
                            }
                        } label: {
                            if vm.isSearching { ProgressView() }
                            else { Label("Пошук", systemImage: "magnifyingglass") }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || vm.isSearching)
                    }
                }
                .padding(.horizontal)

                List(vm.lastPlaces) { place in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(place.name).font(.headline)
                            Spacer()
                            if let open = place.openNow {
                                Text(open ? "Відкрито" : "Зачинено")
                                    .font(.caption)
                                    .foregroundStyle(open ? .green : .orange)
                            }
                        }
                        Text(place.address).font(.subheadline).foregroundStyle(.secondary)
                        if let phone = place.phone, !phone.isEmpty { Text(phone).font(.caption) }
                        if let website = place.website, !website.isEmpty { Text(website).font(.caption).foregroundStyle(.blue) }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Google POI")
            .toolbar {
                Button("Audi XML") { showXML = true }
                    .disabled(vm.lastXML.isEmpty)
            }
            .sheet(isPresented: $showXML) {
                NavigationView {
                    ScrollView {
                        Text(vm.lastXML)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                            .padding()
                    }
                    .navigationTitle("Що отримає MMI")
                    .toolbar { Button("Готово") { showXML = false } }
                }
            }
        }
    }
}
