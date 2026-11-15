import Foundation

struct GooglePlacesClient {
    enum PlacesError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case google(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "Не заданий Google Places API key."
            case .invalidResponse: return "Google повернув некоректну відповідь."
            case .google(let message): return message
            }
        }
    }

    private let endpoint = URL(string: "https://places.googleapis.com/v1/places:searchText")!

    func search(
        text: String,
        latitude: Double,
        longitude: Double,
        radius: Double,
        count: Int,
        language: String,
        apiKey: String,
        richFields: Bool = false
    ) async throws -> [POIPlace] {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PlacesError.missingAPIKey
        }

        let pageSize = max(1, min(20, count))
        var body: [String: Any] = [
            "textQuery": text,
            "pageSize": pageSize,
            "locationBias": [
                "circle": [
                    "center": ["latitude": latitude, "longitude": longitude],
                    "radius": max(1, min(50_000, radius))
                ]
            ]
        ]
        let lang = normalizeLanguage(language)
        if !lang.isEmpty { body["languageCode"] = lang }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")

        var fields = [
            "places.id",
            "places.displayName",
            "places.formattedAddress",
            "places.location",
            "places.primaryType"
        ]
        if richFields {
            fields += [
                "places.nationalPhoneNumber",
                "places.websiteUri",
                "places.currentOpeningHours"
            ]
        }
        request.setValue(fields.joined(separator: ","), forHTTPHeaderField: "X-Goog-FieldMask")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PlacesError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw PlacesError.google("Google Places HTTP \(http.statusCode): \(message)")
        }

        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        return decoded.places.map { place in
            POIPlace(
                id: place.id ?? UUID().uuidString,
                name: place.displayName?.text ?? "Google Place",
                address: place.formattedAddress ?? "",
                latitude: place.location?.latitude ?? latitude,
                longitude: place.location?.longitude ?? longitude,
                primaryType: place.primaryType ?? "",
                phone: place.nationalPhoneNumber,
                website: place.websiteUri,
                openNow: place.currentOpeningHours?.openNow,
                weekdayDescriptions: place.currentOpeningHours?.weekdayDescriptions ?? []
            )
        }
    }

    private func normalizeLanguage(_ raw: String) -> String {
        let first = raw.split(separator: ";").first.map(String.init) ?? raw
        let normalized = first.replacingOccurrences(of: "_", with: "-")
        return normalized.split(separator: "-").first.map { $0.lowercased() } ?? ""
    }
}

private struct SearchResponse: Decodable {
    let places: [PlaceDTO]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        places = try container.decodeIfPresent([PlaceDTO].self, forKey: .places) ?? []
    }

    enum CodingKeys: String, CodingKey { case places }
}

private struct PlaceDTO: Decodable {
    let id: String?
    let displayName: DisplayNameDTO?
    let formattedAddress: String?
    let location: LocationDTO?
    let primaryType: String?
    let nationalPhoneNumber: String?
    let websiteUri: String?
    let currentOpeningHours: OpeningHoursDTO?
}

private struct DisplayNameDTO: Decodable { let text: String? }
private struct LocationDTO: Decodable { let latitude: Double?; let longitude: Double? }
private struct OpeningHoursDTO: Decodable {
    let openNow: Bool?
    let weekdayDescriptions: [String]?
}
