// Spaced repetition — Leitner tuned for a short runway to the exam.
// Ported 1:1 from the vanilla version; see README for the research notes.
//
// Boxes: 0 = new, 1 = wrong/relearning, 2..4 = learning, 5 = mastered.
// First-sight-correct jumps straight to box 4 ("triage"): time goes to the
// unknown questions, not to re-confirming common sense.
import type { ProgressEntry } from './useStore'
import type { Question } from './useQuestions'

// TUNING POINT: the intervals are the levers of the whole system.
const INTERVALS_H: Record<number, number> = {
  1: 0.15, // wrong → again in ~10 min
  2: 8,
  3: 24,
  4: 48,
  5: 24 * 30, // mastered — out of rotation before the exam
}

const H = 3600 * 1000

// One learning round; same algorithm every round, do as many as time allows.
export const ROUND_SIZE = 30
// A missed question comes back this many cards later in the same round.
export const REQUEUE_GAP = 5

export function gradeAnswer(entry: ProgressEntry | undefined, correct: boolean, now = Date.now()): ProgressEntry {
  const e = entry || { box: 0, due: 0, seen: 0, right: 0, wrong: 0 }
  e.seen += 1
  if (correct) {
    e.right += 1
    e.box = e.seen === 1 ? 4 : Math.min(5, (e.box || 1) + 1)
  } else {
    e.wrong += 1
    e.box = 1
  }
  e.due = now + (INTERVALS_H[e.box] ?? 24) * H
  return e
}

export function queueFor(questions: Question[], progress: Record<string, ProgressEntry>, now = Date.now()) {
  const due: Question[] = []
  const fresh: Question[] = []
  for (const q of questions) {
    const e = progress[q.id]
    if (!e || e.seen === 0) fresh.push(q)
    else if (e.box < 5 && e.due <= now) due.push(q)
  }
  // weakest first: lower box, then more lapses, then longest overdue
  due.sort((a, b) => {
    const ea = progress[a.id]!, eb = progress[b.id]!
    return ea.box - eb.box || eb.wrong - ea.wrong || ea.due - eb.due
  })
  return { due, fresh }
}

// Coverage first: every question should be SEEN once before review time is
// spent — unseen questions fill the round first, due reviews (weakest first)
// fill whatever room is left. Missed questions still repeat within the round,
// and once the catalog is exhausted rounds become pure weakest-first review.
export function buildSession(questions: Question[], progress: Record<string, ProgressEntry>, size = ROUND_SIZE, now = Date.now()) {
  const { due, fresh } = queueFor(questions, progress, now)
  const session = fresh.slice(0, size)
  if (session.length < size) session.push(...due.slice(0, size - session.length))
  return session
}

export function summarize(questions: Question[], progress: Record<string, ProgressEntry>) {
  const s = { new: 0, learning: 0, mastered: 0, wrong: 0, total: questions.length }
  for (const q of questions) {
    const e = progress[q.id]
    if (!e || e.seen === 0) s.new += 1
    else if (e.box >= 5) s.mastered += 1
    else {
      s.learning += 1
      if (e.box === 1) s.wrong += 1
    }
  }
  return s
}

export function dueCount(questions: Question[], progress: Record<string, ProgressEntry>, now = Date.now()) {
  return queueFor(questions, progress, now).due.length
}

export function dailyTarget(summary: { new: number }, examDate: string, now = Date.now()) {
  const msLeft = new Date(examDate + 'T09:00:00').getTime() - now
  const daysLeft = Math.max(1, Math.ceil(msLeft / (24 * 3600 * 1000)))
  return { perDay: Math.ceil(summary.new / daysLeft), daysLeft }
}

// A "leech" keeps failing despite repetition — flag it for conscious study.
export function isLeech(entry: ProgressEntry | undefined) {
  return !!entry && entry.wrong >= 4
}
