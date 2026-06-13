import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../data/community_models.dart';
import '../services/community_repository.dart';
import '../state/community_notifiers.dart';
import 'community_decor.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key, required this.group});

  final CommunityGroup group;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  Timer? _typingDebounce;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chat = context.read<GroupChatNotifier>();
      await chat.connect();
      if (!mounted) return;
      final repo = context.read<CommunityRepository>();
      final ids = chat.messages.map((m) => m.id);
      unawaited(repo.markMessagesRead(ids));
    });
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onTextChanged(GroupChatNotifier chat, String v) {
    _typingDebounce?.cancel();
    unawaited(chat.onTypingChanged(true));
    _typingDebounce = Timer(const Duration(milliseconds: 600), () {
      unawaited(chat.onTypingChanged(false));
    });
  }

  Future<void> _send(GroupChatNotifier chat) async {
    final t = _text.text.trim();
    if (t.isEmpty || _sending) return;
    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    await chat.onTypingChanged(false);

    try {
      await chat.send(t);
      if (!mounted) return;
      _text.clear();
      setState(() => _sending = false);
      if (_scroll.hasClients) {
        unawaited(
          _scroll.animateTo(
            _scroll.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message failed to send.',
              style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickImage(GroupChatNotifier chat) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (file != null) await chat.sendImage(file);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<GroupChatNotifier>();
    final repo = context.read<CommunityRepository>();
    final scheme = Theme.of(context).colorScheme;
    final myId = repo.currentUserId;

    final typingOthers = chat.typingUserIds.keys.where((id) => id != myId).length;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            Text(
              '${chat.members.length} members · ${chat.onlinePresenceCount} online',
              style: GoogleFonts.inter(fontSize: 11, color: scheme.onSurface.withOpacity(0.65)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Members',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (ctx) => Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: CommunityDecor.glassCard(ctx),
                  child: ListView(
                    shrinkWrap: true,
                    children: chat.members
                        .map(
                          (m) => ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                CommunityDecor.avatarFor(m.displayName),
                              ),
                            ),
                            title: Text(m.displayName, style: GoogleFonts.inter()),
                            subtitle: Text(
                              'Lv ${m.level} · ${m.streakDays}d streak',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
            icon: const Icon(LucideIcons.users),
          ),
        ],
      ),
      body: Column(
        children: [
          if (typingOthers > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Someone is typing…',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: scheme.primary,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              itemCount: chat.messages.length,
              itemBuilder: (ctx, i) {
                final m = chat.messages[i];
                final mine = m.senderId == myId;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18).copyWith(
                        bottomRight: mine ? const Radius.circular(4) : null,
                        bottomLeft: !mine ? const Radius.circular(4) : null,
                      ),
                      color: mine
                          ? scheme.primary.withOpacity(0.35)
                          : scheme.surfaceContainerHighest.withOpacity(0.65),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!mine)
                          Text(
                            m.sender.displayName,
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        if (m.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              m.imageUrl!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (m.body.isNotEmpty)
                          Text(
                            m.body,
                            style: GoogleFonts.inter(height: 1.35),
                          ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: ['👍', '❤️', '🔥'].map((emoji) {
                            final count = m.reactions[emoji] ?? 0;
                            return ActionChip(
                              visualDensity: VisualDensity.compact,
                              label: Text('$emoji ${count > 0 ? count : ''}'.trim()),
                              onPressed: () => chat.react(m.id, emoji),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Material(
                elevation: 10,
                color: scheme.surface.withOpacity(0.96),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _pickImage(chat),
                        icon: const Icon(LucideIcons.imagePlus),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _text,
                          onChanged: (v) => _onTextChanged(chat, v),
                          minLines: 1,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Message ${widget.group.name}…',
                            filled: true,
                            fillColor: scheme.surfaceContainerHighest.withOpacity(0.4),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: (_text.text.trim().isEmpty || _sending)
                              ? null
                              : CommunityDecor.fabGradient,
                          color: (_text.text.trim().isEmpty || _sending)
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.08)
                                  : const Color(0xFFE5E7EB))
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: (_text.text.trim().isEmpty || _sending)
                                ? null
                                : () => _send(chat),
                            customBorder: const CircleBorder(),
                            child: Center(
                              child: _sending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      LucideIcons.send,
                                      size: 18,
                                      color: (_text.text.trim().isEmpty)
                                          ? (Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white38
                                              : const Color(0xFF9CA3AF))
                                          : Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
