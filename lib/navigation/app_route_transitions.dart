import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/tokens/design_tokens.dart';

class AppRouteTransitions {
  AppRouteTransitions._();

  static CustomTransitionPage<T> buildPage<T>({
    required GoRouterState state,
    required Widget child,
    bool fullscreenDialog = false,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      name: state.name,
      child: SafeArea(
        top: fullscreenDialog,
        bottom: fullscreenDialog,
        child: child,
      ),
      fullscreenDialog: fullscreenDialog,
      transitionDuration: AppMotion.fast,
      reverseTransitionDuration: AppMotion.medium,
      maintainState: true,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final Animation<double> fadeIn = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        final Animation<double> fadeOut = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInCubic,
          reverseCurve: Curves.easeOutCubic,
        );

        final Animation<Offset> slideIn = Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(fadeIn);

        final Animation<Offset> slideOut = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.02, 0),
        ).animate(fadeOut);

        if (secondaryAnimation.isDismissed) {
          return FadeTransition(
            opacity: fadeIn,
            child: SlideTransition(
              position: slideIn,
              child: child,
            ),
          );
        }

        return FadeTransition(
          opacity: ReverseAnimation(fadeOut),
          child: SlideTransition(
            position: slideOut,
            child: FadeTransition(
              opacity: fadeIn,
              child: SlideTransition(
                position: slideIn,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  static CustomTransitionPage<T> buildFadePage<T>({
    required GoRouterState state,
    required Widget child,
    Duration? transitionDuration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      name: state.name,
      child: SafeArea(child: child),
      transitionDuration: transitionDuration ?? AppMotion.medium,
      reverseTransitionDuration: AppMotion.medium,
      maintainState: true,
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        return FadeTransition(
          opacity: fade,
          child: child,
        );
      },
    );
  }

  static CustomTransitionPage<T> buildScalePage<T>({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      name: state.name,
      child: SafeArea(child: child),
      transitionDuration: AppMotion.medium,
      reverseTransitionDuration: AppMotion.medium,
      maintainState: true,
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final scale = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );

        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: scale,
            child: child,
          ),
        );
      },
    );
  }
}

class AppPageWrapper extends StatelessWidget {
  final Widget child;
  final bool showBackButton;
  final String? title;
  final Color? backgroundColor;

  const AppPageWrapper({
    super.key,
    required this.child,
    this.showBackButton = false,
    this.title,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: backgroundColor ??
          (isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFFFFF)),
      appBar: showBackButton && title != null
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(title!),
            )
          : null,
      body: child,
    );
  }
}