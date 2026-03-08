import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// A lightweight "modern" video player UI for [video_player] with:
/// - play/pause
/// - +/- 10s seek
/// - timeline scrubber
/// - playback speed
/// - fullscreen
class ModernVideoPlayer extends StatefulWidget {
  const ModernVideoPlayer({
    super.key,
    required this.controller,
    this.borderRadius = 0,
    this.backgroundColor = Colors.black,
    this.allowFullscreen = true,
    this.showSkipButtons = true,
  });

  final VideoPlayerController controller;
  final double borderRadius;
  final Color backgroundColor;
  final bool allowFullscreen;
  final bool showSkipButtons;

  @override
  State<ModernVideoPlayer> createState() => _ModernVideoPlayerState();
}

class _ModernVideoPlayerState extends State<ModernVideoPlayer> {
  static const _hideDelay = Duration(seconds: 4);
  static const _seekStep = Duration(seconds: 10);
  static const _uiTick = Duration(milliseconds: 250);

  Timer? _hideTimer;
  Timer? _uiTimer;
  bool _showControls = true;
  bool _scrubbing = false;
  Duration? _scrubPosition;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBuffering = false;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;

  final List<double> _speeds = const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _syncFromController();
    widget.controller.addListener(_onControllerChanged);
    _startHideTimer();
    _uiTimer = Timer.periodic(_uiTick, (_) {
      if (!mounted) return;
      // Throttle UI updates (progress/time) to avoid rebuilding every video frame.
      if (!_scrubbing) {
        final p = widget.controller.value.position;
        if (p != _position) {
          setState(() => _position = p);
        }
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _uiTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _syncFromController() {
    final v = widget.controller.value;
    _duration = v.isInitialized ? v.duration : Duration.zero;
    _position = v.position;
    _isBuffering = v.isBuffering;
    _isPlaying = v.isPlaying;
    _playbackSpeed = v.playbackSpeed;
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final v = widget.controller.value;

    final duration = v.isInitialized ? v.duration : Duration.zero;
    final isBuffering = v.isBuffering;
    final isPlaying = v.isPlaying;
    final speed = v.playbackSpeed;

    if (duration != _duration || isBuffering != _isBuffering || isPlaying != _isPlaying || speed != _playbackSpeed) {
      setState(() {
        _duration = duration;
        _isBuffering = isBuffering;
        _isPlaying = isPlaying;
        _playbackSpeed = speed;
      });
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideDelay, () {
      if (!mounted) return;
      setState(() => _showControls = false);
    });
  }

  void _showControlsTemporarily() {
    if (!_showControls) {
      setState(() => _showControls = true);
    }
    _startHideTimer();
  }

  void _hideControls() {
    _hideTimer?.cancel();
    if (_showControls) setState(() => _showControls = false);
  }

  Future<void> _togglePlay() async {
    final c = widget.controller;
    if (!c.value.isInitialized) return;

    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    _showControlsTemporarily();
  }

  Future<void> _seekRelative(Duration delta) async {
    final c = widget.controller;
    if (!c.value.isInitialized) return;
    final duration = c.value.duration;
    final current = c.value.position;
    var next = current + delta;
    if (next < Duration.zero) next = Duration.zero;
    if (next > duration) next = duration;
    await c.seekTo(next);
    _showControlsTemporarily();
  }

  Future<void> _enterFullscreen() async {
    if (!widget.allowFullscreen) return;
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenVideoScreen(controller: widget.controller),
      ),
    );
    if (!mounted) return;
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final cs = Theme.of(context).colorScheme;

    if (c.value.isInitialized && _duration == Duration.zero) {
      // In case init happened before we attached listeners.
      _syncFromController();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: ColoredBox(
        color: widget.backgroundColor,
        child: !c.value.isInitialized
              ? const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: AspectRatio(
                        // Keep aspect ratio stable.
                        aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
                        child: VideoPlayer(c),
                      ),
                    ),

                    // Tap layer (below controls). Single tap should show controls (not toggle off).
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _showControlsTemporarily,
                        onDoubleTap: () => _togglePlay(),
                      ),
                    ),

                    if (_isBuffering)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                          ),
                          child: const Center(
                            child: SizedBox(
                              height: 28,
                              width: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                    if (_showControls) ...[
                      // scrim
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.25),
                                Colors.black.withValues(alpha: 0.15),
                                Colors.black.withValues(alpha: 0.55),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // center controls
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.showSkipButtons)
                              _ControlIcon(
                                icon: Icons.replay_10_rounded,
                                onTap: () => _seekRelative(-_seekStep),
                              ),
                            const SizedBox(width: 10),
                            _ControlIcon(
                              icon: _isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_filled_rounded,
                              size: 66,
                              onTap: _togglePlay,
                            ),
                            const SizedBox(width: 10),
                            if (widget.showSkipButtons)
                              _ControlIcon(
                                icon: Icons.forward_10_rounded,
                                onTap: () => _seekRelative(_seekStep),
                              ),
                          ],
                        ),
                      ),

                      // bottom bar
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 6,
                        child: _BottomBar(
                          controller: c,
                          colorScheme: cs,
                          duration: _duration,
                          position: _scrubbing ? (_scrubPosition ?? _position) : _position,
                          onChangeStart: () {
                            setState(() {
                              _scrubbing = true;
                              _scrubPosition = _position;
                            });
                            _hideTimer?.cancel();
                          },
                          onChanged: (to) {
                            setState(() => _scrubPosition = to);
                          },
                          onChangeEnd: (to) async {
                            await c.seekTo(to);
                            if (!mounted) return;
                            setState(() {
                              _scrubbing = false;
                              _scrubPosition = null;
                              _position = to;
                            });
                            _showControlsTemporarily();
                          },
                          speeds: _speeds,
                          currentSpeed: _playbackSpeed,
                          onSpeedSelected: (s) async {
                            await c.setPlaybackSpeed(s);
                            if (!mounted) return;
                            _showControlsTemporarily();
                          },
                          allowFullscreen: widget.allowFullscreen,
                          onFullscreen: _enterFullscreen,
                        ),
                      ),

                      // Quick dismiss.
                      Positioned(
                        top: 6,
                        right: 6,
                        child: IconButton(
                          onPressed: _hideControls,
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white.withValues(alpha: 0.9),
                          tooltip: 'Hide controls',
                        ),
                      ),
                    ],
                  ],
                ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.controller,
    required this.colorScheme,
    required this.duration,
    required this.position,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
    required this.speeds,
    required this.currentSpeed,
    required this.onSpeedSelected,
    required this.allowFullscreen,
    required this.onFullscreen,
  });

  final VideoPlayerController controller;
  final ColorScheme colorScheme;
  final Duration duration;
  final Duration position;
  final VoidCallback onChangeStart;
  final ValueChanged<Duration> onChanged;
  final ValueChanged<Duration> onChangeEnd;
  final List<double> speeds;
  final double currentSpeed;
  final ValueChanged<double> onSpeedSelected;
  final bool allowFullscreen;
  final VoidCallback onFullscreen;

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final maxMsRaw = duration.inMilliseconds.toDouble();
    final maxMs = maxMsRaw < 1 ? 1.0 : maxMsRaw;
    final posMsRaw = position.inMilliseconds.toDouble();
    final posMs = posMsRaw < 0 ? 0.0 : (posMsRaw > maxMs ? maxMs : posMsRaw);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.35),
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.20),
          ),
          child: Slider(
            min: 0,
            max: maxMs,
            value: posMs,
            onChangeStart: (_) => onChangeStart(),
            onChanged: (newValue) =>
                onChanged(Duration(milliseconds: newValue.round())),
            onChangeEnd: (newValue) =>
                onChangeEnd(Duration(milliseconds: newValue.round())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Text(
                _format(position),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SpeedMenu(
                        speeds: speeds,
                        current: currentSpeed,
                        onSelected: onSpeedSelected,
                      ),
                      if (allowFullscreen) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: onFullscreen,
                          icon: const Icon(Icons.fullscreen_rounded),
                          color: Colors.white.withValues(alpha: 0.92),
                          tooltip: 'Fullscreen',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlIcon extends StatelessWidget {
  const _ControlIcon({
    required this.icon,
    required this.onTap,
    this.size = 46,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      iconSize: size,
      icon: Icon(icon, color: Colors.white.withValues(alpha: 0.92)),
    );
  }
}

class _SpeedMenu extends StatelessWidget {
  const _SpeedMenu({
    required this.speeds,
    required this.current,
    required this.onSelected,
  });

  final List<double> speeds;
  final double current;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final label = current == 1.0 ? '1x' : '${current}x';
    return PopupMenuButton<double>(
      tooltip: 'Speed',
      initialValue: current,
      onSelected: onSelected,
      itemBuilder: (context) => speeds
          .map(
            (s) => PopupMenuItem<double>(
              value: s,
              child: Text(s == 1.0 ? 'Normal (1x)' : '${s}x'),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _FullscreenVideoScreen extends StatefulWidget {
  const _FullscreenVideoScreen({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_FullscreenVideoScreen> createState() => _FullscreenVideoScreenState();
}

class _FullscreenVideoScreenState extends State<_FullscreenVideoScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        // In fullscreen, let the video take maximum space.
        child: Stack(
          children: [
            Center(
              child: ModernVideoPlayer(
                controller: widget.controller,
                allowFullscreen: false,
                showSkipButtons: true,
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
                tooltip: 'Exit fullscreen',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
