import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.trailingText = 'See all',
  });

  final String title;
  final VoidCallback? onSeeAll;
  final String trailingText;

  @override
  Widget build(BuildContext context) {
    final canTap = onSeeAll != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        if (canTap)
          TextButton(
            onPressed: onSeeAll,
            child: Text(trailingText),
          ),
      ],
    );
  }
}

