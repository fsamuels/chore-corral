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
      <div class="list-skeleton__bar list-skeleton__bar--title" />
      <div class="list-skeleton__bar list-skeleton__bar--meta" />
    </div>
    <span class="list-skeleton__sr">{{ label }}</span>
  </div>
</template>

<style scoped>
.list-skeleton__row {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.list-skeleton__bar {
  height: 14px;
  border-radius: 999px;
  background: linear-gradient(
    90deg,
    var(--cc-track) 25%,
    var(--cc-border) 50%,
    var(--cc-track) 75%
  );
  background-size: 200% 100%;
  animation: list-skeleton-shimmer 1.4s ease-in-out infinite;
}

.list-skeleton__bar--title {
  width: 60%;
  height: 18px;
}

.list-skeleton__bar--meta {
  width: 35%;
}

/* Visually hidden, still announced. */
.list-skeleton__sr {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}

@keyframes list-skeleton-shimmer {
  from {
    background-position: 200% 0;
  }
  to {
    background-position: -200% 0;
  }
}

@media (prefers-reduced-motion: reduce) {
  .list-skeleton__bar {
    animation: none;
    background: var(--cc-track);
  }
}
</style>
