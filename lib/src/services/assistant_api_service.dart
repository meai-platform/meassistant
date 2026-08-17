import 'package:dio/dio.dart';
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

  /// Send a prompt to the assistant.
  /// [inputType] marks how the prompt was produced: "text" (typed) or "voice" (transcribed).
  Future<AssistantResponse> sendPrompt(String conversationId, String prompt,
      {String inputType = 'text'}) async {
    _debugPrint('[MeAI SDK] 💬 Sending prompt to conversation: $conversationId');
    _debugPrint('[MeAI SDK] Prompt: ${prompt.substring(0, prompt.length > 100 ? 100 : prompt.length)}${prompt.length > 100 ? '...' : ''}');
    
    final request = SendPromptRequest(
      conversationId: conversationId,
      prompt: prompt,
      inputType: inputType,
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

  /// Transcribe a recorded voice message to text (server-side speech-to-text)
  Future<SpeechTranscription> transcribeAudio(
      String conversationId, String filePath) async {
    _debugPrint('[MeAI SDK] 🎙️ Transcribing audio for conversation: $conversationId');

    final response = await _apiService.postFormData(
      '/api/ai-chat/transcribe',
      {
        'conversationId': conversationId,
        'file': await MultipartFile.fromFile(filePath),
      },
    );

    if (response.statusCode != 200) {
      final errorMessage =
          response.data['error'] ?? response.statusMessage ?? 'Request failed';
      _debugPrint('[MeAI SDK] ❌ Failed to transcribe audio: $errorMessage');
      throw Exception('Failed to transcribe audio: $errorMessage');
    }

    final transcription = SpeechTranscription.fromJson(response.data);
    _debugPrint('[MeAI SDK] ✅ Transcription received');
    return transcription;
  }

  /// Synthesize speech audio for an assistant reply (server-side text-to-speech).
  /// Returns raw audio bytes (format decided by the backend speech config).
  Future<List<int>> synthesizeSpeech(String conversationId, String text) async {
    _debugPrint('[MeAI SDK] 🔊 Synthesizing speech for conversation: $conversationId');

    final response = await _apiService.postForBytes(
      '/api/ai-chat/synthesize',
      {
        'conversationId': conversationId,
        'text': text,
      },
    );

    if (response.statusCode != 200 || response.data == null || response.data!.isEmpty) {
      _debugPrint('[MeAI SDK] ❌ Failed to synthesize speech');
      throw Exception('Failed to synthesize speech');
    }

    _debugPrint('[MeAI SDK] ✅ Speech audio received (${response.data!.length} bytes)');
    return response.data!;
  }
}

