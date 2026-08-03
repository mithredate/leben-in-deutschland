import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class SourceLine extends StatelessWidget {
  const SourceLine(this.q, {super.key});
  final Question q;

  @override
  Widget build(BuildContext context) {
    final src = q.src;
    if (src == null) return const SizedBox.shrink();
    final c = context.colors;
    final isEn = AppState.I.settings.lang == 'en';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text.rich(
        TextSpan(style: TextStyle(fontSize: 12.5, color: c.ink), children: [
          TextSpan(text: isEn ? 'Source: ' : 'Quelle: '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => launchUrl(Uri.parse(src.u), mode: LaunchMode.externalApplication),
              child: Text(
                src.t.isNotEmpty ? src.t : src.u,
                style: TextStyle(
                    fontSize: 12.5, color: c.red, decoration: TextDecoration.underline),
              ),
            ),
          ),
          TextSpan(
            text: isEn
                ? ' · AI-generated explanation, no guarantee'
                : ' · KI-erstellte Erklärung, ohne Gewähr',
            style: TextStyle(color: c.muted),
          ),
        ]),
      ),
    );
  }
}
