import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/theme_model.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModel>(
      builder: (context, themeModel, _) {
        final isDark = themeModel.isDarkMode;
        final disableAnim = MediaQuery.of(context).disableAnimations;
        const Duration d = Duration(milliseconds: 420);
        const Curve c = Curves.easeInOutCubic;
        final effectiveD = disableAnim ? Duration.zero : d;

        return Semantics(
          button: true,
          label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              themeModel.toggleTheme();
            },
            child: AnimatedContainer(
              duration: effectiveD,
              curve: c,
              width: 200,
              height: 46,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF34343A)
                    : const Color(0xFF8D8D93),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Stack(
                children: <Widget>[
                  // Moon icon — always on the left, 55% when inactive
                  Positioned(
                    left: 14,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        duration: effectiveD,
                        opacity: isDark ? 0.0 : 0.55,
                        child: const Icon(Icons.nightlight_round,
                            size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                  // Sun icon — always on the right, 55% when inactive
                  Positioned(
                    right: 14,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        duration: effectiveD,
                        opacity: isDark ? 0.55 : 0.0,
                        child: const Icon(Icons.wb_sunny_rounded,
                            size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                  // Sliding thumb — 38x38 radius 12
                  AnimatedPositioned(
                    duration: effectiveD,
                    curve: c,
                    left: isDark ? 4 : 62,
                    top: 4,
                    bottom: 4,
                    width: 38,
                    child: AnimatedContainer(
                      duration: effectiveD,
                      curve: c,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1D1D22)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.5 : 0.22),
                            blurRadius: isDark ? 8 : 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: effectiveD,
                        switchInCurve: c,
                        switchOutCurve: c,
                        transitionBuilder:
                            (Widget child, Animation<double> a) {
                          if (disableAnim) return child;
                          return RotationTransition(
                            turns: Tween<double>(begin: 0.6, end: 1.0)
                                .animate(a),
                            child: FadeTransition(
                                opacity: a, child: child),
                          );
                        },
                        child: isDark
                            ? const Icon(Icons.nightlight_round,
                                key: ValueKey<String>('moon'),
                                size: 22,
                                color: Color(0xFFCFCFD6))
                            : const Icon(Icons.wb_sunny_rounded,
                                key: ValueKey<String>('sun'),
                                size: 22,
                                color: Color(0xFF3A3A40)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
