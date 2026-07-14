<script setup lang="ts">
import { totalTrackedMs } from '~/services/time-entries'

// Start/stop timer + tracked-time total for the View page. Only rendered
// once a task exists (parent guards with v-if="task"), so a task id is
// always present. `estimatedMinutes` lets the total render as
// "actual / estimate" when the task has an estimate.
const props = defineProps<{
  taskId: string
  estimatedMinutes: number | null
}>()

// Starting a timer can flip the task to in_progress server-side — the
// parent listens to refetch the task so the status select stays true.
const emit = defineEmits<{ started: []; completed: [] }>()

const {
  entries,
  runningEntry,
  entriesError,
  loading,
  mutating,
  mutationError,
  start,
  stop,
} = useTaskTimer(toRef(props, 'taskId'))

const runningHere = computed(() => runningEntry.value?.task_id === props.taskId)
const runningElsewhere = computed(
  () => runningEntry.value !== null && !runningHere.value,
)

// 1s ticker drives the live total while a timer runs on this task; paused
// otherwise so an idle View page does no work.
const now = ref(new Date())
let ticker: ReturnType<typeof setInterval> | undefined
watch(
  runningHere,
  (running) => {
    if (running && !ticker) {
      ticker = setInterval(() => (now.value = new Date()), 1000)
    } else if (!running && ticker) {
      clearInterval(ticker)
      ticker = undefined
    }
  },
  { immediate: true },
)
onUnmounted(() => {
  if (ticker) clearInterval(ticker)
})

const trackedMs = computed(() => totalTrackedMs(entries.value ?? [], now.value))

// "1h 30m 5s" while running (seconds make the tick visible), "1h 30m" at
// rest — sub-minute totals always show seconds so a short session isn't
// rendered as a confusing "0m".
const trackedLabel = computed(() => {
  const totalSeconds = Math.floor(trackedMs.value / 1000)
  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  if (runningHere.value || minutes === 0) {
    return minutes === 0
      ? `${seconds}s`
      : `${formatEstimatedMinutes(minutes)} ${seconds}s`
  }
  return formatEstimatedMinutes(minutes)
})

async function onStart(): Promise<void> {
  if (await start()) emit('started')
}

async function onStopAndComplete(): Promise<void> {
  await stop()
  if (!mutationError.value) emit('completed')
}
</script>

<template>
  <div>
    <p class="cc-eyebrow mb-2">Time tracked</p>

    <v-alert
      v-if="entriesError"
      type="error"
      variant="tonal"
      density="compact"
      class="mb-2"
    >
      {{ entriesError }}
    </v-alert>

    <v-alert
      v-if="mutationError"
      type="error"
      variant="tonal"
      density="compact"
      class="mb-2"
    >
      {{ mutationError }}
    </v-alert>

    <div v-if="entries === null && loading" class="py-2">
      <v-progress-circular indeterminate size="24" color="primary" />
    </div>

    <template v-else-if="entries">
      <div class="cc-timer-readout mb-3">
        <span
          class="cc-timer-time"
          :class="{ 'cc-timer-time--running': runningHere }"
        >
          <template v-if="trackedMs > 0 || runningHere">{{
            trackedLabel
          }}</template>
          <template v-else>0s</template>
        </span>
        <span
          v-if="estimatedMinutes !== null"
          class="text-body-2 text-medium-emphasis"
        >
          of {{ formatEstimatedMinutes(estimatedMinutes) }} estimated
        </span>
        <span
          v-else-if="trackedMs === 0 && !runningHere"
          class="text-body-2 text-medium-emphasis"
        >
          No time tracked yet.
        </span>
      </div>

      <div class="cc-timer-actions">
        <template v-if="runningHere">
          <button
            type="button"
            class="cc-pill-btn cc-pill-btn--outline cc-pill-btn--lg cc-timer-btn"
            :disabled="mutating"
            @click="stop"
          >
            <v-progress-circular
              v-if="mutating"
              indeterminate
              size="18"
              width="2"
            />
            <v-icon v-else icon="mdi-pause" size="20" />
            Pause
          </button>
          <button
            type="button"
            class="cc-pill-btn cc-pill-btn--success cc-pill-btn--lg cc-timer-btn"
            :disabled="mutating"
            @click="onStopAndComplete"
          >
            <v-progress-circular
              v-if="mutating"
              indeterminate
              size="18"
              width="2"
            />
            <v-icon v-else icon="mdi-check-circle-outline" size="20" />
            Complete task
          </button>
        </template>
        <button
          v-else
          type="button"
          class="cc-pill-btn cc-pill-btn--accent cc-pill-btn--lg cc-timer-btn cc-pill-btn--full"
          :disabled="mutating"
          @click="onStart"
        >
          <v-progress-circular
            v-if="mutating"
            indeterminate
            size="18"
            width="2"
          />
          <v-icon v-else icon="mdi-play" size="20" />
          {{ trackedMs > 0 ? 'Resume timer' : 'Start timer' }}
        </button>
      </div>
    </template>

    <p
      v-if="runningElsewhere"
      class="text-caption text-medium-emphasis mt-1 mb-0"
    >
      You have a timer running on another task — starting here will stop it.
    </p>
  </div>
</template>

<style scoped>
.cc-timer-readout {
  display: flex;
  align-items: baseline;
  flex-wrap: wrap;
  gap: 8px;
}

.cc-timer-time {
  font-family: var(--cc-font-slab);
  font-size: 1.75rem;
  font-weight: 700;
  line-height: 1;
  color: var(--cc-ink);
  font-variant-numeric: tabular-nums;
}

.cc-timer-time--running {
  color: var(--cc-accent);
}

.cc-timer-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}

.cc-timer-btn {
  flex: 1 1 140px;
}
</style>
