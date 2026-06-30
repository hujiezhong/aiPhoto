import XCTest
import UIKit
@testable import aiPhoto

final class PhotoSaverTests: XCTestCase {
    func test_conformsToProtocol() {
        let fake: PhotoSaverProtocol = FakePhotoSaver()
        XCTAssertNotNil(fake)
    }
}
