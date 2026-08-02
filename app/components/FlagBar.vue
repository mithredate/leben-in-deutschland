<script setup lang="ts">
// Signature element: progress as the German flag filling in.
// black = unseen, red = learning, gold = mastered.
const props = defineProps<{ mastered: number; learning: number; fresh: number; total: number }>()

const pct = (n: number) => `${((100 * n) / Math.max(1, props.total)).toFixed(2)}%`
</script>

<template>
  <div>
    <div
      class="flex h-[26px] overflow-hidden rounded-[7px] border border-line"
      role="img"
      :aria-label="`${mastered} gemeistert, ${learning} in Arbeit, ${fresh} neu`"
    >
      <div class="min-w-0 bg-gold transition-[width] duration-600 motion-reduce:transition-none" :style="{ width: pct(mastered) }" />
      <div class="min-w-0 bg-brand-red transition-[width] duration-600 motion-reduce:transition-none" :style="{ width: pct(learning) }" />
      <div class="min-w-0 bg-band-black transition-[width] duration-600 motion-reduce:transition-none" :style="{ width: pct(fresh) }" />
    </div>
    <div class="mt-2 flex flex-wrap gap-3.5 text-[12.5px] text-muted">
      <span><i class="mr-1 inline-block size-[9px] rounded-full bg-gold" />{{ mastered }} sicher</span>
      <span><i class="mr-1 inline-block size-[9px] rounded-full bg-brand-red" />{{ learning }} in Arbeit</span>
      <span><i class="mr-1 inline-block size-[9px] rounded-full border border-line bg-band-black" />{{ fresh }} neu</span>
    </div>
  </div>
</template>
