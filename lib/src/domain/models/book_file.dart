enum BookFormat { epub, pdf }

class BookFile {
  const BookFile({
    required this.path,
    required this.title,
    required this.format,
    required this.modifiedAt,
  });

  final String path;
  final String title;
  final BookFormat format;
  final DateTime modifiedAt;

  Map<String, dynamic> toJson() => {
        'path': path,
        'title': title,
        'format': format.name,
        'modifiedAt': modifiedAt.toIso8601String(),
      };

  factory BookFile.fromJson(Map<String, dynamic> json) => BookFile(
        path: json['path'] as String,
        title: json['title'] as String,
        format: BookFormat.values.firstWhere(
          (e) => e.name == json['format'],
          orElse: () => BookFormat.epub,
        ),
        modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      );
}
