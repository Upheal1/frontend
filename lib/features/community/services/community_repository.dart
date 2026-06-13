import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/community_models.dart';
import 'community_supabase.dart';

/// Opaque cursor for keyset-based feed pagination.
/// Obtain from [FeedPage.nextCursor]; pass to [CommunityRepository.fetchPostsFeedPage].
class FeedCursor {
  FeedCursor._(this._createdAt);
  final String _createdAt; // ISO-8601 UTC timestamp of the last fetched post
}

/// Result of one page of the community feed.
class FeedPage {
  FeedPage({required this.posts, required this.nextCursor});

  final List<Map<String, dynamic>> posts;

  /// Null when no further pages exist.
  final FeedCursor? nextCursor;
}

// Number of posts per page for cursor-based pagination.
const int _kFeedPageSize = 20;

/// All Supabase IO for community feed, groups, chat, focus rooms.
class CommunityRepository {
  CommunityRepository([this._clientOverride]);

  final SupabaseClient? _clientOverride;

  SupabaseClient? get _c =>
      _clientOverride ?? CommunitySupabase.clientOrNull;

  bool get isConfigured => _c != null;

  String? get currentUserId => _c?.auth.currentUser?.id;

  /// Anonymous Supabase session + [public.users] + [profiles] (same id as auth.users).
  Future<void> ensureSession({required String displayName}) async {
    final client = _c;
    if (client == null) return;

    if (client.auth.currentUser == null) {
      try {
        await client.auth.signInAnonymously();
        debugPrint('[Community] ensureSession: anonymous sign-in OK. uid=${client.auth.currentUser?.id}');
      } catch (e, st) {
        // Anonymous auth is disabled in this Supabase project.
        // The community feed is publicly readable (anon RLS policy in migration 005).
        // Posting and reacting require a real authenticated session.
        debugPrint('[Community] ensureSession: signInAnonymously failed → $e');
        debugPrint('[Community] ensureSession: stack → $st');
        return;
      }
    } else {
      debugPrint('[Community] ensureSession: existing session uid=${client.auth.currentUser?.id}');
    }

    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    final authEmail = client.auth.currentUser?.email;
    final email = (authEmail != null && authEmail.trim().isNotEmpty)
        ? authEmail.trim()
        : 'anon+${uid.replaceAll('-', '')}@upheal.local';

    final nowIso = DateTime.now().toUtc().toIso8601String();

    try {
      await client.from('users').upsert(
        {
          'id': uid,
          'email': email,
          'updated_at': nowIso,
        },
        onConflict: 'id',
      );
    } catch (_) {
      // Core schema may omit public.users; community still works via profiles only.
    }

    try {
      await client.from('profiles').upsert(
        {
          'id': uid,
          'display_name': displayName,
          'updated_at': nowIso,
        },
        onConflict: 'id',
      );
    } catch (_) {
      // Profile upsert may fail if RLS denies access or network is unavailable.
      // Community read-only feed is still usable without a profile row.
    }
  }

  Future<void> signOut() async {
    await _c?.auth.signOut();
  }

  Stream<List<CommunityPost>> watchPosts({String? tag}) {
    final client = _c;
    if (client == null) return Stream.value(const []);

    return client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(80)
        .asyncMap((rows) => _hydratePosts(client, rows, tag));
  }

  /// Approved timeline rows (`timeline_posts`) with nested profiles — matches moderation pipeline.
  Future<List<Map<String, dynamic>>> fetchFeed({
    int from = 0,
    int to = 19,
  }) async {
    final client = _c;
    if (client == null) return const [];

    final data = await client.from('timeline_posts').select('''
          id,
          user_id,
          content,
          likes_count,
          comments_count,
          created_at,
          profiles (
            display_name,
            avatar_url,
            badges,
            level
          )
        ''').eq('status', 'approved').order('created_at', ascending: false).range(from, to);

    final raw = List<Map<String, dynamic>>.from(data as List);
    return raw.map(_normalizeTimelineProfileBadge).toList(growable: false);
  }

  /// Legacy `posts` feed as maps (body → content, counts, synthetic badge).
  Future<List<Map<String, dynamic>>> fetchPostsFeedLegacy({int limit = 50}) async {
    final client = _c;
    if (client == null) {
      debugPrint('[Community] fetchPostsFeedLegacy: Supabase client is null — skipping.');
      return const [];
    }

    final sessionUid = client.auth.currentUser?.id;
    debugPrint('[Community] fetchPostsFeedLegacy: querying posts (uid=$sessionUid, limit=$limit)...');

    try {
    final response = await client.from('posts').select('''
          id,
          created_at,
          body,
          tags,
          image_urls,
          author_id,
          like_count,
          comment_count,
          profiles!posts_author_id_fkey (
            id,
            display_name,
            avatar_url,
            badges,
            level
          )
        ''').order('created_at', ascending: false).limit(limit);

      final list = (response as List).cast<Map<String, dynamic>>();
      debugPrint('[Community] fetchPostsFeedLegacy: got ${list.length} posts.');
      return list.map(_postRowToFeedMap).toList(growable: false);
    } on PostgrestException catch (e, st) {
      debugPrint('[Community] fetchPostsFeedLegacy PostgrestException: '
          'code=${e.code} message=${e.message} details=${e.details}');
      debugPrint('[Community] fetchPostsFeedLegacy stack → $st');
      // Rethrow so _loadFeed can decide whether to show error vs empty state.
      rethrow;
    } catch (e, st) {
      debugPrint('[Community] fetchPostsFeedLegacy unexpected error: $e');
      debugPrint('[Community] fetchPostsFeedLegacy stack → $st');
      rethrow;
    }
  }

  /// Cursor-paginated feed. Use instead of [fetchPostsFeedLegacy] for all new code.
  ///
  /// Pass [after] from the previous [FeedPage.nextCursor] to load the next page.
  /// A null [FeedPage.nextCursor] in the response means no further pages exist.
  Future<FeedPage> fetchPostsFeedPage({FeedCursor? after}) async {
    final client = _c;
    if (client == null) {
      debugPrint('[Community] fetchPostsFeedPage: client null — skipping.');
      return FeedPage(posts: const [], nextCursor: null);
    }

    debugPrint('[Community] fetchPostsFeedPage: cursor=${after?._createdAt ?? 'start'}');

    final select = '''
          id,
          created_at,
          body,
          tags,
          image_urls,
          author_id,
          like_count,
          comment_count,
          profiles!posts_author_id_fkey (
            id,
            display_name,
            avatar_url,
            badges,
            level
          )
        ''';

    try {
      final dynamic response;
      if (after == null) {
        response = await client
            .from('posts')
            .select(select)
            .order('created_at', ascending: false)
            .order('id', ascending: false)
            .limit(_kFeedPageSize);
      } else {
        // Keyset pagination: posts strictly older than the cursor timestamp.
        // The (created_at DESC, id DESC) composite index in migration 006
        // makes this O(log n) regardless of table size.
        response = await client
            .from('posts')
            .select(select)
            .lt('created_at', after._createdAt)
            .order('created_at', ascending: false)
            .order('id', ascending: false)
            .limit(_kFeedPageSize);
      }

      final list = (response as List).cast<Map<String, dynamic>>();
      debugPrint('[Community] fetchPostsFeedPage: got ${list.length} posts.');

      FeedCursor? nextCursor;
      if (list.length == _kFeedPageSize) {
        final last = list.last;
        nextCursor = FeedCursor._(
          last['created_at'] as String,
        );
      }

      return FeedPage(
        posts: list.map(_postRowToFeedMap).toList(growable: false),
        nextCursor: nextCursor,
      );
    } on PostgrestException catch (e, st) {
      debugPrint('[Community] fetchPostsFeedPage PostgrestException: '
          'code=${e.code} message=${e.message} details=${e.details}');
      debugPrint('[Community] fetchPostsFeedPage stack → $st');
      rethrow;
    } catch (e, st) {
      debugPrint('[Community] fetchPostsFeedPage error: $e');
      debugPrint('[Community] fetchPostsFeedPage stack → $st');
      rethrow;
    }
  }

  Map<String, dynamic> _normalizeTimelineProfileBadge(Map<String, dynamic> row) {
    final m = Map<String, dynamic>.from(row);
    final prof = _normalizeEmbeddedProfile(m['profiles']);
    if (prof != null) {
      final pm = Map<String, dynamic>.from(prof);
      final b = pm['badge'];
      if (b == null || b.toString().trim().isEmpty) {
        pm['badge'] = _badgeLabelFromProfile(pm);
      }
      m['profiles'] = pm;
    }
    return m;
  }

  Map<String, dynamic>? _normalizeEmbeddedProfile(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  String _badgeLabelFromProfile(Map<String, dynamic> p) {
    final badges = p['badges'];
    if (badges is List && badges.isNotEmpty) {
      final b = badges.first;
      if (b != null && b.toString().trim().isNotEmpty) {
        return b.toString();
      }
    }
    final lv = (p['level'] as num?)?.toInt() ?? 1;
    return 'Lv $lv';
  }

  Map<String, dynamic> _postRowToFeedMap(Map<String, dynamic> row) {
    final profileMap = () {
      final base = _normalizeEmbeddedProfile(row['profiles']);
      if (base == null) return null;
      final m = Map<String, dynamic>.from(base);
      m['badge'] = _badgeLabelFromProfile(m);
      return m;
    }();

    return {
      ...row,
      'content': row['body'],
      'likes_count': row['like_count'],
      'comments_count': row['comment_count'],
      if (profileMap != null) 'profiles': profileMap,
    };
  }

  /// Private broadcast channel `feed:global` — requires a JWT ([RealtimeClient.setAuth]).
  /// Returns null when the user has no active Supabase session (guest mode).
  Future<RealtimeChannel?> subscribeToFeedUpdates({
    required void Function() onNewPostAvailable,
  }) async {
    final client = _c;
    if (client == null) return null;

    final token = client.auth.currentSession?.accessToken;
    if (token == null) return null; // Guest mode — skip realtime subscription.

    await client.realtime.setAuth(token);

    final channel = client.channel(
      'feed:global',
      opts: const RealtimeChannelConfig(private: true),
    );

    channel.onBroadcast(
      event: 'new_post',
      callback: (_) => onNewPostAvailable(),
    );

    channel.subscribe();
    return channel;
  }

  Future<void> createPostViaEdgeFunction(String content) async {
    final client = _c;
    if (client == null) throw StateError('Community Supabase not configured');

    final response = await client.functions.invoke(
      'create-post',
      body: {'content': content},
    );

    final data = response.data;

    if (data is Map && data['error'] != null) {
      throw Exception(data['error']);
    }

    if (data is Map && data['blocked'] == true) {
      throw Exception(data['post']?['moderation_reason'] ?? 'Post blocked');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyGroups() async {
    final client = _c;
    if (client == null) return const [];

    final data = await client.from('group_members').select('''
          group_id,
          role,
          groups (
            id,
            name,
            description,
            group_type
          )
        ''');

    final list = List<Map<String, dynamic>>.from(data as List);
    return list.where((row) {
      final s = row['status'];
      return s == null || s == 'active';
    }).toList(growable: false);
  }

  /// Latest messages for [groupId], oldest-first. Maps legacy `body` to `content`;
  /// fills `profiles.badge` when only `badges[]` exists.
  Future<List<Map<String, dynamic>>> fetchGroupMessages(String groupId) async {
    final client = _c;
    if (client == null) return const [];

    final data = await client
        .from('group_messages')
        .select('''
          id,
          group_id,
          sender_id,
          body,
          image_url,
          created_at,
          profiles (
            display_name,
            avatar_url,
            badges,
            level
          )
        ''')
        .eq('group_id', groupId)
        .order('created_at', ascending: false)
        .limit(50);

    final rows = List<Map<String, dynamic>>.from((data as List).reversed);
    return rows.map((row) {
      final m = Map<String, dynamic>.from(row);
      m['content'] = m['content'] ?? m['body'] ?? '';
      final prof = _normalizeEmbeddedProfile(m['profiles']);
      if (prof != null) {
        final pm = Map<String, dynamic>.from(prof);
        if (pm['badge'] == null || (pm['badge'] as String?)?.trim().isEmpty == true) {
          pm['badge'] = _badgeLabelFromProfile(pm);
        }
        m['profiles'] = pm;
      }
      return m;
    }).toList(growable: false);
  }

  Future<void> sendGroupMessageViaEdge({
    required String groupId,
    required String content,
  }) async {
    final client = _c;
    if (client == null) throw StateError('Community Supabase not configured');

    final response = await client.functions.invoke(
      'send-message',
      body: {
        'group_id': groupId,
        'content': content,
      },
    );

    final data = response.data;

    if (data is Map && data['error'] != null) {
      throw Exception(data['error']);
    }

    if (data is Map && data['blocked'] == true) {
      throw Exception(data['reason'] ?? 'Message blocked');
    }
  }

  /// Subscribe to **database-triggered** broadcasts on private topic `group:{groupId}`.
  ///
  /// Expected server pipeline:
  /// 1. Client invokes Edge Function `send-message` ([sendGroupMessageViaEdge]).
  /// 2. Function verifies auth, membership, moderation; inserts into `group_messages`.
  /// 3. Postgres trigger calls `realtime.broadcast_changes` → event `INSERT`, payload `new` row.
  /// 4. Supabase Realtime delivers to subscribers on `group:{groupId}` (match private channel + JWT).
  ///
  /// See `supabase/migrations/004_group_messages_realtime_broadcast.sql`.
  /// Returns null when the user has no active Supabase session (guest mode).
  Future<RealtimeChannel?> subscribeToGroupMessages({
    required String groupId,
    required void Function(Map<String, dynamic> message) onMessage,
    void Function(String error)? onError,
  }) async {
    final client = _c;
    if (client == null) return null;

    final token = client.auth.currentSession?.accessToken;
    if (token == null) return null; // Guest mode — skip realtime subscription.

    await client.realtime.setAuth(token);

    final channel = client.channel(
      'group:$groupId',
      opts: const RealtimeChannelConfig(private: true),
    );

    channel.onBroadcast(
      event: 'INSERT',
      callback: (payload) {
        try {
          final dynamic maybePayload = payload['payload'];
          final Map<String, dynamic> inner = maybePayload is Map
              ? Map<String, dynamic>.from(Map<Object?, Object?>.from(maybePayload))
              : Map<String, dynamic>.from(payload);

          final dynamic maybeNew = inner['new'];

          if (maybeNew is Map) {
            onMessage(Map<String, dynamic>.from(maybeNew));
          }
        } catch (e) {
          onError?.call(e.toString());
        }
      },
    );

    channel.subscribe((status, error) {
      if (error != null) {
        onError?.call(error.toString());
      }
    });

    return channel;
  }

  Future<void> removeRealtimeChannel(RealtimeChannel channel) async {
    final client = _c;
    if (client == null) return;
    await client.removeChannel(channel);
  }

  Future<List<CommunityPost>> _hydratePosts(
    SupabaseClient client,
    List<Map<String, dynamic>> rows,
    String? tag,
  ) async {
    if (rows.isEmpty) return const [];
    final ids = rows.map((e) => e['author_id'] as String).toSet().toList();
    final profRes =
        await client.from('profiles').select().inFilter('id', ids);
    final pmap = {
      for (final m in (profRes as List).cast<Map<String, dynamic>>())
        m['id'] as String: m
    };

    final uid = client.auth.currentUser?.id;
    final postIds = rows.map((r) => r['id'] as String).toList();
    final liked = uid != null && postIds.isNotEmpty
        ? await _postIdsWithUserRelation(
            client,
            'post_likes',
            uid,
            postIds,
          )
        : <String>{};
    final saved = uid != null && postIds.isNotEmpty
        ? await _postIdsWithUserRelation(
            client,
            'post_saves',
            uid,
            postIds,
          )
        : <String>{};

    var posts = rows
        .map(
          (r) => CommunityPost.fromRows(
            r,
            pmap[r['author_id'] as String],
            likedByMe: liked.contains(r['id'] as String),
            savedByMe: saved.contains(r['id'] as String),
          ),
        )
        .toList();

    if (tag != null && tag.isNotEmpty) {
      posts = posts.where((p) => p.tags.contains(tag)).toList();
    }
    return posts;
  }

  Future<Set<String>> fetchLikedPostIds({
    required String userId,
    required List<String> postIds,
  }) async {
    final client = _c;
    if (client == null || postIds.isEmpty) return {};
    return _postIdsWithUserRelation(client, 'post_likes', userId, postIds);
  }

  Future<Set<String>> _postIdsWithUserRelation(
    SupabaseClient client,
    String table,
    String userId,
    List<String> postIds,
  ) async {
    final res = await client
        .from(table)
        .select('post_id')
        .eq('user_id', userId)
        .inFilter('post_id', postIds);
    return {
      for (final m in (res as List).cast<Map<String, dynamic>>())
        m['post_id'] as String
    };
  }

  Future<List<CommunityProfile>> fetchLeaderboard({int limit = 50}) async {
    final client = _c;
    if (client == null) return const [];

    final rows = await client
        .from('profiles')
        .select()
        .order('community_xp', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((m) => CommunityProfile.fromMap(m as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> createPost({
    required String body,
    List<String> tags = const [],
    List<XFile> images = const [],
  }) async {
    final client = _c;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) {
      throw StateError('Community session required');
    }

    // Upload all images in parallel — avoids sequential round-trips.
    final urls = await Future.wait(images.map((img) async {
      final bytes = await img.readAsBytes();
      final name =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(img.path)}';
      final path = '$uid/$name';
      final ct = lookupMimeType(img.path, headerBytes: bytes) ??
          'application/octet-stream';
      await client.storage.from('community-media').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: ct),
          );
      return client.storage.from('community-media').getPublicUrl(path);
    }));

    await client.from('posts').insert({
      'author_id': uid,
      'body': body,
      'tags': tags,
      'image_urls': urls,
    });

    await _logXp(uid, 'post_created', 15);
  }

  Future<void> toggleLike(String postId) async {
    final client = _c;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;

    final existing = await client
        .from('post_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', uid)
        .maybeSingle();

    if (existing != null) {
      await client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', uid);
    } else {
      try {
        await client.from('post_likes').insert({
          'post_id': postId,
          'user_id': uid,
        });
        await _logXp(uid, 'like_given', 2);
      } on PostgrestException catch (e) {
        // 23505 = unique_violation: double-tap or concurrent like — safe to ignore.
        if (e.code != '23505') rethrow;
      }
    }
  }

  Future<bool> likedByMe(String postId) async {
    final client = _c;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return false;
    final row = await client
        .from('post_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', uid)
        .maybeSingle();
    return row != null;
  }

  Future<void> toggleSave(String postId) async {
    final client = _c;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;

    final existing = await client
        .from('post_saves')
        .select()
        .eq('post_id', postId)
        .eq('user_id', uid)
        .maybeSingle();

    if (existing != null) {
      await client
          .from('post_saves')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', uid);
    } else {
      await client.from('post_saves').insert({
        'post_id': postId,
        'user_id': uid,
      });
    }
  }

  Future<List<CommunityComment>> fetchComments(String postId) async {
    final client = _c;
    if (client == null) return const [];

    final rows = await client
        .from('comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return const [];

    final aids =
        list.map((e) => e['author_id'] as String).toSet().toList();
    final profRes =
        await client.from('profiles').select().inFilter('id', aids);
    final pmap = {
      for (final m in (profRes as List).cast<Map<String, dynamic>>())
        m['id'] as String: m
    };

    return list
        .map(
          (c) => CommunityComment.fromMap(c, pmap[c['author_id'] as String]),
        )
        .toList();
  }

  Stream<List<CommunityComment>> watchComments(String postId) {
    final client = _c;
    if (client == null) return Stream.value(const []);

    return client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at')
        .asyncMap((_) => fetchComments(postId));
  }

  Future<void> addComment(
    String postId,
    String body, {
    String? parentId,
  }) async {
    final client = _c;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;

    final trimmed = body.trim();
    if (trimmed.isEmpty || trimmed.length > 2000) return;

    try {
      await client.from('comments').insert({
        'post_id': postId,
        'author_id': uid,
        'body': trimmed,
        if (parentId != null) 'parent_id': parentId,
      });
      await _logXp(uid, 'comment_created', 8);
    } on PostgrestException catch (e) {
      debugPrint('[Community] addComment error: $e');
      rethrow;
    }
  }

  Stream<List<CommunityGroup>> watchGroups() {
    final client = _c;
    if (client == null) return Stream.value(const []);

    return client
        .from('groups')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100)
        .map(
          (rows) =>
              rows.map((r) => CommunityGroup.fromMap(r)).toList(growable: false),
        );
  }

  Future<String> createGroup({
    required String name,
    required String description,
    required CommunityGroupType type,
  }) async {
    final client = _c;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) throw StateError('No session');

    final row = await client
        .from('groups')
        .insert({
          'name': name,
          'description': description,
          'group_type': type.wireName,
          'created_by': uid,
        })
        .select()
        .single();

    final gid = row['id'] as String;
    await client.from('group_members').insert({
      'group_id': gid,
      'user_id': uid,
      'role': 'owner',
    });

    if (type == CommunityGroupType.focusRoom) {
      await client.from('focus_room_state').insert({
        'group_id': gid,
        'phase': 'idle',
        'focus_seconds': 1500,
        'break_seconds': 300,
      });
    }

    return gid;
  }

  Future<void> joinGroup(String groupId) async {
    final client = _c;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;
    await client.from('group_members').upsert(
      {
        'group_id': groupId,
        'user_id': uid,
        'role': 'member',
      },
      onConflict: 'group_id,user_id',
    );
  }

  Future<List<CommunityProfile>> fetchMembers(String groupId) async {
    final client = _c;
    if (client == null) return const [];

    final gm = await client
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId);

    final ids = (gm as List)
        .map((e) => e['user_id'] as String)
        .toList(growable: false);
    if (ids.isEmpty) return const [];

    final profRes =
        await client.from('profiles').select().inFilter('id', ids);
    return (profRes as List)
        .map((m) => CommunityProfile.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Stream<List<GroupChatMessage>> watchMessages(String groupId) {
    final client = _c;
    if (client == null) return Stream.value(const []);

    return client
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: false)
        .limit(120)
        .asyncMap((rows) => _hydrateMessages(client, rows));
  }

  Future<List<GroupChatMessage>> _hydrateMessages(
    SupabaseClient client,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return const [];
    final ids = rows.map((e) => e['sender_id'] as String).toSet().toList();
    final profRes =
        await client.from('profiles').select().inFilter('id', ids);
    final pmap = {
      for (final m in (profRes as List).cast<Map<String, dynamic>>())
        m['id'] as String: m
    };

    final mids = rows.map((e) => e['id'] as String).toList();
    final reactRes = await client
        .from('message_reactions')
        .select()
        .inFilter('message_id', mids);

    final emojiCount = <String, Map<String, int>>{};
    for (final r in (reactRes as List).cast<Map<String, dynamic>>()) {
      final mid = r['message_id'] as String;
      final em = r['emoji'] as String;
      emojiCount.putIfAbsent(mid, () => {});
      emojiCount[mid]![em] = (emojiCount[mid]![em] ?? 0) + 1;
    }

    final messages = rows
        .map(
          (m) => GroupChatMessage.fromMap(
            m,
            pmap[m['sender_id'] as String],
            emojiCount[m['id'] as String] ?? const {},
          ),
        )
        .toList();
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<void> sendMessage(String groupId, String body) async {
    final client = _c;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;
    if (body.trim().isEmpty) return;

    await client.from('group_messages').insert({
      'group_id': groupId,
      'sender_id': uid,
      'body': body.trim(),
    });
    await _logXp(uid, 'chat_message', 3);
  }

  Future<void> sendMessageWithImage(String groupId, XFile image) async {
    final client = _c;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;

    final bytes = await image.readAsBytes();
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';
    final path = '$uid/$name';
    final ct = lookupMimeType(image.path, headerBytes: bytes) ?? 'image/jpeg';
    await client.storage.from('community-media').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: ct),
        );
    final url = client.storage.from('community-media').getPublicUrl(path);

    await client.from('group_messages').insert({
      'group_id': groupId,
      'sender_id': uid,
      'body': '',
      'image_url': url,
    });
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    final client = _c;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;

    final existing = await client
        .from('message_reactions')
        .select()
        .eq('message_id', messageId)
        .eq('user_id', uid)
        .maybeSingle();

    if (existing != null && (existing['emoji'] as String) == emoji) {
      await client
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', uid);
    } else {
      await client.from('message_reactions').delete().match({
        'message_id': messageId,
        'user_id': uid,
      });
      await client.from('message_reactions').insert({
        'message_id': messageId,
        'user_id': uid,
        'emoji': emoji,
      });
    }
  }

  RealtimeChannel typingChannel(String groupId) {
    final client = _c!;
    return client.channel('typing-$groupId');
  }

  void subscribeTyping(
    RealtimeChannel channel,
    void Function(Map<String, dynamic> payload) onTyping,
  ) {
    channel.onBroadcast(
      event: 'typing',
      callback: (payload) => onTyping(payload),
    );
    channel.subscribe();
  }

  Future<void> sendTypingPulse(RealtimeChannel channel, bool typing) async {
    final uid = currentUserId;
    if (uid == null) return;
    await channel.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': uid, 'typing': typing},
    );
  }

  /// Presence: track online members in a group channel.
  Future<RealtimeChannel> joinPresenceChannel(
    String groupId,
    Map<String, dynamic> userMeta, {
    void Function(int onlineCount)? onPresenceChanged,
  }) async {
    final client = _c!;
    final ch = client.channel(
      'presence-group-$groupId',
      opts: RealtimeChannelConfig(key: groupId),
    );
    if (onPresenceChanged != null) {
      ch.onPresenceSync((_) {
        final n = ch.presenceState().fold<int>(
          0,
          (acc, s) => acc + s.presences.length,
        );
        onPresenceChanged(n);
      });
    }
    ch.subscribe();
    await ch.track(userMeta);
    return ch;
  }

  Stream<FocusRoomState?> watchFocusState(String groupId) {
    final client = _c;
    if (client == null) return Stream.value(null);

    return client
        .from('focus_room_state')
        .stream(primaryKey: ['group_id'])
        .eq('group_id', groupId)
        .limit(1)
        .map((rows) {
          if (rows.isEmpty) return null;
          return FocusRoomState.fromMap(rows.first);
        });
  }

  Future<void> updateFocusRoom({
    required String groupId,
    required FocusPhase phase,
    DateTime? phaseStartedAt,
    int focusSeconds = 1500,
    int breakSeconds = 300,
  }) async {
    final client = _c;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;

    final phaseStr = phase == FocusPhase.focus
        ? 'focus'
        : phase == FocusPhase.breakPhase
            ? 'break'
            : 'idle';

    await client.from('focus_room_state').upsert(
      {
        'group_id': groupId,
        'phase': phaseStr,
        'phase_started_at':
            (phaseStartedAt ?? DateTime.now().toUtc()).toIso8601String(),
        'focus_seconds': focusSeconds,
        'break_seconds': breakSeconds,
        'updated_by': uid,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'group_id',
    );
  }

  Future<void> markMessagesRead(Iterable<String> messageIds) async {
    final client = _c;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;
    final rows = messageIds
        .map(
          (id) => {
            'message_id': id,
            'user_id': uid,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          },
        )
        .toList();
    if (rows.isEmpty) return;
    await client.from('message_reads').upsert(
      rows,
      onConflict: 'message_id,user_id',
    );
  }

  /// XP logging is **best-effort**: failures are logged but never propagate
  /// to callers.  A broken XP pipeline must not block posting, liking, or
  /// commenting.
  Future<void> _logXp(String userId, String reason, int points) async {
    final client = _c;
    if (client == null) return;
    try {
      await client.from('community_xp_events').insert({
        'user_id': userId,
        'reason': reason,
        'points': points,
      });
      final row = await client
          .from('profiles')
          .select('community_xp, reputation')
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return;
      final cx = (row['community_xp'] as num?)?.toInt() ?? 0;
      final rep = (row['reputation'] as num?)?.toInt() ?? 0;
      await client.from('profiles').update({
        'community_xp': cx + points,
        'reputation': rep + (points ~/ 3),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('[Community] _logXp failed (reason=$reason, points=$points): $e');
    }
  }
}
