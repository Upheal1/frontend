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
        const Duration d = Duration(milliseconds: 420);
        const Curve c = Curves.easeInOutCubic;

        return Semantics(
          button: true,
          label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              themeModel.toggleTheme();
            },
            child: AnimatedContainer(
              duration: d,
              curve: c,
              width: 104,
              height: 46,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF34343A) : const Color(0xFF8D8D93),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Stack(
                children: <Widget>[
                  AnimatedAlign(
                    duration: d,
                    curve: c,
                    alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: AnimatedContainer(
                        duration: d,
                        curve: c,
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1D1D22) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.22),
                              blurRadius: isDark ? 8 : 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: d,
                          switchInCurve: c,
                          switchOutCurve: c,
                          transitionBuilder: (Widget child, Animation<double> a) {
                            return RotationTransition(
                              turns: Tween<double>(begin: 0.6, end: 1.0).animate(a),
                              child: FadeTransition(opacity: a, child: child),
                            );
                          },
                          child: isDark
                              ? const Icon(Icons.nightlight_round,
                                  key: ValueKey<String>('moon'),
                                  size: 22, color: Color(0xFFCFCFD6))
                              : const Icon(Icons.wb_sunny_rounded,
                                  key: ValueKey<String>('sun'),
                                  size: 22, color: Color(0xFF3A3A40)),
                        ),
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
