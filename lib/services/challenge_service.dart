import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../avatar/services/avatar_progression_provider.dart';
import '../gamification/xp_config.dart';
import '../models/challenge_model.dart';
import '../models/streak_model.dart';
import '../models/user_model.dart';
import 'reward_orchestrator.dart' as rewards;
import 'streak_service.dart';

class ChallengeService extends ChangeNotifier {
  ChallengeService();

  static const String _storageKey = 'challenges_v1';
  static const String _storageMetaKey = 'challenges_v1_meta';

  final List<ChallengeModel> _challenges = <ChallengeModel>[];

  List<ChallengeModel> get _all => List.unmodifiable(_challenges);

  List<ChallengeModel> get dailyChallenges => _all
      .where((c) =>
          c.category == ChallengeCategory.daily &&
          !c.isExpired &&
          c.status != ChallengeStatus.expired)
      .toList();

  List<ChallengeModel> get weeklyChallenges =>
      _all.where((c) => c.category == ChallengeCategory.weekly).toList();

  List<ChallengeModel> get specialChallenges =>
      _all.where((c) => c.category == ChallengeCategory.special).toList();

  List<ChallengeModel> get activeChallenges => _all
      .where((c) =>
          c.status == ChallengeStatus.active &&
          !c.isExpired &&
          c.status != ChallengeStatus.expired)
      .toList();

  int get completedTodayCount {
    final now = DateTime.now();
    return _all.where((c) {
      final completedAt = c.completedAt;
      if (completedAt == null) return false;
      return completedAt.year == now.year &&
          completedAt.month == now.month &&
          completedAt.day == now.day;
    }).length;
  }

  int get totalXpAvailable {
    return _all
        .where((c) =>
            c.status != ChallengeStatus.completed &&
            !c.isExpired &&
            c.status != ChallengeStatus.expired)
        .fold<int>(0, (sum, c) => sum + c.xpReward);
  }

  int get completedTotalCount =>
      _all.where((c) => c.status == ChallengeStatus.completed).length;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final shouldReset = _shouldResetDaily(prefs);
      if (shouldReset) {
        _challenges
          ..clear()
          ..addAll(ChallengeModel.getDefaultChallenges());
        _markExpiredDaily();
        await _persist(prefs, touchedAt: DateTime.now());
        notifyListeners();
        return;
      }

      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        _challenges
          ..clear()
          ..addAll(ChallengeModel.getDefaultChallenges());
        _markExpiredDaily();
        await _persist(prefs, touchedAt: DateTime.now());
        notifyListeners();
        return;
      }

      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final loaded = decoded
          .map((e) =>
              ChallengeModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      _challenges
        ..clear()
        ..addAll(loaded);

      _markExpiredDaily();

      await _persist(prefs, touchedAt: DateTime.now());
      notifyListeners();
    } catch (e) {
      // Fallback to defaults on any parsing error
      _challenges
        ..clear()
        ..addAll(ChallengeModel.getDefaultChallenges());
      _markExpiredDaily();
      await _persist(prefs, touchedAt: DateTime.now());
      notifyListeners();
    }
  }

  bool _shouldResetDaily(SharedPreferences prefs) {
    final metaRaw = prefs.getString(_storageMetaKey);
    if (metaRaw == null || metaRaw.isEmpty) return true;

    try {
      final meta = jsonDecode(metaRaw) as Map<String, dynamic>;
      final lastSavedStr = meta['lastSaved'] as String?;
      if (lastSavedStr == null) return true;
      final lastSaved = DateTime.parse(lastSavedStr);
      final diff = DateTime.now().difference(lastSaved);
      return diff.inHours >= 24;
    } catch (_) {
      return true;
    }
  }

  void _markExpiredDaily() {
    final now = DateTime.now();
    for (var i = 0; i < _challenges.length; i++) {
      final c = _challenges[i];
      if (c.category == ChallengeCategory.daily && c.expiresAt != null) {
        if (now.isAfter(c.expiresAt!)) {
          _challenges[i] = c.copyWith(status: ChallengeStatus.expired);
        }
      }
    }
  }

  void joinChallenge(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final index = _challenges.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final now = DateTime.now();
    final current = _challenges[index];
    final expiresAt = now.add(Duration(hours: current.durationHours));

    _challenges[index] = current.copyWith(
      status: ChallengeStatus.active,
      startedAt: now,
      expiresAt: expiresAt,
    );

    await _persist(prefs, touchedAt: now);
    notifyListeners();
  }

  Future<void> incrementProgress(String id, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final index = _challenges.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final current = _challenges[index];
    if (current.isExpired || current.status == ChallengeStatus.completed) {
      return;
    }

    final updatedCount = current.currentCount + 1;
    final updated = current.copyWith(currentCount: updatedCount);
    _challenges[index] = updated;

    if (updated.currentCount >= updated.targetCount &&
        updated.targetCount > 0) {
      await _completeChallenge(id, context, prefs: prefs);
    } else {
      await _persist(prefs, touchedAt: DateTime.now());
      notifyListeners();
    }
  }

  Future<void> _completeChallenge(
    String id,
    BuildContext context, {
    required SharedPreferences prefs,
  }) async {
    final index = _challenges.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final now = DateTime.now();
    final current = _challenges[index];
    final xpReward = current.xpReward;

    final updated = current.copyWith(
      status: ChallengeStatus.completed,
      completedAt: now,
    );
    _challenges[index] = updated;

    final userModel = Provider.of<UserModel>(context, listen: false);
    final rewardsOrchestrator =
        Provider.of<rewards.RewardOrchestrator>(context, listen: false);
    final avatarProgression =
        Provider.of<AvatarProgressionProvider>(context, listen: false);

    final previousLevel = userModel.level;

    userModel.addXp(xpReward);

    final newXp = userModel.xp;
    final newLevel = userModel.level;

    final nextLevelTotalXp = XpConfig.totalXpForLevel(newLevel + 1);
    final xpNeeded = (nextLevelTotalXp - newXp).clamp(0, nextLevelTotalXp);

    rewardsOrchestrator.queueReward(
      rewards.XpGained(
        amount: xpReward,
        newTotal: newXp,
        xpNeeded: xpNeeded,
        level: newLevel,
      ),
    );

    if (newLevel > previousLevel) {
      rewardsOrchestrator.queueReward(
        rewards.LevelUp(
          newLevel: newLevel,
          newTitle: 'Level $newLevel',
        ),
      );

      final newlyUnlocked = avatarProgression.checkAndUnlock(newLevel);
      for (final avatar in newlyUnlocked) {
        rewardsOrchestrator.queueReward(
          rewards.AvatarUnlocked(
            avatarName: avatar.name,
            avatarSrc: avatar.src,
          ),
        );
      }
    }

    await StreakService.recordActivity(
      StreakActivityType.challenge,
      xpEarned: xpReward,
    );

    final streakState = Provider.of<StreakState>(context, listen: false);
    userModel.setStreak(streakState.currentStreak);

    const milestones = [7, 14, 30, 60, 90];
    if (milestones.contains(streakState.currentStreak)) {
      rewardsOrchestrator.queueReward(
        rewards.StreakMilestone(
          days: streakState.currentStreak,
          label: '${streakState.currentStreak}-day streak',
        ),
      );
    }

    await _persist(prefs, touchedAt: now);
    notifyListeners();
  }

  Future<void> _persist(
    SharedPreferences prefs, {
    required DateTime touchedAt,
  }) async {
    final list = _challenges.map((c) => c.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(list));

    final meta = <String, dynamic>{
      'lastSaved': touchedAt.toIso8601String(),
    };
    await prefs.setString(_storageMetaKey, jsonEncode(meta));
  }
}
