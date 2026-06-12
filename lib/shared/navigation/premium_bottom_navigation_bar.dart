import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../navigation/app_routes.dart';
import '../theme/upheal_home_theme.dart';
import '../widgets/upheal_home_widgets.dart';

class PremiumBottomNavigationBar extends StatelessWidget {
  const PremiumBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onChatbotTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onChatbotTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final UpHealHomeTheme tokens = theme.upHealHome;
    final Color activeIcon = tokens.navActiveDark;
    final Color activeLabel = isDark ? tokens.navActiveDark : tokens.navActive;
    final Color inactive = tokens.navInactive;
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final List<AppBranchDestination> items = appBottomNavDestinations;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 6),
      child: SizedBox(
        height: 68,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GlassNav(
                child: SizedBox(
                  height: 48,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: _NavTab(
                          icon: items[0].icon,
                          label: 'Home',
                          isActive: currentIndex == 0,
                          activeColor: activeIcon,
                          activeLabelColor: activeLabel,
                          inactiveColor: inactive,
                          onTap: () => onTap(0),
                        ),
                      ),
                      Expanded(
                        child: _NavTab(
                          icon: items[1].icon,
                          label: 'Community',
                          isActive: currentIndex == 1,
                          activeColor: activeIcon,
                          activeLabelColor: activeLabel,
                          inactiveColor: inactive,
                          onTap: () => onTap(1),
                        ),
                      ),
                      const SizedBox(width: 52),
                      Expanded(
                        child: _NavTab(
                          icon: LucideIcons.map,
                          label: 'Roadmap',
                          isActive: currentIndex == 3,
                          activeColor: activeIcon,
                          activeLabelColor: activeLabel,
                          inactiveColor: inactive,
                          onTap: () => onTap(3),
                        ),
                      ),
                      Expanded(
                        child: _NavTab(
                          icon: items[4].icon,
                          label: 'Profile',
                          isActive: currentIndex == 4,
                          activeColor: activeIcon,
                          activeLabelColor: activeLabel,
                          inactiveColor: inactive,
                          onTap: () => onTap(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: _ChatbotActionButton(
                isActive: currentIndex == 2,
                onTap: onChatbotTap,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.16, end: 0),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.activeLabelColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color activeLabelColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isActive ? activeColor : inactiveColor;
    final Color labelColor = isActive ? activeLabelColor : inactiveColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: labelColor,
            letterSpacing: -0.1,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedScale(
                scale: isActive ? 1.02 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatbotActionButton extends StatelessWidget {
  const _ChatbotActionButton({
    required this.isActive,
    required this.onTap,
  });

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isActive ? 1.04 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tokens.chatFabFill,
            shape: BoxShape.circle,
            border: Border.all(color: tokens.pageBackground, width: 3),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            LucideIcons.sparkles,
            color: tokens.chatFabIcon,
            size: 16,
          ),
        ),
      ),
    );
  }
}
