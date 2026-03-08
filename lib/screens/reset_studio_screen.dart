import 'package:flutter/material.dart';

import 'reset_studio_player_screen.dart';

class ResetStudioScreen extends StatelessWidget {
  const ResetStudioScreen({super.key});

  static const _items = <_ResetAudioItem>[
    _ResetAudioItem(title: 'Reset 01 — Breath', duration: '5 min', url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'),
    _ResetAudioItem(title: 'Reset 02 — Focus', duration: '5 min', url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4'),
    _ResetAudioItem(title: 'Reset 03 — Gratitude', duration: '5 min', url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4'),
    _ResetAudioItem(title: 'Reset 04 — Calm', duration: '5 min', url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4'),
    _ResetAudioItem(title: 'Reset 05 — Night', duration: '5 min', url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Reset Studio')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (context, i) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final item = _items[i];
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResetStudioPlayerScreen(title: item.title, url: item.url),
                ),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                    color: Colors.black.withValues(alpha: 0.06),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.duration,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black.withValues(alpha: 0.35)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResetAudioItem {
  const _ResetAudioItem({required this.title, required this.duration, required this.url});
  final String title;
  final String duration;
  final String url;
}
