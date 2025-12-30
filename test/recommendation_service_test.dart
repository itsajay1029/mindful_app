import 'package:flutter_test/flutter_test.dart';

import 'package:mindful_app/models/learning_module.dart';
import 'package:mindful_app/models/learning_path.dart';
import 'package:mindful_app/models/user_enrollment.dart';
import 'package:mindful_app/models/user_progress.dart';
import 'package:mindful_app/services/recommendation_service.dart';

// NOTE: These are pure-rule tests (no Firestore).

void main() {
  final svc = RecommendationService();

  LearningPath path({required String id, required int order}) => LearningPath(
        id: id,
        title: 'Path $id',
        description: '',
        category: 'all',
        totalDurationHours: 1,
        isActive: true,
        order: order,
      );

  LearningModule module({required String id, required String pathId, required int order}) => LearningModule(
        id: id,
        pathId: pathId,
        title: 'Module $id',
        description: '',
        contentType: 'video',
        contentUrl: 'https://example.com/video.mp4',
        durationMinutes: 5,
        xp: 10,
        order: order,
        isActive: true,
      );

  UserEnrollment enrollment({required String pathId}) => UserEnrollment(
        id: 'e_$pathId',
        userId: 'u1',
        pathId: pathId,
        status: 'active',
        enrolledAt: null,
      );

  UserProgress progress({required String pathId, required String moduleId}) => UserProgress(
        id: 'p_${pathId}_$moduleId',
        userId: 'u1',
        pathId: pathId,
        moduleId: moduleId,
        completed: true,
        reflection: null,
        completedAt: null,
      );

  test('Scenario 1 — unfinished module => recommends next incomplete module (lowest order)', () {
    final paths = [path(id: 'p1', order: 1)];
    final enrollments = [enrollment(pathId: 'p1')];
    final modulesByPathId = {
      'p1': [
        module(id: 'm1', pathId: 'p1', order: 1),
        module(id: 'm2', pathId: 'p1', order: 2),
      ]
    };
    final completed = [progress(pathId: 'p1', moduleId: 'm1')];

    final reco = svc.compute(
      enrollments: enrollments,
      paths: paths,
      modulesByPathId: modulesByPathId,
      completedProgress: completed,
    );

    expect(reco, isNotNull);
    expect(reco!.module, isNotNull);
    expect(reco.module!.id, 'm2');
  });

  test('Scenario 2 — all modules completed => recommends next path by order', () {
    final paths = [path(id: 'p1', order: 1), path(id: 'p2', order: 2)];
    final enrollments = [enrollment(pathId: 'p1')];
    final modulesByPathId = {
      'p1': [
        module(id: 'm1', pathId: 'p1', order: 1),
        module(id: 'm2', pathId: 'p1', order: 2),
      ]
    };
    final completed = [
      progress(pathId: 'p1', moduleId: 'm1'),
      progress(pathId: 'p1', moduleId: 'm2'),
    ];

    final reco = svc.compute(
      enrollments: enrollments,
      paths: paths,
      modulesByPathId: modulesByPathId,
      completedProgress: completed,
    );

    expect(reco, isNotNull);
    expect(reco!.module, isNull);
    expect(reco.path.id, 'p2');
  });

  test('Scenario 3 — no enrollment => recommends first active path by order', () {
    final paths = [path(id: 'p1', order: 1), path(id: 'p2', order: 2)];
    final enrollments = <UserEnrollment>[];
    final modulesByPathId = <String, List<LearningModule>>{};
    final completed = <UserProgress>[];

    final reco = svc.compute(
      enrollments: enrollments,
      paths: paths,
      modulesByPathId: modulesByPathId,
      completedProgress: completed,
    );

    expect(reco, isNotNull);
    expect(reco!.module, isNull);
    expect(reco.path.id, 'p1');
  });
}
