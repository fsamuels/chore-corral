<script setup lang="ts">
// The single toast host, rendered once from the layout. `lifted` mirrors
// NewTaskFab: it's true while the running-timer dock bar is showing, so the
// toast clears it.
defineProps<{ lifted?: boolean }>()

const { toast, hideToast } = useToast()
const { mobile } = useDisplay()

function onAction(): void {
  toast.value.action?.onClick()
  hideToast()
}

function onOpenChange(open: boolean): void {
  if (!open) hideToast()
}
</script>

<template>
  <!-- :key restarts the timeout when a new toast replaces the current one. -->
  <v-snackbar
    :key="toast.id"
    :model-value="toast.open"
    :timeout="toast.timeout"
    location="bottom"
    class="cc-toast"
    :class="{
      'cc-toast--error': toast.tone === 'error',
      'cc-toast--above-bottom-nav': mobile,
      'cc-toast--lifted': lifted,
    }"
    @update:model-value="onOpenChange"
  >
    <span role="status">{{ toast.message }}</span>
    <template v-if="toast.action" #actions>
      <button
        type="button"
        class="cc-text-link cc-toast__action"
        @click="onAction"
      >
        {{ toast.action.label }}
      </button>
    </template>
  </v-snackbar>
</template>

<style>
/* Unscoped: the snackbar renders in an overlay outside this component's
   scope. Unlayered, so these win over Vuetify's layered defaults. The
   bottom margin clears the same chrome NewTaskFab does: on mobile the 56px
   bottom nav plus the FAB (80px offset + 64px tall), and the timer dock bar
   when it's showing. */
.cc-toast.v-snackbar {
  margin-bottom: calc(24px + env(safe-area-inset-bottom, 0px));
  transition: margin-bottom 0.25s ease;
}

.cc-toast--above-bottom-nav.v-snackbar {
  margin-bottom: calc(80px + 64px + 8px + env(safe-area-inset-bottom, 0px));
}

.cc-toast--lifted.v-snackbar {
  margin-bottom: calc(24px + var(--cc-timer-bar-h));
}

.cc-toast--lifted.cc-toast--above-bottom-nav.v-snackbar {
  margin-bottom: calc(
    80px + 64px + 8px + var(--cc-timer-bar-h) + env(safe-area-inset-bottom, 0px)
  );
}

.cc-toast .v-snackbar__wrapper {
  background: var(--cc-ink);
  color: var(--cc-bg);
  border-radius: var(--cc-radius);
  min-width: 0;
  font-family: var(--cc-font-sans);
  font-size: 0.9375rem;
}

.cc-toast--error .v-snackbar__wrapper {
  border-left: 4px solid var(--cc-urgent-ring);
}

.cc-toast__action {
  min-height: 44px;
  padding: 0 16px;
}
</style>
