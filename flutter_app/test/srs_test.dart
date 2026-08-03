// Parity tests for the SRS engine — mirrors the behavior documented in the
// PWA's app/composables/useSrs.ts. If these fail after an edit, web and app
// scheduling have diverged.
import 'package:flutter_test/flutter_test.dart';
import 'package:lid_trainer/models.dart';
import 'package:lid_trainer/srs.dart';

Question q(String id, {String? state}) => Question(
      id: id,
      num: id,
      state: state,
      category: 'Test',
      question: 'Q$id',
      answers: const ['a', 'b', 'c', 'd'],
      correct: 0,
      image: null,
      en: const QuestionEn(),
      explanationDe: null,
      src: null,
    );

void main() {
  const now = 1000000000000;

  group('gradeAnswer', () {
    test('first-sight correct jumps to box 4 (triage)', () {
      final e = gradeAnswer(null, true, now: now);
      expect(e.box, 4);
      expect(e.seen, 1);
      expect(e.right, 1);
      expect(e.due, now + 48 * 3600 * 1000);
    });

    test('wrong always drops to box 1, due in ~10 min', () {
      final e = gradeAnswer(ProgressEntry(box: 4, seen: 3), false, now: now);
      expect(e.box, 1);
      expect(e.due, now + (0.15 * 3600 * 1000).round());
    });

    test('repeat correct climbs one box, capped at 5', () {
      final e = gradeAnswer(ProgressEntry(box: 4, seen: 2), true, now: now);
      expect(e.box, 5);
      final e2 = gradeAnswer(e, true, now: now);
      expect(e2.box, 5);
    });

    test('correct after wrong climbs from box 1 to 2', () {
      final e = gradeAnswer(ProgressEntry(box: 1, seen: 1, wrong: 1), true, now: now);
      expect(e.box, 2);
    });

    test('box 0 with prior seen climbs to 2 like the PWA (box||1)+1', () {
      final e = gradeAnswer(ProgressEntry(box: 0, seen: 2), true, now: now);
      expect(e.box, 2);
    });
  });

  group('buildSession', () {
    test('coverage first: unseen fill the round before due reviews', () {
      final questions = [for (var i = 0; i < 40; i++) q('$i')];
      final progress = {
        // 5 due reviews
        for (var i = 0; i < 5; i++)
          '$i': ProgressEntry(box: 2, due: now - 1000, seen: 1, right: 1),
      };
      final session =
          buildSession(questions, progress, size: kRoundSize, now: now);
      expect(session.length, kRoundSize);
      // 35 unseen fill first — all 30 slots go to fresh questions
      expect(session.every((x) => progress[x.id] == null), isTrue);
    });

    test('due reviews sorted weakest first: box, then lapses, then overdue', () {
      final questions = [q('a'), q('b'), q('c')];
      final progress = {
        'a': ProgressEntry(box: 3, due: now - 10, seen: 2, right: 2),
        'b': ProgressEntry(box: 1, due: now - 10, seen: 3, wrong: 1),
        'c': ProgressEntry(box: 1, due: now - 10, seen: 5, wrong: 4),
      };
      final r = queueFor(questions, progress, now: now);
      expect(r.due.map((x) => x.id).toList(), ['c', 'b', 'a']);
    });

    test('mastered (box 5) never re-enters the queue', () {
      final questions = [q('a')];
      final progress = {'a': ProgressEntry(box: 5, due: now - 10, seen: 2, right: 2)};
      final r = queueFor(questions, progress, now: now);
      expect(r.due, isEmpty);
      expect(r.fresh, isEmpty);
    });
  });

  group('summarize / dailyTarget', () {
    test('categorizes new, learning, wrong, mastered', () {
      final questions = [q('a'), q('b'), q('c'), q('d')];
      final progress = {
        'b': ProgressEntry(box: 1, seen: 1, wrong: 1),
        'c': ProgressEntry(box: 3, seen: 2, right: 2),
        'd': ProgressEntry(box: 5, seen: 2, right: 2),
      };
      final s = summarize(questions, progress);
      expect(s.newCount, 1);
      expect(s.learning, 2);
      expect(s.wrong, 1);
      expect(s.mastered, 1);
    });

    test('dailyTarget divides new questions across remaining days', () {
      final examDate = DateTime.fromMillisecondsSinceEpoch(now)
          .add(const Duration(days: 5))
          .toIso8601String()
          .substring(0, 10);
      final t = dailyTarget(50, examDate, now: now);
      expect(t.perDay, (50 / t.daysLeft).ceil());
      expect(t.daysLeft, greaterThanOrEqualTo(4));
    });
  });

  test('isLeech at 4+ lapses', () {
    expect(isLeech(ProgressEntry(wrong: 3)), isFalse);
    expect(isLeech(ProgressEntry(wrong: 4)), isTrue);
    expect(isLeech(null), isFalse);
  });
}
