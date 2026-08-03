<script setup lang="ts">
import { useQuestions, STATES, PASS } from '~/composables/useQuestions'
import { summarize, dueCount, dailyTarget, ROUND_SIZE } from '~/composables/useSrs'

const emit = defineEmits<{ study: []; exam: [] }>()

const { questions } = useQuestions()
const { store, settings, rev } = useApp()

const pool = computed(() => questions.value.filter((q) => !q.state || q.state === settings.value.state))

const data = computed(() => {
  void rev.value // recompute after every session
  const progress = store.getProgress()
  const s = summarize(pool.value, progress)
  const due = dueCount(pool.value, progress)
  const { perDay, daysLeft } = dailyTarget(s, settings.value.examDate)
  return {
    s, due, perDay, daysLeft,
    today: store.answeredToday(),
    streak: store.streak(),
    lastExam: store.getExams().at(-1),
  }
})

const examDateLabel = computed(() =>
  new Date(settings.value.examDate).toLocaleDateString('de-DE', { weekday: 'long', day: 'numeric', month: 'long' }),
)

const studyLabel = computed(() => {
  const { due, s } = data.value
  if (due + s.new > 0) return `Runde starten (${Math.min(ROUND_SIZE, due + s.new)} Fragen)`
  return 'Alles gemeistert – Fehler wiederholen'
})
</script>

<template>
  <div>
    <header class="mb-4">
      <p class="text-xs font-bold uppercase tracking-widest text-muted">Leben in Deutschland</p>
      <h1 class="text-3xl font-extrabold tracking-tight">Testtrainer</h1>
    </header>

    <section class="mb-3.5 flex items-center gap-4 rounded-app border border-[var(--cd-border)] bg-[var(--cd-bg)] p-4 text-[var(--cd-fg)]">
      <div class="text-[52px] font-extrabold leading-none tabular-nums text-gold">{{ data.daysLeft }}</div>
      <div class="text-[15px] font-semibold">
        Tag{{ data.daysLeft === 1 ? '' : 'e' }} bis zur Prüfung<br>
        <small class="font-normal opacity-75">{{ examDateLabel }} · {{ STATES[settings.state || ''] || '' }}</small>
      </div>
    </section>

    <section class="mb-3.5 rounded-app border border-line bg-card p-4">
      <h2 class="mb-2.5 font-bold">Dein Fortschritt</h2>
      <FlagBar :mastered="data.s.mastered" :learning="data.s.learning" :fresh="data.s.new" :total="data.s.total" />
      <div class="mt-3.5 grid grid-cols-4 gap-2 text-center">
        <div><b class="block text-[22px] tabular-nums">{{ data.due }}</b><span class="text-[11.5px] text-muted">fällig</span></div>
        <div><b class="block text-[22px] tabular-nums">{{ data.today }}</b><span class="text-[11.5px] text-muted">heute geübt</span></div>
        <div><b class="block text-[22px] tabular-nums">{{ data.streak }}</b><span class="text-[11.5px] text-muted">Tage-Serie</span></div>
        <div><b class="block text-[22px] tabular-nums">{{ Math.max(0, data.perDay) }}</b><span class="text-[11.5px] text-muted">neue/Tag nötig</span></div>
      </div>
    </section>

    <button
      class="mb-2.5 block min-h-[52px] w-full rounded-app bg-gold px-4 py-3 text-center font-bold text-gold-ink active:scale-[0.985]"
      @click="emit('study')"
    >
      {{ studyLabel }}
    </button>
    <button
      class="block min-h-[52px] w-full rounded-app border-[1.5px] border-line px-4 py-3 text-center font-bold"
      @click="emit('exam')"
    >
      Testsimulation starten
    </button>

    <p v-if="data.lastExam" class="mt-3 text-center text-sm text-muted">
      Letzte Simulation: <b>{{ data.lastExam.score }}/33</b>
      {{ data.lastExam.score >= PASS.lid ? '✓ bestanden' : '✗ nicht bestanden' }}
    </p>
  </div>
</template>
