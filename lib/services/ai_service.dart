/// Phase 1 placeholder AI service.
///
/// NOTE: This is NOT real AI. No API calls, no async.
class AiService {
  /// Returns a learning path name based on a single interest string.
  String recommendLearningPath(String interest) {
    final normalized = interest.trim().toLowerCase();

    if (normalized == 'leadership') {
      return 'Mindful Leadership Path';
    }

    if (normalized == 'sustainability') {
      return 'Sustainable Living Path';
    }

    return 'Daily Well-being Path';
  }
}
