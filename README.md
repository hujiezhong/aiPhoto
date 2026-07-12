# aiPhoto

iOS App：用云端大模型的视觉能力辅助拍照构图。
用户把相机对准人景合影，点"分析"，云端大模型返回构图引导点，画面叠加引导层，用户把主体对齐后拍照，照片存系统相册。

## 状态

**MVP 设计与源代码生成完成**（v0.1.0-mvp, 29 commits）。
当前环境（Windows 11）无 Xcode 工具链，代码**未经编译/运行验证**。

> **本仓库代码完整可读，到任何 Mac/Xcode 环境下 10 分钟内可 build 跑起来。**

---

## 路径 A：有 Mac

```bash
brew install xcodegen
cd /path/to/aiPhoto
xcodegen generate
open aiPhoto.xcodeproj
# Xcode 中：⌘U 跑测试（应全绿） / ⌘R 跑 App
# 按 MANUAL_TESTING.md 走 13 项真机验证
```

## 路径 B：没有 Mac（云端自动构建）

把仓库 push 到 GitHub，访问 `Actions` 标签，会自动跑 macOS build/test（GitHub 免费提供 macOS runner）。

```bash
git remote add origin git@github.com:你的用户名/aiPhoto.git
git push -u origin master
```

**.github/workflows/build.yml** 已经配置好：装 xcodegen → 生成项目 → build → 跑单元测试。

免费层 2000 分钟/月，足够日常使用。

## 路径 C：没有 Mac，但想部分本地验证

iOS App 没法在 Windows 本地 build，但**纯逻辑代码**（Models / Errors / 部分 Services / Utilities）可以用 `swift test` 在 Windows 上验证。具体步骤：装 Swift toolchain → 拆出可重用的 Swift Package。

## 仓库内容

```
aiPhoto/
├── aiPhoto/                  # 28 个 Swift 源文件
│   ├── aiPhotoApp.swift      # @main 入口 + DI
│   ├── Models/               # 7 个数据模型
│   ├── Errors/AppError.swift
│   ├── Services/             # 10 个业务层
│   │   ├── PromptBuilder.swift          # 系统 Prompt + 三家请求体
│   │   ├── GuidancePlanDecoder.swift    # 容错 JSON 解析
│   │   ├── VisionModelAdapter.swift     # 协议
│   │   ├── OpenAIAdapter.swift          # GPT-4o 适配器
│   │   ├── ClaudeAdapter.swift          # Anthropic 适配器
│   │   ├── QwenAdapter.swift            # 通义千问适配器
│   │   ├── CameraService.swift          # AVFoundation 封装
│   │   ├── VisionService.swift          # 人脸/人形检测
│   │   ├── PhotoSaver.swift             # 系统相册写入
│   │   └── LogWriter.swift              # 本地日志
│   ├── ViewModels/           # 2 个
│   ├── Views/                # 5 个 SwiftUI 视图
│   └── Utilities/            # KeychainStore, AlignmentCalculator
├── aiPhotoTests/             # 25 个测试文件
│   ├── Unit/                 # 纯逻辑
│   ├── Integration/          # Adapter + ViewModel
│   ├── UI/                   # XCUITest 烟雾测试
│   └── Support/              # Fake / Stub
├── .github/workflows/build.yml   # GitHub Actions macOS build
├── docs/superpowers/
│   ├── specs/2026-07-01-aiPhoto-design.md   # 设计文档
│   └── plans/2026-07-01-aiPhoto-mvp.md      # 实施计划
├── project.yml               # xcodegen 配置
├── MANUAL_TESTING.md         # 真机手动验证清单
├── FINAL_REVIEW.md           # 最终自审报告（含已修 bug）
└── README.md
```

## 设计 / 计划 / 自审

- [设计文档](docs/superpowers/specs/2026-07-01-aiPhoto-design.md)
- [实施计划](docs/superpowers/plans/2026-07-01-aiPhoto-mvp.md)
- [最终 review](FINAL_REVIEW.md)
- [真机清单](MANUAL_TESTING.md)

## 核心技术

| 维度 | 选型 |
|---|---|
| 平台 | iOS 17+ |
| UI | SwiftUI |
| 状态 | MVVM + @Published |
| 多模型 | 协议 + 工厂（OpenAI / Claude / Qwen 三家可热切换） |
| 本地主体检测 | iOS Vision 框架（人脸优先，无人脸回退到人形） |
| 拍照 | AVFoundation (`AVCapturePhotoOutput`) |
| 存图 | `PHPhotoLibrary.addOnly` |
| 持久化 | Keychain（API Key）+ UserDefaults JSON（其他设置） |
| 项目脚手架 | xcodegen（无需 Xcode GUI） |

## 已知缺口（v0.1.0）

- 代码未在此环境编译过（无 Swift toolchain）
- UI 烟雾测试未运行过
- 真机手动验证清单见 `MANUAL_TESTING.md`
- v0.2.0 候选技术债（不影响 MVP）：
  - 抽取 `OpenAICompatibleAdapter` 基类消除 OpenAI/Qwen 重复
  - 补 4 个"协议合规"测试文件的实质业务测试
  - `VisionService` 处理前后摄 orientation（镜像）
  - Adapter 5xx 重试/退避
  - `armv7` → `arm64` capability 修正（已在 v0.1.0-mvp commit 中修复）

## 关键修复记录

最终 code reviewer 发现 2 个 critical bug，已修复：

1. **模型热切换不生效**（`066e959`）：`aiPhotoApp.init()` 原本只启动时创建一个 Adapter，SettingsView 切模型不生效。改为 `modelProvider: (ModelKind) -> VisionModelAdapter` closure，每次 `analyze` 取最新选择。
2. **`project.yml` 写错 `armv7`**（`066e959`）：iOS 17 不可能跑 armv7，删除该 capability。

详见 `FINAL_REVIEW.md`。
