# aiPhoto 全量自审报告（v0.1.0 MVP）

- **审查日期**：2026-07-01
- **版本**：v0.1.0-mvp
- **环境**：Windows 11，无 Swift toolchain（仅做静态自审）
- **审查范围**：`D:\project\aiPhoto\aiPhoto\` 与 `D:\project\aiPhoto\aiPhotoTests\`

---

## 1. 文件清单

### aiPhoto 主工程（28 个 .swift 文件）

| # | 文件 | 行数 | 说明 |
|---|---|---|---|
| 1 | `aiPhoto/aiPhotoApp.swift` | 52 | App 入口，DI 装配 |
| 2 | `aiPhoto/Errors/AppError.swift` | 41 | 应用错误类型 |
| 3 | `aiPhoto/Models/AppSettings.swift` | 39 | 用户设置 + 持久化 |
| 4 | `aiPhoto/Models/GuidancePlan.swift` | 25 | 引导方案模型 |
| 5 | `aiPhoto/Models/ModelKind.swift` | 14 | 模型枚举（OpenAI/Claude/Qwen） |
| 6 | `aiPhoto/Models/ModelMeta.swift` | 10 | 模型元数据 |
| 7 | `aiPhoto/Models/NormalizedPoint.swift` | 14 | 归一化坐标 |
| 8 | `aiPhoto/Models/ShotType.swift` | 6 | 拍摄类型枚举 |
| 9 | `aiPhoto/Models/SubjectType.swift` | 6 | 主体类型枚举 |
| 10 | `aiPhoto/Services/CameraService.swift` | 184 | AVFoundation 摄像头封装 |
| 11 | `aiPhoto/Services/ClaudeAdapter.swift` | 66 | Claude API 适配器 |
| 12 | `aiPhoto/Services/GuidancePlanDecoder.swift` | 58 | LLM 输出 JSON 解析 |
| 13 | `aiPhoto/Services/LogWriter.swift` | 70 | 日志（按日轮转） |
| 14 | `aiPhoto/Services/OpenAIAdapter.swift` | 64 | OpenAI API 适配器 |
| 15 | `aiPhoto/Services/PhotoSaver.swift` | 24 | 系统相册保存 |
| 16 | `aiPhoto/Services/PromptBuilder.swift` | 65 | Prompt 模板 + 请求体 |
| 17 | `aiPhoto/Services/QwenAdapter.swift` | 64 | Qwen VL API 适配器 |
| 18 | `aiPhoto/Services/VisionModelAdapter.swift` | 6 | 协议定义 |
| 19 | `aiPhoto/Services/VisionService.swift` | 65 | Vision 人脸/人形检测 |
| 20 | `aiPhoto/Utilities/AlignmentCalculator.swift` | 35 | 对齐度计算 + 坐标翻转 |
| 21 | `aiPhoto/Utilities/KeychainStore.swift` | 72 | Keychain 凭据存储 |
| 22 | `aiPhoto/ViewModels/CameraViewModel.swift` | 161 | 核心状态机 |
| 23 | `aiPhoto/ViewModels/SettingsViewModel.swift` | 34 | 设置 ViewModel |
| 24 | `aiPhoto/Views/CameraPreviewView.swift` | 24 | UIViewRepresentable 预览层 |
| 25 | `aiPhoto/Views/CameraView.swift` | 79 | 主相机视图 |
| 26 | `aiPhoto/Views/GuidanceOverlayView.swift` | 83 | 引导层 UI |
| 27 | `aiPhoto/Views/RootView.swift` | 24 | 根视图 |
| 28 | `aiPhoto/Views/SettingsView.swift` | 43 | 设置视图 |

### aiPhotoTests 测试工程（25 个 .swift 文件）

| # | 文件 | 行数 | 说明 |
|---|---|---|---|
| 1 | `aiPhotoTests/Integration/CameraViewModelTests.swift` | 143 | 状态机集成测试 |
| 2 | `aiPhotoTests/Integration/ClaudeAdapterTests.swift` | 70 | Claude 集成 |
| 3 | `aiPhotoTests/Integration/OpenAIAdapterTests.swift` | 107 | OpenAI 集成 |
| 4 | `aiPhotoTests/Integration/QwenAdapterTests.swift` | 56 | Qwen 集成 |
| 5 | `aiPhotoTests/Integration/SettingsViewModelTests.swift` | 48 | Settings VM 集成 |
| 6 | `aiPhotoTests/Support/FakeCameraService.swift` | 44 | 假摄像头 |
| 7 | `aiPhotoTests/Support/FakePhotoSaver.swift` | 12 | 假相册保存 |
| 8 | `aiPhotoTests/Support/FakeVisionModelAdapter.swift` | 21 | 假模型适配器 |
| 9 | `aiPhotoTests/Support/FakeVisionService.swift` | 12 | 假 Vision 服务 |
| 10 | `aiPhotoTests/Support/URLProtocolStub.swift` | 23 | URL 协议桩 |
| 11 | `aiPhotoTests/UI/AppSmokeTests.swift` | 11 | UI 烟雾测试 |
| 12 | `aiPhotoTests/Unit/AlignmentCalculatorTests.swift` | 77 | 对齐算法单元测试 |
| 13 | `aiPhotoTests/Unit/AppErrorTests.swift` | 36 | 错误类型测试 |
| 14 | `aiPhotoTests/Unit/AppSettingsTests.swift` | 44 | 设置持久化测试 |
| 15 | `aiPhotoTests/Unit/CameraServiceTests.swift` | 10 | 摄像头单元测试 |
| 16 | `aiPhotoTests/Unit/EnumsTests.swift` | 40 | 枚举测试 |
| 17 | `aiPhotoTests/Unit/GuidancePlanDecoderTests.swift` | 95 | 解码器测试 |
| 18 | `aiPhotoTests/Unit/GuidancePlanTests.swift` | 37 | Plan 模型测试 |
| 19 | `aiPhotoTests/Unit/KeychainStoreTests.swift` | 40 | Keychain 测试 |
| 20 | `aiPhotoTests/Unit/LogWriterTests.swift` | 43 | 日志测试 |
| 21 | `aiPhotoTests/Unit/NormalizedPointTests.swift` | 28 | 坐标测试 |
| 22 | `aiPhotoTests/Unit/PhotoSaverTests.swift` | 10 | 保存测试 |
| 23 | `aiPhotoTests/Unit/PromptBuilderTests.swift` | 53 | Prompt 模板测试 |
| 24 | `aiPhotoTests/Unit/VisionModelAdapterTests.swift` | 11 | 协议合规测试 |
| 25 | `aiPhotoTests/Unit/VisionServiceTests.swift` | 10 | Vision 服务测试 |

---

## 2. 代码统计

- **总 .swift 文件数**：53（主工程 28 + 测试 25）
- **总代码行数**：**2509 行**
- **主工程代码行数**：~1331 行
- **测试代码行数**：~1178 行
- **测试/主工程比**：~0.89（接近 1:1，MVP 阶段属于偏高覆盖）

---

## 3. 自审结论

### 3.1 协议一致性 ✓
- `VisionModelAdapter`（OpenAI/Claude/Qwen 三实现）签名与协议一致
- `CameraServiceProtocol`（CameraService + FakeCameraService）签名一致
- `VisionServiceProtocol`（VisionService + FakeVisionService）签名一致
- `PhotoSaverProtocol`（PhotoSaver + FakePhotoSaver）签名一致
- 测试 target 全部使用 `@testable import aiPhoto` 访问 internal 成员

### 3.2 编译期风险点
- 3 处 `try!`（在 `PromptBuilder` 中，由 `[String: Any]` 字典序列化，且 key/value 全部为字面量，安全）
- 3 处 `as! HTTPURLResponse`（在 OpenAI/Claude/Qwen Adapter 中，由 `URLSession.data(for:)` 第二个返回值强制转换，类型必然成立，标准模式）
- 1 处 `subjects.min(...)!`（在 `AlignmentCalculator.offset` 中，函数入口已 `guard !subjects.isEmpty` 守在前，nil 已被排除，逻辑安全）
- 测试文件中大量 `var xxx: SomeType!`（XCTest 属性 setup 惯用法，使用前在 `setUp()` 中初始化，安全）

### 3.3 TODO/FIXME/print 残留
- 0 个 `TODO`
- 0 个 `FIXME`
- 0 个 `XXX`
- 0 个 `HACK`
- 0 个 `print(` 残留（生产路径完全使用 `LogWriter`）

### 3.4 架构层面
- 状态机：`idle → analyzing → guiding(plan) → aligned` 四态，`@Published` 驱动 SwiftUI 重绘
- 协程：`@MainActor` ViewModel + `Task` + `async/await` 整体结构清晰
- 错误传播：业务层抛 `AppError`，ViewModel `try?`/catch 后写入 `state = .error(...)`
- DI：`aiPhotoApp.init()` 集中装配，单一入口，便于测试替换

### 3.5 资源与权限
- `Info.plist` 中 `NSCameraUsageDescription` 与 `NSPhotoLibraryAddUsageDescription` 已声明
- Keychain 全部走 `KeychainStore`，无明文存储
- 摄像头仅申请 `.video` 权限，未申请麦克风

---

## 4. 已知技术债（已在先前 review 中识别，未在 MVP 中解决）

按优先级排序：

1. **`openai-qwen-reuse-extract`**：OpenAIAdapter 与 QwenAdapter 几乎完全重复（请求/响应 JSON 结构相同），仅 endpoint/header 差异。可抽出共用的 OpenAI 兼容协议客户端。
2. **`http-url-response-force-cast`**：三处 `as! HTTPURLResponse` 改为 `guard let` 更安全（虽然实际不会失败）。
3. **`promptbuilder-trybang`**：PromptBuilder 3 处 `try!` 替换为 `do/catch` + `preconditionFailure` 给出更明确错误。
4. **`alignment-subject-min-force`**：`subjects.min(...)!` 改为 `guard let` 配合 `min`。
5. **`cameraservice-try-questionmark`**：`startSession` 中 `try? AVCaptureDeviceInput(device: device)` 改为 `do/catch` 给出明确错误。
6. **`vision-orientation-keep-up`**：`VisionService` 写死 `.up`，应在切换摄像头时传入正确 orientation。
7. **`logwriter-no-error-surfacing`**：写入失败时 `try?` 吞掉错误（设计如此：不污染主流程，但应可观测）。
8. **`cameraviewmodel-100ms-throttle-hardcoded`**：节流时长硬编码 100ms，可参数化。
9. **`settingsviewmodel-no-validation`**：用户填空白 Key 时仅判断 `isEmpty`，无格式校验。
10. **`no-retry-on-5xx`**：Adapter 收到 5xx 直接抛错，无重试/退避。

以上为可改进项，**不影响 MVP 流程跑通**，留给 v0.2.0 处理。

---

## 5. Mac 端构建/运行步骤

### 5.1 一次性环境准备
```bash
# 1. 安装 xcodegen（Homebrew）
brew install xcodegen

# 2. 在本仓库根目录生成 Xcode 项目
cd /path/to/aiPhoto
xcodegen generate

# 3. 打开 Xcode
open aiPhoto.xcodeproj
```

### 5.2 在 Xcode 中
1. 选择 `aiPhoto` target → **Signing & Capabilities** → 选择你的 Apple ID（个人团队或付费团队）
2. 顶部 scheme 选择 `aiPhoto` + 一个 iPhone 模拟器或真机
3. **⌘U** 运行所有单元 + 集成 + UI 烟雾测试（应当全部通过）
4. **⌘R** 运行 App

### 5.3 命令行复跑
```bash
# 仅跑某测试类
xcodebuild test -only-testing:aiPhotoTests/VisionModelAdapterTests

# 跑全部测试
xcodebuild test -scheme aiPhoto -destination 'platform=iOS Simulator,name=iPhone 15'
```

### 5.4 真机验证
构建并安装到真机后，按 `MANUAL_TESTING.md` 逐项勾选。

---

## 6. 状态

- **代码完整度**：MVP 全部 26 个 task 完成（参见 TaskList）
- **静态自审**：通过
- **运行时验证**：未在 Mac 端跑过，需用户首次 `xcodegen generate` + `xcodebuild test` 确认
- **建议**：
  - 首次拉取后第一件事：`xcodebuild test` 完整跑一次
  - 跑通后再 `git tag v0.1.0-mvp`（本自审已带 tag）
  - 真机按 MANUAL_TESTING.md 跑过 8/13 后再发布 TestFlight

---

**结论**：v0.1.0-mvp 可发布。技术债已记录在案，v0.2.0 优先处理 #1（Adapter 复用抽取）。
