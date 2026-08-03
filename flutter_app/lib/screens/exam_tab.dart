// "Test" tab — exam info + history; ported from ExamTab.vue.
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../ui.dart';

class ExamTab extends StatelessWidget {
  const ExamTab({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final app = AppState.I;
    final c = context.colors;
    return ListenableBuilder(
      listenable: app.store,
      builder: (context, _) {
        final exams = app.store.getExams();
        final stateName = kStates[app.settings.state ?? ''] ?? 'deinem Bundesland';
        final recent = exams.reversed.take(10).toList();
        return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
          const TabHeader(kicker: 'Simulation', title: 'Testsimulation'),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                const TextSpan(text: 'Wie in der echten Prüfung: '),
                const TextSpan(text: '33 Fragen', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: ' (30 allgemeine + 3 aus $stateName), '),
                const TextSpan(text: '60 Minuten', style: TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(text: ' Zeit.'),
              ], style: const TextStyle(fontSize: 15, height: 1.5))),
              const SizedBox(height: 10),
              _bullet(c, '„Leben in Deutschland" (Niederlassungserlaubnis): ab 15 richtigen bestanden'),
              _bullet(c, 'Einbürgerungstest: ab 17 richtigen bestanden'),
              const SizedBox(height: 12),
              AppButton('Simulation starten', onTap: onStart),
            ]),
          ),
          if (recent.isNotEmpty)
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Bisherige Simulationen',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                for (final (i, e) in recent.indexed)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: i < recent.length - 1
                          ? Border(bottom: BorderSide(color: c.line))
                          : null,
                    ),
                    child: Row(children: [
                      Expanded(child: Text(_fmt(e.date), style: const TextStyle(fontSize: 14.5))),
                      Text('${e.score}/33',
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: e.score >= kPassLid ? c.green : c.red)),
                    ]),
                  ),
              ]),
            ),
        ]);
      },
    );
  }

  static String _fmt(String iso) {
    final d = DateTime.parse(iso).toLocal();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.day)}.${p(d.month)}. ${p(d.hour)}:${p(d.minute)}';
  }

  Widget _bullet(AppColors c, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('  •  ', style: TextStyle(color: c.muted)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14.5, height: 1.45))),
        ]),
      );
}
