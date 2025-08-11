import Foundation
import SwiftData

@Model
public final class OutboxItem {
    @Attribute(.unique) public var id: String
    public var path: String
    public var method: String
    public var bodyJSON: String
    public var createdAt: Date
    public var attempts: Int

    public init(id: String = UUID().uuidString, path: String, method: String = "POST", bodyJSON: String) {
        self.id = id; self.path = path; self.method = method; self.bodyJSON = bodyJSON
        self.createdAt = Date(); self.attempts = 0
    }
}
