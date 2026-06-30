import Foundation

final class OpenAIAdapter: VisionModelAdapter {
    let kind: ModelKind = .openai
    let apiKey: String
    let model: String
    let endpoint: URL
    let session: URLSession

    init(
        apiKey: String,
        model: String = "gpt-4o",
        endpoint: URL = URL(string: "https://api.openai.com/v1/")!,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = endpoint
        self.session = session
    }

    func analyze(imageJPEG: Data, model: ModelKind) async throws -> GuidancePlan {
        let base64 = imageJPEG.base64EncodedString()
        let body = PromptBuilder.openaiRequestBody(imageBase64: base64, model: model)
        var request = URLRequest(url: endpoint.appendingPathComponent("chat/completions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        request.timeoutInterval = 15

        let (data, response) = try await sendWithTimeout(request)
        let http = response as! HTTPURLResponse
        try mapStatus(http.statusCode)

        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = dict["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String
        else {
            throw AppError.modelResponseInvalid
        }

        return try GuidancePlanDecoder.decode(content, modelMeta: ModelMeta(kind: self.kind))
    }

    private func sendWithTimeout(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw AppError.modelNetworkTimeout
        }
    }

    private func mapStatus(_ code: Int) throws {
        switch code {
        case 200..<300: return
        case 401, 403: throw AppError.modelAuthFailed
        case 429: throw AppError.modelRateLimited
        default: throw AppError.modelServerError(code: code, msg: "HTTP \(code)")
        }
    }
}
