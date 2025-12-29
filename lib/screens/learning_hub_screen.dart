import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/learning_path.dart';
import '../models/user_enrollment.dart';
import '../services/firestore_service.dart';
import '../widgets/dashboard/course_card.dart';
import 'course_detail_screen.dart';

/// Learning Hub (Courses List)
///
/// Purpose: “What courses are available?”
///
/// - Shows all courses
/// - Filter/search
/// - Enroll into a course
class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({super.key});

  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen> {
  final _firestore = FirestoreService();
  final _searchController = TextEditingController();

  final Set<String> _enrollingPathIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _enroll({required String uid, required String pathId}) async {
    if (_enrollingPathIds.contains(pathId)) return;

    setState(() => _enrollingPathIds.add(pathId));
    try {
      await _firestore.enrollInPath(uid: uid, pathId: pathId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to enroll. Please try again.\n$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _enrollingPathIds.remove(pathId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user found.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Learning Hub'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore.queryActiveLearningPaths().snapshots(),
        builder: (context, pathsSnap) {
          if (pathsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (pathsSnap.hasError) {
            return Center(child: Text('Failed to load learning paths: ${pathsSnap.error}'));
          }

          final paths = (pathsSnap.data?.docs ?? [])
              .map(LearningPath.fromDoc)
              .where((p) => p.title.trim().isNotEmpty)
              .toList();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.queryUserEnrollments(user.uid).snapshots(),
            builder: (context, enrollSnap) {
              final enrollments = (enrollSnap.data?.docs ?? []).map(UserEnrollment.fromDoc).toList();
              final enrolledPathIds = enrollments.map((e) => e.pathId).toSet();

              final query = _searchController.text.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? paths
                  : paths.where((p) => p.title.toLowerCase().contains(query)).toList();

              return Column(
                children: [
                  // Optional: search inside learning hub (not personalization)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search courses',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No courses found.\n\nAdd documents to `learning_paths` (set `isActive=true`).',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final p = filtered[i];
                              final isEnrolled = enrolledPathIds.contains(p.id);
                              final enrolling = _enrollingPathIds.contains(p.id);

                              return CourseCard(
                                course: p,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CourseDetailScreen(path: p),
                                    ),
                                  );
                                },
                                trailing: isEnrolled
                                    ? FilledButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => CourseDetailScreen(path: p),
                                            ),
                                          );
                                        },
                                        child: const Text('Continue'),
                                      )
                                    : FilledButton.tonal(
                                        onPressed: enrolling
                                            ? null
                                            : () => _enroll(uid: user.uid, pathId: p.id),
                                        child: enrolling
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Text('Enroll'),
                                      ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
