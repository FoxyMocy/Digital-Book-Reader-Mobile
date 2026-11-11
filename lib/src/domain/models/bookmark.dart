class Bookmark {
  const Bookmark({
    required this.position,
    required this.label,
    required this.createdAt,
  });

  /// CFI string for epub, page number as string for pdf.
  final String position;
  final String label;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'position': position,
        'label': label,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        position: json['position'] as String,
        label: json['label'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
