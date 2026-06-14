# App icon assets

Black background with white **练** rendered from `hanzi_dictionary.json` stroke paths — the same Make Me a Hanzi vectors used in practice sheets (not a system font).

## Regenerate

From repo root:

```powershell
powershell -ExecutionPolicy Bypass -File tool/export_app_icons.ps1
```

This runs `flutter test tool/render_glyph_icon_test.dart` to rasterize the glyph, then exports iOS / Android / Web / Windows sizes.

Source: `app_icon_lian_square.png` (1024×1024, opaque RGB, no alpha — required for App Store).
