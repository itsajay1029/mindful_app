import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../widgets/pressable_card.dart';
import 'daily_sprint_screen.dart';
import '../services/auth_service.dart';
import 'auth_gate.dart';
import 'leaderboard_screen.dart';
import 'learning_hub_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _bg = Color(0xFFF6F7FB);

  String _firstNameFromUserDoc(Map<String, dynamic> data) {
    final firstName = (data['firstName'] as String?)?.trim() ?? '';
    final displayName = (data['displayName'] as String?)?.trim() ?? '';
    final token = displayName.isEmpty ? '' : displayName.split(RegExp(r'\s+')).first;
    return firstName.isNotEmpty ? firstName : token;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cs = Theme.of(context).colorScheme;
    final firestore = FirestoreService();
    final auth = AuthService();

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user found.')));
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder(
          stream: firestore.streamUserDoc(user.uid),
          builder: (context, AsyncSnapshot userDocSnap) {
            if (userDocSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = (userDocSnap.data?.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
            final name = _firstNameFromUserDoc(data);
            final xp = (data['xp'] as num?)?.toInt() ?? 0;
            final streak = (data['streakCurrent'] as num?)?.toInt() ?? 0;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _HeroHeader(
                  greeting: name.isEmpty ? 'Welcome back' : 'Good Morning, $name',
                  xp: xp,
                  streak: streak,
                  photoUrl: user.photoURL,
                  onLogout: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Logout?'),
                        content: const Text('You will be signed out from this device.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (ok != true) return;
                    await auth.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthGate()),
                      (route) => false,
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Today's Sprint
                PressableCard(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DailySprintScreen()),
                    );
                  },
                  border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Sprint",
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Daily 10‑minute session to level up.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.black.withValues(alpha: 0.62),
                                    height: 1.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const DailySprintScreen()),
                          );
                        },
                        child: const Text('Start'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Daily Rituals
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Rituals',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Build healthy habits',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          builder: (ctx) => const _RitualsBottomSheet(),
                        );
                      },
                      child: const Text('View All  ›'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _RitualsPanel(
                  onLearningTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LearningHubScreen()),
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Track progress CTA
                PressableCard(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(22),
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _SoftLandscapePainter(
                              primary: cs.primary,
                              secondary: cs.secondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Track Progress',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'See your XP, streak and rank',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.90),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Open',
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Browse courses CTA
                PressableCard(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LearningHubScreen()),
                    );
                  },
                  border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.school_rounded, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Continue learning',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Explore courses tailored to your goals',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.black.withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black.withValues(alpha: 0.35)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.greeting,
    required this.xp,
    required this.streak,
    required this.photoUrl,
    required this.onLogout,
  });

  final String greeting;
  final int xp;
  final int streak;
  final String? photoUrl;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: 0.96),
                  cs.secondary.withValues(alpha: 0.82),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                  color: cs.primary.withValues(alpha: 0.22),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        greeting,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _Avatar(photoUrl: photoUrl, fallbackName: greeting),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatPill(icon: Icons.auto_awesome, label: 'XP', value: xp.toString()),
                    const SizedBox(width: 10),
                    _StatPill(icon: Icons.local_fire_department_rounded, label: 'Streak', value: streak.toString()),
                  ],
                ),
              ],
            ),
          ),

          Positioned(
            right: 10,
            top: 10,
            child: IconButton(
              onPressed: onLogout,
              icon: Icon(Icons.logout_rounded, color: Colors.white.withValues(alpha: 0.95)),
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.92)),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.fallbackName});

  final String? photoUrl;
  final String fallbackName;

  String _initials(String raw) {
    final parts = raw
        .replaceAll(RegExp(r'[^A-Za-z\s]'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    final first = parts.first;
    final second = parts.length > 1 ? parts[1] : '';
    return (first.isNotEmpty ? first[0] : '') + (second.isNotEmpty ? second[0] : '');
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(fallbackName);
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: photoUrl == null || photoUrl!.trim().isEmpty
            ? Center(
                child: Text(
                  initials.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              )
            : Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    initials.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ),
      ),
    );
  }
}

// NOTE: old _RitualTile removed after we switched to the richer Rituals panel.

class _RitualsPanel extends StatelessWidget {
  const _RitualsPanel({required this.onLearningTap});

  final VoidCallback onLearningTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SoftLandscapePainter(primary: cs.primary, secondary: cs.secondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Row(
              children: [
                Expanded(
                  child: PressableCard(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(18),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    child: _MiniRitual(icon: Icons.self_improvement_rounded, label: 'Breathing'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PressableCard(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(18),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    child: _MiniRitual(icon: Icons.edit_note_rounded, label: 'Journal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PressableCard(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(18),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    child: _MiniRitual(icon: Icons.directions_walk_rounded, label: 'Walk'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PressableCard(
                    onTap: onLearningTap,
                    borderRadius: BorderRadius.circular(18),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    child: _MiniRitual(icon: Icons.lightbulb_rounded, label: 'Learning'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRitual extends StatelessWidget {
  const _MiniRitual({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: cs.primary),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RitualsBottomSheet extends StatelessWidget {
  const _RitualsBottomSheet();

  static const _items = <({String title, IconData icon})>[
    (title: 'Breathing', icon: Icons.self_improvement_rounded),
    (title: 'Journal', icon: Icons.edit_note_rounded),
    (title: 'Walk', icon: Icons.directions_walk_rounded),
    (title: 'Learning', icon: Icons.lightbulb_rounded),
    (title: 'Focus', icon: Icons.center_focus_strong_rounded),
    (title: 'Gratitude', icon: Icons.volunteer_activism_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Rituals',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            ..._items.map(
              (it) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PressableCard(
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${it.title} — coming soon')),
                    );
                  },
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(it.icon, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          it.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black.withValues(alpha: 0.35)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftLandscapePainter extends CustomPainter {
  _SoftLandscapePainter({required this.primary, required this.secondary});

  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withValues(alpha: 0.95),
          secondary.withValues(alpha: 0.85),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Layer 1
    final p1 = Path()
      ..moveTo(0, size.height * 0.70)
      ..quadraticBezierTo(size.width * 0.30, size.height * 0.55, size.width * 0.60, size.height * 0.70)
      ..quadraticBezierTo(size.width * 0.82, size.height * 0.82, size.width, size.height * 0.66)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      p1,
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );

    // Layer 2
    final p2 = Path()
      ..moveTo(0, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.74, size.width * 0.50, size.height * 0.84)
      ..quadraticBezierTo(size.width * 0.76, size.height * 0.96, size.width, size.height * 0.80)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      p2,
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
  }

  @override
  bool shouldRepaint(covariant _SoftLandscapePainter oldDelegate) {
    return oldDelegate.primary != primary || oldDelegate.secondary != secondary;
  }
}
