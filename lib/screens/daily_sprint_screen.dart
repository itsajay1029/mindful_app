// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  static const int _xpAward = 20;

  int? _selected;
  bool _submitted = false;
  bool _busy = false;
  String? _error;
  bool _didAward = false;

  // Hardcoded sample question for MVP.
  // Later: load from Firestore `daily_sprints/{dateKey}` → `activities`.
  final String _prompt = 'A teammate strongly disagrees with your approach. What’s the best first step?';
  final List<String> _options = const [
    'Push your solution harder with more evidence',
    'Ask them to explain their concerns and listen',
    'Escalate to your manager immediately',
    'Ignore it and continue',
  ];
  final int _correct = 1;
  final String _explanation = 'Active listening reduces defensiveness and helps you find the real issue quickly.';

  String _dateKey(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

  Future<void> _completeSprint() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final ok = await FirestoreService().completeDailySprint(
        uid: user.uid,
        dateKey: _dateKey(DateTime.now()),
        xpAward: _xpAward,
        segmentId: 'communication',
      );

      if (!mounted) return;
      setState(() {
        _didAward = ok;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '+$_xpAward XP' : 'Already completed today')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Daily Sprint'),
      ),
      body: ListView(
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
                  _prompt,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_options.length, (i) {
                  final isSelected = _selected == i;
                  final isCorrect = _submitted && i == _correct;
                  final isWrong = _submitted && isSelected && i != _correct;
                  final bg = isCorrect
                      ? cs.primary.withValues(alpha: 0.12)
                      : isWrong
                          ? cs.error.withValues(alpha: 0.10)
                          : Colors.white;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
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
                    child: RadioListTile<int>(
                      value: i,
                      groupValue: _selected,
                      onChanged: _submitted ? null : (v) => setState(() => _selected = v),
                      title: Text(
                        _options[i],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      activeColor: cs.primary,
                    ),
                  );
                }),
                if (_submitted) ...[
                  const SizedBox(height: 6),
                  Text(
                    _explanation,
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
                : Text(_submitted ? 'Complete Sprint (+$_xpAward XP)' : 'Submit'),
          ),
        ],
      ),
    );
  }
}
