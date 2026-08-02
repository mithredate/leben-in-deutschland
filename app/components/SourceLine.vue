<script setup lang="ts">
import type { Question } from '~/composables/useQuestions'

defineProps<{ q: Question }>()
</script>

<template>
  <p v-if="q.src?.u" class="mt-2 text-[12.5px]">
    Quelle:
    <a :href="q.src.u" target="_blank" rel="noopener" class="text-brand-red underline">{{ q.src.t || q.src.u }}</a>
    <span class="text-muted opacity-85"> · KI-erstellte Erklärung, ohne Gewähr</span>
  </p>
</template>
