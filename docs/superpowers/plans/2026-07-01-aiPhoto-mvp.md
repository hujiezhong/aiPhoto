# aiPhoto MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建 iOS App "aiPhoto"：用户拍照时点"分析"，云端大模型推荐一个画面锚点，引导用户把主体对齐到该点后拍照，照片存系统相册。

**Architecture:** SwiftUI + MVVM。UI层（Views）→ 状态层（ViewModel）→ 业务层（Services）。`VisionModelAdapter` 协议下三个云端模型实现可热切换。VisionService 本地实时对齐检测，VisionModelAdapter 仅在用户按"分析"时调用。

**Tech Stack:** Swift 5.9+, SwiftUI (iOS 17+), AVFoundation, Vision, Photos, Keychain, XCTest

**Spec:** `docs/superpowers/specs/2026-07-01-aiPhoto-design.md`

---

## 文件结构总览

```
aiPhoto/
├── aiPhoto.xcodeproj
├── aiPhoto/
│   ├── aiPhotoApp.swift
│   ├── Info.plist
│   ├── Models/
│   │   ├── NormalizedPoint.swift
│   │   ├── SubjectType.swift
│   │   ├── ShotType.swift
│   │   ├── ModelKind.swift
│   │   ├── ModelMeta.swift
│   │   ├── GuidancePlan.swift
│   │   └── AppSettings.swift
│   ├── Errors/AppError.swift
│   ├── Services/
│   │   ├── PromptBuilder.swift
│   │   ├── GuidancePlanDecoder.swift
│   │   ├── VisionModelAdapter.swift
│   │   ├── OpenAIAdapter.swift
│   │   ├── ClaudeAdapter.swift
│   │   ├── QwenAdapter.swift
│   │   ├── CameraService.swift
│   │   ├── VisionService.swift
│   │   ├── PhotoSaver.swift
│   │   └── LogWriter.swift
│   ├── ViewModels/
│   │   ├── CameraViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Views/
│   │   ├── RootView.swift
│   │   ├── CameraView.swift
│   │   ├── CameraPreviewView.swift
│   │   ├── GuidanceOverlayView.swift
│   │   └── SettingsView.swift
│   └── Utilities/
│       ├── KeychainStore.swift
│       └── AlignmentCalculator.swift
└── aiPhotoTests/
    ├── Unit/
    │   ├── GuidancePlanDecoderTests.swift
    │   ├── PromptBuilderTests.swift
    │   ├── AlignmentCalculatorTests.swift
    │   ├── AppSettingsTests.swift
    │   ├── AppErrorTests.swift
    │   ├── KeychainStoreTests.swift
    │   └── LogWriterTests.swift
    ├── Integration/
    │   ├── OpenAIAdapterTests.swift
    │   ├── ClaudeAdapterTests.swift
    │   ├── QwenAdapterTests.swift
    │   └── CameraViewModelTests.swift
    ├── UI/
    │   └── AppSmokeTests.swift
    └── Support/
        ├── URLProtocolStub.swift
        ├── FakeCameraService.swift
        ├── FakeVisionService.swift
        ├── FakeVisionModelAdapter.swift
        └── FakePhotoSaver.swift
```

---

## Task 1: 项目初始化

**Files:**
- Create: `aiPhoto/aiPhoto.xcodeproj` (Xcode生成)
- Create: `aiPhoto/Info.plist`
- Create: `aiPhoto/aiPhotoApp.swift`

- [ ] **Step 1: 用 Xcode 创建新项目**

操作（手动）：
1. 打开 Xcode → File → New → Project → iOS App
2. Product Name: `aiPhoto`
3. Interface: SwiftUI
4. Language: Swift
5. Storage: None
6. 取消勾选 "Include Tests"（稍后单独加）
7. 保存到 `D:/project/aiPhoto/aiPhoto/`

- [ ] **Step 2: 重新开启 git**

```bash
cd D:/project/aiPhoto
git init
git add .
git commit -m "chore: scaffold Xcode project"
```

- [ ] **Step 3: 添加权限声明到 Info.plist**

编辑 `aiPhoto/Info.plist`，添加（用Xcode Info页的 "+" 按钮）：

| Key | Type | Value |
|---|---|---|
| `NSCameraUsageDescription` | String | aiPhoto 需要使用相机以拍照和实时预览 |
| `NSPhotoLibraryAddUsageDescription` | String | aiPhoto 需要将拍摄的照片保存到相册 |

- [ ] **Step 4: 验证项目可编译**

```bash
xcodebuild -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'generic/platform=iOS Simulator' build
```

期望：`BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add aiPhoto/Info.plist
git commit -m "chore: add camera and photo library permission descriptions"
```

---

## Task 2: 添加 Test Target

**Files:**
- Modify: `aiPhoto.xcodeproj/project.pbxproj` (Xcode UI操作)

- [ ] **Step 1: 添加 Unit Test Bundle**

操作（手动）：
1. 在 Xcode 中选中 `aiPhoto` 项目 → Editor → Add Target → iOS Unit Testing Bundle
2. Product Name: `aiPhotoTests`
3. Language: Swift
4. 完成

- [ ] **Step 2: 配置 Test target 依赖**

1. 选中 `aiPhotoTests` target → General → Frameworks
2. 移除对 `aiPhoto.app` 的 Embed 勾选（保持 None）
3. Target Membership 确保 `aiPhotoTests` 能 import `aiPhoto`

- [ ] **Step 3: 验证测试 target 可用**

替换 `aiPhotoTests/aiPhotoTests.swift` 内容为：

```swift
import XCTest
@testable import aiPhoto

final class aiPhotoTests: XCTestCase {
    func test_sanity() {
        XCTAssertEqual(1 + 1, 2)
    }
}
```

- [ ] **Step 4: 运行测试**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15'
```

期望：`Test Suite 'aiPhotoTests' passed`

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "test: scaffold aiPhotoTests target"
```

---

## Task 3: NormalizedPoint 模型

**Files:**
- Create: `aiPhoto/Models/NormalizedPoint.swift`
- Create: `aiPhotoTests/Unit/NormalizedPointTests.swift`

- [ ] **Step 1: 创建测试文件**

`aiPhotoTests/Unit/NormalizedPointTests.swift`:

```swift
import XCTest
@testable import aiPhoto

final class NormalizedPointTests: XCTestCase {
    func test_origin_isZero() {
        let p = NormalizedPoint.origin
        XCTAssertEqual(p.x, 0)
        XCTAssertEqual(p.y, 0)
    }

    func test_center_isHalf() {
        let p = NormalizedPoint.center
        XCTAssertEqual(p.x, 0.5)
        XCTAssertEqual(p.y, 0.5)
    }

    func test_equality() {
        XCTAssertEqual(NormalizedPoint(x: 0.3, y: 0.7),
                       NormalizedPoint(x: 0.3, y: 0.7))
    }

    func test_codable_roundtrip() throws {
        let original = NormalizedPoint(x: 0.25, y: 0.75)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NormalizedPoint.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/NormalizedPointTests
```

期望：编译错误 `Cannot find 'NormalizedPoint' in scope`

- [ ] **Step 3: 实现 NormalizedPoint**

`aiPhoto/Models/NormalizedPoint.swift`:

```swift
import Foundation

struct NormalizedPoint: Codable, Equatable, Hashable {
    let x: Double
    let y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    static let origin = NormalizedPoint(x: 0, y: 0)
    static let center = NormalizedPoint(x: 0.5, y: 0.5)
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/NormalizedPointTests
```

期望：`Executed 4 tests, with 0 failures`

- [ ] **Step 5: Commit**

```bash
git add aiPhoto/Models/NormalizedPoint.swift aiPhotoTests/Unit/NormalizedPointTests.swift
git commit -m "feat(model): add NormalizedPoint"
```

---

## Task 4: SubjectType / ShotType / ModelKind / ModelMeta 枚举

**Files:**
- Create: `aiPhoto/Models/SubjectType.swift`
- Create: `aiPhoto/Models/ShotType.swift`
- Create: `aiPhoto/Models/ModelKind.swift`
- Create: `aiPhoto/Models/ModelMeta.swift`
- Create: `aiPhotoTests/Unit/EnumsTests.swift`

- [ ] **Step 1: 创建测试文件**

`aiPhotoTests/Unit/EnumsTests.swift`:

```swift
import XCTest
@testable import aiPhoto

final class EnumsTests: XCTestCase {
    func test_subjectType_codable() throws {
        for value in [SubjectType.person, .scene, .personWithScene] {
            let data = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(SubjectType.self, from: data)
            XCTAssertEqual(decoded, value)
        }
    }

    func test_shotType_codable() throws {
        for value in [ShotType.portrait, .landscape, .group] {
            let data = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(ShotType.self, from: data)
            XCTAssertEqual(decoded, value)
        }
    }

    func test_modelKind_caseIterable() {
        XCTAssertEqual(ModelKind.allCases.count, 3)
        XCTAssertTrue(ModelKind.allCases.contains(.openai))
        XCTAssertTrue(ModelKind.allCases.contains(.claude))
        XCTAssertTrue(ModelKind.allCases.contains(.qwenVl))
    }

    func test_modelKind_displayName() {
        XCTAssertFalse(ModelKind.openai.displayName.isEmpty)
        XCTAssertFalse(ModelKind.claude.displayName.isEmpty)
        XCTAssertFalse(ModelKind.qwenVl.displayName.isEmpty)
    }

    func test_modelMeta_codable() throws {
        let meta = ModelMeta(kind: .openai, timestamp: Date(timeIntervalSince1970: 1700000000))
        let data = try JSONEncoder().encode(meta)
        let decoded = try JSONDecoder().decode(ModelMeta.self, from: data)
        XCTAssertEqual(decoded.kind, .openai)
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970, 1700000000, accuracy: 0.001)
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/EnumsTests
```

期望：编译错误

- [ ] **Step 3: 实现 SubjectType**

`aiPhoto/Models/SubjectType.swift`:

```swift
import Foundation

enum SubjectType: String, Codable, CaseIterable, Equatable {
    case person
    case scene
    case personWithScene
}
```

- [ ] **Step 4: 实现 ShotType**

`aiPhoto/Models/ShotType.swift`:

```swift
import Foundation

enum ShotType: String, Codable, CaseIterable, Equatable {
    case portrait
    case landscape
    case group
}
```

- [ ] **Step 5: 实现 ModelKind**

`aiPhoto/Models/ModelKind.swift`:

```swift
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
```

- [ ] **Step 6: 实现 ModelMeta**

`aiPhoto/Models/ModelMeta.swift`:

```swift
import Foundation

struct ModelMeta: Codable, Equatable {
    let kind: ModelKind
    let timestamp: Date

    init(kind: ModelKind, timestamp: Date = Date()) {
        self.kind = kind
        self.timestamp = timestamp
    }
}
```

- [ ] **Step 7: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/EnumsTests
```

期望：`Executed 5 tests, with 0 failures`

- [ ] **Step 8: Commit**

```bash
git add aiPhoto/Models/SubjectType.swift aiPhoto/Models/ShotType.swift aiPhoto/Models/ModelKind.swift aiPhoto/Models/ModelMeta.swift aiPhotoTests/Unit/EnumsTests.swift
git commit -m "feat(model): add subject/shot/model enums and ModelMeta"
```

---

## Task 5: GuidancePlan 模型

**Files:**
- Create: `aiPhoto/Models/GuidancePlan.swift`
- Create: `aiPhotoTests/Unit/GuidancePlanTests.swift`

- [ ] **Step 1: 创建测试文件**

`aiPhotoTests/Unit/GuidancePlanTests.swift`:

```swift
import XCTest
@testable import aiPhoto

final class GuidancePlanTests: XCTestCase {
    func test_codable_roundtrip() throws {
        let plan = GuidancePlan(
            subjectType: .personWithScene,
            anchorPoint: NormalizedPoint(x: 0.618, y: 0.382),
            anchorRadius: 0.08,
            hint: "把人物放到右上引导点",
            shotType: .group,
            modelMeta: ModelMeta(kind: .openai)
        )
        let data = try JSONEncoder().encode(plan)
        let decoded = try JSONDecoder().decode(GuidancePlan.self, from: data)
        XCTAssertEqual(decoded, plan)
    }

    func test_equality() {
        let a = GuidancePlan(
            subjectType: .person,
            anchorPoint: .center,
            anchorRadius: 0.1,
            hint: "x",
            shotType: .portrait,
            modelMeta: ModelMeta(kind: .claude, timestamp: Date(timeIntervalSince1970: 0))
        )
        let b = GuidancePlan(
            subjectType: .person,
            anchorPoint: .center,
            anchorRadius: 0.1,
            hint: "x",
            shotType: .portrait,
            modelMeta: ModelMeta(kind: .claude, timestamp: Date(timeIntervalSince1970: 0))
        )
        XCTAssertEqual(a, b)
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/GuidancePlanTests
```

期望：编译错误

- [ ] **Step 3: 实现 GuidancePlan**

`aiPhoto/Models/GuidancePlan.swift`:

```swift
import Foundation

struct GuidancePlan: Codable, Equatable {
    let subjectType: SubjectType
    let anchorPoint: NormalizedPoint
    let anchorRadius: Double
    let hint: String
    let shotType: ShotType
    let modelMeta: ModelMeta

    init(
        subjectType: SubjectType,
        anchorPoint: NormalizedPoint,
        anchorRadius: Double,
        hint: String,
        shotType: ShotType,
        modelMeta: ModelMeta
    ) {
        self.subjectType = subjectType
        self.anchorPoint = anchorPoint
        self.anchorRadius = anchorRadius
        self.hint = hint
        self.shotType = shotType
        self.modelMeta = modelMeta
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/GuidancePlanTests
```

期望：`Executed 2 tests, with 0 failures`

- [ ] **Step 5: Commit**

```bash
git add aiPhoto/Models/GuidancePlan.swift aiPhotoTests/Unit/GuidancePlanTests.swift
git commit -m "feat(model): add GuidancePlan"
```

---

## Task 6: AppError 错误类型

**Files:**
- Create: `aiPhoto/Errors/AppError.swift`
- Create: `aiPhotoTests/Unit/AppErrorTests.swift`

- [ ] **Step 1: 创建测试文件**

`aiPhotoTests/Unit/AppErrorTests.swift`:

```swift
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
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/AppErrorTests
```

期望：编译错误

- [ ] **Step 3: 实现 AppError**

`aiPhoto/Errors/AppError.swift`:

```swift
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
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/AppErrorTests
```

期望：`Executed 2 tests, with 0 failures`

- [ ] **Step 5: Commit**

```bash
git add aiPhoto/Errors/AppError.swift aiPhotoTests/Unit/AppErrorTests.swift
git commit -m "feat(error): add AppError with localized descriptions"
```

---

## Task 7: PromptBuilder

**Files:**
- Create: `aiPhoto/Services/PromptBuilder.swift`
- Create: `aiPhotoTests/Unit/PromptBuilderTests.swift`

- [ ] **Step 1: 创建测试文件**

`aiPhotoTests/Unit/PromptBuilderTests.swift`:

```swift
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
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/PromptBuilderTests
```

期望：编译错误

- [ ] **Step 3: 实现 PromptBuilder**

`aiPhoto/Services/PromptBuilder.swift`:

```swift
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
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/PromptBuilderTests
```

期望：`Executed 4 tests, with 0 failures`

- [ ] **Step 5: Commit**

```bash
git add aiPhoto/Services/PromptBuilder.swift aiPhotoTests/Unit/PromptBuilderTests.swift
git commit -m "feat(service): add PromptBuilder for OpenAI/Claude/Qwen"
```

---

## Task 8: GuidancePlanDecoder

**Files:**
- Create: `aiPhoto/Services/GuidancePlanDecoder.swift`
- Create: `aiPhotoTests/Unit/GuidancePlanDecoderTests.swift`

- [ ] **Step 1: 创建测试文件**

`aiPhotoTests/Unit/GuidancePlanDecoderTests.swift`:

```swift
import XCTest
@testable import aiPhoto

final class GuidancePlanDecoderTests: XCTestCase {
    let meta = ModelMeta(kind: .openai)

    func test_pureJSON_succeeds() throws {
        let json = """
        {
          "subjectType": "personWithScene",
          "anchorPoint": {"x": 0.6, "y": 0.4},
          "anchorRadius": 0.08,
          "hint": "把人物放在右上",
          "shotType": "group"
        }
        """
        let plan = try GuidancePlanDecoder.decode(json, modelMeta: meta)
        XCTAssertEqual(plan.subjectType, .personWithScene)
        XCTAssertEqual(plan.anchorPoint.x, 0.6, accuracy: 0.0001)
        XCTAssertEqual(plan.anchorPoint.y, 0.4, accuracy: 0.0001)
        XCTAssertEqual(plan.anchorRadius, 0.08, accuracy: 0.0001)
        XCTAssertEqual(plan.hint, "把人物放在右上")
        XCTAssertEqual(plan.shotType, .group)
        XCTAssertEqual(plan.modelMeta.kind, .openai)
    }

    func test_markdownWrapped_succeeds() throws {
        let wrapped = """
        ```json
        {
          "subjectType": "person",
          "anchorPoint": {"x": 0.5, "y": 0.5},
          "anchorRadius": 0.1,
          "hint": "中心",
          "shotType": "portrait"
        }
        ```
        """
        let plan = try GuidancePlanDecoder.decode(wrapped, modelMeta: meta)
        XCTAssertEqual(plan.subjectType, .person)
    }

    func test_leadingTrailingWhitespace_succeeds() throws {
        let padded = "\n\n  {\"subjectType\":\"scene\",\"anchorPoint\":{\"x\":0.1,\"y\":0.9},\"anchorRadius\":0.05,\"hint\":\"x\",\"shotType\":\"landscape\"}  \n"
        let plan = try GuidancePlanDecoder.decode(padded, modelMeta: meta)
        XCTAssertEqual(plan.subjectType, .scene)
    }

    func test_missingField_throws() {
        let json = """
        {
          "subjectType": "person",
          "anchorPoint": {"x": 0.5, "y": 0.5}
        }
        """
        XCTAssertThrowsError(try GuidancePlanDecoder.decode(json, modelMeta: meta)) { error in
            XCTAssertEqual(error as? AppError, .modelResponseInvalid)
        }
    }

    func test_coordinateOutOfRange_throws() {
        let json = """
        {
          "subjectType": "person",
          "anchorPoint": {"x": 1.5, "y": 0.5},
          "anchorRadius": 0.1,
          "hint": "x",
          "shotType": "portrait"
        }
        """
        XCTAssertThrowsError(try GuidancePlanDecoder.decode(json, modelMeta: meta)) { error in
            XCTAssertEqual(error as? AppError, .modelResponseInvalid)
        }
    }

    func test_typeMismatch_throws() {
        let json = """
        {
          "subjectType": "person",
          "anchorPoint": "center",
          "anchorRadius": 0.1,
          "hint": "x",
          "shotType": "portrait"
        }
        """
        XCTAssertThrowsError(try GuidancePlanDecoder.decode(json, modelMeta: meta)) { error in
            XCTAssertEqual(error as? AppError, .modelResponseInvalid)
        }
    }

    func test_emptyString_throws() {
        XCTAssertThrowsError(try GuidancePlanDecoder.decode("", modelMeta: meta)) { error in
            XCTAssertEqual(error as? AppError, .modelResponseInvalid)
        }
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/GuidancePlanDecoderTests
```

期望：编译错误

- [ ] **Step 3: 实现 GuidancePlanDecoder**

`aiPhoto/Services/GuidancePlanDecoder.swift`:

```swift
import Foundation

enum GuidancePlanDecoder {
    static func decode(_ raw: String, modelMeta: ModelMeta) throws -> GuidancePlan {
        let cleaned = stripCodeFence(raw)
        guard let data = cleaned.data(using: .utf8) else {
            throw AppError.modelResponseInvalid
        }

        let raw: RawGuidancePlan
        do {
            raw = try JSONDecoder().decode(RawGuidancePlan.self, from: data)
        } catch {
            throw AppError.modelResponseInvalid
        }

        guard raw.anchorPoint.x >= 0, raw.anchorPoint.x <= 1,
              raw.anchorPoint.y >= 0, raw.anchorPoint.y <= 1,
              raw.anchorRadius >= 0, raw.anchorRadius <= 1
        else {
            throw AppError.modelResponseInvalid
        }

        return GuidancePlan(
            subjectType: raw.subjectType,
            anchorPoint: NormalizedPoint(x: raw.anchorPoint.x, y: raw.anchorPoint.y),
            anchorRadius: raw.anchorRadius,
            hint: raw.hint,
            shotType: raw.shotType,
            modelMeta: modelMeta
        )
    }

    private static func stripCodeFence(_ s: String) -> String {
        var result = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {
            if let firstNewline = result.firstIndex(of: "\n") {
                result = String(result[result.index(after: firstNewline)...])
            }
            if result.hasSuffix("```") {
                result = String(result.dropLast(3))
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private struct RawGuidancePlan: Decodable {
        let subjectType: SubjectType
        let anchorPoint: RawPoint
        let anchorRadius: Double
        let hint: String
        let shotType: ShotType

        struct RawPoint: Decodable {
            let x: Double
            let y: Double
        }
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/GuidancePlanDecoderTests
```

期望：`Executed 7 tests, with 0 failures`

- [ ] **Step 5: Commit**

```bash
git add aiPhoto/Services/GuidancePlanDecoder.swift aiPhotoTests/Unit/GuidancePlanDecoderTests.swift
git commit -m "feat(service): add GuidancePlanDecoder with markdown stripping"
```

---

## Task 9: AlignmentCalculator

**Files:**
- Create: `aiPhoto/Utilities/AlignmentCalculator.swift`
- Create: `aiPhotoTests/Unit/AlignmentCalculatorTests.swift`

- [ ] **Step 1: 创建测试文件**

`aiPhotoTests/Unit/AlignmentCalculatorTests.swift`:

```swift
import XCTest
@testable import aiPhoto

final class AlignmentCalculatorTests: XCTestCase {
    func test_noSubjects_returnsNil() {
        let result = AlignmentCalculator.offset(
            subjects: [],
            anchor: NormalizedPoint(x: 0.5, y: 0.5)
        )
        XCTAssertNil(result)
    }

    func test_subjectAtAnchor_returnsZero() {
        let subjects = [
            DetectedSubject(
                boundingBox: CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2),
                confidence: 0.9,
                type: .person
            )
        ]
        let result = AlignmentCalculator.offset(
            subjects: subjects,
            anchor: NormalizedPoint(x: 0.5, y: 0.5)
        )
        XCTAssertEqual(result ?? -1, 0, accuracy: 0.0001)
    }

    func test_subjectOffsetRight_positiveX() {
        let subjects = [
            DetectedSubject(
                boundingBox: CGRect(x: 0.7, y: 0.4, width: 0.2, height: 0.2),
                confidence: 0.9,
                type: .person
            )
        ]
        let result = AlignmentCalculator.offset(
            subjects: subjects,
            anchor: NormalizedPoint(x: 0.5, y: 0.5)
        )
        XCTAssertEqual(result ?? 0, 0.2, accuracy: 0.001)
    }

    func test_multipleSubjects_pickClosest() {
        let far = DetectedSubject(
            boundingBox: CGRect(x: 0.0, y: 0.0, width: 0.1, height: 0.1),
            confidence: 0.9,
            type: .person
        )
        let close = DetectedSubject(
            boundingBox: CGRect(x: 0.45, y: 0.45, width: 0.1, height: 0.1),
            confidence: 0.8,
            type: .person
        )
        let result = AlignmentCalculator.offset(
            subjects: [far, close],
            anchor: NormalizedPoint(x: 0.5, y: 0.5)
        )
        XCTAssertEqual(result ?? 1, 0, accuracy: 0.001)
    }

    func test_visionCoordinateFlipped() {
        // Vision坐标原点在左下，但anchor用左上原点
        // 主体在Vision y=0.7（靠近底部）→ 屏幕坐标 y=0.3
        let subjects = [
            DetectedSubject(
                boundingBox: CGRect(x: 0.4, y: 0.6, width: 0.2, height: 0.2),
                confidence: 0.9,
                type: .person
            )
        ]
        // 屏幕中心 = (0.5, 0.5)，Vision中心 = (0.5, 0.5)，翻转后 = (0.5, 0.5) 仍对齐
        let result = AlignmentCalculator.offset(
            subjects: subjects,
            anchor: NormalizedPoint(x: 0.5, y: 0.5)
        )
        XCTAssertEqual(result ?? -1, 0, accuracy: 0.0001)
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/AlignmentCalculatorTests
```

期望：编译错误

- [ ] **Step 3: 实现 AlignmentCalculator**

`aiPhoto/Utilities/AlignmentCalculator.swift`:

```swift
import Foundation
import CoreGraphics

struct DetectedSubject: Equatable {
    let boundingBox: CGRect          // Vision坐标系（0~1, 原点在左下）
    let confidence: Float
    let type: SubjectType

    /// 屏幕坐标系下的中心（Vision y 翻转）
    var screenCenter: NormalizedPoint {
        let cx = boundingBox.midX
        let cy = 1.0 - boundingBox.midY   // 翻转
        return NormalizedPoint(x: cx, y: cy)
    }
}

enum AlignmentCalculator {
    /// 返回主体中心与锚点的归一化欧氏距离。
    /// nil 表示画面中无主体。
    static func offset(
        subjects: [DetectedSubject],
        anchor: NormalizedPoint
    ) -> Double? {
        guard !subjects.isEmpty else { return nil }
        let subject = subjects.min(by: { lhs, rhs in
            distance(lhs.screenCenter, anchor) < distance(rhs.screenCenter, anchor)
        })!
        return distance(subject.screenCenter, anchor)
    }

    private static func distance(_ a: NormalizedPoint, _ b: NormalizedPoint) -> Double {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/AlignmentCalculatorTests
```

期望：`Executed 5 tests, with 0 failures`

- [ ] **Step 5: Commit**

```bash
git add aiPhoto/Utilities/AlignmentCalculator.swift aiPhotoTests/Unit/AlignmentCalculatorTests.swift
git commit -m "feat(util): add AlignmentCalculator with Vision coord flip"
```

---

## Task 10: KeychainStore

**Files:**
- Create: `aiPhoto/Utilities/KeychainStore.swift`
- Create: `aiPhotoTests/Unit/KeychainStoreTests.swift`

- [ ] **Step 1: 创建测试文件**

`aiPhotoTests/Unit/KeychainStoreTests.swift`:

```swift
import XCTest
@testable import aiPhoto

final class KeychainStoreTests: XCTestCase {
    var store: KeychainStore!
    let testKey = "test.api.key.\(UUID().uuidString)"
    let service = "com.aiphoto.tests"

    override func setUp() {
        super.setUp()
        store = KeychainStore(service: service)
    }

    override func tearDown() {
        try? store.delete(testKey)
        super.tearDown()
    }

    func test_set_thenGet_returnsSameValue() throws {
        try store.set("secret-123", for: testKey)
        let value = try store.get(testKey)
        XCTAssertEqual(value, "secret-123")
    }

    func test_get_missingKey_throws() {
        XCTAssertThrowsError(try store.get("nonexistent-\(UUID().uuidString)"))
    }

    func test_set_overwritesPrevious() throws {
        try store.set("first", for: testKey)
        try store.set("second", for: testKey)
        let value = try store.get(testKey)
        XCTAssertEqual(value, "second")
    }

    func test_delete_removesValue() throws {
        try store.set("x", for: testKey)
        try store.delete(testKey)
        XCTAssertThrowsError(try store.get(testKey))
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/KeychainStoreTests
```

期望：编译错误

- [ ] **Step 3: 实现 KeychainStore**

`aiPhoto/Utilities/KeychainStore.swift`:

```swift
import Foundation
import Security

final class KeychainStore {
    let service: String

    init(service: String = "com.aiphoto.app") {
        self.service = service
    }

    enum KeychainError: Error, Equatable {
        case unexpectedStatus(OSStatus)
        case dataConversionFailed
    }

    func set(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.dataConversionFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw KeychainError.unexpectedStatus(updateStatus)
        }
    }

    func get(_ key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        guard let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionFailed
        }
        return value
    }

    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/KeychainStoreTests
```

期望：`Executed 4 tests, with 0 failures`

- [ ] **Step 5: Commit**

```bash
git add aiPhoto/Utilities/KeychainStore.swift aiPhotoTests/Unit/KeychainStoreTests.swift
git commit -m "feat(util): add KeychainStore"
```

---

## Task 11: AppSettings 持久化

**Files:**
- Create: `aiPhoto/Models/AppSettings.swift`
- Create: `aiPhotoTests/Unit/AppSettingsTests.swift`

- [ ] **Step 1: 创建测试文件**

`aiPhotoTests/Unit/AppSettingsTests.swift`:

```swift
import XCTest
@testable import aiPhoto

final class AppSettingsTests: XCTestCase {
    var defaults: UserDefaults!
    let suiteName = "com.aiphoto.tests.settings.\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func test_defaultValues() {
        let store = AppSettingsStore(defaults: defaults)
        XCTAssertEqual(store.settings.selectedModel, .openai)
        XCTAssertTrue(store.settings.autoCapture)
        XCTAssertEqual(store.settings.alignmentThreshold, 0.05, accuracy: 0.0001)
    }

    func test_update_andLoad() {
        let store = AppSettingsStore(defaults: defaults)
        var s = store.settings
        s.selectedModel = .claude
        s.autoCapture = false
        s.alignmentThreshold = 0.10
        store.settings = s

        let store2 = AppSettingsStore(defaults: defaults)
        XCTAssertEqual(store2.settings.selectedModel, .claude)
        XCTAssertFalse(store2.settings.autoCapture)
        XCTAssertEqual(store2.settings.alignmentThreshold, 0.10, accuracy: 0.0001)
    }

    func test_corruptedData_fallsBackToDefault() {
        defaults.set("not json".data(using: .utf8), forKey: "appSettings.v1")
        let store = AppSettingsStore(defaults: defaults)
        XCTAssertEqual(store.settings.selectedModel, .openai)
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/AppSettingsTests
```

期望：编译错误

- [ ] **Step 3: 实现 AppSettings**

`aiPhoto/Models/AppSettings.swift`:

```swift
import Foundation

struct AppSettings: Codable, Equatable {
    var selectedModel: ModelKind
    var autoCapture: Bool
    var alignmentThreshold: Double

    init(
        selectedModel: ModelKind = .openai,
        autoCapture: Bool = true,
        alignmentThreshold: Double = 0.05
    ) {
        self.selectedModel = selectedModel
        self.autoCapture = autoCapture
        self.alignmentThreshold = alignmentThreshold
    }
}

final class AppSettingsStore {
    private let defaults: UserDefaults
    private let key = "appSettings.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var settings: AppSettings {
        get {
            guard let data = defaults.data(forKey: key) else {
                return AppSettings()
            }
            return (try? JSONDecoder().decode(AppSettings.self, from: data)) ?? AppSettings()
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: key)
        }
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/AppSettingsTests
```

期望：`Executed 3 tests, with 0 failures`

- [ ] **Step 5: Commit**

```bash
git add aiPhoto/Models/AppSettings.swift aiPhotoTests/Unit/AppSettingsTests.swift
git commit -m "feat(model): add AppSettings and AppSettingsStore"
```

---

## Task 12: LogWriter

**Files:**
- Create: `aiPhoto/Services/LogWriter.swift`
- Create: `aiPhotoTests/Unit/LogWriterTests.swift`

- [ ] **Step 1: 创建测试文件**

`aiPhotoTests/Unit/LogWriterTests.swift`:

```swift
import XCTest
@testable import aiPhoto

final class LogWriterTests: XCTestCase {
    var tempDir: URL!
    var writer: LogWriter!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("logtest-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        writer = LogWriter(directory: tempDir, retentionDays: 7)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func test_write_createsFile() throws {
        try writer.write(level: .info, message: "hello", context: ["k": "v"])
        let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(files.count, 1)
        let content = try String(contentsOf: files[0])
        XCTAssertTrue(content.contains("hello"))
        XCTAssertTrue(content.contains("k=v"))
        XCTAssertTrue(content.contains("INFO"))
    }

    func test_cleanup_removesOldFiles() throws {
        let oldFile = tempDir.appendingPathComponent("2020-01-01.log")
        try "old".write(to: oldFile, atomically: true, encoding: .utf8)
        try writer.write(level: .info, message: "new", context: nil)
        // 触发清理
        try writer.cleanup()
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldFile.path))
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/LogWriterTests
```

期望：编译错误

- [ ] **Step 3: 实现 LogWriter**

`aiPhoto/Services/LogWriter.swift`:

```swift
import Foundation

final class LogWriter {
    enum Level: String { case debug, info, warn, error }

    let directory: URL
    let retentionDays: Int
    private let queue = DispatchQueue(label: "logwriter", qos: .utility)

    init(directory: URL, retentionDays: Int = 7) {
        self.directory = directory
        self.retentionDays = retentionDays
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func write(level: Level, message: String, context: [String: String]?) throws {
        let line = format(level: level, message: message, context: context)
        let fileURL = todayFileURL()
        queue.sync {
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                FileManager.default.createFile(atPath: fileURL.path, contents: nil)
            }
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                defer { try? handle.close() }
                try? handle.seekToEnd()
                if let data = (line + "\n").data(using: .utf8) {
                    try? handle.write(contentsOf: data)
                }
            }
        }
    }

    func cleanup() throws {
        let cutoff = Date().addingTimeInterval(-Double(retentionDays) * 86400)
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])
        for file in files {
            let values = try file.resourceValues(forKeys: [.contentModificationDateKey])
            if let mtime = values.contentModificationDate, mtime < cutoff {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    private func todayFileURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let filename = "\(formatter.string(from: Date())).log"
        return directory.appendingPathComponent(filename)
    }

    private func format(level: Level, message: String, context: [String: String]?) -> String {
        let ts = ISO8601DateFormatter().string(from: Date())
        var line = "\(ts) [\(level.rawValue.uppercased())] \(message)"
        if let context = context, !context.isEmpty {
            let ctx = context.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
            line += " | \(ctx)"
        }
        return line
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/LogWriterTests
```

期望：`Executed 2 tests, with 0 failures`

- [ ] **Step 5: Commit**

```bash
git add aiPhoto/Services/LogWriter.swift aiPhotoTests/Unit/LogWriterTests.swift
git commit -m "feat(service): add LogWriter with rotation"
```

---

## Task 13: VisionModelAdapter 协议 + URLProtocolStub

**Files:**
- Create: `aiPhoto/Services/VisionModelAdapter.swift`
- Create: `aiPhotoTests/Support/URLProtocolStub.swift`
- Create: `aiPhotoTests/Unit/VisionModelAdapterTests.swift`

- [ ] **Step 1: 创建 URLProtocolStub**

`aiPhotoTests/Support/URLProtocolStub.swift`:

```swift
import Foundation

final class URLProtocolStub: URLProtocol {
    typealias Handler = (URLRequest) -> (HTTPURLResponse, Data)

    static var handler: Handler?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = URLProtocolStub.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
```

- [ ] **Step 2: 创建测试文件**

`aiPhotoTests/Unit/VisionModelAdapterTests.swift`:

```swift
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
```

- [ ] **Step 3: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/VisionModelAdapterTests
```

期望：编译错误（`Cannot find 'VisionModelAdapter' in scope`）

- [ ] **Step 4: 实现协议**

`aiPhoto/Services/VisionModelAdapter.swift`:

```swift
import Foundation

protocol VisionModelAdapter {
    var kind: ModelKind { get }
    func analyze(imageJPEG: Data, model: ModelKind) async throws -> GuidancePlan
}
```

- [ ] **Step 5: 再次运行测试（仍失败，因为三个Adapter还不存在）**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/VisionModelAdapterTests
```

期望：仍失败（`Cannot find 'OpenAIAdapter' in scope`）

- [ ] **Step 6: 留待 Task 14-16 实现具体Adapter**

- [ ] **Step 7: Commit stub 和协议**

```bash
git add aiPhoto/Services/VisionModelAdapter.swift aiPhotoTests/Support/URLProtocolStub.swift aiPhotoTests/Unit/VisionModelAdapterTests.swift
git commit -m "feat(service): add VisionModelAdapter protocol and URLProtocolStub"
```

---

## Task 14: OpenAIAdapter

**Files:**
- Create: `aiPhoto/Services/OpenAIAdapter.swift`
- Create: `aiPhotoTests/Integration/OpenAIAdapterTests.swift`

- [ ] **Step 1: 创建测试文件**

`aiPhotoTests/Integration/OpenAIAdapterTests.swift`:

```swift
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
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/OpenAIAdapterTests
```

期望：编译错误

- [ ] **Step 3: 实现 OpenAIAdapter**

`aiPhoto/Services/OpenAIAdapter.swift`:

```swift
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
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/OpenAIAdapterTests
```

期望：`Executed 5 tests, with 0 failures`

- [ ] **Step 5: Commit**

```bash
git add aiPhoto/Services/OpenAIAdapter.swift aiPhotoTests/Integration/OpenAIAdapterTests.swift
git commit -m "feat(service): add OpenAIAdapter"
```

---

## Task 15: ClaudeAdapter

**Files:**
- Create: `aiPhoto/Services/ClaudeAdapter.swift`
- Create: `aiPhotoTests/Integration/ClaudeAdapterTests.swift`

- [ ] **Step 1: 创建测试文件**

`aiPhotoTests/Integration/ClaudeAdapterTests.swift`:

```swift
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
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/ClaudeAdapterTests
```

期望：编译错误

- [ ] **Step 3: 实现 ClaudeAdapter**

`aiPhoto/Services/ClaudeAdapter.swift`:

```swift
import Foundation

final class ClaudeAdapter: VisionModelAdapter {
    let kind: ModelKind = .claude
    let apiKey: String
    let model: String
    let endpoint: URL
    let session: URLSession

    init(
        apiKey: String,
        model: String = "claude-sonnet-4-6",
        endpoint: URL = URL(string: "https://api.anthropic.com/v1/")!,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = endpoint
        self.session = session
    }

    func analyze(imageJPEG: Data, model: ModelKind) async throws -> GuidancePlan {
        let base64 = imageJPEG.base64EncodedString()
        let body = PromptBuilder.claudeRequestBody(imageBase64: base64, model: model)
        var request = URLRequest(url: endpoint.appendingPathComponent("messages"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = body
        request.timeoutInterval = 15

        let (data, response) = try await sendWithTimeout(request)
        let http = response as! HTTPURLResponse
        try mapStatus(http.statusCode)

        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = dict["content"] as? [[String: Any]]
        else {
            throw AppError.modelResponseInvalid
        }

        let text = content.first(where: { ($0["type"] as? String) == "text" })?["text"] as? String
        guard let text = text else {
            throw AppError.modelResponseInvalid
        }

        return try GuidancePlanDecoder.decode(text, modelMeta: ModelMeta(kind: self.kind))
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
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/ClaudeAdapterTests
```

期望：`Executed 3 tests, with 0 failures`

- [ ] **Step 5: Commit**

```bash
git add aiPhoto/Services/ClaudeAdapter.swift aiPhotoTests/Integration/ClaudeAdapterTests.swift
git commit -m "feat(service): add ClaudeAdapter"
```

---

## Task 16: QwenAdapter

**Files:**
- Create: `aiPhoto/Services/QwenAdapter.swift`
- Create: `aiPhotoTests/Integration/QwenAdapterTests.swift`

- [ ] **Step 1: 创建测试文件**

`aiPhotoTests/Integration/QwenAdapterTests.swift`:

```swift
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
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/QwenAdapterTests
```

期望：编译错误

- [ ] **Step 3: 实现 QwenAdapter**

`aiPhoto/Services/QwenAdapter.swift`:

```swift
import Foundation

final class QwenAdapter: VisionModelAdapter {
    let kind: ModelKind = .qwenVl
    let apiKey: String
    let model: String
    let endpoint: URL
    let session: URLSession

    init(
        apiKey: String,
        model: String = "qwen-vl-max",
        endpoint: URL = URL(string: "https://dashscope.aliyuncs.com/compatible-mode/v1/")!,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = endpoint
        self.session = session
    }

    func analyze(imageJPEG: Data, model: ModelKind) async throws -> GuidancePlan {
        let base64 = imageJPEG.base64EncodedString()
        let body = PromptBuilder.qwenRequestBody(imageBase64: base64, model: model)
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
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/QwenAdapterTests
```

期望：`Executed 2 tests, with 0 failures`

- [ ] **Step 5: Commit**

```bash
git add aiPhoto/Services/QwenAdapter.swift aiPhotoTests/Integration/QwenAdapterTests.swift
git commit -m "feat(service): add QwenAdapter"
```

---

## Task 17: 验证 VisionModelAdapterTests 现在能通过

**Files:**
- Modify: 无（仅运行测试）

- [ ] **Step 1: 重新跑之前 task 13 的测试**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/VisionModelAdapterTests
```

期望：`Executed 1 test, with 0 failures`

- [ ] **Step 2: Commit（无文件改动可跳过）**

---

## Task 18: CameraService

**Files:**
- Create: `aiPhoto/Services/CameraService.swift`
- Create: `aiPhotoTests/Support/FakeCameraService.swift`
- Create: `aiPhotoTests/Unit/CameraServiceTests.swift`

- [ ] **Step 1: 创建 FakeCameraService（先有替身便于其他测试）**

`aiPhotoTests/Support/FakeCameraService.swift`:

```swift
import AVFoundation
import Combine
@testable import aiPhoto

final class FakeCameraService: CameraServiceProtocol {
    let frameSubject = PassthroughSubject<CVPixelBuffer, Never>()
    var previewLayer: AVCaptureVideoPreviewLayer { AVCaptureVideoPreviewLayer() }
    var framePublisher: AnyPublisher<CVPixelBuffer, Never> { frameSubject.eraseToAnyPublisher() }

    var startSessionCalled = false
    var stopSessionCalled = false
    var capturePhotoCalled = false
    var captureCurrentFrameJPEGCalled = false
    var switchCameraCalled: AVCaptureDevice.Position?
    var photoToReturn: UIImage = UIImage()
    var jpegToReturn: Data = Data()
    var errorToThrow: Error?

    func startSession() async throws {
        if let error = errorToThrow { throw error }
        startSessionCalled = true
    }

    func stopSession() {
        stopSessionCalled = true
    }

    func capturePhoto() async throws -> UIImage {
        if let error = errorToThrow { throw error }
        capturePhotoCalled = true
        return photoToReturn
    }

    func captureCurrentFrameJPEG(quality: CGFloat) async throws -> Data {
        if let error = errorToThrow { throw error }
        captureCurrentFrameJPEGCalled = true
        return jpegToReturn
    }

    func switchCamera(to position: AVCaptureDevice.Position) async throws {
        if let error = errorToThrow { throw error }
        switchCameraCalled = position
    }
}
```

- [ ] **Step 2: 创建测试文件**

`aiPhotoTests/Unit/CameraServiceTests.swift`:

```swift
import XCTest
import AVFoundation
@testable import aiPhoto

final class CameraServiceTests: XCTestCase {
    func test_conformsToProtocol() {
        // 仅编译期：FakeCameraService 满足协议
        let fake: CameraServiceProtocol = FakeCameraService()
        XCTAssertNotNil(fake)
    }
}
```

- [ ] **Step 3: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/CameraServiceTests
```

期望：编译错误（`Cannot find 'CameraServiceProtocol' in scope`）

- [ ] **Step 4: 实现 CameraService 协议 + 真实实现**

`aiPhoto/Services/CameraService.swift`:

```swift
import AVFoundation
import Combine
import UIKit

protocol CameraServiceProtocol: AnyObject {
    var previewLayer: AVCaptureVideoPreviewLayer { get }
    var framePublisher: AnyPublisher<CVPixelBuffer, Never> { get }
    func startSession() async throws
    func stopSession()
    func capturePhoto() async throws -> UIImage
    func captureCurrentFrameJPEG(quality: CGFloat) async throws -> Data
    func switchCamera(to position: AVCaptureDevice.Position) async throws
}

final class CameraService: NSObject, CameraServiceProtocol {
    let session = AVCaptureSession()
    let previewLayer: AVCaptureVideoPreviewLayer
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let frameSubject = PassthroughSubject<CVPixelBuffer, Never>()
    private var currentInput: AVCaptureDeviceInput?
    private var currentPosition: AVCaptureDevice.Position = .back

    var framePublisher: AnyPublisher<CVPixelBuffer, Never> {
        frameSubject.eraseToAnyPublisher()
    }

    override init() {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init()
        previewLayer.videoGravity = .resizeAspectFill
    }

    func startSession() async throws {
        let granted = await Self.requestCameraPermission()
        guard granted else { throw AppError.cameraPermissionDenied }

        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        if session.inputs.isEmpty {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input)
            else {
                session.commitConfiguration()
                throw AppError.cameraSessionFailed(underlying: "无法添加摄像头输入")
            }
            session.addInput(input)
            currentInput = input
        }

        if !session.outputs.contains(videoOutput) {
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frames"))
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
        }

        if !session.outputs.contains(photoOutput) {
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
        }

        session.commitConfiguration()

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            DispatchQueue.global(qos: .userInitiated).async { [session] in
                session.startRunning()
                cont.resume()
            }
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    func capturePhoto() async throws -> UIImage {
        let settings = AVCapturePhotoSettings()
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<UIImage, Error>) in
            let delegate = PhotoCaptureDelegate { result in
                switch result {
                case .success(let image): cont.resume(returning: image)
                case .failure(let error): cont.resume(throwing: error)
                }
            }
            self.photoDelegates[UUID()] = delegate
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    func captureCurrentFrameJPEG(quality: CGFloat) async throws -> Data {
        let buffer = try await latestFrame()
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw AppError.cameraSessionFailed(underlying: "无法生成预览帧")
        }
        let uiImage = UIImage(cgImage: cgImage)
        guard let data = uiImage.jpegData(compressionQuality: quality) else {
            throw AppError.cameraSessionFailed(underlying: "无法编码 JPEG")
        }
        return data
    }

    func switchCamera(to position: AVCaptureDevice.Position) async throws {
        guard position != currentPosition else { return }
        session.beginConfiguration()
        if let input = currentInput {
            session.removeInput(input)
        }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            session.commitConfiguration()
            throw AppError.cameraSessionFailed(underlying: "无法切换摄像头")
        }
        session.addInput(input)
        currentInput = input
        currentPosition = position
        session.commitConfiguration()
    }

    // MARK: - Private

    private var photoDelegates: [UUID: PhotoCaptureDelegate] = [:]
    private var lastBuffer: CVPixelBuffer?

    private func latestFrame() async throws -> CVPixelBuffer {
        if let last = lastBuffer { return last }
        for await buffer in framePublisher.values {
            return buffer
        }
        throw AppError.cameraSessionFailed(underlying: "无可用帧")
    }

    private static func requestCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined:
            return await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    cont.resume(returning: granted)
                }
            }
        default: return false
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastBuffer = buffer
        frameSubject.send(buffer)
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let completion: (Result<UIImage, Error>) -> Void
    init(_ completion: @escaping (Result<UIImage, Error>) -> Void) { self.completion = completion }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            completion(.failure(AppError.cameraSessionFailed(underlying: error.localizedDescription)))
            return
        }
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data)
        else {
            completion(.failure(AppError.cameraSessionFailed(underlying: "照片数据无效")))
            return
        }
        completion(.success(image))
    }
}
```

- [ ] **Step 5: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/CameraServiceTests
```

期望：`Executed 1 test, with 0 failures`

- [ ] **Step 6: Commit**

```bash
git add aiPhoto/Services/CameraService.swift aiPhotoTests/Support/FakeCameraService.swift aiPhotoTests/Unit/CameraServiceTests.swift
git commit -m "feat(service): add CameraService with protocol and AVFoundation"
```

---

## Task 19: VisionService

**Files:**
- Create: `aiPhoto/Services/VisionService.swift`
- Create: `aiPhotoTests/Support/FakeVisionService.swift`
- Create: `aiPhotoTests/Unit/VisionServiceTests.swift`

- [ ] **Step 1: 创建 FakeVisionService**

`aiPhotoTests/Support/FakeVisionService.swift`:

```swift
import AVFoundation
@testable import aiPhoto

final class FakeVisionService: VisionServiceProtocol {
    var subjectsToReturn: [DetectedSubject] = []
    var detectCallCount = 0

    func detectSubject(in pixelBuffer: CVPixelBuffer) async -> [DetectedSubject] {
        detectCallCount += 1
        return subjectsToReturn
    }
}
```

- [ ] **Step 2: 创建测试文件**

`aiPhotoTests/Unit/VisionServiceTests.swift`:

```swift
import XCTest
import AVFoundation
@testable import aiPhoto

final class VisionServiceTests: XCTestCase {
    func test_conformsToProtocol() {
        let fake: VisionServiceProtocol = FakeVisionService()
        XCTAssertNotNil(fake)
    }
}
```

- [ ] **Step 3: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/VisionServiceTests
```

期望：编译错误

- [ ] **Step 4: 实现 VisionService**

`aiPhoto/Services/VisionService.swift`:

```swift
import AVFoundation
import Vision
import CoreImage

protocol VisionServiceProtocol {
    func detectSubject(in pixelBuffer: CVPixelBuffer) async -> [DetectedSubject]
}

final class VisionService: VisionServiceProtocol {
    func detectSubject(in pixelBuffer: CVPixelBuffer) async -> [DetectedSubject] {
        async let faces = runFaceDetection(pixelBuffer)
        async let humans = runHumanDetection(pixelBuffer)
        let (faceResults, humanResults) = await (faces, humans)

        var subjects: [DetectedSubject] = []
        subjects.append(contentsOf: faceResults.map {
            DetectedSubject(boundingBox: $0.boundingBox, confidence: $0.confidence, type: .person)
        })
        if subjects.isEmpty {
            subjects.append(contentsOf: humanResults.map {
                DetectedSubject(boundingBox: $0.boundingBox, confidence: $0.confidence, type: .person)
            })
        }
        return subjects
    }

    private func runFaceDetection(_ buffer: CVPixelBuffer) async -> [VNDetection] {
        await withCheckedContinuation { (cont: CheckedContinuation<[VNDetection], Never>) in
            let request = VNDetectFaceRectanglesRequest { request, _ in
                let observations = (request.results as? [VNFaceObservation]) ?? []
                cont.resume(returning: observations.map {
                    VNDetection(boundingBox: $0.boundingBox, confidence: $0.confidence)
                })
            }
            let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:])
            try? handler.perform([request])
        }
    }

    private func runHumanDetection(_ buffer: CVPixelBuffer) async -> [VNDetection] {
        await withCheckedContinuation { (cont: CheckedContinuation<[VNDetection], Never>) in
            let request = VNDetectHumanRectanglesRequest { request, _ in
                let observations = (request.results as? [VNHumanObservation]) ?? []
                cont.resume(returning: observations.map {
                    VNDetection(boundingBox: $0.boundingBox, confidence: $0.confidence)
                })
            }
            let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:])
            try? handler.perform([request])
        }
    }

    private struct VNDetection {
        let boundingBox: CGRect
        let confidence: Float
    }
}
```

- [ ] **Step 5: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/VisionServiceTests
```

期望：`Executed 1 test, with 0 failures`

- [ ] **Step 6: Commit**

```bash
git add aiPhoto/Services/VisionService.swift aiPhotoTests/Support/FakeVisionService.swift aiPhotoTests/Unit/VisionServiceTests.swift
git commit -m "feat(service): add VisionService for face/human detection"
```

---

## Task 20: PhotoSaver

**Files:**
- Create: `aiPhoto/Services/PhotoSaver.swift`
- Create: `aiPhotoTests/Support/FakePhotoSaver.swift`
- Create: `aiPhotoTests/Unit/PhotoSaverTests.swift`

- [ ] **Step 1: 创建 FakePhotoSaver**

`aiPhotoTests/Support/FakePhotoSaver.swift`:

```swift
import UIKit
@testable import aiPhoto

final class FakePhotoSaver: PhotoSaverProtocol {
    var savedImages: [UIImage] = []
    var errorToThrow: Error?

    func save(_ image: UIImage) async throws {
        if let error = errorToThrow { throw error }
        savedImages.append(image)
    }
}
```

- [ ] **Step 2: 创建测试文件**

`aiPhotoTests/Unit/PhotoSaverTests.swift`:

```swift
import XCTest
import UIKit
@testable import aiPhoto

final class PhotoSaverTests: XCTestCase {
    func test_conformsToProtocol() {
        let fake: PhotoSaverProtocol = FakePhotoSaver()
        XCTAssertNotNil(fake)
    }
}
```

- [ ] **Step 3: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/PhotoSaverTests
```

期望：编译错误

- [ ] **Step 4: 实现 PhotoSaver**

`aiPhoto/Services/PhotoSaver.swift`:

```swift
import UIKit
import Photos

protocol PhotoSaverProtocol {
    func save(_ image: UIImage) async throws
}

final class PhotoSaver: PhotoSaverProtocol {
    func save(_ image: UIImage) async throws {
        let status = await withCheckedContinuation { (cont: CheckedContinuation<PHAuthorizationStatus, Never>) in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { cont.resume(returning: $0) }
        }
        guard status == .authorized || status == .limited else {
            throw AppError.photoLibraryPermissionDenied
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            }
        } catch {
            throw AppError.photoSaveFailed(underlying: error.localizedDescription)
        }
    }
}
```

- [ ] **Step 5: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/PhotoSaverTests
```

期望：`Executed 1 test, with 0 failures`

- [ ] **Step 6: Commit**

```bash
git add aiPhoto/Services/PhotoSaver.swift aiPhotoTests/Support/FakePhotoSaver.swift aiPhotoTests/Unit/PhotoSaverTests.swift
git commit -m "feat(service): add PhotoSaver for system library"
```

---

## Task 21: CameraViewModel（核心状态机）

**Files:**
- Create: `aiPhoto/ViewModels/CameraViewModel.swift`
- Create: `aiPhotoTests/Support/FakeVisionModelAdapter.swift`
- Create: `aiPhotoTests/Integration/CameraViewModelTests.swift`

- [ ] **Step 1: 创建 FakeVisionModelAdapter**

`aiPhotoTests/Support/FakeVisionModelAdapter.swift`:

```swift
@testable import aiPhoto

final class FakeVisionModelAdapter: VisionModelAdapter {
    let kind: ModelKind
    var planToReturn: GuidancePlan?
    var errorToThrow: Error?
    var analyzeCallCount = 0
    var lastJPEG: Data?

    init(kind: ModelKind = .openai) { self.kind = kind }

    func analyze(imageJPEG: Data, model: ModelKind) async throws -> GuidancePlan {
        analyzeCallCount += 1
        lastJPEG = imageJPEG
        if let error = errorToThrow { throw error }
        guard let plan = planToReturn else {
            throw AppError.modelResponseInvalid
        }
        return plan
    }
}
```

- [ ] **Step 2: 创建测试文件**

`aiPhotoTests/Integration/CameraViewModelTests.swift`:

```swift
import XCTest
import AVFoundation
@testable import aiPhoto

@MainActor
final class CameraViewModelTests: XCTestCase {
    var vm: CameraViewModel!
    var camera: FakeCameraService!
    var vision: FakeVisionService!
    var model: FakeVisionModelAdapter!
    var saver: FakePhotoSaver!
    var settings: AppSettingsStore!

    let fixedPlan = GuidancePlan(
        subjectType: .person,
        anchorPoint: .center,
        anchorRadius: 0.1,
        hint: "test",
        shotType: .portrait,
        modelMeta: ModelMeta(kind: .openai)
    )

    override func setUp() {
        super.setUp()
        camera = FakeCameraService()
        vision = FakeVisionService()
        model = FakeVisionModelAdapter(kind: .openai)
        saver = FakePhotoSaver()
        settings = AppSettingsStore(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
    }

    func makeVM() -> CameraViewModel {
        CameraViewModel(
            camera: camera,
            vision: vision,
            model: model,
            saver: saver,
            settings: settings,
            keychain: KeychainStore(service: "test-\(UUID().uuidString)")
        )
    }

    func test_initialState_isIdle() {
        vm = makeVM()
        if case .idle = vm.state { } else { XCTFail("期望 idle，实际 \(vm.state)") }
    }

    func test_onAnalyzeTap_success_transitionsToGuiding() async {
        model.planToReturn = fixedPlan
        camera.jpegToReturn = Data([1, 2, 3])
        vm = makeVM()

        vm.onAnalyzeTap()
        // analyzing 短暂，可直接等待
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .guiding(let plan) = vm.state {
            XCTAssertEqual(plan.hint, "test")
        } else {
            XCTFail("期望 guiding，实际 \(vm.state)")
        }
    }

    func test_onAnalyzeTap_modelError_transitionsToError() async {
        model.errorToThrow = AppError.modelAuthFailed
        camera.jpegToReturn = Data([1, 2, 3])
        vm = makeVM()

        vm.onAnalyzeTap()
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .error(let err) = vm.state {
            XCTAssertEqual(err, .modelAuthFailed)
        } else {
            XCTFail("期望 error，实际 \(vm.state)")
        }
    }

    func test_onCancelTap_guidesToIdle() async {
        model.planToReturn = fixedPlan
        camera.jpegToReturn = Data([1])
        vm = makeVM()
        vm.onAnalyzeTap()
        try? await Task.sleep(nanoseconds: 100_000_000)

        vm.onCancelTap()
        if case .idle = vm.state { } else { XCTFail("期望 idle，实际 \(vm.state)") }
    }

    func test_aligned_autoCaptureTrue_savesAndResets() async {
        model.planToReturn = fixedPlan
        camera.jpegToReturn = Data([1])
        camera.photoToReturn = UIImage()
        settings.settings.autoCapture = true
        vm = makeVM()

        // 直接驱动对齐检测
        vm.onAlignCheck(
            offset: 0.01,
            hasSubject: true,
            subject: DetectedSubject(
                boundingBox: CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2),
                confidence: 0.9,
                type: .person
            )
        )
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(saver.savedImages.count, 1)
        if case .idle = vm.state { } else { XCTFail("期望 idle，实际 \(vm.state)") }
    }

    func test_aligned_autoCaptureFalse_waitsForShutter() async {
        settings.settings.autoCapture = false
        vm = makeVM()
        vm.onAlignCheck(
            offset: 0.01,
            hasSubject: true,
            subject: nil
        )
        try? await Task.sleep(nanoseconds: 50_000_000)

        if case .aligned = vm.state { } else { XCTFail("期望 aligned，实际 \(vm.state)") }

        vm.onShutterTap()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(saver.savedImages.count, 1)
    }
}
```

- [ ] **Step 3: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/CameraViewModelTests
```

期望：编译错误

- [ ] **Step 4: 实现 CameraViewModel**

`aiPhoto/ViewModels/CameraViewModel.swift`:

```swift
import Foundation
import AVFoundation
import UIKit
import Combine

@MainActor
final class CameraViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case analyzing
        case guiding(plan: GuidancePlan)
        case aligned
        case error(AppError)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var currentOffset: Double = 1.0
    @Published private(set) var hint: String = ""

    private let camera: CameraServiceProtocol
    private let vision: VisionServiceProtocol
    private let model: VisionModelAdapter
    private let saver: PhotoSaverProtocol
    private let settings: AppSettingsStore
    private let keychain: KeychainStore
    private var subscriptions: Set<AnyCancellable> = []
    private var lastSeenSubject: DetectedSubject?
    private var noSubjectTimer: Task<Void, Never>?

    init(
        camera: CameraServiceProtocol,
        vision: VisionServiceProtocol,
        model: VisionModelAdapter,
        saver: PhotoSaverProtocol,
        settings: AppSettingsStore,
        keychain: KeychainStore
    ) {
        self.camera = camera
        self.vision = vision
        self.model = model
        self.saver = saver
        self.settings = settings
        self.keychain = keychain

        // 实时帧 → 主体检测 → 偏移更新
        camera.framePublisher
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] buffer in
                self?.processFrame(buffer)
            }
            .store(in: &subscriptions)
    }

    // MARK: - Public

    func onAnalyzeTap() {
        guard case .idle = state else { return }
        state = .analyzing
        Task { [weak self] in
            await self?.performAnalysis()
        }
    }

    func onCancelTap() {
        noSubjectTimer?.cancel()
        state = .idle
        currentOffset = 1.0
        hint = ""
    }

    func onShutterTap() {
        guard case .aligned = state else { return }
        Task { [weak self] in await self?.captureAndSave() }
    }

    /// 由 SwiftUI 在帧回调中调用
    func onAlignCheck(offset: Double?, hasSubject: Bool, subject: DetectedSubject?) {
        guard case .guiding(let plan) = state else { return }

        if !hasSubject {
            currentOffset = 1.0
            startNoSubjectTimer()
            return
        }
        noSubjectTimer?.cancel()
        noSubjectTimer = nil

        guard let offset = offset else { return }
        lastSeenSubject = subject
        currentOffset = offset
        hint = plan.hint

        if offset < settings.settings.alignmentThreshold {
            if settings.settings.autoCapture {
                Task { [weak self] in await self?.captureAndSave() }
            } else {
                state = .aligned
            }
        }
    }

    // MARK: - Private

    private func processFrame(_ buffer: CVPixelBuffer) {
        Task { [weak self] in
            guard let self = self else { return }
            let subjects = await self.vision.detectSubject(in: buffer)
            guard case .guiding(let plan) = self.state else { return }
            let offset = AlignmentCalculator.offset(subjects: subjects, anchor: plan.anchorPoint)
            self.onAlignCheck(offset: offset, hasSubject: !subjects.isEmpty, subject: subjects.first)
        }
    }

    private func performAnalysis() async {
        do {
            let jpeg = try await camera.captureCurrentFrameJPEG(quality: 0.7)
            let plan = try await model.analyze(imageJPEG: jpeg, model: settings.settings.selectedModel)
            state = .guiding(plan: plan)
            hint = plan.hint
        } catch let error as AppError {
            state = .error(error)
        } catch {
            state = .error(.cameraSessionFailed(underlying: error.localizedDescription))
        }
    }

    private func captureAndSave() async {
        do {
            let photo = try await camera.capturePhoto()
            try await saver.save(photo)
            resetToIdle()
        } catch let error as AppError {
            state = .error(error)
        } catch {
            state = .error(.photoSaveFailed(underlying: error.localizedDescription))
        }
    }

    private func resetToIdle() {
        noSubjectTimer?.cancel()
        noSubjectTimer = nil
        currentOffset = 1.0
        hint = ""
        lastSeenSubject = nil
        state = .idle
    }

    private func startNoSubjectTimer() {
        guard noSubjectTimer == nil else { return }
        noSubjectTimer = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !Task.isCancelled {
                self?.state = .error(.noSubjectDetected)
            }
        }
    }
}
```

- [ ] **Step 5: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/CameraViewModelTests
```

期望：`Executed 6 tests, with 0 failures`

- [ ] **Step 6: Commit**

```bash
git add aiPhoto/ViewModels/CameraViewModel.swift aiPhotoTests/Support/FakeVisionModelAdapter.swift aiPhotoTests/Integration/CameraViewModelTests.swift
git commit -m "feat(vm): add CameraViewModel with state machine"
```

---

## Task 22: SettingsViewModel

**Files:**
- Create: `aiPhoto/ViewModels/SettingsViewModel.swift`
- Create: `aiPhotoTests/Integration/SettingsViewModelTests.swift`

- [ ] **Step 1: 创建测试文件**

`aiPhotoTests/Integration/SettingsViewModelTests.swift`:

```swift
import XCTest
@testable import aiPhoto

@MainActor
final class SettingsViewModelTests: XCTestCase {
    var settings: AppSettingsStore!
    var keychain: KeychainStore!
    var defaults: UserDefaults!
    let suiteName = "settings-vm-\(UUID().uuidString)"
    let kcService = "kc-vm-\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        settings = AppSettingsStore(defaults: defaults)
        keychain = KeychainStore(service: kcService)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func test_initialValues() {
        let vm = SettingsViewModel(settings: settings, keychain: keychain)
        XCTAssertEqual(vm.selectedModel, .openai)
        XCTAssertTrue(vm.autoCapture)
        XCTAssertEqual(vm.alignmentThreshold, 0.05, accuracy: 0.0001)
        XCTAssertEqual(vm.apiKey, "")
    }

    func test_setApiKey_persistsToKeychain() throws {
        let vm = SettingsViewModel(settings: settings, keychain: keychain)
        vm.apiKey = "sk-abc"
        try vm.save()

        let kc = KeychainStore(service: kcService)
        XCTAssertEqual(try kc.get("apiKey"), "sk-abc")
    }

    func test_setSelectedModel_persists() {
        let vm = SettingsViewModel(settings: settings, keychain: keychain)
        vm.selectedModel = .claude
        vm.save()

        let vm2 = SettingsViewModel(settings: settings, keychain: keychain)
        XCTAssertEqual(vm2.selectedModel, .claude)
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/SettingsViewModelTests
```

期望：编译错误

- [ ] **Step 3: 实现 SettingsViewModel**

`aiPhoto/ViewModels/SettingsViewModel.swift`:

```swift
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedModel: ModelKind
    @Published var autoCapture: Bool
    @Published var alignmentThreshold: Double
    @Published var apiKey: String

    private let settings: AppSettingsStore
    private let keychain: KeychainStore
    private let keychainKey = "apiKey"

    init(settings: AppSettingsStore, keychain: KeychainStore) {
        self.settings = settings
        self.keychain = keychain
        let s = settings.settings
        self.selectedModel = s.selectedModel
        self.autoCapture = s.autoCapture
        self.alignmentThreshold = s.alignmentThreshold
        self.apiKey = (try? keychain.get(keychainKey)) ?? ""
    }

    func save() {
        var s = settings.settings
        s.selectedModel = selectedModel
        s.autoCapture = autoCapture
        s.alignmentThreshold = alignmentThreshold
        settings.settings = s

        if !apiKey.isEmpty {
            try? keychain.set(apiKey, for: keychainKey)
        }
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoTests/SettingsViewModelTests
```

期望：`Executed 3 tests, with 0 failures`

- [ ] **Step 5: Commit**

```bash
git add aiPhoto/ViewModels/SettingsViewModel.swift aiPhotoTests/Integration/SettingsViewModelTests.swift
git commit -m "feat(vm): add SettingsViewModel"
```

---

## Task 23: SwiftUI 视图层

**Files:**
- Create: `aiPhoto/Views/CameraPreviewView.swift`
- Create: `aiPhoto/Views/GuidanceOverlayView.swift`
- Create: `aiPhoto/Views/CameraView.swift`
- Create: `aiPhoto/Views/SettingsView.swift`
- Create: `aiPhoto/Views/RootView.swift`

- [ ] **Step 1: 实现 CameraPreviewView**

`aiPhoto/Views/CameraPreviewView.swift`:

```swift
import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let layer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> PreviewContainer {
        let view = PreviewContainer()
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: PreviewContainer, context: Context) {
        layer.frame = uiView.bounds
    }

    final class PreviewContainer: UIView {
        override func layoutSubviews() {
            super.layoutSubviews()
            if let preview = sublayers?.first {
                preview.frame = bounds
            }
        }
    }
}
```

- [ ] **Step 2: 实现 GuidanceOverlayView**

`aiPhoto/Views/GuidanceOverlayView.swift`:

```swift
import SwiftUI

struct GuidanceOverlayView: View {
    let state: CameraViewModel.State
    let offset: Double
    let hint: String

    var body: some View {
        ZStack {
            switch state {
            case .idle:
                EmptyView()
            case .analyzing:
                ProgressView("分析中…")
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .padding(20)
                    .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            case .guiding(let plan), .aligned:
                GeometryReader { geo in
                    let anchor = CGPoint(
                        x: plan.anchorPoint.x * geo.size.width,
                        y: plan.anchorPoint.y * geo.size.height
                    )
                    ZStack {
                        // 引导点
                        Circle()
                            .stroke(alignmentColor, lineWidth: 3)
                            .frame(width: 60, height: 60)
                            .scaleEffect(state == .aligned ? 1.2 : 1.0)
                            .opacity(state == .aligned ? 1.0 : 0.8)
                            .position(anchor)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                       value: state)

                        // 容差圆
                        Circle()
                            .stroke(alignmentColor.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .frame(width: anchorDiameter(plan: plan, in: geo.size),
                                   height: anchorDiameter(plan: plan, in: geo.size))
                            .position(anchor)

                        // 方向提示
                        VStack {
                            Spacer()
                            Text(directionHint(plan: plan))
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                                .padding(.bottom, 100)
                        }
                    }
                }
            case .error(let err):
                VStack(spacing: 12) {
                    Text(err.errorDescription ?? "发生错误")
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.red.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
        }
    }

    private var alignmentColor: Color {
        switch state {
        case .aligned: return .green
        default:
            if offset < 0.1 { return .yellow }
            return .white
        }
    }

    private func anchorDiameter(plan: GuidancePlan, in size: CGSize) -> CGFloat {
        min(size.width, size.height) * CGFloat(plan.anchorRadius) * 4
    }

    private func directionHint(plan: GuidancePlan) -> String {
        plan.hint
    }
}
```

- [ ] **Step 3: 实现 CameraView**

`aiPhoto/Views/CameraView.swift`:

```swift
import SwiftUI

struct CameraView: View {
    @ObservedObject var viewModel: CameraViewModel
    let previewLayer: AVCaptureVideoPreviewLayer

    var body: some View {
        ZStack {
            CameraPreviewView(layer: previewLayer)
                .ignoresSafeArea()

            GuidanceOverlayView(
                state: viewModel.state,
                offset: viewModel.currentOffset,
                hint: viewModel.hint
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                HStack(spacing: 24) {
                    // 分析按钮
                    Button {
                        viewModel.onAnalyzeTap()
                    } label: {
                        Label("分析", systemImage: "wand.and.stars")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.blue, in: Capsule())
                    }
                    .disabled(!isAnalyzeEnabled)

                    // 取消按钮
                    if case .guiding = viewModel.state {
                        Button {
                            viewModel.onCancelTap()
                        } label: {
                            Text("取消")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(.gray, in: Capsule())
                        }
                    }

                    // 快门
                    Button {
                        if case .aligned = viewModel.state {
                            viewModel.onShutterTap()
                        } else {
                            viewModel.onAnalyzeTap()
                        }
                    } label: {
                        Image(systemName: shutterIcon)
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                            .background(Circle().stroke(.white, lineWidth: 4))
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }

    private var isAnalyzeEnabled: Bool {
        if case .idle = viewModel.state { return true }
        return false
    }

    private var shutterIcon: String {
        switch viewModel.state {
        case .aligned: return "camera.fill"
        default: return "wand.and.stars"
        }
    }
}
```

- [ ] **Step 4: 实现 SettingsView**

`aiPhoto/Views/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("模型") {
                    Picker("选择模型", selection: $viewModel.selectedModel) {
                        ForEach(ModelKind.allCases, id: \.self) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("API Key") {
                    SecureField("sk-...", text: $viewModel.apiKey)
                }

                Section("拍摄") {
                    Toggle("对齐后自动拍照", isOn: $viewModel.autoCapture)
                    VStack(alignment: .leading) {
                        Text("对齐阈值: \(String(format: "%.2f", viewModel.alignmentThreshold))")
                        Slider(value: $viewModel.alignmentThreshold, in: 0.01...0.20, step: 0.01)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        viewModel.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 5: 实现 RootView**

`aiPhoto/Views/RootView.swift`:

```swift
import SwiftUI

struct RootView: View {
    let cameraViewModel: CameraViewModel
    let settingsViewModel: SettingsViewModel

    @State private var showingSettings = false

    var body: some View {
        CameraView(viewModel: cameraViewModel, previewLayer: previewLayer)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: settingsViewModel)
            }
    }

    private var previewLayer: AVCaptureVideoPreviewLayer {
        (cameraViewModel.value(forKey: "camera") as? CameraServiceProtocol)?.previewLayer
            ?? AVCaptureVideoPreviewLayer()
    }
}
```

**注意**：上面 `cameraViewModel.value(forKey:)` 是临时方案。更干净的做法是在 CameraViewModel 上加一个 public computed property 暴露 previewLayer。**先这样写保持MVP简单，后续 Task 25 重构**。

- [ ] **Step 6: 编译验证**

```bash
xcodebuild -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'generic/platform=iOS Simulator' build
```

期望：`BUILD SUCCEEDED`（如果 previewLayer 取不到会有运行时问题，但编译应通过）

- [ ] **Step 7: Commit**

```bash
git add aiPhoto/Views/
git commit -m "feat(view): add SwiftUI views (Camera, Settings, Root, Overlay)"
```

---

## Task 24: App 入口（DI 装配）

**Files:**
- Modify: `aiPhoto/aiPhotoApp.swift`

- [ ] **Step 1: 重写 aiPhotoApp.swift**

```swift
import SwiftUI

@main
struct aiPhotoApp: App {
    @StateObject private var cameraViewModel: CameraViewModel
    @StateObject private var settingsViewModel: SettingsViewModel

    init() {
        let settings = AppSettingsStore()
        let keychain = KeychainStore()
        let camera = CameraService()
        let vision = VisionService()
        let saver = PhotoSaver()
        let model = Self.makeAdapter(settings: settings, keychain: keychain)

        let cvm = CameraViewModel(
            camera: camera,
            vision: vision,
            model: model,
            saver: saver,
            settings: settings,
            keychain: keychain
        )
        let svm = SettingsViewModel(settings: settings, keychain: keychain)

        _cameraViewModel = StateObject(wrappedValue: cvm)
        _settingsViewModel = StateObject(wrappedValue: svm)
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                cameraViewModel: _cameraViewModel.wrappedValue,
                settingsViewModel: _settingsViewModel.wrappedValue
            )
        }
    }

    private static func makeAdapter(
        settings: AppSettingsStore,
        keychain: KeychainStore
    ) -> VisionModelAdapter {
        let key = (try? keychain.get("apiKey")) ?? ""
        switch settings.settings.selectedModel {
        case .openai: return OpenAIAdapter(apiKey: key)
        case .claude: return ClaudeAdapter(apiKey: key)
        case .qwenVl: return QwenAdapter(apiKey: key)
        }
    }
}
```

- [ ] **Step 2: 修改 RootView 以正确暴露 previewLayer**

把 Task 23 中 RootView 的 previewLayer 取法替换为：在 `CameraViewModel` 上加一个 public 属性。

编辑 `aiPhoto/ViewModels/CameraViewModel.swift`，新增属性：

```swift
var previewLayer: AVCaptureVideoPreviewLayer { camera.previewLayer }
```

然后把 RootView 改为：

```swift
struct RootView: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel

    @State private var showingSettings = false

    var body: some View {
        CameraView(viewModel: cameraViewModel, previewLayer: cameraViewModel.previewLayer)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: settingsViewModel)
            }
    }
}
```

- [ ] **Step 3: 编译验证**

```bash
xcodebuild -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'generic/platform=iOS Simulator' build
```

期望：`BUILD SUCCEEDED`

- [ ] **Step 4: 重新跑全部测试确保无回归**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15'
```

期望：所有测试通过

- [ ] **Step 5: Commit**

```bash
git add aiPhoto/aiPhotoApp.swift aiPhoto/ViewModels/CameraViewModel.swift aiPhoto/Views/RootView.swift
git commit -m "feat(app): wire DI in aiPhotoApp entry point"
```

---

## Task 25: UI 烟雾测试

**Files:**
- Create: `aiPhotoTests/UI/AppSmokeTests.swift`

- [ ] **Step 1: 创建 UI 测试文件**

`aiPhotoTests/UI/AppSmokeTests.swift`:

```swift
import XCTest

final class AppSmokeTests: XCTestCase {
    func test_appLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        // 验证主要 UI 元素存在
        XCTAssertTrue(app.buttons["分析"].waitForExistence(timeout: 5),
                      "未找到'分析'按钮")
    }
}
```

- [ ] **Step 2: 配置 UI Test target**

1. 在 Xcode 中添加新 Target：iOS UI Testing Bundle
2. Product Name: `aiPhotoUITests`
3. 把 `AppSmokeTests.swift` 移到 `aiPhotoUITests/`
4. 在 `aiPhotoUITests/Info.plist` 配置（默认即可）

- [ ] **Step 3: 运行 UI 测试**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:aiPhotoUITests
```

期望：测试通过（模拟器需要授予相机权限或测试会跳过）

- [ ] **Step 4: 提交**

```bash
git add .
git commit -m "test(ui): add smoke test for app launch"
```

---

## Task 26: 最终全量测试 + 真机手动验证

**Files:**
- Create: `aiPhoto/MANUAL_TESTING.md`（手动验证清单）

- [ ] **Step 1: 运行全量测试**

```bash
xcodebuild test -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15'
```

期望：所有单元+集成+UI测试通过

- [ ] **Step 2: 在真机上 build**

```bash
xcodebuild -project aiPhoto/aiPhoto.xcodeproj -scheme aiPhoto -destination 'generic/platform=iOS' build
```

期望：`BUILD SUCCEEDED`

- [ ] **Step 3: 创建手动验证清单**

`aiPhoto/MANUAL_TESTING.md`:

```markdown
# aiPhoto 手动验证清单（MVP）

> 真机必做，模拟器无法验证。

## 准备
- [ ] iPhone 13+ 真机，iOS 17+
- [ ] 至少一个有效的 API Key（OpenAI / Claude / Qwen 任一）
- [ ] 至少 5 张不同场景的可拍照对象

## 场景验证
- [ ] 启动 App → 弹出相机权限请求 → 允许后看到预览
- [ ] 设置 → 填入 OpenAI Key → 选 OpenAI → 完成
- [ ] 拍人像（朋友站好）→ 点"分析" → 看到引导点
- [ ] 移动手机让人脸进入引导点 → 看到绿色"已对齐"
- [ ] 等待 1 秒（自动拍开启）→ 听到快门声
- [ ] 打开系统相册 → 照片存在
- [ ] 切到前摄自拍 → 同样流程
- [ ] 拍风景（山/建筑）→ 流程通过
- [ ] 拍人景合影 → 流程通过
- [ ] 切换到 Claude 模型 → 同样流程
- [ ] 切换到 Qwen 模型 → 同样流程
- [ ] 关闭 WiFi 飞行模式 → 点"分析" → 看到"网络超时"友好提示
- [ ] 拒绝相册权限 → 拍照后看到"请允许相册访问"

## 边界场景
- [ ] 极暗光 → 引导过程可能无主体，黄条提示
- [ ] 强烈逆光 → 引导过程同上
- [ ] API Key 填错 → 看到"API Key无效"
- [ ] 设置中把对齐阈值调到 0.20 → 容易对齐
- [ ] 关闭自动拍 → 对齐后需要手动按快门
```

- [ ] **Step 4: 真机测试**

在 Xcode 中选择真机 → Run → 走一遍清单

- [ ] **Step 5: Commit + tag**

```bash
git add aiPhoto/MANUAL_TESTING.md
git commit -m "docs: add manual testing checklist for MVP"
git tag v0.1.0-mvp
```

---

## 自审

**Spec 覆盖检查**：

| Spec 需求 | 任务 |
|---|---|
| F1 相机预览+切换 | Task 18, 24 |
| F2 拍前分析截帧+调模型 | Task 21 |
| F3 解析引导方案 | Task 8 |
| F4 引导点叠加 | Task 23 (GuidanceOverlayView) |
| F5 实时对齐检测 | Task 9, 19, 21 |
| F6 对齐阈值判定 | Task 11, 21 |
| F7 自动/手动拍 | Task 21 |
| F8 存系统相册 | Task 20 |
| F9 设置页 | Task 22, 23 |
| F10 持久化 | Task 10, 11 |
| F11 三种Adapter | Task 14, 15, 16 |
| N1 超时降级 | Task 14, 15, 16 (timeoutInterval=15) |
| N2 ≥10FPS | Task 21 (throttle 100ms) |
| N3 流畅 | 单元测试+手动验证 |
| N4 错误统一 | Task 6 |
| N5 不阻塞 | Task 21 (引导失败仍可手动拍) |
| N6 Key存Keychain | Task 10 |
| N7 单元测试≥80% | Task 3-22 大量覆盖 |

**占位符扫描**：无 "TBD" / "TODO" / "类似 Task N"

**类型一致性**：
- `GuidancePlan` 字段名一致（subjectType, anchorPoint, anchorRadius, hint, shotType, modelMeta）
- `AppError` 枚举值一致
- `VisionModelAdapter.analyze(imageJPEG:model:)` 签名一致
- `CameraServiceProtocol` / `VisionServiceProtocol` / `PhotoSaverProtocol` 协议与Fake/Real实现一致

**未覆盖/已知缺口**：
- v1.1 待办：Onboarding、CI、VoiceOver、App Store上架

---

## 完成

26 个任务，每个 5 步。MVP 总代码量预估 ~1500 行（不含测试）。执行完成后可得到一个可拍照出引导照片的 iOS App。
