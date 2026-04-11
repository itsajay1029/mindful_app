import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';
import 'services/local_notification_service.dart';
import 'ui/emerald_orbit/eo_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Local notifications (Phase 2 daily reminder). Safe to call multiple times.
  await LocalNotificationService.instance.init();
  runApp(const MindfulApp());
}

class MindfulApp extends StatelessWidget {
  const MindfulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AboveTheGrind',
      debugShowCheckedModeBanner: false,
      theme: EmeraldOrbitTheme.light(),
      home: const AuthGate(),
    );
  }
}
