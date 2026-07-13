<script setup lang="ts">
import type { TimeEntrySummary } from '~/services/time-entries'
import { formatElapsedDuration } from '~/utils/task-display'

// Global "a timer is running" chrome, rendered once from the layout as a
// "now playing"-style dock bar: fused with the bottom nav on mobile, pinned
// to the bottom edge on desktop. Presentational — the layout owns the
// running-timer state and passes `entry: null` whenever the bar should be
// hidden (no timer, or already on the running task's own page).
const props = defineProps<{
  entry: TimeEntrySummary | null
  taskTitle: string | null
  stopping: boolean
}>()

defineEmits<{ stop: [] }>()

const { mobile } = useDisplay()

// Periodic tick, not a per-second one — the bar's elapsed time doesn't have
// to be exact (unlike TaskTimer's second-level display), so a 30s interval
// is plenty and keeps this idle chrome cheap on every page.
const now = ref(new Date())
let ticker: ReturnType<typeof setInterval> | undefined
watch(
  () => props.entry,
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
  if (!props.entry) return ''
  const started = Date.parse(props.entry.started_at)
  if (Number.isNaN(started)) return ''
  return formatElapsedDuration(now.value.getTime() - started)
})
</script>

<template>
  <Transition name="timer-bar">
    <div
      v-if="entry"
      class="timer-bar"
      :class="{ 'timer-bar--above-bottom-nav': mobile }"
    >
      <div class="timer-bar__inner">
        <NuxtLink
          :to="`/tasks/${entry.task_id}`"
          class="timer-bar__link"
          :aria-label="
            taskTitle ? `Timer running on ${taskTitle}` : 'Timer running'
          "
        >
          <span class="timer-bar__dot" aria-hidden="true" />
          <span class="timer-bar__text">
            <span class="timer-bar__eyebrow">Timer running</span>
            <span class="timer-bar__title">{{ taskTitle ?? 'View task' }}</span>
          </span>
          <span class="timer-bar__elapsed">{{ elapsedLabel }}</span>
        </NuxtLink>
        <button
          type="button"
          class="timer-bar__stop"
          :disabled="stopping"
          aria-label="Stop timer"
          title="Stop timer"
          @click="$emit('stop')"
        >
          <v-progress-circular
            v-if="stopping"
            indeterminate
            size="18"
            width="2"
          />
          <v-icon v-else icon="mdi-stop" size="22" />
        </button>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
/* Docked to the bottom edge, styled like the rest of the app chrome (cream
   surface + hairline border) rather than a floating overlay. */
.timer-bar {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 9;
  background: var(--cc-surface);
  border-top: 1px solid var(--cc-border);
  box-shadow: 0 -2px 10px rgba(43, 33, 24, 0.06);
  /* Clear the home-indicator inset when installed to the home screen. */
  padding-bottom: env(safe-area-inset-bottom, 0px);
}

/* On mobile the bar sits directly on top of the bottom nav, visually fused
   with it; the nav already absorbs the safe-area inset there. */
.timer-bar--above-bottom-nav {
  bottom: calc(56px + env(safe-area-inset-bottom, 0px));
  padding-bottom: 0;
}

/* Content row capped at the same 900px the header uses, so the bar reads as
   part of the same column of chrome on wide screens. */
.timer-bar__inner {
  height: var(--cc-timer-bar-h);
  max-width: 900px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 16px;
}

/* Everything except the stop button navigates to the running task. */
.timer-bar__link {
  flex: 1;
  min-width: 0;
  height: 100%;
  display: flex;
  align-items: center;
  gap: 12px;
  text-decoration: none;
  color: inherit;
}

.timer-bar__dot {
  flex: none;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: var(--cc-accent);
  animation: timer-bar-pulse 2s ease-in-out infinite;
}

@keyframes timer-bar-pulse {
  0%,
  100% {
    opacity: 1;
    box-shadow: 0 0 0 0 rgba(181, 84, 30, 0.35);
  }
  50% {
    opacity: 0.7;
    box-shadow: 0 0 0 5px rgba(181, 84, 30, 0);
  }
}

.timer-bar__text {
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.timer-bar__eyebrow {
  font-size: 0.6875rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--cc-ink-muted);
}

.timer-bar__title {
  font-weight: 600;
  font-size: 0.9375rem;
  line-height: 1.3;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.timer-bar__elapsed {
  flex: none;
  margin-left: auto;
  font-family: var(--cc-font-slab);
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--cc-ink);
  white-space: nowrap;
}

/* Filled danger circle, sized to the app's 44px touch-target minimum. */
.timer-bar__stop {
  flex: none;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: var(--cc-urgent-ring);
  color: #ffffff;
  border: none;
  cursor: pointer;
  padding: 0;
  box-shadow: 0 2px 6px rgba(192, 57, 31, 0.3);
}

.timer-bar__stop:disabled {
  opacity: 0.6;
  cursor: default;
}

/* Slide up from the bottom edge when a timer starts, back down when it
   stops (the mobile bar slides behind the opaque bottom nav). */
.timer-bar-enter-active,
.timer-bar-leave-active {
  transition: transform 0.25s ease;
}

.timer-bar-enter-from,
.timer-bar-leave-to {
  transform: translateY(calc(100% + 56px + env(safe-area-inset-bottom, 0px)));
}

@media (prefers-reduced-motion: reduce) {
  .timer-bar__dot {
    animation: none;
  }

  .timer-bar-enter-active,
  .timer-bar-leave-active {
    transition: none;
  }
}
</style>
