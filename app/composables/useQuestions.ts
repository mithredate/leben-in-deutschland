export interface Question {
  id: string
  num: string
  state: string | null
  category: string
  question: string
  answers: string[]
  correct: number
  image: string | null
  en: { question: string | null; answers: (string | null)[]; explanation: string | null }
  explanation_de: string | null
  src?: { t: string; u: string }
}

export const STATES: Record<string, string> = {
  BW: 'Baden-Württemberg', BY: 'Bayern', BE: 'Berlin', BB: 'Brandenburg',
  HB: 'Bremen', HH: 'Hamburg', HE: 'Hessen', MV: 'Mecklenburg-Vorpommern',
  NI: 'Niedersachsen', NW: 'Nordrhein-Westfalen', RP: 'Rheinland-Pfalz',
  SL: 'Saarland', SN: 'Sachsen', ST: 'Sachsen-Anhalt',
  SH: 'Schleswig-Holstein', TH: 'Thüringen',
}

export const PASS = { lid: 15, einbuergerung: 17 }

export const useQuestions = () => {
  const questions = useState<Question[]>('questions', () => [])
  const baseURL = useRuntimeConfig().app.baseURL

  async function load() {
    if (questions.value.length) return
    const res = await fetch(`${baseURL}data/questions.json`)
    questions.value = await res.json()
  }

  const imgUrl = (file: string) => `${baseURL}img/${file}`

  return { questions, load, imgUrl }
}
