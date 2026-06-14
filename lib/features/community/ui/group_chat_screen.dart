import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/upheal_home_theme.dart';
import '../../../shared/widgets/upheal_home_widgets.dart';
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
  final Set<String> _seenIds = {};
  bool _initialLoadDone = false;

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
      _initialLoadDone = true;
      for (final m in chat.messages) _seenIds.add(m.id);
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
    final file =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (file != null) await chat.sendImage(file);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<GroupChatNotifier>();
    final repo = context.read<CommunityRepository>();
    final tokens = Theme.of(context).upHealHome;
    final myId = repo.currentUserId;

    final typingOthers =
        chat.typingUserIds.keys.where((id) => id != myId).length;

    return UpHealScaffold(
      body: Column(
        children: [
          _buildHeader(tokens, chat),
          Expanded(
            child: _buildMessageList(chat, myId, tokens, typingOthers),
          ),
          _buildComposer(chat, tokens),
        ],
      ),
    );
  }

  Widget _buildHeader(UpHealHomeTheme tokens, GroupChatNotifier chat) {
    final members = chat.members;
    final displayCount = members.length > 3 ? 3 : members.length;
    final overflow = members.length - displayCount;

    return SafeArea(
      bottom: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(4, tokens.space8, tokens.space12, tokens.space12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: tokens.dividerColor),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(LucideIcons.chevronLeft, color: tokens.primaryText),
              onPressed: () => Navigator.maybePop(context),
              tooltip: 'Back',
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: tokens.primaryText,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    '${members.length} members \u00b7 ${chat.onlinePresenceCount} online',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: tokens.faintText,
                    ),
                  ),
                ],
              ),
            ),
            if (members.isNotEmpty)
              SizedBox(
                height: 28,
                child: Stack(
                  children: [
                    for (int i = 0; i < displayCount; i++)
                      Positioned(
                        left: i * 18.0,
                        top: 0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: tokens.cardFill,
                          backgroundImage: NetworkImage(
                            CommunityDecor.avatarFor(members[i].displayName),
                          ),
                        ),
                      ),
                    if (overflow > 0)
                      Positioned(
                        left: displayCount * 18.0,
                        top: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: tokens.quickGroupsChip,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '+$overflow',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: tokens.quickGroupsIcon,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            SizedBox(width: tokens.space8),
            IconButton(
              tooltip: 'Members',
              onPressed: () => _showMembersSheet(chat, tokens),
              icon: Icon(LucideIcons.users, color: tokens.secondaryText, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _showMembersSheet(GroupChatNotifier chat, UpHealHomeTheme tokens) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.all(tokens.space16),
        decoration: CommunityDecor.glassCard(ctx),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.6,
        ),
        child: ListView(
          shrinkWrap: true,
          children: chat.members
              .map(
                (m) => ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(
                      CommunityDecor.avatarFor(m.displayName),
                    ),
                  ),
                  title: Text(
                    m.displayName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: tokens.primaryText,
                    ),
                  ),
                  subtitle: Text(
                    'Lv ${m.level} \u00b7 ${m.streakDays}d streak',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: tokens.faintText,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMessageList(
    GroupChatNotifier chat,
    String? myId,
    UpHealHomeTheme tokens,
    int typingOthers,
  ) {
    final msgs = chat.messages;

    // Track new message IDs for animation
    if (_initialLoadDone) {
      for (final m in msgs) _seenIds.add(m.id);
    }

    // Build grouped message list
    final groups = _groupMessages(msgs, myId);

    return ListView.builder(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(tokens.space12, tokens.space12, tokens.space12, tokens.space12),
      itemCount: groups.length,
      itemBuilder: (ctx, gi) {
        final group = groups[gi];

        if (group.isDateSep) {
          return _buildDateSeparator(group.dateSepLabel!, tokens);
        }

        final msgs = group.messages!;
        final isMe = group.isMe!;
        final firstMsg = msgs.first;
        final lastMsg = msgs.last;
        final showSender = !isMe && msgs.first.senderId == msgs.first.senderId;

        final isNew = !_seenIds.contains(firstMsg.id) && _initialLoadDone;
        final animChild = _buildBubbleGroup(
          msgs, isMe, firstMsg, lastMsg, tokens, myId,
          showAvatar: showSender,
        );

        if (isNew) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: animChild,
          );
        }
        return animChild;
      },
    );
  }

  Widget _buildDateSeparator(String label, UpHealHomeTheme tokens) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.space16),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: tokens.space16, vertical: 6),
          decoration: BoxDecoration(
            color: tokens.cardFill,
            borderRadius: BorderRadius.circular(tokens.pillRadius),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tokens.faintText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubbleGroup(
    List<GroupChatMessage> msgs,
    bool isMe,
    GroupChatMessage firstMsg,
    GroupChatMessage lastMsg,
    UpHealHomeTheme tokens,
    String? myId, {
    bool showAvatar = true,
  }) {
    final otherAvatar = !isMe && showAvatar;

    return Padding(
      padding: EdgeInsets.only(
        bottom: tokens.space8,
        left: isMe ? tokens.space20 : 0,
        right: isMe ? 0 : tokens.space20,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (otherAvatar)
            Padding(
              padding: EdgeInsets.only(right: tokens.space8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: tokens.cardFill,
                backgroundImage: NetworkImage(
                  CommunityDecor.avatarFor(firstMsg.sender.displayName),
                ),
              ),
            ),
          if (otherAvatar) const SizedBox(width: 0) else const Spacer(),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && showAvatar)
                  Padding(
                    padding: EdgeInsets.only(
                      left: 4,
                      bottom: 4,
                    ),
                    child: Text(
                      firstMsg.sender.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.navActive,
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < msgs.length; i++)
                      _buildSingleBubble(
                        msgs[i],
                        isMe,
                        tokens,
                        isFirst: i == 0,
                        isLast: i == msgs.length - 1,
                        single: msgs.length == 1,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBubble(
    GroupChatMessage m,
    bool isMe,
    UpHealHomeTheme tokens, {
    bool isFirst = false,
    bool isLast = false,
    bool single = false,
  }) {
    final borderRadius = BorderRadius.circular(18).copyWith(
      bottomRight: isMe && !single && isLast
          ? const Radius.circular(4)
          : null,
      bottomLeft: !isMe && !single && isLast
          ? const Radius.circular(4)
          : null,
      topRight: isMe && !single && isFirst
          ? const Radius.circular(18)
          : null,
      topLeft: !isMe && !single && isFirst
          ? const Radius.circular(18)
          : null,
    );

    // Tight spacing within group
    final marginBottom = isLast ? 0.0 : 3.0;

    return Container(
      margin: EdgeInsets.only(bottom: marginBottom),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.space12,
              vertical: tokens.space8,
            ),
            decoration: BoxDecoration(
              gradient: isMe
                  ? UpHealHomeTheme.sharedAccentGradient
                  : null,
              color: isMe ? null : tokens.cardFill,
              borderRadius: borderRadius,
              border: isMe ? null : Border.all(color: tokens.cardBorder),
              boxShadow: isMe
                  ? const <BoxShadow>[]
                  : (tokens.cardShadow != null
                      ? <BoxShadow>[tokens.cardShadow!]
                      : const <BoxShadow>[]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (m.imageUrl != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: m.body.isNotEmpty ? 8.0 : 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        m.imageUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                if (m.body.isNotEmpty)
                  Text(
                    m.body,
                    style: GoogleFonts.inter(
                      height: 1.4,
                      color: isMe ? Colors.white : tokens.primaryText,
                      fontSize: 14,
                    ),
                  ),
                if (m.reactions.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: m.reactions.entries.map((e) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.15)
                                : tokens.quickGroupsChip,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${e.key} ${e.value > 0 ? e.value : ''}'.trim(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isMe ? Colors.white70 : tokens.quickGroupsIcon,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          if (isLast)
            Padding(
              padding: EdgeInsets.only(
                top: 2,
                left: isMe ? 0 : 4,
                right: isMe ? 4 : 0,
              ),
              child: Text(
                _formatTime(m.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: tokens.faintText,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_MessageGroup> _groupMessages(List<GroupChatMessage> msgs, String? myId) {
    if (msgs.isEmpty) return [];

    final List<_MessageGroup> groups = [];

    // Insert date separators and group by sender
    String? lastDateStr;
    List<GroupChatMessage> currentGroup = [];

    for (final m in msgs) {
      final dateStr = _dateKey(m.createdAt);

      if (lastDateStr != null && dateStr != lastDateStr) {
        // Close current group
        if (currentGroup.isNotEmpty) {
          groups.add(_MessageGroup(messages: currentGroup, isMe: currentGroup.first.senderId == myId));
          currentGroup = [];
        }
        groups.add(_MessageGroup(isDateSep: true, dateSepLabel: _dateLabel(DateTime.parse(lastDateStr))));
        lastDateStr = dateStr;
        currentGroup = [m];
        continue;
      }

      if (lastDateStr == null) {
        lastDateStr = dateStr;
        currentGroup = [m];
        continue;
      }

      // Same date — check sender continuity
      final lastSenderId = currentGroup.last.senderId;
      if (m.senderId == lastSenderId) {
        currentGroup.add(m);
      } else {
        groups.add(_MessageGroup(messages: currentGroup, isMe: currentGroup.first.senderId == myId));
        currentGroup = [m];
      }
    }

    if (currentGroup.isNotEmpty) {
      groups.add(_MessageGroup(messages: currentGroup, isMe: currentGroup.first.senderId == myId));
    }

    return groups;
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${dt.day} ${_monthAbbr(dt.month)}';
    return '${dt.day} ${_monthAbbr(dt.month)} ${dt.year}';
  }

  String _monthAbbr(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[m - 1];
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h12:$min $period';
  }

  Widget _buildComposer(GroupChatNotifier chat, UpHealHomeTheme tokens) {
    final isEmpty = _text.text.trim().isEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(tokens.space12, tokens.space8, tokens.space12, tokens.space12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: tokens.dividerColor),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => _pickImage(chat),
                icon: Icon(LucideIcons.imagePlus, color: tokens.secondaryText, size: 22),
                tooltip: 'Attach image',
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: tokens.cardFill,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: tokens.cardBorder),
                  ),
                  child: TextField(
                    controller: _text,
                    onChanged: (v) => _onTextChanged(chat, v),
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    style: GoogleFonts.inter(
                      color: tokens.primaryText,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Message ${widget.group.name}\u2026',
                      hintStyle: GoogleFonts.inter(
                        color: tokens.faintText,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: tokens.space16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (isEmpty || _sending)
                      ? null
                      : UpHealHomeTheme.sharedAccentGradient,
                  color: (isEmpty || _sending)
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE5E7EB))
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (isEmpty || _sending) ? null : () => _send(chat),
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
                              color: isEmpty
                                  ? (isDark
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
    );
  }
}

class _MessageGroup {
  final List<GroupChatMessage>? messages;
  final bool? isMe;
  final bool isDateSep;
  final String? dateSepLabel;

  _MessageGroup({
    this.messages,
    this.isMe,
    this.isDateSep = false,
    this.dateSepLabel,
  });
}
