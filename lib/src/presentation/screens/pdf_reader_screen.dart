import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../domain/controllers/library_controller.dart';
import '../../domain/models/book_file.dart';
import '../../domain/models/bookmark.dart';
import '../localization/app_strings.dart';
import '../theme/reader_theme_colors.dart';

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({super.key, required this.book, required this.libraryController});

  final BookFile book;
  final LibraryController libraryController;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  late final PdfControllerPinch _pdfController;
  int _initialPage = 1;
  bool _isInit = false;
  bool _isImmersive = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    _initialPage = await widget.libraryController.getProgress(widget.book.path);
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(widget.book.path),
      initialPage: _initialPage,
    );
    setState(() => _isInit = true);
  }

  void _toggleImmersive() => setState(() => _isImmersive = !_isImmersive);

  // --- Bookmarks ---

  Future<void> _addBookmark() async {
    final page = _pdfController.page;
    await widget.libraryController.addBookmark(
      widget.book.path,
      page.toString(),
      'Halaman $page',
    );
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
          _pdfController.jumpToPage(int.parse(b.position));
        },
        onDelete: (b) {
          widget.libraryController.removeBookmark(widget.book.path, b.position);
          Navigator.pop(context);
        },
      ),
    );
  }

  // --- Jump to page ---

  Future<void> _showJumpToPage(int totalPages) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lompat ke halaman'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(hintText: '1 – $totalPages'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Lompat'),
          ),
        ],
      ),
    );
    if (result != null && result >= 1 && result <= totalPages) {
      _pdfController.jumpToPage(result);
    }
  }

  @override
  void dispose() {
    if (_isInit) _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ListenableBuilder(
      listenable: widget.libraryController,
      builder: (context, _) {
        final colors = ReaderThemeColors.from(widget.libraryController.readerSettings.theme);
        final strings = AppStrings.of(context);

        return Scaffold(
          backgroundColor: colors.background,
          appBar: _isImmersive
              ? null
              : AppBar(
                  backgroundColor: colors.background,
                  foregroundColor: colors.text,
                  title: Text(widget.book.title, style: const TextStyle(fontSize: 16)),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ValueListenableBuilder<int>(
                          valueListenable: _pdfController.pageListenable,
                          builder: (context, page, _) => TextButton(
                            onPressed: () => _showJumpToPage(_pdfController.pagesCount ?? 1),
                            child: Text(strings.page(page)),
                          ),
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
            child: PdfViewPinch(
              controller: _pdfController,
              onPageChanged: (page) => widget.libraryController.setProgress(widget.book.path, page),
            ),
          ),
        );
      },
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
