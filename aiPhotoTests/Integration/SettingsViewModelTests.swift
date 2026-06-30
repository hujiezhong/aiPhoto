import XCTest
@testable import aiPhoto

@MainActor
final class SettingsViewModelTests: XCTestCase {
    var settings: AppSettingsStore!
    var keychain: KeychainStore!
    var defaults: UserDefaults!
    let suiteName = "settings-vm-\(UUID().uuidString)"
    let kcService = "kc-vm-\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        settings = AppSettingsStore(defaults: defaults)
        keychain = KeychainStore(service: kcService)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func test_initialValues() {
        let vm = SettingsViewModel(settings: settings, keychain: keychain)
        XCTAssertEqual(vm.selectedModel, .openai)
        XCTAssertTrue(vm.autoCapture)
        XCTAssertEqual(vm.alignmentThreshold, 0.05, accuracy: 0.0001)
        XCTAssertEqual(vm.apiKey, "")
    }

    func test_setApiKey_persistsToKeychain() throws {
        let vm = SettingsViewModel(settings: settings, keychain: keychain)
        vm.apiKey = "sk-abc"
        try vm.save()

        let kc = KeychainStore(service: kcService)
        XCTAssertEqual(try kc.get("apiKey"), "sk-abc")
    }

    func test_setSelectedModel_persists() {
        let vm = SettingsViewModel(settings: settings, keychain: keychain)
        vm.selectedModel = .claude
        vm.save()

        let vm2 = SettingsViewModel(settings: settings, keychain: keychain)
        XCTAssertEqual(vm2.selectedModel, .claude)
    }
}