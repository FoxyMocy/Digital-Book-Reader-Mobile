enum ReaderThemePreset {
  paper,
  sepia,
  gray,
  dark,
}

class ReaderSettings {
  const ReaderSettings({
    this.theme = ReaderThemePreset.paper,
    this.fontSize = 18.0,
    this.lineHeight = 1.6,
    this.localeCode = 'en',
  });

  final ReaderThemePreset theme;
  final double fontSize;
  final double lineHeight;
  final String localeCode;

  ReaderSettings copyWith({
    ReaderThemePreset? theme,
    double? fontSize,
    double? lineHeight,
    String? localeCode,
  }) {
    return ReaderSettings(
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      localeCode: localeCode ?? this.localeCode,
    );
  }
}
