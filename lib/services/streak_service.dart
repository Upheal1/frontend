import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streak_model.dart';
import 'notification_service.dart';


/// Service for managing streak data persistence and logic
class StreakService {
  static const String _streakDataKey = 'streak_data';
  static const String _lastCheckKey = 'streak_last_check';
  static const String _todayActivitiesKey = 'streak_today_activities';
  static const int _schemaVersion = 1;
  
  static StreakState? _state;
  
  /// Initialize the streak service with state
  static Future<void> initialize(StreakState state) async {
    _state = state;
    await _loadStreakData();
    await _checkDayTransition();
    await _scheduleStreakNotifications();
  }
  
  /// Load streak data from local storage.
  static Future<void> _loadStreakData() async {
    if (_state == null) return;
    
    _state!.setLoading(true);
    
    try {
      final data = await _loadLocalData();
      
      if (data != null) {
        _parseAndInitializeState(data);
      } else {
        // Initialize with defaults
        _state!.initializeData(
          currentStreak: 0,
          longestStreak: 0,
          totalDaysActive: 0,
          freezeTokens: 1,
          totalXpEarned: 0,
          history: [],
          milestones: StreakMilestone.allMilestones,
          todayActivities: {},
          isTodayCompleted: false,
        );
      }
      
      // Load today's activities
      final prefs = await SharedPreferences.getInstance();
      final todayActivitiesJson = prefs.getString(_todayActivitiesKey);
      if (todayActivitiesJson != null) {
        final activities = (json.decode(todayActivitiesJson) as List)
            .map((a) => StreakActivityType.values.firstWhere(
                  (t) => t.name == a,
                  orElse: () => StreakActivityType.challenge,
                ))
            .toSet();
        
        for (final activity in activities) {
          _state!.recordActivity(activity);
        }
      }
    } catch (e) {
      debugPrint('Error loading streak data: $e');
      // Initialize with defaults on error
      _state!.initializeData(
        currentStreak: 0,
        longestStreak: 0,
        totalDaysActive: 0,
        freezeTokens: 1,
        totalXpEarned: 0,
        history: [],
        milestones: StreakMilestone.allMilestones,
        todayActivities: {},
        isTodayCompleted: false,
      );
    }
  }

  /// Load streak data from local storage.
  static Future<Map<String, dynamic>?> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString(_streakDataKey);
      if (localData == null) return null;
      final data = json.decode(localData) as Map<String, dynamic>;
      debugPrint('Loaded streak data from local storage');
      return data;
    } catch (e) {
      debugPrint('Error loading streak data from local storage: $e');
      return null;
    }
  }

  /// Remote streak sync is handled by the backend when an endpoint is available.
  static Future<Map<String, dynamic>?> _loadRemoteData() async {
    return null;
  }
  
  /// Parse data and initialize state
  static void _parseAndInitializeState(Map<String, dynamic> data) {
    if (_state == null) return;
    
    // Parse streak history
    final historyJson = data['history'] as List<dynamic>? ?? [];
    final history = historyJson
        .map((h) => StreakDay.fromJson(h as Map<String, dynamic>))
        .toList();
    
    // Parse milestones
    final milestonesJson = data['milestones'] as List<dynamic>? ?? [];
    final milestones = StreakMilestone.allMilestones.map((m) {
      final saved = milestonesJson.firstWhere(
        (s) => s['type'] == m.type.name,
        orElse: () => <String, dynamic>{},
      ) as Map<String, dynamic>;
      
      if (saved.isNotEmpty) {
        return m.copyWith(
          isUnlocked: saved['isUnlocked'] as bool? ?? false,
          unlockedAt: saved['unlockedAt'] != null 
              ? DateTime.parse(saved['unlockedAt'] as String)
              : null,
        );
      }
      return m;
    }).toList();
    
    // Parse dates
    final lastActiveDate = data['lastActiveDate'] != null 
        ? DateTime.parse(data['lastActiveDate'] as String)
        : null;
    final streakStartDate = data['streakStartDate'] != null 
        ? DateTime.parse(data['streakStartDate'] as String)
        : null;
    
    // Check if isTodayCompleted is valid (lastActiveDate must be today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final savedIsTodayCompleted = data['isTodayCompleted'] as bool? ?? false;
    final lastActiveDay = lastActiveDate != null
        ? DateTime(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day)
        : null;
    
    // Only mark today as completed if lastActiveDate is actually today
    final isTodayCompleted = savedIsTodayCompleted && 
                             lastActiveDay != null && 
                             lastActiveDay.isAtSameMomentAs(today);
    
    _state!.initializeData(
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      totalDaysActive: data['totalDaysActive'] as int? ?? 0,
      freezeTokens: data['freezeTokens'] as int? ?? 1,
      totalXpEarned: data['totalXpEarned'] as int? ?? 0,
      lastActiveDate: lastActiveDate,
      streakStartDate: streakStartDate,
      history: history,
      milestones: milestones,
      todayActivities: {},
      isTodayCompleted: isTodayCompleted,
    );
  }
  
  /// Check if day has changed and handle streak logic
  static Future<void> _checkDayTransition() async {
    if (_state == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final lastCheckStr = prefs.getString(_lastCheckKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (lastCheckStr != null) {
      final lastCheck = DateTime.parse(lastCheckStr);
      final lastCheckDay = DateTime(lastCheck.year, lastCheck.month, lastCheck.day);
      
      if (!lastCheckDay.isAtSameMomentAs(today)) {
        // New day - check if streak should break
        final daysDiff = today.difference(lastCheckDay).inDays;
        final yesterday = today.subtract(const Duration(days: 1));
        final lastActiveDay = _state!.lastActiveDate != null
            ? DateTime(_state!.lastActiveDate!.year, _state!.lastActiveDate!.month, _state!.lastActiveDate!.day)
            : null;
        
        // Check if user missed yesterday (last active was not yesterday)
        if (lastActiveDay != null && !lastActiveDay.isAtSameMomentAs(yesterday) && daysDiff > 1) {
          // Missed at least one day
          if (_state!.freezeTokens > 0) {
            // Use freeze automatically
            _state!.useFreeze();
            debugPrint('Auto-used streak freeze for missed day');
          } else {
            // Break the streak
            _state!.breakStreak();
            debugPrint('Streak broken - no freeze available');
          }
        }
        
        // Reset for new day (only if it's actually a new day)
        if (daysDiff >= 1) {
          _state!.resetForNewDay();
          await prefs.remove(_todayActivitiesKey);
        }
      }
    }
    
    // Update last check
    await prefs.setString(_lastCheckKey, now.toIso8601String());
  }
  
  /// Save streak data to storage
  static Future<void> saveStreakData() async {
    if (_state == null) return;
    
    try {
      final data = _stateToData();
      await _saveLocalData(data);
      await _saveRemoteData(data);
    } catch (e) {
      debugPrint('Error saving streak data: $e');
    }
  }

  /// Serialize the current state into a map for persistence.
  static Map<String, dynamic> _stateToData() {
    return {
      'schemaVersion': _schemaVersion,
      'currentStreak': _state!.currentStreak,
      'longestStreak': _state!.longestStreak,
      'totalDaysActive': _state!.totalDaysActive,
      'freezeTokens': _state!.freezeTokens,
      'totalXpEarned': _state!.totalXpEarned,
      'lastActiveDate': _state!.lastActiveDate?.toIso8601String(),
      'streakStartDate': _state!.streakStartDate?.toIso8601String(),
      'isTodayCompleted': _state!.isTodayCompleted,
      'history': _state!.streakHistory.take(365).map((h) => h.toJson()).toList(),
      'milestones': _state!.milestones.map((m) => m.toJson()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  static Future<void> _saveLocalData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_streakDataKey, json.encode(data));
    await prefs.setString(
      _todayActivitiesKey,
      json.encode(_state!.todayActivities.map((a) => a.name).toList()),
    );
  }

  static Future<void> _saveRemoteData(Map<String, dynamic> data) async {
    return;
  }
  
  /// Record an activity and update streak
  static Future<void> recordActivity(
    StreakActivityType activity, {
    int xpEarned = 10,
  }) async {
    if (_state == null) return;
    
    final wasCompleted = _state!.isTodayCompleted;
    final previousStreak = _state!.currentStreak;
    
    _state!.recordActivity(activity, xpEarned: xpEarned);
    
    // Check for milestone achievement
    if (_state!.currentStreak > previousStreak) {
      final newlyUnlocked = _state!.milestones.where(
        (m) => m.isUnlocked && m.daysRequired == _state!.currentStreak,
      );
      
      for (final milestone in newlyUnlocked) {
        await _showMilestoneNotification(milestone);
      }
    }
    
    // Show first completion notification
    if (!wasCompleted && _state!.isTodayCompleted) {
      await _showStreakCompletedNotification();
    }
    
    await saveStreakData();
  }
  
  /// Use a streak freeze
  static Future<bool> useStreakFreeze() async {
    if (_state == null) return false;
    
    final success = _state!.useFreeze();
    if (success) {
      await saveStreakData();
    }
    return success;
  }
  
  /// Schedule streak reminder notifications
  static Future<void> _scheduleStreakNotifications() async {
    try {
      // Cancel existing streak notifications
      await NotificationService.cancelNotification(1001);
      await NotificationService.cancelNotification(1002);
      await NotificationService.cancelNotification(1003);
      
      // Schedule evening reminder at 7 PM
      final now = DateTime.now();
      var eveningReminder = DateTime(now.year, now.month, now.day, 19, 0);
      if (eveningReminder.isBefore(now)) {
        eveningReminder = eveningReminder.add(const Duration(days: 1));
      }
      
      await NotificationService.scheduleNotification(
        id: 1001,
        title: '🔥 Keep your streak alive!',
        body: 'Complete a quick activity to maintain your ${_state?.currentStreak ?? 0}-day streak!',
        scheduledDate: eveningReminder,
      );
      
      // Schedule night reminder at 9 PM for users who haven't completed
      var nightReminder = DateTime(now.year, now.month, now.day, 21, 0);
      if (nightReminder.isBefore(now)) {
        nightReminder = nightReminder.add(const Duration(days: 1));
      }
      
      await NotificationService.scheduleNotification(
        id: 1002,
        title: '⚠️ Streak at risk!',
        body: 'Only ${_state?.hoursUntilStreakLoss ?? 3} hours left to save your ${_state?.currentStreak ?? 0}-day streak!',
        scheduledDate: nightReminder,
      );
      
      // Schedule last chance at 11 PM
      var lastChance = DateTime(now.year, now.month, now.day, 23, 0);
      if (lastChance.isBefore(now)) {
        lastChance = lastChance.add(const Duration(days: 1));
      }
      
      await NotificationService.scheduleNotification(
        id: 1003,
        title: '🚨 Last chance for your streak!',
        body: 'You have 1 hour left! Open UpHeal now to keep your ${_state?.currentStreak ?? 0}-day streak!',
        scheduledDate: lastChance,
      );
      
      debugPrint('Streak notifications scheduled');
    } catch (e) {
      debugPrint('Error scheduling streak notifications: $e');
    }
  }
  
  /// Cancel streak notifications (when streak is completed)
  static Future<void> cancelStreakNotifications() async {
    try {
      await NotificationService.cancelNotification(1001);
      await NotificationService.cancelNotification(1002);
      await NotificationService.cancelNotification(1003);
    } catch (e) {
      debugPrint('Error canceling streak notifications: $e');
    }
  }
  
  /// Show streak completed notification
  static Future<void> _showStreakCompletedNotification() async {
    try {
      await cancelStreakNotifications();
      
      final streak = _state?.currentStreak ?? 1;
      final multiplier = _state?.streakMultiplier ?? 1.0;
      
      await NotificationService.showNotification(
        id: 1004,
        title: '🔥 Streak Extended!',
        body: 'Day $streak complete! You\'re earning ${multiplier}x XP bonus!',
      );
    } catch (e) {
      debugPrint('Error showing streak completed notification: $e');
    }
  }
  
  /// Show milestone achievement notification
  static Future<void> _showMilestoneNotification(StreakMilestone milestone) async {
    try {
      await NotificationService.showNotification(
        id: 1005,
        title: '🏆 Milestone Achieved!',
        body: '${milestone.emoji} ${milestone.title}: ${milestone.description} (+${milestone.xpReward} XP)',
      );
    } catch (e) {
      debugPrint('Error showing milestone notification: $e');
    }
  }
  
  /// Add freeze tokens from achievements or purchases
  static Future<void> addFreezeTokens(int count) async {
    if (_state == null) return;
    
    _state!.addFreezeTokens(count);
    await saveStreakData();
  }
  
  /// Get streak stats for display
  static Map<String, dynamic> getStreakStats() {
    if (_state == null) {
      return {
        'currentStreak': 0,
        'longestStreak': 0,
        'totalDays': 0,
        'completionRate7Days': 0.0,
        'completionRate30Days': 0.0,
        'multiplier': 1.0,
        'lastStreakBeforeBreak': 0,
        'hasRecentBreak': false,
        'recoveryStreak': 0,
      };
    }
    
    return {
      'currentStreak': _state!.currentStreak,
      'longestStreak': _state!.longestStreak,
      'totalDays': _state!.totalDaysActive,
      'completionRate7Days': _state!.getCompletionRate(7),
      'completionRate30Days': _state!.getCompletionRate(30),
      'multiplier': _state!.streakMultiplier,
      'lastStreakBeforeBreak': _state!.lastStreakBeforeBreak,
      'hasRecentBreak': _state!.isInRecoveryWindow,
      'recoveryStreak': _state!.recoveryStreak,
    };
  }
  
  /// Sync streak data through the backend once a streak endpoint exists.
  static Future<void> syncWithCloud() async {
    if (_state == null) return;
    await saveStreakData();
  }
}
