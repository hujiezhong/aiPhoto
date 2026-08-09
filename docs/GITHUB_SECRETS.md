# GitHub Secrets 配置说明

> aiPhoto 的 signed-ipa workflow 需要 5 个 Secrets。

## 添加位置

https://github.com/hujiezhong/aiPhoto/settings/secrets/actions/new

点 **New repository secret**，逐个添加：

## Secrets 清单

### 1. APPLE_TEAM_ID

| 项目 | 值 |
|---|---|
| 名称 | `APPLE_TEAM_ID` |
| 值 | 你的 10 字符 Team ID（如 `ABCDE12345`） |
| 来源 | https://developer.apple.com/account#membership |

### 2. IOS_CERTIFICATE_P12

| 项目 | 值 |
|---|---|
| 名称 | `IOS_CERTIFICATE_P12` |
| 值 | `.p12` 文件的 base64 编码（无换行） |
| 怎么生成 | `base64 -w 0 aiPhoto.p12` |
| 备注 | **必须是单行**，去掉所有换行 |

### 3. IOS_CERTIFICATE_PASSWORD

| 项目 | 值 |
|---|---|
| 名称 | `IOS_CERTIFICATE_PASSWORD` |
| 值 | 生成 .p12 时设的密码 |

### 4. IOS_PROVISIONING_PROFILE

| 项目 | 值 |
|---|---|
| 名称 | `IOS_PROVISIONING_PROFILE` |
| 值 | `.mobileprovision` 文件的 base64 编码（无换行） |
| 怎么生成 | `base64 -w 0 aiPhoto.mobileprovision` |

### 5. KEYCHAIN_PASSWORD

| 项目 | 值 |
|---|---|
| 名称 | `KEYCHAIN_PASSWORD` |
| 值 | **任意密码**（临时 keychain 用，不会泄露） |
| 建议 | `tempKeychainPass2026` 之类 |

## 验证方式

push 到 main 分支后：
1. 访问 https://github.com/hujiezhong/aiPhoto/actions
2. 看 `signed-ipa` job
3. ✅ success → 下载 artifact
4. ❌ fail → 看日志最常见错误：
   - `No signing certificate` → 检查 IOS_CERTIFICATE_P12
   - `Provisioning profile not found` → 检查 IOS_PROVISIONING_PROFILE
   - `No team found` → 检查 APPLE_TEAM_ID

## 安全提示

- ✅ Secrets 在 GitHub 后端加密，前端永远看不到明文
- ✅ Secrets 只在 `runs-on: macos-14` 的 job 内可见
- ✅ Workflow 里所有 secret 引用都用 `${{ secrets.XXX }}` 不会被打印到日志
- ⚠️ **不要** 把 .p12 或 .mobileprovision 直接 push 到 git

## 删除/轮换

- 想去掉一个 secret：Settings → Secrets → Delete
- 想轮换 .p12：更新 secret 值，触发新 build

## 故障排除清单

| 错误 | 原因 | 解决 |
|---|---|---|
| `errSecInternalComponent` | .p12 密码错误 | 检查 IOS_CERTIFICATE_PASSWORD |
| `Provisioning profile ... doesn't include signing certificate` | 证书与 profile 不匹配 | 重新生成匹配的 profile |
| `No code signing identities found` | .p12 没正确导入 | 检查 base64 编码 |
| `Bundle identifier conflict` | Bundle ID 与另一个 app 冲突 | 换一个 Bundle ID |
| `Your team has no devices registered` | 设备没注册 | 注册设备 UDID |