import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'app_shell.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

/// Production-grade start gate:
///
/// 1) Is user logged in?
///   - NO  -> Login
///   - YES -> ensure Firestore user doc exists
///            then check onboardingCompleted
///              - false -> Onboarding
///              - true  -> Dashboard
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return _EnsureUserDocAndRoute(user: user);
      },
    );
  }
}

class _EnsureUserDocAndRoute extends StatefulWidget {
  const _EnsureUserDocAndRoute({required this.user});

  final User user;

  @override
  State<_EnsureUserDocAndRoute> createState() => _EnsureUserDocAndRouteState();
}

class _EnsureUserDocAndRouteState extends State<_EnsureUserDocAndRoute> {
  late Future<void> _ensureFuture;

  String _friendlyError(Object error) {
    // Cloud Firestore errors come through as FirebaseException (plugin: cloud_firestore)
    if (error is FirebaseException && error.plugin == 'cloud_firestore') {
      if (error.code == 'permission-denied') {
        return 'Firestore permission denied. This usually means your Firestore Security Rules do not allow the signed-in user to read/write their profile document.';
      }
      return 'Firestore error (${error.code}): ${error.message ?? error.toString()}';
    }

    final msg = error.toString();
    if (msg.contains('permission-denied')) {
      return 'Firestore permission denied. Please verify your Firestore Security Rules.';
    }
    return msg;
  }

  @override
  void initState() {
    super.initState();
    _ensureFuture = FirestoreService().ensureUserDoc(widget.user);
  }

  @override
  void didUpdateWidget(covariant _EnsureUserDocAndRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _ensureFuture = FirestoreService().ensureUserDoc(widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ensureFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to initialize user profile.\n\n${_friendlyError(snap.error!)}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return StreamBuilder(
          stream: FirestoreService().streamUserDoc(widget.user.uid),
          builder: (context, AsyncSnapshot userDocSnap) {
            if (userDocSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (userDocSnap.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to load profile.\n\n${_friendlyError(userDocSnap.error!)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final data = (userDocSnap.data?.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
            final onboardingCompleted = data['onboardingCompleted'] == true;

            return onboardingCompleted ? const AppShell() : const OnboardingScreen();
          },
        );
      },
    );
  }
}
