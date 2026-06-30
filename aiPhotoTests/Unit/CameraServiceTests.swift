import XCTest
import AVFoundation
@testable import aiPhoto

final class CameraServiceTests: XCTestCase {
    func test_conformsToProtocol() {
        // 仅编译期：FakeCameraService 满足协议
        let fake: CameraServiceProtocol = FakeCameraService()
        XCTAssertNotNil(fake)
    }
}