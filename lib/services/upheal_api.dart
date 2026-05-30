import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Base URL for the UpHeal backend.
///
/// Set via --dart-define=UPHEAL_API_URL=https://your-server.com at build time.
///
/// Default values for local development:
///   - Android emulator: http://10.0.2.2:8000
///   - Physical device: use your machine's local IP, e.g. http://192.168.x.x:8000
///
/// For production: always use HTTPS.
const String uphealBaseUrl = String.fromEnvironment(
  'UPHEAL_API_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class UphealApi {
  final String baseUrl;

  const UphealApi({required this.baseUrl});

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// Simple health check against `{baseUrl}/health`.
  Future<Map<String, dynamic>> health() async {
    final response = await http.get(_uri('/health'));
    if (response.statusCode != 200) {
      throw Exception(
        'Health check failed (${response.statusCode}): ${response.body}',
      );
    }
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      return body;
    }
    throw Exception('Unexpected health response shape.');
  }

  /// Call the assessment endpoint `{baseUrl}/api/assess`.
  ///
  /// Body:
  /// ```json
  /// {
  ///   "answers": { "gad7_q1": 0, ... },
  ///   "user_id": "user_123",
  ///   "session_id": "optional"
  /// }
  /// ```
  Future<Map<String, dynamic>> assess({
    required Map<String, int> answers,
    required String userId,
    String? authToken,
    String? sessionId,
  }) async {
    final uri = _uri('/api/assess');
    final payload = <String, dynamic>{
      'answers': answers,
      'user_id': userId,
    };
    if (sessionId != null) {
      payload['session_id'] = sessionId;
    }

    if (kDebugMode) {
      debugPrint('[UphealApi] POST $uri');
      debugPrint('[UphealApi] Answers count: ${answers.length}');
    }

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null && authToken.isNotEmpty)
            'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds.');
        },
      );

      if (kDebugMode) {
        debugPrint('[UphealApi] Response status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        if (kDebugMode) debugPrint('[UphealApi] Error: ${response.body}');
        throw Exception(
          'Assessment failed (${response.statusCode}). Please try again.',
        );
      }

      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (kDebugMode) debugPrint('[UphealApi] Response parsed successfully.');
        return body;
      }
      throw Exception('Unexpected assessment response format.');
    } catch (e) {
      if (kDebugMode) debugPrint('[UphealApi] Exception: $e');
      rethrow;
    }
  }
}
