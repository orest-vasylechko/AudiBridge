import Foundation
import CoreLocation

struct POIPlace: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let primaryType: String
    let phone: String?
    let website: String?
    let openNow: Bool?
    let weekdayDescriptions: [String]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var statusLine: String? {
        if let openNow {
            return openNow ? "Відкрито зараз" : "Зачинено зараз"
        }
        return nil
    }
}

struct SavedDestination: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var address: String
    var latitude: Double
    var longitude: Double
    var createdAt = Date()
}

struct MMIPOISearchRequest {
    let key: String
    let language: String
    let latitude: Double
    let longitude: Double
    let radius: Double
    let count: Int
    let index: Int
    let rawQuery: [String: String]
}
