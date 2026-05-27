import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../models/segment.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../ui/emerald_orbit/tokens.dart';
import '../ui/emerald_orbit/widgets/eo_card.dart';

/// Segment detail: lists activities inside a Segment.
///
/// Firestore:
/// - segments
/// - activities (filter by segmentId)
/// - activity_completions (userId + segmentId)
class SegmentDetailScreen extends StatelessWidget {
  const SegmentDetailScreen({super.key, required this.segment});

  final Segment segment;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cs = Theme.of(context).colorScheme;
    final firestore = FirestoreService();

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      backgroundColor: EoColors.background,
      appBar: AppBar(
        title: Text(segment.title.isEmpty ? 'Segment' : segment.title),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore.queryActivitiesForSegment(segment.id).snapshots(),
        builder: (context, activitiesSnap) {
          final activities = (activitiesSnap.data?.docs ?? [])
              .map(Activity.fromDoc)
              .where((a) => a.isActive)
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: firestore
                .queryActivityCompletionsForSegment(uid: user.uid, segmentId: segment.id)
                .snapshots(),
            builder: (context, completionSnap) {
              final completedActivityIds = (completionSnap.data?.docs ?? [])
                  .map((d) => (d.data()['activityId'] as String?) ?? '')
                  .where((id) => id.trim().isNotEmpty)
                  .toSet();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  if ((segment.subtitle ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        segment.subtitle!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: EoColors.onSurfaceVariant),
                      ),
                    ),

                  if (activities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'No activities available yet. Add `activities` for this segment.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: EoColors.onSurfaceVariant),
                      ),
                    ),

                  ...activities.map((a) {
                    final isDone = completedActivityIds.contains(a.id);
                    final xp = a.xpReward;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EoCard(
                        padding: const EdgeInsets.all(16),
                        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.10)),
                        onTap: () async {
                          AnalyticsService.instance.track('activity_opened', props: {
                            'segmentId': segment.id,
                            'activityId': a.id,
                            'type': a.type.name,
                          });

                          // For now: complete on tap (MVP). Later we can add a full activity player.
                          final did = await firestore.markActivityCompleted(
                            uid: user.uid,
                            segmentId: segment.id,
                            activityId: a.id,
                            xpAward: xp,
                          );

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(did ? '+$xp XP' : 'Already completed')),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                color: isDone
                                    ? cs.primary.withValues(alpha: 0.12)
                                    : cs.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                isDone ? Icons.check_rounded : Icons.play_arrow_rounded,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${a.type.name.toUpperCase()} • +$xp XP',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: EoColors.onSurfaceVariant,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: EoColors.onSurfaceVariant.withValues(alpha: 0.60),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
