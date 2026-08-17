class ParseUtils {
  /// Safely converts a dynamic value to double.
  /// Handles num, int, double, and String representations.
  /// Returns null if the value is null or cannot be parsed.
  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Safely converts a dynamic value to double with a fallback.
  static double parseDoubleOrDefault(dynamic value, {double fallback = 0.0}) {
    return parseDouble(value) ?? fallback;
  }

  /// Safely converts a dynamic value to int.
  /// Handles num, int, and String representations.
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Safely converts a dynamic value to int with a fallback.
  static int parseIntOrDefault(dynamic value, {int fallback = 0}) {
    return parseInt(value) ?? fallback;
  }

  /// Custom-object placeholders embedded in assistant text, e.g. "#OBJ1#".
  /// Must stay in sync with the placeholder regex used by TypingText.
  static final RegExp _customObjectPlaceholderRegex =
      RegExp(r'#OBJ(\d+)#(\.?)(,?)( ?)');

  /// Prepares assistant text for text-to-speech: removes custom-object
  /// placeholders (#OBJ1#, #OBJ2#, ...) — the cards they reference are
  /// visual-only and must not be read aloud — and collapses the leftover
  /// whitespace so the speech flows naturally.
  static String sanitizeForSpeech(String text) {
    return text
        .replaceAll(_customObjectPlaceholderRegex, ' ')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
