import XCTest
@testable import aiPhoto

final class EnumsTests: XCTestCase {
    func test_subjectType_codable() throws {
        for value in [SubjectType.person, .scene, .personWithScene] {
            let data = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(SubjectType.self, from: data)
            XCTAssertEqual(decoded, value)
        }
    }

    func test_shotType_codable() throws {
        for value in [ShotType.portrait, .landscape, .group] {
            let data = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(ShotType.self, from: data)
            XCTAssertEqual(decoded, value)
        }
    }

    func test_modelKind_caseIterable() {
        XCTAssertEqual(ModelKind.allCases.count, 3)
        XCTAssertTrue(ModelKind.allCases.contains(.openai))
        XCTAssertTrue(ModelKind.allCases.contains(.claude))
        XCTAssertTrue(ModelKind.allCases.contains(.qwenVl))
    }

    func test_modelKind_displayName() {
        XCTAssertFalse(ModelKind.openai.displayName.isEmpty)
        XCTAssertFalse(ModelKind.claude.displayName.isEmpty)
        XCTAssertFalse(ModelKind.qwenVl.displayName.isEmpty)
    }

    func test_modelMeta_codable() throws {
        let meta = ModelMeta(kind: .openai, timestamp: Date(timeIntervalSince1970: 1700000000))
        let data = try JSONEncoder().encode(meta)
        let decoded = try JSONDecoder().decode(ModelMeta.self, from: data)
        XCTAssertEqual(decoded.kind, .openai)
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970, 1700000000, accuracy: 0.001)
    }
}