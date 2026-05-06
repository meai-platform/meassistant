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
}
