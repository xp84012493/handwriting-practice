import 'dart:ui' show Rect;
import 'package:vector_math/vector_math_64.dart' show Matrix4;

/// 描述笔画 SVG 路径所处的坐标约定，便于与不同数据源对齐。
enum StrokePathConvention {
  /// 常规 SVG：原点在左上，Y 向下增大（viewBox 通常为 0 0 W H）。
  svgTopLeftYDown,

  /// [Make Me a Hanzi](https://github.com/skishore/makemeahanzi) 的笔画坐标：
  /// 数据里 Y 轴向上递增，官方建议用 `scale(1,-1) translate(0,-900)` 包一层。
  /// 这里等价实现为 `translate(0,900)` + `scale(1,-1)`，再映射到你的目标矩形。
  makemeahanzi1024,
}

extension StrokePathConventionMatrix on StrokePathConvention {
  /// 将「数据源坐标」变换到 **Y 向下、左上角为原点** 的规范化画布。
  ///
  /// Make Me a Hanzi 等价于官方 SVG：`<g transform="scale(1,-1) translate(0,-900)">`
  /// 的矩阵组合，即 \(y' = 900 - y\)（在 1024 坐标系下）。
  Matrix4 dataToNormalizedSpace() {
    switch (this) {
      case StrokePathConvention.svgTopLeftYDown:
        return Matrix4.identity();
      case StrokePathConvention.makemeahanzi1024:
        return Matrix4.identity()
          ..translate(0.0, 900.0)
          ..scale(1.0, -1.0);
    }
  }

  /// 将规范化 viewBox（宽 [vbW] × 高 [vbH]）等比缩放并居中落入 [target]。
  Matrix4 normalizedViewBoxToRect(Rect target, double vbW, double vbH) {
    final sx = target.width / vbW;
    final sy = target.height / vbH;
    final s = sx < sy ? sx : sy;
    final dx = target.left + (target.width - vbW * s) / 2;
    final dy = target.top + (target.height - vbH * s) / 2;
    return Matrix4.identity()
      ..translate(dx, dy)
      ..scale(s, s);
  }
}
