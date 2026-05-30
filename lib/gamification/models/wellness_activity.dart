/// Wellness activity types that earn XP and count toward streaks/quests.
///
/// This enum is intentionally stable: new values should be appended at the end
/// to avoid breaking existing persisted indices. For serialization, prefer
/// using [name] or [activityKey] rather than `index`.
enum WellnessActivityType {
  moodLog,
  breathing,
  journal,
  challenge,
  focusSession,
  sleepLog,
  stepGoal,
  aiChat,
}

extension WellnessActivityTypeExtension on WellnessActivityType {
  String get displayName {
    switch (this) {
      case WellnessActivityType.moodLog:
        return 'Mood Log';
      case WellnessActivityType.breathing:
        return 'Breathing';
      case WellnessActivityType.journal:
        return 'Journal';
      case WellnessActivityType.challenge:
        return 'Challenge';
      case WellnessActivityType.focusSession:
        return 'Focus Session';
      case WellnessActivityType.sleepLog:
        return 'Sleep Log';
      case WellnessActivityType.stepGoal:
        return 'Step Goal';
      case WellnessActivityType.aiChat:
        return 'AI Chat';
    }
  }

  /// Stable string key, safe to use in serialized data and configs.
  String get activityKey {
    switch (this) {
      case WellnessActivityType.moodLog:
        return 'mood_log';
      case WellnessActivityType.breathing:
        return 'breathing';
      case WellnessActivityType.journal:
        return 'journal';
      case WellnessActivityType.challenge:
        return 'challenge';
      case WellnessActivityType.focusSession:
        return 'focus_session';
      case WellnessActivityType.sleepLog:
        return 'sleep_log';
      case WellnessActivityType.stepGoal:
        return 'step_goal';
      case WellnessActivityType.aiChat:
        return 'ai_chat';
    }
  }

  /// Parse from a stored key or enum name.
  ///
  /// This is tolerant of older data:
  /// - first tries to match [activityKey]
  /// - then falls back to matching [name]
  static WellnessActivityType fromKey(String raw) {
    final key = raw.trim().toLowerCase();

    for (final value in WellnessActivityType.values) {
      if (value.activityKey == key) {
        return value;
      }
    }

    for (final value in WellnessActivityType.values) {
      if (value.name.toLowerCase() == key) {
        return value;
      }
    }

    // Fallback: treat unknown keys as a generic challenge to avoid crashes.
    return WellnessActivityType.challenge;
  }
}

/// Represents a completed wellness activity for gamification processing.
///
/// This is intentionally lightweight and serializable so it can be stored
/// locally (Hive/SharedPreferences) or through backend APIs.
class WellnessActivity {
  /// Identifier for this activity event.
  final String? id;

  final WellnessActivityType type;
  final DateTime completedAt;

  /// Optional game-specific metadata, e.g.:
  /// - "xp": int
  /// - "durationMinutes": int
  /// - "questId": String
  /// - "source": String ("manual", "auto", ...)
  final Map<String, dynamic>? metadata;

  const WellnessActivity({
    required this.type,
    required this.completedAt,
    this.id,
    this.metadata,
  });

  /// Convenience constructor for "now" events.
  factory WellnessActivity.now(
    WellnessActivityType type, {
    String? id,
    Map<String, dynamic>? metadata,
  }) {
    return WellnessActivity(
      type: type,
      completedAt: DateTime.now(),
      id: id,
      metadata: metadata,
    );
  }

  WellnessActivity copyWith({
    String? id,
    WellnessActivityType? type,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return WellnessActivity(
      id: id ?? this.id,
      type: type ?? this.type,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// JSON shape is kept flat and backend‑friendly.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      // store both a stable key and enum name for future flexibility
      'type': type.name,
      'activityKey': type.activityKey,
      'completedAt': completedAt.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory WellnessActivity.fromJson(Map<String, dynamic> json) {
    final dynamic rawType = json['activityKey'] ?? json['type'];
    final WellnessActivityType parsedType = rawType is String
        ? WellnessActivityTypeExtension.fromKey(rawType)
        : WellnessActivityType.challenge;

    return WellnessActivity(
      id: json['id'] as String?,
      type: parsedType,
      completedAt: DateTime.parse(json['completedAt'] as String),
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
