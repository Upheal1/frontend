import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CustomNavItem> items;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _previousIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(CustomBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _previousIndex) {
      _animController.forward(from: 0);
      _previousIndex = widget.currentIndex;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int get _centerIndex => widget.items.length >> 1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color fillColor = isDark
        ? const Color(0xFF1E1838).withValues(alpha: 0.62)
        : Colors.white.withValues(alpha: 0.82);

    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0x0D14102C);

    final List<BoxShadow> shadows = isDark
        ? [
            BoxShadow(
              color: const Color(0xA6000000),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0x664632A0),
              blurRadius: 34,
              offset: const Offset(0, 14),
            ),
          ];

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: borderColor),
                boxShadow: shadows,
              ),
              child: Row(
                children: [
                  for (int i = 0; i < widget.items.length; i++)
                    if (i == _centerIndex)
                      const SizedBox(width: 64)
                    else
                      Expanded(
                        child: _NavTab(
                          icon: widget.items[i].icon,
                          label: widget.items[i].label,
                          isSelected: widget.currentIndex == i,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onTap(i);
                          },
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -29,
          child: _CenterFab(
            isSelected: widget.currentIndex == _centerIndex,
            isDark: isDark,
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onTap(_centerIndex);
            },
          ),
        ),
      ],
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  static const Color _accent = Color(0xFF8A6CF6);
  static const Color _inactiveDark = Color(0xFF7D789C);
  static const Color _inactiveLight = Color(0xFF9A96B3);

  @override
  Widget build(BuildContext context) {
    final Color itemColor = isSelected
        ? _accent
        : isDark
            ? _inactiveDark
            : _inactiveLight;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: child,
              ),
              child: Icon(
                icon,
                key: ValueKey('${isSelected}_${icon.hashCode}'),
                color: itemColor,
                size: 23,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: itemColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CenterFab({
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  static const Color _pageBgDark = Color(0xFF160F29);
  static const Color _pageBgLight = Color(0xFFECECF6);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        width: isSelected ? 62 : 58,
        height: isSelected ? 62 : 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? _pageBgDark : _pageBgLight,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xD97B5AF5),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5B7CFA), Color(0xFF8A6CF6), Color(0xFFB07BF5)],
          ),
        ),
        child: AnimatedScale(
          scale: isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: const Icon(
            LucideIcons.sparkles,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class CustomNavItem {
  final IconData icon;
  final String label;

  const CustomNavItem({
    required this.icon,
    required this.label,
  });
}
