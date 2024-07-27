import 'dart:math';

extension StringUtil on String {
  /// Returns the safe substring ensuring the [start] and [end] are not outside
  /// the range.
  ///
  /// If [start] is outside the range, an empty string is returned.
  String safeSubstring(int start, [int? end]) {
    if (start >= length) return '';
    return substring(start, end != null ? min(length, end) : length);
  }
}
