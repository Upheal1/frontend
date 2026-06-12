import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../data/community_models.dart';
import 'community_decor.dart';

class CommunityPostCard extends StatefulWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onOpen,
    required this.onLike,
    required this.onSave,
    required this.onShare,
  });

  final CommunityPost post;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onShare;

  static Future<void> sharePost(BuildContext context, CommunityPost post) async {
    final text = '${post.author.displayName} on UpHeal:\n\n${post.body}\n\n#UpHeal';
    await Share.share(text);
  }

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 220),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  String _shortTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    return '${diff.inDays ~/ 30}mo';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _pressCtrl,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.reverse(),
        onTapUp: (_) {
          _pressCtrl.forward();
          widget.onOpen();
        },
        onTapCancel: () => _pressCtrl.forward(),
        child: Container(
          decoration: CommunityDecor.glassCard(context, radius: 22),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Author row ───────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GradientAvatar(
                    displayName: widget.post.author.displayName,
                    avatarUrl: widget.post.author.avatarUrl,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.post.author.displayName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _shortTime(widget.post.createdAt),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: scheme.onSurface.withOpacity(0.42),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _LevelBadge(level: widget.post.author.level),
                            if (widget.post.author.streakDays > 0)
                              _StreakBadge(days: widget.post.author.streakDays),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // ── Tags ─────────────────────────────────────────────────────
              if (widget.post.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: widget.post.tags
                      .map((t) => _TagChip(tag: t))
                      .toList(),
                ),
              ],
              // ── Body ─────────────────────────────────────────────────────
              const SizedBox(height: 12),
              _ExpandableBody(
                body: widget.post.body,
                expanded: _expanded,
                onToggle: () => setState(() => _expanded = !_expanded),
              ),
              // ── Image ────────────────────────────────────────────────────
              if (widget.post.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                _PostImage(url: widget.post.imageUrls.first),
              ],
              // ── Divider + actions ─────────────────────────────────────────
              const SizedBox(height: 14),
              Divider(
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : const Color(0xFFF3F4F6),
                height: 1,
              ),
              const SizedBox(height: 12),
              _ActionRow(
                post: widget.post,
                onLike: widget.onLike,
                onComment: widget.onOpen,
                onSave: widget.onSave,
                onShare: widget.onShare,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Avatar ───────────────────────────────────────────────────────────────────

class _GradientAvatar extends StatelessWidget {
  const _GradientAvatar({required this.displayName, this.avatarUrl});
  final String displayName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [CommunityDecor.lavender, CommunityDecor.mint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(
                  CommunityDecor.avatarFor(displayName),
                  fit: BoxFit.cover,
                ),
              )
            : Image.network(
                CommunityDecor.avatarFor(displayName),
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

// ── Badges ───────────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CommunityDecor.lavender.withOpacity(0.15),
            CommunityDecor.mint.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CommunityDecor.lavender.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.sparkles,
              size: 10, color: CommunityDecor.lavender),
          const SizedBox(width: 3),
          Text(
            'Lv $level',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: CommunityDecor.lavender,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CommunityDecor.peach.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CommunityDecor.peach.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.flame, size: 10, color: CommunityDecor.peach),
          const SizedBox(width: 3),
          Text(
            '$days streak',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: CommunityDecor.peach,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Tag chip ──────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CommunityDecor.lavender.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#$tag',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: CommunityDecor.lavender,
        ),
      ),
    );
  }
}

// ── Body with expand/collapse ─────────────────────────────────────────────────

class _ExpandableBody extends StatelessWidget {
  const _ExpandableBody({
    required this.body,
    required this.expanded,
    required this.onToggle,
  });

  final String body;
  final bool expanded;
  final VoidCallback onToggle;

  static const int _maxLines = 5;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(
          text: body,
          style: GoogleFonts.inter(fontSize: 15, height: 1.55),
        );
        final tp = TextPainter(
          text: span,
          maxLines: _maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final isOverflowing = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOut,
              child: Text(
                body,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.55,
                  color: scheme.onSurface.withOpacity(0.88),
                ),
                maxLines: expanded ? null : _maxLines,
                overflow:
                    expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
            if (isOverflowing) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onToggle,
                child: Text(
                  expanded ? 'Show less' : 'Read more',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CommunityDecor.lavender,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ── Post image ────────────────────────────────────────────────────────────────

class _PostImage extends StatelessWidget {
  const _PostImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              color: scheme.surfaceContainerHighest.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: CommunityDecor.lavender,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            color: scheme.surfaceContainerHighest,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.imageOff, color: scheme.outline, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    'Image unavailable',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: scheme.outline),
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

// ── Action row ────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onSave,
    required this.onShare,
  });

  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _PillAction(
          icon: LucideIcons.heart,
          label: '${post.likeCount}',
          active: post.likedByMe,
          activeColor: CommunityDecor.roseAccent,
          onTap: onLike,
        ),
        const SizedBox(width: 8),
        _PillAction(
          icon: LucideIcons.messageCircle,
          label: '${post.commentCount}',
          onTap: onComment,
        ),
        const SizedBox(width: 8),
        _PillAction(
          icon: LucideIcons.bookmark,
          label: post.savedByMe ? 'Saved' : 'Save',
          active: post.savedByMe,
          activeColor: CommunityDecor.lavender,
          onTap: onSave,
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onShare();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.onSurface.withOpacity(0.06),
            ),
            child: Icon(LucideIcons.share2,
                size: 16, color: scheme.onSurface.withOpacity(0.5)),
          ),
        ),
      ],
    );
  }
}

class _PillAction extends StatefulWidget {
  const _PillAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  @override
  State<_PillAction> createState() => _PillActionState();
}

class _PillActionState extends State<_PillAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final activeColor = widget.activeColor ?? CommunityDecor.lavender;

    final bg = widget.active
        ? activeColor.withOpacity(0.13)
        : isDark
            ? Colors.white.withOpacity(0.07)
            : const Color(0xFFF4F5F7);

    final iconColor = widget.active
        ? activeColor
        : scheme.onSurface.withOpacity(0.52);

    return ScaleTransition(
      scale: _anim,
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          _anim.reverse();
        },
        onTapUp: (_) {
          _anim.forward();
          widget.onTap();
        },
        onTapCancel: () => _anim.forward(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: widget.active
                ? Border.all(color: activeColor.withOpacity(0.28))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: iconColor),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Kept for any external references.
class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 19,
                color: filled ? c : c.withOpacity(0.75),
                fill: filled ? 1.0 : 0.0),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


