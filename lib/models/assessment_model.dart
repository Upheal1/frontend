import 'upheal_roadmap.dart';

class AssessmentResponse {
  const AssessmentResponse({
    required this.userId,
    required this.overviewParagraph,
    required this.suggestedTasks,
    required this.safetyStatus,
    required this.nextCheckupDays,
    required this.days,
    required this.totalDays,
    required this.assessmentRequired,
    required this.timestamp,
    this.sessionId,
    this.anxietyProbability,
    this.depressionProbability,
    this.severity,
    this.comorbidity,
    this.ragRecommendations,
    this.queryUsed,
    this.screenTimeInsights,
  });

  final String userId;
  final String overviewParagraph;
  final List<ClinicalTask> suggestedTasks;
  final String safetyStatus;
  final int nextCheckupDays;
  final List<RoadmapDay> days;
  final int totalDays;
  final bool assessmentRequired;
  final String timestamp;
  final String? sessionId;
  final double? anxietyProbability;
  final double? depressionProbability;
  final Map<String, String>? severity;
  final String? comorbidity;
  final List<RagRecommendation>? ragRecommendations;
  final String? queryUsed;
  final ScreenTimeInsights? screenTimeInsights;

  factory AssessmentResponse.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['suggested_tasks'] as List<dynamic>? ?? [];
    final rawDays = json['days'] as List<dynamic>? ?? [];
    final rawRagRecs = json['rag_recommendations'] as List<dynamic>? ?? [];

    return AssessmentResponse(
      userId: json['user_id'] as String? ?? '',
      overviewParagraph: json['overview_paragraph'] as String? ?? '',
      suggestedTasks: rawTasks
          .map((e) => ClinicalTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      safetyStatus: json['safety_status'] as String? ?? 'GREEN',
      nextCheckupDays: (json['next_checkup_days'] as num?)?.toInt() ?? 7,
      days: rawDays
          .map((e) => RoadmapDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDays: (json['total_days'] as num?)?.toInt() ?? 90,
      assessmentRequired: json['assessment_required'] as bool? ?? false,
      timestamp: json['timestamp'] as String? ?? '',
      sessionId: json['session_id'] as String?,
      anxietyProbability: (json['anxiety_probability'] as num?)?.toDouble(),
      depressionProbability: (json['depression_probability'] as num?)?.toDouble(),
      severity: json['severity'] != null
          ? Map<String, String>.from(json['severity'] as Map)
          : null,
      comorbidity: json['comorbidity'] as String?,
      ragRecommendations: rawRagRecs
          .map((e) => RagRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
      queryUsed: json['query_used'] as String?,
      screenTimeInsights: json['screen_time_insights'] != null
          ? ScreenTimeInsights.fromJson(
              json['screen_time_insights'] as Map<String, dynamic>)
          : null,
    );
  }

  String get anxietySeverity => severity?['anxiety'] ?? 'unknown';
  String get depressionSeverity => severity?['depression'] ?? 'unknown';

  bool get hasHighAnxiety =>
      anxietyProbability != null && anxietyProbability! > 0.5;
  bool get hasHighDepression =>
      depressionProbability != null && depressionProbability! > 0.5;

  bool get needsImmediateAttention => safetyStatus == 'RED';
  bool get hasWarnings => safetyStatus == 'YELLOW';
}

class RagRecommendation {
  const RagRecommendation({
    required this.source,
    required this.section,
    required this.content,
    required this.similarity,
    this.pages,
  });

  final String source;
  final String section;
  final String content;
  final double similarity;
  final String? pages;

  factory RagRecommendation.fromJson(Map<String, dynamic> json) {
    return RagRecommendation(
      source: json['source'] as String? ?? '',
      section: json['section'] as String? ?? '',
      content: json['content'] as String? ?? '',
      similarity: (json['similarity'] as num?)?.toDouble() ?? 0.0,
      pages: json['pages'] as String?,
    );
  }

  int get similarityPercent => (similarity * 100).round();
}

class SeverityLevel {
  static const String minimal = 'minimal';
  static const String mild = 'mild';
  static const String moderate = 'moderate';
  static const String moderatelySevere = 'moderately severe';
  static const String severe = 'severe';

  static String fromProbability(double probability) {
    if (probability < 0.1) return minimal;
    if (probability < 0.3) return mild;
    if (probability < 0.5) return moderate;
    if (probability < 0.7) return moderatelySevere;
    return severe;
  }
}