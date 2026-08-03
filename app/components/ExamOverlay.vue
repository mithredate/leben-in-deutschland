<script setup lang="ts">
import { useQuestions, PASS, type Question } from '~/composables/useQuestions'
import { gradeAnswer } from '~/composables/useSrs'

const emit = defineEmits<{ close: []; drill: [qs: Question[]] }>()

const { questions, imgUrl } = useQuestions()
const { store, settings, bump } = useApp()

const EXAM_MINUTES = 60

function shuffled<T>(arr: T[]): T[] {
  const a = [...arr]
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[a[i], a[j]] = [a[j]!, a[i]!]
  }
  return a
}

const qs = ref<Question[]>([])
const picked = ref<(number | null)[]>([])
const idx = ref(0)
const secondsLeft = ref(EXAM_MINUTES * 60)
const result = ref<null | { score: number; wrong: { q: Question; picked: number | null }[] }>(null)
let timer: ReturnType<typeof setInterval> | null = null

onMounted(() => {
  const general = questions.value.filter((q) => !q.state)
  const state = questions.value.filter((q) => q.state === settings.value.state)
  qs.value = shuffled([...shuffled(general).slice(0, 30), ...shuffled(state).slice(0, 3)])
  picked.value = new Array(qs.value.length).fill(null)
  const deadline = Date.now() + EXAM_MINUTES * 60 * 1000
  timer = setInterval(() => {
    secondsLeft.value = Math.max(0, Math.round((deadline - Date.now()) / 1000))
    if (secondsLeft.value <= 0) submit()
  }, 1000)
})

onUnmounted(() => { if (timer) clearInterval(timer) })

const timeLabel = computed(() => {
  const m = Math.floor(secondsLeft.value / 60)
  const s = secondsLeft.value % 60
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
})

const current = computed(() => qs.value[idx.value])

function pick(i: number) {
  picked.value[idx.value] = i
  if (idx.value < qs.value.length - 1) idx.value += 1
}

const isEn = computed(() => settings.value.lang === 'en')
const t = (de: string, en: string) => (isEn.value ? en : de)

function tryClose() {
  if (result.value || confirm(t('Simulation wirklich abbrechen?', 'Really cancel the simulation?'))) emit('close')
}

function trySubmit() {
  const open = picked.value.filter((p) => p == null).length
  const msg = isEn.value
    ? `${open} question${open === 1 ? '' : 's'} unanswered. Submit anyway?`
    : `${open} Frage${open === 1 ? '' : 'n'} unbeantwortet. Trotzdem abgeben?`
  if (open && !confirm(msg)) return
  submit()
}

function submit() {
  if (result.value) return
  if (timer) clearInterval(timer)
  let score = 0
  const wrong: { q: Question; picked: number | null }[] = []
  const p = store.getProgress()
  qs.value.forEach((q, i) => {
    const ok = picked.value[i] === q.correct
    if (ok) score += 1
    else wrong.push({ q, picked: picked.value[i] ?? null })
    p[q.id] = gradeAnswer(p[q.id], ok)
    store.recordAnswer(ok)
  })
  store.setProgress(p)
  store.addExam({
    date: new Date().toISOString(), score, total: qs.value.length,
    passedLid: score >= PASS.lid, passedEinb: score >= PASS.einbuergerung,
  })
  bump()
  result.value = { score, wrong }
}

const explFor = (q: Question) =>
  isEn.value ? (q.en?.explanation || q.explanation_de) : (q.explanation_de || q.en?.explanation)

// inline translations on the feedback page, shown by default when lang is English
const qEn = (q: Question) => (isEn.value ? q.en?.question : null)
const aEn = (q: Question, i: number | null) => (isEn.value && i != null ? q.en?.answers?.[i] : null)
</script>

<template>
  <div class="fixed inset-0 z-50 flex flex-col bg-paper" role="dialog" aria-modal="true">
    <template v-if="!result">
      <div class="flex items-center gap-3 px-3.5 pb-1 pt-[calc(10px+env(safe-area-inset-top))]">
        <button class="px-2.5 py-1.5 text-xl text-muted" aria-label="Abbrechen" @click="tryClose">✕</button>
        <span class="flex-1 text-center text-[22px] font-extrabold tabular-nums" :class="{ 'text-brand-red': secondsLeft < 300 }">
          {{ timeLabel }}
        </span>
        <button class="rounded-[10px] bg-gold px-3.5 py-1.5 text-sm font-bold text-gold-ink" @click="trySubmit">
          Abgeben
        </button>
      </div>

      <div class="flex gap-1.5 overflow-x-auto px-3.5 pb-2 pt-1 [scrollbar-width:none]">
        <button
          v-for="(_, i) in qs"
          :key="i"
          class="h-[34px] w-[34px] shrink-0 rounded-[9px] border-[1.5px] text-[13px] font-bold tabular-nums"
          :class="[
            picked[i] != null ? 'border-ink bg-ink text-paper' : 'border-line text-muted',
            i === idx ? 'shadow-[0_0_0_2px_var(--gold)] !border-gold' : '',
          ]"
          @click="idx = i"
        >
          {{ i + 1 }}
        </button>
      </div>

      <div class="mx-auto w-full max-w-[620px] flex-1 overflow-y-auto px-4 pb-5 pt-1.5">
        <QuestionCard
          v-if="current"
          :key="current.id"
          :q="current"
          mode="exam"
          :picked="picked[idx]"
          :label="`Aufgabe ${idx + 1} von ${qs.length}${current.state ? ' · Bundesland' : ''}`"
          @pick="pick"
        />
      </div>

      <div class="flex gap-2.5 border-t border-line bg-card px-4 pb-[calc(12px+env(safe-area-inset-bottom))] pt-2.5">
        <button class="min-h-[52px] flex-1 rounded-app border-[1.5px] border-line font-bold" :disabled="idx === 0" @click="idx--">
          ← Zurück
        </button>
        <button class="min-h-[52px] flex-1 rounded-app bg-gold font-bold text-gold-ink" :disabled="idx >= qs.length - 1" @click="idx++">
          Weiter →
        </button>
      </div>
    </template>

    <div v-else class="mx-auto w-full max-w-[620px] flex-1 overflow-y-auto px-4 pb-8">
      <div class="px-2 py-8 text-center">
        <p class="text-xs font-bold uppercase tracking-widest text-muted">{{ t('Ergebnis', 'Result') }}</p>
        <div class="mb-2.5 text-[64px] font-extrabold leading-tight tabular-nums" :class="result.score >= PASS.lid ? 'text-brand-green' : 'text-brand-red'">
          {{ result.score }}/33
        </div>
        <div class="mb-5 grid grid-cols-2 gap-2.5 text-[13.5px]">
          <div class="rounded-[10px] p-2.5" :class="result.score >= PASS.lid ? 'bg-green-soft text-brand-green' : 'bg-red-soft text-brand-red'">
            Leben in Deutschland (NE)<br><b>{{ result.score >= PASS.lid ? t('bestanden ✓', 'passed ✓') : t('nicht bestanden ✗', 'not passed ✗') }}</b>
          </div>
          <div class="rounded-[10px] p-2.5" :class="result.score >= PASS.einbuergerung ? 'bg-green-soft text-brand-green' : 'bg-red-soft text-brand-red'">
            {{ t('Einbürgerung', 'Naturalization') }}<br><b>{{ result.score >= PASS.einbuergerung ? t('bestanden ✓', 'passed ✓') : t('nicht bestanden ✗', 'not passed ✗') }}</b>
          </div>
        </div>

        <template v-if="result.wrong.length">
          <h3 class="mb-2.5 text-left font-bold">{{ t('Falsche Antworten', 'Wrong answers') }} ({{ result.wrong.length }})</h3>
          <div class="mb-4 grid gap-3 text-left">
            <div v-for="w in result.wrong" :key="w.q.id" class="rounded-app border border-line bg-card p-3 text-[14.5px]">
              <p class="mb-1.5 text-xs font-bold uppercase tracking-widest text-muted">{{ t('Frage', 'Question') }} {{ w.q.num }}</p>
              <p class="font-bold" :class="qEn(w.q) ? 'mb-0.5' : 'mb-1.5'">{{ w.q.question }}</p>
              <p v-if="qEn(w.q)" class="mb-1.5 text-muted">{{ qEn(w.q) }}</p>
              <img
                v-if="w.q.image"
                class="my-2 w-full max-w-[300px] rounded-[10px] border border-line bg-white"
                :src="imgUrl(w.q.image)"
                alt=""
                loading="lazy"
              >
              <p class="mb-0.5 text-brand-red">
                {{ t('Deine Antwort', 'Your answer') }}: {{ w.picked != null ? w.q.answers[w.picked] : '–' }}
                <span v-if="aEn(w.q, w.picked)" class="opacity-75">· {{ aEn(w.q, w.picked) }}</span>
              </p>
              <p class="mb-0.5 text-brand-green">
                {{ t('Richtig', 'Correct') }}: {{ w.q.answers[w.q.correct] }}
                <span v-if="aEn(w.q, w.q.correct)" class="opacity-75">· {{ aEn(w.q, w.q.correct) }}</span>
              </p>
              <details v-if="explFor(w.q)" class="mt-1.5 rounded-[10px] border border-line bg-paper px-3 py-2.5 text-sm">
                <summary class="cursor-pointer font-bold">{{ t('Erklärung', 'Explanation') }}</summary>
                <p class="mt-2 text-muted">{{ explFor(w.q) }}</p>
                <SourceLine :q="w.q" />
              </details>
            </div>
          </div>
          <button
            class="mb-2.5 block min-h-[52px] w-full rounded-app bg-gold px-4 py-3 font-bold text-gold-ink"
            @click="emit('drill', result.wrong.map((w) => w.q))"
          >
            {{ t('Fehler jetzt üben', 'Practice mistakes now') }} ({{ result.wrong.length }})
          </button>
        </template>

        <button class="block min-h-[52px] w-full rounded-app border-[1.5px] border-line px-4 py-3 font-bold" @click="emit('close')">
          {{ t('Schließen', 'Close') }}
        </button>
      </div>
    </div>
  </div>
</template>
