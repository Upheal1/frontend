import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:o3d/o3d.dart';
import 'package:provider/provider.dart';

import '../avatar/models/avatar_unlock_config.dart';
import '../avatar/services/avatar_progression_provider.dart';
import '../models/user_model.dart';
import '../shared/theme/upheal_home_theme.dart';
import '../shared/widgets/upheal_home_widgets.dart';

class AvatarShowcaseScreen extends StatelessWidget {
  const AvatarShowcaseScreen({super.key});

  static String _rankTitle(int level) {
    if (level >= 15) return 'Luminary';
    if (level >= 11) return 'Pathfinder';
    if (level >= 7) return 'Trailblazer';
    if (level >= 4) return 'Wanderer';
    return 'Explorer';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();
    final progression = context.watch<AvatarProgressionProvider>();
    final tokens = Theme.of(context).upHealHome;
    final avatars = AvatarUnlockConfig.all;
    final equipped = progression.equippedAvatar;
    final unlockedCount = progression.unlockedAvatars.length;
    final totalCount = avatars.length;
    final allUnlocked = unlockedCount >= totalCount;

    final nextLocked = allUnlocked
        ? null
        : avatars.firstWhere(
            (a) => !progression.isUnlocked(a.src),
            orElse: () => avatars.last,
          );

    return UpHealScaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, tokens)),
            SliverToBoxAdapter(child: _buildHeroCard(user, progression, equipped, tokens)),
            SliverToBoxAdapter(child: _buildProgressStrip(unlockedCount, totalCount, nextLocked, tokens, allUnlocked)),
            if (progression.unlockedAvatars.isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildSectionHeader('Unlocked', tokens)),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: tokens.screenPadding),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: tokens.space12,
                    mainAxisSpacing: tokens.space12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final a = progression.unlockedAvatars[index];
                      final isEquipped = progression.equippedSrc == a.src;
                      return _CompanionTile(
                        avatar: a,
                        unlocked: true,
                        isEquipped: isEquipped,
                        onTap: () {
                          if (!isEquipped) {
                            HapticFeedback.selectionClick();
                            progression.equip(a.src);
                          }
                        },
                      );
                    },
                    childCount: progression.unlockedAvatars.length,
                  ),
                ),
              ),
            ],
            if (!allUnlocked) ...[
              SliverToBoxAdapter(child: _buildSectionHeader('Locked', tokens)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  tokens.screenPadding, 0, tokens.screenPadding, tokens.screenPadding,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: tokens.space12,
                    mainAxisSpacing: tokens.space12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final lockedAvatars = avatars.where((a) => !progression.isUnlocked(a.src)).toList();
                      final a = lockedAvatars[index];
                      final progress = (user.level / a.unlockLevel).clamp(0.0, 1.0);
                      final isPrestige = a == avatars.last;
                      return _CompanionTile(
                        avatar: a,
                        unlocked: false,
                        isEquipped: false,
                        unlockProgress: progress,
                        isPrestige: isPrestige,
                        onTap: () => _showPreviewSheet(context, a, user, progression, tokens, isPrestige),
                      );
                    },
                    childCount: avatars.where((a) => !progression.isUnlocked(a.src)).length,
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(child: SizedBox(height: tokens.screenPadding)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UpHealHomeTheme tokens) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, tokens.space8, tokens.space12, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.chevronLeft, color: tokens.primaryText),
            onPressed: () => Navigator.maybePop(context),
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
          Text(
            'Companions',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: tokens.primaryText,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
    UserModel user,
    AvatarProgressionProvider progression,
    AvatarUnlockConfig? equipped,
    UpHealHomeTheme tokens,
  ) {
    final avatar = equipped ?? AvatarUnlockConfig.all.first;
    final rankTitle = _rankTitle(user.level);
    final xpProgress = user.levelProgress;

    return Container(
      margin: EdgeInsets.all(tokens.screenPadding),
      padding: EdgeInsets.all(tokens.space20),
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(tokens.cardRadius + 2),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow != null
            ? [tokens.cardShadow!]
            : const <BoxShadow>[],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      tokens.navActive.withValues(alpha: 0.25),
                      tokens.navActive.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: SizedBox(
                  width: 128,
                  height: 128,
                  child: O3D.asset(
                    src: avatar.src,
                    cameraControls: false,
                    autoRotate: true,
                    autoRotateDelay: 0,
                    interactionPrompt: InteractionPrompt.none,
                    loading: Loading.eager,
                    reveal: Reveal.auto,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.space16),
          Text(
            avatar.name,
            style: GoogleFonts.inter(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: tokens.primaryText,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '$rankTitle \u00b7 Level ${user.level}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: tokens.faintText,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: tokens.space16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: xpProgress.clamp(0.0, 1.0),
              backgroundColor: tokens.trackColor,
              minHeight: 8,
            ),
          ),
          SizedBox(height: tokens.space12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: tokens.space16, vertical: tokens.space8),
            decoration: BoxDecoration(
              gradient: UpHealHomeTheme.sharedAccentGradient,
              borderRadius: BorderRadius.circular(tokens.pillRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.check, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Equipped',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStrip(
    int unlockedCount,
    int totalCount,
    AvatarUnlockConfig? nextLocked,
    UpHealHomeTheme tokens,
    bool allUnlocked,
  ) {
    final label = allUnlocked
        ? 'You\u2019ve unlocked all $totalCount companions!'
        : 'You\u2019ve unlocked $unlockedCount of $totalCount. '
            'Keep your streak to reveal ${nextLocked?.name ?? 'the next'}.\u2009';

    return Container(
      margin: EdgeInsets.fromLTRB(tokens.screenPadding, 0, tokens.screenPadding, tokens.space12),
      padding: EdgeInsets.all(tokens.space16),
      decoration: BoxDecoration(
        color: tokens.cardFill,
        borderRadius: BorderRadius.circular(tokens.tileRadius),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow != null
            ? [tokens.cardShadow!]
            : const <BoxShadow>[],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tokens.quickGroupsChip,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(LucideIcons.backpack, size: 18, color: tokens.quickGroupsIcon),
            ),
          ),
          SizedBox(width: tokens.space12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: tokens.secondaryText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, UpHealHomeTheme tokens) {
    return Padding(
      padding: EdgeInsets.fromLTRB(tokens.screenPadding, tokens.space8, tokens.screenPadding, tokens.space12),
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

  void _showPreviewSheet(
    BuildContext context,
    AvatarUnlockConfig avatar,
    UserModel user,
    AvatarProgressionProvider progression,
    UpHealHomeTheme tokens,
    bool isPrestige,
  ) {
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
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: isPrestige
                      ? const LinearGradient(
                          colors: [Color(0xFFF2B55D), Color(0xFFE8913A)],
                        )
                      : UpHealHomeTheme.sharedAccentGradient,
                ),
                child: O3D.asset(
                  src: avatar.src,
                  cameraControls: false,
                  autoRotate: true,
                  autoRotateDelay: 0,
                  interactionPrompt: InteractionPrompt.none,
                  loading: Loading.eager,
                  reveal: Reveal.auto,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            SizedBox(height: tokens.space16),
            Text(
              avatar.name,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: tokens.primaryText,
              ),
            ),
            SizedBox(height: tokens.space8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: tokens.space12, vertical: 4),
              decoration: BoxDecoration(
                color: isPrestige
                    ? const Color(0x33F2B55D)
                    : tokens.quickGroupsChip,
                borderRadius: BorderRadius.circular(tokens.pillRadius),
              ),
              child: Text(
                isPrestige ? 'Prestige Companion' : 'Reach Level ${avatar.unlockLevel}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPrestige
                      ? const Color(0xFFF2B55D)
                      : tokens.quickGroupsIcon,
                ),
              ),
            ),
            SizedBox(height: tokens.space16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: tokens.faintText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Lv.${user.level} / Lv.${avatar.unlockLevel}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: tokens.faintText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.space8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (user.level / avatar.unlockLevel).clamp(0.0, 1.0),
                    backgroundColor: tokens.trackColor,
                    color: isPrestige
                        ? const Color(0xFFF2B55D)
                        : tokens.navActive,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.space20),
            if (isPrestige)
              Text(
                'The ultimate companion. Only the most dedicated travelers can unlock this prestige form.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: tokens.faintText,
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompanionTile extends StatelessWidget {
  final AvatarUnlockConfig avatar;
  final bool unlocked;
  final bool isEquipped;
  final double unlockProgress;
  final bool isPrestige;
  final VoidCallback onTap;

  const _CompanionTile({
    required this.avatar,
    required this.unlocked,
    required this.isEquipped,
    this.unlockProgress = 0.0,
    this.isPrestige = false,
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
            color: isEquipped
                ? const Color(0xFF8A6CF6)
                : tokens.cardBorder,
            width: isEquipped ? 2 : 1,
          ),
          boxShadow: isEquipped && tokens.cardShadow != null
              ? [
                  BoxShadow(
                    color: const Color(0xFF8A6CF6).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : (tokens.cardShadow != null
                  ? [tokens.cardShadow!]
                  : const <BoxShadow>[]),
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
                  0,    0,    0,    0.5, 0,
                ]),
                child: _avatarWidget(tokens),
              )
            else
              _avatarWidget(tokens),
            SizedBox(height: tokens.space8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                avatar.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: unlocked
                      ? tokens.primaryText
                      : tokens.faintText,
                ),
              ),
            ),
            if (unlocked && isEquipped)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Equipped',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8A6CF6),
                  ),
                ),
              ),
            if (unlocked && !isEquipped)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Owned',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: tokens.faintText,
                  ),
                ),
              ),
            if (!unlocked) ...[
              const SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPrestige
                      ? const Color(0x33F2B55D)
                      : tokens.quickGroupsChip,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPrestige ? 'Prestige' : 'Lv.${avatar.unlockLevel}',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isPrestige
                        ? const Color(0xFFF2B55D)
                        : tokens.quickGroupsIcon,
                  ),
                ),
              ),
              if (unlockProgress > 0)
                Padding(
                  padding: EdgeInsets.fromLTRB(tokens.space8, 4, tokens.space8, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: unlockProgress.clamp(0.0, 1.0),
                      backgroundColor: tokens.trackColor,
                      minHeight: 3,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _avatarWidget(UpHealHomeTheme tokens) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isPrestige
            ? const LinearGradient(
                colors: [Color(0xFFF2B55D), Color(0xFFE8913A)],
              )
            : UpHealHomeTheme.sharedAccentGradient,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 64,
              height: 64,
              child: O3D.asset(
                src: avatar.src,
                cameraControls: false,
                autoRotate: false,
                interactionPrompt: InteractionPrompt.none,
                loading: Loading.eager,
                reveal: Reveal.auto,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          if (isPrestige)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFFF2B55D),
                  shape: BoxShape.circle,
                ),
                child: const Text('\u2B50', style: TextStyle(fontSize: 10)),
              ),
            ),
          if (isEquipped)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF8A6CF6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
          if (!unlocked)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: tokens.faintText.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, size: 11, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
