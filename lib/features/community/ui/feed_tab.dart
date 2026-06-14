import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../data/community_models.dart';
import '../services/community_repository.dart';
import 'community_actions.dart';
import 'community_decor.dart';
import 'compose_post_screen.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  static Future<void> openCompose(BuildContext context) async {
    final repo = context.read<CommunityRepository>();
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => MultiProvider(
          providers: [
            Provider.value(value: repo),
            ChangeNotifierProvider<UserModel>.value(value: ctx.read<UserModel>()),
          ],
          child: const ComposePostScreen(),
        ),
      ),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Posted to the community', style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.purple,
        ),
      );
      // Refresh the feed after posting
      context.findAncestorStateOfType<_FeedTabState>()?._loadFeed();
    }
  }

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  late final CommunityRepository _repo;
  RealtimeChannel? _feedChannel;

  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _misconfigured = false;
  bool _isGuest = false;
  String? _error;
  List<Map<String, dynamic>> _posts = [];
  FeedCursor? _nextCursor;
  bool _loadingMore = false;
  bool _hasMore = true;
  final Set<String> _likedPostIds = {};
  CommunityPostFilter _filter = CommunityPostFilter.all;

  String? get _currentUserId => _repo.currentUserId;

  @override
  void initState() {
    super.initState();
    _repo = context.read<CommunityRepository>();
    _scrollController.addListener(_onScroll);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!_repo.isConfigured) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _misconfigured = true;
      });
      return;
    }

    try {
      await _repo.ensureSession(displayName: context.read<UserModel>().username);
    } catch (_) {
      // Session setup failed (e.g. anonymous auth disabled); continue as guest.
    }
    if (!mounted) return;
    _isGuest = _repo.currentUserId == null;
    await _loadFeed();
    await _listenForFeedUpdates();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300 && !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadFeed() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _nextCursor = null;
      _hasMore = true;
    });

    try {
      final page = await _repo.fetchPostsFeedPage();
      if (!mounted) return;
      setState(() {
        _posts = page.posts;
        _nextCursor = page.nextCursor;
        _hasMore = page.nextCursor != null;
        _loading = false;
      });
      await _loadLikedPostIds();
    } catch (e) {
      if (!mounted) return;
      debugPrint('[FeedTab] _loadFeed error: $e');

      final msg = e.toString().toLowerCase();
      final isAuthOrRls = msg.contains('42501') ||
          msg.contains('permission denied') ||
          msg.contains('row-level security') ||
          msg.contains('jwt') ||
          msg.contains('not authenticated');

      setState(() {
        _posts = [];
        _nextCursor = null;
        _hasMore = false;
        _error = isAuthOrRls ? null : e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadLikedPostIds() async {
    final uid = _repo.currentUserId;
    if (uid == null || _posts.isEmpty) return;
    try {
      final ids = _posts.map((p) => p['id'] as String).toList();
      final liked = await _repo.fetchLikedPostIds(
        userId: uid,
        postIds: ids,
      );
      if (!mounted) return;
      setState(() {
        _likedPostIds
          ..clear()
          ..addAll(liked);
      });
    } catch (e) {
      debugPrint('[FeedTab] _loadLikedPostIds error: $e');
    }
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> posts) {
    var result = List<Map<String, dynamic>>.from(posts);

    switch (_filter) {
      case CommunityPostFilter.myPosts:
        final uid = _currentUserId;
        if (uid != null) {
          result = result.where((p) => p['author_id'] == uid).toList();
        }
        break;
      case CommunityPostFilter.newest:
        result.sort((a, b) {
          final da = DateTime.tryParse(a['created_at'] as String? ?? '');
          final db = DateTime.tryParse(b['created_at'] as String? ?? '');
          return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
        });
        break;
      case CommunityPostFilter.mostLiked:
        result.sort((a, b) {
          final la = (a['likes_count'] as num?)?.toInt() ?? 0;
          final lb = (b['likes_count'] as num?)?.toInt() ?? 0;
          final cmp = lb.compareTo(la);
          if (cmp != 0) return cmp;
          final da = DateTime.tryParse(a['created_at'] as String? ?? '');
          final db = DateTime.tryParse(b['created_at'] as String? ?? '');
          return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
        });
        break;
      case CommunityPostFilter.all:
        break;
    }

    return result;
  }

  Future<void> _loadMore() async {
    if (!mounted || _loadingMore || !_hasMore || _nextCursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.fetchPostsFeedPage(after: _nextCursor);
      if (!mounted) return;
      setState(() {
        _posts = [..._posts, ...page.posts];
        _nextCursor = page.nextCursor;
        _hasMore = page.nextCursor != null;
        _loadingMore = false;
      });
      await _loadLikedPostIds();
    } catch (e) {
      if (!mounted) return;
      debugPrint('[FeedTab] _loadMore error: $e');
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _listenForFeedUpdates() async {
    try {
      _feedChannel = await _repo.subscribeToFeedUpdates(
        onNewPostAvailable: () {
          if (!mounted) return;
          // Auto-refresh instead of just showing banner
          _loadFeed();
        },
      );
    } catch (e) {
      debugPrint('[FeedTab] _listenForFeedUpdates error: $e');
    }
  }

  Future<void> _toggleLike(String postId) async {
    final uid = _repo.currentUserId;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please sign in to interact with the community.',
                style: GoogleFonts.inter()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final wasLiked = _likedPostIds.contains(postId);
    final postIdx = _posts.indexWhere((p) => p['id'] == postId);
    if (postIdx < 0) return;

    setState(() {
      if (wasLiked) {
        _likedPostIds.remove(postId);
      } else {
        _likedPostIds.add(postId);
      }
      final current = (_posts[postIdx]['likes_count'] as num?)?.toInt() ?? 0;
      _posts[postIdx]['likes_count'] = wasLiked ? (current - 1).clamp(0, 999999) : current + 1;
    });

    try {
      await _repo.toggleLike(postId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (wasLiked) {
          _likedPostIds.add(postId);
        } else {
          _likedPostIds.remove(postId);
        }
        final current = (_posts[postIdx]['likes_count'] as num?)?.toInt() ?? 0;
        _posts[postIdx]['likes_count'] = wasLiked ? current + 1 : (current - 1).clamp(0, 999999);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update like. Try again.',
              style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editPost(String postId, String currentBody) async {
    final edited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPostSheet(
        currentBody: currentBody,
        onSave: (newBody) => _repo.updatePost(
          postId: postId,
          body: newBody,
        ),
      ),
    );

    if (edited == true && mounted) {
      _loadFeed();
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete this post?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Comments and likes on this post may also be removed.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _repo.deletePost(postId);
      if (!mounted) return;
      setState(() {
        _posts.removeWhere((p) => p['id'] == postId);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete post. Try again.',
              style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _showCommentsSheet(String postId) async {
    final uid = _repo.currentUserId;
    if (uid == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please sign in to comment.',
              style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        postId: postId,
        repo: _repo,
      ),
    );

    if (added == true && mounted) {
      final postIdx = _posts.indexWhere((p) => p['id'] == postId);
      if (postIdx >= 0) {
        setState(() {
          final c = (_posts[postIdx]['comments_count'] as num?)?.toInt() ?? 0;
          _posts[postIdx]['comments_count'] = c + 1;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    final channel = _feedChannel;
    if (channel != null) {
      unawaited(_repo.removeRealtimeChannel(channel));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_misconfigured) return _MisconfiguredState();
    if (_loading) return const _ShimmerFeed();
    if (_error != null) return _ErrorState(onRetry: _loadFeed);

    final shownPosts = _applyFilter(_posts);
    final uid = _currentUserId;

    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: _loadFeed,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (_isGuest) _GuestBanner(onSignIn: () {}),
          const _SupportBanner(),
          const SizedBox(height: 12),
          CommunityFilterChips(
            current: _filter,
            onChanged: (CommunityPostFilter f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 12),
          if (shownPosts.isEmpty && _posts.isNotEmpty)
            _FilterEmptyState(filter: _filter)
          else if (shownPosts.isEmpty)
            const _EmptyFeedState()
          else
            for (var i = 0; i < shownPosts.length; i++) ...[
              _FeedPostCard(
                post: shownPosts[i],
                index: i,
                liked: _likedPostIds.contains(shownPosts[i]['id']),
                currentUserId: uid,
                onLike: () => _toggleLike(shownPosts[i]['id'] as String),
                onComment: () =>
                    _showCommentsSheet(shownPosts[i]['id'] as String),
                onPostEdit: () => _editPost(
                  shownPosts[i]['id'] as String,
                  (shownPosts[i]['content'] as String? ?? ''),
                ),
                onPostDelete: () =>
                    _deletePost(shownPosts[i]['id'] as String),
              ),
            ],
          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ),
          if (!_hasMore && shownPosts.isNotEmpty) const _CaughtUpFooter(),
        ],
      ),
    );
  }
}

// ── Shimmer loading skeleton ──────────────────────────────────────────────────

class _ShimmerFeed extends StatelessWidget {
  const _ShimmerFeed();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF232636) : const Color(0xFFEEEFF4);
    final highlight = isDark ? const Color(0xFF2C3050) : const Color(0xFFF8F9FF);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: 4,
        itemBuilder: (_, __) => _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark ? const Color(0xFF2C3050) : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBox(width: 46, height: 46, radius: 23, color: c),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(
                        width: 140, height: 13, radius: 6, color: c),
                    const SizedBox(height: 6),
                    _SkeletonBox(
                        width: 90, height: 11, radius: 6, color: c),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SkeletonBox(width: double.infinity, height: 13, radius: 6, color: c),
          const SizedBox(height: 8),
          _SkeletonBox(width: double.infinity, height: 13, radius: 6, color: c),
          const SizedBox(height: 8),
          _SkeletonBox(width: 180, height: 13, radius: 6, color: c),
          const SizedBox(height: 18),
          Row(
            children: [
              _SkeletonBox(width: 64, height: 32, radius: 99, color: c),
              const SizedBox(width: 8),
              _SkeletonBox(width: 64, height: 32, radius: 99, color: c),
              const SizedBox(width: 8),
              _SkeletonBox(width: 64, height: 32, radius: 99, color: c),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });
  final double width;
  final double height;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF323650) : const Color(0xFFE4E6EE),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Feed post card (inline, uses Map data from Supabase) ─────────────────────

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({
    required this.post,
    required this.index,
    this.liked = false,
    this.currentUserId,
    this.onLike,
    this.onComment,
    this.onPostEdit,
    this.onPostDelete,
  });

  final Map<String, dynamic> post;
  final int index;
  final bool liked;
  final String? currentUserId;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onPostEdit;
  final VoidCallback? onPostDelete;

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 30}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = post['profiles'] as Map<String, dynamic>?;
    final name = profile?['display_name'] as String? ?? 'User';
    final avatarUrl = profile?['avatar_url'] as String?;
    final badge = profile?['badge'] as String?;
    final streakDays = (profile?['streak_days'] as num?)?.toInt() ?? 0;
    final body = post['content'] as String? ?? '';
    final tags = (post['tags'] as List<dynamic>?)?.cast<String>() ?? [];
    final imageUrls =
        (post['image_urls'] as List<dynamic>?)?.cast<String>() ?? [];
    final likes = post['likes_count'] as int? ?? 0;
    final comments = post['comments_count'] as int? ?? 0;
    final createdAt = post['created_at'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isDark
              ? Border.all(color: Colors.white.withValues(alpha: 0.08))
              : Border.all(color: const Color(0xFFE9EBF0)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Author row ─────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SmallAvatar(name: name, avatarUrl: avatarUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + badge chip + time
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111827),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (badge != null && badge.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF14B8A6)
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      border: Border.all(
                                          color: const Color(0xFF14B8A6)
                                              .withValues(alpha: 0.28)),
                                    ),
                                    child: Text(
                                      badge,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0D9488),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (createdAt != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              _timeAgo(createdAt),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white38
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Day + first tag (sub-metadata line)
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (streakDays > 0) ...[
                            Text(
                              'Day $streakDays',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                          if (streakDays > 0 && tags.isNotEmpty)
                            Text(
                              '  ·  ',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white38
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          if (tags.isNotEmpty)
                            Text(
                              '#${tags.first}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PostActionMenu(
                  isOwner: currentUserId != null && post['author_id'] == currentUserId,
                  onEdit: onPostEdit,
                  onDelete: onPostDelete,
                ),
              ],
            ),
            // ── Body ───────────────────────────────────────────────────────
            const SizedBox(height: 12),
            Text(
              body,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.6,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : const Color(0xFF374151),
              ),
            ),
            // ── Image ──────────────────────────────────────────────────────
            if (imageUrls.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    imageUrls.first,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            color: isDark
                                ? const Color(0xFF1E1E2E)
                                : const Color(0xFFF0F1F5),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                          ),
                    errorBuilder: (_, __, ___) => Container(
                      color: scheme.surfaceContainerHighest,
                      child: Center(
                        child: Icon(LucideIcons.imageOff,
                            color: scheme.outline, size: 28),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            // ── Actions ────────────────────────────────────────────────────
            const SizedBox(height: 12),
            Divider(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : const Color(0xFFF3F4F6),
              height: 1,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Like button
                GestureDetector(
                  onTap: onLike,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: liked
                          ? const Color(0xFFEC4899).withValues(alpha: 0.13)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : const Color(0xFFF4F5F7)),
                      borderRadius: BorderRadius.circular(999),
                      border: liked
                          ? Border.all(
                              color: const Color(0xFFEC4899)
                                  .withValues(alpha: 0.28))
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          liked ? Icons.favorite : LucideIcons.heart,
                          size: 16,
                          color: liked
                              ? const Color(0xFFEC4899)
                              : (isDark
                                  ? Colors.white38
                                  : const Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$likes',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: liked
                                ? const Color(0xFFEC4899)
                                : (isDark
                                    ? Colors.white54
                                    : const Color(0xFF6B7280)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Comment button
                GestureDetector(
                  onTap: onComment,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.messageCircle,
                          size: 16,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$comments',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: 40 * index))
        .slideY(
          begin: 0.08,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOut,
          delay: Duration(milliseconds: 40 * index),
        );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.name, this.avatarUrl});
  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.purple, AppColors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(2.5),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(
                  CommunityDecor.avatarFor(name),
                  fit: BoxFit.cover,
                ),
              )
            : Image.network(
                CommunityDecor.avatarFor(name),
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

// ── Banners ───────────────────────────────────────────────────────────────────

class _GuestBanner extends StatelessWidget {
  const _GuestBanner({required this.onSignIn});
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.userX,
              size: 20, color: AppColors.purple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Viewing as guest — sign in to post or interact.',
              style: GoogleFonts.inter(
                color: AppColors.purple,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewPostsBanner extends StatelessWidget {
  const _NewPostsBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.purple.withValues(alpha: 0.12),
              AppColors.teal.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.arrowUp, size: 16, color: AppColors.purple),
            const SizedBox(width: 8),
            Text(
              'New posts — tap to refresh',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.purple,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.3, end: 0);
  }
}

class _SupportBanner extends StatelessWidget {
  const _SupportBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A4A3E)
              : const Color(0xFFD1FAE5),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your words matter here',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Be supportive · Be kind · Be real',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white54
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.arrowUpRight,
            size: 18,
            color: isDark
                ? Colors.white38
                : const Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }
}

// ── Empty / error / footer states ─────────────────────────────────────────────

class _FilterEmptyState extends StatelessWidget {
  const _FilterEmptyState({required this.filter});
  final CommunityPostFilter filter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, title, subtitle) = switch (filter) {
      CommunityPostFilter.myPosts => (
        LucideIcons.pencil,
        "You haven't posted yet.",
        'Share your first thought with the community.',
      ),
      CommunityPostFilter.mostLiked => (
        LucideIcons.heart,
        'No liked posts yet.',
        'Engage with posts to see them here.',
      ),
      _ => (
        LucideIcons.feather,
        'No posts yet. Start the conversation.',
        '',
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.purple.withValues(alpha: 0.15),
                  AppColors.teal.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, size: 40,
                  color: AppColors.purple.withValues(alpha: 0.7)),
            ),
          ).animate().scale(
            duration: 600.ms,
            curve: Curves.elasticOut,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _EmptyFeedState extends StatelessWidget {
  const _EmptyFeedState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.purple.withValues(alpha: 0.15),
                  AppColors.teal.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                LucideIcons.feather,
                size: 40,
                color: AppColors.purple.withValues(alpha: 0.7),
              ),
            ),
          ).animate().scale(
            duration: 600.ms,
            curve: Curves.elasticOut,
          ),
          const SizedBox(height: 24),
          Text(
            'Be the first gentle voice here',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Share a thought, a win, or a question.\nYour community is listening.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _CaughtUpFooter extends StatelessWidget {
  const _CaughtUpFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 1,
            color: AppColors.purple.withValues(alpha: 0.22),
          ),
          const SizedBox(width: 12),
          Text(
            "You're all caught up ✨",
            style: GoogleFonts.inter(
              color: AppColors.purple,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 1,
            color: AppColors.purple.withValues(alpha: 0.22),
          ),
        ],
      ),
    );
  }
}

// ── Comments bottom sheet ─────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({
    required this.postId,
    required this.repo,
  });

  final String postId;
  final CommunityRepository repo;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<CommunityComment> _comments = [];
  bool _loading = true;
  bool _sending = false;
  bool _commented = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await widget.repo.fetchComments(widget.postId);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[CommentsSheet] _loadComments error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > 2000 || _sending) return;

    final uid = widget.repo.currentUserId;
    if (uid == null) return;

    HapticFeedback.lightImpact();
    setState(() => _sending = true);

    try {
      await widget.repo.addComment(widget.postId, text);
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _hasText = false;
        _commented = true;
      });
      _refreshComments();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('[CommentsSheet] send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not post. Try again.',
                style: GoogleFonts.inter()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String? get _currentUserId => widget.repo.currentUserId;

  Future<void> _refreshComments() async {
    try {
      final comments = await widget.repo.fetchComments(widget.postId);
      if (mounted) setState(() => _comments = comments);
    } catch (_) {}
  }

  Future<void> _editComment(CommunityComment comment) async {
    final edited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditCommentSheet(
        currentBody: comment.body,
        onSave: (newBody) => widget.repo.updateComment(
          commentId: comment.id,
          body: newBody,
        ),
      ),
    );

    if (edited == true && mounted) {
      _refreshComments();
    }
  }

  Future<void> _deleteComment(CommunityComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete this comment?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'This cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.repo.deleteComment(comment.id);
      if (!mounted) return;
      setState(() {
        _comments.removeWhere((c) => c.id == comment.id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete comment. Try again.',
              style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canSend = _hasText && !_sending && _controller.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
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
              // ── Header ───────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color:
                            isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(_commented),
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
              ),
              const Divider(height: 1),
              // ── Content ───────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.messageCircle,
                                      size: 48,
                                      color: isDark
                                          ? Colors.white24
                                          : const Color(0xFFD1D5DB)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No comments yet',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Start a supportive conversation.',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white54
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            itemCount: _comments.length,
                            itemBuilder: (_, i) {
                              final c = _comments[i];
                              final isOwner = _currentUserId != null &&
                                  c.authorId == _currentUserId;
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF232636)
                                            .withValues(alpha: 0.6)
                                        : const Color(0xFFF9FAFB),
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundImage:
                                                NetworkImage(
                                              CommunityDecor.avatarFor(
                                                  c.author
                                                      .displayName),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              c.author.displayName,
                                              style: GoogleFonts.inter(
                                                fontWeight:
                                                    FontWeight.w700,
                                                fontSize: 13,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(
                                                        0xFF111827),
                                              ),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isOwner)
                                            CommentActionMenu(
                                              isOwner: true,
                                              onEdit: () => _editComment(c),
                                              onDelete: () => _deleteComment(c),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        c.body,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          height: 1.45,
                                          color: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.85)
                                              : const Color(0xFF374151),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              // ── Input row ─────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => canSend ? _send() : null,
                        decoration: InputDecoration(
                          hintText:
                              'Write a supportive comment...',
                          hintStyle:
                              GoogleFonts.inter(fontSize: 14),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF232636)
                                  .withValues(alpha: 0.6)
                              : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: canSend ? _send : null,
                          customBorder: const CircleBorder(),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: canSend
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF8A6CF6),
                                        Color(0xFF14B8A6),
                                      ],
                                    )
                                  : null,
                              color: canSend
                                  ? null
                                  : (isDark
                                      ? Colors.white.withValues(
                                          alpha: 0.08)
                                      : const Color(0xFFE5E7EB)),
                            ),
                            child: _sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation(
                                              Colors.white),
                                    ),
                                  )
                                : Icon(
                                    LucideIcons.send,
                                    size: 18,
                                    color: canSend
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white24
                                            : const Color(
                                                0xFF9CA3AF)),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.error.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.wifiOff, size: 32, color: scheme.error),
            ),
            const SizedBox(height: 20),
            Text(
              'Could not load feed',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: scheme.onSurface.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.purple, AppColors.teal],
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MisconfiguredState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.cloudOff, size: 48, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              'Supabase URL/key missing for this build.\n\n'
              '1) Stop the app and run again with **Full Restart** (defines load at compile time).\n'
              '2) Use Run config **UpHeal + Supabase community** or **frontend-main** (parent folder).\n'
              '3) Keep keys in **frontend-main/.vscode/supabase.keys.json** (gitignored).\n'
              '4) Or pass: flutter run --dart-define-from-file=.vscode/supabase.keys.json\n\n'
              'See **community_supabase_env.dart**.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                height: 1.4,
                color: scheme.onSurface.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

