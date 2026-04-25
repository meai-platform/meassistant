// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AssistantStore on _AssistantStore, Store {
  late final _$messagesAtom =
      Atom(name: '_AssistantStore.messages', context: context);

  @override
  ObservableList<ChatMessage> get messages {
    _$messagesAtom.reportRead();
    return super.messages;
  }

  @override
  set messages(ObservableList<ChatMessage> value) {
    _$messagesAtom.reportWrite(value, super.messages, () {
      super.messages = value;
    });
  }

  late final _$isLoadingAssistantResponseAtom = Atom(
      name: '_AssistantStore.isLoadingAssistantResponse', context: context);

  @override
  bool get isLoadingAssistantResponse {
    _$isLoadingAssistantResponseAtom.reportRead();
    return super.isLoadingAssistantResponse;
  }

  @override
  set isLoadingAssistantResponse(bool value) {
    _$isLoadingAssistantResponseAtom
        .reportWrite(value, super.isLoadingAssistantResponse, () {
      super.isLoadingAssistantResponse = value;
    });
  }

  late final _$conversationIdAtom =
      Atom(name: '_AssistantStore.conversationId', context: context);

  @override
  String? get conversationId {
    _$conversationIdAtom.reportRead();
    return super.conversationId;
  }

  @override
  set conversationId(String? value) {
    _$conversationIdAtom.reportWrite(value, super.conversationId, () {
      super.conversationId = value;
    });
  }

  late final _$suggestedPromptsAtom =
      Atom(name: '_AssistantStore.suggestedPrompts', context: context);

  @override
  List<SuggestedPrompt>? get suggestedPrompts {
    _$suggestedPromptsAtom.reportRead();
    return super.suggestedPrompts;
  }

  @override
  set suggestedPrompts(List<SuggestedPrompt>? value) {
    _$suggestedPromptsAtom.reportWrite(value, super.suggestedPrompts, () {
      super.suggestedPrompts = value;
    });
  }

  late final _$isCreatingConversationAtom =
      Atom(name: '_AssistantStore.isCreatingConversation', context: context);

  @override
  bool get isCreatingConversation {
    _$isCreatingConversationAtom.reportRead();
    return super.isCreatingConversation;
  }

  @override
  set isCreatingConversation(bool value) {
    _$isCreatingConversationAtom
        .reportWrite(value, super.isCreatingConversation, () {
      super.isCreatingConversation = value;
    });
  }

  late final _$createConversationAsyncAction =
      AsyncAction('_AssistantStore.createConversation', context: context);

  @override
  Future<bool> createConversation() {
    return _$createConversationAsyncAction
        .run(() => super.createConversation());
  }

  late final _$sendPromptAsyncAction =
      AsyncAction('_AssistantStore.sendPrompt', context: context);

  @override
  Future<AssistantResponse?> sendPrompt(String prompt) {
    return _$sendPromptAsyncAction.run(() => super.sendPrompt(prompt));
  }

  late final _$_AssistantStoreActionController =
      ActionController(name: '_AssistantStore', context: context);

  @override
  void clearMessages() {
    final _$actionInfo = _$_AssistantStoreActionController.startAction(
        name: '_AssistantStore.clearMessages');
    try {
      return super.clearMessages();
    } finally {
      _$_AssistantStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
messages: ${messages},
isLoadingAssistantResponse: ${isLoadingAssistantResponse},
conversationId: ${conversationId},
suggestedPrompts: ${suggestedPrompts},
isCreatingConversation: ${isCreatingConversation}
    ''';
  }
}
