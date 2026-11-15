import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var vm: AppViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    statusCard
                    serverCard
                    networkCard
                    if let error = vm.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
            }
            .navigationTitle("AudiBridge")
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Car Mode").font(.headline)
                    Text(vm.carModeEnabled ? "Активний" : "Вимкнений")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { vm.carModeEnabled },
                    set: { enabled in
                        Task {
                            if enabled { await vm.enableCarMode() }
                            else { vm.disableCarMode() }
                        }
                    }
                ))
                .labelsHidden()
            }

            if let location = vm.locationManager.location {
                Label(String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude), systemImage: "location.fill")
                    .font(.footnote.monospacedDigit())
            } else {
                Label("Координати ще не отримані", systemImage: "location.slash")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    private var serverCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("MMI POI server", systemImage: "server.rack")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(vm.server.isRunning ? Color.green : Color.secondary)
                    .frame(width: 10, height: 10)
            }
            Text(vm.server.isRunning ? "Listening on :\(vm.serverPort)" : "Зупинений")
                .foregroundStyle(.secondary)
            Text("Останній запит: \(vm.server.lastRequest)")
                .font(.caption.monospaced())
                .lineLimit(3)
        }
        .cardStyle()
    }

    private var networkCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Важливо для твоєї схеми", systemImage: "network")
                .font(.headline)
            Text("Якщо MMI працює тільки через штатну SIM і Wi‑Fi вимкнений, локальний :8080 на iPhone недоступний напряму. Наступний модуль — Public Relay — дасть MMI стабільну зовнішню адресу, а iPhone залишиться логікою Google POI/myAudi.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
