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
