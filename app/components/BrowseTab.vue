<script setup lang="ts">
import { useQuestions, type Question } from '~/composables/useQuestions'
import { isLeech } from '~/composables/useSrs'

const emit = defineEmits<{ practice: [qs: Question[]] }>()

const { questions } = useQuestions()
const { store, settings, rev } = useApp()

const text = ref('')
const cat = ref('alle')
const status = ref('alle')

const pool = computed(() => questions.value.filter((q) => !q.state || q.state === settings.value.state))
const cats = computed(() => [...new Set(pool.value.map((q) => q.category))])

const progress = computed(() => {
  void rev.value
  return store.getProgress()
})

const marked = computed(() => {
  void rev.value
  return store.getMarked()
})

const rows = computed(() => pool.value.filter((q) => {
  if (cat.value !== 'alle' && q.category !== cat.value) return false
  const e = progress.value[q.id]
  if (status.value === 'neu' && e && e.seen > 0) return false
  if (status.value === 'fehler' && (!e || e.box !== 1)) return false
  if (status.value === 'sicher' && (!e || e.box < 5)) return false
  if (status.value === 'leech' && !isLeech(e)) return false
  if (status.value === 'markiert' && !marked.value.has(q.id)) return false
  if (text.value) {
    const t = text.value.toLowerCase()
    if (!q.question.toLowerCase().includes(t) && !q.num.toLowerCase().includes(t)
      && !q.answers.some((a) => a.toLowerCase().includes(t))) return false
  }
  return true
}))

function dotClass(q: Question) {
  const e = progress.value[q.id]
  if (!e || e.seen === 0) return 'border-[1.5px] border-muted'
  if (e.box >= 5) return 'bg-gold'
  if (e.box === 1) return 'bg-brand-red'
  return 'bg-brand-red opacity-55'
}

function shuffled<T>(arr: T[]): T[] {
  const a = [...arr]
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[a[i], a[j]] = [a[j]!, a[i]!]
  }
  return a
}

const inputCls = 'min-h-[46px] w-full appearance-none rounded-xl border-[1.5px] border-line bg-card px-3 py-2.5 text-ink'
</script>

<template>
  <div>
    <header class="mb-4">
      <p class="text-xs font-bold uppercase tracking-widest text-muted">{{ pool.length }} Fragen im Katalog</p>
      <h1 class="text-3xl font-extrabold tracking-tight">Fragen</h1>
    </header>

    <div class="mb-2">
      <input v-model="text" type="search" placeholder="Suchen…" :class="inputCls">
      <div class="mt-2 flex gap-2">
        <select v-model="cat" :class="inputCls">
          <option value="alle">Alle Themen</option>
          <option v-for="c in cats" :key="c">{{ c }}</option>
        </select>
        <select v-model="status" :class="inputCls">
          <option value="alle">Jeder Status</option>
          <option value="neu">Neu</option>
          <option value="fehler">Fehler</option>
          <option value="markiert">Markiert ★</option>
          <option value="leech">Hartnäckig 🔥</option>
          <option value="sicher">Sicher</option>
        </select>
      </div>
    </div>

    <p class="mx-0.5 my-2 text-[13px] text-muted">
      {{ rows.length }} Treffer
      <template v-if="rows.length">
        · <button class="font-semibold text-brand-red underline" @click="emit('practice', shuffled(rows).slice(0, 30))">diese üben</button>
      </template>
    </p>

    <ul>
      <li
        v-for="q in rows"
        :key="q.id"
        class="flex cursor-pointer items-center gap-2.5 border-b border-line px-1 py-3"
        @click="emit('practice', [q])"
      >
        <span class="size-2.5 shrink-0 rounded-full" :class="dotClass(q)" />
        <span class="w-11 shrink-0 text-xs font-bold text-muted">{{ q.num }}{{ marked.has(q.id) ? ' ★' : '' }}{{ isLeech(progress[q.id]) ? ' 🔥' : '' }}</span>
        <span class="line-clamp-2 text-sm">{{ q.question }}</span>
      </li>
    </ul>
  </div>
</template>
