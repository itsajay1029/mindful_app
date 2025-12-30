import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/learning_path.dart';
import '../models/learning_module.dart';
import '../models/recommendation.dart';
import '../models/user_enrollment.dart';
import '../models/user_progress.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_notification_service.dart';
import '../services/recommendation_service.dart';
import '../widgets/dashboard/course_card.dart';
import '../widgets/dashboard/kpi_card.dart';
import '../widgets/dashboard/section_header.dart';
import 'auth_gate.dart';
import 'course_detail_screen.dart';
import 'learning_hub_screen.dart';
import 'module_player_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();

  final _firestore = FirestoreService();
  final _reco = RecommendationService();

  bool _busy = false;
  bool _scheduledReminder = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Schedule once per app session (Phase 2). Uses same notification ID so it won't duplicate.
    if (!_scheduledReminder) {
      _scheduledReminder = true;
      LocalNotificationService.instance.scheduleDailyReminder();
    }
  }

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

                  // Show only first name on Dashboard greeting.
                  // Priority: firstName (from signup / parsed google name) -> displayName (first token) -> ''
                  final firstName = (data['firstName'] as String?)?.trim() ?? '';
                  final displayNameRaw = (data['displayName'] as String?)?.trim() ?? '';
                  final displayFirstToken = displayNameRaw.isEmpty
                      ? ''
                      : displayNameRaw.split(RegExp(r'\s+')).first.trim();
                  final greetingName = firstName.isNotEmpty ? firstName : displayFirstToken;

                  final interestsRaw = (data['interests'] as List?)?.cast<String>() ?? <String>[];
                  final interests = interestsRaw
                      .map((e) => e.trim().toLowerCase())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  final xp = (data['xp'] as num?)?.toInt() ?? 0;
                  final showGreetingName = greetingName.isNotEmpty;

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

                          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _firestore.queryCompletedUserProgress(user.uid).snapshots(),
                            builder: (context, progressSnap) {
                              final completed = (progressSnap.data?.docs ?? [])
                                  .map(UserProgress.fromDoc)
                                  .where((p) => p.completed)
                                  .toList();

                              return CustomScrollView(
                                controller: _scrollController,
                                slivers: [
                              SliverToBoxAdapter(
                                child: _DashboardHeader(
                                  // only first name
                                  name: showGreetingName ? greetingName : null,
                                  interests: interests.map(_prettyInterest).toList(),
                                  subtitle: interests.isNotEmpty ? null : 'Pick a course to start learning',
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

                              // ===== Recommendation (Phase 2) =====
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                sliver: SliverToBoxAdapter(
                                  child: SectionHeader(
                                    title: 'Recommended for you',
                                    onSeeAll: null,
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                sliver: SliverToBoxAdapter(
                                  child: _RecommendationCard(
                                    userId: user.uid,
                                    enrollments: enrollments,
                                    paths: paths,
                                    completedProgress: completed,
                                    firestore: _firestore,
                                    recompute: _reco,
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
                                  child: Text(enrolledPathIds.contains(p.id) ? 'Continue' : 'View'),
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
                  );
                },
              ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.userId,
    required this.enrollments,
    required this.paths,
    required this.completedProgress,
    required this.firestore,
    required this.recompute,
  });

  final String userId;
  final List<UserEnrollment> enrollments;
  final List<LearningPath> paths;
  final List<UserProgress> completedProgress;
  final FirestoreService firestore;
  final RecommendationService recompute;

  @override
  Widget build(BuildContext context) {
    // We need modules to apply Rule 1. Fetch modules for enrolled paths only.
    final enrolledPathIds = enrollments.where((e) => e.status == 'active').map((e) => e.pathId).toSet();
    final activePaths = paths.where((p) => p.isActive).toList()..sort((a, b) => a.order.compareTo(b.order));
    final relevantPathIds = enrolledPathIds.isEmpty ? {if (activePaths.isNotEmpty) activePaths.first.id} : enrolledPathIds;

    // Ensure deterministic iteration order.
    final relevantPathIdsList = activePaths
        .where((p) => relevantPathIds.contains(p.id))
        .map((p) => p.id)
        .toList();

    return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      stream: Stream.fromFuture(
        Future.wait(
          relevantPathIdsList.map((pid) => firestore.queryModulesForPath(pid).get()),
        ),
      ),
      builder: (context, modulesSnap) {
        final modulesByPathId = <String, List<LearningModule>>{};

        if (modulesSnap.connectionState == ConnectionState.waiting) {
          return const _EmptyStateCard(
            title: 'Loading recommendation…',
            subtitle: 'Preparing your next best action.',
          );
        }

        if (modulesSnap.hasError) {
          return _EmptyStateCard(
            title: 'Failed to load recommendation',
            subtitle: modulesSnap.error.toString(),
          );
        }

        if (modulesSnap.hasData) {
          final results = modulesSnap.data!;
          int idx = 0;
          for (final pid in relevantPathIdsList) {
            final docs = results[idx].docs;
            modulesByPathId[pid] = docs.map(LearningModule.fromDoc).toList();
            idx++;
          }
        }

        final reco = recompute.compute(
          enrollments: enrollments,
          paths: paths,
          modulesByPathId: modulesByPathId,
          completedProgress: completedProgress,
        );

        if (reco == null) {
          return const _EmptyStateCard(
            title: 'No recommendation yet',
            subtitle: 'Add learning paths and modules in Firestore to get started.',
          );
        }

        return InkWell(
          onTap: () {
            if (reco.type == RecommendationType.module && reco.module != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ModulePlayerScreen(path: reco.path, module: reco.module!),
                ),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CourseDetailScreen(path: reco.path),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    reco.type == RecommendationType.module
                        ? Icons.play_circle_fill_rounded
                        : Icons.school_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reco.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reco.path.title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.black.withValues(alpha: 0.35)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.name,
    required this.interests,
    this.subtitle,
    required this.busy,
    required this.onSignOut,
    required this.onOpenLearningHub,
  });

  final String? name;
  final List<String> interests;
  final String? subtitle;
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
                    const SizedBox(height: 6),
                    if (interests.isNotEmpty) ...[
                      Text(
                        'Your interests',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: interests
                            .where((e) => e.trim().isNotEmpty)
                            .map(
                              (i) => _HeaderChip(label: i),
                            )
                            .toList(),
                      ),
                    ] else if (subtitle != null) ...[
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.90),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              IgnorePointer(
                ignoring: busy,
                child: PopupMenuButton<String>(
                  tooltip: 'Menu',
                  onSelected: (value) {
                    if (value == 'signout') onSignOut();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'signout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, color: cs.primary),
                          const SizedBox(width: 10),
                          const Text('Sign out'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
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

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w700,
            ),
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
