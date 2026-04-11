import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../models/learning_path.dart';
import '../models/user_enrollment.dart';
import '../services/firestore_service.dart';
import '../ui/emerald_orbit/tokens.dart';
import '../widgets/dashboard/rich_course_card.dart';
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
  final _searchFocusNode = FocusNode();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _pathsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _enrollmentsStream;

  Timer? _searchDebounce;
  String _query = '';

  // Simple local categories to match Stitch chips.
  // (We currently only store `category` on LearningPath.)
  static const _categories = <String>['All Courses', 'Mindset', 'Business', 'Design'];
  int _selectedCategoryIndex = 0;

  final Set<String> _enrollingPathIds = <String>{};

  @override
  void initState() {
    super.initState();
    // Cache streams so they don't get recreated on every rebuild/keystroke.
    _pathsStream = _firestore.queryActiveLearningPaths().snapshots();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Debounce to avoid rebuilding the list on every keystroke (more modern feel)
    // while still keeping results responsive.
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _query = value.trim().toLowerCase();
      });
    });
  }

  List<LearningPath> _filterByTitle(List<LearningPath> paths, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return paths;

    // Modern-ish search: split into tokens and require all tokens to match in the title.
    // Example: "time management" matches "Time & Stress Management".
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return paths;

    return paths
        .where((p) {
          final title = p.title.toLowerCase();
          return tokens.every(title.contains);
        })
        .toList();
  }

  List<LearningPath> _filterByCategory(List<LearningPath> paths) {
    final selected = _categories[_selectedCategoryIndex];
    if (selected == 'All Courses') return paths;
    final target = selected.toLowerCase();
    return paths.where((p) => p.category.trim().toLowerCase() == target).toList();
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

    // Create/caches enrollment stream once per user session.
    _enrollmentsStream ??= _firestore.queryUserEnrollments(user.uid).snapshots();

    return Scaffold(
      backgroundColor: EoColors.background,
      appBar: AppBar(
        title: const Text('Learning Hub'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _pathsStream,
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
            stream: _enrollmentsStream,
            builder: (context, enrollSnap) {
              final enrollments = (enrollSnap.data?.docs ?? []).map(UserEnrollment.fromDoc).toList();
              final enrolledPathIds = enrollments.map((e) => e.pathId).toSet();

              final filtered = _filterByTitle(_filterByCategory(paths), _query);

              return Column(
                children: [
                  // Search (Stitch-inspired)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: _onSearchChanged,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search for courses, skills...',
                              prefixIcon: Icon(Icons.search_rounded, color: EoColors.onSurfaceVariant),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _query = '';
                                        });
                                        _searchFocusNode.requestFocus();
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                              filled: true,
                              fillColor: EoColors.surfaceContainerLowest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(color: Colors.transparent),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(color: Colors.transparent),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: IconButton(
                            onPressed: () {
                              // Placeholder for filters UI.
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Filters coming soon')),
                              );
                            },
                            icon: Icon(Icons.tune_rounded, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Category chips
                  SizedBox(
                    height: 54,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final selected = i == _selectedCategoryIndex;
                        final label = _categories[i];
                        final bg = selected ? Theme.of(context).colorScheme.primary : EoColors.surfaceContainerLowest;
                        final fg = selected ? Theme.of(context).colorScheme.onPrimary : EoColors.onSurfaceVariant;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategoryIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        blurRadius: 18,
                                        offset: const Offset(0, 10),
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: fg,
                                    ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _query.isEmpty
                                    ? 'No courses available yet.\n\nAdd documents to `learning_paths` (set `isActive=true`).'
                                    : 'No results for "${_searchController.text.trim()}"',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final p = filtered[i];
                              final isEnrolled = enrolledPathIds.contains(p.id);
                              final enrolling = _enrollingPathIds.contains(p.id);

                              // Without a progress model in Firestore, show a mock progress for enrolled.
                              final progress = isEnrolled ? 0.65 : null;

                              return RichCourseCard(
                                course: p,
                                progress01: progress,
                                isNew: !isEnrolled && i == 2,
                                primaryActionLabel: isEnrolled ? 'Continue' : (enrolling ? 'Enrolling...' : 'Enroll'),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CourseDetailScreen(path: p),
                                    ),
                                  );
                                },
                                onPrimaryAction: enrolling
                                    ? () {}
                                    : () {
                                        if (isEnrolled) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => CourseDetailScreen(path: p),
                                            ),
                                          );
                                          return;
                                        }
                                        _enroll(uid: user.uid, pathId: p.id);
                                      },
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
