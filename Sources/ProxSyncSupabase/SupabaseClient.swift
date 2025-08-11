import Foundation

public struct SupabaseConfig: Sendable {
    public let url: URL          // e.g., https://YOUR.supabase.co
    public let anonKey: String   // anon public key
    public init(url: URL, anonKey: String) { self.url = url; self.anonKey = anonKey }
}

public actor SupabaseClient {
    let cfg: SupabaseConfig
    private var jwt: String?

    public init(cfg: SupabaseConfig) { self.cfg = cfg }
    public func setJWT(_ token: String?) { jwt = token }

    public func post(table: String, json: Any) async throws -> Data {
        var req = URLRequest(url: cfg.url.appendingPathComponent("/rest/v1/\(table)"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(cfg.anonKey, forHTTPHeaderField: "apikey")
        if let jwt { req.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization") }
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONSerialization.data(withJSONObject: json, options: [])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "Supabase", code: 1, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "HTTP error"])
        }
        return data
    }

    public func get(table: String, query: String) async throws -> Data {
        var url = cfg.url.appendingPathComponent("/rest/v1/\(table)")
        if !query.isEmpty { url = URL(string: url.absoluteString + "?\(query)")! }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue(cfg.anonKey, forHTTPHeaderField: "apikey")
        if let jwt { req.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization") }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "Supabase", code: 2, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "HTTP error"])
        }
        return data
    }
}
