<script setup lang="ts">
// Shared page title block: optional back pill, the page's single h1, and an
// optional `actions` slot on the right (and a default slot for a subtitle
// line). Keeps every page's top-of-content identical — see `.cc-page-title`.
defineProps<{
  title: string
  back?: { to: string; label: string }
}>()
</script>

<template>
  <div class="page-header">
    <NuxtLink
      v-if="back"
      :to="back.to"
      class="cc-pill-btn cc-pill-btn--surface cc-pill-btn--sm page-header__back"
    >
      <v-icon icon="mdi-arrow-left" size="18" />
      {{ back.label }}
    </NuxtLink>
    <div class="page-header__row">
      <h1 class="cc-page-title">{{ title }}</h1>
      <div v-if="$slots.actions" class="page-header__actions">
        <slot name="actions" />
      </div>
    </div>
    <p v-if="$slots.default" class="page-header__subtitle">
      <slot />
    </p>
  </div>
</template>

<style scoped>
.page-header {
  margin-bottom: 20px;
}

.page-header__back {
  margin-bottom: 12px;
}

.page-header__row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.page-header__actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: none;
}

.page-header__subtitle {
  margin: 4px 0 0;
  font-size: 0.9375rem;
  line-height: 1.5;
  color: var(--cc-ink-muted);
}
</style>
