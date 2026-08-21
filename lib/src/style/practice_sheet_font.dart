/// 无笔画字帖可选的字形来源。
enum PracticeSheetFont {
  /// 应用内笔画轮廓字形（原示范字路径）。
  appDefault,

  /// 霞鹜文楷 GB。
  wenKai,

  /// 霞鹜臻楷 GB。
  zhenKai;

  /// SharedPreferences 存储值。
  String get prefsValue => name;

  /// 是否使用嵌入 TrueType（否则用笔画路径字形）。
  bool get usesEmbeddedTtf => this != PracticeSheetFont.appDefault;

  /// Flutter [TextStyle.fontFamily]；[appDefault] 为 null（走笔画轮廓）。
  String? get familyName => switch (this) {
        PracticeSheetFont.appDefault => null,
        PracticeSheetFont.wenKai => 'LXGWWenKai',
        PracticeSheetFont.zhenKai => 'LXGWZhenKai',
      };

  /// Asset 路径（供 PDF 加载）；[appDefault] 为 null。
  String? get assetPath => switch (this) {
        PracticeSheetFont.appDefault => null,
        PracticeSheetFont.wenKai =>
          'assets/fonts/LXGWWenKaiGB-Regular.ttf',
        PracticeSheetFont.zhenKai =>
          'assets/fonts/LXGWZhenKaiGB-Regular.ttf',
      };

  static PracticeSheetFont fromPrefs(String? value) {
    if (value == PracticeSheetFont.wenKai.name) {
      return PracticeSheetFont.wenKai;
    }
    if (value == PracticeSheetFont.zhenKai.name) {
      return PracticeSheetFont.zhenKai;
    }
    return PracticeSheetFont.appDefault;
  }
}
