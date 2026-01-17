import 'package:flutter/material.dart';
import 'package:maintenance_system/ui/screens/home_screen.dart';
import 'core/theme/theme_controller.dart';
import 'config/app_themes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'RampCheck',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          home: const HomeScreen(), // At later date, change this to AppRoot()
        );
      },
    );
  }
}
