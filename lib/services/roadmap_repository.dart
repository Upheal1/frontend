import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/upheal_roadmap.dart';
import 'upheal_api.dart';
import 'screen_time_service.dart';

/// Repository that wraps [UphealApi] roadmap endpoints and converts raw
/// `Map<String,dynamic>` responses into typed [RoadmapFullResponse] objects.
///
/// Provides enhanced error handling, retry logic, and screen time integration.
class RoadmapRepository {
  RoadmapRepository(this._api);

  final UphealApi _api;

  /// Cached roadmap to prevent redundant API calls
  RoadmapFullResponse? _cachedRoadmap;
  DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Calls `POST /api/roadmap` and returns a typed [RoadmapFullResponse].
  ///
  /// [userId]         — Supabase user UUID (required).
  /// [answers]        — Optional GAD-7/PHQ-9 answer map.
  /// [screenTimeData] — Optional per-app screen time payload.
  /// [topN]           — Number of tasks to return (1–10).
  /// [retries]        — Number of retry attempts on failure (default 2).
  Future<RoadmapFullResponse> generateRoadmap({
    required String userId,
    Map<String, int>? answers,
    Map<String, dynamic>? screenTimeData,
    int? topN,
    int retries = 2,
  }) async {
    Exception? lastError;
    
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        // Collect screen time data if not provided
        final effectiveScreenTime = screenTimeData ?? await _collectScreenTimeData();
        
        final raw = await _api.roadmap(
          userId: userId,
          answers: answers ?? {},
          screenTimeData: effectiveScreenTime,
          topN: topN,
        );
        
        final response = RoadmapFullResponse.fromJson(raw);
        
        // Update cache
        _cachedRoadmap = response;
        _lastFetchTime = DateTime.now();
        
        return response;
      } on TimeoutException {
        lastError = Exception('Roadmap generation timed out. Please try again.');
        debugPrint('[RoadmapRepository] Timeout on attempt ${attempt + 1}');
      } on Exception catch (e) {
        lastError = e;
        debugPrint('[RoadmapRepository] Error on attempt ${attempt + 1}: $e');
        
        // Don't retry on authentication errors
        if (e.toString().contains('401') || e.toString().contains('Not authenticated')) {
          rethrow;
        }
      }
      
      // Wait before retry (exponential backoff)
      if (attempt < retries) {
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    
    throw lastError ?? Exception('Failed to generate roadmap after ${retries + 1} attempts');
  }

  /// Calls `GET /api/roadmap/{userId}` 🔒 and returns the active roadmap.
  ///
  /// Uses cached data if available and not expired.
  /// Throws if the user is unauthenticated or has no roadmap yet.
  Future<RoadmapFullResponse> getCurrentRoadmap(
    String userId, {
    bool forceRefresh = false,
    int retries = 2,
  }) async {
    // Return cached data if valid
    if (!forceRefresh && _isCacheValid()) {
      debugPrint('[RoadmapRepository] Returning cached roadmap');
      return _cachedRoadmap!;
    }

    Exception? lastError;
    
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final raw = await _api.roadmapStatus(userId);
        final response = RoadmapFullResponse.fromJson(raw);
        
        // Update cache
        _cachedRoadmap = response;
        _lastFetchTime = DateTime.now();
        
        return response;
      } on TimeoutException {
        lastError = Exception('Failed to fetch roadmap: connection timed out.');
        debugPrint('[RoadmapRepository] Fetch timeout on attempt ${attempt + 1}');
      } on Exception catch (e) {
        // 404 means no roadmap exists - return null to trigger generation
        if (e.toString().contains('404') || e.toString().contains('No roadmap found')) {
          _cachedRoadmap = null;
          rethrow;
        }
        lastError = e;
        debugPrint('[RoadmapRepository] Fetch error on attempt ${attempt + 1}: $e');
        
        // Don't retry on auth errors
        if (e.toString().contains('401') || e.toString().contains('Not authenticated')) {
          rethrow;
        }
      }
      
      if (attempt < retries) {
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    
    throw lastError ?? Exception('Failed to fetch roadmap after ${retries + 1} attempts');
  }

  /// Calls `GET /api/roadmap/{userId}/history` 🔒 and returns all past
  /// roadmaps for this user (most recent first).
  ///
  /// Returns an empty list if the endpoint responds with 404.
  Future<List<RoadmapFullResponse>> getRoadmapHistory(String userId) async {
    try {
      final raw = await _api.roadmapHistory(userId);
      final list = raw['roadmaps'] as List<dynamic>? ?? [];
      return list
          .map((e) => RoadmapFullResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception catch (e) {
      if (e.toString().contains('404') ||
          e.toString().contains('No roadmap history')) {
        return [];
      }
      rethrow;
    }
  }

  /// Clears the cached roadmap (e.g., after task completion or logout).
  void clearCache() {
    _cachedRoadmap = null;
    _lastFetchTime = null;
    debugPrint('[RoadmapRepository] Cache cleared');
  }

  /// Check if cache is valid
  bool _isCacheValid() {
    if (_cachedRoadmap == null || _lastFetchTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration;
  }

  /// Collect screen time data from the ScreenTimeService
  /// Returns null if permission is not granted or data unavailable
  Future<Map<String, dynamic>?> _collectScreenTimeData() async {
    try {
      final hasPermission = await ScreenTimeService.checkUsageStatsPermission();
      if (!hasPermission) {
        debugPrint('[RoadmapRepository] No screen time permission');
        return null;
      }

      final stats = await ScreenTimeService.getUsageStats();
      if (stats == null) {
        return null;
      }

      final totalMs = stats['totalScreenTime'] as int? ?? 0;
      final categoryUsage = stats['categoryUsage'] as Map<String, int>? ?? {};
      final appUsage = stats['appUsage'] as Map<String, int>? ?? {};

      // Convert milliseconds to minutes
      final totalMinutes = (totalMs / 60000).roundToDouble();
      final socialMinutes = ((categoryUsage['social'] ?? 0) / 60000).roundToDouble();
      final productivityMinutes = ((categoryUsage['productivity'] ?? 0) / 60000).roundToDouble();

      // Build daily usage list (top apps by usage)
      final sortedApps = appUsage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final dailyUsage = sortedApps.take(10).map((entry) {
        final packageName = entry.key;
        final usageMs = entry.value;
        final category = _categorizeAppByName(packageName);
        
        return {
          'packageName': packageName,
          'usageTime': (usageMs / 60000).round(),
          'category': category,
        };
      }).toList();

      return {
        'totalMinutes': totalMinutes,
        'socialMinutes': socialMinutes,
        'productivityMinutes': productivityMinutes,
        'dailyUsage': dailyUsage,
      };
    } catch (e) {
      debugPrint('[RoadmapRepository] Error collecting screen time: $e');
      return null;
    }
  }

  /// Categorize app by package name when category not available
  String _categorizeAppByName(String packageName) {
    final package = packageName.toLowerCase();
    
    // Social apps
    final socialApps = [
      'instagram', 'facebook', 'twitter', 'snapchat', 'whatsapp', 
      'telegram', 'discord', 'tiktok', 'youtube', 'messenger',
      'wechat', 'line', 'viber', 'signal',
    ];
    
    // Productivity apps
    final productivityApps = [
      'gmail', 'docs', 'sheets', 'slides', 'word', 'excel', 
      'powerpoint', 'notion', 'evernote', 'slack', 'zoom', 
      'teams', 'outlook', 'calendar', 'keep',
    ];
    
    for (final app in socialApps) {
      if (package.contains(app)) return 'social';
    }
    
    for (final app in productivityApps) {
      if (package.contains(app)) return 'productivity';
    }
    
    return 'other';
  }
}