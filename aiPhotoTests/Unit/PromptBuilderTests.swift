import XCTest
@testable import aiPhoto

final class PromptBuilderTests: XCTestCase {
    func test_openai_requestBody() {
        let body = PromptBuilder.openaiRequestBody(imageBase64: "BASE64", model: "gpt-4o")
        let dict = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        XCTAssertEqual(dict?["model"] as? String, "gpt-4o")
        let messages = dict?["messages"] as? [[String: Any]]
        XCTAssertEqual(messages?.count, 2)
        let userContent = messages?[1]["content"] as? [[String: Any]]
        XCTAssertEqual(userContent?.count, 2)
        XCTAssertEqual(userContent?[0]["type"] as? String, "text")
        XCTAssertEqual(userContent?[1]["type"] as? String, "image_url")
        let imageUrl = userContent?[1]["image_url"] as? [String: Any]
        let url = imageUrl?["url"] as? String
        XCTAssertEqual(url, "data:image/jpeg;base64,BASE64")
        let responseFormat = dict?["response_format"] as? [String: Any]
        XCTAssertEqual(responseFormat?["type"] as? String, "json_object")
    }

    func test_claude_requestBody() {
        let body = PromptBuilder.claudeRequestBody(imageBase64: "BASE64", model: "claude-sonnet-4-6")
        let dict = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        XCTAssertEqual(dict?["model"] as? String, "claude-sonnet-4-6")
        let messages = dict?["messages"] as? [[String: Any]]
        XCTAssertEqual(messages?.count, 1)
        let content = messages?[0]["content"] as? [[String: Any]]
        XCTAssertEqual(content?.count, 2)
        XCTAssertEqual(content?[0]["type"] as? String, "image")
        XCTAssertEqual(content?[1]["type"] as? String, "text")
        let image = content?[0]["source"] as? [String: Any]
        XCTAssertEqual(image?["type"] as? String, "base64")
        XCTAssertEqual(image?["media_type"] as? String, "image/jpeg")
        XCTAssertEqual(image?["data"] as? String, "BASE64")
    }

    func test_qwen_requestBody() {
        let body = PromptBuilder.qwenRequestBody(imageBase64: "BASE64", model: "qwen-vl-max")
        let dict = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        XCTAssertEqual(dict?["model"] as? String, "qwen-vl-max")
        let messages = dict?["messages"] as? [[String: Any]]
        let userContent = messages?[1]["content"] as? [[String: Any]]
        let image = userContent?[0]["image"] as? String
        XCTAssertEqual(image, "data:image/jpeg;base64,BASE64")
    }

    func test_systemPrompt_containsKeyConstraints() {
        let prompt = PromptBuilder.systemPrompt
        XCTAssertTrue(prompt.contains("JSON"))
        XCTAssertTrue(prompt.contains("0~1"))
        XCTAssertTrue(prompt.contains("中文"))
    }
}