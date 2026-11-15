import Foundation

@MainActor
final class DestinationStore: ObservableObject {
    @Published private(set) var items: [SavedDestination] = []
    private let key = "AudiBridge.savedDestinations"

    init() { load() }

    func add(_ destination: SavedDestination) {
        items.insert(destination, at: 0)
        if items.count > 25 { items.removeLast(items.count - 25) }
        save()
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SavedDestination].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
