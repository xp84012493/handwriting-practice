# iOS 云端构建与 TestFlight 自动上传

本仓库通过 [`.github/workflows/ios.yml`](../.github/workflows/ios.yml) 在 GitHub Actions（macOS + Xcode 26）上：

1. 签名并构建 **Ad Hoc** 与 **App Store** 两套 IPA  
2. 将 **App Store IPA** 自动上传到 **App Store Connect → TestFlight**  
3. 将两套 IPA 保存为 Actions Artifact（便于本地下载或 Ad Hoc 安装）

无需 Mac 本机或 Transporter 手动操作。

## 触发方式

| 方式 | 行为 |
|------|------|
| 推送到 `main` | 构建 + 自动上传 TestFlight |
| Actions → **iOS Build** → **Run workflow** | 可勾选是否上传 TestFlight |

## 一次性配置

### 1. Apple 开发者后台

- **Bundle ID**：`com.leoxp.handwritingpractice`（与 `ios/Runner.xcodeproj` 中 `PRODUCT_BUNDLE_IDENTIFIER` 一致）
- 在 [App Store Connect](https://appstoreconnect.apple.com/) 创建应用，Bundle ID 同上
- 准备 **Apple Distribution** 证书（导出 `.p12`）
- 准备两份描述文件：
  - **Ad Hoc**（真机测试安装）
  - **App Store**（TestFlight / 上架）

若与 `pose-angle` 使用同一开发者账号，可复用同一 Distribution 证书；描述文件需为 **本应用 Bundle ID** 单独创建。

### 2. 签名相关 Secrets（GitHub Repository secrets）

| Secret | 说明 |
|--------|------|
| `P12_BASE64` | Apple Distribution `.p12` 的 Base64 |
| `P12_PASSWORD` | `.p12` 密码 |
| `MOBILEPROVISION_BASE64` | Ad Hoc 描述文件 Base64 |
| `MOBILEPROVISION_APPSTORE_BASE64` | App Store 描述文件 Base64 |
| `APPLE_TEAM_ID` | 10 位 Team ID |
| `IOS_PROVISIONING_PROFILE_NAME` | Ad Hoc 描述文件在 Apple 后台的 **Name** |
| `IOS_PROVISIONING_PROFILE_NAME_APPSTORE` | App Store 描述文件 Name |

**PowerShell 将文件转为 Base64：**

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("path\to\cert.p12")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("path\to\profile.mobileprovision")) | Set-Clipboard
```

### 3. App Store Connect API Key（自动上传 TestFlight 必需）

1. 打开 [App Store Connect → 用户和访问 → 集成 → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)  
2. 生成 API 密钥，权限至少 **App 管理**  
3. 记录 **Issuer ID**、**Key ID**，下载 `AuthKey_XXXXXXXXXX.p8`（仅可下载一次）

| Secret | 值 |
|--------|-----|
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID（UUID） |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID（10 位） |
| `APP_STORE_CONNECT_API_PRIVATE_KEY` | `.p8` 原文或 Base64 编码 PEM |

**推荐用 Base64 存私钥：**

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("keys\AuthKey_XXXXXXXXXX.p8")) | Set-Clipboard
```

## 构建号

CI 自动递增：`run_number * 10 + run_attempt`，写入 `pubspec.yaml` 的 `+build` 部分，避免与已上传 build 冲突。

## 上传后

1. App Store Connect → 你的 App → **TestFlight**  
2. 等待构建处理完成  
3. 在内部/外部测试组中添加构建  

## 常见问题

### `Missing secrets: P12_BASE64`

未配置签名相关 Secret，按上文第 2 节补全。

### `401 NOT_AUTHORIZED`

JWT 认证失败。核对 `APP_STORE_CONNECT_API_KEY_ID`（10 位）、`APP_STORE_CONNECT_ISSUER_ID`（UUID，不是 Team ID）、`APP_STORE_CONNECT_API_PRIVATE_KEY`（完整 PEM 或 Base64）。详见 workflow 日志中的 **Verify App Store Connect API credentials** 步骤。

### 仅构建、不上传 TestFlight

Actions → **iOS Build** → **Run workflow**，取消勾选 **Upload App Store IPA to TestFlight after build**。

### 从 Artifact 下载 IPA

Workflow 完成后，在 Actions 运行页底部 **Artifacts** 下载 `ios-ipas-adhoc-and-appstore`：
- `build/ios/ipa/*.ipa` — Ad Hoc（可注册设备后安装）
- `build/ios/ipa-appstore/*.ipa` — App Store 包

## 相关链接

- [GitHub：在 macOS runner 上安装 Apple 证书](https://docs.github.com/en/actions/deployment/deploying-xcode-applications/installing-an-apple-certificate-on-macos-runners-for-xcode-development)  
- [Apple：创建 App Store Connect API 密钥](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api)
