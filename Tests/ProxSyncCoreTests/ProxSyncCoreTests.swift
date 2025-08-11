import XCTest
@testable import ProxSyncCore

final class ProxSyncCoreTests: XCTestCase {
    struct P: ProxPayload { let x: Int }
    func testEnvelope() throws {
        let env = IngestEnvelope(payload: P(x: 42))
        XCTAssertEqual(env.payload.x, 42)
        XCTAssertFalse(env.id.isEmpty)
    }
}
