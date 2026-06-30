import XCTest
@testable import aiPhoto

final class VisionModelAdapterTests: XCTestCase {
    func test_protocolExists() {
        // 仅编译期检查：协议可见、可被类实现
        let _: VisionModelAdapter.Type = OpenAIAdapter.self
        let _: VisionModelAdapter.Type = ClaudeAdapter.self
        let _: VisionModelAdapter.Type = QwenAdapter.self
    }
}
