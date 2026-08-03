// Signature element: progress as the German flag filling in.
// black = unseen, red = learning, gold = mastered.
import 'package:flutter/material.dart';

import '../theme.dart';

class FlagBar extends StatelessWidget {
  const FlagBar({
    super.key,
    required this.mastered,
    required this.learning,
    required this.fresh,
    required this.total,
  });

  final int mastered, learning, fresh, total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = total < 1 ? 1 : total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Container(
            height: 26,
            decoration: BoxDecoration(
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(children: [
              _band(c.gold, mastered / t),
              _band(c.red, learning / t),
              _band(c.bandBlack, fresh / t),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 14, runSpacing: 4, children: [
          _legend(c, c.gold, '$mastered sicher'),
          _legend(c, c.red, '$learning in Arbeit'),
          _legend(c, c.bandBlack, '$fresh neu'),
        ]),
      ],
    );
  }

  Widget _band(Color color, double frac) => Expanded(
        flex: (frac * 1000).round(),
        child: AnimatedContainer(duration: const Duration(milliseconds: 600), color: color),
      );

  Widget _legend(AppColors c, Color dot, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          Text(label, style: TextStyle(fontSize: 12.5, color: c.muted)),
        ],
      );
}
