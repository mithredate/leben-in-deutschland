// Exam simulation — ported from app/components/ExamOverlay.vue.
// 30 random general + 3 random Bundesland questions, 60 minutes.
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../srs.dart';
import '../theme.dart';
import '../ui.dart';
import '../widgets/question_card.dart';
import '../widgets/source_line.dart';

const int kExamMinutes = 60;

class _Wrong {
  final Question q;
  final int? picked;
  const _Wrong(this.q, this.picked);
}

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key, required this.onDrill});

  /// Called when the user wants to practice their mistakes right away.
  final void Function(List<Question> qs) onDrill;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final app = AppState.I;
  List<Question> qs = [];
  List<int?> picked = [];
  int idx = 0;
  int secondsLeft = kExamMinutes * 60;
  ({int score, List<_Wrong> wrong})? result;
  Timer? timer;
  final _navScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    final general = app.questions.where((q) => q.state == null).toList()..shuffle(rnd);
    final state = app.questions.where((q) => q.state == app.settings.state).toList()..shuffle(rnd);
    qs = [...general.take(30), ...state.take(3)]..shuffle(rnd);
    picked = List<int?>.filled(qs.length, null);
    final deadline = DateTime.now().add(const Duration(minutes: kExamMinutes));
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = deadline.difference(DateTime.now()).inSeconds;
      setState(() => secondsLeft = left < 0 ? 0 : left);
      if (secondsLeft <= 0) _submit();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _navScroll.dispose();
    super.dispose();
  }

  bool get isEn => app.settings.lang == 'en';
  String t(String de, String en) => isEn ? en : de;

  String get timeLabel {
    final m = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _pick(int i) {
    setState(() {
      picked[idx] = i;
      if (idx < qs.length - 1) idx += 1;
    });
  }

  Future<void> _tryClose() async {
    if (result != null ||
        await confirmDialog(context, t('Simulation wirklich abbrechen?', 'Really cancel the simulation?'))) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _trySubmit() async {
    final open = picked.where((p) => p == null).length;
    if (open > 0) {
      final msg = isEn
          ? '$open question${open == 1 ? '' : 's'} unanswered. Submit anyway?'
          : '$open Frage${open == 1 ? '' : 'n'} unbeantwortet. Trotzdem abgeben?';
      if (!await confirmDialog(context, msg)) return;
    }
    _submit();
  }

  void _submit() {
    if (result != null) return;
    timer?.cancel();
    var score = 0;
    final wrong = <_Wrong>[];
    final p = app.store.getProgress();
    for (final (i, q) in qs.indexed) {
      final ok = picked[i] == q.correct;
      if (ok) {
        score += 1;
      } else {
        wrong.add(_Wrong(q, picked[i]));
      }
      p[q.id] = gradeAnswer(p[q.id], ok);
      app.store.recordAnswer(ok);
    }
    app.store.setProgress(p);
    app.store.addExam(ExamRecord(
      date: DateTime.now().toUtc().toIso8601String(),
      score: score,
      total: qs.length,
      passedLid: score >= kPassLid,
      passedEinb: score >= kPassEinbuergerung,
    ));
    setState(() => result = (score: score, wrong: wrong));
  }

  String? _explFor(Question q) =>
      isEn ? (q.en.explanation ?? q.explanationDe) : (q.explanationDe ?? q.en.explanation);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _tryClose();
      },
      child: Scaffold(
        backgroundColor: c.paper,
        body: SafeArea(child: result == null ? _examView(c) : _resultView(c)),
      ),
    );
  }

  Widget _examView(AppColors c) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
        child: Row(children: [
          IconButton(icon: Icon(Icons.close, color: c.muted), onPressed: _tryClose),
          Expanded(
            child: Text(
              timeLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: secondsLeft < 300 ? c.red : c.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          FilledButton(
            onPressed: _trySubmit,
            style: FilledButton.styleFrom(
              backgroundColor: c.gold,
              foregroundColor: c.goldInk,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Abgeben', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
      SizedBox(
        height: 44,
        child: ListView.separated(
          controller: _navScroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          itemCount: qs.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final done = picked[i] != null;
            final active = i == idx;
            return InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => setState(() => idx = i),
              child: Container(
                width: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? c.ink : Colors.transparent,
                  border: Border.all(color: active ? c.gold : (done ? c.ink : c.line), width: 1.5),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: active ? [BoxShadow(color: c.gold, spreadRadius: 1, blurRadius: 0)] : null,
                ),
                child: Text('${i + 1}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: done ? c.paper : c.muted)),
              ),
            );
          },
        ),
      ),
      Expanded(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuestionCard(
                key: ValueKey(qs[idx].id),
                q: qs[idx],
                mode: 'exam',
                picked: picked[idx],
                label:
                    'Aufgabe ${idx + 1} von ${qs.length}${qs[idx].state != null ? ' · Bundesland' : ''}',
                onPick: _pick,
              ),
            ),
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration:
            BoxDecoration(color: c.card, border: Border(top: BorderSide(color: c.line))),
        child: SafeArea(
          top: false,
          child: Row(children: [
            Expanded(
              child: AppButton('← Zurück',
                  variant: 'outline',
                  enabled: idx > 0,
                  onTap: () => setState(() => idx -= 1)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton('Weiter →',
                  enabled: idx < qs.length - 1, onTap: () => setState(() => idx += 1)),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _resultView(AppColors c) {
    final r = result!;
    final passedLid = r.score >= kPassLid;
    final passedEinb = r.score >= kPassEinbuergerung;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
          children: [
            Center(child: Kicker(t('Ergebnis', 'Result'))),
            Center(
              child: Text('${r.score}/33',
                  style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: passedLid ? c.green : c.red)),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _passCard(c, passedLid, 'Leben in Deutschland (NE)',
                      passedLid ? t('bestanden ✓', 'passed ✓') : t('nicht bestanden ✗', 'not passed ✗'))),
              const SizedBox(width: 10),
              Expanded(
                  child: _passCard(c, passedEinb, t('Einbürgerung', 'Naturalization'),
                      passedEinb ? t('bestanden ✓', 'passed ✓') : t('nicht bestanden ✗', 'not passed ✗'))),
            ]),
            const SizedBox(height: 20),
            if (r.wrong.isNotEmpty) ...[
              Text('${t('Falsche Antworten', 'Wrong answers')} (${r.wrong.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 10),
              for (final w in r.wrong) _wrongCard(c, w),
              const SizedBox(height: 6),
              AppButton('${t('Fehler jetzt üben', 'Practice mistakes now')} (${r.wrong.length})',
                  onTap: () {
                final drill = r.wrong.map((w) => w.q).toList();
                Navigator.of(context).pop();
                widget.onDrill(drill);
              }),
              const SizedBox(height: 10),
            ],
            AppButton(t('Schließen', 'Close'),
                variant: 'outline', onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  Widget _passCard(AppColors c, bool passed, String title, String verdict) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: passed ? c.greenSoft : c.redSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: passed ? c.green : c.red)),
          Text(verdict,
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w700, color: passed ? c.green : c.red)),
        ]),
      );

  Widget _wrongCard(AppColors c, _Wrong w) {
    final qEn = isEn ? w.q.en.question : null;
    String? aEn(int? i) =>
        (isEn && i != null && i < w.q.en.answers.length) ? w.q.en.answers[i] : null;
    final expl = _explFor(w.q);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(kRadiusApp),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Kicker('${t('Frage', 'Question')} ${w.q.num}'),
        const SizedBox(height: 6),
        Text(w.q.question, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
        if (qEn != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(qEn, style: TextStyle(color: c.muted, fontSize: 14.5)),
          ),
        if (w.q.image != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/img/${w.q.image}', fit: BoxFit.contain),
          ),
        const SizedBox(height: 6),
        Text(
          '${t('Deine Antwort', 'Your answer')}: ${w.picked != null ? w.q.answers[w.picked!] : '–'}'
          '${aEn(w.picked) != null ? ' · ${aEn(w.picked)}' : ''}',
          style: TextStyle(color: c.red, fontSize: 14.5),
        ),
        Text(
          '${t('Richtig', 'Correct')}: ${w.q.answers[w.q.correct]}'
          '${aEn(w.q.correct) != null ? ' · ${aEn(w.q.correct)}' : ''}',
          style: TextStyle(color: c.green, fontSize: 14.5),
        ),
        if (expl != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.paper,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _Expandable(title: t('Erklärung', 'Explanation'), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expl, style: TextStyle(fontSize: 14, height: 1.45, color: c.muted)),
                SourceLine(w.q),
              ],
            )),
          ),
      ]),
    );
  }
}

class _Expandable extends StatefulWidget {
  const _Expandable({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  State<_Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<_Expandable> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => open = !open),
        child: Row(children: [
          Icon(open ? Icons.expand_more : Icons.chevron_right, size: 18, color: c.muted),
          Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
      if (open) Padding(padding: const EdgeInsets.only(top: 8), child: widget.child),
    ]);
  }
}
