# 预设生字词表数据结构

预设字帖让用户无需手输即可选择常用生字、主题词组或教材单元，点击后填入输入框并生成字帖。

## 文件位置

| 路径 | 说明 |
|------|------|
| `assets/preset_lists.json` | 基础预设数据 |
| `assets/preset_tang300.json` | 唐诗三百首（319 首，由 `tool/build_tang300_preset.dart` 生成） |
| `lib/src/models/localized_label.dart` | 多语言标题 |
| `lib/src/models/preset_sheet_list.dart` | 分类与列表模型 |
| `lib/src/parsers/preset_list_catalog_loader.dart` | 加载与校验 |

在 `pubspec.yaml` 中已注册 `assets/preset_lists.json`。

## JSON Schema（schemaVersion: 1）

```json
{
  "schemaVersion": 1,
  "categories": [
    {
      "id": "grade1",
      "sortOrder": 10,
      "icon": "school",
      "title": {
        "zh": "一年级生字",
        "en": "Grade 1 characters",
        "zh_Hant": "一年級生字"
      },
      "lists": [
        {
          "id": "grade1_unit1",
          "sortOrder": 1,
          "title": { "zh": "识字 1–10", "en": "Characters 1–10" },
          "description": { "zh": "10 字 · 入门常用" },
          "text": "天地人你我他一二三四五",
          "tags": ["grade1", "unit1"],
          "source": { "zh": "示例 · 非官方教材" }
        }
      ]
    }
  ]
}
```

### 根字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `schemaVersion` | int | 是 | 当前为 `1` |
| `categories` | array | 是 | 分类列表，非空 |

### `categories[]` — 分类

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | 是 | 稳定 ID，全局唯一 |
| `title` | LocalizedLabel | 是 | 分类名称 |
| `lists` | array | 是 | 该分类下的预设列表，非空 |
| `sortOrder` | int | 否 | 越小越靠前，默认 `0` |
| `icon` | string | 否 | Material Icons 名，供 UI 映射（如 `school`） |

### `lists[]` — 预设字帖

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | 是 | 稳定 ID，**全库唯一** |
| `title` | LocalizedLabel | 是 | 列表项标题 |
| `text` | string | 是 | **仅汉字**，无空格标点；与输入框规则一致 |
| `sortOrder` | int | 否 | 分类内排序 |
| `description` | LocalizedLabel | 否 | 副标题（字数、单元说明） |
| `tags` | string[] | 否 | 自由标签，便于筛选 |
| `source` | LocalizedLabel | 否 | 出处（教材版本等） |

### `LocalizedLabel`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `zh` | string | 是 | 简体中文 |
| `en` | string | 否 | 英文，缺省回退 `zh` |
| `zh_Hant` | string | 否 | 繁体，缺省回退 `zh` |

## `text` 字段规则

1. 只含基本汉字区 `U+4E00–U+9FFF`。
2. 可连续多字，如 `春天花草`；生成字帖时 **每字一行**（与手动输入一致）。
3. 超出 A4 单页容量时，由 `PracticeSheetController` 自动截断并提示。
4. 加载时 `PresetListCatalogLoader` 会校验非法字符。

## Dart 模型关系

```
PresetListCatalog
  └── List<PresetListCategory>
        └── List<PresetSheetList>
              ├── id, text, tags, sortOrder
              ├── title: LocalizedLabel
              ├── description?: LocalizedLabel
              └── source?: LocalizedLabel
```

### 加载示例

```dart
final loader = PresetListCatalogLoader();
final catalog = await loader.loadFromAsset();

for (final category in catalog.categories) {
  for (final list in category.lists) {
    // list.text → PracticeSheetController.textController.text
    // await controller.generate();
  }
}
```

### 与 UI 对接

字帖页已实现：

- 输入框下方 **快捷 chip**（3 个热门预设 +「更多预设」）
- 空状态 **「或选择预设字帖」** + 同款 chip
- **底部弹层**：分类 Tab、最近用过、列表项点击后自动填入并生成

相关代码：`lib/src/ui/preset_list_sheet.dart`、`lib/src/services/preset_list_service.dart`。

## 扩充教材生字

建议按 **年级 → 单元** 追加 `lists`，保持 `id` 稳定（如 `grade2_unit3`）。

完整人教版/部编版生字需自行核对教材；当前 JSON 为 **示例数据**，`source` 字段可标注教材版本与学期。

## 校验

运行测试：

```bash
flutter test test/preset_list_catalog_test.dart
```

## 相关文档

- [APP_STORE_METADATA.md](./APP_STORE_METADATA.md)
