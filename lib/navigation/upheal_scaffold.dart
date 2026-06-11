import 'package:flutter/material.dart';

import 'app_navigation_keys.dart';
import '../shared/navigation/premium_bottom_navigation_bar.dart';
import '../shared/theme/upheal_home_theme.dart';

class UpHealScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFab;
  final Widget? drawer;
  final bool hideNav;

  const UpHealScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTap,
    required this.onFab,
    this.drawer,
    this.hideNav = false,
  });

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;

    return Scaffold(
      key: rootScaffoldKey,
      extendBody: true,
      backgroundColor: Colors.transparent,
      drawer: drawer,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: tokens.pageGradient),
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: body,
        ),
      ),
      bottomNavigationBar: hideNav
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _Nav(
                index: currentIndex,
                onTap: onTap,
                onFab: onFab,
              ),
            ),
    );
  }
}

class _Nav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onFab;

  const _Nav({
    required this.index,
    required this.onTap,
    required this.onFab,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumBottomNavigationBar(
      currentIndex: index,
      onTap: onTap,
      onChatbotTap: onFab,
    );
  }
}
