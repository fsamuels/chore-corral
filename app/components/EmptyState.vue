<script setup lang="ts">
// Shared centered empty state: large muted icon, a sentence of text, and an
// optional `action` slot (usually a cc-pill-btn).
defineProps<{ icon: string }>()
</script>

<template>
  <div class="cc-empty">
    <v-icon :icon="icon" size="56" />
    <p class="cc-empty__text"><slot /></p>
    <slot name="action" />
  </div>
</template>
