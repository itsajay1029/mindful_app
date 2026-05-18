import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../ui/emerald_orbit/tokens.dart';
import '../ui/emerald_orbit/widgets/eo_avatar_ring.dart';
import '../ui/emerald_orbit/widgets/eo_card.dart';
import '../ui/emerald_orbit/widgets/eo_glass.dart';
import '../ui/emerald_orbit/widgets/eo_tactile_button.dart';
import 'auth_gate.dart';
import 'daily_sprint_screen.dart';
import 'leaderboard_screen.dart';
import 'learning_hub_screen.dart';
import 'riddle_quest_screen.dart';

/// Home hub redesigned to match Stitch exports:
/// - `screens/stitch/home_hub_1`
/// - `screens/stitch/home_hub_2` (includes the Brain Break / Riddle card)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(milliseconds: 900));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String _firstName(Map<String, dynamic> data) {
    final firstName = (data['firstName'] as String?)?.trim() ?? '';
    final displayName = (data['displayName'] as String?)?.trim() ?? '';
    final token = displayName.isEmpty ? '' : displayName.split(RegExp(r'\s+')).first;
    return firstName.isNotEmpty ? firstName : token;
  }

  double _xpProgress(int xp) {
    const goal = 100;
    return (xp % goal) / goal;
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EoColors.surfaceContainerLowest,
        titleTextStyle: Theme.of(ctx).textTheme.titleLarge?.copyWith(
              color: EoColors.onSurface,
              fontWeight: FontWeight.w900,
            ),
        contentTextStyle: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
              color: EoColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
        title: const Text('Logout?'),
        content: const Text('You will be signed out from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Logout')),
        ],
      ),
    );

    if (ok != true) return;
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user found.')));
    }

    final cs = Theme.of(context).colorScheme;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: EoColors.background,
      body: Stack(
        children: [
          // ===== Top glass app bar (Stitch floating HUD) =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: EoGlass(
                  borderRadius: BorderRadius.circular(EoRadii.xl),
                  blur: 24,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                      color: cs.primary.withValues(alpha: 0.10),
                    ),
                  ],
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.10)),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _logout(context),
                        icon: Icon(Icons.arrow_back_rounded, color: cs.primary),
                        tooltip: 'Logout',
                      ),
                      Expanded(
                        child: Text(
                          'AboveTheGrind',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: EoColors.onSurface,
                              ),
                        ),
                      ),
                      StreamBuilder(
                        stream: FirestoreService().streamUserDoc(user.uid),
                        builder: (context, snap) {
                          final data = snap.data?.data() ?? <String, dynamic>{};
                          final xp = (data['xp'] as num?)?.toInt() ?? 0;
                          return EoAvatarRing(
                            photoUrl: user.photoURL,
                            progress: _xpProgress(xp),
                            size: 40,
                            ringWidth: 3,
                            ringColor: cs.primary,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ===== Content =====
          Padding(
            // The floating glass HUD is inside SafeArea, so on devices with
            // notches/taller status bars the HUD sits lower. Include the top
            // inset here to avoid overlap.
            padding: EdgeInsets.only(top: 92 + topInset),
            child: StreamBuilder(
              stream: FirestoreService().streamUserDoc(user.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snap.data?.data() ?? <String, dynamic>{};
                final name = _firstName(data);
                final xp = (data['xp'] as num?)?.toInt() ?? 0;
                final streak = (data['streakCurrent'] as num?)?.toInt() ?? 0;

                Future<void> openSprint() async {
                  final didAward = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const DailySprintScreen()),
                  );
                  if (didAward == true && mounted) {
                    _confetti.play();
                  }
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 140),
                  children: [
                    // Hero header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [EoColors.primary, EoColors.primaryDim],
                        ),
                        borderRadius: BorderRadius.circular(EoRadii.lg),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 50,
                            offset: const Offset(0, 18),
                            color: EoColors.primary.withValues(alpha: 0.30),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WELCOME BACK',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: cs.onPrimary.withValues(alpha: 0.80),
                                  letterSpacing: 1.6,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name.isEmpty ? 'Good Morning' : 'Good Morning, $name',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _HeroPill(icon: Icons.local_fire_department_rounded, label: '$streak Day Streak', tint: EoColors.secondaryContainer),
                              _HeroPill(icon: Icons.star_rounded, label: 'XP $xp', tint: EoColors.tertiaryContainer),
                            ],
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Knowledge Quests (new home)
                    const _KnowledgeQuestsSection(),

                    // Daily Sprint card
                    EoCard(
                      padding: const EdgeInsets.all(20),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(Icons.bolt_rounded, color: cs.primary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: cs.tertiaryContainer.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '+20 XP',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: cs.tertiary,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Daily Sprint', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(
                            '1 question • ~2 min',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: EoColors.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: EoTactileButton.primary(
                              label: 'Start Sprint',
                              icon: const Icon(Icons.play_arrow_rounded),
                              onPressed: openSprint,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Brain Break / Riddle card (Home Hub 2)
                    EoCard(
                      padding: const EdgeInsets.all(20),
                      border: Border.all(color: EoColors.secondaryContainer.withValues(alpha: 0.22)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: EoColors.secondaryContainer.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(Icons.extension_rounded, color: EoColors.onSecondaryContainer),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: EoColors.secondaryContainer.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Brain Break'.toUpperCase(),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: EoColors.onSecondaryContainer,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Riddle of the Day', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(
                            'Solve to boost your streak!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: EoColors.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: EoTactileButton.tonal(
                              label: 'Play now',
                              icon: const Icon(Icons.extension_rounded),
                              toneColor: EoColors.secondaryContainer,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RiddleQuestScreen()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick actions bento
                    Row(
                      children: [
                        Expanded(
                          child: _BentoTile(
                            color: EoColors.secondaryContainer,
                            icon: Icons.search_rounded,
                            iconColor: EoColors.onSecondaryContainer,
                            title: 'Find a\nCourse',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const LearningHubScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BentoTile(
                            color: EoColors.surfaceContainerHigh,
                            icon: Icons.emoji_events_rounded,
                            iconColor: cs.primary,
                            title: 'Leaderboard\nGlobal',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Rituals
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Daily Rituals', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        TextButton(
                          onPressed: () {
                            showModalBottomSheet<void>(
                              context: context,
                              showDragHandle: true,
                              builder: (ctx) => const _RitualsBottomSheet(),
                            );
                          },
                          child: const Text('View All'),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _RitualsGrid(),
                    const SizedBox(height: 28),
                  ],
                );
              },
            ),
          ),

          // Confetti overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 0,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.08,
                numberOfParticles: 18,
                maxBlastForce: 18,
                minBlastForce: 8,
                gravity: 0.22,
                colors: [cs.secondary, cs.primary, cs.tertiary, Colors.white],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label, required this.tint});
  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: tint.withValues(alpha: 0.95)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeQuestsSection extends StatelessWidget {
  const _KnowledgeQuestsSection();

  static final Uri _missionUrl = Uri.parse('https://www.abovethegrind.org');

  Future<void> _openMission(BuildContext context) async {
    final ok = await launchUrl(_missionUrl, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open www.abovethegrind.org')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget item({
      required IconData icon,
      required Color iconColor,
      required String title,
      required String subtitle,
      Widget? trailing,
    }) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EoColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(EoRadii.lg),
          border: Border.all(color: Colors.transparent, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: EoColors.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: EoColors.onSurfaceVariant,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(height: 10),
                    trailing,
                  ]
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Knowledge Quests', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'New Discovery'.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            // soft orb glow (matches Tailwind: blur-3xl circle)
            Positioned(
              right: -48,
              top: -48,
              child: Container(
                height: 128,
                width: 128,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            EoCard(
              padding: const EdgeInsets.all(20),
              border: Border.all(color: cs.primaryContainer.withValues(alpha: 0.35)),
              shadowColor: cs.primary.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(EoRadii.lg),
                        ),
                        child: Icon(Icons.auto_awesome_rounded, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'What is AboveTheGrind?',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: EoColors.onSurface,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  item(
                    icon: Icons.center_focus_strong_rounded,
                    iconColor: cs.primary,
                    title: 'Redefining Leadership',
                    subtitle: 'Helping leaders achieve clarity, balance, and results in a high-pressure world.',
                  ),
                  const SizedBox(height: 12),
                  item(
                    icon: Icons.psychology_rounded,
                    iconColor: cs.secondary,
                    title: 'Intentional Growth',
                    subtitle: 'Coaching • Mindfulness • Consulting • Financial Advisory',
                    trailing: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: const [
                        _MiniTag('Coaching'),
                        _MiniTag('Mindfulness'),
                        _MiniTag('Consulting'),
                        _MiniTag('Financial Advisory'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  item(
                    icon: Icons.groups_rounded,
                    iconColor: cs.tertiary,
                    title: 'How to Lead',
                    subtitle: 'Build stronger teams, create effective systems, and inspire purposeful leadership.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: EoTactileButton.tonal(
                      label: 'Explore the Mission',
                      icon: const Icon(Icons.open_in_new_rounded),
                      toneColor: EoColors.surfaceContainerHigh,
                      onPressed: () => _openMission(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: EoColors.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              fontSize: 9,
            ),
      ),
    );
  }
}

class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(EoRadii.lg),
      child: Container(
        height: 128,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(EoRadii.lg),
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              offset: const Offset(0, 12),
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 30),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    color: iconColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RitualsGrid extends StatelessWidget {
  const _RitualsGrid();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    void comingSoon(String label) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label — coming soon')));
    }

    Widget tile({required IconData icon, required Color iconColor, required String title, required String meta, required VoidCallback onTap}) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EoRadii.lg),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: EoColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(EoRadii.lg),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.08), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                meta.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: EoColors.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        tile(icon: Icons.air_rounded, iconColor: Colors.blue, title: 'Breathing', meta: '5 min session', onTap: () => comingSoon('Breathing')),
        tile(icon: Icons.edit_note_rounded, iconColor: Colors.amber.shade700, title: 'Journal', meta: 'Morning entry', onTap: () => comingSoon('Journal')),
        tile(icon: Icons.directions_walk_rounded, iconColor: Colors.green.shade700, title: 'Walk', meta: '2,400 steps', onTap: () => comingSoon('Walk')),
        tile(
          icon: Icons.menu_book_rounded,
          iconColor: Colors.purple,
          title: 'Learning',
          meta: '15 min deep',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LearningHubScreen()));
          },
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
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('All Rituals', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ..._items.map(
              (it) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EoCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.10)),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${it.title} — coming soon')));
                  },
                  child: Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(it.icon, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(it.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      ),
                      Icon(Icons.chevron_right_rounded, color: EoColors.onSurfaceVariant.withValues(alpha: 0.60)),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
