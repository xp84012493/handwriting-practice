import 'package:flutter/material.dart';

/// 将 `preset_lists.json` 中的 icon 字段映射为 [IconData]。
IconData presetCategoryIcon(String? iconName) {
  switch (iconName) {
    case 'school':
      return Icons.school_outlined;
    case 'eco':
      return Icons.eco_outlined;
    case 'celebration':
      return Icons.celebration_outlined;
    case 'edit':
      return Icons.edit_outlined;
    default:
      return Icons.library_books_outlined;
  }
}
