import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/badge_model.dart';
import '../services/badge_provider.dart';
import '../shared/theme/upheal_home_theme.dart';
import '../shared/widgets/upheal_home_widgets.dart';

const Color _goldA = Color(0xFFFFD66B);
const Color _goldB = Color(0xFFFF9F43);
const LinearGradient _goldGradient = LinearGradient(
  colors: [_goldA, _goldB],
);

const Color _rarityCommon = Color(0xFF9FB4FF);
const Color _rarityRare = Color(0xFFC79BFF);
const Color _rarityEpic = Color(0xFFFF9BD2);
const Color _rarityLegend = Color(0xFFFFCF6B);

enum _BadgeCategory { all, streaks, focus, mindful, social }

const Map<String, _BadgeCategory> _badgeCategoryMap = {
  'streak': _BadgeCategory.streaks,
  'tasks': _BadgeCategory.focus,
  'free': _BadgeCategory.mindful,
};

const Map<String, String> _badgeEmoji = {
  'streak_3': '\uD83D\uDD25',
  'streak_7': '\uD83D\uDD25',
  'streak_14': '\uD83D\uDD25',
  'streak_30': '\uD83D\uDD25',
  'tasks_5': '\u2705',
  'tasks_20': '\u2705',
  'tasks_50': '\u2705',
  'free_3': '\uD83C\uDF3F',
  'free_7': '\uD83C\uDF3F',
  'free_30': '\uD83C\uDF3F',
};

const Map<String, int> _badgeRarityTier = {
  'streak_3': 0,
  'free_3': 0,
  'tasks_5': 0,
  'streak_7': 1,
  'free_7': 1,
  'tasks_20': 1,
  'streak_14': 2,
  'free_30': 2,
  'tasks_50': 2,
  'streak_30': 3,
};

const List<Color> _rarityColors = [_rarityCommon, _rarityRare, _rarityEpic, _rarityLegend];
const List<String> _rarityLabels = ['Common', 'Rare', 'Epic', 'Legend'];

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  _BadgeCategory _filter = _BadgeCategory.all;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).upHealHome;
    final badgeProvider = context.watch<BadgeProvider>();
    final allBadges = badgeProvider.badges;
    final earned = badgeProvider.earned;
    final earnedCount = earned.length;
    final totalCount = allBadges.length;

    final filtered = _applyFilter(allBadges, _filter);

    return UpHealScaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(tokens),
            SliverToBoxAdapter(child: _buildSummaryCard(earnedCount, totalCount, tokens)),
            SliverToBoxAdapter(child: _buildFilterRow(tokens)),
            if (filtered.where((b) => b.isUnlocked).isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildSectionHeader('Earned', tokens)),
              _buildBadgeGrid(filtered.where((b) => b.isUnlocked).toList(), true, tokens),
            ],
            if (filtered.where((b) => !b.isUnlocked).isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildSectionHeader('Locked', tokens)),
              _buildBadgeGrid(filtered.where((b) => !b.isUnlocked).toList(), false, tokens),
            ],
            SliverToBoxAdapter(child: SizedBox(height: tokens.screenPadding)),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(UpHealHomeTheme tokens) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(4, tokens.space8, tokens.space12, 0),
        child: Row(
          children: [
            IconButton(
              icon: Icon(LucideIcons.chevronLeft, color: tokens.primaryText),
              onPressed: () => Navigator.maybePop(context),
              tooltip: 'Back',
            ),
            Text(
              'Badges',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: tokens.primaryText,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int earned, int total, UpHealHomeTheme tokens) {
    final progress = total > 0 ? earned / total : 0.0;
    final rankLabel = _rankLabel(earned, total);

    return Container(
      margin: EdgeInsets.all(tokens.screenPadding),
      padding: EdgeInsets.all(tokens.space20),
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow != null
            ? [tokens.cardShadow!]
            : const <BoxShadow>[],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: _goldGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _goldA.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Text('\uD83C\uDFC6', style: TextStyle(fontSize: 26)),
            ),
          ),
          SizedBox(width: tokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$earned / $total earned',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: tokens.primaryText,
                    height: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  rankLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: tokens.faintText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: tokens.space8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: tokens.trackColor,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(UpHealHomeTheme tokens) {
    final filters = [
      (_BadgeCategory.all, 'All'),
      (_BadgeCategory.streaks, 'Streaks'),
      (_BadgeCategory.focus, 'Focus'),
      (_BadgeCategory.mindful, 'Mindful'),
      (_BadgeCategory.social, 'Social'),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(tokens.screenPadding, 0, 0, tokens.space12),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => SizedBox(width: tokens.space8),
          itemBuilder: (context, index) {
            final f = filters[index];
            final selected = _filter == f.$1;
            return GestureDetector(
              onTap: () => setState(() => _filter = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: tokens.space16),
                decoration: BoxDecoration(
                  gradient: selected
                      ? UpHealHomeTheme.sharedAccentGradient
                      : null,
                  color: selected ? null : tokens.cardFill,
                  borderRadius: BorderRadius.circular(tokens.pillRadius),
                  border: selected ? null : Border.all(color: tokens.cardBorder),
                ),
                child: Center(
                  child: Text(
                    f.$2,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : tokens.secondaryText,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  SliverPadding _buildBadgeGrid(List<BadgeModel> badges, bool earned, UpHealHomeTheme tokens) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: tokens.screenPadding),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: tokens.space12,
          mainAxisSpacing: tokens.space12,
          childAspectRatio: 0.95,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final badge = badges[index];
            final tier = _badgeRarityTier[badge.id] ?? 0;
            return _BadgeTile(
              badge: badge,
              unlocked: earned,
              rarityColor: _rarityColors[tier],
              rarityLabel: _rarityLabels[tier],
              emoji: _badgeEmoji[badge.id] ?? '\uD83C\uDFC6',
              onTap: () {
                HapticFeedback.selectionClick();
                _showBadgeSheet(context, badge, tier, tokens);
              },
            );
          },
          childCount: badges.length,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, UpHealHomeTheme tokens) {
    return Padding(
      padding: EdgeInsets.fromLTRB(tokens.screenPadding, 4.0, tokens.screenPadding, tokens.space12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: tokens.primaryText,
        ),
      ),
    );
  }

  void _showBadgeSheet(BuildContext context, BadgeModel badge, int tier, UpHealHomeTheme tokens) {
    final isUnlocked = badge.isUnlocked;
    final rarityColor = _rarityColors[tier];
    final rarityLabel = _rarityLabels[tier];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.all(tokens.space20),
        decoration: BoxDecoration(
          color: tokens.cardFill,
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isUnlocked
                    ? LinearGradient(
                        colors: [rarityColor, rarityColor.withValues(alpha: 0.6)],
                      )
                    : LinearGradient(
                        colors: [tokens.faintText, tokens.faintText.withValues(alpha: 0.4)],
                      ),
                boxShadow: tier >= 3 && isUnlocked
                    ? [
                        BoxShadow(
                          color: rarityColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  _badgeEmoji[badge.id] ?? '\uD83C\uDFC6',
                  style: TextStyle(fontSize: 32),
                ),
              ),
            ),
            SizedBox(height: tokens.space16),
            Text(
              badge.title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: tokens.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: tokens.space12, vertical: 3),
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(tokens.pillRadius),
              ),
              child: Text(
                rarityLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: rarityColor,
                ),
              ),
            ),
            SizedBox(height: tokens.space12),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: tokens.secondaryText,
                height: 1.5,
              ),
            ),
            SizedBox(height: tokens.space16),
            if (isUnlocked && badge.unlockedAt != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.calendar, size: 14, color: tokens.faintText),
                  SizedBox(width: 6),
                  Text(
                    'Earned on ${_formatDate(badge.unlockedAt!)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: tokens.faintText,
                    ),
                  ),
                ],
              ),
            if (!isUnlocked)
              Column(
                children: [
                  Text(
                    'How to unlock',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.faintText,
                    ),
                  ),
                  SizedBox(height: tokens.space8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: tokens.space12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tokens.quickGroupsChip,
                      borderRadius: BorderRadius.circular(tokens.pillRadius),
                    ),
                    child: Text(
                      'Required: ${badge.requiredValue} ${_conditionLabel(badge.id)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.quickGroupsIcon,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<BadgeModel> _applyFilter(List<BadgeModel> badges, _BadgeCategory filter) {
    if (filter == _BadgeCategory.all) return badges;
    if (filter == _BadgeCategory.social) return [];
    return badges.where((b) {
      final prefix = b.id.split('_').first;
      return _badgeCategoryMap[prefix] == filter;
    }).toList();
  }

  String _rankLabel(int earned, int total) {
    if (total == 0) return '';
    if (earned >= total) return 'Level 4 \u00b7 Legend \u2014 All badges collected!';
    if (earned >= total * 0.75) return 'Level 3 \u00b7 Collector \u2014 ${total - earned} more to Platinum';
    if (earned >= total * 0.5) return 'Level 2 \u00b7 Seeker \u2014 ${total - earned} more to Collector';
    if (earned >= total * 0.25) return 'Level 1 \u00b7 Beginner \u2014 ${total - earned} more to Seeker';
    return 'Level 0 \u00b7 Newcomer \u2014 ${total - earned} more to Beginner';
  }

  String _conditionLabel(String id) {
    if (id.startsWith('streak')) return 'day streak';
    if (id.startsWith('tasks')) return 'tasks completed';
    if (id.startsWith('free')) return 'addiction-free days';
    return '';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeModel badge;
  final bool unlocked;
  final Color rarityColor;
  final String rarityLabel;
  final String emoji;
  final VoidCallback onTap;

  const _BadgeTile({
    required this.badge,
    required this.unlocked,
    required this.rarityColor,
    required this.rarityLabel,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).upHealHome;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.cardFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unlocked
                ? rarityColor.withValues(alpha: 0.3)
                : tokens.cardBorder,
          ),
          boxShadow: unlocked && tokens.cardShadow != null
              ? [tokens.cardShadow!]
              : const <BoxShadow>[],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.21, 0.71, 0.07, 0, 0,
                  0.21, 0.71, 0.07, 0, 0,
                  0.21, 0.71, 0.07, 0, 0,
                  0,    0,    0,    0.45, 0,
                ]),
                child: _medal(tokens),
              )
            else
              _medal(tokens),
            SizedBox(height: tokens.space8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                badge.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: unlocked
                      ? tokens.primaryText
                      : tokens.faintText,
                ),
              ),
            ),
            if (unlocked)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    rarityLabel,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: rarityColor,
                    ),
                  ),
                ),
              ),
            if (!unlocked) ...[
              SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${badge.requiredValue} ${_shortUnit(badge.id)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: tokens.faintText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _medal(UpHealHomeTheme tokens) {
    final isLegend = rarityLabel == 'Legend';

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: unlocked
            ? LinearGradient(
                colors: [rarityColor, rarityColor.withValues(alpha: 0.6)],
              )
            : LinearGradient(
                colors: [tokens.faintText.withValues(alpha: 0.3), tokens.faintText.withValues(alpha: 0.15)],
              ),
        boxShadow: isLegend && unlocked
            ? [
                BoxShadow(
                  color: rarityColor.withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            unlocked ? emoji : '\uD83D\uDD12',
            style: TextStyle(fontSize: unlocked ? 26 : 20),
          ),
          if (!unlocked)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: tokens.faintText.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, size: 9, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  String _shortUnit(String id) {
    if (id.startsWith('streak')) return 'days';
    if (id.startsWith('tasks')) return 'tasks';
    if (id.startsWith('free')) return 'days';
    return '';
  }
}
