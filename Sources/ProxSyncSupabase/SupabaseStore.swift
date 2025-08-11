import Foundation
import ProxSyncCore

/// A generic ProxStore implemented on Supabase REST; caller provides encode/decode closures.
public final class SupabaseStore<Item: Sendable>: ProxStore {

    public typealias DTO = Item

    private let supa: SupabaseClient
    
    private let encodeDTO: (DTO) throws -> [String: Any]
    private let decodeList: (Data) throws -> [DTO]
    private var teamIDs: [String: String] = [:]

    public init(client: SupabaseClient,
                encode: @escaping (DTO) throws -> [String: Any],
                decodeList: @escaping (Data) throws -> [DTO]) {
        self.supa = client; self.encodeDTO = encode; self.decodeList = decodeList
    }

    public func ensureContext(named name: String) async throws {
        if teamIDs[name] != nil { return }
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let data = try await supa.get(table: "teams", query: "name=eq.\(encoded)&select=id&limit=1")
        if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String:Any]],
           let id = arr.first?["id"] as? String {
            teamIDs[name] = id; return
        }
        let back = try await supa.post(table: "teams", json: [["name": name]])
        if let arr = try? JSONSerialization.jsonObject(with: back) as? [[String:Any]],
           let id = arr.first?["id"] as? String {
            teamIDs[name] = id
        }
    }

    public func save(_ dto: DTO, in context: String) async throws {
        try await ensureContext(named: context)
        _ = try await supa.post(table: "assessments", json: [try encodeDTO(dto)])
    }

    public func fetchLatest(in context: String, limit: Int) async throws -> [DTO] {
        try await ensureContext(named: context)
        let data = try await supa.get(table: "team_assessments",
                                     query: "name=eq.\(context)&order=ended_at.desc&limit=\(limit)")
        return try decodeList(data)
    }
}
