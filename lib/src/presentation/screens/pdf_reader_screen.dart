import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../domain/controllers/library_controller.dart';
import '../../domain/models/book_file.dart';
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
          appBar: AppBar(
            backgroundColor: colors.background,
            foregroundColor: colors.text,
            title: Text(widget.book.title, style: const TextStyle(fontSize: 16)),
            actions: [
              ValueListenableBuilder<int>(
                valueListenable: _pdfController.pageListenable,
                builder: (context, page, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(strings.page(page)),
                  ),
                ),
              ),
            ],
          ),
          body: PdfViewPinch(
            controller: _pdfController,
            onPageChanged: (page) => widget.libraryController.setProgress(widget.book.path, page),
          ),
        );
      },
    );
  }
}
