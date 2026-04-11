import 'package:flutter/material.dart';

import '../ui/emerald_orbit/tokens.dart';
import '../ui/emerald_orbit/widgets/eo_glass.dart';

/// MVP Coach (AI Q&A): chat UI with placeholder responses.
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      fromCoach: true,
      text: 'Hello! What would you like to focus on today?',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(fromCoach: false, text: text));
      _messages.add(_ChatMessage(fromCoach: true, text: _coachReply(text)));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _coachReply(String userText) {
    final t = userText.toLowerCase();
    if (t.contains('motivation')) {
      return 'Let’s make it easy: pick a 2‑minute action you can do right now. What’s the smallest win?';
    }
    if (t.contains('conflict') || t.contains('disagree')) {
      return 'Try this script: “Help me understand what matters most to you here.” Then reflect back what you heard.';
    }
    if (t.contains('stress') || t.contains('burn')) {
      return 'Quick reset: 4‑second inhale, 6‑second exhale for 5 cycles. Want a 5‑minute reset audio?';
    }
    return 'Got it. Here’s a simple next step: define the goal, list 2 options, and pick the smallest experiment for today.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // NOTE: This screen is rebuilt to match `screens/stitch/coach_chat/code.html`.
    return Scaffold(
      backgroundColor: EoColors.surface,
      body: Stack(
        children: [
          Column(
            children: [
              _CoachTopBar(
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 160),
                  itemCount: _messages.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: EoColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(EoRadii.full),
                            ),
                            child: Text(
                              'TODAY',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: EoColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                        ),
                      );
                    }

                    final m = _messages[i - 1];
                    return _CoachChatBubble(message: m);
                  },
                ),
              ),
            ],
          ),
          // Bottom composer (fixed) — matches Stitch (rounded-full, glassy, add + send)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                child: EoGlass(
                  blur: 24,
                  color: EoColors.surfaceContainerLowest.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(EoRadii.full),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 40,
                      offset: const Offset(0, 14),
                      color: Colors.black.withValues(alpha: 0.12),
                    ),
                  ],
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.add_circle, color: EoColors.slate400),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: 'Ask anything...',
                            border: InputBorder.none,
                            isCollapsed: true,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: EoColors.slate400,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: EoColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _send,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(EoRadii.full),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                color: cs.primary.withValues(alpha: 0.30),
                              ),
                            ],
                          ),
                          child: Icon(Icons.send, color: cs.onPrimary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachTopBar extends StatelessWidget {
  const _CoachTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.80),
          boxShadow: [
            BoxShadow(
              blurRadius: 32,
              offset: const Offset(0, 8),
              color: cs.primary.withValues(alpha: 0.10),
            )
          ],
        ),
        child: Row(
          children: [
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.arrow_back, color: EoColors.emerald800),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: EoColors.primaryContainer,
                borderRadius: BorderRadius.circular(EoRadii.full),
              ),
              child: Icon(Icons.smart_toy, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Coach Guide',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: EoColors.emerald900,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ONLINE NOW',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: EoColors.onSurfaceVariant,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Icon(Icons.info, color: EoColors.slate400),
          ],
        ),
      ),
    );
  }
}

class _CoachChatBubble extends StatelessWidget {
  const _CoachChatBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCoach = message.fromCoach;
    final time = '09:12 AM';

    if (isCoach) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: EoColors.primaryContainer,
                borderRadius: BorderRadius.circular(EoRadii.full),
              ),
              child: Icon(Icons.smart_toy, color: cs.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: EoColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(EoRadii.lg),
                    topRight: Radius.circular(EoRadii.lg),
                    bottomRight: Radius.circular(EoRadii.lg),
                    bottomLeft: Radius.circular(EoRadii.d), // rounded-bl-none
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                      color: Colors.black.withValues(alpha: 0.04),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: EoColors.onSurface,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: EoColors.onSurfaceVariant.withValues(alpha: 0.60),
                          ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(EoRadii.lg),
                topRight: Radius.circular(EoRadii.lg),
                bottomLeft: Radius.circular(EoRadii.lg),
                bottomRight: Radius.circular(EoRadii.d), // rounded-br-none
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                  color: cs.primary.withValues(alpha: 0.15),
                )
              ],
            ),
            child: Text(
              message.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: cs.onPrimary,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              time,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: EoColors.onSurfaceVariant.withValues(alpha: 0.60),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.fromCoach, required this.text});
  final bool fromCoach;
  final String text;
}
