import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/learning_module.dart';
import '../models/learning_path.dart';
import '../models/user_progress.dart';
import '../services/firestore_service.dart';
import 'module_player_screen.dart';

/// Course Detail (Path Detail)
///
/// Purpose: “What’s inside this course?”
///
/// - Course overview
/// - Module list
/// - Progress
class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key, required this.path});

  final LearningPath path;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: Text(path.title)),
      body: user == null
          ? const Center(child: Text('No user found.'))
          : StreamBuilder(
              stream: FirestoreService().queryModulesForPath(path.id).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> modulesSnap) {
                if (modulesSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (modulesSnap.hasError) {
                  return Center(child: Text('Failed to load modules: ${modulesSnap.error}'));
                }

                final modules = (modulesSnap.data?.docs ?? [])
                    .map(LearningModule.fromDoc)
                    .where((m) => m.title.trim().isNotEmpty)
                    .toList();

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirestoreService().queryUserProgressForPath(uid: user.uid, pathId: path.id).snapshots(),
                  builder: (context, progressSnap) {
                    final progressDocs = (progressSnap.data?.docs ?? [])
                        .map(UserProgress.fromDoc)
                        .where((p) => p.completed)
                        .toList();
                    final completedModuleIds = progressDocs.map((p) => p.moduleId).toSet();

                    final completedCount = modules.where((m) => completedModuleIds.contains(m.id)).length;
                    final total = modules.length;
                    final pct = total == 0 ? 0.0 : (completedCount / total);

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        // Overview card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                path.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                path.description.trim().isEmpty ? 'A focused learning path.' : path.description,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.black.withValues(alpha: 0.65),
                                    ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _Chip(label: _prettyCategory(path.category)),
                                  const SizedBox(width: 10),
                                  _Chip(label: path.durationLabel),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progress',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  Text(
                                    '$completedCount / $total',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 10,
                                  backgroundColor: Colors.black.withValues(alpha: 0.06),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text(
                          'Modules',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 12),

                        if (modules.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'No modules found for this path.\n\nAdd documents to `modules` with `pathId` set to this learning path id.',
                              textAlign: TextAlign.center,
                            ),
                          ),

                        ...modules.map((m) {
                          final done = completedModuleIds.contains(m.id);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: done
                                        ? cs.primary.withValues(alpha: 0.15)
                                        : Colors.black.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    done ? Icons.check_circle_rounded : Icons.play_circle_fill_rounded,
                                    color: done ? cs.primary : Colors.black.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.title,
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${m.durationMinutes} min',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.black.withValues(alpha: 0.6),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FilledButton.tonal(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ModulePlayerScreen(
                                          path: path,
                                          module: m,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(done ? 'Replay' : 'Start'),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.7),
            ),
      ),
    );
  }
}

String _prettyCategory(String raw) {
  final v = raw.trim().toLowerCase();
  return switch (v) {
    'leadership' => 'Leadership',
    'wellbeing' => 'Well‑being',
    'sustainability' => 'Sustainability',
    'all' => 'All',
    _ => v.isEmpty ? 'All' : '${v[0].toUpperCase()}${v.substring(1)}',
  };
}
