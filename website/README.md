# 官网静态站点部署说明

本目录包含可直接部署到任意 Web 服务器的静态页面。每个应用使用**路径缩写**区分，便于在同一域名下托管多个 App 的官网、隐私政策与技术支持页。

**线上域名：** https://www.leo-app.cn

## 目录结构

```
website/
├── index.html          # 站点首页（应用列表）
├── css/site.css        # 共用样式
├── hp/                 # 笔顺练字帖 (Handwriting Practice)
│   ├── index.html      # 产品首页
│   ├── support.html    # 技术支持
│   ├── privacy-zh.html # 隐私政策（中文）
│   └── privacy-en.html # Privacy Policy (EN)
├── pa/                 # 关节量角器 (Joint Goniometer / pose-angle)
│   ├── index.html      # 产品首页
│   ├── support.html    # 技术支持
│   ├── privacy-zh.html # 隐私政策（中文）
│   └── privacy-en.html # Privacy Policy (EN)
└── README.md
```

### 路径缩写说明

| 缩写 | 应用 | 说明 |
|------|------|------|
| `hp` | 笔顺练字帖 / Hanzi Practice | Handwriting Practice，`com.leoxp.handwritingpractice` |
| `pa` | 关节量角器 / Joint Goniometer | pose-angle，`com.leoxp.poseangle`（iOS） |

新应用：复制 `hp/` 或 `pa/` 为新的缩写目录（如 `xyz/`），修改页面内容，并在根目录 `index.html` 的应用列表中添加卡片。

## 笔顺练字帖 — App Store Connect URL

| 字段 | URL |
|------|-----|
| Privacy Policy URL | https://www.leo-app.cn/hp/privacy-zh.html |
| Support URL | https://www.leo-app.cn/hp/support.html |
| Marketing URL（可选） | https://www.leo-app.cn/hp/ |

站点总入口：https://www.leo-app.cn/

支持邮箱：**xp84012493@163.com**

## 关节量角器 — App Store Connect URL

| 字段 | URL |
|------|-----|
| Privacy Policy URL | https://www.leo-app.cn/pa/privacy-zh.html |
| Support URL | https://www.leo-app.cn/pa/support.html |
| Marketing URL（可选） | https://www.leo-app.cn/pa/ |

## 部署

### Nginx 示例

```nginx
server {
    listen 80;
    server_name www.leo-app.cn leo-app.cn;
    root /var/www/leo-app;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### 上传

```bash
rsync -avz --delete website/ user@your-server:/var/www/leo-app/
```

## 验证清单

- [ ] https://www.leo-app.cn/ 应用列表可访问
- [ ] https://www.leo-app.cn/hp/ 及各子页面可访问
- [ ] https://www.leo-app.cn/pa/ 及各子页面可访问
- [ ] App Store Connect 使用带 `/hp/` 或 `/pa/` 前缀的 URL
