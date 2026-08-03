// Study round — ported from app/components/StudyOverlay.vue.
// Missed questions requeue kRequeueGap cards later within the round.
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
  int idx = 0;
  int right = 0;
  int answered = 0;
  bool showNext = false;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    queue = widget.list != null
        ? [...widget.list!]
        : buildSession(app.pool, app.store.getProgress());
    if (queue.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showToast(context, 'Nichts fällig – alles gelernt! 🎉');
        Navigator.of(context).pop();
      });
    }
  }

  Question? get current => idx < queue.length ? queue[idx] : null;

  void _onAnswer(bool correct) {
    final q = current!;
    final p = app.store.getProgress();
    p[q.id] = gradeAnswer(p[q.id], correct);
    app.store.setProgress(p);
    app.store.recordAnswer(correct);
    setState(() {
      answered += 1;
      if (correct) {
        right += 1;
      } else {
        final at = idx + 1 + kRequeueGap;
        queue.insert(at < queue.length ? at : queue.length, q);
      }
      showNext = true;
    });
  }

  void _next() {
    setState(() {
      showNext = false;
      idx += 1;
      if (idx >= queue.length) finished = true;
    });
  }

  void _again() {
    setState(() {
      queue = buildSession(app.pool, app.store.getProgress());
      idx = 0;
      right = 0;
      answered = 0;
      finished = false;
    });
    if (queue.isEmpty) {
      showToast(context, 'Nichts fällig – alles gelernt! 🎉');
      Navigator.of(context).pop();
    }
  }

  String get _finishMessage {
    final pct = answered > 0 ? right / answered : 1.0;
    if (pct == 1) return 'Perfekte Runde!';
    if (pct >= 0.7) return 'Gut gemacht – weiter so.';
    return 'Schwere Fragen kommen in der nächsten Runde zuerst.';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.close, color: c.muted),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: finished ? 1 : (queue.isEmpty ? 0 : idx / queue.length),
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
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: finished ? _finishView(c) : _questionView(),
              ),
            ),
          ),
          if (showNext && !finished)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: c.card,
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: SafeArea(top: false, child: AppButton('Weiter', onTap: _next)),
            ),
        ]),
      ),
    );
  }

  Widget _questionView() {
    final q = current;
    if (q == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: QuestionCard(
        key: ValueKey('${q.id}-$idx'),
        q: q,
        mode: 'study',
        onAnswer: _onAnswer,
      ),
    );
  }

  Widget _finishView(AppColors c) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(children: [
          Text('$right/$answered',
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: 10),
          Text(_finishMessage, style: TextStyle(color: c.muted)),
          const SizedBox(height: 20),
          AppButton('Nächste Runde', onTap: _again),
          const SizedBox(height: 10),
          AppButton('Fertig für jetzt', variant: 'outline', onTap: () => Navigator.of(context).pop()),
        ]),
      );
}
