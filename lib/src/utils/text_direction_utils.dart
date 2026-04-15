import 'package:flutter/material.dart';

/// Returns true if the given text contains Arabic characters.
bool containsArabic(String text) {
  return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
}

/// Returns [TextDirection.rtl] if the text contains Arabic characters,
/// otherwise returns [TextDirection.ltr].
TextDirection textDirectionForContent(String text) {
  return containsArabic(text) ? TextDirection.rtl : TextDirection.ltr;
}
