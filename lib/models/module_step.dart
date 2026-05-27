enum ModuleStepType {
  video,
  quiz,
  reflection,
}

ModuleStepType moduleStepTypeFromString(String raw) {
  final v = raw.trim().toLowerCase();
  return switch (v) {
    'quiz' => ModuleStepType.quiz,
    'reflection' => ModuleStepType.reflection,
    _ => ModuleStepType.video,
  };
}

/// Sprint 2.5 / Sprint 3 foundation: step-based “micro-lesson” unit.
///
/// This is intentionally flexible and stored inside the existing `modules` document
/// as an optional `steps` array so we can evolve gradually without breaking
/// video-only modules.
///
/// Firestore `modules/{moduleId}` optional field:
///
/// steps: [
///   { type: 'video', url: '...', title: '...' },
///   { type: 'quiz', prompt: '...', options: ['a','b'], correctIndex: 1, explanation: '...' },
///   { type: 'reflection', prompt: 'What will you apply today?' }
/// ]
class ModuleStep {
  const ModuleStep({
    required this.type,
    this.title,
    this.url,
    this.prompt,
    this.options,
    this.correctIndex,
    this.explanation,
  });

  final ModuleStepType type;
  final String? title;

  // video
  final String? url;

  // quiz / reflection
  final String? prompt;

  // quiz
  final List<String>? options;
  final int? correctIndex;
  final String? explanation;

  factory ModuleStep.fromMap(Map<String, dynamic> map) {
    final opts = (map['options'] as List?)?.map((e) => e.toString()).toList();
    return ModuleStep(
      type: moduleStepTypeFromString(map['type']?.toString() ?? 'video'),
      title: map['title']?.toString(),
      url: map['url']?.toString(),
      prompt: map['prompt']?.toString(),
      options: opts,
      correctIndex: (map['correctIndex'] as num?)?.toInt(),
      explanation: map['explanation']?.toString(),
    );
  }
}
