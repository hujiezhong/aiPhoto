import XCTest
@testable import aiPhoto

final class LogWriterTests: XCTestCase {
    var tempDir: URL!
    var writer: LogWriter!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("logtest-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        writer = LogWriter(directory: tempDir, retentionDays: 7)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func test_write_createsFile() throws {
        try writer.write(level: .info, message: "hello", context: ["k": "v"])
        let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(files.count, 1)
        let content = try String(contentsOf: files[0])
        XCTAssertTrue(content.contains("hello"))
        XCTAssertTrue(content.contains("k=v"))
        XCTAssertTrue(content.contains("INFO"))
    }

    func test_cleanup_removesOldFiles() throws {
        let oldFile = tempDir.appendingPathComponent("2020-01-01.log")
        try "old".write(to: oldFile, atomically: true, encoding: .utf8)
        try writer.write(level: .info, message: "new", context: nil)
        let preCleanupFiles = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(preCleanupFiles.count, 2, "应存在1个旧文件 + 1个当日文件")
        // 触发清理
        try writer.cleanup()
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldFile.path))
        let postCleanupFiles = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(postCleanupFiles.count, 1, "清理后应只剩当日文件")
    }
}
