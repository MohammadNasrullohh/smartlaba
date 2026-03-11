// Add this file to your project: smartlaba/lib/unbounded_font.dart
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle unboundedMedium({Color? color, double? fontSize}) {
  return GoogleFonts.unbounded(
    fontWeight: FontWeight.w500,
    color: color,
    fontSize: fontSize,
  );
}
