import 'package:flutter/foundation.dart';

/// Filter / sort options for the community feed.
enum CommunityPostFilter {
  all,
  myPosts,
  newest,
  mostLiked,
}

/// Tag presets for the wellness / productivity feed.
const List<String> kCommunityTagPresets = [
  'Focus',
  'Gym',
  'Study',
  'Discipline',
  'Recovery',
  'Programming',
];

@immutable
class CommunityProfile {
  const CommunityProfile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.level = 1,
    this.streakDays = 0,
    this.reputation = 0,
    this.communityXp = 0,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final int level;
  final int streakDays;
  final int reputation;
  final int communityXp;

  factory CommunityProfile.fromMap(Map<String, dynamic> m) {
    return CommunityProfile(
      id: m['id'] as String,
      displayName: m['display_name'] as String? ?? 'Member',
      avatarUrl: m['avatar_url'] as String?,
      level: (m['level'] as num?)?.toInt() ?? 1,
      streakDays: (m['streak_days'] as num?)?.toInt() ?? 0,
      reputation: (m['reputation'] as num?)?.toInt() ?? 0,
      communityXp: (m['community_xp'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.body,
    required this.imageUrls,
    required this.tags,
    required this.likeCount,
    required this.commentCount,
    required this.saveCount,
    required this.createdAt,
    required this.author,
    this.likedByMe = false,
    this.savedByMe = false,
  });

  final String id;
  final String authorId;
  final String body;
  final List<String> imageUrls;
  final List<String> tags;
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final DateTime createdAt;
  final CommunityProfile author;
  final bool likedByMe;
  final bool savedByMe;

  factory CommunityPost.fromRows(
    Map<String, dynamic> post,
    Map<String, dynamic>? authorRow, {
    bool likedByMe = false,
    bool savedByMe = false,
  }) {
    final aid = post['author_id'] as String;
    final a = authorRow != null
        ? CommunityProfile.fromMap(authorRow)
        : CommunityProfile(id: aid, displayName: 'Member');
    return CommunityPost(
      id: post['id'] as String,
      authorId: aid,
      body: post['body'] as String? ?? '',
      imageUrls: List<String>.from(post['image_urls'] as List? ?? const []),
      tags: List<String>.from(post['tags'] as List? ?? const []),
      likeCount: (post['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (post['comment_count'] as num?)?.toInt() ?? 0,
      saveCount: (post['save_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(post['created_at'] as String? ?? '') ??
          DateTime.now(),
      author: a,
      likedByMe: likedByMe,
      savedByMe: savedByMe,
    );
  }
}

@immutable
class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.body,
    this.parentId,
    required this.createdAt,
    required this.author,
  });

  final String id;
  final String postId;
  final String authorId;
  final String body;
  final String? parentId;
  final DateTime createdAt;
  final CommunityProfile author;

  factory CommunityComment.fromMap(
    Map<String, dynamic> m,
    Map<String, dynamic>? authorRow,
  ) {
    final aid = m['author_id'] as String;
    final a = authorRow != null
        ? CommunityProfile.fromMap(authorRow)
        : CommunityProfile(id: aid, displayName: 'Member');
    return CommunityComment(
      id: m['id'] as String,
      postId: m['post_id'] as String,
      authorId: aid,
      body: m['body'] as String? ?? '',
      parentId: m['parent_id'] as String?,
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
          DateTime.now(),
      author: a,
    );
  }
}

enum CommunityGroupType {
  study,
  focusRoom,
  gym,
  coding,
  recovery,
  general;

  String get wireName {
    switch (this) {
      case CommunityGroupType.study:
        return 'study';
      case CommunityGroupType.focusRoom:
        return 'focus_room';
      case CommunityGroupType.gym:
        return 'gym';
      case CommunityGroupType.coding:
        return 'coding';
      case CommunityGroupType.recovery:
        return 'recovery';
      case CommunityGroupType.general:
        return 'general';
    }
  }

  static CommunityGroupType parse(String v) {
    switch (v) {
      case 'study':
        return CommunityGroupType.study;
      case 'focus_room':
        return CommunityGroupType.focusRoom;
      case 'gym':
        return CommunityGroupType.gym;
      case 'coding':
        return CommunityGroupType.coding;
      case 'recovery':
        return CommunityGroupType.recovery;
      default:
        return CommunityGroupType.general;
    }
  }

  String get label {
    switch (this) {
      case CommunityGroupType.study:
        return 'Study group';
      case CommunityGroupType.focusRoom:
        return 'Focus room';
      case CommunityGroupType.gym:
        return 'Gym accountability';
      case CommunityGroupType.coding:
        return 'Coding squad';
      case CommunityGroupType.recovery:
        return 'Recovery / support';
      case CommunityGroupType.general:
        return 'Community';
    }
  }
}

@immutable
class CommunityGroup {
  const CommunityGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.groupType,
    this.imageUrl,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final CommunityGroupType groupType;
  final String? imageUrl;
  final String createdBy;
  final DateTime createdAt;

  factory CommunityGroup.fromMap(Map<String, dynamic> m) {
    return CommunityGroup(
      id: m['id'] as String,
      name: m['name'] as String? ?? '',
      description: m['description'] as String? ?? '',
      groupType: CommunityGroupType.parse(m['group_type'] as String? ?? 'general'),
      imageUrl: m['image_url'] as String?,
      createdBy: m['created_by'] as String,
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

@immutable
class GroupChatMessage {
  const GroupChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.body,
    this.imageUrl,
    required this.createdAt,
    required this.sender,
    this.reactions = const {},
  });

  final String id;
  final String groupId;
  final String senderId;
  final String body;
  final String? imageUrl;
  final DateTime createdAt;
  final CommunityProfile sender;
  final Map<String, int> reactions;

  factory GroupChatMessage.fromMap(
    Map<String, dynamic> m,
    Map<String, dynamic>? senderRow,
    Map<String, int> reactions,
  ) {
    final sid = m['sender_id'] as String;
    final s = senderRow != null
        ? CommunityProfile.fromMap(senderRow)
        : CommunityProfile(id: sid, displayName: 'Member');
    return GroupChatMessage(
      id: m['id'] as String,
      groupId: m['group_id'] as String,
      senderId: sid,
      body: m['body'] as String? ?? '',
      imageUrl: m['image_url'] as String?,
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
          DateTime.now(),
      sender: s,
      reactions: reactions,
    );
  }
}

enum FocusPhase { idle, focus, breakPhase }

@immutable
class FocusRoomState {
  const FocusRoomState({
    required this.groupId,
    required this.phase,
    this.phaseStartedAt,
    required this.focusSeconds,
    required this.breakSeconds,
    this.updatedBy,
    required this.updatedAt,
  });

  final String groupId;
  final FocusPhase phase;
  final DateTime? phaseStartedAt;
  final int focusSeconds;
  final int breakSeconds;
  final String? updatedBy;
  final DateTime updatedAt;

  factory FocusRoomState.fromMap(Map<String, dynamic> m) {
    final p = m['phase'] as String? ?? 'idle';
    return FocusRoomState(
      groupId: m['group_id'] as String,
      phase: p == 'focus'
          ? FocusPhase.focus
          : p == 'break'
              ? FocusPhase.breakPhase
              : FocusPhase.idle,
      phaseStartedAt:
          DateTime.tryParse(m['phase_started_at'] as String? ?? ''),
      focusSeconds: (m['focus_seconds'] as num?)?.toInt() ?? 1500,
      breakSeconds: (m['break_seconds'] as num?)?.toInt() ?? 300,
      updatedBy: m['updated_by'] as String?,
      updatedAt: DateTime.tryParse(m['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
