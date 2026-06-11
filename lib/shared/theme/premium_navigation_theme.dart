import 'package:flutter/material.dart';

class PremiumNavigationTheme {
  PremiumNavigationTheme._();

  static const Color navSurface = Colors.white;
  static const Color navActive = Color(0xFF111111);
  static const Color navInactive = Color(0xFF9CA3AF);
  static const Color navBorder = Color(0x12000000);
  static const Color chatbotSurface = Color(0xFF111111);
  static const Color drawerSurface = Color(0xFFFFFFFF);
  static const Color drawerSectionText = Color(0xFF6B7280);
  static const Color drawerDivider = Color(0x12000000);

  static const List<BoxShadow> navShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> chatbotShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
