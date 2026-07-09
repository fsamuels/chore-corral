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
const emit = defineEmits<{ started: [] }>()

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
</script>

<template>
  <div>
    <p class="text-body-2 mb-2">Time tracked</p>

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

    <div v-else-if="entries" class="d-flex align-center flex-wrap ga-3">
      <v-btn
        v-if="runningHere"
        color="error"
        variant="tonal"
        size="small"
        prepend-icon="mdi-stop-circle-outline"
        :loading="mutating"
        :disabled="mutating"
        @click="stop"
      >
        Stop timer
      </v-btn>
      <v-btn
        v-else
        color="primary"
        variant="tonal"
        size="small"
        prepend-icon="mdi-play-circle-outline"
        :loading="mutating"
        :disabled="mutating"
        @click="onStart"
      >
        Start timer
      </v-btn>

      <span class="text-body-2" :class="{ 'font-weight-medium': runningHere }">
        <template v-if="trackedMs > 0 || runningHere">
          {{ trackedLabel }}
          <template v-if="estimatedMinutes !== null">
            <span class="text-medium-emphasis">
              of {{ formatEstimatedMinutes(estimatedMinutes) }} estimated
            </span>
          </template>
        </template>
        <span v-else class="text-medium-emphasis">No time tracked yet.</span>
      </span>
    </div>

    <p
      v-if="runningElsewhere"
      class="text-caption text-medium-emphasis mt-1 mb-0"
    >
      You have a timer running on another task — starting here will stop it.
    </p>
  </div>
</template>
