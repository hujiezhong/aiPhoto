# aiPhoto 设计文档

> **状态**：草案 v1 · **日期**：2026-07-01 · **作者**：brainstorming 会话

## 一句话总结

iOS App（Swift + SwiftUI）。用户把相机对准人景合影，点"分析"按钮，大模型推荐一个最佳构图锚点，画面上叠加引导点，主体对齐后自动或手动拍照，照片存入系统相册。

## 1. 范围

### 1.1 在范围内（MVP）

- iOS 17+ SwiftUI 单页App
- 相机预览 + 拍前一次性大模型分析 + 引导点叠加 + 对齐检测 + 拍照 + 存系统相册
- 三种云端多模态大模型适配：OpenAI GPT-4o、Anthropic Claude、Qwen-VL（可热切换）
- 设置页：模型选择、API Key、自动/手动拍开关、对齐阈值
- 基础错误处理与降级路径
- 单元测试 + 集成测试 + UI烟雾测试

### 1.2 不在范围内（明确剔除）

- 任何形式的相册管理、历史记录、回看
- ARKit/3D深度/真实空间走位引导（v2再考虑）
- 视频拍摄
- Android/跨平台
- 用户账号、登录、云同步
- 滤镜、后期编辑、分享到社交平台
- 多语言（仅简体中文）
- 离线模型（必须联网）

## 2. 需求

### 2.1 功能需求

| ID | 描述 |
|---|---|
| F1 | 启动后能调起后置/前置相机并实时预览 |
| F2 | 用户点"分析"按钮后，截取当前预览帧送给当前选中的大模型 |
| F3 | 大模型返回的引导方案被解析为画面上的引导点（含容差半径、提示语、构图类型） |
| F4 | 引导点以视觉叠加层呈现，带呼吸动画与方向提示 |
| F5 | 引导过程中，本地持续检测主体（人脸/人体），实时计算与引导点偏移 |
| F6 | 偏移小于阈值时，App判定"已对齐" |
| F7 | "已对齐"后，根据设置触发自动拍照或等待用户按快门 |
| F8 | 拍摄的照片以全分辨率存入系统相册 |
| F9 | 设置页允许切换模型、修改API Key、调整自动拍开关和对齐阈值 |
| F10 | API Key与设置持久化（Keychain + AppStorage） |
| F11 | 三种模型适配器均可独立配置、独立调用、独立测试 |

### 2.2 非功能需求

| ID | 描述 |
|---|---|
| N1 | 单次"分析"调用大模型耗时 ≤ 15s（超时则降级） |
| N2 | 引导过程中对齐检测帧率 ≥ 10 FPS（CPU占用可控） |
| N3 | iPhone 13 及以上机型流畅运行，无明显卡顿或发热 |
| N4 | 所有错误都通过`AppError`统一表达，对用户显示本地化中文消息 |
| N5 | 网络/AI失败不阻塞手动拍照路径（降级） |
| N6 | API Key 仅存于 Keychain，不写入日志与 UserDefaults |
| N7 | 单元测试覆盖核心逻辑 ≥ 80% |

## 3. 架构

### 3.1 分层

```
┌─────────────────────────────────────────────┐
│  SwiftUI Views (UI层)                       │
│  - RootView, CameraView, GuidanceOverlay,  │
│    SettingsView                             │
└──────────────┬──────────────────────────────┘
               │ @StateObject / @ObservedObject
┌──────────────▼──────────────────────────────┐
│  ViewModel (状态层)                         │
│  - CameraViewModel, SettingsViewModel       │
└──────────────┬──────────────────────────────┘
               │ 方法调用 / Combine publisher
┌──────────────▼──────────────────────────────┐
│  Services (业务层)                          │
│  - CameraService (AVFoundation)             │
│  - VisionService (Vision框架)               │
│  - VisionModelAdapter (协议)                │
│    ├─ OpenAIAdapter                         │
│    ├─ ClaudeAdapter                         │
│    └─ QwenAdapter                           │
│  - PhotoSaver (PHPhotoLibrary)              │
│  - PromptBuilder / GuidancePlanDecoder      │
│  - LogWriter                                │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│  Models & Storage                           │
│  - GuidancePlan, AppSettings                │
│  - AppSettings → AppStorage + Keychain      │
│  - LogWriter → Documents/logs/              │
└─────────────────────────────────────────────┘
```

### 3.2 关键原则

- **协议驱动多模型**：`VisionModelAdapter` 协议，三个实现可热切换，新增模型只需新增Adapter
- **MVVM + 状态集中**：所有可变状态在ViewModel（@Published），View纯渲染
- **本地检测 vs 云端分析分离**：VisionService本地CV做实时对齐检测；VisionModelAdapter只在用户按"分析"时调用
- **数据流单向**：UI事件 → ViewModel → Service → 结果回ViewModel → View重渲染
- **降级而非崩溃**：模型失败/网络失败都不能阻塞用户拍照

## 4. 核心数据流：拍照状态机

```
[空闲] ──点"分析"──▶ [分析中]
   ▲                     │
   │                     │ 返回GuidancePlan
   │                     ▼
   │                [引导中]
   │                     │
   │                     ├── 每帧：VisionService检测主体
   │                     │   计算与引导点偏移
   │                     │
   │                     ├── 偏移 < 阈值 ──▶ [已对齐]
   │                     │                       │
   │                     │                       ├── 设置=自动拍 ──▶ 拍照 ──▶ [空闲]
   │                     │                       │
   │                     │                       └── 设置=手动拍 ──▶ 等用户按快门 ──▶ 拍照 ──▶ [空闲]
   │                     │
   │                     └── 点"取消" ──▶ [空闲]
   │
   └─ 任何阶段错误 ──▶ [错误态] ──▶ 用户确认 ──▶ [空闲]
```

## 5. 关键数据模型

```swift
// 大模型返回的引导方案
struct GuidancePlan: Codable {
    let subjectType: SubjectType        // .person | .scene | .personWithScene
    let anchorPoint: NormalizedPoint    // 屏幕归一化坐标 (0~1, 0~1)
    let anchorRadius: Double            // 引导点容差半径（归一化）
    let hint: String                    // 中文提示语
    let shotType: ShotType              // .portrait | .landscape | .group
    let modelMeta: ModelMeta            // 哪个模型、何时返回
}

struct NormalizedPoint: Codable {
    let x: Double  // 0=最左, 1=最右
    let y: Double  // 0=最上, 1=最下
}

enum SubjectType: String, Codable { case person, scene, personWithScene }
enum ShotType: String, Codable { case portrait, landscape, group }
struct ModelMeta: Codable { let kind: ModelKind; let timestamp: Date }

// 用户设置
struct AppSettings: Codable {
    var selectedModel: ModelKind
    var autoCapture: Bool
    var alignmentThreshold: Double  // 默认 0.05
    // apiKey / endpoint 不在AppSettings中，单独存Keychain
}

enum ModelKind: String, Codable, CaseIterable {
    case openai, claude, qwenVl
    var displayName: String { /* openai: "OpenAI GPT-4o" 等 */ }
}
```

## 6. 大模型 Prompt 契约

### 6.1 系统 Prompt

```
你是一个摄影构图助手。分析这张照片，给出最佳构图方案。

要求：
1. 识别主体（人物/景物/合影）
2. 推荐主体应处于画面哪个位置（黄金分割点/三分法点/中心）
3. 输出严格JSON，结构：
   {subjectType, anchorPoint:{x,y}, anchorRadius, hint, shotType}
4. 坐标使用归一化值（0~1），x从左到右，y从上到下
5. hint用中文，一句话，<20字
6. 不要输出任何JSON以外内容
```

### 6.2 用户输入

当前预览帧 JPEG（1280×720，quality 0.7），base64编码。

### 6.3 响应

纯 JSON，零 markdown 包裹（模型实现层负责处理兼容）。

## 7. 组件详细设计

### 7.1 CameraService

**职责**：AVFoundation封装，管理预览流、帧回调、拍照。

```swift
protocol CameraServiceProtocol: AnyObject {
    var previewLayer: AVCaptureVideoPreviewLayer { get }
    var framePublisher: AnyPublisher<CVPixelBuffer, Never> { get }
    func startSession() async throws
    func stopSession()
    func capturePhoto() async throws -> UIImage
    func captureCurrentFrameJPEG(quality: CGFloat) async throws -> Data
    func switchCamera(to position: AVCaptureDevice.Position) async throws
}
```

**实现要点**：
- 后摄+前摄可切换
- `AVCaptureVideoDataOutput` 输出预览帧，丢弃音频
- 帧分辨率降到 1280×720（送模型够用，节省 token）
- actor 隔离状态保证线程安全

### 7.2 VisionService

**职责**：本地主体检测，用于实时对齐判定。

```swift
struct DetectedSubject {
    let boundingBox: CGRect          // Vision坐标系（0~1, 原点在左下）
    let confidence: Float
    let type: SubjectType            // .person | .face | .generic
}

protocol VisionServiceProtocol {
    func detectSubject(in pixelBuffer: CVPixelBuffer) async -> [DetectedSubject]
}
```

**实现要点**：
- `VNDetectFaceRectanglesRequest` 检测人脸
- `VNDetectHumanRectanglesRequest` 检测人形
- 二者中取置信度高者作为主体中心
- 帧率控制在10 FPS，用 `CADisplayLink` 或定时器跳帧

### 7.3 VisionModelAdapter 协议

```swift
protocol VisionModelAdapter {
    var kind: ModelKind { get }
    func analyze(imageJPEG: Data, prompt: String) async throws -> GuidancePlan
}
```

**三个实现**：

| 适配器 | Endpoint | 请求体关键点 | 响应解析位置 |
|---|---|---|---|
| `OpenAIAdapter` | `chat/completions` | `gpt-4o`，`response_format: {type: "json_object"}` | `choices[0].message.content` |
| `ClaudeAdapter` | `messages` | `claude-sonnet-4-6`，强制 `tool_use` 输出JSON | `content[0].text` 或 tool input |
| `QwenAdapter` | OpenAI兼容 | `qwen-vl-max` | 同OpenAI |

**共用工件**：
- `PromptBuilder` 拼装系统prompt+用户消息
- `GuidancePlanDecoder` 容错解析（处理markdown代码块包裹）
- 失败统一抛 `ModelError`

### 7.4 PhotoSaver

**职责**：把 UIImage 写入系统相册。

```swift
protocol PhotoSaverProtocol {
    func save(_ image: UIImage) async throws
}
```

**实现**：`PHPhotoLibrary.shared().performChanges`，需 `NSPhotoLibraryAddUsageDescription`。

### 7.5 CameraViewModel

```swift
@MainActor
final class CameraViewModel: ObservableObject {
    enum State { case idle, analyzing, guiding(plan: GuidancePlan), aligned, error(AppError) }
    
    @Published private(set) var state: State = .idle
    @Published private(set) var currentOffset: Double = 1.0  // 0=对齐, 1=最大
    @Published private(set) var lastSavedPhoto: UIImage?
    
    private let camera: CameraServiceProtocol
    private let vision: VisionServiceProtocol
    private let model: VisionModelAdapter
    private let saver: PhotoSaverProtocol
    private var alignmentTask: Task<Void, Never>?
    
    func onAnalyzeTap()
    func onCancelTap()
    func onShutterTap()
    private func startAlignmentLoop()
    private func checkAlignment(frame: CVPixelBuffer)
}
```

### 7.6 SwiftUI 视图

- `RootView`：TabView，单Tab"相机"，设置页藏于 Toolbar
- `CameraView`：ZStack = `CameraPreviewView`（UIViewRepresentable包AVCaptureVideoPreviewLayer）+ `GuidanceOverlayView`（Canvas画引导点、偏移指示）+ 底部控制栏
- `GuidanceOverlayView`：订阅 `viewModel.state`，渲染引导点（呼吸动画）、方向箭头、提示语
- `SettingsView`：Form，模型选择、API Key（SecureField）、自动拍开关、对齐阈值Slider

## 8. 错误处理

### 8.1 AppError 枚举

```swift
enum AppError: LocalizedError {
    // 相机
    case cameraPermissionDenied
    case cameraSessionFailed(underlying: String)
    
    // 模型
    case modelNotConfigured
    case modelAuthFailed
    case modelRateLimited
    case modelNetworkTimeout
    case modelResponseInvalid
    case modelServerError(code: Int, msg: String)
    
    // 相册
    case photoLibraryPermissionDenied
    case photoSaveFailed(underlying: String)
    
    // 对齐
    case noSubjectDetected
}
```

用户可见消息通过 `errorDescription` 本地化，绝不暴露原始堆栈。

### 8.2 处理策略

| 阶段 | 错误 | 处理 |
|---|---|---|
| 启动 | 相机权限拒绝 | 弹窗引导到系统设置；提供"重试" |
| 启动 | 相机启动失败 | 错误态，3秒后自动回idle |
| 分析 | 未配置Key | 弹窗"前往设置" |
| 分析 | 401/403 | 弹窗"API Key无效" |
| 分析 | 429 | 显示"调用过快，X秒后重试"，自动重试 |
| 分析 | 网络超时 >15s | 弹窗"网络超时，重试？" |
| 分析 | 解析失败 | 重试一次；仍失败则"AI返回异常，可手动拍" |
| 引导 | 无主体 | 顶部黄条提示 |
| 引导 | 持续3秒无主体 | 弹窗"自动取消引导"，回idle |
| 拍照 | 相册权限拒绝 | 弹窗引导系统设置 |
| 拍照 | 保存失败 | 重试一次；仍失败则提示 |

### 8.3 设计原则

- 永不静默失败
- 可恢复优先（"重试"/"去设置"按钮）
- 不阻塞拍摄：AI失败时仍可手动拍
- 降级路径：模型失败 → 跳过引导；本地检测失败 → 用默认锚点
- 可观测性：本地日志（Debug构建启用，Release禁用）

## 9. 测试策略

### 9.1 层次

| 层级 | 范围 | 工具 | 覆盖目标 |
|---|---|---|---|
| 单元测试 | 纯逻辑组件 | XCTest | ≥ 80% |
| 集成测试 | Adapter + Service协作 | XCTest + 协议替身 | 关键路径 |
| UI测试 | 关键交互 | XCUITest | 烟雾测试 |

### 9.2 必写单元测试

- **GuidancePlanDecoder**：纯JSON / markdown包裹 / 缺字段 / 坐标越界 / 类型不匹配
- **PromptBuilder**：OpenAI/Claude/Qwen三种格式拼接正确
- **AlignmentCalculator**：重合/偏移/多主体/无主体各场景
- **AppSettings持久化**：切换模型、Key存Keychain、非法JSON降级
- **三个Adapter**：成功/401/403/429/500/超时/响应污染各路径（用URLProtocol stub）
- **LogWriter**：写读/清理/并发

### 9.3 集成测试

用 FakeCameraService（固定帧序列）+ FakeVisionModelAdapter（预设GuidancePlan）验证CameraViewModel状态机：
- 点"分析" → analyzing → guiding
- 引导中点"取消" → idle
- 检测到对齐 → aligned
- 自动拍开启+对齐 → 调PhotoSaver → idle
- 手动拍模式+对齐 → 保持aligned直到用户点快门

### 9.4 UI 测试（最小集）

1. 冷启动看到相机预览
2. 未配置Key点"分析"看到"前往设置"提示
3. 填Key后点"分析"看到loading态

不测：实际模型结果、Vision准确性（人工+真机验证）。

### 9.5 手动验证清单（真机）

- 后摄/前摄各拍一张对齐照片
- 暗光/逆光下检测成功率
- 三种模型各跑一次
- Key错误/网络中断/拒绝相册权限的友好提示
- 照片正确进入系统相册"相机胶卷"

### 9.6 测试组织

- `AppTests/Unit/` — 纯逻辑
- `AppTests/Integration/` — Fake替身+流程
- `AppUITests/` — XCUITest
- `AppTests/Support/` — Fake/Mock
- 不引入第三方测试库，标准XCTest足够

## 10. 交付节奏

按"MVP优先"原则：
- **MVP（首个可用版）**：F1~F8 + 三种Adapter（其中Qwen可放最后）+ 基础错误处理 + 单元测试
- **v1.1**：设置页完善、UI润色、可访问性、日志完善
- **v2+**：ARKit深度方案、Android、滤镜分享等（本设计不涉及）

## 11. 风险与缓解

| 风险 | 缓解 |
|---|---|
| 大模型返回非严格JSON | GuidancePlanDecoder容错解析；重试一次 |
| 大模型延迟过高（>15s） | 超时降级到"跳过引导直接拍" |
| iOS Vision框架识别失败 | 用默认锚点（画面中心）+ 提示"未检测到主体" |
| API Key泄露 | Keychain存储 + 日志脱敏 + 不上传 |
| 私有Endpoint（用户自配代理） | AppSettings.endpoint可自定义 |
| 拍照后用户发现照片不理想 | 提示语+对齐阈值可调，给用户掌控感 |

## 12. 待办与已知缺口

- [ ] iOS 最低版本 = iOS 17（设计假设）
- [ ] Bundle ID / 开发者证书 待配置
- [ ] 上架策略（App Store vs TestFlight 仅限本人）待定
- [ ] CI/CD 暂未引入（本地构建 + 真机手动验证）
- [ ] 无障碍 / VoiceOver / Onboarding 教学 暂未做（v1.1）
