// Reactive glue over the imperative localStorage layer: `settings` is a
// reactive mirror persisted on change, `rev` invalidates progress-derived
// computeds after every answer.
import type { Settings } from './useStore'

export const useApp = () => {
  const store = useStore()

  const settings = useState<Settings>('settings', () => store.getSettings())
  const rev = useState<number>('progress-rev', () => 0)
  const tab = useState<'home' | 'browse' | 'exam' | 'more'>('tab', () => 'home')

  function patchSettings(patch: Partial<Settings>) {
    store.patchSettings(patch)
    settings.value = store.getSettings()
    applyTheme()
  }

  function bump() {
    rev.value += 1
  }

  function applyTheme() {
    const theme = settings.value.theme
    const root = document.documentElement
    if (theme === 'light' || theme === 'dark') root.dataset.theme = theme
    else delete root.dataset.theme
    const dark = theme === 'dark'
      || (theme !== 'light' && window.matchMedia('(prefers-color-scheme: dark)').matches)
    document.querySelector('meta[name="theme-color"]')?.setAttribute('content', dark ? '#141418' : '#fafaf7')
  }

  return { store, settings, patchSettings, rev, bump, tab, applyTheme }
}
