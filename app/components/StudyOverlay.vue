<script setup lang="ts">
import { useQuestions, type Question } from '~/composables/useQuestions'
import { buildSession, gradeAnswer, requeuePosition, shuffle } from '~/composables/useSrs'

const props = defineProps<{ list?: Question[] }>()
const emit = defineEmits<{ close: [] }>()

const { questions } = useQuestions()
const { store, settings, bump } = useApp()
const toast = useToast()

const pool = computed(() => questions.value.filter((q) => !q.state || q.state === settings.value.state))

// queue grows when a question is missed (in-round relearning);
// answers[i] is the picked index for queue[i] — lifted here so the user can
// navigate back to any card and still see their answer + feedback
const queue = ref<Question[]>([])
const answers = ref<(number | null)[]>([])
const idx = ref(0)
const finished = ref(false)

function start(qs: Question[]) {
  queue.value = qs
  answers.value = new Array(qs.length).fill(null)
  idx.value = 0
  finished.value = false
  if (!qs.length) {
    toast.show('Nichts fällig – alles gelernt! 🎉')
    emit('close')
  }
}

onMounted(() => start(props.list ? [...props.list] : buildSession(pool.value, store.getProgress())))

const current = computed(() => queue.value[idx.value])
const answeredCount = computed(() => answers.value.filter((a) => a != null).length)
const rightCount = computed(() => answers.value.filter((a, i) => a != null && a === queue.value[i]!.correct).length)
const allAnswered = computed(() => answeredCount.value === queue.value.length)

// unique questions missed at least once this round (drill material)
const mistakes = computed(() => {
  const seen = new Set<string>()
  const out: Question[] = []
  queue.value.forEach((q, i) => {
    const a = answers.value[i]
    if (a != null && a !== q.correct && !seen.has(q.id)) {
      seen.add(q.id)
      out.push(q)
    }
  })
  return out
})

function onAnswer(correct: boolean, picked: number) {
  if (answers.value[idx.value] != null) return
  const q = current.value!
  answers.value[idx.value] = picked
  const p = store.getProgress()
  p[q.id] = gradeAnswer(p[q.id], correct)
  store.setProgress(p)
  store.recordAnswer(correct)
  if (!correct) {
    const at = requeuePosition(idx.value, queue.value.length)
    queue.value.splice(at, 0, q)
    answers.value.splice(at, 0, null)
  }
}

function next() {
  if (idx.value < queue.value.length - 1) {
    idx.value += 1
  } else if (allAnswered.value) {
    finished.value = true
  } else {
    // reached the end with skipped cards — jump to the first open one
    idx.value = answers.value.findIndex((a) => a == null)
  }
}

function again() {
  bump()
  start(buildSession(pool.value, store.getProgress()))
}

function drillMistakes() {
  bump()
  start(shuffle([...mistakes.value]))
}

const finishMessage = computed(() => {
  const pct = answeredCount.value ? rightCount.value / answeredCount.value : 1
  if (pct === 1) return 'Perfekte Runde!'
  if (pct >= 0.7) return 'Gut gemacht – weiter so.'
  return 'Schwere Fragen kommen in den nächsten Runden zurück.'
})
</script>

<template>
  <div class="fixed inset-0 z-50 flex flex-col bg-paper" role="dialog" aria-modal="true">
    <div class="flex items-center gap-3 px-3.5 pb-1 pt-[calc(10px+env(safe-area-inset-top))]">
      <button class="px-2.5 py-1.5 text-xl text-muted" aria-label="Schließen" @click="emit('close')">✕</button>
      <div class="h-2 flex-1 overflow-hidden rounded bg-line">
        <div
          class="h-full bg-gold transition-[width] duration-300"
          :style="{ width: `${(100 * answeredCount) / Math.max(1, queue.length)}%` }"
        />
      </div>
      <span class="text-[13px] font-bold tabular-nums text-muted">{{ Math.min(idx + 1, queue.length) }}/{{ queue.length }}</span>
    </div>

    <div v-if="!finished" class="flex gap-1.5 overflow-x-auto px-3.5 pb-2 pt-1 [scrollbar-width:none]">
      <button
        v-for="(q, i) in queue"
        :key="i"
        class="h-[34px] w-[34px] shrink-0 rounded-[9px] border-[1.5px] text-[13px] font-bold tabular-nums"
        :class="[
          answers[i] == null
            ? 'border-line text-muted'
            : answers[i] === q.correct
              ? 'border-brand-green bg-green-soft text-brand-green'
              : 'border-brand-red bg-red-soft text-brand-red',
          i === idx ? 'shadow-[0_0_0_2px_var(--gold)] !border-gold' : '',
        ]"
        @click="idx = i"
      >
        {{ i + 1 }}
      </button>
    </div>

    <div class="mx-auto w-full max-w-[620px] flex-1 overflow-y-auto px-4 pb-5 pt-1.5">
      <template v-if="!finished">
        <QuestionCard
          v-if="current"
          :key="`${current.id}-${idx}`"
          :q="current"
          mode="study"
          :answered="answers[idx] ?? null"
          @answer="onAnswer"
        />
      </template>
      <div v-else class="px-2 py-8 text-center">
        <div class="mb-2.5 text-[64px] font-extrabold leading-tight tabular-nums">{{ rightCount }}/{{ answeredCount }}</div>
        <p class="mb-5 text-muted">{{ finishMessage }}</p>
        <button
          v-if="mistakes.length"
          class="mb-2.5 block min-h-[52px] w-full rounded-app bg-gold px-4 py-3 font-bold text-gold-ink"
          @click="drillMistakes"
        >
          Fehler jetzt üben ({{ mistakes.length }})
        </button>
        <button
          class="mb-2.5 block min-h-[52px] w-full rounded-app px-4 py-3 font-bold"
          :class="mistakes.length ? 'border-[1.5px] border-line' : 'bg-gold text-gold-ink'"
          @click="again"
        >
          Nächste Runde
        </button>
        <button
          class="mb-2.5 block min-h-[52px] w-full rounded-app border-[1.5px] border-line px-4 py-3 font-bold"
          @click="finished = false"
        >
          Antworten ansehen
        </button>
        <button
          class="block min-h-[52px] w-full rounded-app border-[1.5px] border-line px-4 py-3 font-bold"
          @click="emit('close')"
        >
          Fertig für jetzt
        </button>
      </div>
    </div>

    <div v-if="!finished" class="flex gap-2.5 border-t border-line bg-card px-4 pb-[calc(12px+env(safe-area-inset-bottom))] pt-2.5">
      <button
        class="min-h-[52px] flex-1 rounded-app border-[1.5px] border-line font-bold disabled:opacity-40"
        :disabled="idx === 0"
        @click="idx--"
      >
        ← Zurück
      </button>
      <button
        class="min-h-[52px] flex-1 rounded-app bg-gold font-bold text-gold-ink disabled:opacity-40"
        :disabled="answers[idx] == null"
        @click="next"
      >
        {{ idx >= queue.length - 1 && allAnswered ? 'Fertig ✓' : 'Weiter →' }}
      </button>
    </div>
  </div>
</template>
