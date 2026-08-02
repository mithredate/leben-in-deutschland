// Persistence layer — everything lives in localStorage, no backend.
// Keys are versioned so future schema changes can migrate cleanly.

const K = {
  settings: 'lid.settings.v1',
  progress: 'lid.progress.v1',
  stats: 'lid.stats.v1',
  exams: 'lid.exams.v1',
};

function read(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    return raw ? JSON.parse(raw) : fallback;
  } catch {
    return fallback;
  }
}

function write(key, value) {
  localStorage.setItem(key, JSON.stringify(value));
}

export const store = {
  get settings() {
    const defaultExam = new Date(Date.now() + 14 * 24 * 3600 * 1000).toISOString().slice(0, 10);
    return { theme: 'auto', ...read(K.settings, { state: null, lang: 'en', examDate: defaultExam }) };
  },
  set settings(s) {
    write(K.settings, s);
  },
  patchSettings(patch) {
    this.settings = { ...this.settings, ...patch };
  },

  // progress: { [questionId]: {box, due, seen, right, wrong} }
  get progress() {
    return read(K.progress, {});
  },
  set progress(p) {
    write(K.progress, p);
  },

  // stats: { days: { 'YYYY-MM-DD': {answered, correct} } }
  get stats() {
    return read(K.stats, { days: {} });
  },
  set stats(s) {
    write(K.stats, s);
  },

  get exams() {
    return read(K.exams, []);
  },
  set exams(e) {
    write(K.exams, e);
  },

  recordAnswer(qid, correct, now = Date.now()) {
    const day = new Date(now).toISOString().slice(0, 10);
    const stats = this.stats;
    const d = stats.days[day] || { answered: 0, correct: 0 };
    d.answered += 1;
    if (correct) d.correct += 1;
    stats.days[day] = d;
    this.stats = stats;
  },

  answeredToday(now = Date.now()) {
    const day = new Date(now).toISOString().slice(0, 10);
    return (this.stats.days[day] || { answered: 0 }).answered;
  },

  streak(now = Date.now()) {
    const days = this.stats.days;
    let n = 0;
    const d = new Date(now);
    for (;;) {
      const key = d.toISOString().slice(0, 10);
      if ((days[key] || {}).answered > 0) {
        n += 1;
        d.setDate(d.getDate() - 1);
      } else {
        // today without answers yet doesn't break the streak
        if (n === 0 && key === new Date(now).toISOString().slice(0, 10)) {
          d.setDate(d.getDate() - 1);
          continue;
        }
        break;
      }
    }
    return n;
  },

  exportAll() {
    return JSON.stringify({
      version: 1,
      exportedAt: new Date().toISOString(),
      settings: this.settings,
      progress: this.progress,
      stats: this.stats,
      exams: this.exams,
    });
  },

  importAll(json) {
    const data = JSON.parse(json);
    if (!data || data.version !== 1) throw new Error('Unbekanntes Format');
    if (data.settings) this.settings = data.settings;
    if (data.progress) this.progress = data.progress;
    if (data.stats) this.stats = data.stats;
    if (data.exams) this.exams = data.exams;
  },

  resetProgress() {
    localStorage.removeItem(K.progress);
    localStorage.removeItem(K.stats);
    localStorage.removeItem(K.exams);
  },
};
