import Foundation

enum AppError: LocalizedError, Equatable {
    case cameraPermissionDenied
    case cameraSessionFailed(underlying: String)
    case modelNotConfigured
    case modelAuthFailed
    case modelRateLimited
    case modelNetworkTimeout
    case modelResponseInvalid
    case modelServerError(code: Int, msg: String)
    case photoLibraryPermissionDenied
    case photoSaveFailed(underlying: String)
    case noSubjectDetected

    var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied:
            return "请在设置中允许 aiPhoto 使用相机"
        case .cameraSessionFailed:
            return "相机启动失败，请重试"
        case .modelNotConfigured:
            return "请先在设置中配置 API Key"
        case .modelAuthFailed:
            return "API Key 无效，请在设置中检查"
        case .modelRateLimited:
            return "调用过于频繁，请稍后再试"
        case .modelNetworkTimeout:
            return "网络超时，请重试"
        case .modelResponseInvalid:
            return "AI 返回内容无法解析"
        case .modelServerError(let code, let msg):
            return "AI 服务异常 (\(code))：\(msg)"
        case .photoLibraryPermissionDenied:
            return "请在设置中允许 aiPhoto 访问相册"
        case .photoSaveFailed:
            return "照片保存失败，请重试"
        case .noSubjectDetected:
            return "画面中未检测到主体，请调整角度"
        }
    }
}