import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_riddle.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../ui/emerald_orbit/tokens.dart';
import '../ui/emerald_orbit/widgets/eo_tactile_button.dart';
import 'victory_celebration_screen.dart';

/// "Brain Break" riddle quest screens inspired by Stitch exports:
/// - `screens/stitch/riddle_quest_1`
/// - `screens/stitch/riddle_quest_2`
class RiddleQuestScreen extends StatefulWidget {
  const RiddleQuestScreen({super.key});

  @override
  State<RiddleQuestScreen> createState() => _RiddleQuestScreenState();
}

class _RiddleQuestScreenState extends State<RiddleQuestScreen> {
  int? _selected;
  bool _submitted = false;

  bool _busy = false;

  String _dateKey(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final user = FirebaseAuth.instance.currentUser;

    final dateKey = _dateKey(DateTime.now());

    return Scaffold(
      backgroundColor: EoColors.surface,
      // Built to match `screens/stitch/riddle_quest_1/code.html`.
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: EoColors.emerald100.withValues(alpha: 0.80),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  color: cs.primary.withValues(alpha: 0.10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: EoColors.primaryContainer,
                        borderRadius: BorderRadius.circular(EoRadii.full),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(EoRadii.full),
                        child: Image.asset(
                          'screens/stitch/riddle_quest_1/screen.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Brain Break',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: EoColors.emerald800,
                            letterSpacing: -0.2,
                          ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: EoColors.tertiaryContainer.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(EoRadii.full),
                      ),
                      child: StreamBuilder(
                        stream: user == null ? null : FirestoreService().streamUserDoc(user.uid),
                        builder: (context, snap) {
                          final data = (snap.data as dynamic)?.data() as Map<String, dynamic>?;
                          final streak = (data?['streakCurrent'] as num?)?.toInt() ?? 0;
                          return Row(
                            children: [
                              Icon(Icons.local_fire_department, color: cs.tertiary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '$streak',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: EoColors.onTertiaryContainer,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.bolt, color: EoColors.emerald700),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestoreService().dailyRiddleDoc(dateKey).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snap.data;
          if (doc == null || doc.exists == false) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No Daily Riddle configured for today ($dateKey).',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final riddle = DailyRiddle.fromDoc(doc);
          final options = riddle.options;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 160),
                children: [
              // Mascot placeholder (use stitch PNG for now)
              Center(
                child: SizedBox(
                  width: 190,
                  height: 190,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Image.asset(
                          'screens/stitch/riddle_quest_1/screen.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Transform.rotate(
                          angle: -0.20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: EoColors.primaryContainer,
                              borderRadius: BorderRadius.circular(EoRadii.full),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                  color: Colors.black.withValues(alpha: 0.10),
                                )
                              ],
                            ),
                            child: Text(
                              'QUEST ACTIVE!',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: EoColors.onPrimaryContainer,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Level 4: The Riddle Master'.toUpperCase(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: EoColors.onSurfaceVariant,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Think fast, Brainiac!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: EoColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(EoRadii.xl),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 50,
                      offset: const Offset(0, 20),
                      color: cs.primary.withValues(alpha: 0.10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // top gradient strip
                    Container(
                      height: 8,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(EoRadii.full),
                        gradient: LinearGradient(
                          colors: [cs.primary, EoColors.secondaryContainer],
                        ),
                      ),
                    ),
                    Text('🤔', style: Theme.of(context).textTheme.displaySmall),
                    const SizedBox(height: 12),
                    Text(
                      riddle.prompt,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.20,
                            fontSize: 20,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(99)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: EoColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: EoColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...List.generate(options.length, (i) {
                final selected = _selected == i;
                final isCorrect = _submitted && i == riddle.correctIndex;
                final base = EoColors.surfaceContainerLow;
                final bg = selected || isCorrect ? EoColors.primaryContainer : base;
                final bottomBorderColor = selected || isCorrect ? EoColors.onPrimaryFixedVariant : EoColors.surfaceContainerHighest;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: _submitted ? null : () => setState(() => _selected = i),
                    borderRadius: BorderRadius.circular(EoRadii.lg),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(EoRadii.lg),
                        boxShadow: [BoxShadow(blurRadius: 0, offset: const Offset(0, 4), color: bottomBorderColor)],
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              color: (selected || isCorrect) ? cs.primary : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode('A'.codeUnitAt(0) + i),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: (selected || isCorrect) ? Colors.white : cs.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              options[i],
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: selected || isCorrect ? FontWeight.w900 : FontWeight.w800,
                                    color: selected || isCorrect ? EoColors.onPrimaryContainer : EoColors.onSurface,
                                  ),
                            ),
                          ),
                          if (selected || isCorrect)
                            Icon(Icons.check_circle, color: cs.primary)
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [EoColors.surface.withValues(alpha: 0.0), EoColors.surface],
                ),
              ),
              child: EoTactileButton.tonal(
                label: _submitted ? 'Continue' : 'Check answer',
                onPressed: () async {
                  if (_busy) return;

                  final navigator = Navigator.of(context);

                  if (_selected == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick an option')));
                    return;
                  }
                  if (!_submitted) {
                    setState(() => _submitted = true);
                    return;
                  }

                  setState(() => _busy = true);

                  // Award + mark completion (idempotent)
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      return;
                    }

                    AnalyticsService.instance.track('daily_riddle_complete_attempt', props: {
                      'dateKey': dateKey,
                      'xpAward': riddle.xpAward,
                      'selected': _selected,
                      'correct': riddle.correctIndex,
                    });

                    final didAward = await FirestoreService().completeDailyRiddle(
                      uid: user.uid,
                      dateKey: dateKey,
                      xpAward: riddle.xpAward,
                    );

                    AnalyticsService.instance.track('daily_riddle_completed', props: {
                      'dateKey': dateKey,
                      'awarded': didAward,
                      'xpAward': riddle.xpAward,
                    });

                    // Show celebration then go back.
                    if (!mounted) return;
                    await navigator.push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => VictoryCelebrationScreen(
                          title: 'Mastermind!',
                          subtitle: riddle.explanation.trim().isEmpty
                              ? 'You decoded the riddle with ease.'
                              : riddle.explanation,
                          xpRewardLabel: didAward ? '+${riddle.xpAward} XP' : 'Completed',
                          streakLabel: didAward ? 'Streak Updated!' : 'Already completed today',
                        ),
                      ),
                    );
                  } catch (e) {
                    AnalyticsService.instance.track('daily_riddle_complete_failed', props: {
                      'error': e.toString(),
                    });
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }

                  if (!mounted) return;
                  navigator.maybePop();
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                toneColor: _submitted ? cs.primaryContainer : cs.secondaryContainer,
              ),
            ),
          )
        ],
      );
        },
      ),
    );
  }
}
