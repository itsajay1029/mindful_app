import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/learning_module.dart';
import '../models/learning_path.dart';
import '../models/user_enrollment.dart';
import '../services/firestore_service.dart';

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
  late final VideoPlayerController _videoController;
  final _reflectionController = TextEditingController();
  bool _busy = false;
  bool _completed = false;
  bool _loadingCompletion = true;
  bool _checkingEnrollment = true;
  bool _isEnrolled = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.module.contentUrl));
    _initVideo();
    _loadCompletion();
    _loadEnrollment();
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
    try {
      await _videoController.initialize();
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

  @override
  void dispose() {
    _videoController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_completed) return;

    setState(() => _busy = true);
    try {
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
    final isReady = _videoController.value.isInitialized;

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
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: Colors.black,
                height: 220,
                child: _videoError != null
                    ? Padding(
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
                              _videoError!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            FilledButton.tonal(
                              onPressed: _initVideo,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : isReady
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _videoController.value.size.width,
                                  height: _videoController.value.size.height,
                                  child: VideoPlayer(_videoController),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _videoController.value.isPlaying
                                        ? _videoController.pause()
                                        : _videoController.play();
                                  });
                                },
                                iconSize: 64,
                                icon: Icon(
                                  _videoController.value.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
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
