/// 练字格线宽与虚线参数（预览与 PDF 共用）。
abstract final class PracticeGridMetrics {
  static const double borderStrokeWidth = 0.75;
  static const double guideStrokeWidth = 0.65;
  static const List<double> guideDashPattern = [5.0, 3.5];
}

/// 练字格线样式。
enum PracticeGridStyle {
  /// 米字格：十字 + 对角虚线。
  mizi,

  /// 田字格：仅十字虚线。
  tianzi;

  /// SharedPreferences 存储值。
  String get prefsValue => name;

  /// 是否绘制对角辅助线。
  bool get drawDiagonals => this == PracticeGridStyle.mizi;

  static PracticeGridStyle fromPrefs(String? value) {
    if (value == PracticeGridStyle.tianzi.name) {
      return PracticeGridStyle.tianzi;
    }
    return PracticeGridStyle.mizi;
  }
}
