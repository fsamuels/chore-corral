<script setup lang="ts">
// Placeholder for one section of the chore detail page (photos, shopping
// list, tools, reminders, timer, activity) while that section's own data
// loads. Replaces the per-section spinner so the card holds roughly its final
// height instead of growing when the content arrives.
//
// `lines` draws text-row bars (lists, activity); `tiles` draws square photo
// thumbnails instead.
withDefaults(
  defineProps<{ lines?: number; tiles?: number; label?: string }>(),
  { lines: 2, tiles: 0, label: 'Loading' },
)
</script>

<template>
  <div
    class="section-skeleton"
    role="status"
    aria-busy="true"
    :aria-label="label"
  >
    <div v-if="tiles > 0" class="section-skeleton__tiles" aria-hidden="true">
      <div
        v-for="n in tiles"
        :key="n"
        class="cc-skeleton cc-skeleton--block section-skeleton__tile"
      />
    </div>
    <template v-else>
      <div
        v-for="n in lines"
        :key="n"
        class="cc-skeleton section-skeleton__line"
        :style="{ width: n % 2 === 1 ? '70%' : '45%' }"
        aria-hidden="true"
      />
    </template>
    <span class="cc-sr-only">{{ label }}</span>
  </div>
</template>

<style scoped>
.section-skeleton {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 4px 0;
}

.section-skeleton__line {
  height: 16px;
}

.section-skeleton__tiles {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}

/* Matches TaskPhotos' thumbnail size. */
.section-skeleton__tile {
  width: 140px;
  height: 140px;
}
</style>
