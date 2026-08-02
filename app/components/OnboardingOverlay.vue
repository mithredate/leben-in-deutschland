<script setup lang="ts">
import { STATES } from '~/composables/useQuestions'
const emit = defineEmits<{ done: [] }>()

const { patchSettings, settings } = useApp()

const step = ref<'state' | 'date'>('state')
const today = new Date().toISOString().slice(0, 10)
const date = ref(
  settings.value.examDate >= today
    ? settings.value.examDate
    : new Date(Date.now() + 14 * 24 * 3600 * 1000).toISOString().slice(0, 10),
)

function pickState(code: string) {
  patchSettings({ state: code })
  step.value = 'date'
}

function finish() {
  if (date.value) patchSettings({ examDate: date.value })
  emit('done')
}
</script>

<template>
  <div class="fixed inset-0 z-50 overflow-y-auto bg-paper" role="dialog" aria-modal="true">
    <div class="mx-auto max-w-[620px] px-4 pb-10 pt-12 text-center">
      <template v-if="step === 'state'">
        <p class="text-xs font-bold uppercase tracking-widest text-muted">Willkommen</p>
        <h1 class="mx-0 mb-2 mt-1.5 text-[26px] font-extrabold leading-tight">In welchem Bundesland machst du die Prüfung?</h1>
        <p class="mb-5 text-muted">3 der 33 Prüfungsfragen kommen aus deinem Bundesland.</p>
        <div class="grid grid-cols-2 gap-2.5 text-left sm:grid-cols-4">
          <button
            v-for="(name, code) in STATES"
            :key="code"
            class="min-h-[52px] rounded-xl border-[1.5px] border-line bg-card px-3 py-2.5 text-sm font-semibold active:border-gold active:bg-paper"
            @click="pickState(code)"
          >
            {{ name }}
          </button>
        </div>
      </template>

      <template v-else>
        <p class="text-xs font-bold uppercase tracking-widest text-muted">Fast geschafft</p>
        <h1 class="mx-0 mb-2 mt-1.5 text-[26px] font-extrabold leading-tight">Wann ist deine Prüfung?</h1>
        <p class="mb-5 text-muted">Daraus berechnet die App deinen Countdown und dein Tagespensum. Später änderbar unter „Mehr“.</p>
        <input
          v-model="date"
          type="date"
          :min="today"
          class="mx-auto mb-4.5 block min-h-[46px] w-full max-w-[280px] rounded-xl border-[1.5px] border-line bg-card px-3 py-2.5 text-center text-[17px] text-ink"
        >
        <button class="mx-auto block min-h-[52px] w-full max-w-[280px] rounded-app bg-gold px-4 py-3 font-bold text-gold-ink" @click="finish">
          Los geht's
        </button>
      </template>
    </div>
  </div>
</template>
