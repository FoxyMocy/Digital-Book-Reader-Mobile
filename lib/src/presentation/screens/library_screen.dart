import 'package:flutter/material.dart';

import '../../domain/controllers/library_controller.dart';
import '../../domain/models/book_file.dart';
import '../localization/app_strings.dart';
import 'epub_reader_screen.dart';
import 'pdf_reader_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.controller});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final books = controller.filteredBooks;
        final textTheme = Theme.of(context).textTheme;
        final lastRead = controller.lastReadBook;
        final strings = AppStrings.of(context);
        final colorScheme = Theme.of(context).colorScheme;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (lastRead != null) ...[
                  Card(
                    color: colorScheme.primaryContainer,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              lastRead.format == BookFormat.epub ? Icons.auto_stories : Icons.picture_as_pdf,
                              color: colorScheme.onPrimaryContainer,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(strings.lastRead, style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimaryContainer)),
                                const SizedBox(height: 2),
                                Text(
                                  lastRead.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimaryContainer),
                                ),
                                const SizedBox(height: 2),
                                Text(strings.previousBookHint, style: textTheme.bodySmall?.copyWith(color: colorScheme.onPrimaryContainer)),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: () => _openBook(context, lastRead),
                                  child: Text(strings.continueReading),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(strings.library, style: textTheme.titleLarge),
                    IconButton(
                      tooltip: controller.isGridView ? strings.listMode : strings.gridMode,
                      icon: Icon(controller.isGridView ? Icons.view_list : Icons.grid_view),
                      onPressed: controller.toggleViewMode,
                    ),
                  ],
                ),
                Text('${strings.totalBooks}: ${controller.books.length}', style: textTheme.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('All (${controller.books.length})'),
                      selected: controller.filter == 'all',
                      onSelected: (_) => controller.setFilter('all'),
                    ),
                    ChoiceChip(
                      label: Text('EPUB (${controller.books.where((b) => b.format == BookFormat.epub).length})'),
                      selected: controller.filter == 'epub',
                      onSelected: (_) => controller.setFilter('epub'),
                    ),
                    ChoiceChip(
                      label: Text('PDF (${controller.books.where((b) => b.format == BookFormat.pdf).length})'),
                      selected: controller.filter == 'pdf',
                      onSelected: (_) => controller.setFilter('pdf'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (controller.isScanning) const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: 12),
                if (books.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(strings.noBookInFilter),
                    ),
                  )
                else if (controller.isGridView)
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: books.length,
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: isWide ? 260 : 180,
                      childAspectRatio: 3 / 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _openBook(context, book),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  book.format == BookFormat.epub ? Icons.menu_book : Icons.picture_as_pdf,
                                  size: 32,
                                ),
                                const Spacer(),
                                Text(
                                  book.title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(book.format.name.toUpperCase(), style: textTheme.labelSmall),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                else
                  ...books.map(
                    (book) => Card(
                      child: ListTile(
                        leading: Icon(book.format == BookFormat.epub ? Icons.menu_book : Icons.picture_as_pdf),
                        title: Text(book.title),
                        subtitle: Text(book.format.name.toUpperCase()),
                        onTap: () => _openBook(context, book),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _openBook(BuildContext context, BookFile book) {
    final reader = book.format == BookFormat.pdf
        ? PdfReaderScreen(book: book, libraryController: controller)
        : EpubReaderScreen(book: book, libraryController: controller);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => reader),
    );
  }
}
