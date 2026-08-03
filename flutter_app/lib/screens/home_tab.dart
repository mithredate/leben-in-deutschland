// "Heute" tab — ported from app/components/HomeTab.vue.
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../srs.dart';
import '../theme.dart';
import '../ui.dart';
import '../widgets/flag_bar.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onStudy, required this.onExam});

  final VoidCallback onStudy;
  final VoidCallback onExam;

  @override
  Widget build(BuildContext context) {
    final app = AppState.I;
    final c = context.colors;
    return ListenableBuilder(
      listenable: app.store,
      builder: (context, _) {
        final settings = app.settings;
        final pool = app.pool;
        final progress = app.store.getProgress();
        final s = summarize(pool, progress);
        final due = dueCount(pool, progress);
        final target = dailyTarget(s.newCount, settings.examDate);
        final today = app.store.answeredToday();
        final streak = app.store.streak();
        final exams = app.store.getExams();
        final lastExam = exams.isEmpty ? null : exams.last;

        final examDate = DateTime.parse(settings.examDate);
        const wd = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
        const mo = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli',
          'August', 'September', 'Oktober', 'November', 'Dezember'];
        final dateLabel =
            '${wd[examDate.weekday - 1]}, ${examDate.day}. ${mo[examDate.month - 1]}';

        final roundable = due + s.newCount;
        final studyLabel = roundable > 0
            ? 'Runde starten (${roundable < kRoundSize ? roundable : kRoundSize} Fragen)'
            : 'Alles gemeistert – Fehler wiederholen';

        return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
          const TabHeader(kicker: 'Leben in Deutschland', title: 'Testtrainer'),
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.cdBg,
              border: Border.all(color: c.cdBorder ?? Colors.transparent),
              borderRadius: BorderRadius.circular(kRadiusApp),
            ),
            child: Row(children: [
              Text('${target.daysLeft}',
                  style: TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: c.gold, height: 1)),
              const SizedBox(width: 16),
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                      text: 'Tag${target.daysLeft == 1 ? '' : 'e'} bis zur Prüfung\n',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: c.cdFg)),
                  TextSpan(
                      text: '$dateLabel · ${kStates[settings.state ?? ''] ?? ''}',
                      style: TextStyle(fontSize: 13, color: c.cdFg.withValues(alpha: 0.75))),
                ])),
              ),
            ]),
          ),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Dein Fortschritt',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 10),
              FlagBar(mastered: s.mastered, learning: s.learning, fresh: s.newCount, total: s.total),
              const SizedBox(height: 14),
              Row(children: [
                _stat(c, due, 'fällig'),
                _stat(c, today, 'heute geübt'),
                _stat(c, streak, 'Tage-Serie'),
                _stat(c, target.perDay < 0 ? 0 : target.perDay, 'neue/Tag nötig'),
              ]),
            ]),
          ),
          AppButton(studyLabel, onTap: onStudy),
          const SizedBox(height: 10),
          AppButton('Testsimulation starten', variant: 'outline', onTap: onExam),
          if (lastExam != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Letzte Simulation: '),
                  TextSpan(
                      text: '${lastExam.score}/33 ',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(
                      text: lastExam.score >= kPassLid ? '✓ bestanden' : '✗ nicht bestanden'),
                ], style: TextStyle(fontSize: 14, color: c.muted)),
                textAlign: TextAlign.center,
              ),
            ),
        ]);
      },
    );
  }

  Widget _stat(AppColors c, int value, String label) => Expanded(
        child: Column(children: [
          Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          Text(label,
              textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: c.muted)),
        ]),
      );
}
