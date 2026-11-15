import Foundation

struct AudiPOIXMLBuilder {
    func build(request: MMIPOISearchRequest, places: [POIPlace], sourceName: String = "Google Places") -> Data {
        let root = XMLElement("Result")

        let query = root.add("Query")
        query.add("searchKey", request.key)
        let qPos = query.add("Position")
        qPos.add("lat", format(request.latitude))
        qPos.add("lon", format(request.longitude))
        qPos.add("rad", format(request.radius))
        query.add("index", String(request.index))
        query.add("num", String(request.count))
        query.add("lan", request.language)

        let used = query.add("UsedServices")
        let service = used.add("UsedService")
        service.add("sourceID", "google-places")
        service.add("sourceName", sourceName)

        let results = root.add("PoiResults")
        results.attributes["totalCount"] = String(places.count)

        for place in places {
            let poi = results.add("PoiResult")
            poi.add("name", place.name)
            poi.add("description", description(for: place))

            let address = poi.add("Address")
            let parts = splitAddress(place.address)
            address.add("street", parts.street)
            address.add("zip", "")
            address.add("city", parts.city)
            address.add("region", "")
            address.add("country", parts.country)

            poi.add("phone", place.phone ?? "")
            poi.add("url", place.website ?? "")
            poi.add("statusUrl", "")
            poi.add("type", place.primaryType.isEmpty ? "0" : place.primaryType)

            let pos = poi.add("Position")
            pos.add("lat", format(place.latitude))
            pos.add("lon", format(place.longitude))
        }

        root.add("AlternativeSuggestions")
        let error = root.add("ErrorStatus")
        error.add("errorCode", "0")
        error.add("errorDescription", "")

        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n" + root.render()
        return Data(xml.utf8)
    }

    private func description(for place: POIPlace) -> String {
        var lines: [String] = []
        if let status = place.statusLine { lines.append(status) }
        if !place.address.isEmpty { lines.append(place.address) }
        return lines.joined(separator: " · ")
    }

    private func splitAddress(_ formatted: String) -> (street: String, city: String, country: String) {
        let parts = formatted.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return (
            parts.first ?? formatted,
            parts.count > 1 ? parts[1] : "",
            parts.count > 1 ? (parts.last ?? "") : ""
        )
    }

    private func format(_ value: Double) -> String {
        String(format: "%.12f", value)
    }
}

private final class XMLElement {
    let name: String
    var text: String?
    var attributes: [String: String] = [:]
    var children: [XMLElement] = []

    init(_ name: String, text: String? = nil) {
        self.name = name
        self.text = text
    }

    @discardableResult
    func add(_ name: String, _ text: String? = nil) -> XMLElement {
        let child = XMLElement(name, text: text)
        children.append(child)
        return child
    }

    func render() -> String {
        let attrs = attributes.sorted { $0.key < $1.key }.map { " \($0.key)=\"\(escape($0.value))\"" }.joined()
        if children.isEmpty && (text == nil || text == "") {
            return "<\(name)\(attrs) />"
        }
        let content = (text.map(escape) ?? "") + children.map { $0.render() }.joined()
        return "<\(name)\(attrs)>\(content)</\(name)>"
    }

    private func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
