import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/learning_path.dart';
import '../models/user_enrollment.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/dashboard/course_card.dart';
import '../widgets/dashboard/kpi_card.dart';
import '../widgets/dashboard/section_header.dart';
import 'auth_gate.dart';
import 'course_detail_screen.dart';
import 'learning_hub_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();

  final _firestore = FirestoreService();

  bool _busy = false;

  Future<void> _signOut() async {
    setState(() {
      _busy = true;
    });

    try {
      await _authService.signOut();

      if (!mounted) return;
      // Return to AuthGate so it routes to Login when signed out.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('No user found.'))
            : StreamBuilder(
                stream: _firestore.streamUserDoc(user.uid),
                builder: (context, AsyncSnapshot userDocSnap) {
                  if (userDocSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = (userDocSnap.data?.data() as Map<String, dynamic>?) ??
                      <String, dynamic>{};

                  final displayName = (data['displayName'] as String?)?.trim().isNotEmpty == true
                      ? (data['displayName'] as String).trim()
                      : ((data['firstName'] as String?)?.trim().isNotEmpty == true
                          ? (data['firstName'] as String).trim()
                          : '');

                  final interestsRaw = (data['interests'] as List?)?.cast<String>() ?? <String>[];
                  final interests = interestsRaw
                      .map((e) => e.trim().toLowerCase())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  final xp = (data['xp'] as num?)?.toInt() ?? 0;
                  final showGreetingName = displayName.isNotEmpty;

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firestore.queryUserEnrollments(user.uid).snapshots(),
                    builder: (context, enrollSnap) {
                      final enrollments = (enrollSnap.data?.docs ?? []).map(UserEnrollment.fromDoc).toList();
                      final enrolledCount = enrollments.length;
                      final enrolledPathIds = enrollments.map((e) => e.pathId).toSet();

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _firestore.queryActiveLearningPaths().snapshots(),
                        builder: (context, pathsSnap) {
                          if (pathsSnap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (pathsSnap.hasError) {
                            return Center(child: Text('Failed to load courses: ${pathsSnap.error}'));
                          }

                          final paths = (pathsSnap.data?.docs ?? [])
                              .map(LearningPath.fromDoc)
                              .where((p) => p.title.trim().isNotEmpty)
                              .toList();

                          // Dashboard preview sets
                          final featured = paths.take(3).toList();
                          final myCourses = paths.where((p) => enrolledPathIds.contains(p.id)).take(3).toList();

                          return CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: _DashboardHeader(
                                  name: showGreetingName ? displayName : null,
                                  subtitle: interests.isNotEmpty
                                      ? 'Your focus: ${_prettyInterest(interests.first)}'
                                      : 'Pick a course to start learning',
                                  onOpenLearningHub: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const LearningHubScreen()),
                                    );
                                  },
                                  busy: _busy,
                                  onSignOut: _signOut,
                                ),
                              ),

                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      KpiCard(
                                        title: 'XP',
                                        value: xp.toString(),
                                        icon: Icons.auto_awesome,
                                        onTap: () {},
                                      ),
                                      const SizedBox(width: 12),
                                      KpiCard(
                                        title: 'Enrolled',
                                        value: enrolledCount.toString(),
                                        icon: Icons.school_rounded,
                                        onTap: () {},
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SliverToBoxAdapter(child: SizedBox(height: 18)),

                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                sliver: SliverToBoxAdapter(
                                  child: SectionHeader(
                                    title: 'Featured',
                                    onSeeAll: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const LearningHubScreen()),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                sliver: featured.isEmpty
                                    ? const SliverToBoxAdapter(
                                        child: _EmptyStateCard(
                                          title: 'No courses available',
                                          subtitle: 'Add documents to `learning_paths` in Firestore.',
                                        ),
                                      )
                                    : SliverList.separated(
                                        itemCount: featured.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                                        itemBuilder: (context, i) {
                                          final p = featured[i];
                                          return CourseCard(
                                            course: p,
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => CourseDetailScreen(path: p),
                                                ),
                                              );
                                            },
                                            trailing: FilledButton.tonal(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => CourseDetailScreen(path: p),
                                                  ),
                                                );
                                              },
                                              child: const Text('View'),
                                            ),
                                          );
                                        },
                                      ),
                              ),

                              const SliverToBoxAdapter(child: SizedBox(height: 18)),

                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                sliver: SliverToBoxAdapter(
                                  child: SectionHeader(
                                    title: 'My Courses',
                                    onSeeAll: enrolledCount == 0
                                        ? null
                                        : () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(builder: (_) => const LearningHubScreen()),
                                            );
                                          },
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                sliver: myCourses.isEmpty
                                    ? const SliverToBoxAdapter(
                                        child: _EmptyStateCard(
                                          title: 'No enrollments yet',
                                          subtitle: 'Open the Learning Hub to enroll in a course.',
                                        ),
                                      )
                                    : SliverList.separated(
                                        itemCount: myCourses.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                                        itemBuilder: (context, i) {
                                          final p = myCourses[i];
                                          return CourseCard(
                                            course: p,
                                            compact: true,
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => CourseDetailScreen(path: p),
                                                ),
                                              );
                                            },
                                            trailing: const _EnrolledBadge(),
                                          );
                                        },
                                      ),
                              ),

                              const SliverToBoxAdapter(child: SizedBox(height: 18)),

                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                sliver: SliverToBoxAdapter(
                                  child: FilledButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const LearningHubScreen()),
                                      );
                                    },
                                    child: const Text('Browse all courses'),
                                  ),
                                ),
                              ),

                              const SliverToBoxAdapter(child: SizedBox(height: 24)),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.name,
    required this.subtitle,
    required this.busy,
    required this.onSignOut,
    required this.onOpenLearningHub,
  });

  final String? name;
  final String subtitle;
  final bool busy;
  final VoidCallback onSignOut;
  final VoidCallback onOpenLearningHub;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.95),
            cs.secondary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 26,
            offset: const Offset(0, 16),
            color: cs.primary.withValues(alpha: 0.22),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name == null || name!.isEmpty ? 'Hi' : 'Hi, ${name!}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.90),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: busy ? null : onSignOut,
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: 'Sign out',
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Search is a launcher action: opens Learning Hub
          InkWell(
            onTap: onOpenLearningHub,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search courses',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: cs.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: onOpenLearningHub,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: cs.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('All Courses'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black.withValues(alpha: 0.6),
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

class _EnrolledBadge extends StatelessWidget {
  const _EnrolledBadge();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Enrolled',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

String _prettyInterest(String raw) {
  final v = raw.trim().toLowerCase();
  return switch (v) {
    'leadership' => 'Leadership',
    'wellbeing' => 'Well‑being',
    'sustainability' => 'Sustainability',
    _ => v.isEmpty ? 'your interests' : '${v[0].toUpperCase()}${v.substring(1)}',
  };
}
