import 'package:flutter/material.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/app/routes.dart';

class CampusApp extends StatelessWidget {
  const CampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusGO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      
      // Konfigurasi routing
      initialRoute: Routes.splash,
      onGenerateRoute: Routes.generateRoute,
      
      // Navigasi observer untuk logging/tracking
      navigatorObservers: [
        // Tambahkan observer jika diperlukan (Firebase Analytics, dll)
      ],
    );
  }
}