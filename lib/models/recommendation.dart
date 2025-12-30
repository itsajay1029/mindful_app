import 'learning_module.dart';
import 'learning_path.dart';

enum RecommendationType {
  module,
  path,
}

class Recommendation {
  Recommendation.module({
    required this.path,
    required LearningModule recommendedModule,
  })  : type = RecommendationType.module,
        module = recommendedModule,
        action = null,
        label = 'Continue: ${recommendedModule.title}';

  Recommendation.path({
    required this.path,
    required String startAction,
  })  : type = RecommendationType.path,
        module = null,
        action = startAction,
        label = '$startAction: ${path.title}';

  final RecommendationType type;

  /// e.g. "Continue: Mindful Breathing Practice" or "Start: Mindful Leadership"
  final String label;

  /// Action for path-type recommendations (e.g. "Start")
  final String? action;

  final LearningPath path;
  final LearningModule? module;
}
