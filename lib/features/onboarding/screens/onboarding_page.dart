import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/onboarding_data.dart';
import '../widgets/onboarding_widgets.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;
  final int pageIndex;

  const OnboardingPage({
    super.key,
    required this.data,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget hero = SizedBox(
      height: 220,
      child: Image.asset(
        data.travelerImage,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Center(
          child: OnboardingVisual(
            type: data.type,
            heroTag: data.heroTag,
            gradientColors: data.gradientColors,
          ),
        ),
      ),
    );
    if (!reduceMotion) {
      hero = hero
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -6, duration: 2400.ms, curve: Curves.easeInOut);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: data.gradientColors,
        ),
      ),
      child: Stack(
        children: [
          const ParticlesBackground(
            particleCount: 12,
            particleColors: [
              Color(0xFF8B5CF6),
              Color(0xFF6366F1),
              Color(0xFFEC4899),
              Color(0xFF06B6D4),
              Color(0xFFA855F7),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.06),
                  hero
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .scale(begin: const Offset(0.8, 0.8), duration: 600.ms, delay: 200.ms),
                  SizedBox(height: screenHeight * 0.04),
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 400.ms)
                      .slideY(begin: 0.3, duration: 500.ms, delay: 400.ms),
                  const SizedBox(height: 16),
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 550.ms)
                      .slideY(begin: 0.3, duration: 500.ms, delay: 550.ms),
                  SizedBox(height: screenHeight * 0.06),
                  _buildFeatureHints(context, data.type)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 700.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHints(BuildContext context, OnboardingPageType type) {
    final hints = _getHintsForType(type);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: hints.asMap().entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                entry.value.icon,
                size: 18,
                color: entry.value.color,
              ),
              const SizedBox(width: 8),
              Text(
                entry.value.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<_FeatureHint> _getHintsForType(OnboardingPageType type) {
    switch (type) {
      case OnboardingPageType.welcome:
        return const [
          _FeatureHint(Icons.explore_rounded, 'Journey', Color(0xFF8B5CF6)),
          _FeatureHint(Icons.self_improvement_rounded, 'Growth', Color(0xFF06B6D4)),
          _FeatureHint(Icons.spa_rounded, 'Heal', Color(0xFF45D9A8)),
        ];
      case OnboardingPageType.focus:
        return const [
          _FeatureHint(Icons.do_not_disturb_rounded, 'Block', Color(0xFFEC4899)),
          _FeatureHint(Icons.timer_rounded, 'Focus', Color(0xFFF97316)),
          _FeatureHint(Icons.check_circle_rounded, 'Habit', Color(0xFF45D9A8)),
        ];
      case OnboardingPageType.gamification:
        return const [
          _FeatureHint(Icons.local_fire_department_rounded, 'Streaks', Color(0xFFF97316)),
          _FeatureHint(Icons.military_tech_rounded, 'Badges', Color(0xFFFFD700)),
          _FeatureHint(Icons.trending_up_rounded, 'Level Up', Color(0xFF8B5CF6)),
        ];
      case OnboardingPageType.aiAssistant:
        return const [
          _FeatureHint(Icons.smart_toy_rounded, 'AI Chat', Color(0xFF06B6D4)),
          _FeatureHint(Icons.insights_rounded, 'Insights', Color(0xFF8B5CF6)),
          _FeatureHint(Icons.route_rounded, 'Roadmap', Color(0xFF45D9A8)),
        ];
    }
  }
}

class _FeatureHint {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureHint(this.icon, this.label, this.color);
}