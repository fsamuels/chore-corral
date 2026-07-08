<script setup lang="ts">
import {
  isTaskOverdue,
  type TaskPriority,
  type TaskStatus,
} from '~/services/tasks'
import { listActivityForTask, type ActivityEntry } from '~/services/activity'

const route = useRoute()
const router = useRouter()
const taskId = computed(() => route.params.id as string)

const { fetchFarms, activeFarm, activeFarmId, farmsError } = useFarms()
const { task, taskError, loading, fetchTask } = useTask(taskId)
const { setStatus } = useTasks()
const { categories, fetchCategories } = useCategories()

await fetchFarms()
await fetchTask()
await fetchCategories()

const statusItems: { title: string; value: TaskStatus }[] = [
  { title: 'Not started', value: 'not_started' },
  { title: 'In progress', value: 'in_progress' },
  { title: 'Done', value: 'done' },
]

const activity = ref<ActivityEntry[] | null>(null)
const activityError = ref<string | null>(null)

async function fetchActivity() {
  const farmId = activeFarmId.value
  if (!farmId) return
  try {
    activity.value = await listActivityForTask(useSupabaseClient(), {
      farmId,
      taskId: taskId.value,
    })
    activityError.value = null
  } catch (error) {
    activityError.value =
      error instanceof Error ? error.message : 'Failed to load activity'
  }
}

if (task.value) await fetchActivity()
watch(task, (value) => {
  if (value) fetchActivity()
})

function categoryDisplay(categoryId: string | null) {
  return categoryDisplayName(categoryId, categories.value)
}

const statusChanging = ref(false)
const statusChangeError = ref<string | null>(null)

async function onStatusChange(status: TaskStatus) {
  if (!task.value || task.value.status === status) return
  statusChanging.value = true
  statusChangeError.value = null
  try {
    await setStatus(task.value.id, status)
    await fetchTask()
  } catch (error) {
    statusChangeError.value =
      error instanceof Error ? error.message : 'Failed to update status'
  } finally {
    statusChanging.value = false
  }
}

// One-time warning from the create page when a staged photo failed to
// upload — read once, then stripped so a refresh doesn't reshow it (same
// pattern the old `?task=` deep link used).
const photoWarningCount = ref<number | null>(null)
if (import.meta.client) {
  onMounted(() => {
    const raw = route.query.photoWarning
    const count = typeof raw === 'string' ? Number(raw) : NaN
    if (Number.isFinite(count) && count > 0) {
      photoWarningCount.value = count
      router.replace({ query: {} })
    }
  })
}

const EVENT_ICON: Record<string, string> = {
  task_created: 'mdi-plus-circle-outline',
  task_status_changed: 'mdi-swap-horizontal',
  task_priority_changed: 'mdi-flag-outline',
  task_due_date_changed: 'mdi-calendar-clock',
  task_deleted: 'mdi-delete-outline',
}

function eventLabel(entry: ActivityEntry): string {
  if (entry.event_type === 'task_status_changed') {
    const oldStatus = String(entry.event_detail.old_status ?? '')
    const newStatus = String(entry.event_detail.new_status ?? '')
    const label = (s: string) =>
      statusItems.find((i) => i.value === s)?.title ?? s
    return `Status changed: ${label(oldStatus)} → ${label(newStatus)}`
  }
  if (entry.event_type === 'task_priority_changed') {
    const label = (p: string) => PRIORITY_DISPLAY[p as TaskPriority]?.label ?? p
    const oldPriority = String(entry.event_detail.old_priority ?? '')
    const newPriority = String(entry.event_detail.new_priority ?? '')
    return `Priority changed: ${label(oldPriority)} → ${label(newPriority)}`
  }
  if (entry.event_type === 'task_due_date_changed') {
    const label = (d: unknown) => (d == null ? 'none' : String(d))
    return `Due date changed: ${label(entry.event_detail.old_due_date)} → ${label(entry.event_detail.new_due_date)}`
  }
  if (entry.event_type === 'task_created') return 'Task created'
  if (entry.event_type === 'task_deleted') return 'Task deleted'
  return entry.event_type
}

function formatTimestamp(iso: string): string {
  const date = new Date(iso)
  return Number.isNaN(date.getTime()) ? iso : date.toLocaleString()
}

const hasLocation = computed(
  () => task.value?.lat != null && task.value?.lng != null,
)
</script>

<template>
  <v-container style="max-width: 720px">
    <v-alert
      v-if="farmsError"
      type="error"
      variant="tonal"
      title="Couldn't load your farms"
      class="mb-4"
    >
      {{ farmsError }} — try reloading; if this persists, the database may not
      be reachable.
    </v-alert>

    <template v-else-if="activeFarm">
      <v-btn
        variant="text"
        prepend-icon="mdi-arrow-left"
        to="/tasks"
        class="mb-2"
      >
        Back to tasks
      </v-btn>

      <v-alert
        v-if="taskError"
        type="error"
        variant="tonal"
        title="Couldn't load task"
        class="mb-4"
      >
        {{ taskError }} — try reloading; if this persists, the database may not
        be reachable.
      </v-alert>

      <div v-else-if="loading && task === undefined" class="text-center py-8">
        <v-progress-circular indeterminate color="primary" />
      </div>

      <div
        v-else-if="task === null"
        class="text-center py-12 text-medium-emphasis"
      >
        <v-icon icon="mdi-clipboard-alert-outline" size="64" class="mb-4" />
        <p class="text-body-1 mb-4">
          Task not found. It may have been deleted, or the link may be out of
          date.
        </p>
        <v-btn color="primary" to="/tasks">Back to tasks</v-btn>
      </div>

      <template v-else-if="task">
        <v-snackbar
          :model-value="photoWarningCount !== null"
          color="warning"
          :timeout="8000"
          @update:model-value="(v: boolean) => !v && (photoWarningCount = null)"
        >
          Task created, but {{ photoWarningCount }} photo(s) failed to upload —
          add them from Edit.
        </v-snackbar>

        <div class="d-flex align-start justify-space-between mb-4">
          <h1
            class="text-h4"
            :class="{
              'text-medium-emphasis text-decoration-line-through':
                task.status === 'done',
            }"
          >
            {{ task.title }}
          </h1>
          <v-btn
            color="primary"
            variant="tonal"
            size="large"
            prepend-icon="mdi-pencil-outline"
            :to="`/tasks/${task.id}/edit`"
          >
            Edit
          </v-btn>
        </div>

        <div class="d-flex flex-wrap ga-2 mb-6">
          <v-chip
            :prepend-icon="PRIORITY_DISPLAY[task.priority].icon"
            :color="PRIORITY_DISPLAY[task.priority].color || undefined"
          >
            {{ PRIORITY_DISPLAY[task.priority].label }}
          </v-chip>
          <v-chip
            v-if="isTaskOverdue(task)"
            color="error"
            :prepend-icon="OVERDUE_ICON"
          >
            Overdue
          </v-chip>
          <v-chip
            :class="{
              'text-medium-emphasis font-italic': categoryDisplay(
                task.category_id,
              ).deleted,
            }"
          >
            {{ categoryDisplay(task.category_id).text }}
          </v-chip>
          <v-chip v-if="task.due_date"> Due {{ task.due_date }} </v-chip>
          <v-chip
            v-if="task.estimated_minutes !== null"
            prepend-icon="mdi-timer-outline"
          >
            Est. {{ formatEstimatedMinutes(task.estimated_minutes) }}
          </v-chip>
        </div>

        <v-select
          :model-value="task.status"
          :items="statusItems"
          label="Status"
          density="comfortable"
          variant="outlined"
          :loading="statusChanging"
          hide-details
          style="max-width: 260px"
          class="mb-6"
          @update:model-value="onStatusChange"
        >
          <template #selection="{ item: selected }">
            <v-icon
              :icon="STATUS_DISPLAY[selected.value as TaskStatus].icon"
              size="small"
              class="mr-1"
            />
            {{ selected.title }}
          </template>
          <template #item="{ item: option, props: itemProps }">
            <v-list-item
              v-bind="itemProps"
              :prepend-icon="STATUS_DISPLAY[option.value as TaskStatus].icon"
            />
          </template>
        </v-select>

        <v-alert
          v-if="statusChangeError"
          type="error"
          variant="tonal"
          density="compact"
          class="mb-6"
        >
          {{ statusChangeError }}
        </v-alert>

        <div v-if="task.tags.length > 0" class="mb-6">
          <p class="text-body-2 text-medium-emphasis mb-2">Tags</p>
          <div class="d-flex flex-wrap ga-1">
            <v-chip v-for="tag in task.tags" :key="tag.id" size="small">
              {{ tag.name }}
            </v-chip>
          </div>
        </div>

        <div v-if="task.notes" class="mb-6">
          <p class="text-body-2 text-medium-emphasis mb-2">Notes</p>
          <p class="text-body-1" style="white-space: pre-wrap">
            {{ task.notes }}
          </p>
        </div>

        <div v-if="hasLocation" class="mb-6">
          <p class="text-body-2 text-medium-emphasis mb-2">Location</p>
          <TaskLocationPreview :lat="task.lat!" :lng="task.lng!" />
        </div>

        <div class="mb-6">
          <TaskPhotos :task-id="task.id" />
        </div>

        <div class="mb-6">
          <TaskShoppingList :task-id="task.id" readonly />
        </div>

        <div class="mb-6">
          <TaskTools :task-id="task.id" readonly />
        </div>

        <v-divider class="my-6" />

        <div>
          <h2 class="text-h6 mb-3">Activity</h2>
          <v-alert
            v-if="activityError"
            type="error"
            variant="tonal"
            density="compact"
            class="mb-4"
          >
            {{ activityError }}
          </v-alert>
          <p
            v-else-if="activity && activity.length === 0"
            class="text-body-2 text-medium-emphasis"
          >
            No activity recorded yet.
          </p>
          <v-timeline v-else-if="activity" density="compact" side="end">
            <v-timeline-item
              v-for="entry in activity"
              :key="entry.id"
              :icon="EVENT_ICON[entry.event_type] ?? 'mdi-circle-small'"
              size="small"
            >
              <div class="text-body-2">{{ eventLabel(entry) }}</div>
              <div class="text-caption text-medium-emphasis">
                {{ formatTimestamp(entry.created_at) }}
                <template v-if="entry.actor_email">
                  · by {{ entry.actor_email }}
                </template>
              </div>
            </v-timeline-item>
          </v-timeline>
        </div>
      </template>
    </template>
  </v-container>
</template>
