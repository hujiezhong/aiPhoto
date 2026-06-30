import XCTest
@testable import aiPhoto

final class OpenAIAdapterTests: XCTestCase {
    var session: URLSession!
    var adapter: OpenAIAdapter!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        session = URLSession(configuration: config)
        adapter = OpenAIAdapter(
            apiKey: "test-key",
            model: "gpt-4o",
            endpoint: URL(string: "https://api.openai.com/v1/")!,
            session: session
        )
    }

    func test_success_parsesGuidancePlan() async throws {
        let json = """
        {
          "choices": [{
            "message": {
              "content": "{\\"subjectType\\":\\"person\\",\\"anchorPoint\\":{\\"x\\":0.5,\\"y\\":0.5},\\"anchorRadius\\":0.1,\\"hint\\":\\"中心\\",\\"shotType\\":\\"portrait\\"}"
            }
          }]
        }
        """
        URLProtocolStub.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://api.openai.com/v1/")!,
                             statusCode: 200, httpVersion: nil, headerFields: nil)!,
             json.data(using: .utf8)!)
        }
        let plan = try await adapter.analyze(imageJPEG: Data([0]), model: .openai)
        XCTAssertEqual(plan.subjectType, .person)
        XCTAssertEqual(plan.hint, "中心")
        XCTAssertEqual(plan.modelMeta.kind, .openai)
    }

    func test_401_throwsAuthFailed() async {
        URLProtocolStub.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://api.openai.com/")!,
                             statusCode: 401, httpVersion: nil, headerFields: nil)!,
             Data("{}".utf8))
        }
        do {
            _ = try await adapter.analyze(imageJPEG: Data([0]), model: .openai)
            XCTFail("应抛错")
        } catch let error as AppError {
            XCTAssertEqual(error, .modelAuthFailed)
        } catch {
            XCTFail("错误的错误类型: \(error)")
        }
    }

    func test_429_throwsRateLimited() async {
        URLProtocolStub.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://api.openai.com/")!,
                             statusCode: 429, httpVersion: nil, headerFields: nil)!,
             Data("{}".utf8))
        }
        do {
            _ = try await adapter.analyze(imageJPEG: Data([0]), model: .openai)
            XCTFail("应抛错")
        } catch let error as AppError {
            XCTAssertEqual(error, .modelRateLimited)
        } catch {
            XCTFail("错误的错误类型: \(error)")
        }
    }

    func test_500_throwsServerError() async {
        URLProtocolStub.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://api.openai.com/")!,
                             statusCode: 500, httpVersion: nil, headerFields: nil)!,
             Data("{}".utf8))
        }
        do {
            _ = try await adapter.analyze(imageJPEG: Data([0]), model: .openai)
            XCTFail("应抛错")
        } catch let error as AppError {
            if case .modelServerError(let code, _) = error {
                XCTAssertEqual(code, 500)
            } else {
                XCTFail("错误的错误类型: \(error)")
            }
        }
    }

    func test_invalidJSON_throwsResponseInvalid() async {
        URLProtocolStub.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://api.openai.com/")!,
                             statusCode: 200, httpVersion: nil, headerFields: nil)!,
             Data("not json".utf8))
        }
        do {
            _ = try await adapter.analyze(imageJPEG: Data([0]), model: .openai)
            XCTFail("应抛错")
        } catch let error as AppError {
            XCTAssertEqual(error, .modelResponseInvalid)
        } catch {
            XCTFail("错误的错误类型: \(error)")
        }
    }
}
