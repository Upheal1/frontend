import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/onboarding_service.dart';
// ChartPreviewWidget + LimitPreviewWidget still live here.
import '../../widgets/onboarding/permission_step_widget.dart';

/// Onboarding flow for analytics / screen-time permissions.
///
/// Enhanced look & logic:
/// - Traveler character art (assets/onboarding/) as the hero of each page,
///   with a graceful icon fallback if an asset is missing.
/// - App design tokens (accent gradient + warm/dark backgrounds).
/// - Gradient CTA with a guarded grant action + loading state.
/// - Back navigation, tappable animated page indicator, haptics.
/// - Respects reduced-motion (MediaQuery.disableAnimations).
///
/// Logic preserved: still marks analytics onboarding complete via
/// OnboardingService.markAnalyticsOnboardingComplete() and fires onComplete /
/// onSkip exactly as before.
class AnalyticsPermissionOnboarding extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  const AnalyticsPermissionOnboarding({
    super.key,
    required this.onComplete,
    this.onSkip,
  });

  @override
  State<AnalyticsPermissionOnboarding> createState() =>
      _AnalyticsPermissionOnboardingState();
}

class _AnalyticsPermissionOnboardingState
    extends State<AnalyticsPermissionOnboarding> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isGranting = false;
  static const int _totalPages = 3;

  // ---- Brand tokens (mirror the app design system) ----
  static const Color _accentA = Color(0xFF5B7CFA);
  static const Color _accentB = Color(0xFF8A6CF6);
  static const Color _accentC = Color(0xFFB07BF5);
  static const List<Color> _accentGradient = <Color>[_accentA, _accentB, _accentC];

  // ---- Traveler art (drop your PNGs here; names can be changed) ----
  static const String _imgWave = 'assets/onboarding/traveler_wave.png';
  static const String _imgPoint = 'assets/onboarding/traveler_point.png';
  static const String _imgCelebrate = 'assets/onboarding/traveler_celebrate.png';

  late final AnimationController _backgroundController;
  late final Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );
    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion) {
      _backgroundController.stop();
      _backgroundController.value = 0.5;
    } else if (!_backgroundController.isAnimating) {
      _backgroundController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF1B1733);
  Color get _textSecondary =>
      _isDark ? const Color(0xFFA9A4C9) : const Color(0xFF5E5979);

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onSkip() {
    HapticFeedback.lightImpact();
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      widget.onComplete();
    }
  }

  Future<void> _onGrantPermission() async {
    if (_isGranting) return;
    setState(() => _isGranting = true);
    HapticFeedback.mediumImpact();
    try {
      await OnboardingService.markAnalyticsOnboardingComplete();
    } finally {
      if (mounted) setState(() => _isGranting = false);
    }
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          final double t = _backgroundAnimation.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? <Color>[
                        const Color(0xFF241A40),
                        Color.lerp(const Color(0xFF160F29),
                            const Color(0xFF0F0A1E), t)!,
                      ]
                    : <Color>[
                        const Color(0xFFFBFAFF),
                        Color.lerp(const Color(0xFFF2F0FB),
                            const Color(0xFFEFEDF9), t)!,
                      ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeader(isDark),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    HapticFeedback.selectionClick();
                    setState(() => _currentPage = page);
                  },
                  children: <Widget>[
                    _buildPage1(),
                    _buildPage2(),
                    _buildPage3(),
                  ],
                ),
              ),
              _buildBottomSection(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SizeTransition(
                    sizeFactor: anim,
                    axis: Axis.horizontal,
                    child: child,
                  ),
                ),
                child: _currentPage > 0
                    ? IconButton(
                        key: const ValueKey<String>('back'),
                        onPressed: _previousPage,
                        tooltip: 'Back',
                        icon: Icon(LucideIcons.arrowLeft,
                            size: 20, color: _textPrimary),
                      )
                    : const SizedBox(
                        key: ValueKey<String>('noback'), width: 4),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _accentGradient),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: _accentB.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.brain,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'UpHeal',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: _onSkip,
            child: Text(
              'Skip',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPage1() {
    return _buildTravelerPage(
      index: 0,
      image: _imgWave,
      fallbackIcon: LucideIcons.smartphone,
      accent: _accentB,
      title: 'Track Your Digital Wellbeing',
      description:
          'Understand how you spend time on your device and build healthier digital habits.',
      benefits: const <String>[
        'See your daily and weekly screen time',
        'Track which apps you use most',
        'Understand your usage patterns',
        'Spot areas to improve',
      ],
    );
  }

  Widget _buildPage2() {
    return _buildTravelerPage(
      index: 1,
      image: _imgPoint,
      fallbackIcon: LucideIcons.barChart2,
      accent: const Color(0xFF2E9E63),
      title: 'Understand Your Usage',
      description:
          'Visualize your app usage with beautiful charts and clear insights.',
      customContent: const ChartPreviewWidget(),
    );
  }

  Widget _buildPage3() {
    return _buildTravelerPage(
      index: 2,
      image: _imgCelebrate,
      fallbackIcon: LucideIcons.timer,
      accent: const Color(0xFFCF942A),
      title: 'Set Healthy Limits',
      description:
          'Set app time limits and get a gentle nudge before you reach them.',
      customContent: const LimitPreviewWidget(),
    );
  }

  /// A single onboarding page with the traveler art as the hero visual.
  Widget _buildTravelerPage({
    required int index,
    required String image,
    required IconData fallbackIcon,
    required Color accent,
    required String title,
    required String description,
    List<String>? benefits,
    Widget? customContent,
  }) {
    Widget hero = SizedBox(
      height: 220,
      child: Image.asset(
        image,
        fit: BoxFit.contain,
        // Graceful fallback: if the asset name/path doesn't match, show a
        // tinted icon badge instead of crashing.
        errorBuilder: (context, error, stackTrace) =>
            Center(child: _fallbackBadge(fallbackIcon, accent)),
      ),
    );
    if (!_reduceMotion) {
      // Gentle idle bob so the static art feels alive.
      hero = hero
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -6, duration: 2400.ms, curve: Curves.easeInOut);
    }

    final Widget content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          hero,
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: _textSecondary,
            ),
          ),
          if (benefits != null) ...<Widget>[
            const SizedBox(height: 24),
            ...benefits.map((b) => _benefitItem(b, accent)),
          ],
          if (customContent != null) ...<Widget>[
            const SizedBox(height: 24),
            customContent,
          ],
        ],
      ),
    );

    return content
        .animate(key: ValueKey<int>(index))
        .fadeIn(duration: 380.ms)
        .slideY(begin: 0.05, end: 0, duration: 380.ms, curve: Curves.easeOutCubic);
  }

  Widget _benefitItem(String text, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.check, size: 14, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackBadge(IconData icon, Color accent) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 60, color: accent),
    );
  }

  Widget _buildBottomSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildPageIndicator(isDark),
          const SizedBox(height: 28),
          _buildPrimaryButton(isDark),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _currentPage == _totalPages - 1
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      Platform.isAndroid
                          ? 'This opens Android settings to grant usage access'
                          : 'This requests Screen Time permission',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _textSecondary.withValues(alpha: 0.85),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildPageIndicator(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(_totalPages, (index) {
        final bool isActive = index == _currentPage;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _goToPage(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            width: isActive ? 26 : 8,
            height: 8,
            decoration: BoxDecoration(
              gradient:
                  isActive ? const LinearGradient(colors: _accentGradient) : null,
              color: isActive
                  ? null
                  : (isDark ? Colors.white24 : Colors.black12),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPrimaryButton(bool isDark) {
    final bool isLastPage = _currentPage == _totalPages - 1;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: _accentGradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _accentB.withValues(alpha: 0.40),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isGranting
                ? null
                : (isLastPage ? _onGrantPermission : _nextPage),
            child: Center(
              child: _isGranting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          isLastPage ? 'Grant Permission' : 'Next',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isLastPage
                              ? LucideIcons.shield
                              : LucideIcons.arrowRight,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen onboarding dialog wrapper
class AnalyticsOnboardingDialog extends StatelessWidget {
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  const AnalyticsOnboardingDialog({
    super.key,
    required this.onComplete,
    this.onSkip,
  });

  /// Show the onboarding as a full-screen dialog
  static Future<bool?> show(BuildContext context) {
    return Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return AnalyticsOnboardingDialog(
            onComplete: () {
              Navigator.of(context).pop(true);
            },
            onSkip: () {
              Navigator.of(context).pop(false);
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnalyticsPermissionOnboarding(
      onComplete: onComplete,
      onSkip: onSkip,
    );
  }
}
