import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/learning_module.dart';
import '../models/learning_path.dart';
import '../models/module_step.dart';
import '../models/user_enrollment.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../widgets/video/modern_video_player.dart';

/// Module Player
///
/// Purpose: “Consume the lesson”
///
/// - In future: plays video/audio
/// - For now: shows module content placeholder
/// - Allows completion
/// - Updates progress + XP
class ModulePlayerScreen extends StatefulWidget {
  const ModulePlayerScreen({
    super.key,
    required this.path,
    required this.module,
  });

  final LearningPath path;
  final LearningModule module;

  @override
  State<ModulePlayerScreen> createState() => _ModulePlayerScreenState();
}

class _ModulePlayerScreenState extends State<ModulePlayerScreen> {
  VideoPlayerController? _videoController;

  /// Used for the legacy single-reflection UX AND as the final reflection text
  /// when step-based modules include a reflection step.
  final _reflectionController = TextEditingController();

  // ===== Step-based module state =====
  int _stepIndex = 0;
  int? _quizSelected;
  bool _quizSubmitted = false;
  final _stepScroll = ScrollController();

  bool _busy = false;
  bool _completed = false;
  bool _loadingCompletion = true;
  bool _checkingEnrollment = true;
  bool _isEnrolled = false;
  String? _videoError;

  List<ModuleStep> get _steps => widget.module.steps ?? const <ModuleStep>[];
  bool get _isStepBased => widget.module.steps != null && widget.module.steps!.isNotEmpty;

  @override
  void initState() {
    super.initState();

    // Legacy (single video): initialize immediately.
    // Step-based: initialize only when current step is a video.
    if (!_isStepBased) {
      _setVideoUrl(widget.module.contentUrl);
    } else {
      _initCurrentStep();
    }

    _loadCompletion();
    _loadEnrollment();

    AnalyticsService.instance.track('module_opened', props: {
      'pathId': widget.path.id,
      'moduleId': widget.module.id,
      'contentType': widget.module.contentType,
    });
  }

  Future<void> _loadEnrollment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _checkingEnrollment = false);
      return;
    }

    try {
      final snap = await FirestoreService().queryUserEnrollments(user.uid).get();
      final enrollments = snap.docs.map(UserEnrollment.fromDoc).toList();
      final enrolled = enrollments.any((e) => e.status == 'active' && e.pathId == widget.path.id);
      if (!mounted) return;
      setState(() {
        _isEnrolled = enrolled;
        _checkingEnrollment = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checkingEnrollment = false);
    }
  }

  Future<void> _loadCompletion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loadingCompletion = false);
      return;
    }

    try {
      final doc = await FirestoreService().userProgressDoc(
        uid: user.uid,
        pathId: widget.path.id,
        moduleId: widget.module.id,
      ).get();

      final data = doc.data();
      final isCompleted = (data?['completed'] == true);
      final reflection = (data?['reflection'] as String?)?.trim();

      if (!mounted) return;
      setState(() {
        _completed = isCompleted;
        _loadingCompletion = false;
      });

      if (isCompleted && (reflection ?? '').isNotEmpty) {
        _reflectionController.text = reflection!;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCompletion = false);
    }
  }

  Future<void> _initVideo() async {
    final controller = _videoController;
    if (controller == null) return;
    try {
      await controller.initialize();

      // Always start from the beginning for a predictable course experience.
      await controller.seekTo(Duration.zero);

      // Autoplay on open (modern app behavior). If you want manual start,
      // remove this line.
      await controller.play();

      if (!mounted) return;
      setState(() {
        _videoError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _videoError = e.toString();
      });
    }
  }

  void _setVideoUrl(String url) {
    // Empty URLs are common when content isn't configured yet.
    if (url.trim().isEmpty) {
      setState(() {
        _videoController = null;
        _videoError = 'No video URL configured.';
      });
      return;
    }

    // Dispose previous controller (if any)
    _videoController?.pause();
    _videoController?.dispose();

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoError = null;
    _initVideo();
  }

  void _initCurrentStep() {
    if (!_isStepBased) return;
    if (_stepIndex < 0 || _stepIndex >= _steps.length) return;

    final step = _steps[_stepIndex];
    // reset per-step state
    _quizSelected = null;
    _quizSubmitted = false;

    if (step.type == ModuleStepType.video) {
      _setVideoUrl(step.url ?? '');
    } else {
      // not a video step
      _videoController?.pause();
    }
  }

  @override
  void dispose() {
    // Prevent background playback when leaving the screen.
    // (If you ever want background playback, remove this.)
    _videoController?.pause();
    _videoController?.dispose();
    _reflectionController.dispose();
    _stepScroll.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_isStepBased) return;
    if (_stepIndex >= _steps.length - 1) return;
    setState(() {
      _stepIndex += 1;
    });
    _initCurrentStep();
    if (_stepScroll.hasClients) {
      _stepScroll.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  void _prevStep() {
    if (!_isStepBased) return;
    if (_stepIndex <= 0) return;
    setState(() {
      _stepIndex -= 1;
    });
    _initCurrentStep();
    if (_stepScroll.hasClients) {
      _stepScroll.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  Widget _buildStepBasedBody(BuildContext context) {
    final step = _steps[_stepIndex];
    final cs = Theme.of(context).colorScheme;

    Widget header() {
      return Row(
        children: [
          Text(
            'Step ${_stepIndex + 1} of ${_steps.length}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withValues(alpha: 0.65),
                ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${widget.module.xp} XP',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.tertiary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
            ),
          ),
        ],
      );
    }

    Widget content() {
      switch (step.type) {
        case ModuleStepType.video:
          final controller = _videoController;
          return SizedBox(
            height: 240,
            child: _videoError != null
                ? Center(child: Text('Unable to play.\n$_videoError', textAlign: TextAlign.center))
                : ModernVideoPlayer(
                    controller: controller!,
                    borderRadius: 18,
                    allowFullscreen: true,
                    showSkipButtons: true,
                  ),
          );

        case ModuleStepType.quiz:
          final prompt = (step.prompt ?? '').trim().isEmpty
              ? 'Choose the best answer.'
              : step.prompt!.trim();
          final options = step.options ?? const <String>[];
          final correct = step.correctIndex;
          final explanation = step.explanation;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                prompt,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              ...List.generate(options.length, (i) {
                final isSelected = _quizSelected == i;
                final isCorrect = _quizSubmitted && correct != null && i == correct;
                final isWrong = _quizSubmitted && isSelected && correct != null && i != correct;
                final bg = isCorrect
                    ? cs.primary.withValues(alpha: 0.12)
                    : isWrong
                        ? cs.error.withValues(alpha: 0.10)
                        : Colors.white;

                final enabled = !_quizSubmitted;
                return InkWell(
                  onTap: enabled ? () => setState(() => _quizSelected = i) : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCorrect
                            ? cs.primary.withValues(alpha: 0.35)
                            : isWrong
                                ? cs.error.withValues(alpha: 0.35)
                                : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isWrong ? cs.error : cs.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            options[i],
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (_quizSubmitted && (explanation ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  explanation!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black.withValues(alpha: 0.65),
                        height: 1.25,
                      ),
                ),
              ],
            ],
          );

        case ModuleStepType.reflection:
          final prompt = (step.prompt ?? '').trim().isEmpty
              ? 'What will you apply from this lesson?'
              : step.prompt!.trim();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                prompt,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reflectionController,
                minLines: 4,
                maxLines: 7,
                readOnly: _completed,
                decoration: InputDecoration(
                  hintText: 'Write a few sentences…',
                  filled: true,
                  fillColor: const Color(0xFFF6F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                ),
              ),
            ],
          );
      }
    }

    Widget primaryButton() {
      final isLast = _stepIndex == _steps.length - 1;

      // quiz gating
      if (step.type == ModuleStepType.quiz && !_quizSubmitted) {
        return FilledButton(
          onPressed: _busy
              ? null
              : () {
                  if (_quizSelected == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pick an option to continue')),
                    );
                    return;
                  }
                  setState(() => _quizSubmitted = true);
                },
          child: const Text('Check answer'),
        );
      }

      if (isLast) {
        return FilledButton(
          onPressed: (_busy || _completed || _loadingCompletion) ? null : _complete,
          child: (_busy || _loadingCompletion)
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_completed ? 'Completed' : 'Complete lesson'),
        );
      }

      return FilledButton(
        onPressed: _busy ? null : _nextStep,
        child: const Text('Continue'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header(),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            controller: _stepScroll,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: content(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (_stepIndex > 0) ...[
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _busy ? null : _prevStep,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: primaryButton()),
          ],
        ),
      ],
    );
  }

  Future<void> _complete() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_completed) return;

    setState(() => _busy = true);
    try {
      AnalyticsService.instance.track('module_complete_attempt', props: {
        'pathId': widget.path.id,
        'moduleId': widget.module.id,
        'xpReward': widget.module.xp,
        'hasReflection': _reflectionController.text.trim().isNotEmpty,
      });

      // XP Logic: on first completion only, add module.xp to users.xp
      final didWrite = await FirestoreService().markModuleCompleted(
        uid: user.uid,
        pathId: widget.path.id,
        moduleId: widget.module.id,
        reflection: _reflectionController.text,
        xpReward: widget.module.xp,
      );

      if (!mounted) return;

      setState(() => _completed = true);

      AnalyticsService.instance.track('module_completed', props: {
        'pathId': widget.path.id,
        'moduleId': widget.module.id,
        'didWrite': didWrite,
        'xpReward': widget.module.xp,
      });

      if (didWrite) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('+${widget.module.xp} XP')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingEnrollment) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isEnrolled) {
      final cs = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(title: Text(widget.module.title)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.lock_rounded, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enroll required',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Please enroll in “${widget.path.title}” to unlock and play modules.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.black.withValues(alpha: 0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;
                  await FirestoreService().enrollInPath(uid: user.uid, pathId: widget.path.id);
                  await _loadEnrollment();
                },
                child: const Text('Enroll'),
              ),
            ],
          ),
        ),
      );
    }

    // Step-based module runner
    if (_isStepBased) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(title: Text(widget.module.title)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildStepBasedBody(context),
        ),
      );
    }

    // Legacy single-video module player
    final controller = _videoController;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(widget.module.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video player
            SizedBox(
              height: 220,
              child: (_videoError != null || controller == null)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        color: Colors.black,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                'Unable to load video',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _videoError ?? 'No video URL configured.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.75),
                                    ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              FilledButton.tonal(
                                onPressed: () => _setVideoUrl(widget.module.contentUrl),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ModernVideoPlayer(
                      controller: controller,
                      borderRadius: 18,
                      allowFullscreen: true,
                      showSkipButtons: true,
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.path.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.black.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.module.durationMinutes} min • ${widget.module.xp} XP',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.module.description.trim().isEmpty
                            ? 'Watch the video and reflect on what you learned.'
                            : widget.module.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black.withValues(alpha: 0.75),
                              height: 1.3,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Reflection (optional)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _reflectionController,
                        minLines: 3,
                        maxLines: 6,
                        readOnly: _completed,
                        decoration: InputDecoration(
                          hintText: 'What did you notice? What will you apply?',
                          filled: true,
                          fillColor: const Color(0xFFF6F7FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Important: This module is NOT auto-completed. You must tap “Mark as Complete”.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black.withValues(alpha: 0.55),
                              height: 1.25,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: (_busy || _completed || _loadingCompletion) ? null : _complete,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: (_busy || _loadingCompletion)
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_completed ? 'Completed' : 'Mark Complete'),
            ),
          ],
        ),
      ),
    );
  }
}
