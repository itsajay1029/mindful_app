import 'package:flutter/material.dart';

import 'coach_screen.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'reset_studio_screen.dart';
import 'segments_screen.dart';
import '../services/local_notification_service.dart';
import '../ui/emerald_orbit/widgets/eo_bottom_nav.dart';

/// Main app container with bottom navigation.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _scheduledReminder = false;

  late final List<Widget> _tabs = const [
    HomeScreen(),
    SegmentsScreen(),
    ResetStudioScreen(),
    LeaderboardScreen(),
    CoachScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Schedule once per app session.
    if (!_scheduledReminder) {
      _scheduledReminder = true;
      LocalNotificationService.instance.scheduleDailyReminder(
        title: 'AboveTheGrind',
        body: 'Ready for your 10‑minute sprint?',
      );
    }

    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: EoBottomNav(
        index: _index,
        onSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
