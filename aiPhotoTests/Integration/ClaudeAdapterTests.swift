import XCTest
@testable import aiPhoto

final class ClaudeAdapterTests: XCTestCase {
    var session: URLSession!
    var adapter: ClaudeAdapter!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        session = URLSession(configuration: config)
        adapter = ClaudeAdapter(
            apiKey: "test-key",
            model: "claude-sonnet-4-6",
            endpoint: URL(string: "https://api.anthropic.com/v1/")!,
            session: session
        )
    }

    func test_success_parsesGuidancePlan() async throws {
        let json = """
        {
          "content": [{
            "type": "text",
            "text": "{\\"subjectType\\":\\"scene\\",\\"anchorPoint\\":{\\"x\\":0.3,\\"y\\":0.7},\\"anchorRadius\\":0.08,\\"hint\\":\\"把山放左下\\",\\"shotType\\":\\"landscape\\"}"
          }]
        }
        """
        URLProtocolStub.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://api.anthropic.com/v1/")!,
                             statusCode: 200, httpVersion: nil, headerFields: nil)!,
             json.data(using: .utf8)!)
        }
        let plan = try await adapter.analyze(imageJPEG: Data([0]), model: .claude)
        XCTAssertEqual(plan.subjectType, .scene)
        XCTAssertEqual(plan.hint, "把山放左下")
    }

    func test_401_throwsAuthFailed() async {
        URLProtocolStub.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://api.anthropic.com/")!,
                             statusCode: 401, httpVersion: nil, headerFields: nil)!,
             Data("{}".utf8))
        }
        do {
            _ = try await adapter.analyze(imageJPEG: Data([0]), model: .claude)
            XCTFail("应抛错")
        } catch let error as AppError {
            XCTAssertEqual(error, .modelAuthFailed)
        } catch {
            XCTFail("错误的错误类型: \(error)")
        }
    }

    func test_429_throwsRateLimited() async {
        URLProtocolStub.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://api.anthropic.com/")!,
                             statusCode: 429, httpVersion: nil, headerFields: nil)!,
             Data("{}".utf8))
        }
        do {
            _ = try await adapter.analyze(imageJPEG: Data([0]), model: .claude)
            XCTFail("应抛错")
        } catch let error as AppError {
            XCTAssertEqual(error, .modelRateLimited)
        } catch {
            XCTFail("错误的错误类型: \(error)")
        }
    }
}