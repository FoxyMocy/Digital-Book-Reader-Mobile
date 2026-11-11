import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book_file.dart';
import '../models/bookmark.dart';
import '../models/reader_settings.dart';
import '../services/local_library_scanner.dart';

class LibraryController extends ChangeNotifier {
  LibraryController({LocalLibraryScanner? scanner}) : _scanner = scanner ?? LocalLibraryScanner();

  final LocalLibraryScanner _scanner;
  final List<String> _sources = [];
  final List<BookFile> _books = [];
  bool _isScanning = false;
  bool _isInitialized = false;
  ReaderSettings _readerSettings = const ReaderSettings();
  String? _lastMessage;
  BookFile? _lastReadBook;
  bool _isGridView = false;
  String _filter = 'all';

  static const _sourcesKey = 'library_sources';
  static const _booksKey = 'library_books';
  static const _progressKey = 'library_progress';
  static const _themeKey = 'reader_theme';
  static const _fontSizeKey = 'reader_font_size';
  static const _lineHeightKey = 'reader_line_height';
  static const _localeKey = 'reader_locale';
  static const _lastReadKey = 'library_last_read';
  static const _viewModeKey = 'library_is_grid_view';
  static const _bookmarksKey = 'library_bookmarks';

  List<String> get sources => List.unmodifiable(_sources);
  List<BookFile> get books => List.unmodifiable(_books);
  bool get isScanning => _isScanning;
  bool get isInitialized => _isInitialized;
  ReaderSettings get readerSettings => _readerSettings;
  String? get lastMessage => _lastMessage;
  BookFile? get lastReadBook => _lastReadBook;
  bool get isGridView => _isGridView;
  String get filter => _filter;

  void toggleViewMode() {
    _isGridView = !_isGridView;
    SharedPreferences.getInstance().then((prefs) => prefs.setBool(_viewModeKey, _isGridView));
    notifyListeners();
  }

  void setFilter(String value) {
    if (value != 'all' && value != 'epub' && value != 'pdf') return;
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  List<BookFile> get filteredBooks {
    if (_filter == 'epub') return _books.where((b) => b.format == BookFormat.epub).toList();
    if (_filter == 'pdf') return _books.where((b) => b.format == BookFormat.pdf).toList();
    return _books;
  }

  int booksCountForSource(String source) {
    return _books.where((b) => b.path.startsWith(source)).length;
  }

  void clearMessage() {
    if (_lastMessage == null) return;
    _lastMessage = null;
    notifyListeners();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    final savedSources = prefs.getStringList(_sourcesKey);
    if (savedSources != null) {
      _sources.addAll(savedSources);
    }

    final savedBooks = prefs.getStringList(_booksKey);
    if (savedBooks != null) {
      for (final jsonStr in savedBooks) {
        try {
          _books.add(BookFile.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>));
        } catch (_) {}
      }
    }

    final themeName = prefs.getString(_themeKey);
    _readerSettings = ReaderSettings(
      theme: ReaderThemePreset.values.firstWhere(
        (theme) => theme.name == themeName,
        orElse: () => ReaderThemePreset.paper,
      ),
      fontSize: prefs.getDouble(_fontSizeKey) ?? 18,
      lineHeight: prefs.getDouble(_lineHeightKey) ?? 1.6,
      localeCode: prefs.getString(_localeKey) ?? 'en',
    );

    _isGridView = prefs.getBool(_viewModeKey) ?? false;
    
    final lastReadPath = prefs.getString(_lastReadKey);
    if (lastReadPath != null) {
      final idx = _books.indexWhere((b) => b.path == lastReadPath);
      if (idx != -1) _lastReadBook = _books[idx];
    }

    _isInitialized = true;
    notifyListeners();

    // Clean up stale files in background without blocking UI
    _verifyStaleFiles().then((changed) {
      if (changed) {
        _saveBooks();
        notifyListeners();
      }
    });
  }

  Future<void> addSource(String path) async {
    if (_sources.contains(path)) return;
    _sources.add(path);
    await _saveSources();
    notifyListeners();
    await scan();
  }

  /// Inject direct files bypassing folder scanner (for Android scoped storage fallback)
  Future<void> addDirectFiles(List<String> paths) async {
    int addedCount = 0;
    for (final path in paths) {
      if (_books.any((b) => b.path == path)) continue;
      
      final ext = path.toLowerCase();
      final format = ext.endsWith('.epub') ? BookFormat.epub : (ext.endsWith('.pdf') ? BookFormat.pdf : null);
      if (format == null) continue;

      final file = File(path);
      if (!await file.exists()) continue;

      final stat = await file.stat();
      final fileName = path.split(Platform.pathSeparator).last;
      final dot = fileName.lastIndexOf('.');
      final title = dot == -1 ? fileName : fileName.substring(0, dot);

      _books.add(BookFile(
        path: path,
        title: title,
        format: format,
        modifiedAt: stat.modified,
      ));
      addedCount++;
    }

    if (addedCount > 0) {
      _books.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      await _saveBooks();
      _lastMessage = "Berhasil menambahkan $addedCount file baru.";
      notifyListeners();
    } else {
      _lastMessage = "Tidak ada file baru ditambahkan (sudah ada / tidak didukung).";
      notifyListeners();
    }
  }

  Future<void> removeSource(String path) async {
    _sources.remove(path);
    await _saveSources();
    
    final originalCount = _books.length;
    _books.removeWhere((b) => b.path.startsWith(path));
    if (_books.length != originalCount) {
      await _saveBooks();
    }
    
    if (_lastReadBook?.path.startsWith(path) ?? false) {
      _lastReadBook = null;
    }

    notifyListeners();
    // Scan unneeded if we just removed books from memory.
  }

  Future<void> scan() async {
    _isScanning = true;
    notifyListeners();

    final scannedBooks = await _scanner.scanDirectories(_sources);

    // Merge manual direct files + scanned files
    final validManual = _books.where((b) => !_sources.any((s) => b.path.startsWith(s))).toList();
    
    _books
      ..clear()
      ..addAll(scannedBooks)
      ..addAll(validManual);
      
    // Dedupe
    final seen = <String>{};
    _books.retainWhere((b) {
      if (seen.contains(b.path)) return false;
      seen.add(b.path);
      return true;
    });

    _books.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    await _saveBooks();

    final found = scannedBooks.length;
    _lastMessage = "Scan selesai. Menemukan $found buku dari folder.";
    _isScanning = false;
    notifyListeners();
  }

  Future<void> _saveSources() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_sourcesKey, _sources);
  }

  Future<void> _saveBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _books.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList(_booksKey, jsonList);
  }

  Future<int> getProgress(String path) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_progressKey:$path') ?? 1;
  }

  Future<void> setProgress(String path, int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_progressKey:$path', page);
    await _updateLastRead(path);
  }

  Future<String?> getLocator(String path) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_progressKey:locator:$path');
  }

  Future<void> setLocator(String path, String locator) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_progressKey:locator:$path', locator);
    // Silent update _lastReadBook tanpa notifyListeners untuk menghindari rebuild di reader
    final idx = _books.indexWhere((b) => b.path == path);
    if (idx != -1) {
      _lastReadBook = _books[idx];
      await prefs.setString(_lastReadKey, path);
    }
  }

  // --- Bookmarks ---

  Future<List<Bookmark>> getBookmarks(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_bookmarksKey:$path');
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(Bookmark.fromJson).toList();
  }

  Future<void> addBookmark(String path, String position, String label) async {
    final bookmarks = await getBookmarks(path);
    bookmarks.add(Bookmark(
      position: position,
      label: label,
      createdAt: DateTime.now(),
    ));
    await _saveBookmarks(path, bookmarks);
  }

  Future<void> removeBookmark(String path, String position) async {
    final bookmarks = await getBookmarks(path);
    bookmarks.removeWhere((b) => b.position == position);
    await _saveBookmarks(path, bookmarks);
  }

  Future<void> _saveBookmarks(String path, List<Bookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_bookmarksKey:$path',
      jsonEncode(bookmarks.map((b) => b.toJson()).toList()),
    );
  }

  Future<void> _updateLastRead(String path) async {
    final idx = _books.indexWhere((b) => b.path == path);
    if (idx != -1) {
      _lastReadBook = _books[idx];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastReadKey, path);
      // notifyListeners delay to avoid changing UI during build/scroll
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> updateReaderSettings(ReaderSettings settings) async {
    _readerSettings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, settings.theme.name);
    await prefs.setDouble(_fontSizeKey, settings.fontSize);
    await prefs.setDouble(_lineHeightKey, settings.lineHeight);
    await prefs.setString(_localeKey, settings.localeCode);
    notifyListeners();
  }

  Future<bool> _verifyStaleFiles() async {
    bool changed = false;
    final validBooks = <BookFile>[];
    for (final book in _books) {
      if (await File(book.path).exists()) {
        validBooks.add(book);
      } else {
        changed = true;
      }
    }
    if (changed) {
      _books.clear();
      _books.addAll(validBooks);
    }
    return changed;
  }
}
