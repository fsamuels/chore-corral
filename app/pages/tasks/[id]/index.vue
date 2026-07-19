<script setup lang="ts">
import {
  isTaskOverdue,
  parseLocalDateString,
  toLocalDateString,
  type TaskPriority,
  type TaskStatus,
} from '~/services/tasks'
import { listActivityForTask, type ActivityEntry } from '~/services/activity'
import {
  listFarmMemberProfiles,
  type FarmMemberProfile,
} from '~/services/members'
import { setTaskCompleters, type TaskCompleter } from '~/services/completers'
import { memberShortLabels } from '~/utils/member-display'
import type { TaskLocationValue } from '~/components/TaskLocationInput.vue'

const route = useRoute()
const router = useRouter()
const taskId = computed(() => route.params.id as string)

const { fetchFarms, activeFarm, activeFarmId, farmsError } = useFarms()
const { task, taskError, loading, fetchTask } = useTask(taskId)
const { setStatus, update, remove } = useTasks()
const { categories, fetchCategories } = useCategories()
const { tags, fetchTags } = useTags()
const { locations, fetchLocations } = useLocations()

await fetchFarms()
await fetchTask()
await fetchCategories()
await fetchTags()
await fetchLocations()

// Farm members for the "Completed by" picker. No composable exists for this
// (only the activity service reads farm_member_profiles), so it's a direct
// service call into a local ref — refetched when the active farm changes.
const members = ref<FarmMemberProfile[]>([])

async function fetchMembers() {
  const farmId = activeFarmId.value
  if (!farmId) {
    members.value = []
    return
  }
  members.value = await listFarmMemberProfiles(useSupabaseClient(), farmId)
}

await fetchMembers()
watch(activeFarmId, () => fetchMembers())

// Resolve a task's defined-location name/coords from the farm's location
// list — the task row only carries `location_id`, not a name or coords.
function locationById(locationId: string | null) {
  if (!locationId) return null
  return (locations.value ?? []).find((l) => l.id === locationId) ?? null
}

const tagSuggestions = computed(() => (tags.value ?? []).map((t) => t.name))

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

// --- In-place field editing (immediate save per field; see DECISIONS.md) ---
// Each chip edits one field via `updateTask`'s full-field write, carrying
// the unchanged fields from the freshly loaded task.

const priorityItems: { title: string; value: TaskPriority }[] = [
  { title: 'Urgent', value: 'urgent' },
  { title: 'Soon', value: 'soon' },
  { title: 'Whenever', value: 'whenever' },
]

// Pill icon/label for the priority system (mdi-fire for urgent, clock for
// soon, no icon for whenever) — shared by the priority menu and the
// activity feed's "Priority changed" entries.
function priorityIcon(priority: TaskPriority): string | null {
  if (priority === 'urgent') return 'mdi-fire'
  if (priority === 'soon') return 'mdi-clock-outline'
  return null
}

function priorityLabel(priority: TaskPriority): string {
  if (priority === 'urgent') return 'Urgent'
  if (priority === 'soon') return 'Soon'
  return 'Whenever'
}

const categoryItems = computed(() => [
  { title: '❓ Uncategorized', value: null as string | null },
  ...(categories.value ?? []).map((category) => ({
    title: `${category.emoji ?? '🏷️'} ${category.name}`,
    value: category.id as string | null,
  })),
])

type EditableField =
  | 'priority'
  | 'category'
  | 'dueDate'
  | 'estimate'
  | 'title'
  | 'notes'
  | 'tags'
  | 'location'
  | 'completedBy'
  | 'completedAt'
const fieldSaving = ref<EditableField | null>(null)
const fieldSaveError = ref<string | null>(null)

async function saveTaskField(
  field: EditableField,
  patch: Partial<{
    categoryId: string | null
    priority: TaskPriority
    dueDate: string | null
    estimatedMinutes: number | null
    title: string
    notes: string | null
    tagNames: string[]
    lat: number | null
    lng: number | null
    locationId: string | null
    completedAt: string | null
  }>,
): Promise<boolean> {
  const current = task.value
  if (!current) return false
  fieldSaving.value = field
  fieldSaveError.value = null
  try {
    await update({
      taskId: current.id,
      title: current.title,
      categoryId: current.category_id,
      priority: current.priority,
      dueDate: current.due_date,
      estimatedMinutes: current.estimated_minutes,
      notes: current.notes,
      lat: current.lat,
      lng: current.lng,
      locationId: current.location_id,
      completedAt: current.completed_at,
      tagNames: current.tags.map((tag) => tag.name),
      ...patch,
    })
    await fetchTask()
    return true
  } catch (error) {
    fieldSaveError.value =
      error instanceof Error ? error.message : 'Failed to save change'
    return false
  } finally {
    fieldSaving.value = null
  }
}

function onPrioritySelect(priority: TaskPriority) {
  if (task.value?.priority === priority) return
  saveTaskField('priority', { priority })
}

function onCategorySelect(categoryId: string | null) {
  if ((task.value?.category_id ?? null) === categoryId) return
  saveTaskField('category', { categoryId })
}

const dueDateMenu = ref(false)
const dueDatePickerValue = computed(() =>
  task.value?.due_date ? parseLocalDateString(task.value.due_date) : null,
)

async function onDueDatePick(value: unknown) {
  if (!(value instanceof Date)) return
  const dueDate = toLocalDateString(value)
  if (task.value?.due_date === dueDate) {
    dueDateMenu.value = false
    return
  }
  if (await saveTaskField('dueDate', { dueDate })) dueDateMenu.value = false
}

async function onDueDateClear() {
  if (await saveTaskField('dueDate', { dueDate: null }))
    dueDateMenu.value = false
}

const estimateMenu = ref(false)
const estimateInput = ref('')
watch(estimateMenu, (open) => {
  if (open) {
    estimateInput.value =
      task.value?.estimated_minutes != null
        ? String(task.value.estimated_minutes)
        : ''
  }
})

async function onEstimateSave() {
  const estimatedMinutes = parseEstimatedMinutesInput(estimateInput.value)
  if (task.value?.estimated_minutes === estimatedMinutes) {
    estimateMenu.value = false
    return
  }
  if (await saveTaskField('estimate', { estimatedMinutes }))
    estimateMenu.value = false
}

// Title: click-to-edit, blur-commits (same convention as the shopping/tool
// list's inline rename). Empty is rejected by reverting rather than saving
// — a task can't be retitled to nothing, and Delete is the explicit way to
// remove a task, mirroring the shopping-list item convention.
const editingTitle = ref(false)
const titleDraft = ref('')

function startEditingTitle() {
  if (fieldSaving.value !== null || !task.value) return
  titleDraft.value = task.value.title
  editingTitle.value = true
}

function onTitleCancel() {
  editingTitle.value = false
}

async function onTitleBlur() {
  editingTitle.value = false
  const current = task.value
  if (!current) return
  const draft = titleDraft.value.trim()
  if (!draft || draft === current.title) return
  await saveTaskField('title', { title: draft })
}

// Notes: same click-to-edit, blur-commit convention. Empty is valid here
// (clears notes to null), unlike title.
const editingNotes = ref(false)
const notesDraft = ref('')

function startEditingNotes() {
  if (fieldSaving.value !== null || !task.value) return
  notesDraft.value = task.value.notes ?? ''
  editingNotes.value = true
}

function onNotesCancel() {
  editingNotes.value = false
}

async function onNotesBlur() {
  editingNotes.value = false
  const current = task.value
  if (!current) return
  const draft = notesDraft.value.trim()
  if (draft === (current.notes ?? '')) return
  await saveTaskField('notes', { notes: draft || null })
}

// Tags: click-to-edit into the same combobox the Edit page uses, but with
// explicit Save/Cancel instead of blur-commit — a combobox's menu clicks
// make blur ambiguous, unlike a plain text field.
const editingTags = ref(false)
const tagsDraft = ref<string[]>([])

function startEditingTags() {
  if (fieldSaving.value !== null || !task.value) return
  tagsDraft.value = task.value.tags.map((tag) => tag.name)
  editingTags.value = true
}

function onTagsCancel() {
  editingTags.value = false
}

async function onTagsSave() {
  const current = task.value
  if (!current) return
  const before = current.tags.map((tag) => tag.name)
  const draft = [...tagsDraft.value]
  const unchanged =
    draft.length === before.length &&
    [...draft].sort().join('\n') === [...before].sort().join('\n')
  if (unchanged) {
    editingTags.value = false
    return
  }
  if (await saveTaskField('tags', { tagNames: draft }))
    editingTags.value = false
}

// Location: explicit edit mode with Save/Cancel, like tags — a map's
// click/drag interactions rule out blur-commit, and LocationPicker itself
// provides GPS capture, manual placement, and pin removal. No auto-capture
// on open (editing must never overwrite an existing pin with wherever the
// editor happens to be standing — same call as the old Edit page).
const farmCenter = computed(() => {
  const farm = activeFarm.value
  return farm?.default_lat != null && farm?.default_lng != null
    ? { lat: farm.default_lat, lng: farm.default_lng }
    : null
})

const editingLocation = ref(false)
const locationDraft = ref<TaskLocationValue>({
  locationId: null,
  lat: null,
  lng: null,
})

function startEditingLocation() {
  if (fieldSaving.value !== null || !task.value) return
  locationDraft.value = {
    locationId: task.value.location_id,
    lat: task.value.lat,
    lng: task.value.lng,
  }
  editingLocation.value = true
}

function onLocationCancel() {
  editingLocation.value = false
}

async function onLocationSave() {
  const current = task.value
  if (!current) return
  const draft = locationDraft.value
  if (
    draft.locationId === current.location_id &&
    draft.lat === current.lat &&
    draft.lng === current.lng
  ) {
    editingLocation.value = false
    return
  }
  if (
    await saveTaskField('location', {
      lat: draft.lat,
      lng: draft.lng,
      locationId: draft.locationId,
    })
  )
    editingLocation.value = false
}

// --- Completed by (attribution) — only surfaced when the task is done ---
// Now a multi-person set (see services/completers.ts): any number of farm
// members plus any number of free-text names for people who aren't app users.
// The acting member is auto-credited on completion when nobody's credited yet
// (see changeTaskStatus), but the whole set is editable here — add/remove
// members via the multi-select, add/remove names via the freeform combobox, or
// Clear to empty it. Save replaces the full set via `setTaskCompleters`.
const completedByMenu = ref(false)
const completedByMemberDraft = ref<string[]>([])
const completedByNamesDraft = ref<string[]>([])

watch(completedByMenu, (open) => {
  if (open && task.value) {
    completedByMemberDraft.value = task.value.completers
      .filter((completer) => completer.user_id !== null)
      .map((completer) => completer.user_id!)
    completedByNamesDraft.value = task.value.completers
      .filter((completer) => completer.completer_name !== null)
      .map((completer) => completer.completer_name!)
  }
})

// Short display labels (first name; last initial or more only when needed
// to disambiguate — see memberShortLabels) for every farm member, shared by
// the picker items and the completed-by pill.
const memberLabels = computed(() => memberShortLabels(members.value))

const memberItems = computed(() =>
  members.value.map((member) => ({
    title: memberLabels.value.get(member.user_id) ?? member.user_id,
    value: member.user_id,
    avatarUrl: member.avatar_url,
  })),
)

// One completer resolved to a display label: a member's short label
// (best-effort — "unknown member" if the id is no longer in the fetched
// list), else the free-text name.
function completerLabel(completer: TaskCompleter): string {
  if (completer.user_id !== null) {
    return memberLabels.value.get(completer.user_id) ?? 'unknown member'
  }
  return completer.completer_name ?? ''
}

// The full attribution as a comma-joined label for the pill; null when the task
// has no completers set.
const completedByLabel = computed(() => {
  const completers = task.value?.completers ?? []
  if (completers.length === 0) return null
  return completers.map(completerLabel).join(', ')
})

// Save/Clear go straight through `setTaskCompleters` (not `updateTask`) — the
// completer set is its own table, edited independently of the task's fields.
async function saveCompleters(completers: TaskCompleter[]): Promise<void> {
  const current = task.value
  if (!current) return
  fieldSaving.value = 'completedBy'
  fieldSaveError.value = null
  try {
    await setTaskCompleters(useSupabaseClient(), {
      taskId: current.id,
      completers,
    })
    await fetchTask()
    completedByMenu.value = false
  } catch (error) {
    fieldSaveError.value =
      error instanceof Error ? error.message : 'Failed to save change'
  } finally {
    fieldSaving.value = null
  }
}

async function onCompletedBySave() {
  const names = [
    ...new Set(
      completedByNamesDraft.value.map((name) => name.trim()).filter(Boolean),
    ),
  ]
  const completers: TaskCompleter[] = [
    ...completedByMemberDraft.value.map((userId) => ({
      user_id: userId,
      completer_name: null,
    })),
    ...names.map((name) => ({ user_id: null, completer_name: name })),
  ]
  await saveCompleters(completers)
}

async function onCompletedByClear() {
  await saveCompleters([])
}

// --- Completed at (date/time) — only surfaced when the task is done ---
// Auto-set to "now" on the move to done (see changeTaskStatus), but
// independently editable here for a task marked done after the fact or at
// the wrong moment. A v-date-picker (date) and a time text field (time of
// day) are combined into one timestamp on save.
const completedAtMenu = ref(false)
const completedAtDateDraft = ref<Date | null>(null)
const completedAtTimeDraft = ref('')

watch(completedAtMenu, (open) => {
  if (!open) return
  const completedAt = task.value?.completed_at
  const current = completedAt ? new Date(completedAt) : new Date()
  completedAtDateDraft.value = new Date(
    current.getFullYear(),
    current.getMonth(),
    current.getDate(),
  )
  completedAtTimeDraft.value = formatTimeForInput(current)
})

function onCompletedAtDatePick(value: unknown) {
  if (value instanceof Date) completedAtDateDraft.value = value
}

const completedAtLabel = computed(() => {
  const completedAt = task.value?.completed_at
  if (!completedAt) return null
  return new Date(completedAt).toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
})

async function onCompletedAtSave() {
  if (!completedAtDateDraft.value) return
  const combined = combineDateAndTime(
    completedAtDateDraft.value,
    completedAtTimeDraft.value,
  )
  if (!combined) return
  const completedAt = combined.toISOString()
  if (task.value?.completed_at === completedAt) {
    completedAtMenu.value = false
    return
  }
  if (await saveTaskField('completedAt', { completedAt }))
    completedAtMenu.value = false
}

// --- Delete (moved here from the retired Edit page) ---
const confirmingDelete = ref(false)
const deleting = ref(false)
const deleteError = ref<string | null>(null)

async function performDelete() {
  if (!task.value) return
  deleting.value = true
  deleteError.value = null
  try {
    await remove(task.value.id)
    await navigateTo('/tasks')
  } catch (error) {
    deleteError.value =
      error instanceof Error ? error.message : 'Failed to delete chore'
  } finally {
    deleting.value = false
  }
}

// One-time warnings from the create page when a staged photo/reminder failed
// to upload/schedule — read once, then stripped so a refresh doesn't reshow
// them (same pattern the old `?task=` deep link used). Both are read (and
// the query cleared) in one pass so a chore created with both a failed photo
// and a failed reminder doesn't need two separate query-clearing round trips.
const photoWarningCount = ref<number | null>(null)
const reminderWarningCount = ref<number | null>(null)
if (import.meta.client) {
  onMounted(() => {
    function positiveCount(raw: unknown): number | null {
      const count = typeof raw === 'string' ? Number(raw) : NaN
      return Number.isFinite(count) && count > 0 ? count : null
    }
    const photoCount = positiveCount(route.query.photoWarning)
    const reminderCount = positiveCount(route.query.reminderWarning)
    if (photoCount !== null) photoWarningCount.value = photoCount
    if (reminderCount !== null) reminderWarningCount.value = reminderCount
    if (photoCount !== null || reminderCount !== null) {
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
    const label = (p: string) => priorityLabel(p as TaskPriority)
    const oldPriority = String(entry.event_detail.old_priority ?? '')
    const newPriority = String(entry.event_detail.new_priority ?? '')
    return `Priority changed: ${label(oldPriority)} → ${label(newPriority)}`
  }
  if (entry.event_type === 'task_due_date_changed') {
    const label = (d: unknown) => (d == null ? 'none' : String(d))
    return `Due date changed: ${label(entry.event_detail.old_due_date)} → ${label(entry.event_detail.new_due_date)}`
  }
  if (entry.event_type === 'task_created') return 'Chore created'
  if (entry.event_type === 'task_deleted') return 'Chore deleted'
  return entry.event_type
}

function formatTimestamp(iso: string): string {
  const date = new Date(iso)
  return Number.isNaN(date.getTime()) ? iso : date.toLocaleString()
}

// The task's defined location, resolved for display — null when the task
// uses a freeform pin instead (or has no location at all).
const taskLocation = computed(() =>
  locationById(task.value?.location_id ?? null),
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
      <v-alert
        v-if="taskError"
        type="error"
        variant="tonal"
        title="Couldn't load chore"
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
          Chore not found. It may have been deleted, or the link may be out of
          date.
        </p>
        <v-btn color="primary" to="/tasks">Back to chores</v-btn>
      </div>

      <template v-else-if="task">
        <v-snackbar
          :model-value="photoWarningCount !== null"
          color="warning"
          :timeout="8000"
          @update:model-value="(v: boolean) => !v && (photoWarningCount = null)"
        >
          Chore created, but {{ photoWarningCount }} photo(s) failed to upload —
          add them again from the Photos section below.
        </v-snackbar>

        <v-snackbar
          :model-value="reminderWarningCount !== null"
          color="warning"
          :timeout="8000"
          @update:model-value="
            (v: boolean) => !v && (reminderWarningCount = null)
          "
        >
          Chore created, but {{ reminderWarningCount }} reminder(s) failed to
          schedule — add them again from the Reminders section below.
        </v-snackbar>

        <div class="d-flex align-start justify-space-between mb-4 ga-2">
          <v-text-field
            v-if="editingTitle"
            v-model="titleDraft"
            autofocus
            density="comfortable"
            variant="outlined"
            hide-details
            class="text-h4 flex-grow-1"
            :disabled="fieldSaving === 'title'"
            @blur="onTitleBlur"
            @keydown.enter.prevent="($event.target as HTMLInputElement).blur()"
            @keydown.esc.stop="onTitleCancel"
          />
          <template v-else>
            <h1
              class="text-h4 detail-title"
              :class="{
                'text-medium-emphasis text-decoration-line-through':
                  task.status === 'done',
              }"
            >
              {{ task.title }}
            </h1>
            <button
              type="button"
              class="cc-icon-btn"
              aria-label="Edit title"
              title="Edit title"
              @click="startEditingTitle"
            >
              <v-icon icon="mdi-pencil-outline" size="18" />
            </button>
          </template>
        </div>

        <div class="d-flex flex-wrap ga-2 mb-6">
          <v-menu>
            <template #activator="{ props: activatorProps }">
              <button
                type="button"
                v-bind="activatorProps"
                class="cc-pill cc-pill--pick cc-pill-btn--sm"
                :class="`cc-pill--${task.priority}`"
                :disabled="fieldSaving !== null"
              >
                <v-icon
                  v-if="priorityIcon(task.priority)"
                  :icon="priorityIcon(task.priority)!"
                  size="14"
                />
                {{ priorityLabel(task.priority) }}
                <v-icon icon="mdi-menu-down" size="16" />
              </button>
            </template>
            <v-list density="compact">
              <v-list-item
                v-for="item in priorityItems"
                :key="item.value"
                :prepend-icon="priorityIcon(item.value) ?? undefined"
                :active="item.value === task.priority"
                @click="onPrioritySelect(item.value)"
              >
                <v-list-item-title>{{ item.title }}</v-list-item-title>
              </v-list-item>
            </v-list>
          </v-menu>

          <span
            v-if="isTaskOverdue(task)"
            class="cc-pill cc-pill--error cc-pill-btn--sm"
          >
            <v-icon :icon="OVERDUE_ICON" size="14" />
            Overdue
          </span>

          <v-menu>
            <template #activator="{ props: activatorProps }">
              <button
                type="button"
                v-bind="activatorProps"
                class="cc-pill-btn cc-pill-btn--surface cc-pill-btn--sm"
                :disabled="fieldSaving !== null"
                :class="{
                  'text-medium-emphasis font-italic': categoryDisplay(
                    task.category_id,
                  ).deleted,
                }"
              >
                {{ categoryDisplay(task.category_id).emoji }}
                {{ categoryDisplay(task.category_id).text }}
                <v-icon icon="mdi-menu-down" size="16" />
              </button>
            </template>
            <v-list density="compact">
              <v-list-item
                v-for="item in categoryItems"
                :key="item.value ?? 'uncategorized'"
                :active="item.value === (task.category_id ?? null)"
                @click="onCategorySelect(item.value)"
              >
                <v-list-item-title>{{ item.title }}</v-list-item-title>
              </v-list-item>
            </v-list>
          </v-menu>

          <v-menu v-model="dueDateMenu" :close-on-content-click="false">
            <template #activator="{ props: activatorProps }">
              <button
                type="button"
                v-bind="activatorProps"
                class="cc-pill-btn cc-pill-btn--sm"
                :class="
                  task.due_date ? 'cc-pill-btn--surface' : 'cc-pill-btn--ghost'
                "
                :disabled="fieldSaving !== null"
              >
                <v-icon
                  v-if="!task.due_date"
                  icon="mdi-calendar-plus"
                  size="16"
                />
                {{ task.due_date ? `Due ${task.due_date}` : 'Add due date' }}
                <v-icon v-if="task.due_date" icon="mdi-menu-down" size="16" />
              </button>
            </template>
            <v-card>
              <v-date-picker
                :model-value="dueDatePickerValue"
                hide-header
                show-adjacent-months
                @update:model-value="onDueDatePick"
              />
              <v-card-actions v-if="task.due_date">
                <v-spacer />
                <v-btn
                  color="error"
                  variant="text"
                  :loading="fieldSaving === 'dueDate'"
                  @click="onDueDateClear"
                >
                  Clear due date
                </v-btn>
              </v-card-actions>
            </v-card>
          </v-menu>

          <v-menu v-model="estimateMenu" :close-on-content-click="false">
            <template #activator="{ props: activatorProps }">
              <button
                type="button"
                v-bind="activatorProps"
                class="cc-pill-btn cc-pill-btn--sm"
                :class="
                  task.estimated_minutes !== null
                    ? 'cc-pill-btn--surface'
                    : 'cc-pill-btn--ghost'
                "
                :disabled="fieldSaving !== null"
              >
                <v-icon
                  v-if="task.estimated_minutes === null"
                  icon="mdi-timer-outline"
                  size="16"
                />
                {{
                  task.estimated_minutes !== null
                    ? `Est. ${formatEstimatedMinutes(task.estimated_minutes)}`
                    : '+ Estimate'
                }}
                <v-icon
                  v-if="task.estimated_minutes !== null"
                  icon="mdi-menu-down"
                  size="16"
                />
              </button>
            </template>
            <v-card min-width="280">
              <v-card-text>
                <v-text-field
                  v-model="estimateInput"
                  label="Estimated time (minutes)"
                  type="number"
                  min="1"
                  step="1"
                  density="comfortable"
                  variant="outlined"
                  hide-details
                  autofocus
                  @keydown.enter="onEstimateSave"
                />
              </v-card-text>
              <v-card-actions>
                <v-spacer />
                <v-btn @click="estimateMenu = false">Cancel</v-btn>
                <v-btn
                  color="primary"
                  :loading="fieldSaving === 'estimate'"
                  @click="onEstimateSave"
                >
                  Save
                </v-btn>
              </v-card-actions>
            </v-card>
          </v-menu>
        </div>

        <v-alert
          v-if="fieldSaveError"
          type="error"
          variant="tonal"
          density="compact"
          class="mb-6"
        >
          {{ fieldSaveError }}
        </v-alert>

        <div class="cc-eyebrow mb-2">Status</div>
        <div class="cc-segmented mb-6" role="group" aria-label="Chore status">
          <button
            v-for="item in statusItems"
            :key="item.value"
            type="button"
            class="cc-segmented__option"
            :class="{
              'cc-segmented__option--active':
                task.status === item.value && item.value === 'not_started',
              'cc-segmented__option--active-progress':
                task.status === item.value && item.value === 'in_progress',
              'cc-segmented__option--active-done':
                task.status === item.value && item.value === 'done',
            }"
            :disabled="statusChanging"
            :aria-pressed="task.status === item.value"
            @click="onStatusChange(item.value)"
          >
            <v-icon :icon="STATUS_DISPLAY[item.value].icon" size="16" />
            {{ item.title }}
          </button>
        </div>

        <v-alert
          v-if="statusChangeError"
          type="error"
          variant="tonal"
          density="compact"
          class="mb-6"
        >
          {{ statusChangeError }}
        </v-alert>

        <div v-if="task.status === 'done'" class="mb-6">
          <div class="cc-eyebrow mb-2">Completed by</div>
          <v-menu v-model="completedByMenu" :close-on-content-click="false">
            <template #activator="{ props: activatorProps }">
              <button
                type="button"
                v-bind="activatorProps"
                class="cc-pill-btn cc-pill-btn--sm"
                :class="
                  completedByLabel !== null
                    ? 'cc-pill-btn--surface'
                    : 'cc-pill-btn--ghost'
                "
                :disabled="fieldSaving !== null"
              >
                <v-icon
                  v-if="completedByLabel === null"
                  icon="mdi-account-plus-outline"
                  size="16"
                />
                {{
                  completedByLabel !== null
                    ? `Completed by ${completedByLabel}`
                    : '+ Completed by'
                }}
                <v-icon
                  v-if="completedByLabel !== null"
                  icon="mdi-menu-down"
                  size="16"
                />
              </button>
            </template>
            <v-card min-width="320">
              <v-card-text>
                <v-select
                  v-model="completedByMemberDraft"
                  :items="memberItems"
                  item-title="title"
                  item-value="value"
                  label="Farm members"
                  multiple
                  chips
                  closable-chips
                  density="comfortable"
                  variant="outlined"
                  hide-details
                >
                  <template #item="{ props: itemProps, item }">
                    <v-list-item v-bind="itemProps">
                      <template #prepend>
                        <MemberAvatar
                          :src="item.avatarUrl"
                          :size="28"
                          class="mr-3"
                        />
                      </template>
                    </v-list-item>
                  </template>
                  <template #chip="{ props: chipProps, item }">
                    <v-chip v-bind="chipProps">
                      <template #prepend>
                        <MemberAvatar
                          :src="item.avatarUrl"
                          :size="20"
                          class="mr-1"
                        />
                      </template>
                      {{ item.title }}
                    </v-chip>
                  </template>
                </v-select>
                <div class="text-caption text-medium-emphasis my-2">
                  and/or others (type a name, press enter)
                </div>
                <v-combobox
                  v-model="completedByNamesDraft"
                  label="Other names"
                  multiple
                  chips
                  closable-chips
                  density="comfortable"
                  variant="outlined"
                  hide-details
                />
              </v-card-text>
              <v-card-actions>
                <v-btn
                  color="error"
                  variant="text"
                  :loading="fieldSaving === 'completedBy'"
                  @click="onCompletedByClear"
                >
                  Clear
                </v-btn>
                <v-spacer />
                <v-btn @click="completedByMenu = false">Cancel</v-btn>
                <v-btn
                  color="primary"
                  :loading="fieldSaving === 'completedBy'"
                  @click="onCompletedBySave"
                >
                  Save
                </v-btn>
              </v-card-actions>
            </v-card>
          </v-menu>
        </div>

        <div v-if="task.status === 'done'" class="mb-6">
          <div class="cc-eyebrow mb-2">Completed at</div>
          <v-menu v-model="completedAtMenu" :close-on-content-click="false">
            <template #activator="{ props: activatorProps }">
              <button
                type="button"
                v-bind="activatorProps"
                class="cc-pill-btn cc-pill-btn--sm"
                :class="
                  completedAtLabel !== null
                    ? 'cc-pill-btn--surface'
                    : 'cc-pill-btn--ghost'
                "
                :disabled="fieldSaving !== null"
              >
                <v-icon icon="mdi-calendar-clock" size="16" />
                {{
                  completedAtLabel !== null
                    ? `Completed ${completedAtLabel}`
                    : 'Set completion date'
                }}
                <v-icon icon="mdi-menu-down" size="16" />
              </button>
            </template>
            <v-card min-width="280">
              <v-date-picker
                :model-value="completedAtDateDraft"
                hide-header
                show-adjacent-months
                @update:model-value="onCompletedAtDatePick"
              />
              <v-card-text class="pt-0">
                <v-text-field
                  v-model="completedAtTimeDraft"
                  type="time"
                  label="Time"
                  density="comfortable"
                  variant="outlined"
                  hide-details
                />
              </v-card-text>
              <v-card-actions>
                <v-spacer />
                <v-btn @click="completedAtMenu = false">Cancel</v-btn>
                <v-btn
                  color="primary"
                  :loading="fieldSaving === 'completedAt'"
                  @click="onCompletedAtSave"
                >
                  Save
                </v-btn>
              </v-card-actions>
            </v-card>
          </v-menu>
        </div>

        <div class="cc-card mb-6">
          <TaskTimer
            :task-id="task.id"
            :estimated-minutes="task.estimated_minutes"
            @started="fetchTask"
            @completed="onStatusChange('done')"
          />
        </div>

        <div class="cc-card mb-6">
          <p class="cc-eyebrow mb-2">Tags</p>
          <template v-if="editingTags">
            <v-combobox
              v-model="tagsDraft"
              :items="tagSuggestions"
              multiple
              chips
              closable-chips
              autofocus
              density="comfortable"
              variant="outlined"
              hide-details
              :disabled="fieldSaving === 'tags'"
              @keydown.esc.stop="onTagsCancel"
            />
            <div class="d-flex justify-end ga-2 mt-2">
              <v-btn
                size="small"
                :disabled="fieldSaving === 'tags'"
                @click="onTagsCancel"
              >
                Cancel
              </v-btn>
              <v-btn
                size="small"
                color="primary"
                :loading="fieldSaving === 'tags'"
                @click="onTagsSave"
              >
                Save
              </v-btn>
            </div>
          </template>
          <div
            v-else
            role="button"
            tabindex="0"
            style="cursor: pointer"
            @click="startEditingTags"
            @keydown.enter="startEditingTags"
          >
            <div
              v-if="task.tags.length > 0"
              class="d-flex flex-wrap align-center ga-1"
            >
              <v-chip v-for="tag in task.tags" :key="tag.id" size="small">
                {{ tag.name }}
              </v-chip>
              <v-icon
                icon="mdi-pencil-outline"
                size="small"
                class="text-medium-emphasis"
              />
            </div>
            <button
              v-else
              type="button"
              class="cc-pill-btn cc-pill-btn--ghost cc-pill-btn--sm"
              @click="startEditingTags"
            >
              + Add tags
            </button>
          </div>
        </div>

        <div class="cc-card mb-6">
          <p class="cc-eyebrow mb-2">Notes</p>
          <textarea
            v-if="editingNotes"
            v-model="notesDraft"
            autofocus
            rows="3"
            class="cc-field"
            :disabled="fieldSaving === 'notes'"
            @blur="onNotesBlur"
            @keydown.esc.stop="onNotesCancel"
          />
          <p
            v-else
            class="text-body-1"
            :class="{ 'text-medium-emphasis font-italic': !task.notes }"
            style="white-space: pre-wrap; cursor: pointer"
            role="button"
            tabindex="0"
            @click="startEditingNotes"
            @keydown.enter="startEditingNotes"
          >
            {{ task.notes || 'Add notes' }}
          </p>
        </div>

        <div class="cc-card mb-6">
          <p class="cc-eyebrow mb-2">Location</p>
          <template v-if="editingLocation">
            <TaskLocationInput
              v-model="locationDraft"
              :locations="locations ?? []"
              :fallback-center="farmCenter"
              :disabled="fieldSaving === 'location'"
            />
            <div class="d-flex justify-end ga-2 mt-2">
              <v-btn
                size="small"
                :disabled="fieldSaving === 'location'"
                @click="onLocationCancel"
              >
                Cancel
              </v-btn>
              <v-btn
                size="small"
                color="primary"
                :loading="fieldSaving === 'location'"
                @click="onLocationSave"
              >
                Save
              </v-btn>
            </div>
          </template>
          <template v-else-if="taskLocation">
            <v-chip prepend-icon="mdi-map-marker" class="mb-2">
              {{ taskLocation.name }}
            </v-chip>
            <div class="detail-map">
              <TaskLocationPreview
                :lat="taskLocation.lat"
                :lng="taskLocation.lng"
              />
            </div>
            <button
              type="button"
              class="cc-pill-btn cc-pill-btn--outline cc-pill-btn--sm cc-pill-btn--full mt-3"
              @click="startEditingLocation"
            >
              <v-icon icon="mdi-pencil-outline" size="16" />
              Edit location
            </button>
          </template>
          <template v-else-if="task.lat !== null && task.lng !== null">
            <div class="detail-map">
              <TaskLocationPreview :lat="task.lat" :lng="task.lng" />
            </div>
            <button
              type="button"
              class="cc-pill-btn cc-pill-btn--outline cc-pill-btn--sm cc-pill-btn--full mt-3"
              @click="startEditingLocation"
            >
              <v-icon icon="mdi-pencil-outline" size="16" />
              Edit location
            </button>
          </template>
          <template v-else-if="task.location_id !== null">
            <!-- location_id set but unresolved: the referenced location was
                 soft-deleted after this (non-active) task was assigned to
                 it, so useLocations() no longer returns it. -->
            <p class="text-body-1 text-medium-emphasis font-italic mb-2">
              Location no longer available
            </p>
            <button
              type="button"
              class="cc-pill-btn cc-pill-btn--outline cc-pill-btn--sm cc-pill-btn--full"
              @click="startEditingLocation"
            >
              <v-icon icon="mdi-pencil-outline" size="16" />
              Edit location
            </button>
          </template>
          <button
            v-else
            type="button"
            class="cc-pill-btn cc-pill-btn--ghost cc-pill-btn--sm"
            @click="startEditingLocation"
          >
            + Add location
          </button>
        </div>

        <div class="cc-card mb-6">
          <TaskPhotos :task-id="task.id" />
        </div>

        <div class="cc-card mb-6">
          <TaskShoppingList :task-id="task.id" />
        </div>

        <div class="cc-card mb-6">
          <TaskTools :task-id="task.id" />
        </div>

        <div class="cc-card mb-6">
          <TaskReminders :task-id="task.id" />
        </div>

        <div class="cc-card mb-6">
          <h2 class="cc-section-title mb-3">Activity</h2>
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
                <template v-if="entry.actor_label">
                  · by {{ entry.actor_label }}
                </template>
              </div>
            </v-timeline-item>
          </v-timeline>
        </div>

        <div class="detail-delete">
          <button
            type="button"
            class="cc-pill-btn cc-pill-btn--danger cc-pill-btn--lg cc-pill-btn--full"
            :disabled="fieldSaving !== null"
            @click="confirmingDelete = true"
          >
            <v-icon icon="mdi-delete-outline" size="18" />
            Delete chore
          </button>
        </div>

        <v-dialog v-model="confirmingDelete" max-width="420" persistent>
          <v-card>
            <v-card-title>Delete chore?</v-card-title>
            <v-card-text>
              Delete "{{ task.title }}"? This can't be undone.
              <v-alert
                v-if="deleteError"
                type="error"
                variant="tonal"
                density="compact"
                class="mt-3"
              >
                {{ deleteError }}
              </v-alert>
            </v-card-text>
            <v-card-actions>
              <v-spacer />
              <v-btn
                size="large"
                :disabled="deleting"
                @click="confirmingDelete = false"
              >
                Cancel
              </v-btn>
              <v-btn
                color="error"
                size="large"
                :loading="deleting"
                @click="performDelete"
              >
                Delete
              </v-btn>
            </v-card-actions>
          </v-card>
        </v-dialog>
      </template>
    </template>
  </v-container>
</template>

<style scoped>
/* Each section below is a .cc-card, whose shared 20px padding is more top
   space than a section needs once its eyebrow label sits right at the
   top edge — trim just the top side, keep the rest for breathing room. */
.cc-card {
  padding-top: 8px;
}

/* Clickable priority pill (menu activator) — reset button chrome, keep the
   cc-pill look, add a disabled state to match the surrounding v-chips. */
.cc-pill--pick {
  border: none;
  cursor: pointer;
  font-family: var(--cc-font-sans);
}

.cc-pill--pick:disabled {
  opacity: 0.6;
  cursor: default;
}

.detail-title {
  flex: 1;
  min-width: 0;
  overflow-wrap: anywhere;
}

/* Round the map preview's corners to match the rest of the page — the
   Leaflet container itself doesn't take a border-radius directly. */
.detail-map {
  border-radius: var(--cc-radius);
  overflow: hidden;
}

.detail-delete {
  margin-top: 32px;
  padding-top: 24px;
  border-top: 1px solid var(--cc-border);
}

/* Ring the activity timeline's dots in the shared track color instead of
   Vuetify's default. */
:deep(.v-timeline-item .v-timeline-item__dot) {
  background: var(--cc-track);
  box-shadow: none;
}

:deep(.v-timeline-item .v-timeline-item__inner-dot) {
  color: var(--cc-ink);
}
</style>
