<script setup lang="ts">
// Shared "couldn't load X" alert for page-level fetch failures, with the
// standard reload hint appended to the underlying error message. Pass `retry`
// (the page's fetch function) to offer a "Try again" button; the button shows
// a busy state while the returned promise is pending.
const props = defineProps<{
  title: string
  message: string
  retry?: () => unknown
}>()

const retrying = ref(false)

async function onRetry() {
  if (!props.retry || retrying.value) return
  retrying.value = true
  try {
    await props.retry()
  } finally {
    retrying.value = false
  }
}
</script>

<template>
  <v-alert type="error" variant="tonal" :title="title" class="mb-4">
    {{ message }} — try reloading; if this persists, the database may not be
    reachable.
    <div v-if="retry" class="mt-3">
      <button
        type="button"
        class="cc-pill-btn cc-pill-btn--outline cc-pill-btn--sm"
        :disabled="retrying"
        @click="onRetry"
      >
        <v-progress-circular
          v-if="retrying"
          indeterminate
          size="16"
          width="2"
        />
        <v-icon v-else icon="mdi-refresh" size="18" />
        Try again
      </button>
    </div>
  </v-alert>
</template>
