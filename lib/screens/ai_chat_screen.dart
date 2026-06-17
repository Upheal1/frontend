import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/navigation_model.dart';
import '../models/user_model.dart';
import '../services/ai_chat_service.dart';

/// Upheal-style AI companion chat: warm bubbles, typing indicator, quick replies.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

enum _MsgKind { user, assistant, system }

class _ChatMessage {
  _ChatMessage({
    required this.kind,
    required this.text,
    required this.time,
    this.crisis = false,
  });

  final _MsgKind kind;
  final String text;
  final DateTime time;
  final bool crisis;
}

class _AiChatScreenState extends State<AiChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  final List<_ChatMessage> _messages = [];
  final List<Map<String, String>> _apiHistory = [];

  bool _loading = false;
  bool _typing = false;
  int _userSendCount = 0;
  bool _sessionXpAwarded = false;
  List<String>? _quickReplies;

  static const _bg = Color(0xFFFAFAF8);
  static const _userBubble = Color(0xFFE8F4F8);
  static const _userText = Color(0xFF0E7490);
  static const _mountain = Color(0xFF4A5565);
  static const _muted = Color(0xFF7C8496);
  static const _sage = Color(0xFF6BA88A);
  static const _teal = Color(0xFF5A9B9B);
  static const _gold = Color(0xFFE8C547);

  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    _controller.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  bool _crisisHit(String text) {
    final lower = text.toLowerCase();
    return RegExp(
      r'suicid|kill myself|self[- ]harm|end my life|hurt myself|want to die',
      caseSensitive: false,
    ).hasMatch(text) ||
        lower.contains("can't go on") ||
        lower.contains('cant go on');
  }

  Future<void> _send({String? preset}) async {
    final raw = preset ?? _controller.text;
    final text = raw.trim();
    if (text.isEmpty || _loading) return;

    _controller.clear();
    _quickReplies = null;
    setState(() {
      _messages.add(
        _ChatMessage(
          kind: _MsgKind.user,
          text: text,
          time: DateTime.now(),
        ),
      );
      _userSendCount++;
      _loading = true;
      _typing = !_reduceMotion;
    });
    _scrollBottom();

    final crisis = _crisisHit(text);
    if (crisis) {
      setState(() {
        _messages.add(
          _ChatMessage(
            kind: _MsgKind.system,
            text:
                'If you are in immediate danger, contact local emergency services. Crisis support (U.S.): call or text 988. You are not alone.',
            time: DateTime.now(),
            crisis: true,
          ),
        );
      });
    }

    _apiHistory.add({'role': 'user', 'content': text});

    final typingMs = _reduceMotion ? 0 : 900;
    if (typingMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: typingMs));
    }
    if (!mounted) return;

    String reply;
    try {
      if (AiChatService.isConfigured) {
        reply = await AiChatService.sendMessage(text, _apiHistory);
      } else {
        reply = AiChatService.localFallbackReply(text);
      }
    } catch (_) {
      reply = AiChatService.localFallbackReply(text);
    }

    if (!mounted) return;

    _apiHistory.add({'role': 'assistant', 'content': reply});

    setState(() {
      _typing = false;
      _loading = false;
      _messages.add(
        _ChatMessage(
          kind: _MsgKind.assistant,
          text: reply,
          time: DateTime.now(),
        ),
      );
      _quickReplies = const [
        'Tell me more',
        'That helps',
        'I want a small next step',
      ];
    });

    if (_userSendCount >= 5 && !_sessionXpAwarded) {
      _sessionXpAwarded = true;
      final user = context.read<UserModel>();
      user.addXp(20);
      setState(() {
        _messages.add(
          _ChatMessage(
            kind: _MsgKind.system,
            text: '+20 XP — thanks for a meaningful conversation. Keep climbing.',
            time: DateTime.now(),
          ),
        );
      });
    }

    _scrollBottom();
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _apiHistory.clear();
      _userSendCount = 0;
      _sessionXpAwarded = false;
      _quickReplies = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0D12) : _bg;
    final onCard = isDark ? Colors.white : _mountain;
    final subtle = isDark ? Colors.white60 : _muted;
    final uname = context.select<UserModel, String>((u) => u.username.trim());
    final userName = uname.isEmpty ? 'there' : uname.split(RegExp(r'\s+')).first;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _ChatHeader(
            isDark: isDark,
            onCard: onCard,
            subtle: subtle,
            onMenu: (v) {
              if (v == 'clear') _clearChat();
              if (v == 'journal') {
                context.read<NavigationModel>().setIndex(9);
                Navigator.of(context).pop();
              }
              if (v == 'privacy') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Chats stay on this device unless you choose to share. I’m an AI companion, not a replacement for a licensed therapist.',
                      style: GoogleFonts.inter(),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          Expanded(
            child: _messages.isEmpty && !_typing
                ? _EmptyState(
                    userName: userName,
                    isDark: isDark,
                    onCard: onCard,
                    subtle: subtle,
                    onPick: (s) {
                      _controller.text = s;
                      _send();
                    },
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                    itemCount: _messages.length + (_typing ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_typing && i == _messages.length) {
                        return _TypingRow(
                          isDark: isDark,
                          reduceMotion: _reduceMotion,
                          controller: _dotController,
                        );
                      }
                      final m = _messages[i];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: m.kind == _MsgKind.user ? 6 : 14,
                        ),
                        child: _MessageBubble(
                          message: m,
                          isDark: isDark,
                          subtle: subtle,
                        ),
                      );
                    },
                  ),
          ),
          if (_quickReplies != null && _quickReplies!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickReplies!
                    .map(
                      (q) => ActionChip(
                        label: Text(
                          q,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        side: BorderSide(color: _sage.withValues(alpha: 0.45)),
                        backgroundColor:
                            isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                        onPressed: () => _send(preset: q),
                      ),
                    )
                    .toList(),
              ),
            ),
          _Composer(
            isDark: isDark,
            controller: _controller,
            focusNode: _focus,
            loading: _loading,
            onSend: () => _send(),
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.isDark,
    required this.onCard,
    required this.subtle,
    required this.onMenu,
  });

  final bool isDark;
  final Color onCard;
  final Color subtle;
  final void Function(String) onMenu;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      color: isDark ? const Color(0xFF12151A) : Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 12),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(LucideIcons.arrowLeft, color: onCard),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _AiChatScreenState._teal.withValues(alpha: 0.85),
                          _AiChatScreenState._sage.withValues(alpha: 0.9),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _AiChatScreenState._teal.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.mountainSnow,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guide',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: onCard,
                      ),
                    ),
                    Text(
                      'Your AI companion · Always here to listen',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: subtle,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Online',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: subtle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(LucideIcons.moreVertical, color: onCard),
                onSelected: onMenu,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'clear', child: Text('Clear chat')),
                  const PopupMenuItem(
                    value: 'journal',
                    child: Text('Open journal'),
                  ),
                  const PopupMenuItem(
                    value: 'privacy',
                    child: Text('Privacy & safety'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.userName,
    required this.isDark,
    required this.onCard,
    required this.subtle,
    required this.onPick,
  });

  final String userName;
  final bool isDark;
  final Color onCard;
  final Color subtle;
  final ValueChanged<String> onPick;

  static const _starters = [
    ("I'm feeling anxious about…", LucideIcons.cloudRain),
    ('I need help with focus and discipline', LucideIcons.target),
    ('I want to talk about screen habits', LucideIcons.smartphone),
    ("I'm struggling with motivation", LucideIcons.flame),
    ('I just need someone to listen', LucideIcons.heart),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Center(
          child: Icon(
            LucideIcons.sparkles,
            size: 48,
            color: _AiChatScreenState._teal.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Hi $userName, I’m here to listen.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: onCard,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share what’s on your mind, and we’ll work through it together — at your pace.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.5,
            color: subtle,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Try a starter',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: subtle,
          ),
        ),
        const SizedBox(height: 12),
        ..._starters.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: isDark ? const Color(0xFF16191F) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onPick(s.$1),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(s.$2, color: _AiChatScreenState._sage, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.$1,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: onCard,
                          ),
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, color: subtle, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.subtle,
  });

  final _ChatMessage message;
  final bool isDark;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final timeStr = TimeOfDay.fromDateTime(message.time).format(context);
    switch (message.kind) {
      case _MsgKind.system:
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: message.crisis
                  ? _AiChatScreenState._gold.withValues(alpha: 0.12)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: message.crisis
                    ? _AiChatScreenState._gold.withValues(alpha: 0.65)
                    : subtle.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              message.text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white70 : _AiChatScreenState._mountain,
              ),
            ),
          ),
        );
      case _MsgKind.user:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82,
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                color: _AiChatScreenState._userBubble,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(6),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.5,
                  color: _AiChatScreenState._userText,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: subtle.withValues(alpha: 0.65),
              ),
            ),
          ],
        );
      case _MsgKind.assistant:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: _AiChatScreenState._sage.withValues(alpha: 0.25),
              child: const Icon(LucideIcons.mountainSnow,
                  size: 16, color: _AiChatScreenState._teal),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A1F26)
                          : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        height: 1.55,
                        color: isDark ? Colors.white.withValues(alpha: 0.92) : _AiChatScreenState._mountain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: subtle.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class _TypingRow extends StatelessWidget {
  const _TypingRow({
    required this.isDark,
    required this.reduceMotion,
    required this.controller,
  });

  final bool isDark;
  final bool reduceMotion;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            _dot(0, 1),
            _dot(1, 1),
            _dot(2, 1),
          ],
        ),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _dot(0, (controller.value + 0) % 1.0),
              _dot(1, (controller.value + 0.2) % 1.0),
              _dot(2, (controller.value + 0.4) % 1.0),
            ],
          ),
        );
      },
    );
  }

  Widget _dot(int i, double phase) {
    final t = math.sin(phase * 2 * math.pi) * 0.5 + 0.5;
    return Padding(
      padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
      child: Opacity(
        opacity: 0.35 + 0.65 * t,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _AiChatScreenState._sage,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.isDark,
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onSend,
  });

  final bool isDark;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08);
    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      color: isDark ? const Color(0xFF12151A) : Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Focus(
                  onFocusChange: (_) {},
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 5,
                    enabled: !loading,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Share what’s on your mind…',
                      hintStyle: GoogleFonts.inter(
                        color: isDark ? Colors.white38 : _AiChatScreenState._muted,
                      ),
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF1A1F26) : const Color(0xFFFAFAF8),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: _AiChatScreenState._teal,
                          width: 1.4,
                        ),
                      ),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 1.45,
                      color: isDark ? Colors.white : _AiChatScreenState._mountain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, val, _) {
                  final has = val.text.trim().isNotEmpty;
                  final active = has || loading;
                  return SizedBox(
                    width: 48,
                    height: 48,
                    child: FilledButton(
                      onPressed: (!active || loading)
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              onSend();
                            },
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: active
                            ? _AiChatScreenState._teal
                            : (isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
                        foregroundColor:
                            active ? Colors.white : _AiChatScreenState._muted,
                        shape: const CircleBorder(),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.send, size: 20),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
