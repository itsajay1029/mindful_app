import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../widgets/video/modern_video_player.dart';

/// MVP player: reuses the existing video player widget.
///
/// In production, we can swap to a true audio player plugin.
class ResetStudioPlayerScreen extends StatefulWidget {
  const ResetStudioPlayerScreen({super.key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  State<ResetStudioPlayerScreen> createState() => _ResetStudioPlayerScreenState();
}

class _ResetStudioPlayerScreenState extends State<ResetStudioPlayerScreen> {
  late final VideoPlayerController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      await _controller.play();
      if (!mounted) return;
      setState(() => _error = null);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 240,
              child: _error != null
                  ? Center(child: Text('Unable to play.\n$_error', textAlign: TextAlign.center))
                  : ModernVideoPlayer(
                      controller: _controller,
                      borderRadius: 18,
                      allowFullscreen: true,
                      showSkipButtons: true,
                    ),
            ),
            const SizedBox(height: 14),
            Text(
              'Tip: In production, this will be an audio-first experience with a calm background.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
