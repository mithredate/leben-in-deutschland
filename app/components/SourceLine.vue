<script setup lang="ts">
import type { Question } from '~/composables/useQuestions'

defineProps<{ q: Question }>()

const { settings } = useApp()
const isEn = computed(() => settings.value.lang === 'en')
</script>

<template>
  <p v-if="q.src?.u" class="mt-2 text-[12.5px]">
    {{ isEn ? 'Source' : 'Quelle' }}:
    <a :href="q.src.u" target="_blank" rel="noopener" class="text-brand-red underline">{{ q.src.t || q.src.u }}</a>
    <span class="text-muted opacity-85"> · {{ isEn ? 'AI-generated explanation, no guarantee' : 'KI-erstellte Erklärung, ohne Gewähr' }}</span>
  </p>
</template>
