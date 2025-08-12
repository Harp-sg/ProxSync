import Foundation

public protocol ProxAuthSession: Sendable {
    var accessToken: String { get }
    var refreshToken: String { get }
    var userID: String? { get }
    var expiresIn: Int { get }
    var tokenType: String { get }
}

public protocol ProxAuthProvider: AnyObject, Sendable {
    /// Sign up a new user. Some projects require email confirmation.
    func signUp(email: String, password: String) async throws

    /// Log in with email/password and return a session (JWT etc.)
    func login(email: String, password: String) async throws -> ProxAuthSession

    /// Refresh an access token using a refresh token.
    func refresh(using refreshToken: String) async throws -> ProxAuthSession

    /// Client-side logout hook (usually clears local session only).
    func logout() async
}

public enum ProxAuthError: LocalizedError, Sendable {
    case http(Int, String)
    case invalidResponse
    case decoding(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .http(let code, let body): return "HTTP \(code): \(body)"
        case .invalidResponse: return "Invalid response"
        case .decoding(let msg): return "Decoding error: \(msg)"
        case .unknown(let msg): return msg
        }
    }
}
