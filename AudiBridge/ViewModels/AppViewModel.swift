import Foundation
import CoreLocation

@MainActor
final class AppViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var carModeEnabled = false
    @Published var richGoogleFields = false
    @Published var lastPlaces: [POIPlace] = []
    @Published var lastXML: String = ""
    @Published var lastError: String?
    @Published var isSearching = false
    @Published var serverPort: UInt16 = 8080

    let locationManager = CarModeLocationManager()
    let server = LocalHTTPServer()
    let destinations = DestinationStore()

    private let places = GooglePlacesClient()
    private let xmlBuilder = AudiPOIXMLBuilder()
    private let apiKeyKey = "google.places.apiKey"

    init() {
        apiKey = KeychainStore.shared.get(apiKeyKey) ?? ""
    }

    func saveAPIKey() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            if trimmed.isEmpty {
                KeychainStore.shared.delete(apiKeyKey)
            } else {
                try KeychainStore.shared.set(trimmed, for: apiKeyKey)
            }
            apiKey = trimmed
            lastError = nil
        } catch {
            lastError = "Не вдалося зберегти API key: \(error.localizedDescription)"
        }
    }

    func enableCarMode() async {
        carModeEnabled = true
        locationManager.start()
        startLocalServer()
    }

    func disableCarMode() {
        carModeEnabled = false
        server.stop()
        locationManager.stop()
    }

    func startLocalServer() {
        server.start(port: serverPort) { [weak self] request in
            guard let self else { return Data() }
            return await self.handleMMIRequest(request)
        }
    }

    func search(text: String, latitude: Double? = nil, longitude: Double? = nil, radius: Double = 500) async {
        let lat = latitude ?? locationManager.location?.coordinate.latitude
        let lon = longitude ?? locationManager.location?.coordinate.longitude
        guard let lat, let lon else {
            lastError = "Немає координат. Дозволь геолокацію або введи координати вручну."
            return
        }

        isSearching = true
        defer { isSearching = false }
        do {
            let result = try await places.search(
                text: text,
                latitude: lat,
                longitude: lon,
                radius: radius,
                count: 10,
                language: "uk_UA;de_DE",
                apiKey: apiKey,
                richFields: richGoogleFields
            )
            lastPlaces = result
            let request = MMIPOISearchRequest(
                key: text,
                language: "uk_UA;de_DE",
                latitude: lat,
                longitude: lon,
                radius: radius,
                count: 10,
                index: 0,
                rawQuery: [:]
            )
            lastXML = String(data: xmlBuilder.build(request: request, places: result), encoding: .utf8) ?? ""
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func handleMMIRequest(_ request: MMIPOISearchRequest) async -> Data {
        do {
            let result = try await places.search(
                text: request.key,
                latitude: request.latitude,
                longitude: request.longitude,
                radius: request.radius,
                count: request.count,
                language: request.language,
                apiKey: apiKey,
                richFields: richGoogleFields
            )
            await MainActor.run {
                self.lastPlaces = result
                self.lastXML = String(data: self.xmlBuilder.build(request: request, places: result), encoding: .utf8) ?? ""
                self.lastError = nil
            }
            return xmlBuilder.build(request: request, places: result)
        } catch {
            await MainActor.run { self.lastError = error.localizedDescription }
            return xmlBuilder.build(request: request, places: [], sourceName: "Google Places")
        }
    }
}
