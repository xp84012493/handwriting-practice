# 上架前 Checklist（汉字笔顺练字帖）

面向 **App Store / Google Play / 国内商店** 的通用核对清单；具体以各平台当期规则为准。完成项可在 PR 或发版前打勾。

---

## 1. 产品与体验

- [ ] **核心流程**：多字输入 → 生成 → 预览；AppBar **「导出 PDF」** 菜单中 **系统打印 / 保存到文件 / 分享** 在 iPhone 真机上跑通。
- [ ] **字库预期**：默认 `assets/hanzi_dictionary.json` 字数与商店描述一致；若仅示例字，说明中写清「可扩充 / 需自备数据」。
- [ ] **弱网 / 无网**：本应用以本地资产为主时，确认无意外强依赖网络（若有，写进隐私说明）。
- [ ] **无障碍**：关键控件有语义或 Tooltip；字体缩放后主要按钮仍可点。
- [ ] **关于页**：应用内 **设置 → 语言 / 关于** 与第三方许可说明。

---

## 2. 工程与质量

- [ ] **版本号**：`pubspec.yaml` 的 `version:` 与商店构建号一致；与 `lib/src/app_build_info.dart` 中常量同步（若采用该文件）。
- [ ] **测试**：`flutter test` 通过；必要时补充关键路径 widget/integration 测试。
- [ ] **分析**：`flutter analyze` 无未处理严重问题。
- [ ] **Release 构建**：`flutter build ipa` / `flutter build appbundle`（或对应 CI）成功，安装包在目标系统版本上试装。

---

## 3. 合规与版权

- [ ] **笔画数据**：使用 Make Me a Hanzi `graphics.txt` 或其衍生数据时，保留 **Arphic Public License** 义务；README / `THIRD_PARTY_NOTICES.md` / 应用内说明一致。
- [ ] **未使用 dictionary.txt**：若未使用 MMaH `dictionary.txt`，勿在商店文案中暗示含 LGPL 字典全文。
- [ ] **自有代码许可证**：仓库根 `LICENSE`（MIT）与分发方式（开源 + 商店收费等）策略一致。
- [ ] **字体**：界面或 PDF 若嵌入其他字体（如霞鹜文楷），核对该字体在 App 分发场景下的许可。

---

## 4. App Store（Apple）

- [ ] **App Store Connect**：应用记录、Bundle ID、定价/销售范围、年龄分级问卷。
- [ ] **隐私**：**App 隐私** 标签与实际情况一致（数据收集、用途、是否关联用户等）。
- [ ] **出口合规**：`Info.plist` 已设 `ITSAppUsesNonExemptEncryption = false`（仅使用豁免加密时）；若日后加入自定义加密，须改回并重新申报。
- [ ] **截图与预览**：仅需 **iPhone** 截图（如 6.9" 1290×2796），展示真实 UI（勿误导）。本应用为 **iPhone-only**，无需 iPad 截图。
- [ ] **审核备注**：如需测试账号、特殊操作步骤，在「审核信息」中写清。
- [ ] **iOS 桌面显示名**：`en.lproj` / `zh-Hans.lproj` 的 `InfoPlist.strings`（英文 **Hanzi Practice**，中文 **汉字练字**）。
- [ ] **Privacy Manifest**：若使用需声明的 SDK / API，按 Apple 要求提供 `PrivacyInfo.xcprivacy`（随 Flutter/Xcode 版本更新核对）。

---

## 5. Google Play

- [ ] **商店详情**：短说明、完整说明、截图、功能图。
- [ ] **数据安全表单**：与网络、分析、崩溃上报等实际情况一致。
- [ ] **内容分级**：问卷完成。
- [ ] **目标 API 级别**：满足 Play 当期最低要求。

---

## 6. 国内安卓商店（若上架）

- [ ] **软著 / ICP 等**：按目标渠道要求准备资质与备案信息。
- [ ] **隐私政策 URL**：可访问、内容与 App 行为一致。
- [ ] **用户协议 / 未成年人**：按渠道要求提供。

---

## 7. 运营与支持

- [ ] **支持 URL / 邮箱**：商店必填项可访问，有人回复。
- [ ] **隐私政策 URL**：可访问的 HTTPS 页面；模板见 [`docs/legal/privacy-policy-en.md`](legal/privacy-policy-en.md) / [`privacy-policy-zh.md`](legal/privacy-policy-zh.md)，发布说明见 [`docs/legal/README.md`](legal/README.md)。
- [ ] **更新日志**：首版或后续版本在商店「新功能」中简述。

---

## 8. 发版后

- [ ] **监控崩溃**：接入崩溃统计（若采用）并在隐私政策中披露。
- [ ] **用户反馈**：应用内或商店评论渠道有跟进计划。

---

文档维护：随平台规则或本应用功能变更更新本清单。
