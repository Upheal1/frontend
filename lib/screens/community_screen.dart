import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/auth_model.dart';
import '../models/journal_model.dart';
import '../models/user_model.dart';
import '../widgets/drawer_menu_button.dart';

/// Upheal-style Community: Feed + Support Groups, warm palette.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _tab = 0; // 0 Feed, 1 Groups
  final List<_FeedPost> _myShared = [];

  static const _bg = Color(0xFFFAFAF8);
  static const _title = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _sky = Color(0xFF38BDF8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<JournalModel>().loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0D12) : _bg;
    final card = isDark ? const Color(0xFF16191F) : Colors.white;
    final onCard = isDark ? Colors.white : _title;
    final subtle = isDark ? Colors.white60 : _muted;

    final authName = context.select<AuthModel, String?>((a) => a.userName);
    final userName = context.select<UserModel, String>((u) => u.username);
    final level = context.select<UserModel, int>((u) => u.level);
    final journalCount = context.select<JournalModel, int>((j) => j.entries.length);
    final rawName = (authName ?? userName).trim();
    final firstName = rawName.isEmpty
        ? 'Traveler'
        : rawName.split(RegExp(r'\s+')).first;

    final baseFeed = _defaultFeed(firstName, level);
    final feed = [..._myShared, ...baseFeed];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DrawerMenuButton(
                      iconColor: isDark ? Colors.white : _title,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: onCard,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A safe space for your journey',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: subtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openShareSheet(context, firstName),
                      style: FilledButton.styleFrom(
                        backgroundColor: _sky,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: Text(
                        'Share',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: _FeedGroupsTabs(
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                  isDark: isDark,
                  onCard: onCard,
                  subtle: subtle,
                ),
              ),
            ),
            if (_tab == 0) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _KindnessBanner(
                    isDark: isDark,
                    journalCount: journalCount,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      i == feed.length - 1 ? 24 : 12,
                    ),
                    child: _PostCard(
                      post: feed[i],
                      card: card,
                      isDark: isDark,
                      onCard: onCard,
                      subtle: subtle,
                    ),
                  ),
                  childCount: feed.length,
                ),
              ),
            ] else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'SUPPORT GROUPS',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: subtle,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_supportGroups.length} available',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: subtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      i == _supportGroups.length - 1 ? 28 : 10,
                    ),
                    child: _GroupCard(
                      group: _supportGroups[i],
                      card: card,
                      isDark: isDark,
                      onCard: onCard,
                      subtle: subtle,
                    ),
                  ),
                  childCount: _supportGroups.length,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openShareSheet(BuildContext context, String name) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 16 + bottom,
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
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share with the community',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 4,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: 'What’s on your heart today?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  final t = controller.text.trim();
                  if (t.isEmpty) return;
                  setState(() {
                    _myShared.insert(
                      0,
                      _FeedPost(
                        name: name,
                        badge: 'Trail Blazer',
                        timeLabel: 'Just now',
                        dayLabel: 'Today',
                        tag: '#Reflection',
                        body: t,
                        likes: 0,
                        comments: 0,
                        emoji: '🌿',
                        isYours: true,
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Thanks for sharing — your post is live on the feed.',
                        style: GoogleFonts.inter(),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _sky,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Post',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_FeedPost> _defaultFeed(String you, int level) {
    return [
      _FeedPost(
        name: 'Mia K.',
        badge: 'Summit Seeker',
        timeLabel: '2h ago',
        dayLabel: 'Day 31',
        tag: '#Anxiety',
        body:
            'Had a rough morning but did the breathing exercise from Journey — felt a little more grounded. Small win 🏕️',
        likes: 24,
        comments: 6,
        emoji: '🧘',
      ),
      _FeedPost(
        name: 'Jordan',
        badge: 'Trail Blazer',
        timeLabel: '5h ago',
        dayLabel: 'Day 12',
        tag: '#Focus',
        body:
            'Phone-free hour before bed for three nights now. Sleep feels… lighter? Grateful for this group.',
        likes: 41,
        comments: 9,
        emoji: '🙏',
      ),
      _FeedPost(
        name: you,
        badge: _levelBadgeLabel(level),
        timeLabel: 'Yesterday',
        dayLabel: 'Day 8',
        tag: '#Motivation',
        body:
            'Re-reading my journal from last week — didn’t realize how far I’d come. Progress, not perfection.',
        likes: 18,
        comments: 4,
        emoji: '📓',
        isYours: true,
      ),
    ];
  }

  static String _levelBadgeLabel(int level) {
    if (level <= 5) return 'Base Camp Explorer';
    if (level <= 10) return 'Trail Blazer';
    if (level <= 20) return 'Mountain Guide';
    if (level <= 30) return 'Summit Seeker';
    return 'Peak Master';
  }
}

class _FeedPost {
  _FeedPost({
    required this.name,
    required this.badge,
    required this.timeLabel,
    required this.dayLabel,
    required this.tag,
    required this.body,
    required this.likes,
    required this.comments,
    required this.emoji,
    this.isYours = false,
  });

  final String name;
  final String badge;
  final String timeLabel;
  final String dayLabel;
  final String tag;
  final String body;
  final int likes;
  final int comments;
  final String emoji;
  final bool isYours;
}

class _SupportGroup {
  const _SupportGroup({
    required this.title,
    required this.members,
    required this.activeNow,
    required this.icon,
    required this.iconBg,
    required this.tags,
  });

  final String title;
  final String members;
  final String activeNow;
  final IconData icon;
  final Color iconBg;
  final List<_GroupTag> tags;
}

class _GroupTag {
  const _GroupTag(this.label, this.color, this.fg);
  final String label;
  final Color color;
  final Color fg;
}

final List<_SupportGroup> _supportGroups = [
  _SupportGroup(
    title: 'Anxiety & Calm',
    members: '2,340',
    activeNow: '45',
    icon: LucideIcons.waves,
    iconBg: const Color(0xFFE0F2FE),
    tags: [
      _GroupTag('Most active', const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
    ],
  ),
  _SupportGroup(
    title: 'Focus & Flow',
    members: '1,892',
    activeNow: '32',
    icon: LucideIcons.target,
    iconBg: const Color(0xFFE8F8EF),
    tags: [
      _GroupTag('Trending', const Color(0xFFFEF9C3), const Color(0xFF854D0E)),
    ],
  ),
  _SupportGroup(
    title: 'Screen Detox',
    members: '3,102',
    activeNow: '58',
    icon: LucideIcons.smartphone,
    iconBg: const Color(0xFFF3E8FF),
    tags: [
      _GroupTag('Your group', const Color(0xFFD1FAE5), const Color(0xFF166534)),
    ],
  ),
  _SupportGroup(
    title: 'Sleep & Wind-down',
    members: '1,410',
    activeNow: '21',
    icon: LucideIcons.moon,
    iconBg: const Color(0xFFEEF2FF),
    tags: [],
  ),
  _SupportGroup(
    title: 'Motivation Circle',
    members: '2,756',
    activeNow: '40',
    icon: LucideIcons.flame,
    iconBg: const Color(0xFFFFF4E6),
    tags: [
      _GroupTag('Trending', const Color(0xFFFEF9C3), const Color(0xFF854D0E)),
    ],
  ),
  _SupportGroup(
    title: 'Parents & Caregivers',
    members: '980',
    activeNow: '14',
    icon: LucideIcons.heart,
    iconBg: const Color(0xFFFFE4E6),
    tags: [],
  ),
];

class _FeedGroupsTabs extends StatelessWidget {
  const _FeedGroupsTabs({
    required this.selected,
    required this.onChanged,
    required this.isDark,
    required this.onCard,
    required this.subtle,
  });

  final int selected;
  final ValueChanged<int> onChanged;
  final bool isDark;
  final Color onCard;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final track = isDark ? const Color(0xFF1E2329) : const Color(0xFFEEF1F4);
    final tabs = [
      (LucideIcons.messageCircle, 'Feed'),
      (LucideIcons.users, 'Groups'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: List.generate(2, (i) {
          final sel = selected == i;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel
                      ? (isDark ? const Color(0xFF2A3038) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tabs[i].$1,
                      size: 18,
                      color: sel ? const Color(0xFF7C3AED) : subtle,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tabs[i].$2,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                        color: sel ? onCard : subtle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _KindnessBanner extends StatelessWidget {
  const _KindnessBanner({
    required this.isDark,
    required this.journalCount,
  });

  final bool isDark;
  final int journalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E3A3A),
                  const Color(0xFF134E4A),
                ]
              : [
                  const Color(0xFFB2DFDB).withValues(alpha: 0.85),
                  const Color(0xFF86EFAC).withValues(alpha: 0.55),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text('🌱', style: GoogleFonts.inter(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your words matter here',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF134E4A),
                  ),
                ),
                Text(
                  journalCount > 0
                      ? 'Be supportive • Be kind • Be real — you’ve written $journalCount journal entries on your journey.'
                      : 'Be supportive • Be kind • Be real',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.85)
                        : const Color(0xFF14532D).withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.trendingUp,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : const Color(0xFF14532D).withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.card,
    required this.isDark,
    required this.onCard,
    required this.subtle,
  });

  final _FeedPost post;
  final Color card;
  final bool isDark;
  final Color onCard;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE0F2FE),
                child: Text(
                  post.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: onCard,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            post.badge,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0369A1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${post.timeLabel} · ${post.dayLabel}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: subtle,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.bookmark, size: 20, color: subtle),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              post.tag,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: subtle,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            post.body,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: onCard,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(LucideIcons.heart, size: 18, color: subtle),
              const SizedBox(width: 4),
              Text(
                '${post.likes}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subtle,
                ),
              ),
              const SizedBox(width: 16),
              Icon(LucideIcons.messageCircle, size: 18, color: subtle),
              const SizedBox(width: 4),
              Text(
                '${post.comments}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subtle,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: onCard,
                  side: BorderSide(color: subtle.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                child: Text(
                  'Encourage 🙌',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.card,
    required this.isDark,
    required this.onCard,
    required this.subtle,
  });

  final _SupportGroup group;
  final Color card;
  final bool isDark;
  final Color onCard;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Opening ${group.title}…',
                style: GoogleFonts.inter(),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? group.iconBg.withValues(alpha: 0.25)
                        : group.iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(group.icon, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              group.title,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: onCard,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...group.tags.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: t.color,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  t.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: t.fg,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: subtle,
                          ),
                          children: [
                            TextSpan(
                              text: '${group.members} members',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const TextSpan(text: ' · '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Container(
                                width: 7,
                                height: 7,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            TextSpan(
                              text: '${group.activeNow} active now',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: subtle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
