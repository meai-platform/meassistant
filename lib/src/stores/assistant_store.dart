import 'package:mobx/mobx.dart';
import 'package:dio/dio.dart';
import '../models/assistant_response.dart';
import '../models/conversation_models.dart';
import '../services/assistant_api_service.dart';
import '../services/assistant_service.dart';

part 'assistant_store.g.dart';

/// Store for managing assistant state and messages
class AssistantStore = _AssistantStore with _$AssistantStore;

abstract class _AssistantStore with Store {
  final AssistantApiService _assistantApiService;
  final AssistantService? _assistantService;

  _AssistantStore(this._assistantApiService, this._assistantService);

  @observable
  ObservableList<ChatMessage> messages = ObservableList();

  @observable
  bool isLoadingAssistantResponse = false;

  @observable
  String? conversationId;

  @observable
  List<SuggestedPrompt>? suggestedPrompts;

  @observable
  bool isCreatingConversation = false;

  @action
  Future<bool> createConversation() async {
    if (isCreatingConversation) {
      return false;
    }
    isCreatingConversation = true;
    try {
      final result = await _assistantApiService.createConversation();
      conversationId = result.conversationId;
      suggestedPrompts = result.suggestedPrompts;
      isCreatingConversation = false;
      return true;
    } catch (err) {
      isCreatingConversation = false;
      
      // Check if this is an authentication error
      bool isAuthError = false;
      if (err is DioException) {
        // Check for 401 Unauthorized or authentication-related errors
        if (err.response?.statusCode == 401) {
          isAuthError = true;
        } else if (err.message?.toLowerCase().contains('authentication') == true ||
                   err.message?.toLowerCase().contains('unauthorized') == true) {
          isAuthError = true;
        }
      } else if (err is Exception) {
        final errorMessage = err.toString().toLowerCase();
        if (errorMessage.contains('authentication') ||
            errorMessage.contains('unauthorized') ||
            errorMessage.contains('token') ||
            errorMessage.contains('401')) {
          isAuthError = true;
        }
      }
      
      // Close modal immediately if authentication failed
      if (isAuthError && _assistantService != null) {
        _assistantService!.hideModal();
      }
      
      return false;
    }
  }

  @action
  Future<AssistantResponse?> sendPrompt(String prompt) async {
    if (isLoadingAssistantResponse) {
      return null;
    }
    
    if (conversationId == null) {
      // Try to create conversation if not exists
      final created = await createConversation();
      if (!created) {
        return AssistantResponse(
          textResponse: "Sorry, I cannot help you with that right now. Please try again later.",
        );
      }
    }

    isLoadingAssistantResponse = true;
    try {
      final result = await _assistantApiService.sendPrompt(conversationId!, prompt);
      isLoadingAssistantResponse = false;
      return result;
    } catch (err) {
      isLoadingAssistantResponse = false;
      
      // Check if this is an authentication error
      bool isAuthError = false;
      if (err is DioException) {
        // Check for 401 Unauthorized or authentication-related errors
        if (err.response?.statusCode == 401) {
          isAuthError = true;
        } else if (err.message?.toLowerCase().contains('authentication') == true ||
                   err.message?.toLowerCase().contains('unauthorized') == true) {
          isAuthError = true;
        }
      } else if (err is Exception) {
        final errorMessage = err.toString().toLowerCase();
        if (errorMessage.contains('authentication') ||
            errorMessage.contains('unauthorized') ||
            errorMessage.contains('token') ||
            errorMessage.contains('401')) {
          isAuthError = true;
        }
      }
      
      // Close modal immediately if authentication failed
      if (isAuthError && _assistantService != null) {
        _assistantService!.hideModal();
      }
      
      return AssistantResponse(
        textResponse: "Sorry I cannot help you with that right now.",
      );
    }
  }

  @action
  void clearMessages() {
    messages.clear();
    conversationId = null;
    suggestedPrompts = null;
  }
}

