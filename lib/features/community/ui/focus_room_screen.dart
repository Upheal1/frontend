import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../models/user_model.dart';
import '../data/community_models.dart';
import '../services/community_repository.dart';
import '../state/community_notifiers.dart';
import 'community_decor.dart';
import 'group_chat_screen.dart';

class FocusRoomScreen extends StatefulWidget {
  const FocusRoomScreen({super.key, required this.group});

  final CommunityGroup group;

  @override
  State<FocusRoomScreen> createState() => _FocusRoomScreenState();
}

class _FocusRoomScreenState extends State<FocusRoomScreen> {
  List<CommunityProfile> _members = const [];

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = context.read<CommunityRepository>();
      final focus = context.read<FocusRoomNotifier>();
      await focus.connect();
      final mem = await repo.fetchMembers(widget.group.id);
      if (mounted) setState(() => _members = mem);
    });
  }

  Future<void> _openChat() async {
    final repo = context.read<CommunityRepository>();
    final user = context.read<UserModel>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MultiProvider(
          providers: [
            Provider.value(value: repo),
            ChangeNotifierProvider<UserModel>.value(value: user),
            ChangeNotifierProvider(
              create: (_) => GroupChatNotifier(repo, widget.group.id, user.username),
            ),
          ],
          child: GroupChatScreen(group: widget.group),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusRoomNotifier>();
    final scheme = Theme.of(context).colorScheme;

    final phaseLabel = switch (focus.state?.phase ?? FocusPhase.idle) {
      FocusPhase.idle => 'Ready when you are',
      FocusPhase.focus => 'Deep focus',
      FocusPhase.breakPhase => 'Gentle break',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          TextButton.icon(
            onPressed: _openChat,
            icon: const Icon(LucideIcons.messagesSquare, size: 18),
            label: Text('Chat', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: CommunityDecor.calmBackdrop(context)),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Ink(
              decoration: CommunityDecor.glassCard(context, radius: 28),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    phaseLabel,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    focus.state == null ||
                            focus.state!.phase == FocusPhase.idle ||
                            focus.remaining == Duration.zero
                        ? '25:00'
                        : _fmt(focus.remaining),
                    style: GoogleFonts.inter(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Synchronized Pomodoro · everyone sees the same rhythm',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.35,
                      color: scheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => focus.setPhase(FocusPhase.focus),
                        icon: const Icon(LucideIcons.play),
                        label: Text('Start focus', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => focus.setPhase(FocusPhase.breakPhase),
                        icon: const Icon(LucideIcons.coffee),
                        label: Text('Break', style: GoogleFonts.inter()),
                      ),
                      TextButton.icon(
                        onPressed: () => focus.setPhase(FocusPhase.idle),
                        icon: const Icon(LucideIcons.square),
                        label: Text('Pause', style: GoogleFonts.inter()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Participants (${_members.length})',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ..._members.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: scheme.surfaceContainerHighest.withOpacity(0.35),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      CommunityDecor.avatarFor(m.displayName),
                    ),
                  ),
                  title: Text(m.displayName, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Lv ${m.level} · ${m.streakDays}d streak · ${m.reputation} rep',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  trailing: Icon(
                    LucideIcons.circle,
                    size: 12,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Group focus streaks can mirror your personal streak — celebrate small wins.',
              style: GoogleFonts.inter(
                height: 1.45,
                fontSize: 13,
                color: scheme.onSurface.withOpacity(0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
