<script setup lang="ts">
// Shared centered spinner for a page or list that's still loading, labelled
// for screen readers.
withDefaults(defineProps<{ label?: string }>(), { label: 'Loading' })
</script>

<template>
  <div class="cc-loading" role="status" :aria-label="label">
    <v-progress-circular indeterminate color="primary" />
  </div>
</template>
