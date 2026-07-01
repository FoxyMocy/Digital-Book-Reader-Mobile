import 'package:flutter/material.dart';

import '../../domain/controllers/library_controller.dart';
import '../../domain/models/reader_settings.dart';
import '../localization/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final settings = controller.readerSettings;
        final textTheme = Theme.of(context).textTheme;
        final strings = AppStrings.of(context);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(strings.settings, style: textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.language),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(strings.english),
                          selected: settings.localeCode == 'en',
                          onSelected: (_) => controller.updateReaderSettings(settings.copyWith(localeCode: 'en')),
                        ),
                        ChoiceChip(
                          label: Text(strings.indonesian),
                          selected: settings.localeCode == 'id',
                          onSelected: (_) => controller.updateReaderSettings(settings.copyWith(localeCode: 'id')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.theme),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final theme in ReaderThemePreset.values)
                          ChoiceChip(
                            label: Text(theme.name),
                            selected: settings.theme == theme,
                            onSelected: (_) => controller.updateReaderSettings(settings.copyWith(theme: theme)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.format_size),
                title: Text(strings.fontSize(settings.fontSize)),
                subtitle: Slider(
                  value: settings.fontSize,
                  min: 14,
                  max: 28,
                  divisions: 14,
                  label: settings.fontSize.toStringAsFixed(0),
                  onChanged: (value) => controller.updateReaderSettings(settings.copyWith(fontSize: value)),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.line_weight),
                title: Text(strings.lineHeight(settings.lineHeight)),
                subtitle: Slider(
                  value: settings.lineHeight,
                  min: 1.2,
                  max: 2.0,
                  divisions: 8,
                  label: settings.lineHeight.toStringAsFixed(1),
                  onChanged: (value) => controller.updateReaderSettings(settings.copyWith(lineHeight: value)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
