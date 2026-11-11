import 'dart:io';

import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';

import '../../domain/controllers/library_controller.dart';
import '../../domain/models/book_file.dart';
import '../../domain/models/bookmark.dart';
import '../theme/reader_theme_colors.dart';

class EpubReaderScreen extends StatefulWidget {
  const EpubReaderScreen({
    super.key,
    required this.book,
    required this.libraryController,
  });

  final BookFile book;
  final LibraryController libraryController;

  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  late final EpubController _epubController;
  bool _isInit = false;
  bool _isImmersive = false;
  bool _isSearchOpen = false;
  final _searchController = TextEditingController();
  List<Map<String, String>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final bytes = await File(widget.book.path).readAsBytes();
    final savedCfi = await widget.libraryController.getLocator(widget.book.path);

    _epubController = EpubController(
      document: EpubDocument.openData(bytes),
      epubCfi: savedCfi,
    );
    setState(() => _isInit = true);
  }

  void _onChapterChanged(dynamic value) {
    if (value != null) {
      final cfi = _epubController.generateEpubCfi();
      if (cfi != null) {
        widget.libraryController.setLocator(widget.book.path, cfi);
      }
    }
  }

  void _toggleImmersive() => setState(() => _isImmersive = !_isImmersive);

  // --- Bookmarks ---

  Future<void> _addBookmark() async {
    final cfi = _epubController.generateEpubCfi();
    if (cfi == null) return;
    final chapterTitle = _epubController.currentValue?.chapter?.Title ?? 'Bookmark';
    await widget.libraryController.addBookmark(widget.book.path, cfi, chapterTitle);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmark ditambahkan')),
      );
    }
  }

  Future<void> _showBookmarks() async {
    final bookmarks = await widget.libraryController.getBookmarks(widget.book.path);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => _BookmarkList(
        bookmarks: bookmarks,
        onTap: (b) {
          Navigator.pop(context);
          _epubController.gotoEpubCfi(b.position);
        },
        onDelete: (b) {
          widget.libraryController.removeBookmark(widget.book.path, b.position);
          Navigator.pop(context);
        },
      ),
    );
  }

  // --- Table of Contents ---

  void _showToc() {
    showModalBottomSheet(
      context: context,
      builder: (context) => EpubViewTableOfContents(
        controller: _epubController,
        itemBuilder: (context, index, chapter, itemCount) => ListTile(
          dense: true,
          title: Text(
            chapter.title ?? 'Tanpa judul',
            style: TextStyle(
              fontWeight: chapter.type == 'chapter' ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            _epubController.scrollTo(index: chapter.startIndex);
          },
        ),
      ),
    );
  }

  // --- Search ---

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final doc = await _epubController.document;
    final results = <Map<String, String>>[];
    final lowerQuery = query.toLowerCase();

    void searchChapters(List<EpubChapter>? chapters) {
      if (chapters == null) return;
      for (final ch in chapters) {
        final html = ch.HtmlContent ?? '';
        final text = html.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ');
        final idx = text.toLowerCase().indexOf(lowerQuery);
        if (idx != -1) {
          final start = (idx - 30).clamp(0, text.length);
          final end = (idx + query.length + 30).clamp(0, text.length);
          results.add({
            'title': ch.Title ?? 'Tanpa judul',
            'snippet': '…${text.substring(start, end)}…',
            'chapterIndex': (doc.Chapters?.indexOf(ch) ?? 0).toString(),
          });
        }
        searchChapters(ch.SubChapters);
      }
    }

    searchChapters(doc.Chapters);
    setState(() => _searchResults = results);
  }

  void _closeSearch() {
    setState(() {
      _isSearchOpen = false;
      _searchResults = [];
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_isInit) _epubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final settings = widget.libraryController.readerSettings;
    final colors = ReaderThemeColors.from(settings.theme);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _isImmersive
          ? null
          : AppBar(
              backgroundColor: colors.background,
              foregroundColor: colors.text,
              title: _isSearchOpen
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(color: colors.text, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Cari dalam buku…',
                        hintStyle: TextStyle(color: colors.text.withValues(alpha: 0.5)),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _search,
                      onChanged: _search,
                    )
                  : Text(widget.book.title, style: const TextStyle(fontSize: 16)),
              actions: [
                if (_isSearchOpen)
                  IconButton(icon: const Icon(Icons.close), onPressed: _closeSearch),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => setState(() => _isSearchOpen = true),
                      tooltip: 'Cari',
                    ),
                    IconButton(
                      icon: const Icon(Icons.toc),
                      onPressed: _showToc,
                      tooltip: 'Daftar Isi',
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark_add_outlined),
                      onPressed: _addBookmark,
                      tooltip: 'Tambah Bookmark',
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmarks_outlined),
                      onPressed: _showBookmarks,
                      tooltip: 'Daftar Bookmark',
                    ),
                  ],
                ),
              ),
            ),
      body: GestureDetector(
        onTap: _toggleImmersive,
        child: _isSearchOpen && _searchResults.isNotEmpty
            ? _SearchResultsList(
                results: _searchResults,
                colors: colors,
                onTap: (r) {
                  _closeSearch();
                  _epubController.scrollTo(index: int.parse(r['chapterIndex']!));
                },
              )
            : EpubView(
                controller: _epubController,
                onChapterChanged: _onChapterChanged,
                builders: EpubViewBuilders<DefaultBuilderOptions>(
                  options: DefaultBuilderOptions(
                    textStyle: TextStyle(
                      color: colors.text,
                      fontSize: settings.fontSize,
                      height: settings.lineHeight,
                    ),
                  ),
                  errorBuilder: (context, error) =>
                      Center(child: Text('Error: $error', style: TextStyle(color: colors.text))),
                ),
              ),
      ),
    );
  }
}

class _BookmarkList extends StatelessWidget {
  const _BookmarkList({
    required this.bookmarks,
    required this.onTap,
    required this.onDelete,
  });

  final List<Bookmark> bookmarks;
  final void Function(Bookmark) onTap;
  final void Function(Bookmark) onDelete;

  @override
  Widget build(BuildContext context) {
    if (bookmarks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('Belum ada bookmark')),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final b = bookmarks[index];
        return ListTile(
          leading: const Icon(Icons.bookmark_outline),
          title: Text(b.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(b.createdAt.toString().substring(0, 16)),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => onDelete(b),
          ),
          onTap: () => onTap(b),
        );
      },
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({
    required this.results,
    required this.colors,
    required this.onTap,
  });

  final List<Map<String, String>> results;
  final ReaderThemeColors colors;
  final void Function(Map<String, String>) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final r = results[index];
        return ListTile(
          title: Text(r['title']!, style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
          subtitle: Text(r['snippet']!, style: TextStyle(color: colors.text.withValues(alpha: 0.7))),
          onTap: () => onTap(r),
        );
      },
    );
  }
}
