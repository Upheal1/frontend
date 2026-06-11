import 'package:flutter/material.dart';

class StepsTheme extends ThemeExtension<StepsTheme> {
  const StepsTheme({
    required this.ringTrackColor,
    required this.ringProgressColors,
    required this.ringGlowColor,
    required this.cardSurface,
    required this.cardSurfaceAlt,
    required this.textFaint,
    required this.textSoft,
    required this.accentPurple,
    required this.accentGreen,
    required this.accentOrange,
    required this.accentBlue,
    required this.avatarGradient,
    required this.ringGradient,
    required this.smartMessageGradient,
    required this.barColors,
    required this.barInactiveColor,
    required this.glassBackground,
    required this.glassBorder,
    required this.fabGradient,
  });

  final Color ringTrackColor;
  final List<Color> ringProgressColors;
  final Color ringGlowColor;
  final Color cardSurface;
  final Color cardSurfaceAlt;
  final Color textFaint;
  final Color textSoft;
  final Color accentPurple;
  final Color accentGreen;
  final Color accentOrange;
  final Color accentBlue;
  final LinearGradient avatarGradient;
  final Gradient ringGradient;
  final LinearGradient smartMessageGradient;
  final List<Color> barColors;
  final Color barInactiveColor;
  final Color glassBackground;
  final Color glassBorder;
  final LinearGradient fabGradient;

  factory StepsTheme.fromBrightness(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    return StepsTheme(
      ringTrackColor: isDark ? const Color(0xFF2A2D35) : const Color(0xFFE8EAF0),
      ringProgressColors: isDark
          ? [const Color(0xFFA78BFA), const Color(0xFF7C3AED), const Color(0xFF6D28D9)]
          : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
      ringGlowColor: isDark
          ? const Color(0xFF7C3AED).withValues(alpha: 0.35)
          : const Color(0xFF7C3AED).withValues(alpha: 0.20),
      cardSurface: isDark ? const Color(0xFF1C1F26) : const Color(0xFFFFFFFF),
      cardSurfaceAlt: isDark ? const Color(0xFF23262E) : const Color(0xFFF8F9FC),
      textFaint: isDark
          ? const Color(0xFFFFFFFF).withValues(alpha: 0.35)
          : const Color(0xFF0F172A).withValues(alpha: 0.35),
      textSoft: isDark
          ? const Color(0xFFFFFFFF).withValues(alpha: 0.60)
          : const Color(0xFF0F172A).withValues(alpha: 0.60),
      accentPurple: const Color(0xFF7C3AED),
      accentGreen: const Color(0xFF45D9A8),
      accentOrange: const Color(0xFFF97316),
      accentBlue: const Color(0xFF3B82F6),
      avatarGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
      ),
      ringGradient: const SweepGradient(
        startAngle: -1.5708,
        endAngle: 4.71239,
        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED), Color(0xFF6D28D9)],
        stops: [0.0, 0.5, 1.0],
      ),
      smartMessageGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF2D1B4E), const Color(0xFF1C1F26)]
            : [const Color(0xFFF5F0FF), const Color(0xFFFFFFFF)],
      ),
      barColors: [
        const Color(0xFFA78BFA),
        const Color(0xFF8B5CF6),
        const Color(0xFF7C3AED),
        const Color(0xFF6D28D9),
        const Color(0xFF5B21B6),
      ],
      barInactiveColor: isDark
          ? const Color(0xFF2A2D35)
          : const Color(0xFFE8EAF0),
      glassBackground: isDark
          ? const Color(0xFF1C1F26).withValues(alpha: 0.85)
          : const Color(0xFFFFFFFF).withValues(alpha: 0.82),
      glassBorder: isDark
          ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
          : const Color(0xFF0F172A).withValues(alpha: 0.08),
      fabGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
      ),
    );
  }

  @override
  StepsTheme copyWith({
    Color? ringTrackColor,
    List<Color>? ringProgressColors,
    Color? ringGlowColor,
    Color? cardSurface,
    Color? cardSurfaceAlt,
    Color? textFaint,
    Color? textSoft,
    Color? accentPurple,
    Color? accentGreen,
    Color? accentOrange,
    Color? accentBlue,
    LinearGradient? avatarGradient,
    Gradient? ringGradient,
    LinearGradient? smartMessageGradient,
    List<Color>? barColors,
    Color? barInactiveColor,
    Color? glassBackground,
    Color? glassBorder,
    LinearGradient? fabGradient,
  }) {
    return StepsTheme(
      ringTrackColor: ringTrackColor ?? this.ringTrackColor,
      ringProgressColors: ringProgressColors ?? this.ringProgressColors,
      ringGlowColor: ringGlowColor ?? this.ringGlowColor,
      cardSurface: cardSurface ?? this.cardSurface,
      cardSurfaceAlt: cardSurfaceAlt ?? this.cardSurfaceAlt,
      textFaint: textFaint ?? this.textFaint,
      textSoft: textSoft ?? this.textSoft,
      accentPurple: accentPurple ?? this.accentPurple,
      accentGreen: accentGreen ?? this.accentGreen,
      accentOrange: accentOrange ?? this.accentOrange,
      accentBlue: accentBlue ?? this.accentBlue,
      avatarGradient: avatarGradient ?? this.avatarGradient,
      ringGradient: ringGradient ?? this.ringGradient,
      smartMessageGradient: smartMessageGradient ?? this.smartMessageGradient,
      barColors: barColors ?? this.barColors,
      barInactiveColor: barInactiveColor ?? this.barInactiveColor,
      glassBackground: glassBackground ?? this.glassBackground,
      glassBorder: glassBorder ?? this.glassBorder,
      fabGradient: fabGradient ?? this.fabGradient,
    );
  }

  @override
  StepsTheme lerp(ThemeExtension<StepsTheme>? other, double t) {
    if (other is! StepsTheme) return this;
    return StepsTheme(
      ringTrackColor: Color.lerp(ringTrackColor, other.ringTrackColor, t)!,
      ringProgressColors: _lerpColorList(ringProgressColors, other.ringProgressColors, t),
      ringGlowColor: Color.lerp(ringGlowColor, other.ringGlowColor, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardSurfaceAlt: Color.lerp(cardSurfaceAlt, other.cardSurfaceAlt, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      textSoft: Color.lerp(textSoft, other.textSoft, t)!,
      accentPurple: Color.lerp(accentPurple, other.accentPurple, t)!,
      accentGreen: Color.lerp(accentGreen, other.accentGreen, t)!,
      accentOrange: Color.lerp(accentOrange, other.accentOrange, t)!,
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t)!,
      avatarGradient: avatarGradient,
      ringGradient: ringGradient,
      smartMessageGradient: smartMessageGradient,
      barColors: other.barColors,
      barInactiveColor: Color.lerp(barInactiveColor, other.barInactiveColor, t)!,
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      fabGradient: fabGradient,
    );
  }

  static List<Color> _lerpColorList(List<Color> a, List<Color> b, double t) {
    final length = a.length > b.length ? a.length : b.length;
    return List.generate(length, (i) {
      final ca = i < a.length ? a[i] : a.last;
      final cb = i < b.length ? b[i] : b.last;
      return Color.lerp(ca, cb, t)!;
    });
  }
}

extension StepsThemeX on ThemeData {
  StepsTheme get steps => extension<StepsTheme>()!;
}

extension StepsThemeContextX on BuildContext {
  StepsTheme get steps => Theme.of(this).extension<StepsTheme>()!;
}
