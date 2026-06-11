import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/upheal_home_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(radius ?? tokens.cardRadius),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow == null
            ? const <BoxShadow>[]
            : <BoxShadow>[tokens.cardShadow!],
      ),
      child: child,
    );
  }
}

class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.label,
    required this.value,
    this.gradientValue = false,
    this.alignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final bool gradientValue;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space12,
        vertical: tokens.space12,
      ),
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(tokens.tileRadius),
        border: Border.all(color: tokens.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: tokens.faintText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: tokens.space8),
          if (gradientValue)
            GradientValueText(value: value)
          else
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.primaryText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.title,
    required this.duration,
    required this.reward,
    required this.completed,
    required this.onTap,
  });

  final String title;
  final String duration;
  final String reward;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.tileRadius),
        child: Container(
          padding: EdgeInsets.all(tokens.space16),
          decoration: BoxDecoration(
            color: tokens.cardFill,
            borderRadius: BorderRadius.circular(tokens.tileRadius),
            border: Border.all(color: tokens.dividerColor),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: completed ? Colors.transparent : tokens.faintText,
                    width: 1.8,
                  ),
                  gradient: completed ? tokens.accentGradient : null,
                ),
                child: completed
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              SizedBox(width: tokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration:
                            completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    SizedBox(height: tokens.space8 / 2),
                    Text(
                      duration,
                      style: TextStyle(
                        color: tokens.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: tokens.space12),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.space12,
                  vertical: tokens.space8,
                ),
                decoration: BoxDecoration(
                  gradient: tokens.accentGradient,
                  borderRadius: BorderRadius.circular(tokens.pillRadius),
                ),
                child: Text(
                  reward,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickTile extends StatelessWidget {
  const QuickTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.tileRadius),
        child: Container(
          padding: EdgeInsets.all(tokens.space16),
          decoration: BoxDecoration(
            color: isDark ? tokens.cardFill : color,
            borderRadius: BorderRadius.circular(tokens.tileRadius),
            border: Border.all(color: tokens.dividerColor),
            boxShadow: isDark || tokens.cardShadow == null
                ? const <BoxShadow>[]
                : <BoxShadow>[tokens.cardShadow!],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? color.withValues(alpha: 0.18) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: isDark ? color : tokens.primaryText),
              ),
              Text(
                title,
                style: TextStyle(
                  color: tokens.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GradientBanner extends StatelessWidget {
  const GradientBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        child: Container(
          padding: EdgeInsets.all(tokens.space20),
          decoration: BoxDecoration(
            gradient: tokens.accentGradient,
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: tokens.glowColor,
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              SizedBox(width: tokens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GradientValueText extends StatelessWidget {
  const GradientValueText({
    super.key,
    required this.value,
    this.fontSize = 15,
  });

  final String value;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;

    return ShaderMask(
      shaderCallback: (Rect bounds) => tokens.accentGradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Wrap any page body to paint the gradient + keep Scaffold transparent.
class UpHealPageBackground extends StatelessWidget {
  const UpHealPageBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: tokens.pageGradient),
      child: child,
    );
  }
}

/// Drop-in Scaffold replacement: warm gradient edge-to-edge, transparent
/// Scaffold (no grey), body extended behind the nav.
class UpHealScaffold extends StatelessWidget {
  const UpHealScaffold({
    super.key,
    required this.body,
    this.bottomNav,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  final Widget body;
  final Widget? bottomNav;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: tokens.pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: body,
        bottomNavigationBar: bottomNav,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      ),
    );
  }
}

class GlassNav extends StatelessWidget {
  const GlassNav({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final UpHealHomeTheme tokens = Theme.of(context).upHealHome;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.navFill,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: tokens.navBorder),
            boxShadow: tokens.navShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}