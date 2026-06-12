import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../models/achievement.dart';
import '../navigation/navigation_helpers.dart';

class AchievementsScreen extends StatefulWidget {
  final List<Achievement> achievements;

  const AchievementsScreen({
    super.key,
    required this.achievements,
  });

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

enum _AchievementFilter {
  all,
  streak,
  sessions,
  time,
  level,
  special,
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  _AchievementFilter _filter = _AchievementFilter.all;

  @override
  Widget build(BuildContext context) {
    final all = widget.achievements;
    final unlocked = all.where((a) => a.isUnlocked).toList();

    final filtered = _applyFilter(all, _filter);
    final sorted = _sortAchievements(filtered);

    final unlockedCount = unlocked.length;
    final totalCount = all.length;
    final xpFromBadges =
        unlocked.fold<int>(0, (sum, a) => sum + (a.xpReward));
    final rarest = _rarestRarity(unlocked);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$unlockedCount / $totalCount unlocked',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => safeGoBack(context),
        ),
      ),
      body: Column(
        children: [
          _buildFilterRow(context),
          const SizedBox(height: 8),
          _buildStatsRow(
            context,
            unlockedCount: unlockedCount,
            xpFromBadges: xpFromBadges,
            rarest: rarest,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.82,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final achievement = sorted[index];
                  return _AchievementTile(
                    achievement: achievement,
                    index: index,
                    onTap: achievement.isUnlocked
                        ? () => _showDetailsBottomSheet(context, achievement)
                        : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Achievement> _applyFilter(
    List<Achievement> achievements,
    _AchievementFilter filter,
  ) {
    switch (filter) {
      case _AchievementFilter.all:
        return achievements;
      case _AchievementFilter.streak:
        return achievements
            .where((a) => a.type == AchievementType.focusStreak)
            .toList();
      case _AchievementFilter.sessions:
        return achievements
            .where((a) => a.type == AchievementType.totalSessions)
            .toList();
      case _AchievementFilter.time:
        return achievements
            .where((a) => a.type == AchievementType.totalTime)
            .toList();
      case _AchievementFilter.level:
        return achievements
            .where((a) => a.type == AchievementType.level)
            .toList();
      case _AchievementFilter.special:
        return achievements
            .where((a) => a.type == AchievementType.special)
            .toList();
    }
  }

  List<Achievement> _sortAchievements(List<Achievement> list) {
    final unlocked = list.where((a) => a.isUnlocked).toList()
      ..sort((a, b) {
        final ad = a.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad); // newest first
      });

    final locked = list.where((a) => !a.isUnlocked).toList()
      ..sort((a, b) {
        final rr = _rarityRank(b.rarity) - _rarityRank(a.rarity);
        if (rr != 0) return rr;
        return a.id.compareTo(b.id);
      });

    return [...unlocked, ...locked];
  }

  AchievementRarity? _rarestRarity(List<Achievement> unlocked) {
    if (unlocked.isEmpty) return null;
    AchievementRarity best = unlocked.first.rarity;
    for (final a in unlocked) {
      if (_rarityRank(a.rarity) > _rarityRank(best)) {
        best = a.rarity;
      }
    }
    return best;
  }

  int _rarityRank(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 1;
      case AchievementRarity.rare:
        return 2;
      case AchievementRarity.epic:
        return 3;
      case AchievementRarity.legendary:
        return 4;
    }
  }

  String _rarityLabel(AchievementRarity? rarity) {
    if (rarity == null) return '—';
    return rarity.name.toUpperCase();
  }

  Color _rarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return const Color(0xFF888780);
      case AchievementRarity.rare:
        return const Color(0xFF378ADD);
      case AchievementRarity.epic:
        return AppColors.purple; // 0xFF7F77DD
      case AchievementRarity.legendary:
        return const Color(0xFFBA7517);
    }
  }

  Widget _buildFilterRow(BuildContext context) {
    final chips = <(_AchievementFilter, String)>[
      (_AchievementFilter.all, 'All'),
      (_AchievementFilter.streak, 'Streak'),
      (_AchievementFilter.sessions, 'Sessions'),
      (_AchievementFilter.time, 'Time'),
      (_AchievementFilter.level, 'Level'),
      (_AchievementFilter.special, 'Special'),
    ];

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: chips.map((e) {
            final selected = _filter == e.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  e.$2,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
                selected: selected,
                selectedColor: AppColors.purple,
                backgroundColor:
                    AppColors.textPrimary.withOpacity(0.03),
                side: selected
                    ? BorderSide.none
                    : BorderSide(
                        color: AppColors.textSecondary.withOpacity(0.3),
                      ),
                onSelected: (_) {
                  setState(() {
                    _filter = e.$1;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context, {
    required int unlockedCount,
    required int xpFromBadges,
    required AchievementRarity? rarest,
  }) {
    final cards = [
      ('$unlockedCount', 'unlocked'),
      ('$xpFromBadges', 'XP earned'),
      (_rarityLabel(rarest), 'rarest'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: cards.map((c) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.$1,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.$2,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showDetailsBottomSheet(
    BuildContext context,
    Achievement achievement,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final rarityColor = _rarityColor(achievement.rarity);
        final unlockedAt = achievement.unlockedAt;
        final unlockedText = unlockedAt != null
            ? 'Unlocked ${unlockedAt.month}/${unlockedAt.year}'
            : 'Unlocked';

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: achievement.color.withOpacity(0.16),
                ),
                alignment: Alignment.center,
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: rarityColor.withOpacity(0.1),
                    ),
                    child: Text(
                      achievement.rarity.name.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: rarityColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: AppColors.teal.withOpacity(0.1),
                    ),
                    child: Text(
                      '+ ${achievement.xpReward} XP',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                unlockedText,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final int index;
  final VoidCallback? onTap;

  const _AchievementTile({
    required this.achievement,
    required this.index,
    this.onTap,
  });

  bool get _isHiddenLocked =>
      achievement.visibility == AchievementVisibility.hidden &&
      !achievement.isUnlocked;

  Color _rarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return const Color(0xFF888780);
      case AchievementRarity.rare:
        return const Color(0xFF378ADD);
      case AchievementRarity.epic:
        return AppColors.purple;
      case AchievementRarity.legendary:
        return const Color(0xFFBA7517);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(achievement.rarity);

    Widget card;
    if (_isHiddenLocked) {
      card = _buildHiddenTile(context);
    } else if (achievement.isUnlocked) {
      card = _buildUnlockedTile(context, rarityColor);
    } else {
      card = _buildLockedTile(context, rarityColor);
    }

    return GestureDetector(
      onTap: achievement.isUnlocked ? onTap : null,
      child: card
          .animate()
          .fadeIn(duration: 250.ms, delay: (index * 50).ms)
          .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
    );
  }

  Widget _buildUnlockedTile(BuildContext context, Color rarityColor) {
    final unlockedAt = achievement.unlockedAt;
    final unlockedText = unlockedAt != null
        ? 'Unlocked ${unlockedAt.month}/${unlockedAt.year}'
        : 'Unlocked';

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: rarityColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: rarityColor.withOpacity(0.1),
                  ),
                  child: Text(
                    achievement.rarity.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: rarityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: achievement.color.withOpacity(0.15),
                ),
                alignment: Alignment.center,
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              achievement.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: 1.0,
                backgroundColor: Colors.grey.withOpacity(0.15),
                valueColor:
                    AlwaysStoppedAnimation<Color>(rarityColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unlockedText,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedTile(BuildContext context, Color rarityColor) {
    final current = achievement.currentProgress ?? 0;
    final total = achievement.requirement;
    final progress = achievement.progress;

    return Card(
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: rarityColor.withOpacity(0.06),
                  ),
                  child: Text(
                    achievement.rarity.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: rarityColor.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: achievement.color.withOpacity(0.1),
                ),
                alignment: Alignment.center,
                child: Opacity(
                  opacity: 0.5,
                  child: Text(
                    achievement.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              achievement.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  rarityColor.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$current / $total',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHiddenTile(BuildContext context) {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[700],
                ),
                alignment: Alignment.center,
                child: const Text(
                  '?',
                  style: TextStyle(
                    fontSize: 26,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '???',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Keep going to reveal this badge',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey[400],
              ),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: 0,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

