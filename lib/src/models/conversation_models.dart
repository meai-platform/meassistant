import 'dart:convert';

/// Request model for creating a conversation
class CreateConversationRequest {
  final String customerId;
  final String lang;

  CreateConversationRequest({
    required this.customerId,
    this.lang = "en",
  });

  factory CreateConversationRequest.fromRawJson(String str) =>
      CreateConversationRequest.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CreateConversationRequest.fromJson(Map<String, dynamic> json) =>
      CreateConversationRequest(
        customerId: json["customerId"] as String,
        lang: json["lang"] as String? ?? "en",
      );

  Map<String, dynamic> toJson() => {
        "customerId": customerId,
        "lang": lang,
      };
}

/// Response model for creating a conversation
class CreateConversationResponse {
  final int? chatId;
  final String conversationId;
  final String customerId;
  final DateTime? createdAt;
  final String lang;
  final List<SuggestedPrompt>? suggestedPrompts;

  CreateConversationResponse({
    this.chatId,
    required this.conversationId,
    required this.customerId,
    this.createdAt,
    this.lang = "en",
    this.suggestedPrompts,
  });

  factory CreateConversationResponse.fromRawJson(String str) =>
      CreateConversationResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CreateConversationResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    List<SuggestedPrompt>? parseSuggestedPrompts(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value
            .map((x) => SuggestedPrompt.fromJson(x as Map<String, dynamic>))
            .toList();
      }
      return null;
    }

    return CreateConversationResponse(
      chatId: json["chatId"] as int?,
      conversationId: json["conversationId"] as String,
      customerId: json["customerId"] as String,
      createdAt: parseDateTime(json["createdAt"]),
      lang: json["lang"] as String? ?? "en",
      suggestedPrompts: parseSuggestedPrompts(json["suggestedPrompts"]),
    );
  }

  Map<String, dynamic> toJson() => {
        if (chatId != null) "chatId": chatId,
        "conversationId": conversationId,
        "customerId": customerId,
        if (createdAt != null) "createdAt": createdAt!.toIso8601String(),
        "lang": lang,
        if (suggestedPrompts != null)
          "suggestedPrompts":
              suggestedPrompts!.map((x) => x.toJson()).toList(),
      };
}

/// Suggested prompt model
class SuggestedPrompt {
  final int? promptId;
  final String promptEn;
  final String promptAr;

  SuggestedPrompt({
    this.promptId,
    required this.promptEn,
    required this.promptAr,
  });

  factory SuggestedPrompt.fromRawJson(String str) =>
      SuggestedPrompt.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SuggestedPrompt.fromJson(Map<String, dynamic> json) =>
      SuggestedPrompt(
        promptId: json["promptId"] as int?,
        promptEn: json["promptEn"] as String,
        promptAr: json["promptAr"] as String,
      );

  Map<String, dynamic> toJson() => {
        if (promptId != null) "promptId": promptId,
        "promptEn": promptEn,
        "promptAr": promptAr,
      };

  /// Get prompt text based on language
  String getPrompt(String lang) {
    return lang == "ar" ? promptAr : promptEn;
  }
}

/// Request model for sending a prompt
class SendPromptRequest {
  final String conversationId;
  final String prompt;

  SendPromptRequest({
    required this.conversationId,
    required this.prompt,
  });

  factory SendPromptRequest.fromRawJson(String str) =>
      SendPromptRequest.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SendPromptRequest.fromJson(Map<String, dynamic> json) =>
      SendPromptRequest(
        conversationId: json["conversationId"] as String,
        prompt: json["prompt"] as String,
      );

  Map<String, dynamic> toJson() => {
        "conversationId": conversationId,
        "prompt": prompt,
      };
}

