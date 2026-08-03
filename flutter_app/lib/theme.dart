// Design tokens ported from the PWA (app/assets/css/main.css). The names
// mirror the CSS variables so both UIs stay visually in sync.
import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color ink, paper, card, line, muted, gold, goldInk, red, green;
  final Color greenSoft, redSoft, bandBlack, cdBg, cdFg;
  final Color? cdBorder;

  const AppColors({
    required this.ink,
    required this.paper,
    required this.card,
    required this.line,
    required this.muted,
    required this.gold,
    required this.goldInk,
    required this.red,
    required this.green,
    required this.greenSoft,
    required this.redSoft,
    required this.bandBlack,
    required this.cdBg,
    required this.cdFg,
    this.cdBorder,
  });

  static const light = AppColors(
    ink: Color(0xFF1A1A1F),
    paper: Color(0xFFFAFAF7),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE6E4DD),
    muted: Color(0xFF5B5B66),
    gold: Color(0xFFFFCC00),
    goldInk: Color(0xFF1A1A1F),
    red: Color(0xFFDD3A2A),
    green: Color(0xFF2E7D46),
    greenSoft: Color(0xFFE3F0E7),
    redSoft: Color(0xFFFBE9E6),
    bandBlack: Color(0xFF1A1A1F),
    cdBg: Color(0xFF1A1A1F),
    cdFg: Color(0xFFFAFAF7),
  );

  static const dark = AppColors(
    ink: Color(0xFFF2F0EA),
    paper: Color(0xFF141418),
    card: Color(0xFF1E1E24),
    line: Color(0xFF32323A),
    muted: Color(0xFFA5A5B0),
    gold: Color(0xFFFFCC00),
    goldInk: Color(0xFF1A1A1F),
    red: Color(0xFFDD3A2A),
    green: Color(0xFF2E7D46),
    greenSoft: Color(0xFF1E3226),
    redSoft: Color(0xFF3A201C),
    bandBlack: Color(0xFF4A4A55),
    cdBg: Color(0xFF1E1E24),
    cdFg: Color(0xFFF2F0EA),
    cdBorder: Color(0xFF32323A),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

const double kRadiusApp = 14;

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final base = ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: c.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.gold,
      brightness: brightness,
      surface: c.paper,
    ),
    fontFamily: null, // platform default, like the PWA's system font stack
    splashFactory: InkSparkle.splashFactory,
  );
  return base.copyWith(
    extensions: [c],
    textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink),
    dividerColor: c.line,
  );
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
