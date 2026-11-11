import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/controllers/library_controller.dart';
import '../localization/app_strings.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key, required this.controller});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final sources = controller.sources;
        final textTheme = Theme.of(context).textTheme;
        final strings = AppStrings.of(context);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(strings.sources, style: textTheme.titleLarge),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => _addFiles(context),
                      icon: const Icon(Icons.file_open),
                      label: Text(strings.addFiles),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _addFolder(context),
                      icon: const Icon(Icons.create_new_folder),
                      label: Text(strings.addFolder),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.library_books),
                title: Text('${controller.books.length} ${strings.booksInLibrary}'),
                subtitle: controller.lastMessage == null ? null : Text(controller.lastMessage!),
                trailing: controller.lastMessage == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: controller.clearMessage,
                      ),
              ),
            ),
            if (sources.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(strings.noSources),
                  subtitle: Text(strings.noSourcesHelp),
                ),
              )
            else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: controller.isScanning ? null : () => _scan(context),
                  icon: const Icon(Icons.refresh),
                  label: Text(strings.scan),
                ),
              ),
              for (final source in sources)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(source, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(strings.booksFromFolder(controller.booksCountForSource(source))),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmRemoveSource(context, source, strings),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _addFolder(BuildContext context) async {
    if (!await _ensureFolderScanPermission(context)) return;

    final path = await FilePicker.getDirectoryPath();
    if (path == null) return;
    await controller.addSource(path);
  }

  Future<void> _scan(BuildContext context) async {
    if (!await _ensureFolderScanPermission(context)) return;
    await controller.scan();
  }

  Future<bool> _ensureFolderScanPermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    final isGranted = await Permission.manageExternalStorage.isGranted;
    if (isGranted) return true;

    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;

    if (context.mounted) {
      final strings = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.folderPermissionMessage)),
      );
      await openAppSettings();
    }
    return false;
  }

  Future<void> _confirmRemoveSource(BuildContext context, String source, AppStrings strings) async {
    final booksCount = controller.booksCountForSource(source);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.removeSourceTitle),
        content: Text(strings.removeSourceMessage(booksCount)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(strings.remove)),
        ],
      ),
    );

    if (confirm == true) {
      await controller.removeSource(source);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.sourceRemoved)),
        );
      }
    }
  }

  Future<void> _addFiles(BuildContext context) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
    );
    final validPaths = files.map((f) => f.path).whereType<String>().toList();
    if (validPaths.isEmpty) return;
    await controller.addDirectFiles(validPaths);
  }
}
