import '../models/mood_entry.dart';

/// Backend sync placeholder for mood entries.
///
/// Direct database access was removed from the frontend. Mood data remains
/// offline-first until the UpHeal backend exposes mood endpoints.
class MoodApiService {
  Future<void> saveEntry(MoodEntry entry) async {}

  Future<List<MoodEntry>> getEntries() async {
    return [];
  }

  Future<MoodEntry?> getEntryByDate(DateTime date) async {
    return null;
  }

  Future<List<MoodEntry>> getEntriesInRange(
    DateTime start,
    DateTime end,
  ) async {
    return [];
  }

  Future<void> deleteEntry(String id) async {}

  Future<List<MoodEntry>> getEntriesForAnalysis({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    return [];
  }

  Future<Map<String, dynamic>> analyzeEntry(String entryId) async {
    return {
      'status': 'not_available',
      'message': 'Mood analysis is waiting for a backend endpoint.',
    };
  }

  Future<Map<String, dynamic>> analyzeMoodTrends({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return {
      'status': 'not_available',
      'message': 'Mood trend analysis is waiting for a backend endpoint.',
    };
  }
}
