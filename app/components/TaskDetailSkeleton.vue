<script setup lang="ts">
// Placeholder for the whole chore detail page while the chore itself (and the
// farm's categories/tags/locations/members it's displayed against) loads.
// Mirrors the real page's layout — back link, title, field pills, age line,
// status control, then the section cards — so content fills in where the
// blanks were instead of the page reflowing.
withDefaults(defineProps<{ label?: string }>(), { label: 'Loading chore' })

// Widths for the priority / category / due date / estimate pills.
const PILL_WIDTHS = ['96px', '132px', '112px', '88px']
</script>

<template>
  <div role="status" aria-busy="true" :aria-label="label">
    <div aria-hidden="true">
      <div class="cc-skeleton cc-skeleton--pill task-skeleton__back" />

      <div class="cc-skeleton task-skeleton__title mb-4" />

      <div class="d-flex flex-wrap ga-2 mb-6">
        <div
          v-for="width in PILL_WIDTHS"
          :key="width"
          class="cc-skeleton cc-skeleton--pill"
          :style="{ width }"
        />
      </div>

      <div class="cc-skeleton task-skeleton__age mb-6" />

      <div class="cc-skeleton task-skeleton__eyebrow mb-2" />
      <div class="cc-skeleton cc-skeleton--pill task-skeleton__status mb-6" />

      <div v-for="n in 3" :key="n" class="cc-card mb-6">
        <div class="cc-skeleton task-skeleton__eyebrow mb-3" />
        <SectionSkeleton :lines="2" />
      </div>
    </div>
    <span class="cc-sr-only">{{ label }}</span>
  </div>
</template>

<style scoped>
.task-skeleton__back {
  width: 104px;
  height: 36px;
  margin-bottom: 12px;
}

.task-skeleton__title {
  width: 70%;
  height: 32px;
  border-radius: 10px;
}

.task-skeleton__age {
  width: 140px;
}

.task-skeleton__eyebrow {
  width: 64px;
  height: 12px;
}

.task-skeleton__status {
  width: 100%;
}
</style>
