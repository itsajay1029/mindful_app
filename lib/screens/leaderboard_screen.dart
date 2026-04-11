import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/public_user.dart';
import '../services/firestore_service.dart';
import '../ui/emerald_orbit/tokens.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  String _formatXp(int xp) {
    if (xp >= 1000000) {
      final v = xp / 1000000.0;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}M XP';
    }
    if (xp >= 1000) {
      final v = xp / 1000.0;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}K XP';
    }
    return '$xp XP';
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: EoColors.background,
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore.queryLeaderboard(limit: 30).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed to load leaderboard: ${snap.error}'));
          }

          final users = (snap.data?.docs ?? [])
              .map(PublicUser.fromDoc)
              .where((u) => u.displayName.trim().isNotEmpty)
              .toList();

          if (users.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No players yet.\n\nOnce users sign in, they will appear here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final top3 = users.take(3).toList(growable: false);
          final rest = users.skip(3).toList(growable: false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              if (top3.isNotEmpty) _Podium(top3: top3, formatXp: _formatXp),
              const SizedBox(height: 18),
              ...List.generate(rest.length, (i) {
                final u = rest[i];
                final rank = i + 4;
                final isMe = currentUid != null && u.uid == currentUid;
                return Padding(
                  padding: EdgeInsets.only(bottom: i == rest.length - 1 ? 0 : 12),
                  child: _LeaderboardRow(
                    user: u,
                    rank: rank,
                    isMe: isMe,
                    formatXp: _formatXp,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top3, required this.formatXp});

  final List<PublicUser> top3;
  final String Function(int xp) formatXp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    PublicUser? first;
    PublicUser? second;
    PublicUser? third;
    if (top3.isNotEmpty) first = top3[0];
    if (top3.length > 1) second = top3[1];
    if (top3.length > 2) third = top3[2];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
      decoration: BoxDecoration(
        color: EoColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(EoRadii.lg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 12),
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      // NOTE: No fixed height here. Using a fixed height caused overflow on
      // smaller devices and visually overlapped the list below.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumSlot(
              user: second,
              rank: 2,
              height: 110,
              ringColor: Colors.white,
              badgeBg: EoColors.surfaceContainer,
              badgeFg: EoColors.onSurface,
              xpBg: cs.tertiaryContainer.withValues(alpha: 0.45),
              xpFg: EoColors.onTertiaryContainer,
              formatXp: formatXp,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PodiumSlot(
              user: first,
              rank: 1,
              height: 150,
              ringColor: cs.secondary,
              badgeBg: cs.secondary,
              badgeFg: cs.onSecondary,
              xpBg: cs.primary,
              xpFg: cs.onPrimary,
              crown: const Icon(Icons.emoji_events_rounded, size: 34, color: EoColors.secondary),
              formatXp: formatXp,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PodiumSlot(
              user: third,
              rank: 3,
              height: 90,
              ringColor: Colors.white,
              badgeBg: cs.tertiaryContainer.withValues(alpha: 0.50),
              badgeFg: EoColors.onTertiaryContainer,
              xpBg: cs.tertiaryContainer.withValues(alpha: 0.45),
              xpFg: EoColors.onTertiaryContainer,
              formatXp: formatXp,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.user,
    required this.rank,
    required this.height,
    required this.ringColor,
    required this.badgeBg,
    required this.badgeFg,
    required this.xpBg,
    required this.xpFg,
    required this.formatXp,
    this.crown,
  });

  final PublicUser? user;
  final int rank;
  final double height;
  final Color ringColor;
  final Color badgeBg;
  final Color badgeFg;
  final Color xpBg;
  final Color xpFg;
  final Widget? crown;
  final String Function(int xp) formatXp;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final second = parts.length > 1 ? parts[1].characters.first : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = user?.displayName ?? '—';
    final xp = user?.xp ?? 0;
    final avatarSize = rank == 1 ? 86.0 : 70.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (rank == 1) ...[
          crown ?? const SizedBox.shrink(),
          const SizedBox(height: 8),
        ],
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ringColor, width: rank == 1 ? 4 : 2),
              ),
              child: CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: cs.primaryContainer.withValues(alpha: 0.55),
                child: Text(
                  _initials(name),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                      ),
                ),
              ),
            ),
            Positioned(
              top: -12,
              right: rank == 2 ? -8 : null,
              left: rank == 3 ? -8 : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                      color: Colors.black.withValues(alpha: 0.08),
                    )
                  ],
                ),
                child: Text(
                  '#$rank',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: badgeFg,
                      ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: rank == 1 ? FontWeight.w900 : FontWeight.w800,
                color: rank == 1 ? cs.primary : EoColors.onSurface,
              ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: xpBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            formatXp(xp),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: xpFg,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: rank == 1 ? cs.primary.withValues(alpha: 0.92) : EoColors.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, -6),
                color: rank == 1 ? cs.primary.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.03),
              ),
            ],
          ),
          child: rank == 1
              ? Center(
                  child: Icon(Icons.rocket_launch_rounded, color: cs.onPrimary.withValues(alpha: 0.22), size: 38),
                )
              : null,
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.user,
    required this.rank,
    required this.isMe,
    required this.formatXp,
  });

  final PublicUser user;
  final int rank;
  final bool isMe;
  final String Function(int xp) formatXp;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final second = parts.length > 1 ? parts[1].characters.first : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rowBg = isMe ? cs.primaryContainer.withValues(alpha: 0.35) : EoColors.surfaceContainerLowest;
    final border = isMe ? cs.primary.withValues(alpha: 0.22) : cs.outlineVariant.withValues(alpha: 0.10);
    final rankColor = isMe ? cs.primary : EoColors.outlineVariant;
    final xpBg = isMe ? cs.primary : cs.tertiaryContainer;
    final xpFg = isMe ? cs.onPrimary : cs.onTertiaryContainer;
    final streakColor = isMe ? cs.primary : cs.secondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(EoRadii.lg),
        border: Border.all(color: border, width: isMe ? 2 : 1),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 12),
            color: Colors.black.withValues(alpha: isMe ? 0.06 : 0.04),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: rankColor,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.55),
            child: Text(
              _initials(user.displayName),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isMe ? cs.onPrimaryContainer : EoColors.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded, size: 16, color: streakColor),
                    const SizedBox(width: 6),
                    Text(
                      '${user.streakCurrent} DAY STREAK',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: streakColor,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: xpBg,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  color: xpBg.withValues(alpha: 0.22),
                )
              ],
            ),
            child: Text(
              formatXp(user.xp),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: xpFg,
                    letterSpacing: 0.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
