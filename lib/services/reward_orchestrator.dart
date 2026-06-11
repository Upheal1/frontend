import 'package:flutter/foundation.dart';

/// A reward event emitted by the app when the user earns something.
///
/// This is UI-agnostic: it carries enough data for overlays/animations,
/// snackbars, and logs, but does not implement any UI itself.
sealed class RewardEvent {
  const RewardEvent();
}

final class XpGained extends RewardEvent {
  final int amount;
  final int newTotal;
  final int xpNeeded;
  final int level;

  const XpGained({
    required this.amount,
    required this.newTotal,
    required this.xpNeeded,
    required this.level,
  });
}

final class LevelUp extends RewardEvent {
  final int newLevel;
  final String newTitle;

  const LevelUp({
    required this.newLevel,
    required this.newTitle,
  });
}

final class StreakMilestone extends RewardEvent {
  final int days;
  final String label;

  const StreakMilestone({
    required this.days,
    required this.label,
  });
}

final class BadgeUnlocked extends RewardEvent {
  final String badgeId;
  final String badgeName;
  final String emoji;

  const BadgeUnlocked({
    required this.badgeId,
    required this.badgeName,
    required this.emoji,
  });
}

final class UrgeResisted extends RewardEvent {
  final int secondsHeld;

  const UrgeResisted({
    required this.secondsHeld,
  });
}

final class AvatarUnlocked extends RewardEvent {
  final String avatarName;
  final String avatarSrc;

  const AvatarUnlocked({
    required this.avatarName,
    required this.avatarSrc,
  });
}

/// Central queue for reward moments (XP, level ups, streak milestones, etc.).
///
/// Screens can listen to this notifier and consume events to show
/// calm, supportive animations/overlays in a consistent way.
class RewardOrchestrator extends ChangeNotifier {
  final List<RewardEvent> _queue = <RewardEvent>[];

  bool get hasPending => _queue.isNotEmpty;

  void queueReward(RewardEvent event) {
    _queue.add(event);
    notifyListeners();
  }

  /// Pops and returns the next reward event, or null if none.
  RewardEvent? consumeNext() {
    if (_queue.isEmpty) return null;
    final next = _queue.removeAt(0);
    notifyListeners();
    return next;
  }
}

