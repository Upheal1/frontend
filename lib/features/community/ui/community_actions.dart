import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../constants/app_colors.dart';
import '../data/community_models.dart';

/// 3-dot overflow menu for a post.  Only shows Edit/Delete when the current
/// user owns the post (controlled via [isOwner]).
class PostActionMenu extends StatelessWidget {
  const PostActionMenu({
    super.key,
    required this.isOwner,
    this.onEdit,
    this.onDelete,
  });

  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (!isOwner) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert,
          size: 18,
          color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
        ),
        onSelected: (value) {
          if (value == 'edit') onEdit?.call();
          if (value == 'delete') onDelete?.call();
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(LucideIcons.pencil, size: 16, color: AppColors.purple),
                const SizedBox(width: 10),
                Text('Edit', style: GoogleFonts.inter(fontSize: 14)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(LucideIcons.trash2, size: 16, color: AppColors.red),
                const SizedBox(width: 10),
                Text('Delete',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 3-dot overflow menu for a comment.  Only shows Edit/Delete when the current
/// user owns the comment (controlled via [isOwner]).
class CommentActionMenu extends StatelessWidget {
  const CommentActionMenu({
    super.key,
    required this.isOwner,
    this.onEdit,
    this.onDelete,
  });

  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (!isOwner) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert,
          size: 15,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white24
              : const Color(0xFF9CA3AF),
        ),
        onSelected: (value) {
          if (value == 'edit') onEdit?.call();
          if (value == 'delete') onDelete?.call();
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(LucideIcons.pencil, size: 14, color: AppColors.purple),
                const SizedBox(width: 8),
                Text('Edit', style: GoogleFonts.inter(fontSize: 13)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(LucideIcons.trash2, size: 14, color: AppColors.red),
                const SizedBox(width: 8),
                Text('Delete',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for editing a post's body text.
class EditPostSheet extends StatefulWidget {
  const EditPostSheet({
    super.key,
    required this.currentBody,
    required this.onSave,
  });

  final String currentBody;
  final Future<void> Function(String newBody) onSave;

  @override
  State<EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<EditPostSheet> {
  late final TextEditingController _controller;
  late bool _hasText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentBody);
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(
        () => setState(() => _hasText = _controller.text.trim().isNotEmpty));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Edit post',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.x,
                        size: 18,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 8,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Write something...',
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF232636).withValues(alpha: 0.6)
                    : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _hasText && !_saving ? _save : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: _hasText
                            ? const LinearGradient(colors: [
                                Color(0xFF8A6CF6),
                                Color(0xFF14B8A6),
                              ])
                            : null,
                        color: _hasText
                            ? null
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(
                                'Save',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: _hasText
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white24
                                          : const Color(0xFF9CA3AF)),
                                ),
                              ),
                      ),
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

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text == widget.currentBody.trim()) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save. Try again.',
              style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Bottom sheet for editing a comment's body text.
class EditCommentSheet extends StatefulWidget {
  const EditCommentSheet({
    super.key,
    required this.currentBody,
    required this.onSave,
  });

  final String currentBody;
  final Future<void> Function(String newBody) onSave;

  @override
  State<EditCommentSheet> createState() => _EditCommentSheetState();
}

class _EditCommentSheetState extends State<EditCommentSheet> {
  late final TextEditingController _controller;
  late bool _hasText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentBody);
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(
        () => setState(() => _hasText = _controller.text.trim().isNotEmpty));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Edit comment',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.x,
                        size: 18,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 6,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Edit your comment...',
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF232636).withValues(alpha: 0.6)
                    : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _hasText && !_saving ? _save : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: _hasText
                            ? const LinearGradient(colors: [
                                Color(0xFF8A6CF6),
                                Color(0xFF14B8A6),
                              ])
                            : null,
                        color: _hasText
                            ? null
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(
                                'Save',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: _hasText
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white24
                                          : const Color(0xFF9CA3AF)),
                                ),
                              ),
                      ),
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

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text == widget.currentBody.trim()) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save. Try again.',
              style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Horizontal scrollable filter chip row for the community feed.
class CommunityFilterChips extends StatelessWidget {
  const CommunityFilterChips({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final CommunityPostFilter current;
  final ValueChanged<CommunityPostFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentGradient = LinearGradient(colors: [
      Color(0xFF5B7CFA),
      Color(0xFF8A6CF6),
      Color(0xFFB07BF5),
    ]);

    final filters = [
      (CommunityPostFilter.all, 'All Posts'),
      (CommunityPostFilter.myPosts, 'My Posts'),
      (CommunityPostFilter.newest, 'Newest'),
      (CommunityPostFilter.mostLiked, 'Most Liked'),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final selected = current == f.$1;
          return GestureDetector(
            onTap: () => onChanged(f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                gradient: selected ? accentGradient : null,
                color: selected
                    ? null
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : const Color(0xFFF3F4F6)),
                borderRadius: BorderRadius.circular(999),
                border: selected
                    ? null
                    : Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFFE5E7EB),
                      ),
              ),
              child: Center(
                child: Text(
                  f.$2,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : (isDark
                            ? Colors.white54
                            : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
