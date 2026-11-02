<script setup lang="ts">
// Placeholder rows shown while a *list* page loads, so the layout doesn't
// jump when the real cards arrive. Use LoadingState for non-list loads.
withDefaults(defineProps<{ rows?: number; label?: string }>(), {
  rows: 4,
  label: 'Loading',
})
</script>

<template>
  <div class="cc-card-list" role="status" aria-busy="true" :aria-label="label">
    <div
      v-for="n in rows"
      :key="n"
      class="cc-card cc-card--row list-skeleton__row"
      aria-hidden="true"
    >
      <div class="cc-skeleton list-skeleton__bar--title" />
      <div class="cc-skeleton list-skeleton__bar--meta" />
    </div>
    <span class="cc-sr-only">{{ label }}</span>
  </div>
</template>

<style scoped>
.list-skeleton__row {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.list-skeleton__bar--title {
  width: 60%;
  height: 18px;
}

.list-skeleton__bar--meta {
  width: 35%;
}
</style>
