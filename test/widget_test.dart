// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epub_ink_reader/main.dart';
import 'package:epub_ink_reader/src/domain/controllers/library_controller.dart';

void main() {
  testWidgets('App shell smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = LibraryController();
    await controller.init();

    await tester.pumpWidget(EInkReaderApp(libraryController: controller));
    expect(find.text('Library'), findsWidgets);
  });
}
