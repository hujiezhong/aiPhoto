import XCTest
@testable import aiPhoto

final class GuidancePlanTests: XCTestCase {
    func test_codable_roundtrip() throws {
        let plan = GuidancePlan(
            subjectType: .personWithScene,
            anchorPoint: NormalizedPoint(x: 0.618, y: 0.382),
            anchorRadius: 0.08,
            hint: "把人物放到右上引导点",
            shotType: .group,
            modelMeta: ModelMeta(kind: .openai)
        )
        let data = try JSONEncoder().encode(plan)
        let decoded = try JSONDecoder().decode(GuidancePlan.self, from: data)
        XCTAssertEqual(decoded, plan)
    }

    func test_equality() {
        let a = GuidancePlan(
            subjectType: .person,
            anchorPoint: .center,
            anchorRadius: 0.1,
            hint: "x",
            shotType: .portrait,
            modelMeta: ModelMeta(kind: .claude, timestamp: Date(timeIntervalSince1970: 0))
        )
        let b = GuidancePlan(
            subjectType: .person,
            anchorPoint: .center,
            anchorRadius: 0.1,
            hint: "x",
            shotType: .portrait,
            modelMeta: ModelMeta(kind: .claude, timestamp: Date(timeIntervalSince1970: 0))
        )
        XCTAssertEqual(a, b)
    }
}