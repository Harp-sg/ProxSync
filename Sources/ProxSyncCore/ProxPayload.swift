import Foundation

/// Any payload you want to ingest over nearby transport / other sources.
public protocol ProxPayload: Codable, Sendable {}

/// Envelope for received payloads.
public struct IngestEnvelope<P: ProxPayload>: Codable, Sendable {
    public let id: String
    public let createdAt: Date
    public let payload: P
    public init(id: String = UUID().uuidString, createdAt: Date = Date(), payload: P) {
        self.id = id; self.createdAt = createdAt; self.payload = payload
    }
}

/// Generic mapper: transform an envelope into a DTO your app persists.
public protocol ProxMapper {
    associatedtype P: ProxPayload
    associatedtype DTO: Sendable
    func map(_ env: IngestEnvelope<P>, context: String, userData: [String: Any]?) throws -> DTO
}

/// A store abstraction (cloud or local).
/// A store abstraction (cloud or local).
public protocol ProxStore {
    associatedtype DTO
    func ensureContext(named: String) async throws
    func save(_ dto: DTO, in context: String) async throws
    func fetchLatest(in context: String, limit: Int) async throws -> [DTO]
}
