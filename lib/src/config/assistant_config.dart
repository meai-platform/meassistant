import 'package:flutter/material.dart';

/// Configuration class for customizing the assistant appearance and behavior
class AssistantConfig {
  /// Assistant name displayed in the UI
  final String assistantName;

  /// Main logo/avatar image path (asset path or network URL)
  final String? logoPath;

  /// Floating button logo/icon path (asset path or network URL)
  final String? floatingLogoPath;

  /// Floating button container image path (asset path or network URL)
  final String? floatingButtonContainerPath;

  /// Suggestion card icon path (asset path or network URL)
  final String? suggestionIconPath;

  /// Transition animation last frame image path (asset path or network URL)
  final String? transitionLastFramePath;

  /// Transition animation Lottie file path (asset path)
  final String? transitionLottiePath;

  /// Typing indicator Lottie file path (asset path)
  final String? typingIndicatorLottiePath;

  /// Color scheme for the assistant (optional - can use individual colors instead)
  final AssistantColorScheme? colorScheme;

  /// Individual color overrides (used if colorScheme is not provided)
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? hintTextColor;
  final Color? userMessageColor;
  final Color? assistantMessageColor;
  final Color? borderColor;
  final Color? floatingButtonColor;
  final Color? floatingButtonIconColor;

  /// Intro text displayed on the welcome screen
  final String introText;

  /// Text field hint text
  final String textFieldHint;

  /// Base URL for the API
  final String baseUrl;

  /// Function to get authentication token
  final Future<String?> Function()? getAuthToken;

  /// Function to get user ID (deprecated - use customerId instead)
  final Future<int?> Function()? getUserId;

  /// Customer ID for API requests (required for mebank SDK)
  final String? customerId;

  /// Language preference (en or ar, defaults to en)
  final String lang;

  /// SDK Authentication credentials
  final String? clientId;
  /// Function to get HMAC hash for authentication
  /// The HMAC should be calculated by your backend using: HMAC-SHA256(clientSecret, timestamp + clientId + packageName + customerId)
  /// Parameters: timestamp (int), clientId (String), packageName (String), customerId (String?)
  /// Returns: HMAC hash as String
  final Future<String?> Function(int timestamp, String clientId, String packageName, String? customerId)? getHmac;
  /// App hash is automatically calculated from app signature - cannot be manually set

  /// Additional headers to include in API requests
  final Map<String, String>? additionalHeaders;

  /// Bottom spacing for the floating button
  final double floatingButtonBottomSpacing;

  /// Floating button right spacing
  final double floatingButtonRightSpacing;

  /// Custom suggestion prompts for the welcome screen (deprecated - will use API suggested prompts)
  final List<String>? suggestionPrompts;

  /// Font family to use throughout the assistant UI (default: 'ReadexPro')
  final String? fontFamily;

  /// Enable debug logging throughout the SDK (default: false)
  final bool debug;

  const AssistantConfig({
    required this.assistantName,
    this.logoPath = 'packages/meai_assistant/assets/images/ai_button.png', // Default meAi assistant logo
    this.floatingLogoPath = 'packages/meai_assistant/assets/images/ic_ai.png', // Default meAi AI icon
    this.floatingButtonContainerPath = 'packages/meai_assistant/assets/images/ai_button_container.png', // Default floating button container
    this.suggestionIconPath = 'packages/meai_assistant/assets/images/ic_ai.png', // Default suggestion card icon
    this.transitionLastFramePath = 'packages/meai_assistant/assets/images/me-assistant-last-frame.png', // Default transition last frame
    this.transitionLottiePath = 'packages/meai_assistant/assets/lottie/ai-transition-2.json', // Default transition animation
    this.typingIndicatorLottiePath = 'packages/meai_assistant/assets/lottie/ai-loop.json', // Default typing indicator animation
    this.colorScheme, // Optional: use predefined color scheme
    // Individual color overrides (used if colorScheme is null, otherwise colorScheme takes precedence)
    this.primaryColor,
    this.secondaryColor,
    this.backgroundColor,
    this.textColor,
    this.hintTextColor,
    this.userMessageColor,
    this.assistantMessageColor,
    this.borderColor,
    this.floatingButtonColor,
    this.floatingButtonIconColor,
    this.introText = "Hello! I'm your smart money assistant.",
    this.textFieldHint = "Ask something...",
    required this.baseUrl,
    this.getAuthToken,
    this.getUserId,
    this.customerId,
    this.lang = "en",
    this.clientId,
    this.getHmac,
    this.additionalHeaders,
    this.floatingButtonBottomSpacing = 100.0,
    this.floatingButtonRightSpacing = 20.0,
    this.suggestionPrompts,
    this.fontFamily,
    this.debug = false,
  });

  /// Get the effective color scheme (either provided or built from individual colors)
  AssistantColorScheme get effectiveColorScheme {
    // If colorScheme is provided, use it (individual colors are ignored)
    if (colorScheme != null) {
      return colorScheme!;
    }
    // If individual colors are provided, build scheme from them
    // Otherwise, use default meAi assistant theme (purple)
    if (primaryColor != null || floatingButtonColor != null || textColor != null) {
      return AssistantColorScheme(
        primaryColor: primaryColor ?? const Color(0xFF6310D1), // mePurple900
        secondaryColor: secondaryColor ?? const Color(0xFFAF79F5), // mePurple600v2
        backgroundColor: backgroundColor ?? Colors.white,
        textColor: textColor ?? const Color(0xFF0F0F0F),
        hintTextColor: hintTextColor ?? const Color(0xFF9292A0),
        userMessageColor: userMessageColor ?? const Color(0x0A000000),
        assistantMessageColor: assistantMessageColor ?? const Color(0xFF42424C),
        borderColor: borderColor ?? const Color(0x0A000000),
        floatingButtonColor: floatingButtonColor ?? const Color(0xFF6310D1), // mePurple900
        floatingButtonIconColor: floatingButtonIconColor ?? Colors.white,
      );
    }
    // Default to meAi assistant theme (purple, not yellow)
    return AssistantColorScheme.purple;
  }

  /// Create a copy with modified values
  AssistantConfig copyWith({
    String? assistantName,
    String? logoPath,
    String? floatingLogoPath,
    String? floatingButtonContainerPath,
    String? suggestionIconPath,
    String? transitionLastFramePath,
    String? transitionLottiePath,
    String? typingIndicatorLottiePath,
    AssistantColorScheme? colorScheme,
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? textColor,
    Color? hintTextColor,
    Color? userMessageColor,
    Color? assistantMessageColor,
    Color? borderColor,
    Color? floatingButtonColor,
    Color? floatingButtonIconColor,
    String? introText,
    String? textFieldHint,
    String? baseUrl,
    Future<String?> Function()? getAuthToken,
    Future<int?> Function()? getUserId,
    String? customerId,
    String? lang,
    String? clientId,
    Future<String?> Function(int timestamp, String clientId, String packageName, String? customerId)? getHmac,
    Map<String, String>? additionalHeaders,
    double? floatingButtonBottomSpacing,
    double? floatingButtonRightSpacing,
    List<String>? suggestionPrompts,
    bool? debug,
  }) {
    return AssistantConfig(
      assistantName: assistantName ?? this.assistantName,
      logoPath: logoPath ?? this.logoPath,
      floatingLogoPath: floatingLogoPath ?? this.floatingLogoPath,
      floatingButtonContainerPath: floatingButtonContainerPath ?? this.floatingButtonContainerPath,
      suggestionIconPath: suggestionIconPath ?? this.suggestionIconPath,
      transitionLastFramePath: transitionLastFramePath ?? this.transitionLastFramePath,
      transitionLottiePath: transitionLottiePath ?? this.transitionLottiePath,
      typingIndicatorLottiePath: typingIndicatorLottiePath ?? this.typingIndicatorLottiePath,
      colorScheme: colorScheme ?? this.colorScheme,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      hintTextColor: hintTextColor ?? this.hintTextColor,
      userMessageColor: userMessageColor ?? this.userMessageColor,
      assistantMessageColor: assistantMessageColor ?? this.assistantMessageColor,
      borderColor: borderColor ?? this.borderColor,
      floatingButtonColor: floatingButtonColor ?? this.floatingButtonColor,
      floatingButtonIconColor: floatingButtonIconColor ?? this.floatingButtonIconColor,
      introText: introText ?? this.introText,
      textFieldHint: textFieldHint ?? this.textFieldHint,
      baseUrl: baseUrl ?? this.baseUrl,
      getAuthToken: getAuthToken ?? this.getAuthToken,
      getUserId: getUserId ?? this.getUserId,
      customerId: customerId ?? this.customerId,
      lang: lang ?? this.lang,
      clientId: clientId ?? this.clientId,
      getHmac: getHmac ?? this.getHmac,
      additionalHeaders: additionalHeaders ?? this.additionalHeaders,
      floatingButtonBottomSpacing:
          floatingButtonBottomSpacing ?? this.floatingButtonBottomSpacing,
      floatingButtonRightSpacing:
          floatingButtonRightSpacing ?? this.floatingButtonRightSpacing,
      suggestionPrompts: suggestionPrompts ?? this.suggestionPrompts,
      fontFamily: fontFamily ?? this.fontFamily,
      debug: debug ?? this.debug,
    );
  }
}

/// Color scheme for the assistant UI
class AssistantColorScheme {
  /// Primary color (used for buttons, highlights)
  final Color primaryColor;

  /// Secondary color (used for accents)
  final Color secondaryColor;

  /// Background color for the modal
  final Color backgroundColor;

  /// Text color for primary text
  final Color textColor;

  /// Text color for secondary/hint text
  final Color hintTextColor;

  /// Color for user message bubbles
  final Color userMessageColor;

  /// Color for assistant message text
  final Color assistantMessageColor;

  /// Border color
  final Color borderColor;

  /// Floating button background color
  final Color floatingButtonColor;

  /// Floating button icon color
  final Color floatingButtonIconColor;

  /// Overlay background color (behind modal)
  final Color overlayBackgroundColor;

  /// Modal background color
  final Color modalBackgroundColor;

  /// Modal border color
  final Color modalBorderColor;

  /// Modal shadow color
  final Color modalShadowColor;

  /// Handle bar color (top drag indicator)
  final Color handleBarColor;

  /// User message text color
  final Color userMessageTextColor;

  /// Assistant message text color
  final Color assistantMessageTextColor;

  /// Input area background color
  final Color inputBackgroundColor;

  /// Footer text color
  final Color footerTextColor;

  /// Suggestion card background color
  final Color suggestionCardBackgroundColor;

  /// Suggestion card border color
  final Color suggestionCardBorderColor;

  /// Suggestion icon color
  final Color suggestionIconColor;

  /// Suggestion prompt background color
  final Color suggestionPromptBackgroundColor;

  /// Suggestion prompt border color
  final Color suggestionPromptBorderColor;

  /// Shimmer base color (for skeleton loading)
  final Color shimmerBaseColor;

  /// Shimmer highlight color (for skeleton loading)
  final Color shimmerHighlightColor;

  /// Skeleton color (for skeleton loading)
  final Color skeletonColor;

  const AssistantColorScheme({
    this.primaryColor = const Color(0xFFFED401), // meAi yellow
    this.secondaryColor = const Color(0xFFDFBA01), // meAi yellow darker
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF0F0F0F), // meBlack
    this.hintTextColor = const Color(0xFF9292A0), // dark400
    this.userMessageColor = const Color(0x0A000000),
    this.assistantMessageColor = const Color(0xFF42424C), // dark800
    this.borderColor = const Color(0x0A000000),
    this.floatingButtonColor = const Color(0xFFFED401), // meAi yellow
    this.floatingButtonIconColor = const Color(0xFF0F0F0F), // meBlack for contrast
    this.overlayBackgroundColor = const Color(0x4D000000), // Colors.black.withOpacity(0.3)
    this.modalBackgroundColor = const Color(0xE0FFFFFF), // Colors.white.withOpacity(0.88)
    this.modalBorderColor = const Color(0x4DFFFFFF), // Colors.white.withOpacity(0.3)
    this.modalShadowColor = const Color(0x1A000000), // Colors.black.withOpacity(0.1)
    this.handleBarColor = const Color(0x33000000), // Colors.black.withOpacity(0.2)
    this.userMessageTextColor = const Color(0xff26262B), // dark900
    this.assistantMessageTextColor = const Color(0xff42424c), // dark800
    this.inputBackgroundColor = const Color(0xB3FFFFFF), // Colors.white.withOpacity(0.7)
    this.footerTextColor = const Color(0x66000000), // Colors.black.withOpacity(0.4)
    this.suggestionCardBackgroundColor = const Color(0xB3FFFFFF), // Colors.white.withOpacity(0.7)
    this.suggestionCardBorderColor = const Color(0x4DFFFFFF), // Colors.white.withOpacity(0.3)
    this.suggestionIconColor = const Color(0xffC8C8D0), // dark200
    this.suggestionPromptBackgroundColor = Colors.white,
    this.suggestionPromptBorderColor = const Color(0x14000000), // Colors.black.withOpacity(0.08)
    this.shimmerBaseColor = Colors.white,
    this.shimmerHighlightColor = const Color(0xFFE0E0E0), // Colors.grey[200]!
    this.skeletonColor = Colors.grey,
  });

  /// Default meAi theme (yellow branding)
  static const AssistantColorScheme meAi = AssistantColorScheme(
    primaryColor: Color(0xFFFED401), // meYellow600
    secondaryColor: Color(0xFFDFBA01), // meYellow900
    backgroundColor: Colors.white,
    textColor: Color(0xFF0F0F0F), // meBlack
    hintTextColor: Color(0xFF9292A0), // dark400
    userMessageColor: Color(0x0A000000),
    assistantMessageColor: Color(0xFF42424C), // dark800
    borderColor: Color(0x0A000000),
    floatingButtonColor: Color(0xFFFED401), // meYellow600
    floatingButtonIconColor: Color(0xFF0F0F0F), // meBlack
    overlayBackgroundColor: Color(0x4D000000), // Colors.black.withOpacity(0.3)
    modalBackgroundColor: Color(0xE0FFFFFF), // Colors.white.withOpacity(0.88)
    modalBorderColor: Color(0x4DFFFFFF), // Colors.white.withOpacity(0.3)
    modalShadowColor: Color(0x1A000000), // Colors.black.withOpacity(0.1)
    handleBarColor: Color(0x33000000), // Colors.black.withOpacity(0.2)
    userMessageTextColor: Color(0xff26262B), // dark900
    assistantMessageTextColor: Color(0xff42424c), // dark800
    inputBackgroundColor: Color(0xB3FFFFFF), // Colors.white.withOpacity(0.7)
    footerTextColor: Color(0x66000000), // Colors.black.withOpacity(0.4)
    suggestionCardBackgroundColor: Color(0xB3FFFFFF), // Colors.white.withOpacity(0.7)
    suggestionCardBorderColor: Color(0x4DFFFFFF), // Colors.white.withOpacity(0.3)
    suggestionIconColor: Color(0xffC8C8D0), // dark200
    suggestionPromptBackgroundColor: Colors.white,
    suggestionPromptBorderColor: Color(0x14000000), // Colors.black.withOpacity(0.08)
    shimmerBaseColor: Colors.white,
    shimmerHighlightColor: Color(0xFFE0E0E0), // Colors.grey[200]!
    skeletonColor: Colors.grey,
  );

  /// Default purple theme (kept for backward compatibility)
  static const AssistantColorScheme purple = AssistantColorScheme(
    primaryColor: Color(0xFF6310D1),
    secondaryColor: Color(0xFFAF79F5),
    backgroundColor: Colors.white,
    textColor: Color(0xFF0F0F0F),
    hintTextColor: Color(0xFF9292A0),
    userMessageColor: Color(0x0A000000),
    assistantMessageColor: Color(0xFF42424C),
    borderColor: Color(0x0A000000),
    floatingButtonColor: Color(0xFF6310D1),
    floatingButtonIconColor: Colors.white,
    overlayBackgroundColor: Color(0x4D000000), // Colors.black.withOpacity(0.3)
    modalBackgroundColor: Color(0xE0FFFFFF), // Colors.white.withOpacity(0.88)
    modalBorderColor: Color(0x4DFFFFFF), // Colors.white.withOpacity(0.3)
    modalShadowColor: Color(0x1A000000), // Colors.black.withOpacity(0.1)
    handleBarColor: Color(0x33000000), // Colors.black.withOpacity(0.2)
    userMessageTextColor: Color(0xff26262B), // dark900
    assistantMessageTextColor: Color(0xff42424c), // dark800
    inputBackgroundColor: Color(0xB3FFFFFF), // Colors.white.withOpacity(0.7)
    footerTextColor: Color(0x66000000), // Colors.black.withOpacity(0.4)
    suggestionCardBackgroundColor: Color(0xB3FFFFFF), // Colors.white.withOpacity(0.7)
    suggestionCardBorderColor: Color(0x4DFFFFFF), // Colors.white.withOpacity(0.3)
    suggestionIconColor: Color(0xffC8C8D0), // dark200
    suggestionPromptBackgroundColor: Colors.white,
    suggestionPromptBorderColor: Color(0x14000000), // Colors.black.withOpacity(0.08)
    shimmerBaseColor: Colors.white,
    shimmerHighlightColor: Color(0xFFE0E0E0), // Colors.grey[200]!
    skeletonColor: Colors.grey,
  );

  /// Blue theme
  static const AssistantColorScheme blue = AssistantColorScheme(
    primaryColor: Color(0xFF1976D2),
    secondaryColor: Color(0xFF42A5F5),
    backgroundColor: Colors.white,
    textColor: Color(0xFF0F0F0F),
    hintTextColor: Color(0xFF9292A0),
    userMessageColor: Color(0x0A000000),
    assistantMessageColor: Color(0xFF42424C),
    borderColor: Color(0x0A000000),
    floatingButtonColor: Color(0xFF1976D2),
    floatingButtonIconColor: Colors.white,
    overlayBackgroundColor: Color(0x4D000000), // Colors.black.withOpacity(0.3)
    modalBackgroundColor: Color(0xE0FFFFFF), // Colors.white.withOpacity(0.88)
    modalBorderColor: Color(0x4DFFFFFF), // Colors.white.withOpacity(0.3)
    modalShadowColor: Color(0x1A000000), // Colors.black.withOpacity(0.1)
    handleBarColor: Color(0x33000000), // Colors.black.withOpacity(0.2)
    userMessageTextColor: Color(0xff26262B), // dark900
    assistantMessageTextColor: Color(0xff42424c), // dark800
    inputBackgroundColor: Color(0xB3FFFFFF), // Colors.white.withOpacity(0.7)
    footerTextColor: Color(0x66000000), // Colors.black.withOpacity(0.4)
    suggestionCardBackgroundColor: Color(0xB3FFFFFF), // Colors.white.withOpacity(0.7)
    suggestionCardBorderColor: Color(0x4DFFFFFF), // Colors.white.withOpacity(0.3)
    suggestionIconColor: Color(0xffC8C8D0), // dark200
    suggestionPromptBackgroundColor: Colors.white,
    suggestionPromptBorderColor: Color(0x14000000), // Colors.black.withOpacity(0.08)
    shimmerBaseColor: Colors.white,
    shimmerHighlightColor: Color(0xFFE0E0E0), // Colors.grey[200]!
    skeletonColor: Colors.grey,
  );

  /// Green theme
  static const AssistantColorScheme green = AssistantColorScheme(
    primaryColor: Color(0xFF388E3C),
    secondaryColor: Color(0xFF66BB6A),
    backgroundColor: Colors.white,
    textColor: Color(0xFF0F0F0F),
    hintTextColor: Color(0xFF9292A0),
    userMessageColor: Color(0x0A000000),
    assistantMessageColor: Color(0xFF42424C),
    borderColor: Color(0x0A000000),
    floatingButtonColor: Color(0xFF388E3C),
    floatingButtonIconColor: Colors.white,
    overlayBackgroundColor: Color(0x4D000000), // Colors.black.withOpacity(0.3)
    modalBackgroundColor: Color(0xE0FFFFFF), // Colors.white.withOpacity(0.88)
    modalBorderColor: Color(0x4DFFFFFF), // Colors.white.withOpacity(0.3)
    modalShadowColor: Color(0x1A000000), // Colors.black.withOpacity(0.1)
    handleBarColor: Color(0x33000000), // Colors.black.withOpacity(0.2)
    userMessageTextColor: Color(0xff26262B), // dark900
    assistantMessageTextColor: Color(0xff42424c), // dark800
    inputBackgroundColor: Color(0xB3FFFFFF), // Colors.white.withOpacity(0.7)
    footerTextColor: Color(0x66000000), // Colors.black.withOpacity(0.4)
    suggestionCardBackgroundColor: Color(0xB3FFFFFF), // Colors.white.withOpacity(0.7)
    suggestionCardBorderColor: Color(0x4DFFFFFF), // Colors.white.withOpacity(0.3)
    suggestionIconColor: Color(0xffC8C8D0), // dark200
    suggestionPromptBackgroundColor: Colors.white,
    suggestionPromptBorderColor: Color(0x14000000), // Colors.black.withOpacity(0.08)
    shimmerBaseColor: Colors.white,
    shimmerHighlightColor: Color(0xFFE0E0E0), // Colors.grey[200]!
    skeletonColor: Colors.grey,
  );

  /// Create a copy with modified values
  AssistantColorScheme copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? textColor,
    Color? hintTextColor,
    Color? userMessageColor,
    Color? assistantMessageColor,
    Color? borderColor,
    Color? floatingButtonColor,
    Color? floatingButtonIconColor,
    Color? overlayBackgroundColor,
    Color? modalBackgroundColor,
    Color? modalBorderColor,
    Color? modalShadowColor,
    Color? handleBarColor,
    Color? userMessageTextColor,
    Color? assistantMessageTextColor,
    Color? inputBackgroundColor,
    Color? footerTextColor,
    Color? suggestionCardBackgroundColor,
    Color? suggestionCardBorderColor,
    Color? suggestionIconColor,
    Color? suggestionPromptBackgroundColor,
    Color? suggestionPromptBorderColor,
    Color? shimmerBaseColor,
    Color? shimmerHighlightColor,
    Color? skeletonColor,
  }) {
    return AssistantColorScheme(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      hintTextColor: hintTextColor ?? this.hintTextColor,
      userMessageColor: userMessageColor ?? this.userMessageColor,
      assistantMessageColor:
          assistantMessageColor ?? this.assistantMessageColor,
      borderColor: borderColor ?? this.borderColor,
      floatingButtonColor: floatingButtonColor ?? this.floatingButtonColor,
      floatingButtonIconColor:
          floatingButtonIconColor ?? this.floatingButtonIconColor,
      overlayBackgroundColor: overlayBackgroundColor ?? this.overlayBackgroundColor,
      modalBackgroundColor: modalBackgroundColor ?? this.modalBackgroundColor,
      modalBorderColor: modalBorderColor ?? this.modalBorderColor,
      modalShadowColor: modalShadowColor ?? this.modalShadowColor,
      handleBarColor: handleBarColor ?? this.handleBarColor,
      userMessageTextColor: userMessageTextColor ?? this.userMessageTextColor,
      assistantMessageTextColor: assistantMessageTextColor ?? this.assistantMessageTextColor,
      inputBackgroundColor: inputBackgroundColor ?? this.inputBackgroundColor,
      footerTextColor: footerTextColor ?? this.footerTextColor,
      suggestionCardBackgroundColor: suggestionCardBackgroundColor ?? this.suggestionCardBackgroundColor,
      suggestionCardBorderColor: suggestionCardBorderColor ?? this.suggestionCardBorderColor,
      suggestionIconColor: suggestionIconColor ?? this.suggestionIconColor,
      suggestionPromptBackgroundColor: suggestionPromptBackgroundColor ?? this.suggestionPromptBackgroundColor,
      suggestionPromptBorderColor: suggestionPromptBorderColor ?? this.suggestionPromptBorderColor,
      shimmerBaseColor: shimmerBaseColor ?? this.shimmerBaseColor,
      shimmerHighlightColor: shimmerHighlightColor ?? this.shimmerHighlightColor,
      skeletonColor: skeletonColor ?? this.skeletonColor,
    );
  }
}

