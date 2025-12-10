import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';
import '../config/assistant_config.dart';
import '../models/assistant_response.dart';
import '../models/conversation_models.dart';
import '../services/assistant_service.dart';
import '../stores/assistant_store.dart';
import 'typing_text.dart';

/// Modal widget that displays the assistant chat interface
class AssistantModal extends StatefulWidget {
  final AssistantConfig config;
  final AssistantStore assistantStore;
  final AssistantService assistantService;

  const AssistantModal({
    Key? key,
    required this.config,
    required this.assistantStore,
    required this.assistantService,
  }) : super(key: key);

  @override
  State<AssistantModal> createState() => _AssistantModalState();
}

class _AssistantModalState extends State<AssistantModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _conversationAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late StreamSubscription<bool> keyboardSubscription;

  FocusNode _textFieldFocusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isKeyboardVisible = false;
  bool _isInConversation = false;
  bool _isTyping = false;
  bool _isFirstTime = true;
  bool _isDontAnimateLastMsg = false;
  bool _isAnimatingText = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _conversationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _conversationAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((bool visible) {
      setState(() {
        _isKeyboardVisible = visible;
        if (_isKeyboardVisible) {
          Future.delayed(const Duration(milliseconds: 300)).then((v) {
            _scrollToBottomAnimate();
          });
        }
      });
    });

    // Automatically create conversation when modal opens
    _createConversationIfNeeded();
  }

  void _createConversationIfNeeded() async {
    // Only create conversation if one doesn't exist and we're not already creating one
    if (widget.assistantStore.conversationId == null && 
        !widget.assistantStore.isCreatingConversation) {
      final success = await widget.assistantStore.createConversation();
      if (success && mounted) {
        setState(() {}); // Refresh UI to show suggested prompts
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _conversationAnimationController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    keyboardSubscription.cancel();
    super.dispose();
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      widget.assistantService.hideModal();
    });
  }

  void _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final userMessage = _textController.text.trim();
    _textController.clear();
    _textFieldFocusNode.unfocus();

    setState(() {
      widget.assistantStore.messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isInConversation = true;
      _isTyping = true;
    });

    _conversationAnimationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    AssistantResponse? response =
        await widget.assistantStore.sendPrompt(userMessage.trim());

    setState(() {
      _isTyping = false;
      widget.assistantStore.messages.add(ChatMessage(
        text: response!.textResponse,
        isUser: false,
        timestamp: DateTime.now(),
        assistantResponse: response,
      ));
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    }
  }

  void _scrollToBottomAnimate() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => Observer(
            builder: (_) {
              if (_isFirstTime) {
                _isFirstTime = false;
                _isInConversation = widget.assistantStore.messages.isNotEmpty;
                if (_isInConversation) {
                  _isDontAnimateLastMsg = true;
                  _conversationAnimationController.forward();
                }
              }
              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Scaffold(
                    backgroundColor: Colors.transparent,
                    resizeToAvoidBottomInset: true,
                    body: Stack(
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: GestureDetector(
                            onTap: _closeModal,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: widget.config.effectiveColorScheme.overlayBackgroundColor,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 1),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.easeOutCubic,
                            )),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildBottomSheetContent(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildBottomSheetContent() {
    return GestureDetector(
      onTap: () {
        // Unfocus the text field if it has focus
        if (_textFieldFocusNode.hasFocus) {
          _textFieldFocusNode.unfocus();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height *
              (_isKeyboardVisible ? 0.5 : 0.9),
          minHeight: MediaQuery.of(context).size.height *
              (_isKeyboardVisible ? 0.5 : 0.9),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: widget.config.effectiveColorScheme.modalBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border.all(
                  color: widget.config.effectiveColorScheme.modalBorderColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.config.effectiveColorScheme.modalShadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child:                       Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: widget.config.effectiveColorScheme.handleBarColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Icon(
                        //   Icons.access_time,
                        //   size: 24,
                        //   color: widget.config.effectiveColorScheme.textColor,
                        // ),
                        GestureDetector(
                          onTap: _closeModal,
                          child: Icon(
                            Icons.close,
                            size: 24,
                            color: widget.config.effectiveColorScheme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                      },
                      behavior: HitTestBehavior.translucent,
                    child: Stack(
                      children: [
                        if (!_isInConversation) _buildWelcomeScreen(),
                        if (_isInConversation) _buildConversationScreen(),
                      ],
                      ),
                    ),
                  ),
                  _buildInputArea(),
                  SizedBox(
                    height: _isKeyboardVisible ? 0 : 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return AnimatedOpacity(
      opacity: _isInConversation ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          Expanded(
            flex: _isKeyboardVisible ? 6 : 1,
            child: Container(),
          ),
          _buildImage(
            widget.config.logoPath ?? 'packages/meai_assistant/assets/images/ai_button.png',
            width: 90,
          ),
          const SizedBox(height: 16),
          Text(
            widget.config.assistantName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: widget.config.effectiveColorScheme.primaryColor,
              fontFamily: widget.config.fontFamily ?? 'ReadexPro',
            ),
          ),
          const SizedBox(height: 30),
          Text(
            widget.config.introText,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: widget.config.effectiveColorScheme.textColor,
              fontFamily: widget.config.fontFamily ?? 'ReadexPro',
            ),
            textAlign: TextAlign.center,
          ),
          Expanded(child: Container()),
          Observer(
            builder: (_) {
              // Use API suggested prompts if available, otherwise fall back to config
              final prompts = widget.assistantStore.suggestedPrompts;
              final lang = widget.config.lang;
              
              // Show skeleton loading when creating conversation
              if (widget.assistantStore.isCreatingConversation && !_isKeyboardVisible) {
                return Container(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: List.generate(3, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _buildSuggestionCardSkeleton(),
                      );
                    }),
                  ),
                );
              }
              
              if (prompts != null && prompts.isNotEmpty && !_isKeyboardVisible) {
                return Container(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: prompts.map((prompt) {
                      return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _buildSuggestionCard(prompt.getPrompt(lang)),
                      );
                    }).toList(),
                  ),
                );
              }
              
              // Fall back to config suggested prompts if API didn't return any
              if (!_isKeyboardVisible && widget.config.suggestionPrompts != null) {
                return Container(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: widget.config.suggestionPrompts!.map((prompt) {
                      return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _buildSuggestionCard(prompt),
                      );
                    }).toList(),
                  ),
                );
              }
              
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildConversationScreen() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _conversationAnimationController,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: widget.assistantStore.messages.length +
                    (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == widget.assistantStore.messages.length &&
                      _isTyping) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(
                    widget.assistantStore.messages[index],
                    index == widget.assistantStore.messages.length - 1 &&
                        !_isDontAnimateLastMsg,
                    index == 0,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isLast, bool isFirst) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          message.isUser
              ? SizedBox(height: isFirst ? 8 : 30)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    message.isAnimated && !isLast
                        ? Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: _buildImage(
                              widget.config.transitionLastFramePath ?? 'packages/meai_assistant/assets/images/me-assistant-last-frame.png',
                              width: 120,
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Lottie.asset(
                              widget.config.transitionLottiePath ?? 'packages/meai_assistant/assets/lottie/ai-transition-2.json',
                              repeat: false,
                            ),
                          ),
                  ],
                ),
          Row(
            mainAxisAlignment:
                message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isUser) const SizedBox(width: 40),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: message.isUser ? 16 : 0,
                    vertical: message.isUser ? 12 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? widget.config.effectiveColorScheme.userMessageColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      topLeft: message.isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      topRight: message.isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                  ),
                  child: message.isUser
                      ? Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: widget.config.effectiveColorScheme.userMessageTextColor,
                            fontWeight: FontWeight.w300,
                            fontFamily: widget.config.fontFamily ?? 'ReadexPro',
                          ),
                        )
                      : TypingText(
                          fullText: message.text,
                          scrollController: _scrollController,
                          speed: const Duration(milliseconds: 10),
                          showFullContentImmediately: message.isAnimated,
                          style: TextStyle(
                            fontSize: 15,
                            color: widget.config.effectiveColorScheme.assistantMessageTextColor,
                            fontWeight: FontWeight.w300,
                            fontFamily: widget.config.fontFamily ?? 'ReadexPro',
                          ),
                          onStart: () {
                            setState(() {
                              _isAnimatingText = true;
                            });
                          },
                          onComplete: () {
                            setState(() {
                              _isDontAnimateLastMsg = false;
                              message.isAnimated = true;
                              _isAnimatingText = false;
                            });
                            Future.delayed(const Duration(milliseconds: 500))
                                .then((v) {
                              _scrollToBottomAnimate();
                            });
                          },
                        ),
                ),
              ),
            ],
          ),
          if (!_isAnimatingText &&
              isLast &&
              !message.isUser &&
              message.assistantResponse != null &&
              message.assistantResponse!.suggestedResponses != null)
            Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 15),
                  for (String suggestion
                      in message.assistantResponse!.suggestedResponses!)
                    _buildSuggestionPrompt(suggestion),
                  const SizedBox(height: 15),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Lottie.asset(widget.config.typingIndicatorLottiePath ?? "packages/meai_assistant/assets/lottie/ai-loop.json"),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: widget.config.effectiveColorScheme.inputBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.config.effectiveColorScheme.borderColor,
                width: 1,
              ),
            ),
            child: TextField(
              controller: _textController,
              maxLines: 5,
              minLines: 1,
              focusNode: _textFieldFocusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              onEditingComplete: () {
                setState(() {});
              },
              onChanged: (str) {
                setState(() {});
              },
              enabled: !widget.assistantStore.isLoadingAssistantResponse && !widget.assistantStore.isCreatingConversation,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: widget.config.effectiveColorScheme.textColor,
                fontFamily: widget.config.fontFamily ?? 'ReadexPro',
              ),
              decoration: InputDecoration(
                hintText: widget.config.textFieldHint,
                hintStyle: TextStyle(
                  color: widget.config.effectiveColorScheme.hintTextColor,
                  fontSize: 13,
                  fontFamily: widget.config.fontFamily ?? 'ReadexPro',
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: _textController.text.isEmpty
                    ? null
                    : InkWell(
                        onTap: _sendMessage,
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.send,
                            size: 20,
                            color: widget.config.effectiveColorScheme.primaryColor,
                          ),
                        ),
                      ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(14),
                  child: Image.asset(
                    widget.config.suggestionIconPath ?? 'packages/meai_assistant/assets/images/ic_ai.png',
                    width: 20,
                    height: 20,
                    color: widget.config.effectiveColorScheme.primaryColor,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.chat_bubble_outline,
                    size: 20,
                    color: widget.config.effectiveColorScheme.primaryColor,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (!_isKeyboardVisible)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'You\'re chatting with an AI Financial Assistant - Powered by meAi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: widget.config.effectiveColorScheme.footerTextColor,
                  fontFamily: widget.config.fontFamily ?? 'ReadexPro',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(String text) {
    return GestureDetector(
      onTap: () {
        _textController.text = text;
        _sendMessage();
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.config.effectiveColorScheme.suggestionCardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.config.effectiveColorScheme.suggestionCardBorderColor,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 2),
              child: Image.asset(
                widget.config.suggestionIconPath ?? 'packages/meai_assistant/assets/images/ic_ai.png',
                width: 18,
                color: widget.config.effectiveColorScheme.suggestionIconColor,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.chat_bubble_outline,
                size: 18,
                    color: widget.config.effectiveColorScheme.suggestionIconColor,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                maxLines: 3,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.config.effectiveColorScheme.textColor,
                  fontFamily: widget.config.fontFamily ?? 'ReadexPro',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCardSkeleton() {
    return Shimmer.fromColors(
      baseColor: widget.config.effectiveColorScheme.shimmerBaseColor,
      highlightColor: widget.config.effectiveColorScheme.shimmerHighlightColor,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.config.effectiveColorScheme.suggestionCardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.config.effectiveColorScheme.suggestionCardBorderColor,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: widget.config.effectiveColorScheme.skeletonColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: widget.config.effectiveColorScheme.skeletonColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 12,
                    decoration: BoxDecoration(
                      color: widget.config.effectiveColorScheme.skeletonColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionPrompt(String text) {
    return GestureDetector(
      onTap: () {
        _textController.text = text;
        _sendMessage();
      },
      child: FadeIn(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.config.effectiveColorScheme.suggestionPromptBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.config.effectiveColorScheme.suggestionPromptBorderColor,
              width: 1,
            ),
          ),
          child: Text(
            text,
            maxLines: 3,
            style: TextStyle(
              fontSize: 14,
              color: widget.config.effectiveColorScheme.primaryColor,
              fontFamily: widget.config.fontFamily ?? 'ReadexPro',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String path, {double? width, double? height}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            widget.config.logoPath ?? 'packages/meai_assistant/assets/images/ai_button.png',
            width: width ?? 90,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
                Icons.chat_bubble_outline,
            size: width ?? 90,
            color: widget.config.effectiveColorScheme.primaryColor,
              );
            },
          );
        },
      );
    } else {
      return Image.asset(
        path,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            widget.config.logoPath ?? 'packages/meai_assistant/assets/images/ai_button.png',
            width: width ?? 90,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
                Icons.chat_bubble_outline,
            size: width ?? 90,
            color: widget.config.effectiveColorScheme.primaryColor,
              );
            },
          );
        },
      );
    }
  }
}

