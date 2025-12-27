import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'auth_gate.dart';

enum UserRole { individual, manager }

enum Interest { leadership, wellbeing, sustainability }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _logoPath = 'assets/branding/logo.png';

  int _step = 0;

  UserRole? _role;
  final Set<Interest> _interests = <Interest>{};
  int? _minutesPerDay;

  bool _busy = false;
  String? _error;

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _role != null;
      case 1:
        return _interests.isNotEmpty;
      case 2:
        return _minutesPerDay != null;
      default:
        return false;
    }
  }

  String _interestLabel(Interest i) {
    return switch (i) {
      Interest.leadership => 'Leadership',
      Interest.wellbeing => 'Well-being',
      Interest.sustainability => 'Sustainability',
    };
  }

  String _roleLabel(UserRole r) {
    return switch (r) {
      UserRole.individual => 'Individual',
      UserRole.manager => 'Manager',
    };
  }

  String _headerText() {
    return switch (_step) {
      0 => 'Who are you?',
      1 => 'What do you want?',
      2 => 'How much time do you have?',
      _ => 'Onboarding',
    };
  }

  Future<void> _finish() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      final role = _role;
      final minutesPerDay = _minutesPerDay;
      if (role == null || minutesPerDay == null || _interests.isEmpty) {
        throw Exception('Please complete onboarding.');
      }

      await FirestoreService().setOnboardingData(
        uid: user.uid,
        role: _roleLabel(role).toLowerCase(),
        interests: _interests.map(_interestLabel).map((e) => e.toLowerCase()).toList(),
        minutesPerDay: minutesPerDay,
      );

      if (!mounted) return;
      // Return to AuthGate so it routes based on onboardingCompleted.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _next() {
    if (_step < 2) {
      setState(() {
        _step += 1;
      });
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() {
        _step -= 1;
      });
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Individual'),
              selected: _role == UserRole.individual,
              onSelected: _busy ? null : (v) => setState(() => _role = v ? UserRole.individual : _role),
            ),
            ChoiceChip(
              label: const Text('Manager'),
              selected: _role == UserRole.manager,
              onSelected: _busy ? null : (v) => setState(() => _role = v ? UserRole.manager : _role),
            ),
          ],
        );
      case 1:
        return Column(
          children: Interest.values.map((interest) {
            final selected = _interests.contains(interest);
            return CheckboxListTile(
              title: Text(_interestLabel(interest)),
              value: selected,
              onChanged: _busy
                  ? null
                  : (v) {
                      setState(() {
                        if (v == true) {
                          _interests.add(interest);
                        } else {
                          _interests.remove(interest);
                        }
                      });
                    },
            );
          }).toList(),
        );
      case 2:
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('5 min/day'),
              selected: _minutesPerDay == 5,
              onSelected: _busy ? null : (v) => setState(() => _minutesPerDay = v ? 5 : _minutesPerDay),
            ),
            ChoiceChip(
              label: const Text('10 min/day'),
              selected: _minutesPerDay == 10,
              onSelected: _busy ? null : (v) => setState(() => _minutesPerDay = v ? 10 : _minutesPerDay),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AboveTheGrind'),
        leading: _step == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _busy ? null : _back,
              ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                _logoPath,
                height: 84,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image, size: 56);
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _headerText(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Step ${_step + 1} of 3',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: _buildStep(),
              ),
            ),
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: (_busy || !_canContinue) ? null : _next,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_step < 2 ? 'Continue' : 'Finish'),
            ),
          ],
        ),
      ),
    );
  }
}
