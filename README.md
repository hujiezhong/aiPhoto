# aiPhoto

iOS App：用云端大模型的视觉能力辅助拍照构图。

## 状态

**MVP 设计 + 源代码生成完成。** 当前环境（Windows 11）无 Xcode 工具链，代码**未经编译/运行验证**。到 Mac 环境后可按下方步骤构建。

## 在 Mac 上构建（推荐路径）

### 一次性环境准备

```bash
# 1. 安装 xcodegen（Homebrew）
brew install xcodegen

# 2. 在本仓库根目录生成 Xcode 项目
cd /path/to/aiPhoto
xcodegen generate

# 3. 打开 Xcode
open aiPhoto.xcodeproj
```

### 在 Xcode 中

1. 选择 `aiPhoto` target → Signing & Capabilities → 选择你的 Apple ID
2. 选择一个 iPhone 模拟器或真机
3. ⌘U 运行所有测试（应当全部通过）
4. ⌘R 运行 App

### 替换 plan 中的 Task 1-2、25

因环境无 Xcode，原本需 GUI 操作的步骤已用 `project.yml`（xcodegen）替代。**在 Mac 上 `xcodegen generate` 会一并完成原 plan 中 Task 1、Task 2、Task 25 的工作**。

## 当前仓库内容

- `aiPhoto/Models/` — 数据模型（NormalizedPoint, GuidancePlan 等）
- `aiPhoto/Errors/` — AppError
- `aiPhoto/Services/` — 业务层（Prompt、Adapter、Camera、Vision、Photo、Log）
- `aiPhoto/ViewModels/` — CameraViewModel, SettingsViewModel
- `aiPhoto/Views/` — SwiftUI 视图
- `aiPhoto/Utilities/` — KeychainStore, AlignmentCalculator
- `aiPhotoTests/Unit/` — 单元测试
- `aiPhotoTests/Integration/` — Adapter / ViewModel 集成测试
- `aiPhotoTests/Support/` — Test fakes / stubs
- `aiPhotoTests/UI/` — UI 烟雾测试
- `project.yml` — xcodegen 配置
- `docs/superpowers/specs/` — 设计文档
- `docs/superpowers/plans/` — 实施计划

## 设计 & 计划

- [设计文档](docs/superpowers/specs/2026-07-01-aiPhoto-design.md)
- [实施计划](docs/superpowers/plans/2026-07-01-aiPhoto-mvp.md)

## 已知缺口

- 代码未在本环境编译过（无 Swift toolchain）
- UI 烟雾测试未运行过
- 真机手动验证清单见 `MANUAL_TESTING.md`（代码生成后由最后一个 subagent 写入）
