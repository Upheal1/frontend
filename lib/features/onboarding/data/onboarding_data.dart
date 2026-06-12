import 'package:flutter/material.dart';

enum OnboardingPageType {
  welcome,
  focus,
  gamification,
  aiAssistant,
}

class OnboardingPageData {
  final OnboardingPageType type;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final IconData icon;
  final String heroTag;
  final String travelerImage;

  const OnboardingPageData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.icon,
    required this.heroTag,
    required this.travelerImage,
  });

  static List<OnboardingPageData> get pages => [
        OnboardingPageData(
          type: OnboardingPageType.welcome,
          title: 'Welcome to UpHeal',
          subtitle:
              'Your journey toward clarity, discipline, and healing starts here.',
          gradientColors: const [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
          icon: Icons.landscape_rounded,
          heroTag: 'welcome_hero',
          travelerImage: 'assets/onboarding/traveler_wave.png',
        ),
        OnboardingPageData(
          type: OnboardingPageType.focus,
          title: 'Defeat Distractions',
          subtitle:
              'Reduce addictive scrolling, regain focus, and build stronger habits.',
          gradientColors: const [
            Color(0xFF1A1A2E),
            Color(0xFF2D1B4E),
            Color(0xFF1F1137),
          ],
          icon: Icons.do_not_disturb_on_rounded,
          heroTag: 'focus_hero',
          travelerImage: 'assets/onboarding/traveler_point.png',
        ),
        OnboardingPageData(
          type: OnboardingPageType.gamification,
          title: 'Level Up Your Mind',
          subtitle:
              'Track streaks, earn achievements, and evolve daily.',
          gradientColors: const [
            Color(0xFF0D1B2A),
            Color(0xFF1B263B),
            Color(0xFF415A77),
          ],
          icon: Icons.emoji_events_rounded,
          heroTag: 'gamification_hero',
          travelerImage: 'assets/onboarding/traveler_celebrate.png',
        ),
        OnboardingPageData(
          type: OnboardingPageType.aiAssistant,
          title: 'Your Personal Growth Companion',
          subtitle:
              'AI-powered guidance designed around your goals and behavior.',
          gradientColors: const [
            Color(0xFF0A0A0F),
            Color(0xFF1A1A2E),
            Color(0xFF252542),
          ],
          icon: Icons.psychology_rounded,
          heroTag: 'ai_hero',
          travelerImage: 'assets/onboarding/traveler_point.png',
        ),
      ];
}