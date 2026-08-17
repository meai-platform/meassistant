import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';
import '../config/assistant_config.dart';
import '../models/assistant_response.dart';
import '../services/assistant_service.dart';
import '../services/voice_service.dart';
import '../stores/assistant_store.dart';
import '../utils/parse_utils.dart';
import '../utils/text_direction_utils.dart';
import '../utils/meai_localizations.dart';
import 'typing_text.dart';

/// Modal widget that displays the assistant chat interface
class AssistantModal extends StatefulWidget {
  final AssistantConfig config;
  final AssistantStore assistantStore;
  final AssistantService assistantService;

  const AssistantModal({
    super.key,
    required this.config,
    required this.assistantStore,
    required this.assistantService,
  });

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

  final FocusNode _textFieldFocusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Use ValueNotifier for keyboard visibility to avoid full rebuilds
  final ValueNotifier<bool> _keyboardVisibleNotifier =
      ValueNotifier<bool>(false);
  bool _isKeyboardVisible = false;
  bool _isClosing = false;
  bool _isInConversation = false;
  bool _isFirstTime = true;
  bool _isDontAnimateLastMsg = false;
  bool _isAnimatingText = false;
  late String _loadingMessage;
  Timer? _loadingMessageTimer;
  DateTime? _typingStartTime;
  bool _isTimerRunning = false;
  ReactionDisposer? _loadingStateReaction;
  Timer? _keyboardDebounceTimer;

  // Voice assistant state
  late final VoiceService _voiceService;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  int? _speakingMessageIndex;
  bool _isFetchingSpeech = false;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceService(debug: widget.config.debug);
    _loadingMessage = MeAiLocalizations.analyzingMessage(widget.config.lang);
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
      // Debounce keyboard visibility changes to reduce rebuilds
      _keyboardDebounceTimer?.cancel();
      _keyboardDebounceTimer = Timer(const Duration(milliseconds: 50), () {
        if (mounted) {
          _isKeyboardVisible = visible;
          _keyboardVisibleNotifier.value = visible;
          if (_isKeyboardVisible) {
            Future.delayed(const Duration(milliseconds: 300)).then((v) {
              if (mounted) {
                _scrollToBottomAnimate();
              }
            });
          }
        }
      });
    });

    // Listen to loading state changes for timer management
    _loadingStateReaction = reaction<bool>(
      (_) => widget.assistantStore.isLoadingAssistantResponse,
      (isLoading) {
        if (isLoading && !_isTimerRunning) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && widget.assistantStore.isLoadingAssistantResponse) {
              _startLoadingMessageTimer();
            }
          });
        } else if (!isLoading && _isTimerRunning) {
          _loadingMessageTimer?.cancel();
          _loadingMessageTimer = null;
          _isTimerRunning = false;
        }
      },
    );

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
    _loadingMessageTimer?.cancel();
    _keyboardDebounceTimer?.cancel();
    _keyboardVisibleNotifier.dispose();
    _loadingStateReaction?.call();
    _recordingTimer?.cancel();
    _voiceService.dispose();
    super.dispose();
  }

  void _closeModal() {
    if (_isClosing) return;
    _isClosing = true;
    _voiceService.cancelRecording();
    _voiceService.stopPlayback();
    _animationController.reverse().then((_) {
      if (mounted) widget.assistantService.hideModal();
    });
  }

  void _startNewConversation() {
    if (widget.assistantStore.isLoadingAssistantResponse) return;

    _voiceService.cancelRecording();
    _voiceService.stopPlayback();
    _recordingTimer?.cancel();
    widget.assistantStore.clearMessages();
    _conversationAnimationController.reset();

    setState(() {
      _isInConversation = false;
      _isDontAnimateLastMsg = false;
      _isAnimatingText = false;
      _isRecording = false;
      _speakingMessageIndex = null;
      _isFetchingSpeech = false;
      _textController.clear();
      _loadingMessage = MeAiLocalizations.analyzingMessage(widget.config.lang);
    });

    _createConversationIfNeeded();
  }

  void _sendMessage({String? overrideText, bool fromVoice = false}) async {
    final rawText = overrideText ?? _textController.text;
    if (rawText.trim().isEmpty) return;
    if (widget.assistantStore.isLoadingAssistantResponse ||
        widget.assistantStore.isCreatingConversation) {
      return;
    }

    final userMessage = rawText.trim();
    _textController.clear();
    _textFieldFocusNode.unfocus();
    await _voiceService.stopPlayback();

    setState(() {
      _speakingMessageIndex = null;
      widget.assistantStore.messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isInConversation = true;
      // Reset loading message and cancel any existing timer for new prompt
      _loadingMessage = MeAiLocalizations.analyzingMessage(widget.config.lang);
      _loadingMessageTimer?.cancel();
      _loadingMessageTimer = null;
      _isTimerRunning = false;
    });

    _conversationAnimationController.forward();

    // Wait for layout to complete before scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    AssistantResponse? response = await widget.assistantStore
        .sendPrompt(userMessage, inputType: fromVoice ? 'voice' : 'text');

    if (!mounted) return;
    setState(() {
      widget.assistantStore.messages.add(ChatMessage(
        text: response!.textResponse,
        isUser: false,
        timestamp: DateTime.now(),
        assistantResponse: response,
      ));
    });

    // Voice-initiated prompts get a spoken reply automatically
    if (fromVoice && widget.config.voiceEnabled && response != null) {
      _speakMessage(
          widget.assistantStore.messages.length - 1, response.textResponse);
    }
  }

  // ── Voice input (record → transcribe → send) ─────────────────────────────

  void _startVoiceRecording() async {
    if (widget.assistantStore.isLoadingAssistantResponse ||
        widget.assistantStore.isCreatingConversation ||
        widget.assistantStore.isTranscribing ||
        _isRecording) {
      return;
    }
    _textFieldFocusNode.unfocus();
    await _voiceService.stopPlayback();

    final started = await _voiceService.startRecording();
    if (!mounted) return;
    if (!started) {
      _showVoiceError(MeAiLocalizations.micPermissionDenied(widget.config.lang));
      return;
    }

    setState(() {
      _isRecording = true;
      _speakingMessageIndex = null;
      _recordingDuration = Duration.zero;
    });
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isRecording) {
        timer.cancel();
        return;
      }
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });
  }

  void _cancelVoiceRecording() async {
    _recordingTimer?.cancel();
    await _voiceService.cancelRecording();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  void _stopVoiceRecordingAndSend() async {
    _recordingTimer?.cancel();
    final path = await _voiceService.stopRecording();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
    if (path == null) {
      _showVoiceError(MeAiLocalizations.transcriptionFailed(widget.config.lang));
      return;
    }

    final transcription = await widget.assistantStore.transcribeAudio(path);
    _voiceService.deleteRecording(path);
    if (!mounted) return;

    if (transcription == null) {
      _showVoiceError(MeAiLocalizations.transcriptionFailed(widget.config.lang));
      return;
    }

    _sendMessage(overrideText: transcription.text, fromVoice: true);
  }

  // ── Spoken replies (synthesize → play) ────────────────────────────────────

  void _speakMessage(int messageIndex, String text) async {
    if (_speakingMessageIndex == messageIndex) {
      await _voiceService.stopPlayback();
      if (!mounted) return;
      setState(() {
        _speakingMessageIndex = null;
      });
      return;
    }
    // Custom-object placeholders (#OBJn#) mark where visual cards render —
    // strip them so only the narrative text is spoken.
    text = ParseUtils.sanitizeForSpeech(text);
    if (_isFetchingSpeech || text.isEmpty) return;

    await _voiceService.stopPlayback();
    if (!mounted) return;
    setState(() {
      _isFetchingSpeech = true;
      _speakingMessageIndex = null;
    });

    final audio = await widget.assistantStore.synthesizeSpeech(text);
    if (!mounted) return;
    if (audio == null) {
      // Synthesis unavailable — the reply stays text-only
      setState(() {
        _isFetchingSpeech = false;
      });
      return;
    }

    setState(() {
      _isFetchingSpeech = false;
      _speakingMessageIndex = messageIndex;
    });
    await _voiceService.playBytes(audio, onComplete: () {
      if (mounted) {
        setState(() {
          _speakingMessageIndex = null;
        });
      }
    });
  }

  void _showVoiceError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: widget.config.fontFamily ?? 'ReadexPro',
            fontSize: 13,
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatRecordingDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
      // final maxScroll = _scrollController.position.maxScrollExtent;
      // if (maxScroll.isFinite && maxScroll >= 0) {
      //   _scrollController.jumpTo(maxScroll);
      // }
    }
  }

  void _scrollToBottomAnimate() {
    if (_scrollController.hasClients &&
        !_scrollController.position.isScrollingNotifier.value) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll.isFinite && maxScroll >= 0) {
        _scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstTime) {
      _isFirstTime = false;
      _isInConversation = widget.assistantStore.messages.isNotEmpty;
      if (_isInConversation) {
        _isDontAnimateLastMsg = true;
        _conversationAnimationController.forward();
      }
    }

    final isArabic = widget.config.isArabic;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _closeModal();
      },
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => AnimatedBuilder(
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
                              color: widget.config.effectiveColorScheme
                                  .overlayBackgroundColor,
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
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetContent() {
    // Use ValueListenableBuilder for keyboard visibility to avoid full rebuilds
    return ValueListenableBuilder<bool>(
      valueListenable: _keyboardVisibleNotifier,
      builder: (context, isKeyboardVisible, child) {
        // Cache MediaQuery to avoid repeated lookups
        final mediaQuery = MediaQuery.of(context);
        final screenHeight = mediaQuery.size.height;
        final modalHeight =
            isKeyboardVisible ? screenHeight * 0.5 : screenHeight * 0.9;

        return GestureDetector(
            onTap: () {
              // Unfocus the text field if it has focus
              if (_textFieldFocusNode.hasFocus) {
                _textFieldFocusNode.unfocus();
              }
            },
            child: RepaintBoundary(
                child: AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxHeight: modalHeight,
                        minHeight: modalHeight,
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: RepaintBoundary(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: widget.config.effectiveColorScheme
                                    .modalBackgroundColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                                border: Border.all(
                                  color: widget.config.effectiveColorScheme
                                      .modalBorderColor,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.config.effectiveColorScheme
                                        .modalShadowColor,
                                    blurRadius: 20,
                                    offset: const Offset(0, -10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Center(
                                      child: Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: widget
                                              .config
                                              .effectiveColorScheme
                                              .handleBarColor,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (_isInConversation)
                                          GestureDetector(
                                            onTap: _startNewConversation,
                                            child: Icon(
                                              Icons.add_comment_outlined,
                                              size: 24,
                                              color: widget
                                                  .config
                                                  .effectiveColorScheme
                                                  .textColor,
                                            ),
                                          )
                                        else
                                          const SizedBox.shrink(),
                                        GestureDetector(
                                          onTap: _closeModal,
                                          child: Icon(
                                            Icons.close,
                                            size: 24,
                                            color: widget.config
                                                .effectiveColorScheme.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: RepaintBoundary(
                                      child: GestureDetector(
                                        onTap: () {
                                          FocusScope.of(context).unfocus();
                                        },
                                        behavior: HitTestBehavior.translucent,
                                        child: Stack(
                                          children: [
                                            if (!_isInConversation)
                                              _buildWelcomeScreen(),
                                            if (_isInConversation)
                                              _buildConversationScreen(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildInputArea(),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: _keyboardVisibleNotifier,
                                    builder:
                                        (context, isKeyboardVisible, child) {
                                      return SizedBox(
                                        height: isKeyboardVisible ? 0 : 20,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ))));
      },
    );
  }

  Widget _buildWelcomeScreen() {
    return AnimatedOpacity(
      opacity: _isInConversation ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: ValueListenableBuilder<bool>(
        valueListenable: _keyboardVisibleNotifier,
        builder: (context, isKeyboardVisible, child) {
          return Column(
            children: [
              Expanded(
                flex: isKeyboardVisible ? 6 : 1,
                child: const SizedBox.shrink(),
              ),
              _buildImage(
                widget.config.logoPath ??
                    'packages/meai_assistant/assets/images/ai_button.png',
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
                widget.config.effectiveIntroText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: widget.config.effectiveColorScheme.textColor,
                  fontFamily: widget.config.fontFamily ?? 'ReadexPro',
                ),
                textAlign: TextAlign.center,
              ),
              const Expanded(child: SizedBox.shrink()),
              Observer(
                builder: (_) {
                  // Use API suggested prompts if available, otherwise fall back to config
                  final prompts = widget.assistantStore.suggestedPrompts;
                  final lang = widget.config.lang;

                  return ValueListenableBuilder<bool>(
                    valueListenable: _keyboardVisibleNotifier,
                    builder: (context, isKeyboardVisible, child) {
                      // Show skeleton loading when creating conversation
                      if (widget.assistantStore.isCreatingConversation &&
                          !isKeyboardVisible) {
                        return SizedBox(
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

                      if (prompts != null &&
                          prompts.isNotEmpty &&
                          !isKeyboardVisible) {
                        return SizedBox(
                          height: 90,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            children: prompts.map((prompt) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: _buildSuggestionCard(
                                    prompt.getPrompt(lang)),
                              );
                            }).toList(),
                          ),
                        );
                      }

                      // Fall back to config suggested prompts if API didn't return any
                      if (!isKeyboardVisible &&
                          widget.config.suggestionPrompts != null) {
                        return SizedBox(
                          height: 90,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            children:
                                widget.config.suggestionPrompts!.map((prompt) {
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
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConversationScreen() {
    return Observer(
      builder: (_) {
        return RepaintBoundary(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _conversationAnimationController,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      itemCount: widget.assistantStore.messages.length +
                          (widget.assistantStore.isLoadingAssistantResponse
                              ? 1
                              : 0),
                      cacheExtent: 500,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      itemBuilder: (context, index) {
                        if (index == widget.assistantStore.messages.length &&
                            widget.assistantStore.isLoadingAssistantResponse) {
                          return _buildTypingIndicator();
                        }
                        return RepaintBoundary(
                          child: _buildMessageBubble(
                            widget.assistantStore.messages[index],
                            index ==
                                    widget.assistantStore.messages.length - 1 &&
                                !_isDontAnimateLastMsg,
                            index == 0,
                            index,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(
      ChatMessage message, bool isLast, bool isFirst, int index) {
    return Container(
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
                              widget.config.transitionLastFramePath ??
                                  'packages/meai_assistant/assets/images/me-assistant-last-frame.png',
                              width: 120,
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Lottie.asset(
                              widget.config.transitionLottiePath ??
                                  'packages/meai_assistant/assets/lottie/ai-transition-2.json',
                              repeat: false,
                            ),
                          ),
                  ],
                ),
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
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
                          textDirection: textDirectionForContent(message.text),
                          style: TextStyle(
                            fontSize: 15,
                            color: widget.config.effectiveColorScheme
                                .userMessageTextColor,
                            fontWeight: FontWeight.w300,
                            fontFamily: widget.config.fontFamily ?? 'ReadexPro',
                          ),
                        )
                      : TypingText(
                          fullText: message.text,
                          scrollController: _scrollController,
                          speed: const Duration(milliseconds: 10),
                          showFullContentImmediately: message.isAnimated,
                          assistantResponse: message.assistantResponse,
                          customObjectWidgetBuilder:
                              widget.config.customObjectWidgetBuilder,
                          fontFamily: widget.config.fontFamily,
                          lang: widget.config.lang,
                          textDirection: textDirectionForContent(message.text),
                          style: TextStyle(
                            fontSize: 15,
                            color: widget.config.effectiveColorScheme
                                .assistantMessageTextColor,
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
          if (widget.config.voiceEnabled &&
              !message.isUser &&
              ParseUtils.sanitizeForSpeech(message.text).isNotEmpty &&
              (message.isAnimated || !isLast))
            _buildSpeakerButton(index, message.text),
          if (!_isAnimatingText &&
              isLast &&
              !message.isUser &&
              message.assistantResponse != null &&
              message.assistantResponse!.suggestedResponses != null)
            LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
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
                );
              },
            )
        ],
      ),
    );
  }

  void _startLoadingMessageTimer() {
    _loadingMessageTimer?.cancel();
    _typingStartTime = DateTime.now();
    _loadingMessage = MeAiLocalizations.analyzingMessage(widget.config.lang);
    _isTimerRunning = true;

    // Use 1 second interval since we only check seconds
    _loadingMessageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!widget.assistantStore.isLoadingAssistantResponse || !mounted) {
        timer.cancel();
        _loadingMessageTimer = null;
        _isTimerRunning = false;
        return;
      }

      final elapsed = DateTime.now().difference(_typingStartTime!);
      final seconds = elapsed.inSeconds;
      final lang = widget.config.lang;

      String newMessage;
      if (seconds < 5) {
        newMessage = MeAiLocalizations.analyzingMessage(lang);
      } else if (seconds < 7) {
        newMessage = MeAiLocalizations.fetchingData(lang);
      } else if (seconds < 10) {
        newMessage = MeAiLocalizations.analyzingData(lang);
      } else {
        newMessage = MeAiLocalizations.preparingResponse(lang);
      }

      if (newMessage != _loadingMessage && mounted) {
        setState(() {
          _loadingMessage = newMessage;
        });
      }
    });
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Lottie.asset(widget.config.typingIndicatorLottiePath ??
              "packages/meai_assistant/assets/lottie/ai-loop-cropped.json"),
          const SizedBox(width: 12),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[600]!,
              highlightColor: Colors.grey[300]!,
              child: Text(
                _loadingMessage,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 14,
                  color: widget
                      .config.effectiveColorScheme.assistantMessageTextColor,
                  fontWeight: FontWeight.w500,
                  fontFamily: widget.config.fontFamily ?? 'ReadexPro',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Small speaker toggle shown under assistant messages when voice is enabled.
  Widget _buildSpeakerButton(int index, String text) {
    final isSpeakingThis = _speakingMessageIndex == index;
    final lang = widget.config.lang;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _speakMessage(index, text),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: _isFetchingSpeech && !isSpeakingThis
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            widget.config.effectiveColorScheme.hintTextColor,
                      ),
                    )
                  : Icon(
                      isSpeakingThis
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up_outlined,
                      size: 18,
                      semanticLabel: isSpeakingThis
                          ? MeAiLocalizations.stopSpeaking(lang)
                          : MeAiLocalizations.speakReply(lang),
                      color: isSpeakingThis
                          ? widget.config.effectiveColorScheme.primaryColor
                          : widget.config.effectiveColorScheme.hintTextColor,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Observer(
      builder: (_) {
        final isBusy = widget.assistantStore.isLoadingAssistantResponse ||
            widget.assistantStore.isCreatingConversation;
        final isTranscribing = widget.assistantStore.isTranscribing;
        return Container(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color:
                      widget.config.effectiveColorScheme.inputBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.config.effectiveColorScheme.borderColor,
                    width: 1,
                  ),
                ),
                child: _isRecording
                    ? _buildRecordingBar()
                    : isTranscribing
                        ? _buildTranscribingBar()
                        : TextField(
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: widget.config.effectiveColorScheme.textColor,
                    fontFamily: widget.config.fontFamily ?? 'ReadexPro',
                  ),
                  decoration: InputDecoration(
                    hintText: widget.config.effectiveTextFieldHint,
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
                        ? (widget.config.voiceEnabled
                            ? InkWell(
                                onTap: isBusy ? null : _startVoiceRecording,
                                child: Container(
                                  margin: const EdgeInsets.all(10),
                                  child: Icon(
                                    Icons.mic_none_outlined,
                                    size: 20,
                                    semanticLabel: MeAiLocalizations
                                        .tapToSpeak(widget.config.lang),
                                    color: isBusy
                                        ? widget.config.effectiveColorScheme
                                            .hintTextColor
                                        : widget.config.effectiveColorScheme
                                            .primaryColor,
                                  ),
                                ),
                              )
                            : null)
                        : InkWell(
                            onTap: isBusy ? null : _sendMessage,
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              child: Icon(
                                Icons.send,
                                size: 20,
                                color: isBusy
                                    ? widget.config.effectiveColorScheme
                                        .hintTextColor
                                    : widget.config.effectiveColorScheme
                                        .primaryColor,
                              ),
                            ),
                          ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(14),
                      child: Image.asset(
                        widget.config.suggestionIconPath ??
                            'packages/meai_assistant/assets/images/ic_ai.png',
                        width: 20,
                        height: 20,
                        color: widget.config.effectiveColorScheme.primaryColor,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.chat_bubble_outline,
                            size: 20,
                            color:
                                widget.config.effectiveColorScheme.primaryColor,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _keyboardVisibleNotifier,
                builder: (context, isKeyboardVisible, child) {
                  if (!isKeyboardVisible) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        MeAiLocalizations.footerText(widget.config.lang),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          color: widget
                              .config.effectiveColorScheme.footerTextColor,
                          fontFamily: widget.config.fontFamily ?? 'ReadexPro',
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Shown inside the input container while recording voice input.
  Widget _buildRecordingBar() {
    final lang = widget.config.lang;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            onPressed: _cancelVoiceRecording,
            icon: Icon(
              Icons.close,
              size: 20,
              color: widget.config.effectiveColorScheme.hintTextColor,
            ),
          ),
          const Icon(
            Icons.mic,
            size: 18,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Shimmer.fromColors(
              baseColor:
                  widget.config.effectiveColorScheme.assistantMessageTextColor,
              highlightColor:
                  widget.config.effectiveColorScheme.hintTextColor,
              child: Text(
                MeAiLocalizations.listening(lang),
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: widget.config.fontFamily ?? 'ReadexPro',
                ),
              ),
            ),
          ),
          Text(
            _formatRecordingDuration(_recordingDuration),
            style: TextStyle(
              fontSize: 13,
              color: widget.config.effectiveColorScheme.hintTextColor,
              fontFamily: widget.config.fontFamily ?? 'ReadexPro',
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _stopVoiceRecordingAndSend,
            icon: Icon(
              Icons.send,
              size: 20,
              color: widget.config.effectiveColorScheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Shown inside the input container while the recording is being transcribed.
  Widget _buildTranscribingBar() {
    final lang = widget.config.lang;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.config.effectiveColorScheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Shimmer.fromColors(
              baseColor:
                  widget.config.effectiveColorScheme.assistantMessageTextColor,
              highlightColor:
                  widget.config.effectiveColorScheme.hintTextColor,
              child: Text(
                MeAiLocalizations.transcribing(lang),
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: widget.config.fontFamily ?? 'ReadexPro',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(String text) {
    // Use MediaQuery for width since this is used in a horizontal ListView
    // LayoutBuilder would give unbounded constraints in horizontal scroll
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        _textController.text = text;
        _sendMessage();
      },
      child: Container(
        width: screenWidth * 0.65,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              widget.config.effectiveColorScheme.suggestionCardBackgroundColor,
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
                widget.config.suggestionIconPath ??
                    'packages/meai_assistant/assets/images/ic_ai.png',
                width: 18,
                color: widget.config.effectiveColorScheme.suggestionIconColor,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color:
                        widget.config.effectiveColorScheme.suggestionIconColor,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textDirection: textDirectionForContent(text),
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
    // Use MediaQuery for width since this is used in a horizontal ListView
    // LayoutBuilder would give unbounded constraints in horizontal scroll
    final screenWidth = MediaQuery.of(context).size.width;
    return Shimmer.fromColors(
      baseColor: widget.config.effectiveColorScheme.shimmerBaseColor,
      highlightColor: widget.config.effectiveColorScheme.shimmerHighlightColor,
      child: Container(
        width: screenWidth * 0.6,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              widget.config.effectiveColorScheme.suggestionCardBackgroundColor,
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
                    width: screenWidth * 0.4,
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
            color: widget
                .config.effectiveColorScheme.suggestionPromptBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget
                  .config.effectiveColorScheme.suggestionPromptBorderColor,
              width: 1,
            ),
          ),
          child: Text(
            text,
            maxLines: 3,
            textDirection: textDirectionForContent(text),
            style: TextStyle(
              fontSize: 13,
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
            widget.config.logoPath ??
                'packages/meai_assistant/assets/images/ai_button.png',
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
            widget.config.logoPath ??
                'packages/meai_assistant/assets/images/ai_button.png',
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
