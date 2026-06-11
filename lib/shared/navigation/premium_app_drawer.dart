import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../constants/app_colors.dart';
import '../../navigation/app_routes.dart';
import '../theme/premium_navigation_theme.dart';

class PremiumAppDrawer extends StatelessWidget {
  const PremiumAppDrawer({
    super.key,
    required this.location,
    required this.currentIndex,
    required this.onBranchSelected,
    required this.onRouteSelected,
    this.onLogout,
    this.showCompactHeader = false,
  });

  final String location;
  final int currentIndex;
  final ValueChanged<int> onBranchSelected;
  final ValueChanged<AppRouteData> onRouteSelected;
  final VoidCallback? onLogout;
  final bool showCompactHeader;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color drawerSurface = isDark ? const Color(0xFF17171B) : PremiumNavigationTheme.drawerSurface;
    final Color titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final Color mutedColor = isDark ? Colors.white60 : PremiumNavigationTheme.drawerSectionText;

    return Drawer(
      backgroundColor: drawerSurface,
      child: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: isDark ? const Color(0xFF25252B) : const Color(0xFFF5F5F7),
                      ),
                      child: const Icon(LucideIcons.sparkles, color: AppColors.purple, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'UpHeal',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                          Text(
                            showCompactHeader ? 'Navigate your workspace' : 'Mental wellness workspace',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...appDrawerSections.map((AppDrawerSection section) {
              return SliverToBoxAdapter(
                child: _DrawerSection(
                  section: section,
                  location: location,
                  currentIndex: currentIndex,
                  onBranchSelected: onBranchSelected,
                  onRouteSelected: onRouteSelected,
                ),
              );
            }),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  children: <Widget>[
                    Divider(color: PremiumNavigationTheme.drawerDivider),
                    const SizedBox(height: 8),
                    _DrawerActionTile(
                      icon: LucideIcons.logOut,
                      label: 'Logout',
                      isSelected: false,
                      onTap: onLogout,
                      destructive: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({
    required this.section,
    required this.location,
    required this.currentIndex,
    required this.onBranchSelected,
    required this.onRouteSelected,
  });

  final AppDrawerSection section;
  final String location;
  final int currentIndex;
  final ValueChanged<int> onBranchSelected;
  final ValueChanged<AppRouteData> onRouteSelected;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color headerColor = isDark ? Colors.white54 : PremiumNavigationTheme.drawerSectionText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Text(
              section.title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: headerColor,
              ),
            ),
          ),
          ...section.items.map((AppDrawerDestination item) {
            final int primaryIndex = appBottomNavDestinations.indexWhere(
              (AppBranchDestination branch) => branch.route.location == item.route.location,
            );
            final bool isPrimary = primaryIndex != -1;
            final bool isSelected = isPrimary
                ? currentIndex == primaryIndex
                : location == item.route.location || location.startsWith('${item.route.location}/');

            return _DrawerActionTile(
              icon: item.icon,
              label: item.label,
              isSelected: isSelected,
              onTap: () {
                if (isPrimary) {
                  onBranchSelected(primaryIndex);
                } else {
                  onRouteSelected(item.route);
                }
              },
            );
          }),
        ],
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  const _DrawerActionTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activeBg = isDark ? const Color(0xFF24242A) : const Color(0xFFF5F5F7);
    final Color activeFg = destructive ? const Color(0xFFD92D20) : const Color(0xFF111111);
    final Color inactiveFg = destructive
        ? const Color(0xFFD92D20)
        : (isDark ? Colors.white.withValues(alpha: 0.86) : const Color(0xFF374151));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 18, color: isSelected ? activeFg : inactiveFg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? activeFg : inactiveFg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
