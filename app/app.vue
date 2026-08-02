<script setup lang="ts">
import { useQuestions, type Question } from '~/composables/useQuestions'

const { load } = useQuestions()
const { settings, tab, applyTheme, bump } = useApp()
const toast = useToast()

const loaded = ref(false)
const overlay = ref<null | { type: 'study'; list?: Question[] } | { type: 'exam' } | { type: 'onboarding' }>(null)

onMounted(async () => {
  applyTheme()
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', applyTheme)
  if (navigator.storage?.persist) navigator.storage.persist().catch(() => {})
  await load()
  loaded.value = true
  if (!settings.value.state) overlay.value = { type: 'onboarding' }
})

const tabs = [
  { key: 'home', label: 'Heute', ico: '◈' },
  { key: 'browse', label: 'Fragen', ico: '≣' },
  { key: 'exam', label: 'Test', ico: '◷' },
  { key: 'more', label: 'Mehr', ico: '⋯' },
] as const

function startStudy(list?: Question[]) {
  overlay.value = { type: 'study', list }
}

function closeOverlay() {
  overlay.value = null
  bump()
}

function drill(qs: Question[]) {
  overlay.value = null
  nextTick(() => (overlay.value = { type: 'study', list: qs }))
}
</script>

<template>
  <div class="min-h-dvh pb-[calc(64px+env(safe-area-inset-bottom))]">
    <main
      v-if="loaded"
      class="mx-auto max-w-[620px] px-4 pt-[calc(16px+env(safe-area-inset-top))] pb-6"
      aria-live="polite"
    >
      <HomeTab v-if="tab === 'home'" @study="startStudy()" @exam="overlay = { type: 'exam' }" />
      <BrowseTab v-else-if="tab === 'browse'" @practice="startStudy($event)" />
      <ExamTab v-else-if="tab === 'exam'" @start="overlay = { type: 'exam' }" />
      <MoreTab v-else />
    </main>

    <nav
      class="fixed bottom-0 left-0 right-0 z-40 flex border-t border-line bg-card pb-[env(safe-area-inset-bottom)]"
      aria-label="Hauptnavigation"
    >
      <button
        v-for="t in tabs"
        :key="t.key"
        class="flex flex-1 flex-col items-center gap-0.5 pt-2 pb-2.5 text-[11.5px] font-bold"
        :class="tab === t.key ? 'text-ink' : 'text-muted'"
        @click="tab = t.key"
      >
        <span class="text-xl leading-none" :class="tab === t.key ? 'text-brand-red' : ''">{{ t.ico }}</span>
        {{ t.label }}
      </button>
    </nav>

    <OnboardingOverlay v-if="overlay?.type === 'onboarding'" @done="closeOverlay" />
    <StudyOverlay
      v-else-if="overlay?.type === 'study'"
      :list="overlay.list"
      @close="closeOverlay"
    />
    <ExamOverlay v-else-if="overlay?.type === 'exam'" @close="closeOverlay" @drill="drill" />

    <Transition
      enter-active-class="transition duration-250"
      enter-from-class="opacity-0 translate-y-2"
      leave-active-class="transition duration-250"
      leave-to-class="opacity-0 translate-y-2"
    >
      <div
        v-if="toast.visible.value"
        class="pointer-events-none fixed bottom-[calc(80px+env(safe-area-inset-bottom))] left-1/2 z-90 -translate-x-1/2 rounded-xl bg-ink px-4.5 py-2.5 text-sm font-semibold text-paper"
      >
        {{ toast.message.value }}
      </div>
    </Transition>
  </div>
</template>
