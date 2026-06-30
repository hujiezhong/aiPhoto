import Foundation

enum ModelKind: String, Codable, CaseIterable, Equatable {
    case openai
    case claude
    case qwenVl

    var displayName: String {
        switch self {
        case .openai: return "OpenAI GPT-4o"
        case .claude: return "Anthropic Claude"
        case .qwenVl: return "通义千问 Qwen-VL"
        }
    }
}