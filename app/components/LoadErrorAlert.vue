<script setup lang="ts">
// Shared "couldn't load X" alert for page-level fetch failures, with the
// standard reload hint appended to the underlying error message.
defineProps<{ title: string; message: string }>()
</script>

<template>
  <v-alert type="error" variant="tonal" :title="title" class="mb-4">
    {{ message }} — try reloading; if this persists, the database may not be
    reachable.
  </v-alert>
</template>
