import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/daily_sprint.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';

/// MVP Daily Sprint: a single interactive quiz question.
///
/// This is intentionally simple so the client can experience “play → reward”.
class DailySprintScreen extends StatefulWidget {
  const DailySprintScreen({super.key});

  @override
  State<DailySprintScreen> createState() => _DailySprintScreenState();
}

class _DailySprintScreenState extends State<DailySprintScreen> {
  int? _selected;
  bool _submitted = false;
  bool _busy = false;
  String? _error;
  bool _didAward = false;

  String _dateKey(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

  Future<void> _completeSprint() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dateKey = _dateKey(DateTime.now());
    final contentSnap = await FirestoreService().dailySprintDoc(dateKey).get();
    if (!contentSnap.exists) {
      if (!mounted) return;
      setState(() => _error = 'No Daily Sprint configured for today ($dateKey).');
      return;
    }

    final sprint = DailySprint.fromDoc(contentSnap);
    if (sprint.xpAward <= 0) {
      if (!mounted) return;
      setState(() => _error = 'Daily Sprint is missing a valid xpAward.');
      return;
    }

    AnalyticsService.instance.track('daily_sprint_complete_attempt', props: {
      'dateKey': dateKey,
      'xpAward': sprint.xpAward,
    });

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final ok = await FirestoreService().completeDailySprint(
        uid: user.uid,
        dateKey: dateKey,
        xpAward: sprint.xpAward,
        segmentId: sprint.segmentId,
      );

      if (!mounted) return;
      setState(() {
        _didAward = ok;
      });

      AnalyticsService.instance.track('daily_sprint_completed', props: {
        'dateKey': dateKey,
        'awarded': ok,
        'xpAward': sprint.xpAward,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '+${sprint.xpAward} XP' : 'Already completed today')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());

      AnalyticsService.instance.track('daily_sprint_complete_failed', props: {
        'error': e.toString(),
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final dateKey = _dateKey(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Daily Sprint'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestoreService().dailySprintDoc(dateKey).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snap.data;
          if (doc == null || doc.exists == false) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No Daily Sprint configured for today ($dateKey).',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final sprint = DailySprint.fromDoc(doc);
          final options = sprint.options;
          final correct = sprint.correctIndex;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                      color: Colors.black.withValues(alpha: 0.06),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1 question • ~2 min',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.black.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      sprint.prompt,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(options.length, (i) {
                      final isSelected = _selected == i;
                      final isCorrect = _submitted && i == correct;
                      final isWrong = _submitted && isSelected && i != correct;
                      final bg = isCorrect
                          ? cs.primary.withValues(alpha: 0.12)
                          : isWrong
                              ? cs.error.withValues(alpha: 0.10)
                              : Colors.white;

                      final enabled = !_submitted;
                      return InkWell(
                        onTap: enabled ? () => setState(() => _selected = i) : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCorrect
                                  ? cs.primary.withValues(alpha: 0.35)
                                  : isWrong
                                      ? cs.error.withValues(alpha: 0.35)
                                      : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: isWrong ? cs.error : cs.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  options[i],
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (_submitted && sprint.explanation.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        sprint.explanation,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black.withValues(alpha: 0.65),
                              height: 1.25,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: cs.error),
                )
              ],
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);

                        if (!_submitted) {
                          if (_selected == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pick an option to continue')),
                            );
                            return;
                          }
                          setState(() => _submitted = true);
                          return;
                        }

                        await _completeSprint();

                        if (!mounted) return;
                        if (_didAward) {
                          // Return a result so Home can trigger celebratory UI.
                          navigator.pop(true);
                        }
                      },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_submitted ? 'Complete Sprint (+${sprint.xpAward} XP)' : 'Submit'),
              ),
            ],
          );
        },
      ),
    );
  }
}
