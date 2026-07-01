import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/domain/controllers/library_controller.dart';
import 'src/presentation/navigation/main_navigation_screen.dart';
import 'src/presentation/theme/eink_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final libraryController = LibraryController();
  await libraryController.init();
  runApp(EInkReaderApp(libraryController: libraryController));
}

class EInkReaderApp extends StatelessWidget {
  const EInkReaderApp({super.key, required this.libraryController});

  final LibraryController libraryController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: libraryController,
      builder: (context, _) {
        final localeCode = libraryController.readerSettings.localeCode;
        return MaterialApp(
          title: 'Digital Book Reader',
          theme: EInkTheme.lightTheme,
          locale: Locale(localeCode),
          supportedLocales: const [
            Locale('en'),
            Locale('id'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MainNavigationScreen(libraryController: libraryController),
        );
      },
    );
  }
}
