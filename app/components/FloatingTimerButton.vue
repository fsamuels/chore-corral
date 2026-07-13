<script setup lang="ts">
import { formatElapsedDuration } from '~/utils/task-display'

// Global "a timer is running" chrome — rendered once from the layout, not
// tied to any one page. Hidden on the running task's own detail page since
// TaskTimer.vue already shows the live timer there.
const { runningEntry, taskTitle } = useRunningTimer()
const route = useRoute()
const { mobile } = useDisplay()

const isOnRunningTaskPage = computed(
  () => route.path === `/tasks/${runningEntry.value?.task_id}`,
)

// Periodic tick, not a per-second one — the button's elapsed time "doesn't
// have to be exact" (unlike TaskTimer's second-level display), so a
// 30s interval is plenty and keeps this idle chrome cheap on every page.
const now = ref(new Date())
let ticker: ReturnType<typeof setInterval> | undefined
watch(
  runningEntry,
  (entry) => {
    if (entry && !ticker) {
      now.value = new Date()
      ticker = setInterval(() => (now.value = new Date()), 30000)
    } else if (!entry && ticker) {
      clearInterval(ticker)
      ticker = undefined
    }
  },
  { immediate: true },
)
onUnmounted(() => {
  if (ticker) clearInterval(ticker)
})

const elapsedLabel = computed(() => {
  if (!runningEntry.value) return ''
  const started = Date.parse(runningEntry.value.started_at)
  if (Number.isNaN(started)) return ''
  return formatElapsedDuration(now.value.getTime() - started)
})
</script>

<template>
  <NuxtLink
    v-if="runningEntry && !isOnRunningTaskPage"
    :to="`/tasks/${runningEntry.task_id}`"
    class="timer-fab"
    :class="{ 'timer-fab--above-bottom-nav': mobile }"
    :aria-label="taskTitle ? `Timer running on ${taskTitle}` : 'Timer running'"
    :title="taskTitle ? `Timer running on ${taskTitle}` : 'Timer running'"
  >
    <v-icon icon="mdi-timer-outline" size="20" />
    <span class="timer-fab__elapsed">{{ elapsedLabel }}</span>
    <span v-if="taskTitle" class="timer-fab__task">{{ taskTitle }}</span>
  </NuxtLink>
</template>

<style scoped>
/* Floating pill, mirrors .home-fab but pinned to the opposite corner so the
   two can coexist without overlapping. */
.timer-fab {
  position: fixed;
  left: 24px;
  /* Clear the home-indicator inset when installed to the home screen. */
  bottom: calc(24px + env(safe-area-inset-bottom, 0px));
  z-index: 10;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  max-width: calc(100vw - 48px);
  background: var(--cc-ink);
  color: var(--cc-surface);
  border-radius: 999px;
  padding: 12px 20px;
  font-weight: 600;
  font-size: 0.9375rem;
  text-decoration: none;
  box-shadow: 0 4px 12px rgba(43, 33, 24, 0.25);
}

.timer-fab--above-bottom-nav {
  bottom: calc(80px + env(safe-area-inset-bottom, 0px));
}

.timer-fab__elapsed {
  white-space: nowrap;
}

/* The task name is a "nice to have" that only shows when there's room:
   truncated with an ellipsis on wider screens, dropped entirely once the
   viewport is narrow enough that it'd just get squeezed to nothing. */
.timer-fab__task {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 160px;
  opacity: 0.85;
  font-weight: 400;
}

@media (max-width: 420px) {
  .timer-fab__task {
    display: none;
  }
}
</style>
