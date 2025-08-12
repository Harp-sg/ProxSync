//
//  SupabaseAuthConfig.swift
//  ProxSync
//
//  Created by Arnav Jhajharia on 12/8/25.
//


import Foundation
import ProxSyncAuth

public struct SupabaseAuthConfig: Sendable {
    public let projectURL: URL      // e.g., https://YOUR.supabase.co
    public let anonKey: String      // public anon key (safe for client)
    public init(projectURL: URL, anonKey: String) {
        self.projectURL = projectURL
        self.anonKey = anonKey
    }
}

public struct SupabaseSession: ProxAuthSession, Decodable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let tokenType: String
    public let expiresIn: Int
    public let userID: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType    = "token_type"
        case expiresIn    = "expires_in"
        case user
    }
    enum UserKeys: String, CodingKey { case id }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken  = try c.decode(String.self, forKey: .accessToken)
        self.refreshToken = try c.decode(String.self, forKey: .refreshToken)
        self.tokenType    = try c.decode(String.self, forKey: .tokenType)
        self.expiresIn    = try c.decode(Int.self, forKey: .expiresIn)
        if let uc = try? c.nestedContainer(keyedBy: UserKeys.self, forKey: .user) {
            self.userID = try? uc.decode(String.self, forKey: .id)
        } else {
            self.userID = nil
        }
    }
}

public final class SupabaseAuthProvider: ProxAuthProvider, @unchecked Sendable {
    private let cfg: SupabaseAuthConfig
    public init(cfg: SupabaseAuthConfig) { self.cfg = cfg }

    public func signUp(email: String, password: String) async throws {
        var req = URLRequest(url: cfg.projectURL.appendingPathComponent("/auth/v1/signup"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(cfg.anonKey, forHTTPHeaderField: "apikey")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "password": password])
        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.throwIfBad(resp, data: data)
        // Supabase may require email confirm; no session returned on sign-up.
    }

    public func login(email: String, password: String) async throws -> ProxAuthSession {
        var comps = URLComponents(url: cfg.projectURL.appendingPathComponent("/auth/v1/token"),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "grant_type", value: "password")]

        var req = URLRequest(url: comps.url!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(cfg.anonKey, forHTTPHeaderField: "apikey")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "password": password])

        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.throwIfBad(resp, data: data)
        do {
            return try JSONDecoder().decode(SupabaseSession.self, from: data)
        } catch {
            throw ProxAuthError.decoding(String(describing: error))
        }
    }

    public func refresh(using refreshToken: String) async throws -> ProxAuthSession {
        var comps = URLComponents(url: cfg.projectURL.appendingPathComponent("/auth/v1/token"),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]

        var req = URLRequest(url: comps.url!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(cfg.anonKey, forHTTPHeaderField: "apikey")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token": refreshToken])

        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.throwIfBad(resp, data: data)
        do {
            return try JSONDecoder().decode(SupabaseSession.self, from: data)
        } catch {
            throw ProxAuthError.decoding(String(describing: error))
        }
    }

    public func logout() async {
        // No server call needed for public clients; just clear local session in app.
    }

    // MARK: - Helpers
    private static func throwIfBad(_ resp: URLResponse, data: Data) throws {
        guard let http = resp as? HTTPURLResponse else { throw ProxAuthError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            throw ProxAuthError.http(http.statusCode, body)
        }
    }
}
