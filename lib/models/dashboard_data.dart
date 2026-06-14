import '../utils/format_duration.dart';

class DashboardData {
  final List<Map<String, dynamic>> usageData;
  final int focusScore;
  final int blockedCount;
  final int focusSessions;
  final int? socialMediaTimeSeconds;

  DashboardData({
    required this.usageData,
    required this.focusScore,
    this.blockedCount = 0,
    this.focusSessions = 0,
    this.socialMediaTimeSeconds,
  });

  int get todayTotalDuration {
    return usageData.fold<int>(0, (sum, item) {
      return sum + ((item['usageTime'] as int) ~/ 1000);
    });
  }

  String get formattedTotal => formatDuration(todayTotalDuration);

  int get appCount => usageData.length;

  String get formattedSocialMedia {
    if (socialMediaTimeSeconds != null) {
      return formatDuration(socialMediaTimeSeconds!);
    }
    final socialSeconds = usageData
        .where((app) {
          final cat = (app['category'] as String?)?.toLowerCase() ?? '';
          return cat == 'social';
        })
        .fold<int>(0, (sum, item) => sum + ((item['usageTime'] as int) ~/ 1000));
    return formatDuration(socialSeconds);
  }

  List<Map<String, dynamic>> get topApps => usageData.take(10).toList();

  static const int dailyGoalSeconds = 7200;

  bool get isOverLimit => todayTotalDuration > dailyGoalSeconds;

  int get overageSeconds => isOverLimit ? todayTotalDuration - dailyGoalSeconds : 0;

  int get remainingSeconds => !isOverLimit ? dailyGoalSeconds - todayTotalDuration : 0;

  double get limitProgress => todayTotalDuration / dailyGoalSeconds;
}
