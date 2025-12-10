import 'dart:convert';

/// Request model for sending prompts to the assistant API
class AssistantPromptRequest {
  final int sessionId;
  final int userId;
  final String prompt;

  AssistantPromptRequest({
    required this.sessionId,
    required this.userId,
    required this.prompt,
  });

  factory AssistantPromptRequest.fromRawJson(String str) =>
      AssistantPromptRequest.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory AssistantPromptRequest.fromJson(Map<String, dynamic> json) =>
      AssistantPromptRequest(
        sessionId: json["sessionId"],
        userId: json["userId"],
        prompt: json["prompt"],
      );

  Map<String, dynamic> toJson() => {
        "sessionId": sessionId,
        "userId": userId,
        "prompt": prompt,
      };
}

