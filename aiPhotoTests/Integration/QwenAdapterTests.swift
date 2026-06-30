import XCTest
@testable import aiPhoto

final class QwenAdapterTests: XCTestCase {
    var session: URLSession!
    var adapter: QwenAdapter!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        session = URLSession(configuration: config)
        adapter = QwenAdapter(
            apiKey: "test-key",
            model: "qwen-vl-max",
            endpoint: URL(string: "https://dashscope.aliyuncs.com/compatible-mode/v1/")!,
            session: session
        )
    }

    func test_success_parsesGuidancePlan() async throws {
        let json = """
        {
          "choices": [{
            "message": {
              "content": "{\\"subjectType\\":\\"personWithScene\\",\\"anchorPoint\\":{\\"x\\":0.618,\\"y\\":0.382},\\"anchorRadius\\":0.08,\\"hint\\":\\"黄金分割点\\",\\"shotType\\":\\"group\\"}"
            }
          }]
        }
        """
        URLProtocolStub.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://dashscope.aliyuncs.com/")!,
                             statusCode: 200, httpVersion: nil, headerFields: nil)!,
             json.data(using: .utf8)!)
        }
        let plan = try await adapter.analyze(imageJPEG: Data([0]), model: .qwenVl)
        XCTAssertEqual(plan.subjectType, .personWithScene)
        XCTAssertEqual(plan.hint, "黄金分割点")
    }

    func test_401_throwsAuthFailed() async {
        URLProtocolStub.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://dashscope.aliyuncs.com/")!,
                             statusCode: 401, httpVersion: nil, headerFields: nil)!,
             Data("{}".utf8))
        }
        do {
            _ = try await adapter.analyze(imageJPEG: Data([0]), model: .qwenVl)
            XCTFail("应抛错")
        } catch let error as AppError {
            XCTAssertEqual(error, .modelAuthFailed)
        } catch {
            XCTFail("错误的错误类型: \(error)")
        }
    }
}
