<script setup lang="ts">
import { useQuestions, type Question } from '~/composables/useQuestions'
import { buildSession, gradeAnswer, REQUEUE_GAP } from '~/composables/useSrs'

const props = defineProps<{ list?: Question[] }>()
const emit = defineEmits<{ close: [] }>()

const { questions } = useQuestions()
const { store, settings, bump } = useApp()
const toast = useToast()

const pool = computed(() => questions.value.filter((q) => !q.state || q.state === settings.value.state))

// queue grows when a question is missed (in-round relearning)
const queue = ref<Question[]>([])
const idx = ref(0)
const right = ref(0)
const answered = ref(0)
const showNext = ref(false)
const finished = ref(false)

onMounted(() => {
  queue.value = props.list ? [...props.list] : buildSession(pool.value, store.getProgress())
  if (!queue.value.length) {
    toast.show('Nichts fällig – alles gelernt! 🎉')
    emit('close')
  }
})

const current = computed(() => queue.value[idx.value])

function onAnswer(correct: boolean) {
  const q = current.value!
  const p = store.getProgress()
  p[q.id] = gradeAnswer(p[q.id], correct)
  store.setProgress(p)
  store.recordAnswer(correct)
  answered.value += 1
  if (correct) {
    right.value += 1
  } else {
    queue.value.splice(Math.min(idx.value + 1 + REQUEUE_GAP, queue.value.length), 0, q)
  }
  showNext.value = true
}

function next() {
  showNext.value = false
  idx.value += 1
  if (idx.value >= queue.value.length) finished.value = true
}

function again() {
  bump()
  queue.value = buildSession(pool.value, store.getProgress())
  idx.value = 0
  right.value = 0
  answered.value = 0
  finished.value = false
  if (!queue.value.length) {
    toast.show('Nichts fällig – alles gelernt! 🎉')
    emit('close')
  }
}

const finishMessage = computed(() => {
  const pct = answered.value ? right.value / answered.value : 1
  if (pct === 1) return 'Perfekte Runde!'
  if (pct >= 0.7) return 'Gut gemacht – weiter so.'
  return 'Schwere Fragen kommen in der nächsten Runde zuerst.'
})
</script>

<template>
  <div class="fixed inset-0 z-50 flex flex-col bg-paper" role="dialog" aria-modal="true">
    <div class="flex items-center gap-3 px-3.5 pb-2.5 pt-[calc(10px+env(safe-area-inset-top))]">
      <button class="px-2.5 py-1.5 text-xl text-muted" aria-label="Schließen" @click="emit('close')">✕</button>
      <div class="h-2 flex-1 overflow-hidden rounded bg-line">
        <div
          class="h-full bg-gold transition-[width] duration-300"
          :style="{ width: `${finished ? 100 : (100 * idx) / Math.max(1, queue.length)}%` }"
        />
      </div>
      <span class="text-[13px] font-bold tabular-nums text-muted">{{ Math.min(idx + 1, queue.length) }}/{{ queue.length }}</span>
    </div>

    <div class="mx-auto w-full max-w-[620px] flex-1 overflow-y-auto px-4 pb-5 pt-1.5">
      <template v-if="!finished">
        <QuestionCard v-if="current" :key="`${current.id}-${idx}`" :q="current" mode="study" @answer="onAnswer" />
      </template>
      <div v-else class="px-2 py-8 text-center">
        <div class="mb-2.5 text-[64px] font-extrabold leading-tight tabular-nums">{{ right }}/{{ answered }}</div>
        <p class="mb-5 text-muted">{{ finishMessage }}</p>
        <button
          class="mb-2.5 block min-h-[52px] w-full rounded-app bg-gold px-4 py-3 font-bold text-gold-ink"
          @click="again"
        >
          Nächste Runde
        </button>
        <button
          class="block min-h-[52px] w-full rounded-app border-[1.5px] border-line px-4 py-3 font-bold"
          @click="emit('close')"
        >
          Fertig für jetzt
        </button>
      </div>
    </div>

    <div v-if="showNext && !finished" class="border-t border-line bg-card px-4 pb-[calc(12px+env(safe-area-inset-bottom))] pt-2.5">
      <button class="block min-h-[52px] w-full rounded-app bg-gold px-4 py-3 font-bold text-gold-ink" @click="next">
        Weiter
      </button>
    </div>
  </div>
</template>
