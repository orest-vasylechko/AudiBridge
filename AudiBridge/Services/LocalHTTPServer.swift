import Foundation
import Network

final class LocalHTTPServer: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var lastRequest = "—"
    @Published private(set) var lastError: String?

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "AudiBridge.LocalHTTPServer")
    private var requestHandler: ((MMIPOISearchRequest) async -> Data)?

    func start(port: UInt16 = 8080, handler: @escaping (MMIPOISearchRequest) async -> Data) {
        stop()
        requestHandler = handler
        do {
            guard let nwPort = NWEndpoint.Port(rawValue: port) else {
                throw NSError(domain: "AudiBridge", code: 1, userInfo: [NSLocalizedDescriptionKey: "Некоректний порт"])
            }
            let listener = try NWListener(using: .tcp, on: nwPort)
            self.listener = listener

            listener.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isRunning = true
                        self?.lastError = nil
                    case .failed(let error):
                        self?.isRunning = false
                        self?.lastError = error.localizedDescription
                    case .cancelled:
                        self?.isRunning = false
                    default: break
                    }
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                self?.handle(connection)
            }
            listener.start(queue: queue)
        } catch {
            DispatchQueue.main.async {
                self.lastError = error.localizedDescription
                self.isRunning = false
            }
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        requestHandler = nil
        DispatchQueue.main.async { self.isRunning = false }
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        receive(on: connection, buffer: Data())
    }

    private func receive(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            if let error {
                self.send(status: 500, contentType: "text/plain; charset=utf-8", body: Data(error.localizedDescription.utf8), on: connection)
                return
            }
            var next = buffer
            if let data { next.append(data) }
            if next.range(of: Data("\r\n\r\n".utf8)) != nil || isComplete {
                self.process(next, on: connection)
            } else {
                self.receive(on: connection, buffer: next)
            }
        }
    }

    private func process(_ data: Data, on connection: NWConnection) {
        guard let text = String(data: data, encoding: .utf8),
              let firstLine = text.components(separatedBy: "\r\n").first else {
            send(status: 400, contentType: "text/plain", body: Data("bad request".utf8), on: connection)
            return
        }

        let pieces = firstLine.split(separator: " ")
        guard pieces.count >= 2, pieces[0] == "GET" else {
            send(status: 405, contentType: "text/plain", body: Data("method not allowed".utf8), on: connection)
            return
        }

        let target = String(pieces[1])
        DispatchQueue.main.async { self.lastRequest = target }

        if target.hasPrefix("/health") {
            send(status: 200, contentType: "text/plain; charset=utf-8", body: Data("AudiBridge OK\n".utf8), on: connection)
            return
        }

        guard target.hasPrefix("/poi/search") else {
            send(status: 404, contentType: "text/plain", body: Data("not found".utf8), on: connection)
            return
        }

        guard let request = parseMMIRequest(target) else {
            send(status: 400, contentType: "text/plain", body: Data("invalid MMI request".utf8), on: connection)
            return
        }

        guard let requestHandler else {
            send(status: 503, contentType: "text/plain", body: Data("handler unavailable".utf8), on: connection)
            return
        }

        Task {
            let body = await requestHandler(request)
            self.send(status: 200, contentType: "text/xml; charset=UTF-8", body: body, on: connection)
        }
    }

    private func parseMMIRequest(_ target: String) -> MMIPOISearchRequest? {
        guard let url = URL(string: "http://localhost\(target)"),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        var params: [String: String] = [:]
        for item in components.queryItems ?? [] { params[item.name] = item.value ?? "" }
        guard let key = params["key"],
              let lat = Double(params["lat"] ?? ""),
              let lon = Double(params["lon"] ?? "") else { return nil }
        return MMIPOISearchRequest(
            key: key,
            language: params["lan"] ?? "uk_UA",
            latitude: lat,
            longitude: lon,
            radius: Double(params["radius"] ?? "500") ?? 500,
            count: Int(params["num"] ?? "10") ?? 10,
            index: Int(params["index"] ?? "0") ?? 0,
            rawQuery: params
        )
    }

    private func send(status: Int, contentType: String, body: Data, on connection: NWConnection) {
        let reason: String
        switch status {
        case 200: reason = "OK"
        case 400: reason = "Bad Request"
        case 404: reason = "Not Found"
        case 405: reason = "Method Not Allowed"
        case 503: reason = "Service Unavailable"
        default: reason = "Error"
        }
        let header = "HTTP/1.1 \(status) \(reason)\r\nContent-Type: \(contentType)\r\nContent-Length: \(body.count)\r\nConnection: close\r\nCache-Control: no-cache\r\n\r\n"
        var response = Data(header.utf8)
        response.append(body)
        connection.send(content: response, completion: .contentProcessed { _ in connection.cancel() })
    }
}
