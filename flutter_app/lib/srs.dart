// Spaced repetition — Leitner tuned for a short runway to the exam.
// Ported 1:1 from the PWA (app/composables/useSrs.ts); keep both in sync.
//
// Boxes: 0 = new, 1 = wrong/relearning, 2..4 = learning, 5 = mastered.
// First-sight-correct jumps straight to box 4 ("triage"): time goes to the
// unknown questions, not to re-confirming common sense.
import 'dart:math';

import 'models.dart';

// TUNING POINT: the intervals are the levers of the whole system.
const Map<int, double> _intervalsH = {
  1: 0.15, // wrong → again in ~10 min
  2: 8,
  3: 24,
  4: 48,
  5: 24 * 30, // mastered — out of rotation before the exam
};

const int _hourMs = 3600 * 1000;

// One learning round; same algorithm every round, do as many as time allows.
const int kRoundSize = 30;
// A missed question comes back at least this many cards later in the same
// round, at a random position after that.
const int kRequeueGap = 5;

// Where a just-missed question re-enters the queue: uniformly random between
// kRequeueGap cards ahead and the end, so its return is never predictable.
int requeuePosition(int idx, int len, {Random? rng}) {
  final lo = (idx + 1 + kRequeueGap) < len ? (idx + 1 + kRequeueGap) : len;
  return lo + (rng ?? Random()).nextInt(len - lo + 1);
}

int _now() => DateTime.now().millisecondsSinceEpoch;

ProgressEntry gradeAnswer(ProgressEntry? entry, bool correct, {int? now}) {
  final e = entry ?? ProgressEntry();
  e.seen += 1;
  if (correct) {
    e.right += 1;
    e.box = e.seen == 1 ? 4 : (e.box < 1 ? 2 : (e.box + 1 > 5 ? 5 : e.box + 1));
  } else {
    e.wrong += 1;
    e.box = 1;
  }
  e.due = (now ?? _now()) + ((_intervalsH[e.box] ?? 24) * _hourMs).round();
  return e;
}

class Queues {
  final List<Question> due;
  final List<Question> fresh;
  const Queues(this.due, this.fresh);
}

Queues queueFor(List<Question> questions, Map<String, ProgressEntry> progress, {int? now}) {
  final t = now ?? _now();
  final due = <Question>[];
  final fresh = <Question>[];
  for (final q in questions) {
    final e = progress[q.id];
    if (e == null || e.seen == 0) {
      fresh.add(q);
    } else if (e.box < 5 && e.due <= t) {
      due.add(q);
    }
  }
  // weakest first: lower box, then more lapses, then longest overdue
  due.sort((a, b) {
    final ea = progress[a.id]!, eb = progress[b.id]!;
    if (ea.box != eb.box) return ea.box - eb.box;
    if (ea.wrong != eb.wrong) return eb.wrong - ea.wrong;
    return ea.due - eb.due;
  });
  return Queues(due, fresh);
}

// Coverage first: every question should be SEEN once before review time is
// spent — unseen questions fill the round first, due reviews (weakest first)
// fill whatever room is left. Missed questions still repeat within the round,
// and once the catalog is exhausted rounds become pure weakest-first review.
//
// The fresh pool is shuffled BEFORE slicing: the catalog is grouped by topic,
// so catalog order would serve monotopic rounds. A uniform shuffle samples
// categories proportionally to what's left. Due questions keep weakest-first
// SELECTION (which ones get in), then the whole round is shuffled for
// presentation so hard reviews interleave instead of front-loading.
List<Question> buildSession(List<Question> questions, Map<String, ProgressEntry> progress,
    {int size = kRoundSize, int? now, Random? rng}) {
  final r = rng ?? Random();
  final q = queueFor(questions, progress, now: now);
  final session = (q.fresh..shuffle(r)).take(size).toList();
  if (session.length < size) {
    session.addAll(q.due.take(size - session.length));
  }
  return session..shuffle(r);
}

class Summary {
  int newCount = 0, learning = 0, mastered = 0, wrong = 0, total = 0;
}

Summary summarize(List<Question> questions, Map<String, ProgressEntry> progress) {
  final s = Summary()..total = questions.length;
  for (final q in questions) {
    final e = progress[q.id];
    if (e == null || e.seen == 0) {
      s.newCount += 1;
    } else if (e.box >= 5) {
      s.mastered += 1;
    } else {
      s.learning += 1;
      if (e.box == 1) s.wrong += 1;
    }
  }
  return s;
}

int dueCount(List<Question> questions, Map<String, ProgressEntry> progress, {int? now}) =>
    queueFor(questions, progress, now: now).due.length;

class DailyTarget {
  final int perDay;
  final int daysLeft;
  const DailyTarget(this.perDay, this.daysLeft);
}

DailyTarget dailyTarget(int newCount, String examDate, {int? now}) {
  final t = now ?? _now();
  final exam = DateTime.parse('${examDate}T09:00:00');
  final msLeft = exam.millisecondsSinceEpoch - t;
  final daysLeft = (msLeft / (24 * 3600 * 1000)).ceil();
  final d = daysLeft < 1 ? 1 : daysLeft;
  return DailyTarget((newCount / d).ceil(), d);
}

// A "leech" keeps failing despite repetition — flag it for conscious study.
bool isLeech(ProgressEntry? entry) => entry != null && entry.wrong >= 4;
