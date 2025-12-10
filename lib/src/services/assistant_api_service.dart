import '../config/assistant_config.dart';
import '../models/assistant_response.dart';
import '../models/conversation_models.dart';
import 'api_service.dart';

/// Service for interacting with the assistant API
class AssistantApiService {
  final ApiService _apiService;
  final AssistantConfig _config;

  AssistantApiService(this._apiService, this._config);

  void _debugPrint(String message) {
    if (_config.debug) {
      print(message);
    }
  }

  /// Create a new conversation
  Future<CreateConversationResponse> createConversation() async {
    _debugPrint('[MeAI SDK] 💬 Creating new conversation...');
    final customerId = _config.customerId;
    if (customerId == null || customerId.isEmpty) {
      _debugPrint('[MeAI SDK] ❌ Failed to create conversation: customerId is required');
      throw Exception('customerId is required for creating a conversation');
    }

    final request = CreateConversationRequest(
      customerId: customerId,
      lang: _config.lang,
    );

    _debugPrint('[MeAI SDK] Request: customerId=$customerId, lang=${_config.lang}');

    final response = await _apiService.post(
      '/api/ai-chat/conversations',
      request.toJson(),
    );

    _debugPrint('[MeAI SDK] Response Status: ${response.statusCode}');
    _debugPrint('[MeAI SDK] Response Data: ${response.data}');

    if (response.statusCode != 200) {
      final errorMessage = response.data['error'] ?? response.statusMessage ?? 'Request failed';
      _debugPrint('[MeAI SDK] ❌ Failed to create conversation: $errorMessage');
      throw Exception('Failed to create conversation: $errorMessage');
    }

    final responseDto = CreateConversationResponse.fromJson(response.data);
    _debugPrint('[MeAI SDK] ✅ Conversation created: ${responseDto.conversationId}');
    return responseDto;
  }

  /// Send a prompt to the assistant
  Future<AssistantResponse> sendPrompt(String conversationId, String prompt) async {
    _debugPrint('[MeAI SDK] 💬 Sending prompt to conversation: $conversationId');
    _debugPrint('[MeAI SDK] Prompt: ${prompt.substring(0, prompt.length > 100 ? 100 : prompt.length)}${prompt.length > 100 ? '...' : ''}');
    
    final request = SendPromptRequest(
      conversationId: conversationId,
      prompt: prompt,
    );

    final response = await _apiService.post(
      '/api/ai-chat/prompt',
      request.toJson(),
    );

    _debugPrint('[MeAI SDK] Response Status: ${response.statusCode}');
    _debugPrint('[MeAI SDK] Response Data: ${response.data}');

    if (response.statusCode != 200) {
      final errorMessage = response.data['error'] ?? response.statusMessage ?? 'Request failed';
      _debugPrint('[MeAI SDK] ❌ Failed to send prompt: $errorMessage');
      throw Exception('Failed to send prompt: $errorMessage');
    }

    final responseDto = AssistantResponse.fromJson(response.data);
    _debugPrint('[MeAI SDK] ✅ Prompt response received');
    if (responseDto.suggestedResponses != null && responseDto.suggestedResponses!.isNotEmpty) {
      _debugPrint('[MeAI SDK] Suggested Responses: ${responseDto.suggestedResponses!.length} prompts');
    }
    return responseDto;
  }
}

