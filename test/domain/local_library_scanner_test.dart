import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:epub_ink_reader/src/domain/services/local_library_scanner.dart';
import 'package:epub_ink_reader/src/domain/models/book_file.dart';

void main() {
  late Directory tempDir;
  late LocalLibraryScanner scanner;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('epub_ink_reader_test');
    scanner = LocalLibraryScanner();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('scanner finds epub and pdf, ignores others and hidden', () async {
    await File('${tempDir.path}/a.epub').create();
    await File('${tempDir.path}/b.pdf').create();
    await File('${tempDir.path}/c.txt').create();

    final sub = await Directory('${tempDir.path}/.hidden').create();
    await File('${sub.path}/d.epub').create();

    final books = await scanner.scanDirectories([tempDir.path]);
    
    expect(books.length, 2);
    final titles = books.map((b) => b.title).toList()..sort();
    expect(titles, ['a', 'b']);
    expect(books.firstWhere((b) => b.title == 'a').format, BookFormat.epub);
    expect(books.firstWhere((b) => b.title == 'b').format, BookFormat.pdf);
  });
}
