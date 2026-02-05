import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:campusapp/app/app.dart';
import 'firebase_options.dart';

void main() async {
  // WAJIB untuk Firebase & async di main
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(const CampusApp());
}
