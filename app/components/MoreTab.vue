<script setup lang="ts">
import { STATES } from '~/composables/useQuestions'
const { store, settings, patchSettings, rev, bump } = useApp()
const toast = useToast()

const fileInput = ref<HTMLInputElement>()
const health = ref<{ seen: number; persisted: boolean | null; lastSaved: number | null } | null>(null)

onMounted(refreshHealth)
watch(rev, refreshHealth)

async function refreshHealth() {
  health.value = await store.storageHealth()
}

const lastSavedLabel = computed(() =>
  health.value?.lastSaved
    ? new Date(health.value.lastSaved).toLocaleString('de-DE', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })
    : '–',
)

function exportAll() {
  const blob = new Blob([store.exportAll()], { type: 'application/json' })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = `lid-fortschritt-${new Date().toISOString().slice(0, 10)}.json`
  a.click()
  URL.revokeObjectURL(a.href)
}

async function importFile() {
  const f = fileInput.value?.files?.[0]
  if (!f) return
  try {
    store.importAll(await f.text())
    bump()
    toast.show('Fortschritt importiert ✓')
  } catch {
    toast.show('Import fehlgeschlagen')
  }
}

function reset() {
  if (confirm('Wirklich den gesamten Lernfortschritt löschen?')) {
    store.resetProgress()
    bump()
    toast.show('Zurückgesetzt')
  }
}

const inputCls = 'mt-1.5 min-h-[46px] w-full appearance-none rounded-xl border-[1.5px] border-line bg-card px-3 py-2.5 font-normal text-ink'
const cardCls = 'mb-3.5 rounded-app border border-line bg-card p-4'
const infoCls = 'ml-4.5 list-disc text-[14.5px] [&_li]:mb-2'
</script>

<template>
  <div>
    <header class="mb-4">
      <p class="text-xs font-bold uppercase tracking-widest text-muted">Einstellungen &amp; Wissen</p>
      <h1 class="text-3xl font-extrabold tracking-tight">Mehr</h1>
    </header>

    <section :class="cardCls">
      <h2 class="mb-2.5 font-bold">Einstellungen</h2>
      <label class="mb-3 block text-[13px] font-bold text-muted">Bundesland
        <select :value="settings.state || ''" :class="inputCls" @change="patchSettings({ state: ($event.target as HTMLSelectElement).value }); toast.show('Bundesland gespeichert')">
          <option v-for="(name, code) in STATES" :key="code" :value="code">{{ name }}</option>
        </select>
      </label>
      <label class="mb-3 block text-[13px] font-bold text-muted">Erklärungen
        <select :value="settings.lang" :class="inputCls" @change="patchSettings({ lang: ($event.target as HTMLSelectElement).value as 'en' | 'de' })">
          <option value="en">Englisch</option>
          <option value="de">Deutsch</option>
        </select>
      </label>
      <label class="mb-3 block text-[13px] font-bold text-muted">Prüfungsdatum
        <input type="date" :value="settings.examDate" :class="inputCls" @change="patchSettings({ examDate: ($event.target as HTMLInputElement).value })">
      </label>
      <label class="block text-[13px] font-bold text-muted">Design
        <select :value="settings.theme" :class="inputCls" @change="patchSettings({ theme: ($event.target as HTMLSelectElement).value as 'auto' | 'light' | 'dark' })">
          <option value="auto">Wie System</option>
          <option value="light">Hell</option>
          <option value="dark">Dunkel</option>
        </select>
      </label>
    </section>

    <section :class="cardCls">
      <h2 class="mb-2.5 font-bold">So läuft die Prüfung</h2>
      <ul :class="infoCls">
        <li><b>33 Fragen</b>, Mehrfachauswahl, genau eine Antwort richtig.</li>
        <li><b>60 Minuten</b> Zeit – die meisten sind nach 15–20 Minuten fertig.</li>
        <li>30 Fragen aus dem Katalog (300) + 3 aus deinem Bundesland (10).</li>
        <li>Für die <b>Niederlassungserlaubnis</b> („Leben in Deutschland“): <b>15 richtige</b> reichen.</li>
        <li>Für die <b>Einbürgerung</b> zählt dieselbe Prüfung ab <b>17 richtigen</b> – schaffst du 17+, ist das Zertifikat später auch dafür gültig.</li>
        <li>Mitbringen: <b>Ausweis/Pass</b> und die Einladung. Handy bleibt aus.</li>
        <li>Es gibt keine Minuspunkte – <b>nie eine Frage offen lassen</b>, im Zweifel raten.</li>
      </ul>
    </section>

    <section :class="cardCls">
      <h2 class="mb-2.5 font-bold">Merkhilfen – die Zahlen, die immer drankommen</h2>
      <ul :class="infoCls">
        <li><b>1949</b> Grundgesetz · <b>1961</b> Mauerbau · <b>9. Nov 1989</b> Mauerfall · <b>3. Okt 1990</b> Wiedervereinigung (Feiertag!) · <b>8. Mai 1945</b> Kriegsende</li>
        <li><b>16</b> Bundesländer · Bundestagswahl alle <b>4 Jahre</b> · wählen ab <b>18</b> · Schulpflicht ab <b>6</b></li>
        <li>Bundeskanzler/in wird vom <b>Bundestag</b> gewählt; Staatsoberhaupt ist der/die <b>Bundespräsident/in</b> (gewählt von der Bundesversammlung)</li>
        <li>Gewaltenteilung: <b>Legislative</b> (Parlament) · <b>Exekutive</b> (Regierung/Polizei) · <b>Judikative</b> (Gerichte). „Direktive“ gibt es nicht!</li>
        <li>Erststimme = <b>Person</b> im Wahlkreis · Zweitstimme = <b>Partei</b> (entscheidet Sitzverteilung) · <b>5%-Hürde</b></li>
        <li>Deutschland: <b>demokratischer + sozialer Bundesstaat</b> · Rechtsstaat = <b>Staat ist an Gesetze gebunden</b></li>
        <li><b>9 Nachbarländer</b> (u.a. Polen, Dänemark, Luxemburg, Tschechien, Österreich). Beliebte Fangfrage: die <b>Schweiz</b> ist Nachbar, aber <b>nicht in der EU</b> – Österreich schon.</li>
        <li>Wappen: <b>Bundesadler</b> (gelb/schwarz) = BRD · <b>Hammer &amp; Zirkel im Ährenkranz</b> = DDR · <b>Sterne auf Blau</b> = EU-Flagge</li>
        <li>Sozialversicherung: Kranken-, Pflege-, Renten-, Unfall- und <b>Arbeitslosenversicherung</b> – keine „Autoversicherung“!</li>
      </ul>
    </section>

    <section :class="cardCls">
      <h2 class="mb-2.5 font-bold">Daten</h2>
      <p v-if="health" class="mb-2 text-sm">
        💾 <b>{{ health.seen }}</b> Frage{{ health.seen === 1 ? '' : 'n' }} gespeichert · zuletzt: {{ lastSavedLabel }}
        <span v-if="health.persisted === false" class="text-brand-red"> · Speicher nicht dauerhaft geschützt</span>
        <span v-else-if="health.persisted === true"> · dauerhaft geschützt ✓</span>
      </p>
      <p class="mb-3 rounded-[10px] border border-line bg-paper px-2.5 py-2 text-[12.5px] text-muted">
        Hinweis (iOS): Safari und die installierte Home-Bildschirm-App haben <b>getrennte Speicher</b>.
        Beim Wechsel Fortschritt hier exportieren und dort importieren.
      </p>
      <div class="flex gap-2.5">
        <button class="min-h-[52px] flex-1 rounded-app border-[1.5px] border-line font-bold" @click="exportAll">Fortschritt exportieren</button>
        <button class="min-h-[52px] flex-1 rounded-app border-[1.5px] border-line font-bold" @click="fileInput?.click()">Importieren</button>
      </div>
      <input ref="fileInput" type="file" accept="application/json" class="hidden" @change="importFile">
      <button class="mt-2.5 block min-h-[52px] w-full rounded-app border-[1.5px] border-brand-red font-bold text-brand-red" @click="reset">
        Fortschritt zurücksetzen
      </button>
    </section>

    <section :class="cardCls">
      <h2 class="mb-2.5 font-bold">Über</h2>
      <p class="text-[13.5px] text-muted">
        Open Source, ohne Server – alles bleibt auf deinem Gerät. Fragenkatalog: BAMF „Gesamtfragenkatalog
        Leben in Deutschland / Einbürgerungstest“ (Stand 05/2025), aufbereitet aus
        <a href="https://github.com/flexsurfer/einburgerungstest" target="_blank" rel="noopener" class="text-brand-red underline">flexsurfer/einburgerungstest</a> und
        <a href="https://github.com/leben-in-deutschland/leben-in-deutschland-scrapper" target="_blank" rel="noopener" class="text-brand-red underline">leben-in-deutschland</a>
        (beide MIT). Erklärungen KI-erstellt mit Quellenangabe, ohne Gewähr.
      </p>
    </section>
  </div>
</template>
