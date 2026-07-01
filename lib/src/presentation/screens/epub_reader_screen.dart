import 'dart:io';

import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';

import '../../domain/controllers/library_controller.dart';
import '../../domain/models/book_file.dart';

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
        // Jangan panggil await dan hindari re-render berat
        widget.libraryController.setLocator(widget.book.path, cfi);
      }
    }
  }

  @override
  void dispose() {
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
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        title: Text(widget.book.title, style: const TextStyle(fontSize: 16)),
      ),
      body: EpubView(
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
          errorBuilder: (context, error) => Center(child: Text('Error: $error', style: TextStyle(color: colors.text))),
        ),
      ),
    );
  }
}
