import 'dart:ui';

import 'package:flutter/material.dart';

class UpHealHomeTheme extends ThemeExtension<UpHealHomeTheme> {
  const UpHealHomeTheme({
    required this.pageGradient,
    required this.accentGradient,
    required this.primaryText,
    required this.secondaryText,
    required this.faintText,
    required this.cardFill,
    required this.cardBorder,
    required this.cardShadow,
    required this.trackColor,
    required this.dividerColor,
    required this.glowColor,
    required this.quickJournal,
    required this.quickCoach,
    required this.quickInsights,
    required this.quickGroups,
    required this.navFill,
    required this.navBorder,
    required this.navShadow,
    required this.navActive,
    required this.navActiveDark,
    required this.navInactive,
    required this.chatFabFill,
    required this.chatFabIcon,
    required this.pageBackground,
    required this.cardRadius,
    required this.tileRadius,
    required this.pillRadius,
    required this.screenPadding,
    required this.space8,
    required this.space12,
    required this.space16,
    required this.space20,
    required this.quickJournalChip,
    required this.quickCoachChip,
    required this.quickInsightsChip,
    required this.quickGroupsChip,
    required this.quickJournalIcon,
    required this.quickCoachIcon,
    required this.quickInsightsIcon,
    required this.quickGroupsIcon,
    required this.quickJournalLabel,
    required this.quickCoachLabel,
    required this.quickInsightsLabel,
    required this.quickGroupsLabel,
  });

  final Gradient pageGradient;
  final LinearGradient accentGradient;
  final Color primaryText;
  final Color secondaryText;
  final Color faintText;
  final Color cardFill;
  final Color cardBorder;
  final BoxShadow? cardShadow;
  final Color trackColor;
  final Color dividerColor;
  final Color glowColor;
  final Color quickJournal;
  final Color quickCoach;
  final Color quickInsights;
  final Color quickGroups;
  final Color navFill;
  final Color navBorder;
  final List<BoxShadow> navShadow;
  final Color navActive;
  final Color navActiveDark;
  final Color navInactive;
  final Color chatFabFill;
  final Color chatFabIcon;
  final Color pageBackground;
  final double cardRadius;
  final double tileRadius;
  final double pillRadius;
  final double screenPadding;
  final double space8;
  final double space12;
  final double space16;
  final double space20;
  // Quick-tile chip / icon / label tokens
  final Color quickJournalChip;
  final Color quickCoachChip;
  final Color quickInsightsChip;
  final Color quickGroupsChip;
  final Color quickJournalIcon;
  final Color quickCoachIcon;
  final Color quickInsightsIcon;
  final Color quickGroupsIcon;
  final Color quickJournalLabel;
  final Color quickCoachLabel;
  final Color quickInsightsLabel;
  final Color quickGroupsLabel;

  static const LinearGradient sharedAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF5B7CFA),
      Color(0xFF8A6CF6),
      Color(0xFFB07BF5),
    ],
  );

  static UpHealHomeTheme dark() {
    return const UpHealHomeTheme(
      pageGradient: RadialGradient(
        center: Alignment(0, -1),
        radius: 1.2,
        colors: <Color>[
          Color(0xFF241A40),
          Color(0xFF160F29),
          Color(0xFF0F0A1E),
        ],
        stops: <double>[0, 0.55, 1],
      ),
      accentGradient: sharedAccentGradient,
      primaryText: Color(0xFFFFFFFF),
      secondaryText: Color(0xFFA9A4C9),
      faintText: Color(0xFF7D789C),
      cardFill: Color(0x0EFFFFFF),
      cardBorder: Color(0x17FFFFFF),
      cardShadow: null,
      trackColor: Color(0x1FFFFFFF),
      dividerColor: Color(0x17FFFFFF),
      glowColor: Color(0x668A6CF6),
      quickJournal: Color(0x1A6BCB8E),
      quickCoach: Color(0x1A5B7CFA),
      quickInsights: Color(0x1AF2B55D),
      quickGroups: Color(0x1A8A6CF6),
      navFill: Color(0xB31E1838),
      navBorder: Color(0x1AFFFFFF),
      navShadow: <BoxShadow>[
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
      navActive: Color(0xFF8A6CF6),
      navActiveDark: Color(0xFFCDBCFF),
      navInactive: Color(0xFF7D789C),
      chatFabFill: Color(0xFFFFFFFF),
      chatFabIcon: Color(0xFF111111),
      pageBackground: Color(0xFF0F0A1E),
      cardRadius: 26,
      tileRadius: 18,
      pillRadius: 999,
      screenPadding: 20,
      space8: 8,
      space12: 12,
      space16: 16,
      space20: 20,
      quickJournalChip: Color(0x266BCB8E),
      quickCoachChip: Color(0x265B7CFA),
      quickInsightsChip: Color(0x26F2B55D),
      quickGroupsChip: Color(0x268A6CF6),
      quickJournalIcon: Color(0xFF6BCB8E),
      quickCoachIcon: Color(0xFF5B7CFA),
      quickInsightsIcon: Color(0xFFF2B55D),
      quickGroupsIcon: Color(0xFF8A6CF6),
      quickJournalLabel: Color(0xFF6BCB8E),
      quickCoachLabel: Color(0xFF5B7CFA),
      quickInsightsLabel: Color(0xFFF2B55D),
      quickGroupsLabel: Color(0xFF8A6CF6),
    );
  }

  static UpHealHomeTheme light() {
    return const UpHealHomeTheme(
      pageGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFFFBFAFF),
          Color(0xFFF2F0FB),
          Color(0xFFEFEDF9),
        ],
        stops: <double>[0, 0.6, 1],
      ),
      accentGradient: sharedAccentGradient,
      primaryText: Color(0xFF1B1733),
      secondaryText: Color(0xFF5E5979),
      faintText: Color(0xFF9A96B3),
      cardFill: Color(0xFFFFFFFF),
      cardBorder: Color(0x0A141032),
      cardShadow: BoxShadow(
        color: Color(0x2E785ADC),
        blurRadius: 30,
        offset: Offset(0, 14),
        spreadRadius: -16,
      ),
      trackColor: Color(0x140F1032),
      dividerColor: Color(0x120F1032),
      glowColor: Color(0x408A6CF6),
      quickJournal: Color(0xFFE6F6EC),
      quickCoach: Color(0xFFE6F0FE),
      quickInsights: Color(0xFFFCEFD6),
      quickGroups: Color(0xFFF0E8FD),
      navFill: Color(0xF5FFFFFF),
      navBorder: Color(0x0D141032),
      navShadow: <BoxShadow>[
        BoxShadow(
          color: Color(0x66503CA0),
          blurRadius: 34,
          offset: Offset(0, 16),
          spreadRadius: -14,
        ),
      ],
      navActive: Color(0xFF1B1733),
      navActiveDark: Color(0xFF8A5CF0),
      navInactive: Color(0xFF9A96B3),
      chatFabFill: Color(0xFF161616),
      chatFabIcon: Color(0xFFFFFFFF),
      pageBackground: Color(0xFFEFEDF9),
      cardRadius: 24,
      tileRadius: 18,
      pillRadius: 999,
      screenPadding: 20,
      space8: 8,
      space12: 12,
      space16: 16,
      space20: 20,
      quickJournalChip: Color(0xFFCDECD8),
      quickCoachChip: Color(0xFFD2E4FD),
      quickInsightsChip: Color(0xFFFAE3BC),
      quickGroupsChip: Color(0xFFE2D2FB),
      quickJournalIcon: Color(0xFF2E9E63),
      quickCoachIcon: Color(0xFF3F7CE0),
      quickInsightsIcon: Color(0xFFCF942A),
      quickGroupsIcon: Color(0xFF8A5CF0),
      quickJournalLabel: Color(0xFF1F7A4B),
      quickCoachLabel: Color(0xFF2F63C4),
      quickInsightsLabel: Color(0xFFA9761C),
      quickGroupsLabel: Color(0xFF6E44C9),
    );
  }

  @override
  UpHealHomeTheme copyWith({
    Gradient? pageGradient,
    LinearGradient? accentGradient,
    Color? primaryText,
    Color? secondaryText,
    Color? faintText,
    Color? cardFill,
    Color? cardBorder,
    BoxShadow? cardShadow,
    Color? trackColor,
    Color? dividerColor,
    Color? glowColor,
    Color? quickJournal,
    Color? quickCoach,
    Color? quickInsights,
    Color? quickGroups,
    Color? navFill,
    Color? navBorder,
    List<BoxShadow>? navShadow,
    Color? navActive,
    Color? navActiveDark,
    Color? navInactive,
    Color? chatFabFill,
    Color? chatFabIcon,
    Color? pageBackground,
    double? cardRadius,
    double? tileRadius,
    double? pillRadius,
    double? screenPadding,
    double? space8,
    double? space12,
    double? space16,
    double? space20,
    Color? quickJournalChip,
    Color? quickCoachChip,
    Color? quickInsightsChip,
    Color? quickGroupsChip,
    Color? quickJournalIcon,
    Color? quickCoachIcon,
    Color? quickInsightsIcon,
    Color? quickGroupsIcon,
    Color? quickJournalLabel,
    Color? quickCoachLabel,
    Color? quickInsightsLabel,
    Color? quickGroupsLabel,
  }) {
    return UpHealHomeTheme(
      pageGradient: pageGradient ?? this.pageGradient,
      accentGradient: accentGradient ?? this.accentGradient,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      faintText: faintText ?? this.faintText,
      cardFill: cardFill ?? this.cardFill,
      cardBorder: cardBorder ?? this.cardBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      trackColor: trackColor ?? this.trackColor,
      dividerColor: dividerColor ?? this.dividerColor,
      glowColor: glowColor ?? this.glowColor,
      quickJournal: quickJournal ?? this.quickJournal,
      quickCoach: quickCoach ?? this.quickCoach,
      quickInsights: quickInsights ?? this.quickInsights,
      quickGroups: quickGroups ?? this.quickGroups,
      navFill: navFill ?? this.navFill,
      navBorder: navBorder ?? this.navBorder,
      navShadow: navShadow ?? this.navShadow,
      navActive: navActive ?? this.navActive,
      navActiveDark: navActiveDark ?? this.navActiveDark,
      navInactive: navInactive ?? this.navInactive,
      chatFabFill: chatFabFill ?? this.chatFabFill,
      chatFabIcon: chatFabIcon ?? this.chatFabIcon,
      pageBackground: pageBackground ?? this.pageBackground,
      cardRadius: cardRadius ?? this.cardRadius,
      tileRadius: tileRadius ?? this.tileRadius,
      pillRadius: pillRadius ?? this.pillRadius,
      screenPadding: screenPadding ?? this.screenPadding,
      space8: space8 ?? this.space8,
      space12: space12 ?? this.space12,
      space16: space16 ?? this.space16,
      space20: space20 ?? this.space20,
      quickJournalChip: quickJournalChip ?? this.quickJournalChip,
      quickCoachChip: quickCoachChip ?? this.quickCoachChip,
      quickInsightsChip: quickInsightsChip ?? this.quickInsightsChip,
      quickGroupsChip: quickGroupsChip ?? this.quickGroupsChip,
      quickJournalIcon: quickJournalIcon ?? this.quickJournalIcon,
      quickCoachIcon: quickCoachIcon ?? this.quickCoachIcon,
      quickInsightsIcon: quickInsightsIcon ?? this.quickInsightsIcon,
      quickGroupsIcon: quickGroupsIcon ?? this.quickGroupsIcon,
      quickJournalLabel: quickJournalLabel ?? this.quickJournalLabel,
      quickCoachLabel: quickCoachLabel ?? this.quickCoachLabel,
      quickInsightsLabel: quickInsightsLabel ?? this.quickInsightsLabel,
      quickGroupsLabel: quickGroupsLabel ?? this.quickGroupsLabel,
    );
  }

  @override
  UpHealHomeTheme lerp(ThemeExtension<UpHealHomeTheme>? other, double t) {
    if (other is! UpHealHomeTheme) {
      return this;
    }

    return UpHealHomeTheme(
      pageGradient: t < 0.5 ? pageGradient : other.pageGradient,
      accentGradient: t < 0.5 ? accentGradient : other.accentGradient,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      faintText: Color.lerp(faintText, other.faintText, t)!,
      cardFill: Color.lerp(cardFill, other.cardFill, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      trackColor: Color.lerp(trackColor, other.trackColor, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      glowColor: Color.lerp(glowColor, other.glowColor, t)!,
      quickJournal: Color.lerp(quickJournal, other.quickJournal, t)!,
      quickCoach: Color.lerp(quickCoach, other.quickCoach, t)!,
      quickInsights: Color.lerp(quickInsights, other.quickInsights, t)!,
      quickGroups: Color.lerp(quickGroups, other.quickGroups, t)!,
      navFill: Color.lerp(navFill, other.navFill, t)!,
      navBorder: Color.lerp(navBorder, other.navBorder, t)!,
      navShadow: t < 0.5 ? navShadow : other.navShadow,
      navActive: Color.lerp(navActive, other.navActive, t)!,
      navActiveDark: Color.lerp(navActiveDark, other.navActiveDark, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      chatFabFill: Color.lerp(chatFabFill, other.chatFabFill, t)!,
      chatFabIcon: Color.lerp(chatFabIcon, other.chatFabIcon, t)!,
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      tileRadius: lerpDouble(tileRadius, other.tileRadius, t)!,
      pillRadius: lerpDouble(pillRadius, other.pillRadius, t)!,
      screenPadding: lerpDouble(screenPadding, other.screenPadding, t)!,
      space8: lerpDouble(space8, other.space8, t)!,
      space12: lerpDouble(space12, other.space12, t)!,
      space16: lerpDouble(space16, other.space16, t)!,
      space20: lerpDouble(space20, other.space20, t)!,
      quickJournalChip: Color.lerp(quickJournalChip, other.quickJournalChip, t)!,
      quickCoachChip: Color.lerp(quickCoachChip, other.quickCoachChip, t)!,
      quickInsightsChip: Color.lerp(quickInsightsChip, other.quickInsightsChip, t)!,
      quickGroupsChip: Color.lerp(quickGroupsChip, other.quickGroupsChip, t)!,
      quickJournalIcon: Color.lerp(quickJournalIcon, other.quickJournalIcon, t)!,
      quickCoachIcon: Color.lerp(quickCoachIcon, other.quickCoachIcon, t)!,
      quickInsightsIcon: Color.lerp(quickInsightsIcon, other.quickInsightsIcon, t)!,
      quickGroupsIcon: Color.lerp(quickGroupsIcon, other.quickGroupsIcon, t)!,
      quickJournalLabel: Color.lerp(quickJournalLabel, other.quickJournalLabel, t)!,
      quickCoachLabel: Color.lerp(quickCoachLabel, other.quickCoachLabel, t)!,
      quickInsightsLabel: Color.lerp(quickInsightsLabel, other.quickInsightsLabel, t)!,
      quickGroupsLabel: Color.lerp(quickGroupsLabel, other.quickGroupsLabel, t)!,
    );
  }
}

extension UpHealHomeThemeX on ThemeData {
  UpHealHomeTheme get upHealHome => extension<UpHealHomeTheme>()!;
}