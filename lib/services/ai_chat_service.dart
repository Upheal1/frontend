import 'dart:async';

import '../models/chat_model.dart';
import 'upheal_api.dart';

class AiChatService {
  static const Duration timeout = Duration(seconds: 30);

  static Future<ChatResponse> sendMessage({
    required String message,
    String? sessionId,
    String? roadmapId,
  }) async {
    try {
      final result = await UphealApi().sendChatMessage(
        message: message,
        sessionId: sessionId,
        roadmapId: roadmapId,
      );

      final response = ChatResponse.fromJson(result);
      return response;
    } on TimeoutException {
      throw Exception('Chat request timed out. Please try again.');
    } catch (e) {
      if (e.toString().contains('401')) {
        throw Exception('Session expired. Please sign in again.');
      }
      rethrow;
    }
  }

  static Future<ChatHistoryResponse> getHistory(String sessionId) async {
    try {
      final result = await UphealApi().getChatHistory(sessionId);
      final response = ChatHistoryResponse.fromJson(result);
      return response;
    } on TimeoutException {
      throw Exception('Chat history request timed out.');
    } catch (e) {
      if (e.toString().contains('404')) {
        throw Exception('Chat session not found.');
      }
      rethrow;
    }
  }

  static Future<void> sendMessageWithLocalFallback({
    required String message,
    String? sessionId,
    String? roadmapId,
    required void Function(String) onResponse,
    required void Function(String) onError,
  }) async {
    try {
      final response = await sendMessage(
        message: message,
        sessionId: sessionId,
        roadmapId: roadmapId,
      );
      onResponse(response.assistantMessage.content);
    } catch (e) {
      onError(e.toString());
    }
  }
}
