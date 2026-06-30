import XCTest
import AVFoundation
@testable import aiPhoto

final class VisionServiceTests: XCTestCase {
    func test_conformsToProtocol() {
        let fake: VisionServiceProtocol = FakeVisionService()
        XCTAssertNotNil(fake)
    }
}
