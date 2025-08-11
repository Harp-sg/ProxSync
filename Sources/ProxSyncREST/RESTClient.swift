import Foundation

public struct RESTConfig: Sendable {
    public let baseURL: URL
    public init(baseURL: URL) { self.baseURL = baseURL }
}

public actor RESTClient {
    let cfg: RESTConfig
    private var bearer: String?
    public init(cfg: RESTConfig) { self.cfg = cfg }
    public func setBearer(_ token: String?) { bearer = token }

    public func post(path: String, json: Any, extraHeaders: [String:String] = [:]) async throws -> Data {
        var req = URLRequest(url: cfg.baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        extraHeaders.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        if let bearer { req.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization") }
        req.httpBody = try JSONSerialization.data(withJSONObject: json, options: [])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "REST", code: 1, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "HTTP error"])
        }
        return data
    }

    public func get(path: String, query: String = "", extraHeaders: [String:String] = [:]) async throws -> Data {
        var url = cfg.baseURL.appendingPathComponent(path)
        if !query.isEmpty {
            url = URL(string: url.absoluteString + (url.query == nil ? "?" : "&") + query)!
        }
        var req = URLRequest(url: url)
        extraHeaders.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        if let bearer { req.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization") }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "REST", code: 2, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "HTTP error"])
        }
        return data
    }
}
