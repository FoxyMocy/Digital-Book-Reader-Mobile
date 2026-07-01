import 'package:flutter/material.dart';

import '../../domain/models/reader_settings.dart';

class ReaderThemeColors {
  const ReaderThemeColors({required this.background, required this.text});

  final Color background;
  final Color text;

  static ReaderThemeColors from(ReaderThemePreset preset) {
    return switch (preset) {
      ReaderThemePreset.paper => const ReaderThemeColors(
          background: Color(0xFFF3F1E8),
          text: Color(0xFF222222),
        ),
      ReaderThemePreset.sepia => const ReaderThemeColors(
          background: Color(0xFFF1E3C6),
          text: Color(0xFF2B2118),
        ),
      ReaderThemePreset.gray => const ReaderThemeColors(
          background: Color(0xFFE7E7E0),
          text: Color(0xFF202020),
        ),
      ReaderThemePreset.dark => const ReaderThemeColors(
          background: Color(0xFF1F1F1B),
          text: Color(0xFFE8E2CF),
        ),
    };
  }
}
