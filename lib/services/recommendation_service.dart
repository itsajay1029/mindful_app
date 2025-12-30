import '../models/learning_module.dart';
import '../models/learning_path.dart';
import '../models/recommendation.dart';
import '../models/user_enrollment.dart';
import '../models/user_progress.dart';

/// Phase 2: deterministic, rule-based recommendation engine.
///
/// IMPORTANT: No Firestore writes. Calculated at runtime only.
class RecommendationService {
  /// Apply the rules in this exact order:
  ///
  /// Rule 1 — Unfinished Modules
  /// If user is enrolled in a path AND there exists at least one module not completed,
  /// recommend the next incomplete module (lowest `order`).
  ///
  /// Rule 2 — All Modules Completed
  /// If all modules in the current path are completed, recommend the next active path by `order`.
  ///
  /// Rule 3 — No Enrollment
  /// If user has no active enrollment, recommend the first active path by `order`.
  Recommendation? compute({
    required List<UserEnrollment> enrollments,
    required List<LearningPath> paths,
    required Map<String, List<LearningModule>> modulesByPathId,
    required List<UserProgress> completedProgress,
  }) {
    final activePaths = paths.where((p) => p.isActive).toList()..sort((a, b) => a.order.compareTo(b.order));
    if (activePaths.isEmpty) return null;

    final activeEnrollments = enrollments.where((e) => e.status == 'active').toList();

    // Rule 3 — No Enrollment
    if (activeEnrollments.isEmpty) {
      return Recommendation.path(path: activePaths.first, startAction: 'Start');
    }

    // Choose the “current learning path” deterministically.
    // We pick the enrolled path with the lowest path.order among active paths.
    final enrolledPathIds = activeEnrollments.map((e) => e.pathId).toSet();
    final enrolledActivePaths = activePaths.where((p) => enrolledPathIds.contains(p.id)).toList();

    // If enrollment exists but the path is missing/inactive, fallback to Rule 3 behavior.
    if (enrolledActivePaths.isEmpty) {
      return Recommendation.path(path: activePaths.first, startAction: 'Start');
    }

    final currentPath = enrolledActivePaths.first;
    final modules = (modulesByPathId[currentPath.id] ?? <LearningModule>[])..sort((a, b) => a.order.compareTo(b.order));
    final completedModuleIds = completedProgress.where((p) => p.pathId == currentPath.id && p.completed).map((p) => p.moduleId).toSet();

    // Rule 1 — Unfinished Modules
    final nextIncomplete = modules.where((m) => !completedModuleIds.contains(m.id)).toList();
    if (nextIncomplete.isNotEmpty) {
      return Recommendation.module(path: currentPath, recommendedModule: nextIncomplete.first);
    }

    // Rule 2 — All Modules Completed => next path by order
    final idx = activePaths.indexWhere((p) => p.id == currentPath.id);
    final nextPath = (idx >= 0 && idx + 1 < activePaths.length) ? activePaths[idx + 1] : null;
    if (nextPath != null) {
      return Recommendation.path(path: nextPath, startAction: 'Start');
    }

    // No next path available.
    return null;
  }
}
