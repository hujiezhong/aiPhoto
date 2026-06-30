import XCTest
@testable import aiPhoto

final class AppErrorTests: XCTestCase {
    func test_allCases_haveDescription() {
        let cases: [AppError] = [
            .cameraPermissionDenied,
            .cameraSessionFailed(underlying: "x"),
            .modelNotConfigured,
            .modelAuthFailed,
            .modelRateLimited,
            .modelNetworkTimeout,
            .modelResponseInvalid,
            .modelServerError(code: 500, msg: "boom"),
            .photoLibraryPermissionDenied,
            .photoSaveFailed(underlying: "x"),
            .noSubjectDetected
        ]
        for error in cases {
            XCTAssertNotNil(error.errorDescription, "\(error) 无描述")
            XCTAssertFalse(error.errorDescription!.isEmpty, "\(error) 描述为空")
        }
    }

    func test_descriptions_areInChinese() {
        let cases: [AppError] = [
            .cameraPermissionDenied,
            .modelAuthFailed,
            .noSubjectDetected
        ]
        for error in cases {
            let desc = error.errorDescription!
            let hasChinese = desc.unicodeScalars.contains { $0.value > 0x4E00 && $0.value < 0x9FFF }
            XCTAssertTrue(hasChinese, "\(error) 描述不是中文: \(desc)")
        }
    }
}