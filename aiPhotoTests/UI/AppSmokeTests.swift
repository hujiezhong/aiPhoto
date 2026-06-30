import XCTest

final class AppSmokeTests: XCTestCase {
    func test_appLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        // 验证主要 UI 元素存在
        XCTAssertTrue(app.buttons["分析"].waitForExistence(timeout: 5),
                      "未找到'分析'按钮")
    }
}
