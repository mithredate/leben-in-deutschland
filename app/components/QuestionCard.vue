<script setup lang="ts">
import { useQuestions, type Question } from '~/composables/useQuestions'

const props = defineProps<{
  q: Question
  mode: 'study' | 'exam'
  picked?: number | null
  label?: string
}>()

const emit = defineEmits<{ answer: [correct: boolean]; pick: [index: number] }>()

const { settings } = useApp()
const { imgUrl } = useQuestions()

// answers stay in catalog order when they reference image positions/numbers
const isPositional = computed(() => props.q.answers.every((a) => /^(bild\s*)?\d+\s*€?$/i.test(a.trim())))

function shuffled<T>(arr: T[]): T[] {
  const a = [...arr]
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[a[i], a[j]] = [a[j]!, a[i]!]
  }
  return a
}

const { store } = useApp()
const toast = useToast()

const order = ref<number[]>([])
const answered = ref<number | null>(null)
const flipped = ref(false)
const showAlt = ref(false)
const marked = ref(false)

watch(() => props.q, () => {
  order.value = isPositional.value ? [0, 1, 2, 3] : shuffled([0, 1, 2, 3])
  answered.value = null
  flipped.value = false
  showAlt.value = false
  marked.value = store.getMarked().has(props.q.id)
}, { immediate: true })

function toggleMark() {
  marked.value = store.toggleMarked(props.q.id)
  toast.show(marked.value ? '★ Als schwierig markiert' : 'Markierung entfernt')
}

const en = computed(() => props.q.en || { question: null, answers: [], explanation: null })
const hasBack = computed(() =>
  props.mode === 'study'
  && settings.value.lang !== 'de'
  && !!(en.value.question || en.value.explanation || (en.value.answers || []).some(Boolean)),
)

const correct = computed(() => answered.value !== null && answered.value === props.q.correct)
const expl = computed(() =>
  settings.value.lang === 'en' ? en.value.explanation : (props.q.explanation_de || en.value.explanation),
)
const altExpl = computed(() =>
  settings.value.lang === 'en' ? props.q.explanation_de : en.value.explanation,
)

function choose(i: number) {
  if (props.mode === 'exam') {
    emit('pick', i)
    return
  }
  if (answered.value !== null) return
  answered.value = i
  emit('answer', i === props.q.correct)
}

function answerClass(i: number) {
  if (props.mode === 'exam') {
    return props.picked === i
      ? 'border-ink bg-paper [&_.letter]:bg-ink [&_.letter]:text-paper'
      : 'border-line bg-card'
  }
  if (answered.value === null) return 'border-line bg-card'
  if (i === props.q.correct) return 'border-brand-green bg-green-soft [&_.letter]:bg-brand-green [&_.letter]:text-white [&_.letter]:border-brand-green'
  if (i === answered.value) return 'border-brand-red bg-red-soft answer-shake [&_.letter]:bg-brand-red [&_.letter]:text-white [&_.letter]:border-brand-red'
  return 'border-line bg-card'
}
</script>

<template>
  <article class="pb-6 pt-1">
    <div class="mb-2 flex items-center justify-between gap-2.5">
      <p class="text-xs font-bold uppercase tracking-widest text-muted">
        {{ label || `Frage ${q.num} · ${q.category}` }}
      </p>
      <div class="flex shrink-0 items-center gap-1.5">
        <button
          v-if="mode === 'study'"
          class="rounded-full border-[1.5px] px-2.5 py-1 text-sm leading-none"
          :class="marked ? 'border-gold text-gold' : 'border-line text-muted'"
          :aria-pressed="marked"
          aria-label="Als schwierig markieren"
          @click="toggleMark"
        >
          {{ marked ? '★' : '☆' }}
        </button>
        <button
          v-if="hasBack"
          class="rounded-full border-[1.5px] px-3 py-1 text-xs font-extrabold tracking-wide"
          :class="flipped ? 'border-gold text-ink' : 'border-line text-muted'"
          :aria-pressed="flipped"
          aria-label="Englische Übersetzung zeigen"
          @click="flipped = !flipped"
        >
          EN ⇄
        </button>
      </div>
    </div>

    <div class="flip" :class="{ flipped }">
      <div class="flip-inner">
        <div class="face face-front" :aria-hidden="flipped">
          <h2 class="mb-1.5 text-xl font-bold leading-snug">{{ q.question }}</h2>
          <img
            v-if="q.image"
            class="my-2.5 w-full max-w-[460px] rounded-[10px] border border-line bg-white"
            :src="imgUrl(q.image)"
            :alt="`Abbildung zu Frage ${q.num}`"
            loading="lazy"
          >
          <div class="mt-3.5 grid gap-2.5">
            <button
              v-for="(i, pos) in order"
              :key="i"
              class="flex min-h-[52px] items-center gap-3 rounded-app border-[1.5px] px-3.5 py-3 text-left text-[15.5px] transition-colors"
              :class="answerClass(i)"
              :disabled="mode === 'study' && answered !== null"
              @click="choose(i)"
            >
              <span class="letter grid size-7 shrink-0 place-items-center rounded-lg border border-line bg-paper text-[13px] font-bold">
                {{ 'ABCD'[pos] }}
              </span>
              <span>{{ q.answers[i] }}</span>
            </button>
          </div>
        </div>

        <div v-if="hasBack" class="face face-back" :aria-hidden="!flipped">
          <p class="mb-2 text-xs font-bold uppercase tracking-widest text-muted">English</p>
          <h2 class="mb-1.5 text-xl font-bold leading-snug">{{ en.question || q.question }}</h2>
          <div class="mt-3.5 grid gap-2.5">
            <div
              v-for="(i, pos) in order"
              :key="i"
              class="pointer-events-none flex min-h-[52px] items-center gap-3 rounded-app border-[1.5px] border-line bg-card px-3.5 py-3 text-left text-[15.5px]"
            >
              <span class="grid size-7 shrink-0 place-items-center rounded-lg border border-line bg-paper text-[13px] font-bold">
                {{ 'ABCD'[pos] }}
              </span>
              <span>{{ (en.answers || [])[i] || q.answers[i] }}</span>
            </div>
          </div>
          <p v-if="en.explanation" class="my-3 rounded-[10px] border border-line bg-paper px-3 py-2.5 text-sm text-muted">
            {{ en.explanation }}
          </p>
          <SourceLine :q="q" />
          <button
            class="mt-1 block w-full min-h-[52px] rounded-app border-[1.5px] border-line px-4 py-3 text-center font-bold"
            @click="flipped = false"
          >
            ← Zurück zur Frage
          </button>
        </div>
      </div>
    </div>

    <div v-if="mode === 'study' && answered !== null" class="mt-3.5">
      <p class="mb-1.5 text-[17px] font-extrabold" :class="correct ? 'text-brand-green' : 'text-brand-red'">
        {{ correct ? 'Richtig!' : 'Leider falsch.' }}
      </p>
      <details v-if="expl" class="rounded-[10px] border border-line bg-paper px-3 py-2.5 text-sm" :open="!correct">
        <summary class="cursor-pointer font-bold">Erklärung</summary>
        <p class="mt-2 text-muted">{{ expl }}</p>
        <SourceLine :q="q" />
        <template v-if="altExpl">
          <button class="py-1 text-sm font-semibold text-brand-red underline" @click="showAlt = !showAlt">
            Auf {{ settings.lang === 'en' ? 'Deutsch' : 'Englisch' }} zeigen
          </button>
          <p v-if="showAlt" class="mt-1 text-muted">{{ altExpl }}</p>
        </template>
      </details>
    </div>
  </article>
</template>
