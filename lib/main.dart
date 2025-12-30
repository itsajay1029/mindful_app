import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';
import 'services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Local notifications (Phase 2 daily reminder). Safe to call multiple times.
  await LocalNotificationService.instance.init();
  runApp(const MindfulApp());
}

class MindfulApp extends StatelessWidget {
  const MindfulApp({super.key});

  static const _primary = Color(0xFF276347); // #276347
  static const _secondary = Color(0xFFD7A933); // #d7a933

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      secondary: _secondary,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'AboveTheGrind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
