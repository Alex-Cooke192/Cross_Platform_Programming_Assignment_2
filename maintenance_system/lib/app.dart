import 'package:flutter/material.dart';
import 'package:maintenance_system/core/data/local/app_database.dart';
import 'package:maintenance_system/ui/screens/home_screen.dart';
import 'core/theme/theme_controller.dart';
import 'config/app_themes.dart';

class App extends StatelessWidget {
  final AppDatabase database; 

  const App({
    super.key, 
    required this.database
    });

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
