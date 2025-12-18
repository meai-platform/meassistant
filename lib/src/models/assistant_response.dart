import 'dart:convert';

/// Response model from the assistant API (SendPromptPublicResponse)
class AssistantResponse {
  final String textResponse;
  final dynamic customObjectsTypes; // Can be List<String> or Map<String, String>
  final dynamic customObjects; // Can be List<dynamic> or Map<String, dynamic>
  final List<String>? suggestedResponses;
  final String? sentiment;
  final double? confidence;
  final int? triggeredCampaignId;

  AssistantResponse({
    required this.textResponse,
    this.customObjectsTypes,
    this.customObjects,
    this.suggestedResponses,
    this.sentiment,
    this.confidence,
    this.triggeredCampaignId,
  });

  factory AssistantResponse.fromRawJson(String str) =>
      AssistantResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    List<String>? parseStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((x) => x.toString()).toList();
      }
      return null;
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return AssistantResponse(
      textResponse: json["textResponse"] as String? ?? "",
      // Keep as dynamic to support both List and Map formats
      customObjectsTypes: json["customObjectsTypes"],
      customObjects: json["customObjects"],
      suggestedResponses: parseStringList(json["suggestedResponses"]),
      sentiment: json["sentiment"] as String?,
      confidence: parseDouble(json["confidence"]),
      triggeredCampaignId: json["triggeredCampaignId"] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        "textResponse": textResponse,
        if (customObjectsTypes != null) "customObjectsTypes": customObjectsTypes,
        if (customObjects != null) "customObjects": customObjects,
        if (suggestedResponses != null) "suggestedResponses": suggestedResponses,
        if (sentiment != null) "sentiment": sentiment,
        if (confidence != null) "confidence": confidence,
        if (triggeredCampaignId != null) "triggeredCampaignId": triggeredCampaignId,
      };
}

/// Internal chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;
  bool isAnimated;
  final AssistantResponse? assistantResponse;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.assistantResponse,
    this.isTyping = false,
    this.isAnimated = false,
  });
}

