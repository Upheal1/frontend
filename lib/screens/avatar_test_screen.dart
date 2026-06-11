import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:o3d/o3d.dart';
import 'package:provider/provider.dart';

import '../avatar/models/avatar_unlock_config.dart';
import '../avatar/services/avatar_progression_provider.dart';
import '../constants/app_colors.dart';
import '../gamification/xp_config.dart';
import '../models/user_model.dart';

class AvatarTestScreen extends StatefulWidget {
  const AvatarTestScreen({super.key});

  @override
  State<AvatarTestScreen> createState() => _AvatarTestScreenState();
}

class _AvatarTestScreenState extends State<AvatarTestScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserModel>();
    final progression = context.watch<AvatarProgressionProvider>();
    final avatars = AvatarUnlockConfig.all;
    final selectedAvatar = avatars[_selected];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar Showcase'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _LevelHeader(level: user.level, xp: user.xp),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    O3D.asset(
                      key: ValueKey<String>('${selectedAvatar.src}_$_selected'),
                      id: 'avatar_showcase_$_selected',
                      src: selectedAvatar.src,
                      cameraControls: true,
                      autoRotate: true,
                      autoRotateDelay: 0,
                      interactionPrompt: InteractionPrompt.none,
                      cameraOrbit: CameraOrbit(0, 75, 3.2),
                      environmentImage: 'neutral',
                      exposure: 1,
                      shadowIntensity: 0.35,
                      loading: Loading.eager,
                      reveal: Reveal.auto,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                    if (!progression.isUnlocked(selectedAvatar.src))
                      Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.lock,
                              color: Colors.white70,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Unlocks at level ${selectedAvatar.unlockLevel}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              selectedAvatar.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (progression.isUnlocked(selectedAvatar.src))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                progression.equippedSrc == selectedAvatar.src
                    ? 'Equipped'
                    : 'Tap equip to use this avatar',
                style: TextStyle(
                  fontSize: 13,
                  color: progression.equippedSrc == selectedAvatar.src
                      ? AppColors.purple
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (progression.isUnlocked(selectedAvatar.src))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: progression.equippedSrc == selectedAvatar.src
                      ? null
                      : () => progression.equip(selectedAvatar.src),
                  icon: Icon(
                    progression.equippedSrc == selectedAvatar.src
                        ? LucideIcons.checkCircle
                        : LucideIcons.backpack,
                    size: 18,
                  ),
                  label: Text(
                    progression.equippedSrc == selectedAvatar.src
                        ? 'Equipped'
                        : 'Equip',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: progression.equippedSrc == selectedAvatar.src
                        ? AppColors.purple.withValues(alpha: 0.3)
                        : AppColors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: avatars.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final avatar = avatars[i];
                  final unlocked = progression.isUnlocked(avatar.src);
                  final selected = i == _selected;
                  return _AvatarCard(
                    avatar: avatar,
                    unlocked: unlocked,
                    selected: selected,
                    onTap: unlocked ? () => setState(() => _selected = i) : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  final int level;
  final int xp;

  const _LevelHeader({required this.level, required this.xp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextLevelTotal = XpConfig.totalXpForLevel(level + 1);
    final currentLevelTotal = XpConfig.totalXpForLevel(level);
    final progress = nextLevelTotal > currentLevelTotal
        ? (xp - currentLevelTotal) / (nextLevelTotal - currentLevelTotal)
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.purple, Color(0xFF7F77DD)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '$level',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level $level',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    color: AppColors.purple,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$xp / $nextLevelTotal XP',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarCard extends StatelessWidget {
  final AvatarUnlockConfig avatar;
  final bool unlocked;
  final bool selected;
  final VoidCallback? onTap;

  const _AvatarCard({
    required this.avatar,
    required this.unlocked,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 76,
        decoration: BoxDecoration(
          color: unlocked
              ? (selected ? AppColors.purple.withValues(alpha: 0.1) : theme.cardColor)
              : theme.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.purple : Colors.grey.withValues(alpha: 0.15),
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  unlocked ? '🧑' : '🔒',
                  style: TextStyle(
                    fontSize: unlocked ? 24 : 20,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    avatar.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: unlocked
                          ? (selected
                              ? AppColors.purple
                              : theme.colorScheme.onSurface.withValues(alpha: 0.7))
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (!unlocked) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Lv.${avatar.unlockLevel}',
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            if (selected && unlocked)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.purple,
                  ),
                  child: const Icon(Icons.check, size: 9, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
