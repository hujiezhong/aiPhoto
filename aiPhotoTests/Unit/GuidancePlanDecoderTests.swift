import XCTest
@testable import aiPhoto

final class GuidancePlanDecoderTests: XCTestCase {
    let meta = ModelMeta(kind: .openai)

    func test_pureJSON_succeeds() throws {
        let json = """
        {
          "subjectType": "personWithScene",
          "anchorPoint": {"x": 0.6, "y": 0.4},
          "anchorRadius": 0.08,
          "hint": "把人物放在右上",
          "shotType": "group"
        }
        """
        let plan = try GuidancePlanDecoder.decode(json, modelMeta: meta)
        XCTAssertEqual(plan.subjectType, .personWithScene)
        XCTAssertEqual(plan.anchorPoint.x, 0.6, accuracy: 0.0001)
        XCTAssertEqual(plan.anchorPoint.y, 0.4, accuracy: 0.0001)
        XCTAssertEqual(plan.anchorRadius, 0.08, accuracy: 0.0001)
        XCTAssertEqual(plan.hint, "把人物放在右上")
        XCTAssertEqual(plan.shotType, .group)
        XCTAssertEqual(plan.modelMeta.kind, .openai)
    }

    func test_markdownWrapped_succeeds() throws {
        let wrapped = """
        ```json
        {
          "subjectType": "person",
          "anchorPoint": {"x": 0.5, "y": 0.5},
          "anchorRadius": 0.1,
          "hint": "中心",
          "shotType": "portrait"
        }
        ```
        """
        let plan = try GuidancePlanDecoder.decode(wrapped, modelMeta: meta)
        XCTAssertEqual(plan.subjectType, .person)
    }

    func test_leadingTrailingWhitespace_succeeds() throws {
        let padded = "\n\n  {\"subjectType\":\"scene\",\"anchorPoint\":{\"x\":0.1,\"y\":0.9},\"anchorRadius\":0.05,\"hint\":\"x\",\"shotType\":\"landscape\"}  \n"
        let plan = try GuidancePlanDecoder.decode(padded, modelMeta: meta)
        XCTAssertEqual(plan.subjectType, .scene)
    }

    func test_missingField_throws() {
        let json = """
        {
          "subjectType": "person",
          "anchorPoint": {"x": 0.5, "y": 0.5}
        }
        """
        XCTAssertThrowsError(try GuidancePlanDecoder.decode(json, modelMeta: meta)) { error in
            XCTAssertEqual(error as? AppError, .modelResponseInvalid)
        }
    }

    func test_coordinateOutOfRange_throws() {
        let json = """
        {
          "subjectType": "person",
          "anchorPoint": {"x": 1.5, "y": 0.5},
          "anchorRadius": 0.1,
          "hint": "x",
          "shotType": "portrait"
        }
        """
        XCTAssertThrowsError(try GuidancePlanDecoder.decode(json, modelMeta: meta)) { error in
            XCTAssertEqual(error as? AppError, .modelResponseInvalid)
        }
    }

    func test_typeMismatch_throws() {
        let json = """
        {
          "subjectType": "person",
          "anchorPoint": "center",
          "anchorRadius": 0.1,
          "hint": "x",
          "shotType": "portrait"
        }
        """
        XCTAssertThrowsError(try GuidancePlanDecoder.decode(json, modelMeta: meta)) { error in
            XCTAssertEqual(error as? AppError, .modelResponseInvalid)
        }
    }

    func test_emptyString_throws() {
        XCTAssertThrowsError(try GuidancePlanDecoder.decode("", modelMeta: meta)) { error in
            XCTAssertEqual(error as? AppError, .modelResponseInvalid)
        }
    }
}