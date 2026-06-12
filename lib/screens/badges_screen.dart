import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/badge_model.dart';
import '../navigation/navigation_helpers.dart';
import '../services/badge_provider.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0D12) : theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: () => safeGoBack(context),
        ),
        title: Text(
          'Badges',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
      body: _BadgesContent(),
    );
  }
}

class _BadgesContent extends StatelessWidget {
  const _BadgesContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<BadgeProvider?>(
      builder: (context, provider, child) {
        if (provider == null) {
          return const _LoadingState();
        }

        try {
          final earned = provider.earned;
          final locked = provider.locked;

          if (earned.isEmpty && locked.isEmpty) {
            return _EmptyBadgesState();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              _SectionHeader(
                title: 'Earned',
                subtitle: '${earned.length} unlocked',
              ),
              const SizedBox(height: 12),
              if (earned.isEmpty)
                const _EmptySection(
                  title: 'No badges yet',
                  subtitle: 'Complete streaks and challenges to unlock badges.',
                )
              else
                _BadgesGrid(badges: earned, locked: false),
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'Locked',
                subtitle: '${locked.length} remaining',
              ),
              const SizedBox(height: 12),
              if (locked.isEmpty)
                const _EmptySection(
                  title: 'All unlocked!',
                  subtitle: 'You\'ve collected all available badges.',
                )
              else
                _BadgesGrid(badges: locked, locked: true),
            ],
          );
        } catch (e, stack) {
          debugPrint('BadgesScreen error: $e');
          debugPrint('Stack: $stack');
          return _ErrorState(message: e.toString());
        }
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading badges...',
            style: GoogleFonts.inter(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.alertCircle,
                color: Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load badges',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBadgesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.award,
                color: AppColors.purple,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Badges Yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete streaks and challenges to unlock your first badge!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptySection({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: (isDark ? Colors.white : AppColors.surface).withValues(alpha: 0.5),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _BadgesGrid extends StatelessWidget {
  final List<BadgeModel> badges;
  final bool locked;

  const _BadgesGrid({required this.badges, required this.locked});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _BadgeTile(badge: badge, isLocked: locked)
            .animate()
            .fadeIn(duration: 220.ms, delay: (index * 35).ms)
            .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1));
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeModel badge;
  final bool isLocked;

  const _BadgeTile({required this.badge, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : AppColors.textPrimary;
    final surfaceColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    final glow = !isLocked;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: surfaceColor.withValues(alpha: 0.55),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Opacity(
        opacity: isLocked ? 0.45 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: _BadgeIcon(path: badge.iconPath ?? '', locked: isLocked),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              badge.title ?? 'Unknown',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLocked ? 'Unlock at ${badge.requiredValue}' : 'Unlocked',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isLocked
                    ? onSurface.withValues(alpha: 0.6)
                    : AppColors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final String path;
  final bool locked;

  const _BadgeIcon({required this.path, required this.locked});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildFallback() {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (isDark ? Colors.white : AppColors.surface).withValues(alpha: 0.08),
        ),
        alignment: Alignment.center,
        child: Text(
          locked ? '🔒' : '🏅',
          style: const TextStyle(fontSize: 22),
        ),
      );
    }

    if (path.isEmpty) {
      return buildFallback();
    }

    return Image.asset(
      path,
      width: 52,
      height: 52,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => buildFallback(),
    );
  }
}