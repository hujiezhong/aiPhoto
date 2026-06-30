import Foundation

enum PromptBuilder {
    static let systemPrompt: String = """
    你是一个摄影构图助手。分析这张照片，给出最佳构图方案。

    要求：
    1. 识别主体（人物/景物/合影）
    2. 推荐主体应处于画面哪个位置（黄金分割点/三分法点/中心）
    3. 输出严格JSON，结构：
       {subjectType, anchorPoint:{x,y}, anchorRadius, hint, shotType}
    4. 坐标使用归一化值（0~1），x从左到右，y从上到下
    5. hint用中文，一句话，<20字
    6. 不要输出任何JSON以外内容
    """

    static func openaiRequestBody(imageBase64: String, model: String) -> Data {
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": [
                    ["type": "text", "text": "请分析此图构图。"],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(imageBase64)"]]
                ]]
            ],
            "response_format": ["type": "json_object"],
            "max_tokens": 500
        ]
        return try! JSONSerialization.data(withJSONObject: body)
    }

    static func claudeRequestBody(imageBase64: String, model: String) -> Data {
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 500,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": [
                    ["type": "image", "source": [
                        "type": "base64",
                        "media_type": "image/jpeg",
                        "data": imageBase64
                    ]],
                    ["type": "text", "text": "请分析此图构图。"]
                ]]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: body)
    }

    static func qwenRequestBody(imageBase64: String, model: String) -> Data {
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": [
                    ["image": "data:image/jpeg;base64,\(imageBase64)"],
                    ["text": "请分析此图构图。"]
                ]]
            ],
            "response_format": ["type": "json_object"]
        ]
        return try! JSONSerialization.data(withJSONObject: body)
    }
}