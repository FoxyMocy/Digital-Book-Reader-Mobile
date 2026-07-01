import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/book_file.dart';

class LocalLibraryScanner {
  Future<List<BookFile>> scanDirectories(List<String> paths) async {
    final seenPaths = <String>{};
    final results = <BookFile>[];

    for (final dirPath in paths) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        debugPrint('SCAN ERROR: Directory does not exist or no permission: $dirPath');
        continue;
      }

      try {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is! File) continue;

          final normalized = entity.absolute.path;
          if (_hasHiddenSegment(normalized)) continue;

          final format = _formatFor(normalized);
          if (format == null || seenPaths.contains(normalized)) continue;

          seenPaths.add(normalized);
          final stat = await entity.stat();

          results.add(BookFile(
            path: normalized,
            title: _titleFor(normalized),
            format: format,
            modifiedAt: stat.modified,
          ));
        }
      } on FileSystemException catch (e) {
        debugPrint('SCAN ERROR on $dirPath: $e');
        continue;
      } catch (e) {
        debugPrint('SCAN UNKNOWN ERROR on $dirPath: $e');
        continue;
      }
    }

    return results;
  }

  bool _hasHiddenSegment(String path) {
    return path.split(Platform.pathSeparator).any((segment) => segment.startsWith('.') && segment.length > 1);
  }

  BookFormat? _formatFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.epub')) return BookFormat.epub;
    if (lower.endsWith('.pdf')) return BookFormat.pdf;
    return null;
  }

  String _titleFor(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? fileName : fileName.substring(0, dot);
  }
}
