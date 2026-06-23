# Legal & store documents

## Privacy policy (App Store / GitHub Pages)

| Language | File |
|----------|------|
| English | [privacy-policy-en.md](privacy-policy-en.md) |
| 简体中文 | [privacy-policy-zh.md](privacy-policy-zh.md) |

### Before you publish

1. Replace placeholders: `[EFFECTIVE_DATE]`, `[SUPPORT_EMAIL]`, and any `[YOUR_NAME_OR_COMPANY]` if you add one.
2. Host the files over **HTTPS** (App Store Connect requires a privacy policy URL).

### GitHub Pages (example)

1. Repository **Settings → Pages → Build and deployment → Source:** Deploy from branch **`main`**, folder **`/docs`** (or copy `legal/*.md` to your Pages root).
2. After GitHub Pages is enabled, typical URLs:
   - English: `https://<GITHUB_USERNAME>.github.io/<REPO_NAME>/legal/privacy-policy-en`
   - 中文: `https://<GITHUB_USERNAME>.github.io/<REPO_NAME>/legal/privacy-policy-zh`
3. In **App Store Connect → App Privacy → Privacy Policy URL**, use the English page (or a single landing page that links to both).

> GitHub Pages renders Markdown automatically. If a path 404s, confirm Pages source folder and wait a few minutes after the first deploy.

### Suggested App Store fields

- **Privacy Policy URL:** English URL above  
- **Support URL:** project homepage or `mailto:[SUPPORT_EMAIL]`  
- **Marketing URL:** optional — repository or product page
