import XCTest
@testable import aiPhoto

final class KeychainStoreTests: XCTestCase {
    var store: KeychainStore!
    let testKey = "test.api.key.\(UUID().uuidString)"
    let service = "com.aiphoto.tests"

    override func setUp() {
        super.setUp()
        store = KeychainStore(service: service)
    }

    override func tearDown() {
        try? store.delete(testKey)
        super.tearDown()
    }

    func test_set_thenGet_returnsSameValue() throws {
        try store.set("secret-123", for: testKey)
        let value = try store.get(testKey)
        XCTAssertEqual(value, "secret-123")
    }

    func test_get_missingKey_throws() {
        XCTAssertThrowsError(try store.get("nonexistent-\(UUID().uuidString)"))
    }

    func test_set_overwritesPrevious() throws {
        try store.set("first", for: testKey)
        try store.set("second", for: testKey)
        let value = try store.get(testKey)
        XCTAssertEqual(value, "second")
    }

    func test_delete_removesValue() throws {
        try store.set("x", for: testKey)
        try store.delete(testKey)
        XCTAssertThrowsError(try store.get(testKey))
    }
}