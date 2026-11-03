<script setup lang="ts">
import type { TimeEntrySummary, TrackedSpan } from '~/services/time-entries'
import {
  formatElapsedWithSeconds,
  runningTotalLabel,
} from '~/utils/task-display'

// Global "a timer is running" chrome, rendered once from the layout as a
// "now playing"-style dock bar: fused with the bottom nav on mobile, pinned
// to the bottom edge on desktop. Presentational — the layout owns the
// running-timer state and passes `entry: null` whenever the bar should be
// hidden (no timer, or already on the running task's own page).
const props = defineProps<{
  entry: TimeEntrySummary | null
  taskTitle: string | null
  stopping: boolean
  /** Title of the chore the switch button jumps to; null hides the button. */
  previousTaskTitle?: string | null
  switching?: boolean
  /** Every session on the running chore, for the small "total" line. */
  taskSpans?: TrackedSpan[] | null
}>()

defineEmits<{ stop: []; switch: [] }>()

const { mobile } = useDisplay()

// 1s ticker, matching TaskTimer's live display — purely local (recomputes
// now - entry.started_at below), no Supabase query per tick.
const now = ref(new Date())
let ticker: ReturnType<typeof setInterval> | undefined
watch(
  () => props.entry,
  (entry) => {
    if (entry && !ticker) {
      now.value = new Date()
      ticker = setInterval(() => (now.value = new Date()), 1000)
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
  return formatElapsedWithSeconds(now.value.getTime() - started)
})

// Minute resolution, so the 1s ticker re-renders it but it only changes
// once a minute.
const totalLabel = computed(() =>
  runningTotalLabel(props.taskSpans ?? null, now.value),
)
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
            <span class="timer-bar__title">{{
              taskTitle ?? 'View chore'
            }}</span>
            <span class="timer-bar__elapsed" role="timer">{{
              elapsedLabel
            }}</span>
            <span v-if="totalLabel" class="timer-bar__total">{{
              totalLabel
            }}</span>
          </span>
        </NuxtLink>
        <button
          v-if="previousTaskTitle"
          type="button"
          class="cc-icon-btn timer-bar__switch"
          :disabled="switching || stopping"
          :aria-label="`Switch timer to ${previousTaskTitle}`"
          :title="`Switch to ${previousTaskTitle}`"
          @click="$emit('switch')"
        >
          <v-progress-circular
            v-if="switching"
            indeterminate
            size="20"
            width="3"
          />
          <v-icon v-else icon="mdi-swap-horizontal" size="26" />
        </button>
        <button
          type="button"
          class="cc-icon-btn cc-icon-btn--danger timer-bar__stop"
          :disabled="stopping"
          aria-label="Stop timer"
          title="Stop timer"
          @click="$emit('stop')"
        >
          <v-progress-circular
            v-if="stopping"
            indeterminate
            size="24"
            width="3"
          />
          <v-icon v-else icon="mdi-stop" size="32" />
        </button>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
/* Docked to the bottom edge. Inverted (deep ink with cream text, an accent
   top edge) so a running timer is the most prominent thing on any page —
   the rest of the chrome is cream, so the bar can't be mistaken for it. */
.timer-bar {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 9;
  background: var(--cc-ink);
  color: var(--cc-bg);
  border-top: 3px solid var(--cc-accent);
  box-shadow: 0 -4px 16px color-mix(in srgb, var(--cc-ink) 25%, transparent);
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
  gap: 12px;
  padding: 0 16px;
}

/* Everything except the stop button navigates to the running task. */
.timer-bar__link {
  flex: 1;
  min-width: 0;
  height: 100%;
  display: flex;
  align-items: center;
  gap: 14px;
  text-decoration: none;
  color: inherit;
}

.timer-bar__dot {
  flex: none;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: var(--cc-accent);
  animation: timer-bar-pulse 2s ease-in-out infinite;
}

@keyframes timer-bar-pulse {
  0%,
  100% {
    opacity: 1;
    box-shadow: 0 0 0 0 color-mix(in srgb, var(--cc-accent) 60%, transparent);
  }
  50% {
    opacity: 0.7;
    box-shadow: 0 0 0 9px color-mix(in srgb, var(--cc-accent) 0%, transparent);
  }
}

.timer-bar__text {
  min-width: 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.timer-bar__title {
  font-weight: 600;
  font-size: 1.0625rem;
  line-height: 1.3;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* The elapsed time is the headline — stacked under the title on its own
   line so it can be large without squeezing the title on narrow phones. */
.timer-bar__elapsed {
  font-family: var(--cc-font-slab);
  /* Scales down on narrow phones so it clears the switch and stop buttons;
     full size from ~450px wide. */
  font-size: clamp(1.75rem, 8vw, 2.25rem);
  font-weight: 700;
  color: var(--cc-surface);
  line-height: 1;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

/* Cumulative time on the chore: an FYI under the headline, deliberately
   small and dim so it never competes with the live elapsed time. */
.timer-bar__total {
  margin-top: 3px;
  font-size: 0.8125rem;
  line-height: 1.2;
  color: color-mix(in srgb, var(--cc-bg) 55%, transparent);
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

/* Bigger tap target than the default 44px icon button — this is the
   control people reach for most while a timer runs. */
.timer-bar__stop {
  flex: none;
  width: 60px;
  height: 60px;
}

/* Secondary to stop: a step smaller so the two read as distinct controls,
   but still a comfortable thumb target. */
.timer-bar__switch {
  flex: none;
  /* Translucent on the dark bar, so it reads as secondary to stop. */
  background: color-mix(in srgb, var(--cc-bg) 12%, transparent);
  border-color: color-mix(in srgb, var(--cc-bg) 30%, transparent);
  box-shadow: none;
  color: var(--cc-bg);
  width: 44px;
  height: 44px;
  margin-right: -4px;
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
