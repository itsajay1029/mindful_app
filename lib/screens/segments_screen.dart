import 'package:flutter/material.dart';

import '../widgets/pressable_card.dart';

/// MVP segments list (static).
///
/// Later: drive from Firestore `segments` collection.
class SegmentsScreen extends StatelessWidget {
  const SegmentsScreen({super.key});

  static const _segments = <String>[
    'Problem Solving',
    'Communication',
    'Conflict Resolution',
    'Well Being',
    'Team Management',
    'Emotional Intelligence',
    'Active Listening',
    'Self Awareness',
    'Resilience & Adaptability',
    'Purpose',
    'Reflection',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Segments')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: _segments.length,
        separatorBuilder: (context, i) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final s = _segments[i];
          return PressableCard(
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s,
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Segment experiences are coming next.\n\nFor now you can browse courses and sprints from Home.',
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: Colors.black.withValues(alpha: 0.7),
                            ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Got it'),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.bolt_rounded, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Games • Micro-sprints • Audio resets',
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
          );
        },
      ),
    );
  }
}
