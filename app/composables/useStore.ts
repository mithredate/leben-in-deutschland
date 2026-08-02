// Persistence layer — localStorage only, no backend. Keys and schema are
// IDENTICAL to the pre-Nuxt vanilla version so existing progress survives
// the stack migration.

export interface ProgressEntry {
  box: number
  due: number
  seen: number
  right: number
  wrong: number
}

export interface Settings {
  state: string | null
  lang: 'en' | 'de'
  examDate: string
  theme: 'auto' | 'light' | 'dark'
}

export interface ExamRecord {
  date: string
  score: number
  total: number
  passedLid: boolean
  passedEinb: boolean
}

const K = {
  settings: 'lid.settings.v1',
  progress: 'lid.progress.v1',
  stats: 'lid.stats.v1',
  exams: 'lid.exams.v1',
  lastSaved: 'lid.lastSaved.v1',
}

function read<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key)
    return raw ? (JSON.parse(raw) as T) : fallback
  } catch {
    return fallback
  }
}

export const useStore = () => {
  const toast = useToast()

  function write(key: string, value: unknown) {
    try {
      localStorage.setItem(key, JSON.stringify(value))
      localStorage.setItem(K.lastSaved, JSON.stringify(Date.now()))
    } catch {
      toast.show('⚠️ Speichern fehlgeschlagen – Privatmodus aktiv?')
    }
  }

  const defaultExam = () => new Date(Date.now() + 14 * 24 * 3600 * 1000).toISOString().slice(0, 10)

  const getSettings = (): Settings => ({
    theme: 'auto',
    ...read<Partial<Settings>>(K.settings, { state: null, lang: 'en', examDate: defaultExam() }),
  }) as Settings

  const patchSettings = (patch: Partial<Settings>) => write(K.settings, { ...getSettings(), ...patch })

  const getProgress = () => read<Record<string, ProgressEntry>>(K.progress, {})
  const setProgress = (p: Record<string, ProgressEntry>) => write(K.progress, p)

  const getStats = () => read<{ days: Record<string, { answered: number; correct: number }> }>(K.stats, { days: {} })

  const getExams = () => read<ExamRecord[]>(K.exams, [])
  const addExam = (e: ExamRecord) => write(K.exams, [...getExams(), e])

  function recordAnswer(correct: boolean, now = Date.now()) {
    const day = new Date(now).toISOString().slice(0, 10)
    const stats = getStats()
    const d = stats.days[day] || { answered: 0, correct: 0 }
    d.answered += 1
    if (correct) d.correct += 1
    stats.days[day] = d
    write(K.stats, stats)
  }

  function answeredToday(now = Date.now()) {
    const day = new Date(now).toISOString().slice(0, 10)
    return (getStats().days[day] || { answered: 0 }).answered
  }

  function streak(now = Date.now()) {
    const days = getStats().days
    let n = 0
    const d = new Date(now)
    for (;;) {
      const key = d.toISOString().slice(0, 10)
      if ((days[key] || { answered: 0 }).answered > 0) {
        n += 1
        d.setDate(d.getDate() - 1)
      } else {
        if (n === 0 && key === new Date(now).toISOString().slice(0, 10)) {
          d.setDate(d.getDate() - 1)
          continue
        }
        break
      }
    }
    return n
  }

  function exportAll(): string {
    return JSON.stringify({
      version: 1,
      exportedAt: new Date().toISOString(),
      settings: getSettings(),
      progress: getProgress(),
      stats: getStats(),
      exams: getExams(),
    })
  }

  function importAll(json: string) {
    const data = JSON.parse(json)
    if (!data || data.version !== 1) throw new Error('Unbekanntes Format')
    if (data.settings) write(K.settings, data.settings)
    if (data.progress) write(K.progress, data.progress)
    if (data.stats) write(K.stats, data.stats)
    if (data.exams) write(K.exams, data.exams)
  }

  function resetProgress() {
    localStorage.removeItem(K.progress)
    localStorage.removeItem(K.stats)
    localStorage.removeItem(K.exams)
  }

  async function storageHealth() {
    const seen = Object.values(getProgress()).filter((e) => e.seen > 0).length
    let persisted: boolean | null = null
    try {
      if (navigator.storage?.persisted) persisted = await navigator.storage.persisted()
    } catch { /* unsupported */ }
    return { seen, persisted, lastSaved: read<number | null>(K.lastSaved, null) }
  }

  return {
    getSettings, patchSettings, getProgress, setProgress,
    getExams, addExam, recordAnswer, answeredToday, streak,
    exportAll, importAll, resetProgress, storageHealth,
  }
}
