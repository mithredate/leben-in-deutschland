<script setup lang="ts">
import { STATES, PASS } from '~/composables/useQuestions'
const emit = defineEmits<{ start: [] }>()

const { store, settings, rev } = useApp()

const exams = computed(() => {
  void rev.value
  return store.getExams()
})

const fmt = (iso: string) => {
  const d = new Date(iso)
  return `${d.toLocaleDateString('de-DE', { day: '2-digit', month: '2-digit' })} ${d.toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' })}`
}
</script>

<template>
  <div>
    <header class="mb-4">
      <p class="text-xs font-bold uppercase tracking-widest text-muted">Simulation</p>
      <h1 class="text-3xl font-extrabold tracking-tight">Testsimulation</h1>
    </header>

    <section class="mb-3.5 rounded-app border border-line bg-card p-4">
      <p>
        Wie in der echten Prüfung: <b>33 Fragen</b> (30 allgemeine + 3 aus
        {{ STATES[settings.state || ''] || 'deinem Bundesland' }}), <b>60 Minuten</b> Zeit.
      </p>
      <ul class="my-2.5 ml-4.5 list-disc text-[14.5px] [&_li]:mb-1">
        <li>„Leben in Deutschland“ (Niederlassungserlaubnis): <b>ab 15 richtigen</b> bestanden</li>
        <li>Einbürgerungstest: <b>ab 17 richtigen</b> bestanden</li>
      </ul>
      <button class="block min-h-[52px] w-full rounded-app bg-gold px-4 py-3 font-bold text-gold-ink" @click="emit('start')">
        Simulation starten
      </button>
    </section>

    <section v-if="exams.length" class="rounded-app border border-line bg-card p-4">
      <h2 class="mb-2.5 font-bold">Bisherige Simulationen</h2>
      <ul>
        <li
          v-for="e in exams.slice(-10).reverse()"
          :key="e.date"
          class="flex justify-between border-b border-line py-2 text-[14.5px] last:border-b-0"
        >
          <span>{{ fmt(e.date) }}</span>
          <b :class="e.score >= PASS.lid ? 'text-brand-green' : 'text-brand-red'">{{ e.score }}/33</b>
        </li>
      </ul>
    </section>
  </div>
</template>
