# In-app purchase setup（20 次免费 → 一次性解锁）

应用内 **每成功生成一次字帖** 计 1 次；前 **20 次免费**，之后需购买 **非消耗型** 内购 `handwriting_practice_unlock` 解锁无限次。

iOS / Android 走商店内购；Windows / Web 开发版不限制次数。

### 卸载后次数会重置吗？

| 平台 | 行为 |
|------|------|
| **iOS** | 次数与解锁状态存在 **Keychain**，**同一 App 卸载再安装通常仍会保留**（Apple 机制） |
| **Android** | 卸载会清除应用数据，**次数会重置**；已购「解锁」可通过 **恢复购买** 找回（安装后首次打开也会自动恢复） |
| **无后端账号** | 无法 100% 防刷；要跨设备同步或 Android 卸载后也记次数，需自建账号 + 服务端 |

代码使用 `flutter_secure_storage`（见 [`UsageQuotaService`](../lib/src/services/usage_quota_service.dart)）。

### 分享得免费次数

- **设置 → 分享得免费次数**：调起系统分享面板，分享推荐文案 + App Store 链接
- 每成功分享 1 次 → **+5 次**免费生成额度
- 最多奖励 **10 次分享**（合计最多 +50 次，即 20+50=70 次免费）
- 上架后请在 [`AppShareConfig`](../lib/src/config/app_share_config.dart) 中替换正式 App Store URL
- 无法验证对方是否已安装或读完；仅在系统返回 **已选择分享目标**（`ShareResultStatus.success`）时发放，用户直接关闭面板不计入

---

| 平台 | Product ID | 类型 |
|------|------------|------|
| App Store Connect | `handwriting_practice_unlock` | 非消耗型（Non-Consumable） |
| Google Play Console | `handwriting_practice_unlock` | 一次性商品（One-time product） |

代码见 [`lib/src/config/iap_products.dart`](../lib/src/config/iap_products.dart)。

---

## App Store Connect

1. 你的 App → **功能** → **App 内购买项目** → **+**
2. 类型选 **非消耗型项目**
3. **参考名称**：例如 `Unlimited sheet generation`
4. **产品 ID**：`handwriting_practice_unlock`（必须与代码一致）
5. 设置 **价格**（如 ¥12 / ¥18，按你的定价）
6. 添加 **本地化显示名称与描述**（审核会看）
7. 状态变为 **准备提交** 后，随 App 版本一并提交审核

审核备注可写：前 20 次生成字帖免费，第 21 次起弹出购买页；设置里可 **恢复购买**；安装后首次打开也会自动恢复已购解锁。

---

## Google Play（若上架）

1. **Monetize → Products → One-time products**
2. Product ID：`handwriting_practice_unlock`
3. 激活并定价

---

## 测试

- **iOS**：Sandbox 测试账号，TestFlight 或 Xcode 安装
- 购买前需先在 Connect 创建商品并关联 App
- 若商品未配置，应用内会提示「商店尚未配置内购商品」

---

## 合规提示

- 数字功能解锁 **必须** 使用 IAP，不可引导站外支付
- 提供 **恢复购买**（已实现于购买页；安装后首次打开也会静默恢复）
- App Store 审核说明中写清：20 次免费试用 + 一次性解锁
