# 无 Mac 准备 iOS 签名材料指南

> 目标：完全不接触 Mac，用 Windows + GitHub Actions 把 aiPhoto 装到自己的 iPhone 上。
> 全程约 30-60 分钟（其中等 Apple 审核 5-10 分钟）。

## 你需要的全部材料

| # | 材料 | 来源 |
|---|---|---|
| 1 | Apple Developer 账号 | https://developer.apple.com （免费个人账号即可） |
| 2 | iPhone UDID | iPhone 连接电脑查看 |
| 3 | 签名证书 (.p12) | 你即将用 openssl 生成 |
| 4 | Provisioning Profile | Apple Developer 后台创建 |
| 5 | Team ID | Apple Developer 后台 |

---

## Step 1: 注册 Apple Developer 账号（5 分钟）

1. 打开 https://developer.apple.com/account
2. 用你的 Apple ID 登录
3. 同意协议，注册个人账号（**免费**）
4. 注意：免费账号 7 天后证书会过期，到时重新跑 workflow 即可

## Step 2: 查 iPhone UDID（2 分钟）

**方法 A**：用 Windows 装 3uTools（https://www.3u.com）
- 数据线连 iPhone
- 打开 3uTools → 设备信息 → UDID

**方法 B**：iPhone 装 App "UDID查询" 类（搜"UDID"）
- 注意：iOS 17+ 限制了 App 读 UDID，此方法可能失败

**方法 C**：找朋友 Mac 帮忙（最快）
- Mac 打开 Finder → 选 iPhone → 点序列号位置多次切换到 UDID

记下 UDID，形如 `00008110-001234567890ABCD`。

## Step 3: 在 Apple Developer 后台注册设备（2 分钟）

1. https://developer.apple.com/account/resources/devices/list
2. 点 + 添加设备
3. Device Name: `iPhone-hujie`（随便起）
4. Device ID (UDID): 粘贴你的 UDID
5. Register

## Step 4: 创建 App ID（2 分钟）

1. https://developer.apple.com/account/resources/identifiers/list
2. 点 + → App IDs → Continue
3. Description: `aiPhoto`
4. Bundle ID: `com.hujiezhong.aiphoto`（**选 Explicit**）
5. Capabilities: 勾选
   - Camera (`com.apple.developer.device-cameras-access`)
   - Photo Library (`com.apple.developer.photos-service`)
6. Continue → Register

## Step 5: 生成签名证书（10 分钟）

### 5.1 创建 CSR（Certificate Signing Request）

打开 Git Bash（你已经在用），运行：

```bash
mkdir -p ~/aiPhoto-signing && cd ~/aiPhoto-signing

# 生成 RSA 私钥
openssl genrsa -out aiPhoto.key 2048

# 生成 CSR（会被 Apple 拒绝，要稍作修改）
openssl req -new -key aiPhoto.key -out aiPhoto.csr -subj "/emailAddress=hujie@youremail.com,CN=Hujie Zhong,O=Hujie"
```

⚠️ **CSR 会被 Apple 网站报错**（缺少 OU 字段），解法：
- 用 GUI 工具 `XCA`（https://hohnstaedt.de/xca/）生成完整 CSR
- 或用 `easy-rsa`（https://github.com/OpenVPN/easy-rsa）
- 或参考下面"变通方案"

### 5.2 变通方案：用 fastlane 在 GitHub Actions 里生成

更简单：让我加一个 workflow 在 CI 里生成 CSR，然后你下载 → 上传 Apple Developer。

**或者用最简单的方案**：借一次 Mac 朋友 30 分钟，用 Xcode 一键搞定。

### 5.3 把 CSR 提交到 Apple 后台

1. https://developer.apple.com/account/resources/certificates/list
2. + → Apple Development → Continue
3. Choose File → 上传 `aiPhoto.csr`
4. Continue → Download 生成好的 `.cer` 文件
5. 双击 .cer 在 Windows 上没反应，所以需要转换：

```bash
# 把 Apple 的 .cer 转为 .p12
openssl x509 -in ios_development.cer -inform DER -out ios_development.pem
openssl pkcs12 -export -inkey aiPhoto.key -in ios_development.pem -out aiPhoto.p12
# 会问密码，记下来 → 这就是 IOS_CERTIFICATE_PASSWORD
```

## Step 6: 创建 Provisioning Profile（3 分钟）

1. https://developer.apple.com/account/resources/profiles/list
2. + → iOS App Development → Continue
3. 选你创建的 App ID: `com.hujiezhong.aiphoto`
4. 选刚生成的证书
5. 选设备: `iPhone-hujie`
6. Profile Name: `aiPhoto`
7. Generate → Download → 文件名类似 `aiPhoto.mobileprovision`

## Step 7: 找到你的 Team ID

1. https://developer.apple.com/account#membership
2. **Team ID** 字段，10 个字符，例如 `ABCDE12345`

## Step 8: 把材料传到 GitHub Secrets

去 https://github.com/hujiezhong/aiPhoto/settings/secrets/actions/new

新建以下 Secrets：

| Secret 名称 | 值 |
|---|---|
| `APPLE_TEAM_ID` | 你的 Team ID（10字符） |
| `IOS_CERTIFICATE_PASSWORD` | .p12 的密码 |
| `IOS_CERTIFICATE_P12` | `base64 -w 0 aiPhoto.p12` 的输出 |
| `IOS_PROVISIONING_PROFILE` | `base64 -w 0 aiPhoto.mobileprovision` 的输出 |
| `KEYCHAIN_PASSWORD` | 任意密码，如 `tempBuildKeychain123` |

## Step 9: 触发 Actions

```bash
git commit --allow-empty -m "trigger signed build"
git push
```

去 https://github.com/hujiezhong/aiPhoto/actions 看 signed-ipa job。
成功后下载 `.ipa` artifact。

## Step 10: 装到 iPhone（5 分钟）

**方法 A（推荐）**：AltStore
1. Windows 上下载 AltServer: https://altstore.io/
2. 启动 AltServer → 用 Apple ID 登录 → 连 iPhone
3. AltStore 自动签名 .ipa → 装到 iPhone

**方法 B**：用 ideviceinstaller（命令行）
1. 安装 iTunes（Windows 版）
2. `ideviceinstaller -i aiPhoto.ipa`

**方法 C**：最简单——把 .ipa 传到自己的网盘，用 iPhone Safari 访问 + 安装
（需要企业证书，普通开发者证书不行）

---

## 🚨 现实检查

### 容易卡住的环节

1. **CSR 生成**（最容易出错）—— Apple 拒绝无 OU 的 CSR
   - 解法 1: 用 XCA GUI
   - 解法 2: 借 Mac 30 分钟（用 Xcode 一键）
   - 解法 3: 我帮你写 GitHub Actions job 自动生成 CSR

2. **Profile 安装到 Xcode 项目**（自动签名需要）
   - 我们 project.yml 里没设 `PROVISIONING_PROFILE_SPECIFIER`
   - 我已经在 workflow 里设了，应该 OK

3. **免费账号 7 天过期**
   - 过期后重新跑 workflow 重新签名即可

### 最省事的路径

**借一次 Mac**（朋友、同事、大学机房、共享办公），30 分钟搞定全部签名材料。
之后再也不用 Mac。

---

## 我能立即帮你做的

- ✅ 已写好 workflow（done）
- ✅ 已写好 Secrets 清单（done）
- ❓ **需要你做决策**：你愿意试上面这套流程吗？

  - 选项 A：照文档做，遇到问题来问
  - 选项 B：借一次 Mac，让我远程指导
  - 选项 C：放弃签名，等真买 Mac 时再用