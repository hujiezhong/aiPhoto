import XCTest
@testable import aiPhoto

final class AppSettingsTests: XCTestCase {
    var defaults: UserDefaults!
    let suiteName = "com.aiphoto.tests.settings.\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func test_defaultValues() {
        let store = AppSettingsStore(defaults: defaults)
        XCTAssertEqual(store.settings.selectedModel, .openai)
        XCTAssertTrue(store.settings.autoCapture)
        XCTAssertEqual(store.settings.alignmentThreshold, 0.05, accuracy: 0.0001)
    }

    func test_update_andLoad() {
        let store = AppSettingsStore(defaults: defaults)
        var s = store.settings
        s.selectedModel = .claude
        s.autoCapture = false
        s.alignmentThreshold = 0.10
        store.settings = s

        let store2 = AppSettingsStore(defaults: defaults)
        XCTAssertEqual(store2.settings.selectedModel, .claude)
        XCTAssertFalse(store2.settings.autoCapture)
        XCTAssertEqual(store2.settings.alignmentThreshold, 0.10, accuracy: 0.0001)
    }

    func test_corruptedData_fallsBackToDefault() {
        defaults.set("not json".data(using: .utf8), forKey: "appSettings.v1")
        let store = AppSettingsStore(defaults: defaults)
        XCTAssertEqual(store.settings.selectedModel, .openai)
    }
}
