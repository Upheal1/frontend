import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'supabase_service.dart';

class _RedirectClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    var response = await _inner.send(request);

    // Follow up to 5 redirects
    int redirectCount = 0;
    while (_isRedirect(response) && redirectCount < 5) {
      final location = response.headers['location'];
      if (location == null) break;

      if (kDebugMode) {
        debugPrint('[UphealApi] Following redirect to: $location');
      }

      final newUri = request.url.resolve(location);
      final newRequest = http.Request(request.method, newUri);
      newRequest.headers.addAll(request.headers);
      if (request is http.Request) {
        newRequest.body = (request as http.Request).body;
      }

      response = await _inner.send(newRequest);
      redirectCount++;
    }

    return response;
  }

  bool _isRedirect(http.BaseResponse response) {
    return response.statusCode == 301 ||
        response.statusCode == 302 ||
        response.statusCode == 303 ||
        response.statusCode == 307 ||
        response.statusCode == 308;
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Base URL for the UpHeal Railway backend.
///
/// Set via --dart-define=UPHEAL_API_URL=https://your-server.com at build time.
///
/// Default production value: https://upheal-gateway.onrender.com
/// Local development: http://10.0.2.2:8000 (Android emulator) or http://localhost:8000
const String uphealBaseUrl = String.fromEnvironment(
  'UPHEAL_API_URL',
  defaultValue: 'https://upheal-rag.onrender.com'
);

class UphealApi {
  final String baseUrl;

  final http.Client _client;

  final Duration timeout;

  UphealApi({
    String? baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 90),
  })  : baseUrl = baseUrl ?? uphealBaseUrl,
        _client = client ?? _createRedirectClient();

  static http.Client _createRedirectClient() {
    return http.Client();
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// Builds HTTP headers for every request.
  ///
  /// When the user is signed in the Supabase JWT is injected automatically.
  /// The Flutter SDK refreshes the token before expiry, so this always
  /// returns a valid (non-expired) bearer token.
  Future<Map<String, String>> _getHeaders() async {
    final token = await SupabaseService.idToken;
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    debugPrint('[UphealApi] Token: ${token != null ? "present (${token.substring(0, 20)}...)" : "NULL"}');
    debugPrint('[UphealApi] UserId from SupabaseService: ${SupabaseService.userId}');
    debugPrint('[UphealApi] Headers: $headers');
    return headers;
  }

  // ─── Public endpoints ──────────────────────────────────────────────────────

  /// GET /health — confirms the backend and knowledge-base are reachable.
  /// This endpoint is PUBLIC (no auth required) - good for testing connectivity.
  Future<Map<String, dynamic>> health() async {
    final fullUrl = '$baseUrl/health';
    debugPrint('[UphealApi] GET $fullUrl (PUBLIC - no auth)');
    final response = await _client.get(_uri('/health'));
    debugPrint('[UphealApi] health → ${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception(
        'Health check failed (${response.statusCode}): ${response.body}',
      );
    }
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected health response shape.');
  }

  /// Test endpoint - sends a simple request to verify server connectivity
  /// Returns the raw response for debugging
  Future<String> testServerConnectivity() async {
    final fullUrl = '$baseUrl/health';
    debugPrint('[UphealApi] Testing connectivity to: $fullUrl');
    try {
      final response = await _client.get(_uri('/health'));
      return 'Status: ${response.statusCode}, Body: ${response.body}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// POST /api/assess — run the GAD-7 + PHQ-9 clinical assessment.
  ///
  /// [answers]        — Map of question keys to scores (0–3).
  ///                    Keys: gad7_q1…gad7_q7, phq9_q1…phq9_q9.
  /// [userId]         — Supabase user UUID.
  /// [sessionId]      — Optional; continues an existing session.
  /// [screenTimeData] — Optional per-app usage data.
  Future<Map<String, dynamic>> assess({
    required Map<String, int> answers,
    required String userId,
    String? sessionId,
    Map<String, dynamic>? screenTimeData,
  }) async {
    final headers = await _getHeaders();
    // biome-ignore-line: print
    print('========================================');
    print('🔐 FULL HEADERS TO SEND:');
    headers.forEach((key, value) => print('  $key: $value'));
    print('========================================');
    
    final payload = <String, dynamic>{
      'answers': answers,
      'user_id': userId,
    };
    if (sessionId != null) payload['session_id'] = sessionId;
    if (screenTimeData != null) payload['screenTimeData'] = screenTimeData;

    final fullUrl = '$baseUrl/api/assess';
    debugPrint('[UphealApi] POST $fullUrl  answers=${answers.length}  userId=$userId');

    try {
      // Create explicit request to debug
      final uri = Uri.parse(fullUrl);
      final request = http.Request('POST', uri);
      request.headers.addAll(headers);
      request.body = jsonEncode(payload);
      
      debugPrint('[UphealApi] Request headers: ${request.headers}');
      
      final response = await _client
          .post(
            _uri('/api/assess'),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(
            timeout,
            onTimeout: () =>
                throw TimeoutException('assess() timed out after 90 s.'),
          );

      if (kDebugMode) {
        debugPrint('[UphealApi] assess → ${response.statusCode}');
        debugPrint('[UphealApi] response headers: ${response.headers}');
      }

      if (response.statusCode == 307 || response.statusCode == 301 || response.statusCode == 302) {
        final location = response.headers['location'];
        if (kDebugMode) {
          debugPrint('[UphealApi] Redirect detected: ${response.statusCode}');
          debugPrint('[UphealApi] Location: $location');
        }
        throw Exception(
          'Server redirect (${response.statusCode}). Please check your API URL is correct. Location: $location',
        );
      }

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[UphealApi] error: ${response.body}');
          debugPrint('[UphealApi] Full URL was: $baseUrl/api/assess');
        }
        throw Exception(
          'Assessment failed (${response.statusCode}). Please try again.',
        );
      }

      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected assess response shape.');
    } catch (e) {
      if (kDebugMode) debugPrint('[UphealApi] assess exception: $e');
      rethrow;
    }
  }

  /// POST /api/roadmap — generate a new personalised wellness roadmap.
  ///
  /// [topN] controls how many tasks are returned (1–10, default 5 on the server).
  Future<Map<String, dynamic>> roadmap({
    required String userId,
    required Map<String, int> answers,
    Map<String, dynamic>? screenTimeData,
    int? topN,
  }) async {
    final headers = await _getHeaders();
    final payload = <String, dynamic>{
      'user_id': userId,
      'answers': answers,
    };
    if (screenTimeData != null) payload['screenTimeData'] = screenTimeData;
    if (topN != null) payload['top_n'] = topN;

    if (kDebugMode) {
      debugPrint('[UphealApi] POST /api/roadmap  topN=$topN');
    }

    final response = await _client
        .post(
          _uri('/api/roadmap'),
          headers: headers,
          body: jsonEncode(payload),
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('roadmap() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] roadmap → ${response.statusCode}');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to generate roadmap (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected roadmap response shape.');
  }

  // ─── Auth-protected endpoints (🔒 JWT required) ───────────────────────────

  /// GET /api/roadmap/{userId} — fetch the user's current active roadmap.
  ///
  /// Throws a descriptive [Exception] on:
  ///   - 401: user not signed in
  ///   - 404: no roadmap has been generated yet
  Future<Map<String, dynamic>> roadmapStatus(String userId) async {
    final headers = await _getHeaders();

    if (kDebugMode) {
      debugPrint('[UphealApi] GET /api/roadmap/$userId');
    }

    final response = await _client
        .get(
          _uri('/api/roadmap/$userId'),
          headers: headers,
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('roadmapStatus() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] roadmapStatus → ${response.statusCode}');
    }

    if (response.statusCode == 401) {
      throw Exception('Not authenticated. Please sign in.');
    }
    if (response.statusCode == 404) {
      throw Exception('No roadmap found for user $userId.');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get roadmap status (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected roadmapStatus response shape.');
  }

  /// GET /api/roadmap/{userId}/history — fetch past roadmaps for the user.
  ///
  /// Returns `{ "roadmaps": [...], "total_count": int }`.
  ///
  /// Throws a descriptive [Exception] on:
  ///   - 401: user not signed in
  ///   - 404: no history for this user
  Future<Map<String, dynamic>> roadmapHistory(String userId) async {
    final headers = await _getHeaders();

    if (kDebugMode) {
      debugPrint('[UphealApi] GET /api/roadmap/$userId/history');
    }

    final response = await _client
        .get(
          _uri('/api/roadmap/$userId/history'),
          headers: headers,
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('roadmapHistory() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] roadmapHistory → ${response.statusCode}');
    }

    if (response.statusCode == 401) {
      throw Exception('Not authenticated. Please sign in.');
    }
    if (response.statusCode == 404) {
      throw Exception('No roadmap history found for user $userId.');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get roadmap history (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected roadmapHistory response shape.');
  }

  // ─── Chat endpoints ─────────────────────────────────────────────────────

  /// POST /api/chat — send a message to the AI therapist chatbot.
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    String? sessionId,
    String? roadmapId,
  }) async {
    final headers = await _getHeaders();
    final payload = <String, dynamic>{
      'message': message,
      if (sessionId != null) 'session_id': sessionId,
      if (roadmapId != null) 'roadmap_id': roadmapId,
    };

    if (kDebugMode) {
      debugPrint('[UphealApi] POST /api/chat');
    }

    final response = await _client
        .post(
          _uri('/api/chat'),
          headers: headers,
          body: jsonEncode(payload),
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('sendChatMessage() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] sendChatMessage → ${response.statusCode}');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to send message (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected chat response shape.');
  }

  /// GET /api/chat/{sessionId}/history — retrieve chat history.
  Future<Map<String, dynamic>> getChatHistory(String sessionId) async {
    final headers = await _getHeaders();

    if (kDebugMode) {
      debugPrint('[UphealApi] GET /api/chat/$sessionId/history');
    }

    final response = await _client
        .get(
          _uri('/api/chat/$sessionId/history'),
          headers: headers,
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('getChatHistory() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] getChatHistory → ${response.statusCode}');
    }

    if (response.statusCode == 404) {
      throw Exception('Chat session not found: $sessionId');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get chat history (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected chat history response shape.');
  }

  // ─── Journal endpoints ───────────────────────────────────────────────────

  /// GET /api/journal — list journal entries.
  Future<Map<String, dynamic>> listJournal({
    int page = 1,
    int limit = 20,
    bool includeArchived = false,
  }) async {
    final headers = await _getHeaders();
    final queryParams = 'page=$page&limit=$limit&include_archived=$includeArchived';

    if (kDebugMode) {
      debugPrint('[UphealApi] GET /api/journal?$queryParams');
    }

    final response = await _client
        .get(
          _uri('/api/journal?$queryParams'),
          headers: headers,
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('listJournal() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] listJournal → ${response.statusCode}');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to list journal entries (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected journal list response shape.');
  }

  /// POST /api/journal — create a new journal entry.
  Future<Map<String, dynamic>> createJournal({
    required String title,
    required String content,
    String? mood,
    int? moodRating,
    List<String>? tags,
  }) async {
    final headers = await _getHeaders();
    final payload = <String, dynamic>{
      'title': title,
      'content': content,
      if (mood != null) 'mood': mood,
      if (moodRating != null) 'mood_rating': moodRating,
      if (tags != null) 'tags': tags,
    };

    if (kDebugMode) {
      debugPrint('[UphealApi] POST /api/journal');
    }

    final response = await _client
        .post(
          _uri('/api/journal'),
          headers: headers,
          body: jsonEncode(payload),
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('createJournal() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] createJournal → ${response.statusCode}');
    }

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) return body;
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create journal entry (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected create journal response shape.');
  }

  /// GET /api/journal/{entryId} — get a single journal entry.
  Future<Map<String, dynamic>> getJournal(String entryId) async {
    final headers = await _getHeaders();

    if (kDebugMode) {
      debugPrint('[UphealApi] GET /api/journal/$entryId');
    }

    final response = await _client
        .get(
          _uri('/api/journal/$entryId'),
          headers: headers,
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('getJournal() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] getJournal → ${response.statusCode}');
    }

    if (response.statusCode == 404) {
      throw Exception('Journal entry not found: $entryId');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get journal entry (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected journal entry response shape.');
  }

  /// PUT /api/journal/{entryId} — update a journal entry.
  Future<Map<String, dynamic>> updateJournal(
    String entryId, {
    String? title,
    String? content,
    String? mood,
    int? moodRating,
    List<String>? tags,
  }) async {
    final headers = await _getHeaders();
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title;
    if (content != null) payload['content'] = content;
    if (mood != null) payload['mood'] = mood;
    if (moodRating != null) payload['mood_rating'] = moodRating;
    if (tags != null) payload['tags'] = tags;

    if (kDebugMode) {
      debugPrint('[UphealApi] PUT /api/journal/$entryId');
    }

    final response = await _client
        .put(
          _uri('/api/journal/$entryId'),
          headers: headers,
          body: jsonEncode(payload),
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('updateJournal() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] updateJournal → ${response.statusCode}');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update journal entry (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected update journal response shape.');
  }

  /// DELETE /api/journal/{entryId} — archive (soft-delete) a journal entry.
  Future<void> archiveJournal(String entryId) async {
    final headers = await _getHeaders();

    if (kDebugMode) {
      debugPrint('[UphealApi] DELETE /api/journal/$entryId');
    }

    final response = await _client
        .delete(
          _uri('/api/journal/$entryId'),
          headers: headers,
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('archiveJournal() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] archiveJournal → ${response.statusCode}');
    }

    if (response.statusCode != 204) {
      throw Exception(
        'Failed to archive journal entry (${response.statusCode}): ${response.body}',
      );
    }
  }

  // ─── Telemetry endpoint ─────────────────────────────────────────────────

  /// POST /api/telemetry/ — log user-task interaction (unauthenticated).
  Future<Map<String, dynamic>> logTelemetry({
    required String userId,
    required String taskId,
    required String interactionType,
    int? completionTime,
    double? dropOffPoint,
    int xpEarned = 0,
    String? dedupeKey,
    int? userRating,
    String? feedbackText,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'task_id': taskId,
      'interaction_type': interactionType,
      if (completionTime != null) 'completion_time': completionTime,
      if (dropOffPoint != null) 'drop_off_point': dropOffPoint,
      'xp_earned': xpEarned,
      if (dedupeKey != null) 'dedupe_key': dedupeKey,
      if (userRating != null) 'user_rating': userRating,
      if (feedbackText != null) 'feedback_text': feedbackText,
    };

    if (kDebugMode) {
      debugPrint('[UphealApi] POST /api/telemetry/');
    }

    final response = await _client
        .post(
          _uri('/api/telemetry/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('logTelemetry() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] logTelemetry → ${response.statusCode}');
    }

    if (response.statusCode == 204) {
      return {'idempotent': true};
    }
    if (response.statusCode != 201) {
      throw Exception(
        'Failed to log telemetry (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected telemetry response shape.');
  }

  // ─── Audit endpoint ───────────────────────────────────────────────────────

  /// POST /audit — run a clinical safety audit (unauthenticated).
  Future<Map<String, dynamic>> audit({
    required String userId,
    required String overviewParagraph,
    required List<Map<String, dynamic>> taskContents,
    String locale = 'en',
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'overview_paragraph': overviewParagraph,
      'task_contents': taskContents,
      'locale': locale,
    };

    if (kDebugMode) {
      debugPrint('[UphealApi] POST /audit');
    }

    final response = await _client
        .post(
          _uri('/audit'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('audit() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] audit → ${response.statusCode}');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to run audit (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected audit response shape.');
  }

  // ─── Service health checks ───────────────────────────────────────────────

  /// GET /assessment/health — assessment service health check.
  Future<Map<String, dynamic>> assessmentHealth() async {
    final response = await _client.get(_uri('/assessment/health'));
    if (response.statusCode != 200) {
      throw Exception('Assessment service unhealthy: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /knowledge_base/health — knowledge base health check.
  Future<Map<String, dynamic>> knowledgeBaseHealth() async {
    final response = await _client.get(_uri('/knowledge_base/health'));
    if (response.statusCode != 200) {
      throw Exception('Knowledge base unhealthy: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /api/roadmap/health — roadmap service health check.
  Future<Map<String, dynamic>> roadmapServiceHealth() async {
    final response = await _client.get(_uri('/api/roadmap/health'));
    if (response.statusCode != 200) {
      throw Exception('Roadmap service unhealthy: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /api/roadmap/{userId}/status — check if user needs to retake assessment.
  ///
  /// Returns reassessment status including:
  /// - roadmap_id, roadmap_status, current_day, total_days
  /// - assessment_required (true if user needs to retake assessment)
  /// - days_since_last_assessment
  Future<Map<String, dynamic>> getRoadmapStatus(String userId) async {
    final headers = await _getHeaders();

    if (kDebugMode) {
      debugPrint('[UphealApi] GET /api/roadmap/$userId/status');
    }

    final response = await _client
        .get(
          _uri('/api/roadmap/$userId/status'),
          headers: headers,
        )
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('getRoadmapStatus() timed out after 90 s.'),
        );

    if (kDebugMode) {
      debugPrint('[UphealApi] getRoadmapStatus → ${response.statusCode}');
    }

    if (response.statusCode == 401) {
      throw Exception('Not authenticated. Please sign in.');
    }
    if (response.statusCode == 404) {
      throw Exception('No roadmap status found for user $userId.');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get roadmap status (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Unexpected roadmap status response shape.');
  }
}
