// Study round — ported from app/components/StudyOverlay.vue.
// Missed questions requeue at a random spot ≥ kRequeueGap cards later.
// answers[i] is the picked index for queue[i] — lifted here so the user can
// navigate back to any card and still see their answer + feedback.
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../srs.dart';
import '../theme.dart';
import '../ui.dart';
import '../widgets/question_card.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, this.list});

  /// Explicit drill list (from browse / exam mistakes); null = normal round.
  final List<Question>? list;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final app = AppState.I;
  List<Question> queue = [];
  List<int?> answers = [];
  int idx = 0;
  bool finished = false;
  final _stripCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _start(widget.list != null
        ? [...widget.list!]
        : buildSession(app.pool, app.store.getProgress()));
  }

  @override
  void dispose() {
    _stripCtrl.dispose();
    super.dispose();
  }

  void _start(List<Question> qs) {
    setState(() {
      queue = qs;
      answers = List<int?>.filled(qs.length, null, growable: true);
      idx = 0;
      finished = false;
    });
    if (qs.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showToast(context, 'Nichts fällig – alles gelernt! 🎉');
        Navigator.of(context).pop();
      });
    }
  }

  Question? get current => idx < queue.length ? queue[idx] : null;
  int get answeredCount => answers.where((a) => a != null).length;
  int get rightCount {
    var n = 0;
    for (var i = 0; i < queue.length; i++) {
      if (answers[i] != null && answers[i] == queue[i].correct) n++;
    }
    return n;
  }

  bool get allAnswered => answeredCount == queue.length;

  /// Unique questions missed at least once this round (drill material).
  List<Question> get mistakes {
    final seen = <String>{};
    final out = <Question>[];
    for (var i = 0; i < queue.length; i++) {
      final a = answers[i];
      if (a != null && a != queue[i].correct && seen.add(queue[i].id)) {
        out.add(queue[i]);
      }
    }
    return out;
  }

  void _onAnswer(bool correct, int picked) {
    if (answers[idx] != null) return;
    final q = current!;
    final p = app.store.getProgress();
    p[q.id] = gradeAnswer(p[q.id], correct);
    app.store.setProgress(p);
    app.store.recordAnswer(correct);
    setState(() {
      answers[idx] = picked;
      if (!correct) {
        final at = requeuePosition(idx, queue.length);
        queue.insert(at, q);
        answers.insert(at, null);
      }
    });
  }

  void _next() {
    setState(() {
      if (idx < queue.length - 1) {
        idx += 1;
      } else if (allAnswered) {
        finished = true;
      } else {
        // reached the end with skipped cards — jump to the first open one
        idx = answers.indexWhere((a) => a == null);
      }
    });
  }

  void _again() {
    _start(buildSession(app.pool, app.store.getProgress()));
  }

  void _drillMistakes() {
    final qs = [...mistakes]..shuffle();
    _start(qs);
  }

  String get _finishMessage {
    final pct = answeredCount > 0 ? rightCount / answeredCount : 1.0;
    if (pct == 1) return 'Perfekte Runde!';
    if (pct >= 0.7) return 'Gut gemacht – weiter so.';
    return 'Schwere Fragen kommen in den nächsten Runden zurück.';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.close, color: c.muted),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: queue.isEmpty ? 0 : answeredCount / queue.length,
                    minHeight: 8,
                    backgroundColor: c.line,
                    valueColor: AlwaysStoppedAnimation(c.gold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(idx + 1) > queue.length ? queue.length : idx + 1}/${queue.length}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.muted),
              ),
            ]),
          ),
          if (!finished) _numberStrip(c),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: finished ? _finishView(c) : _questionView(),
              ),
            ),
          ),
          if (!finished) _navBar(c),
        ]),
      ),
    );
  }

  Widget _numberStrip(AppColors c) => SizedBox(
        height: 42,
        child: ListView.separated(
          controller: _stripCtrl,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          itemCount: queue.length,
          separatorBuilder: (_, i) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final a = answers[i];
            final Color border, fg;
            Color? bg;
            if (a == null) {
              border = c.line;
              fg = c.muted;
            } else if (a == queue[i].correct) {
              border = c.green;
              fg = c.green;
              bg = c.greenSoft;
            } else {
              border = c.red;
              fg = c.red;
              bg = c.redSoft;
            }
            return InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => setState(() => idx = i),
              child: Container(
                width: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  border: Border.all(color: i == idx ? c.gold : border, width: i == idx ? 2 : 1.5),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text('${i + 1}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
              ),
            );
          },
        ),
      );

  Widget _navBar(AppColors c) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: SafeArea(
          top: false,
          child: Row(children: [
            Expanded(
              child: AppButton('← Zurück',
                  variant: 'outline', onTap: idx == 0 ? null : () => setState(() => idx -= 1)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                idx >= queue.length - 1 && allAnswered ? 'Fertig ✓' : 'Weiter →',
                onTap: answers.isNotEmpty && answers[idx] == null ? null : _next,
              ),
            ),
          ]),
        ),
      );

  Widget _questionView() {
    final q = current;
    if (q == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: QuestionCard(
        key: ValueKey('${q.id}-$idx'),
        q: q,
        mode: 'study',
        controlled: true,
        answered: answers[idx],
        onAnswer: _onAnswer,
      ),
    );
  }

  Widget _finishView(AppColors c) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(children: [
          Text('$rightCount/$answeredCount',
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: 10),
          Text(_finishMessage, style: TextStyle(color: c.muted)),
          const SizedBox(height: 20),
          if (mistakes.isNotEmpty) ...[
            AppButton('Fehler jetzt üben (${mistakes.length})', onTap: _drillMistakes),
            const SizedBox(height: 10),
          ],
          AppButton('Nächste Runde',
              variant: mistakes.isNotEmpty ? 'outline' : 'primary', onTap: _again),
          const SizedBox(height: 10),
          AppButton('Antworten ansehen',
              variant: 'outline', onTap: () => setState(() => finished = false)),
          const SizedBox(height: 10),
          AppButton('Fertig für jetzt', variant: 'outline', onTap: () => Navigator.of(context).pop()),
        ]),
      );
}
