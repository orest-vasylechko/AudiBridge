import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var vm: AppViewModel
    @State private var showKey = false

    var body: some View {
        NavigationView {
            Form {
                Section("Google Places") {
                    HStack {
                        if showKey {
                            TextField("API key", text: $vm.apiKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("API key", text: $vm.apiKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        Button { showKey.toggle() } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                        }
                    }
                    Button("Зберегти ключ у Keychain") { vm.saveAPIKey() }
                    Toggle("Телефон / сайт / години роботи", isOn: $vm.richGoogleFields)
                    Text("Розширені поля Google Places можуть мати інший billing SKU. Для першого тесту їх можна залишити вимкненими.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("MMI") {
                    Stepper("Локальний порт: \(vm.serverPort)", value: Binding(
                        get: { Int(vm.serverPort) },
                        set: { vm.serverPort = UInt16(max(1024, min(65535, $0))) }
                    ), in: 1024...65535)
                    Text("Перевірений MMI endpoint: /poi/search")
                        .font(.caption)
                }

                Section("Public Relay") {
                    Text("Ще не реалізований у v0.1. Він потрібен саме у твоєму сценарії: MMI → штатна SIM → Internet → relay → iPhone.")
                        .foregroundStyle(.secondary)
                }

                Section("Автозапуск") {
                    Text("Після встановлення створимо Shortcuts Automation: Bluetooth → Audi MMI → Open App (audibridge://car-mode).")
                        .font(.caption)
                }
            }
            .navigationTitle("Налаштування")
        }
    }
}
