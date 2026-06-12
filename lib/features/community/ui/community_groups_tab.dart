import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../models/user_model.dart';
import '../data/community_models.dart';
import '../services/community_repository.dart';
import '../state/community_notifiers.dart';
import 'community_decor.dart';
import 'focus_room_screen.dart';
import 'group_chat_screen.dart';

class CommunityGroupsTab extends StatelessWidget {
  const CommunityGroupsTab({super.key});

  static Future<void> openCreateSheet(BuildContext context) async {
    final repo = context.read<CommunityRepository>();
    final user = context.read<UserModel>();
    final groups = context.read<GroupsNotifier>();

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    CommunityGroupType type = CommunityGroupType.study;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              final isDark = Theme.of(ctx).brightness == Brightness.dark;
              return Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2235) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: isDark
                      ? Border.all(color: Colors.white.withOpacity(0.07))
                      : null,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle pill
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        'Create a space',
                        style: GoogleFonts.inter(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF111827)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Build a circle for accountability, focus, or growth.',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 20),
                      _StyledTextField(
                          controller: nameCtrl, label: 'Name'),
                      const SizedBox(height: 12),
                      _StyledTextField(
                        controller: descCtrl,
                        label: 'Description',
                        minLines: 2,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      Text('Type',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF374151))),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          CommunityGroupType.study,
                          CommunityGroupType.focusRoom,
                          CommunityGroupType.gym,
                          CommunityGroupType.coding,
                          CommunityGroupType.recovery,
                          CommunityGroupType.general,
                        ].map((t) {
                          final selected = type == t;
                          return GestureDetector(
                            onTap: () => setModal(() => type = t),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: selected
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF7C6EE6),
                                          Color(0xFF4ECDC4)
                                        ],
                                      )
                                    : null,
                                color: selected
                                    ? null
                                    : isDark
                                        ? Colors.white.withOpacity(0.07)
                                        : const Color(0xFFF4F5F7),
                                borderRadius: BorderRadius.circular(99),
                                border: selected
                                    ? null
                                    : Border.all(
                                        color: isDark
                                            ? Colors.white12
                                            : const Color(0xFFD1D5DB)),
                              ),
                              child: Text(
                                t.label,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : isDark
                                          ? Colors.white70
                                          : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          if (!repo.isConfigured) return;
                          try {
                            await repo.ensureSession(
                                displayName: user.username);
                            await groups.createGroup(
                              name: nameCtrl.text.trim().isEmpty
                                  ? 'My group'
                                  : nameCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              type: type,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Group created',
                                      style: GoogleFonts.inter()),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFF7C6EE6),
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C6EE6), Color(0xFF4ECDC4)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF7C6EE6).withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Create space',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

  }

  static Future<void> openGroup(BuildContext context, CommunityGroup group) async {
    final repo = context.read<CommunityRepository>();
    final user = context.read<UserModel>();

    await repo.ensureSession(displayName: user.username);
    try {
      await repo.joinGroup(group.id);
    } catch (_) {
      // Already a member or RLS blocked the upsert — proceed to open the chat.
    }

    if (!context.mounted) return;

    if (group.groupType == CommunityGroupType.focusRoom) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => MultiProvider(
            providers: [
              Provider.value(value: repo),
              ChangeNotifierProvider<UserModel>.value(value: user),
              ChangeNotifierProvider(
                create: (_) => FocusRoomNotifier(repo, group.id, user.username),
              ),
            ],
            child: FocusRoomScreen(group: group),
          ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => MultiProvider(
            providers: [
              Provider.value(value: repo),
              ChangeNotifierProvider<UserModel>.value(value: user),
              ChangeNotifierProvider(
                create: (_) => GroupChatNotifier(repo, group.id, user.username),
              ),
            ],
            child: GroupChatScreen(group: group),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupsNotifier>();
    final repo = context.read<CommunityRepository>();

    if (!repo.isConfigured) return const SizedBox.shrink();

    if (groups.groups.isEmpty) {
      return const _EmptyGroupsState();
    }

    return RefreshIndicator(
      color: const Color(0xFF7C6EE6),
      onRefresh: () => groups.connect(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: groups.groups.length,
        itemBuilder: (ctx, i) {
          final g = groups.groups[i];
          return _GroupCard(
            group: g,
            index: i,
            onTap: () => openGroup(context, g),
          );
        },
      ),
    );
  }
}

// ── Group card ─────────────────────────────────────────────────────────────────

class _GroupCard extends StatefulWidget {
  const _GroupCard({
    required this.group,
    required this.index,
    required this.onTap,
  });

  final CommunityGroup group;
  final int index;
  final VoidCallback onTap;

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  IconData get _icon {
    return switch (widget.group.groupType) {
      CommunityGroupType.focusRoom => LucideIcons.timer,
      CommunityGroupType.gym => LucideIcons.dumbbell,
      CommunityGroupType.coding => LucideIcons.code2,
      CommunityGroupType.study => LucideIcons.bookOpen,
      CommunityGroupType.recovery => LucideIcons.heart,
      _ => LucideIcons.messagesSquare,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ScaleTransition(
        scale: _press,
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.selectionClick();
            _press.reverse();
          },
          onTapUp: (_) {
            _press.forward();
            widget.onTap();
          },
          onTapCancel: () => _press.forward(),
          child: Container(
            decoration: CommunityDecor.glassCard(context, radius: 22),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              CommunityDecor.groupCoverFor(widget.group.name),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF7C6EE6), Color(0xFF4ECDC4)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.25),
                                Colors.black.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                          child: Icon(_icon, color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.group.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF7C6EE6).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.group.groupType.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C6EE6),
                          ),
                        ),
                      ),
                      if (widget.group.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.group.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.4,
                            color: scheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: scheme.onSurface.withOpacity(0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
            duration: 280.ms,
            delay: Duration(milliseconds: 50 * widget.index))
        .slideY(
            begin: 0.07,
            end: 0,
            duration: 280.ms,
            curve: Curves.easeOut,
            delay: Duration(milliseconds: 50 * widget.index));
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyGroupsState extends StatelessWidget {
  const _EmptyGroupsState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7C6EE6).withOpacity(0.14),
                    const Color(0xFF4ECDC4).withOpacity(0.10),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🔵', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No spaces yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join study circles, accountability pods,\nor open a focus room.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.6,
                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

// ── Styled text field ─────────────────────────────────────────────────────────

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.label,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: isDark ? Colors.white : const Color(0xFF111827),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
          fontSize: 14,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF7C6EE6),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
