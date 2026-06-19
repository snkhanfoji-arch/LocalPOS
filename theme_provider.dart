import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeOption { light, dark, blue, green, orange }

class ThemeNotifier extends StateNotifier<ThemeOption> {
  ThemeNotifier() : super(ThemeOption.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_option') ?? 0;
    if (themeIndex >= 0 && themeIndex < ThemeOption.values.length) {
      state = ThemeOption.values[themeIndex];
    }
  }

  Future<void> setTheme(ThemeOption option) async {
    state = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_option', option.index);
  }

  ThemeData getThemeData() {
    switch (state) {
      case ThemeOption.dark:
        return ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueGrey,
            brightness: Brightness.dark,
          ),
          fontFamily: 'Inter',
        );
      case ThemeOption.blue:
        return ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            primary: Colors.blue.shade800,
            secondary: Colors.blueAccent,
            brightness: Brightness.light,
          ),
          fontFamily: 'Inter',
        );
      case ThemeOption.green:
        return ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            primary: Colors.green.shade800,
            secondary: Colors.teal,
            brightness: Brightness.light,
          ),
          fontFamily: 'Inter',
        );
      case ThemeOption.orange:
        return ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            primary: Colors.orange.shade800,
            secondary: Colors.deepOrangeAccent,
            brightness: Brightness.light,
          ),
          fontFamily: 'Inter',
        );
      case ThemeOption.light:
      default:
        return ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            primary: Colors.indigo.shade700,
            secondary: Colors.amber.shade700,
            brightness: Brightness.light,
          ),
          fontFamily: 'Inter',
        );
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeOption>((ref) {
  return ThemeNotifier();
});
