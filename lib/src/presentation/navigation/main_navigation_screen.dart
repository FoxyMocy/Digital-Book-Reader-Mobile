import 'package:flutter/material.dart';

import '../../domain/controllers/library_controller.dart';
import '../screens/library_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/sources_screen.dart';
import '../localization/app_strings.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, required this.libraryController});

  final LibraryController libraryController;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final _screens = [
    LibraryScreen(controller: widget.libraryController),
    SourcesScreen(controller: widget.libraryController),
    SettingsScreen(controller: widget.libraryController),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appTitle),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books),
            label: strings.library,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder_copy),
            label: strings.sources,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: strings.settings,
          ),
        ],
      ),
    );
  }
}
