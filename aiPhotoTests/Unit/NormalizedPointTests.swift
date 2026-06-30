import XCTest
@testable import aiPhoto

final class NormalizedPointTests: XCTestCase {
    func test_origin_isZero() {
        let p = NormalizedPoint.origin
        XCTAssertEqual(p.x, 0)
        XCTAssertEqual(p.y, 0)
    }

    func test_center_isHalf() {
        let p = NormalizedPoint.center
        XCTAssertEqual(p.x, 0.5)
        XCTAssertEqual(p.y, 0.5)
    }

    func test_equality() {
        XCTAssertEqual(NormalizedPoint(x: 0.3, y: 0.7),
                       NormalizedPoint(x: 0.3, y: 0.7))
    }

    func test_codable_roundtrip() throws {
        let original = NormalizedPoint(x: 0.25, y: 0.75)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NormalizedPoint.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
