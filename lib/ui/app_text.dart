import 'package:flutter/painting.dart';

class AppText {
  const AppText._();

  static const String fontFamily = 'NotoSansKR';

  static TextStyle style({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      shadows: shadows,
    );
  }
}
