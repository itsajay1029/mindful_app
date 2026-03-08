import 'package:flutter/material.dart';

import 'coach_screen.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'reset_studio_screen.dart';
import 'segments_screen.dart';
import '../services/local_notification_service.dart';

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
    final cs = Theme.of(context).colorScheme;

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: cs.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Segments'),
          NavigationDestination(icon: Icon(Icons.headphones_rounded), label: 'Reset'),
          NavigationDestination(icon: Icon(Icons.emoji_events_rounded), label: 'Board'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_rounded), label: 'Coach'),
        ],
      ),
    );
  }
}
