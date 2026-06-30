import XCTest
@testable import aiPhoto

final class AlignmentCalculatorTests: XCTestCase {
    func test_noSubjects_returnsNil() {
        let result = AlignmentCalculator.offset(
            subjects: [],
            anchor: NormalizedPoint(x: 0.5, y: 0.5)
        )
        XCTAssertNil(result)
    }

    func test_subjectAtAnchor_returnsZero() {
        let subjects = [
            DetectedSubject(
                boundingBox: CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2),
                confidence: 0.9,
                type: .person
            )
        ]
        let result = AlignmentCalculator.offset(
            subjects: subjects,
            anchor: NormalizedPoint(x: 0.5, y: 0.5)
        )
        XCTAssertEqual(result ?? -1, 0, accuracy: 0.0001)
    }

    func test_subjectOffsetRight_positiveX() {
        let subjects = [
            DetectedSubject(
                boundingBox: CGRect(x: 0.6, y: 0.4, width: 0.2, height: 0.2),
                confidence: 0.9,
                type: .person
            )
        ]
        let result = AlignmentCalculator.offset(
            subjects: subjects,
            anchor: NormalizedPoint(x: 0.5, y: 0.5)
        )
        XCTAssertEqual(result ?? 0, 0.2, accuracy: 0.001)
    }

    func test_multipleSubjects_pickClosest() {
        let far = DetectedSubject(
            boundingBox: CGRect(x: 0.0, y: 0.0, width: 0.1, height: 0.1),
            confidence: 0.9,
            type: .person
        )
        let close = DetectedSubject(
            boundingBox: CGRect(x: 0.45, y: 0.45, width: 0.1, height: 0.1),
            confidence: 0.8,
            type: .person
        )
        let result = AlignmentCalculator.offset(
            subjects: [far, close],
            anchor: NormalizedPoint(x: 0.5, y: 0.5)
        )
        XCTAssertEqual(result ?? 1, 0, accuracy: 0.001)
    }

    func test_visionCoordinateFlipped() {
        // Vision坐标原点在左下，但anchor用左上原点
        // boundingBox y=0.4, h=0.2 → midY=0.5 → screenY=1.0-0.5=0.5（与anchor一致）
        let subjects = [
            DetectedSubject(
                boundingBox: CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2),
                confidence: 0.9,
                type: .person
            )
        ]
        // screenCenter = (0.5, 0.5) = anchor → 距离 0
        let result = AlignmentCalculator.offset(
            subjects: subjects,
            anchor: NormalizedPoint(x: 0.5, y: 0.5)
        )
        XCTAssertEqual(result ?? -1, 0, accuracy: 0.0001)
    }
}