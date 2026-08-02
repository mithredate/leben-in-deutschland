// Spaced repetition — a Leitner system tuned for a short runway to the exam.
//
// Boxes: 0 = new (never seen), 1 = wrong/relearning, 2..4 = learning, 5 = mastered.
// A question you get right on FIRST sight jumps straight to box 4 ("triage"):
// with ~310 questions and days to go, time must be spent on the unknown ones,
// not on re-confirming common sense.
//
// TUNING POINT: the intervals below are the levers of the whole system.
// Feel free to adjust — e.g. with more days before the exam, stretch them
// toward classic Leitner (1d/2d/4d/8d).
const INTERVALS_H = {
  1: 0.15, // wrong → see again in ~10 min (same session)
  2: 8,    // hours
  3: 24,
  4: 48,
  5: 24 * 30, // mastered — effectively out of rotation before the exam
};

const H = 3600 * 1000;

export function gradeAnswer(entry, correct, now = Date.now()) {
  const e = entry || { box: 0, due: 0, seen: 0, right: 0, wrong: 0 };
  e.seen += 1;
  if (correct) {
    e.right += 1;
    e.box = e.seen === 1 ? 4 : Math.min(5, (e.box || 1) + 1);
  } else {
    e.wrong += 1;
    e.box = 1;
  }
  e.due = now + INTERVALS_H[e.box] * H;
  return e;
}

export function queueFor(questions, progress, now = Date.now()) {
  const due = [];
  const fresh = [];
  for (const q of questions) {
    const e = progress[q.id];
    if (!e || e.seen === 0) fresh.push(q);
    else if (e.box < 5 && e.due <= now) due.push([e.due, q]);
  }
  // overdue first (oldest due date first), then new questions in catalog order
  due.sort((a, b) => a[0] - b[0]);
  return { due: due.map(([, q]) => q), fresh };
}

export function buildSession(questions, progress, size = 20, now = Date.now()) {
  const { due, fresh } = queueFor(questions, progress, now);
  const session = due.slice(0, size);
  if (session.length < size) session.push(...fresh.slice(0, size - session.length));
  return session;
}

export function summarize(questions, progress) {
  const s = { new: 0, learning: 0, mastered: 0, wrong: 0, total: questions.length };
  for (const q of questions) {
    const e = progress[q.id];
    if (!e || e.seen === 0) s.new += 1;
    else if (e.box >= 5) s.mastered += 1;
    else {
      s.learning += 1;
      if (e.box === 1) s.wrong += 1;
    }
  }
  return s;
}

export function dueCount(questions, progress, now = Date.now()) {
  return queueFor(questions, progress, now).due.length;
}

// How many NEW questions per day to see everything once before the exam.
export function dailyTarget(summary, examDate, now = Date.now()) {
  const msLeft = new Date(examDate + 'T09:00:00') - now;
  const daysLeft = Math.max(1, Math.ceil(msLeft / (24 * 3600 * 1000)));
  return { perDay: Math.ceil(summary.new / daysLeft), daysLeft };
}
