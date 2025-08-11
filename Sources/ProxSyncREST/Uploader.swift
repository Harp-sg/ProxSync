import Foundation
import SwiftData
import ProxSyncCore
import ProxSyncLocal

public final class Uploader {
    private let rest: RESTClient
    private let ctx: ModelContext
    private let extraHeaders: [String:String]

    public init(rest: RESTClient, context: ModelContext, extraHeaders: [String:String] = [:]) {
        self.rest = rest; self.ctx = context; self.extraHeaders = extraHeaders
    }

    public func enqueue(path: String, body: Any) throws {
        let json = try JSONSerialization.data(withJSONObject: body, options: [])
        let s = String(data: json, encoding: .utf8)!
        ctx.insert(OutboxItem(path: path, bodyJSON: s))
        try ctx.save()
    }

    public func flush() async {
        let fetch = FetchDescriptor<OutboxItem>(
            sortBy: [SortDescriptor(\OutboxItem.createdAt)]
        )
        guard let items = try? ctx.fetch(fetch) else { return }

        for item in items {
            do {
                let obj = try JSONSerialization.jsonObject(with: Data(item.bodyJSON.utf8))
                _ = try await rest.post(path: item.path, json: obj, extraHeaders: extraHeaders)
                ctx.delete(item)
                try? ctx.save()
            } catch {
                item.attempts += 1
                try? ctx.save()
                let wait = Backoff.delay(for: item.attempts)
                try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            }
        }
    }

}
