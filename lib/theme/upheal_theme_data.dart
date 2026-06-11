import 'package:flutter/material.dart';

import '../design_system/tokens/app_gradients.dart';
import '../design_system/tokens/app_shadows.dart';
import '../features/steps/presentation/steps_theme.dart';
import '../shared/theme/upheal_home_theme.dart';

/// Builds the app's light & dark ThemeData with the grey Material surface gone.
class UpHealTheme {
  const UpHealTheme._();

  static ThemeData light() => _build(UpHealHomeTheme.light(), Brightness.light);
  static ThemeData dark() => _build(UpHealHomeTheme.dark(), Brightness.dark);

  static ThemeData _build(UpHealHomeTheme tokens, Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8A6CF6),
      brightness: brightness,
    ).copyWith(
      surface: tokens.pageBackground,
      surfaceTint: Colors.transparent,
    );

    final AppShadowTheme shadowTheme = AppShadowTheme.fromBrightness(brightness);
    final AppGradientTheme gradientTheme = AppGradientTheme.fromColorScheme(scheme);
    final StepsTheme stepsTheme = StepsTheme.fromBrightness(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.pageBackground,
      canvasColor: tokens.pageBackground,
      cardTheme: CardThemeData(
        color: tokens.cardFill,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
      ),
      extensions: <ThemeExtension<dynamic>>[
        tokens,
        shadowTheme,
        gradientTheme,
        stepsTheme,
      ],
    );
  }
}
