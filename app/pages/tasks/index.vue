<script setup lang="ts">
import type { Database } from '~/types/database.types'
import {
  compareTasksDoneLast,
  listDoneTasks,
  toLocalDateString,
  type TaskPriority,
  type TaskStatus,
  type TaskSummary,
} from '~/services/tasks'
import {
  ALL,
  defaultTaskFilters,
  filterTasks,
  type DueDateFilter,
} from '~/utils/task-filters'
import {
  listFarmMemberProfiles,
  type FarmMemberProfile,
} from '~/services/members'
import { memberShortLabels } from '~/utils/member-display'
import { assigneeDisplayNames } from '~/utils/task-display'

const route = useRoute()
const supabase = useSupabaseClient<Database>()
const { fetchFarms, activeFarm, activeFarmId, farmsError } = useFarms()
// Outstanding tasks (a farm's active workload, which stays small) are
// always fetched in full; Done tasks have no natural bound — SPEC keeps
// them visible/filterable forever — so they're paged in separately below
// instead of being pulled all at once on every visit.
const {
  tasks: outstandingTasks,
  tasksError,
  loading,
  fetchTasks,
} = useTasks({ excludeDone: true })
const { categories, fetchCategories } = useCategories()
const { tags, fetchTags } = useTags()
const { locations, fetchLocations } = useLocations()

const doneTasks = ref<TaskSummary[]>([])
const doneHasMore = ref(false)
const doneLoading = ref(false)
const doneOffset = ref(0)

async function fetchDonePage(reset: boolean): Promise<void> {
  const farmId = activeFarmId.value
  if (!farmId) {
    doneTasks.value = []
    doneHasMore.value = false
    return
  }
  if (reset) doneOffset.value = 0
  doneLoading.value = true
  try {
    const result = await listDoneTasks(supabase, farmId, {
      offset: doneOffset.value,
    })
    doneTasks.value = reset
      ? result.tasks
      : [...doneTasks.value, ...result.tasks]
    doneHasMore.value = result.hasMore
    doneOffset.value += result.tasks.length
  } finally {
    doneLoading.value = false
  }
}

// All tasks the page currently has loaded: the full outstanding set plus
// however many Done pages have been fetched so far.
const tasks = computed<TaskSummary[]>(() => [
  ...(outstandingTasks.value ?? []),
  ...doneTasks.value,
])

// Farm members, resolved to short labels for each card's assignee indicator
// — mirrors the same fetch on the home page (index.vue).
const members = ref<FarmMemberProfile[]>([])

async function fetchMembers() {
  const farmId = activeFarmId.value
  if (!farmId) {
    members.value = []
    return
  }
  members.value = await listFarmMemberProfiles(supabase, farmId)
}

// Fetch farms first so the active farm resolves during SSR (everything else
// keys off activeFarmId); the rest are independent of each other and fetched
// concurrently. Later farm switches are covered by each composable's own
// watch, plus the explicit watch below for the Done-task pages and members.
await fetchFarms()
await Promise.all([
  fetchTasks(),
  fetchDonePage(true),
  fetchCategories(),
  fetchTags(),
  fetchLocations(),
  fetchMembers(),
])
watch(activeFarmId, () => {
  fetchDonePage(true)
  fetchMembers()
})

const memberLabels = computed(() => memberShortLabels(members.value))

function assigneeNames(assigneeIds: string[]): string[] {
  return assigneeDisplayNames(assigneeIds, memberLabels.value)
}

const today = computed(() => toLocalDateString(new Date()))

const KNOWN_STATUSES: TaskStatus[] = ['not_started', 'in_progress', 'done']

const statusFilterItems = [
  { title: 'All statuses', value: ALL },
  { title: 'Not started', value: 'not_started' },
  { title: 'In progress', value: 'in_progress' },
  { title: 'Done', value: 'done' },
]

const priorityFilterItems: {
  title: string
  value: TaskPriority | typeof ALL
}[] = [
  { title: 'All priorities', value: ALL },
  { title: 'Urgent', value: 'urgent' },
  { title: 'Soon', value: 'soon' },
  { title: 'Whenever', value: 'whenever' },
]

const dueDateFilterItems: { title: string; value: DueDateFilter }[] = [
  { title: 'Any due date', value: ALL },
  { title: 'Has due date', value: 'has_due_date' },
  { title: 'No due date', value: 'no_due_date' },
]

const categoryItems = computed(() =>
  (categories.value ?? []).map((category) => ({
    title: `${category.emoji ?? '🏷️'} ${category.name}`,
    value: category.id,
  })),
)

// Sentinel for "no filter"; `null` is a real value (Uncategorized), so the
// filter needs a distinct value for "all categories".
const ALL_CATEGORIES = 'all'
const selectedCategory = ref<string | null>(ALL_CATEGORIES)

const categoryFilterItems = computed(() => [
  { title: 'All categories', value: ALL_CATEGORIES },
  { title: '❓ Uncategorized', value: null },
  ...categoryItems.value,
])

// Tag filter matches by tag name (tasks carry their tags inline). 'all' is the
// no-filter sentinel; the picker is populated from the farm's full tag list.
const ALL_TAGS = 'all'
const selectedTag = ref<string>(ALL_TAGS)

const tagFilterItems = computed(() => [
  { title: 'All tags', value: ALL_TAGS },
  ...(tags.value ?? []).map((tag) => ({ title: tag.name, value: tag.name })),
])

// Location filter matches by id (locations aren't addressable by name, and
// two locations could share a name). 'all' is the no-filter sentinel.
const ALL_LOCATIONS = 'all'
const selectedLocation = ref<string>(ALL_LOCATIONS)

const locationFilterItems = computed(() => [
  { title: 'All locations', value: ALL_LOCATIONS },
  ...(locations.value ?? []).map((location) => ({
    title: location.name,
    value: location.id,
  })),
])

const filters = ref(defaultTaskFilters())

// The tags/categories/locations pages deep-link here with
// `?tag=<name>&status=<status>`, `?category=<id>&status=<status>`, or
// `?location=<id>&status=<status>`; sync those query params into the
// filters, both on first load and on later in-app navigation to a new query
// (the page component is reused, so a watcher is needed — setup doesn't
// re-run).
function applyQuery() {
  const category = route.query.category
  selectedCategory.value =
    typeof category === 'string' && category ? category : ALL_CATEGORIES

  const tag = route.query.tag
  selectedTag.value = typeof tag === 'string' && tag ? tag : ALL_TAGS

  const location = route.query.location
  selectedLocation.value =
    typeof location === 'string' && location ? location : ALL_LOCATIONS

  const status = route.query.status
  filters.value.status =
    typeof status === 'string' && (KNOWN_STATUSES as string[]).includes(status)
      ? (status as TaskStatus)
      : ALL
}
watch(() => route.query, applyQuery, { immediate: true })

const hasActiveFilters = computed(
  () =>
    selectedCategory.value !== ALL_CATEGORIES ||
    selectedTag.value !== ALL_TAGS ||
    selectedLocation.value !== ALL_LOCATIONS ||
    filters.value.status !== ALL ||
    filters.value.priority !== ALL ||
    filters.value.dueDate !== ALL ||
    filters.value.overdueOnly ||
    (filters.value.search ?? '').trim() !== '',
)

function resetFilters() {
  selectedCategory.value = ALL_CATEGORIES
  selectedTag.value = ALL_TAGS
  selectedLocation.value = ALL_LOCATIONS
  filters.value = defaultTaskFilters()
}

const filteredTasks = computed(() => {
  const all = tasks.value ?? []
  const byCategory =
    selectedCategory.value === ALL_CATEGORIES
      ? all
      : all.filter((task) => task.category_id === selectedCategory.value)
  const byTag =
    selectedTag.value === ALL_TAGS
      ? byCategory
      : byCategory.filter((task) =>
          task.tags.some((tag) => tag.name === selectedTag.value),
        )
  const byLocation =
    selectedLocation.value === ALL_LOCATIONS
      ? byTag
      : byTag.filter((task) => task.location_id === selectedLocation.value)
  return filterTasks(byLocation, filters.value).sort(compareTasksDoneLast)
})

function categoryName(categoryId: string | null): string {
  return categoryDisplayName(categoryId, categories.value).text
}

function locationName(locationId: string | null): string | null {
  return locationDisplayName(locationId, locations.value)
}
</script>

<template>
  <v-container>
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
      <h1 class="text-h4 mb-1">Chores</h1>
      <p class="cc-eyebrow mb-4">{{ activeFarm.name }}</p>

      <v-text-field
        v-model="filters.search"
        label="Search by title"
        prepend-inner-icon="mdi-magnify"
        density="comfortable"
        variant="outlined"
        hide-details
        clearable
        class="mb-4 tasks-search"
      />

      <div class="d-flex flex-wrap ga-4 align-center mb-4">
        <v-select
          v-model="selectedCategory"
          :items="categoryFilterItems"
          label="Category"
          density="comfortable"
          variant="outlined"
          hide-details
          class="tasks-filter__field"
        />
        <v-select
          v-model="selectedTag"
          :items="tagFilterItems"
          label="Tag"
          density="comfortable"
          variant="outlined"
          hide-details
          class="tasks-filter__field"
        />
        <v-select
          v-model="selectedLocation"
          :items="locationFilterItems"
          label="Location"
          density="comfortable"
          variant="outlined"
          hide-details
          class="tasks-filter__field"
        />
        <v-select
          v-model="filters.status"
          :items="statusFilterItems"
          label="Status"
          density="comfortable"
          variant="outlined"
          hide-details
          class="tasks-filter__field"
        />
        <v-select
          v-model="filters.priority"
          :items="priorityFilterItems"
          label="Priority"
          density="comfortable"
          variant="outlined"
          hide-details
          class="tasks-filter__field"
        />
        <v-select
          v-model="filters.dueDate"
          :items="dueDateFilterItems"
          label="Due date"
          density="comfortable"
          variant="outlined"
          hide-details
          class="tasks-filter__field"
        />
        <v-checkbox
          v-model="filters.overdueOnly"
          label="Overdue only"
          density="comfortable"
          hide-details
        />
        <v-btn
          v-if="hasActiveFilters"
          variant="text"
          density="comfortable"
          prepend-icon="mdi-filter-remove-outline"
          @click="resetFilters"
        >
          Clear filters
        </v-btn>
      </div>

      <v-alert
        v-if="tasksError"
        type="error"
        variant="tonal"
        title="Couldn't load chores"
        class="mb-4"
      >
        {{ tasksError }} — try reloading; if this persists, the database may not
        be reachable.
      </v-alert>

      <div
        v-else-if="loading && outstandingTasks === null"
        class="text-center py-8"
      >
        <v-progress-circular indeterminate color="primary" />
      </div>

      <div
        v-else-if="tasks.length === 0"
        class="text-center py-12 text-medium-emphasis"
      >
        <v-icon icon="mdi-clipboard-text-outline" size="64" class="mb-4" />
        <p class="text-body-1 mb-4">
          No chores yet. Add one to start tracking work on this farm.
        </p>
        <v-btn color="primary" size="large" to="/tasks/new">New chore</v-btn>
      </div>

      <div
        v-else-if="filteredTasks.length === 0"
        class="text-center py-12 text-medium-emphasis"
      >
        <v-icon icon="mdi-filter-variant-remove" size="64" class="mb-4" />
        <p class="text-body-1">No chores match the current filters.</p>
        <v-btn
          v-if="hasActiveFilters"
          variant="text"
          class="mt-2"
          @click="resetFilters"
        >
          Clear filters
        </v-btn>
      </div>

      <div v-else class="tasks-list__cards">
        <TaskCard
          v-for="item in filteredTasks"
          :key="item.id"
          :task="item"
          :category-name="categoryName(item.category_id)"
          :location-name="locationName(item.location_id)"
          :assignee-names="assigneeNames(item.assignee_ids)"
          :today="today"
          hide-check
        />
      </div>

      <div v-if="doneHasMore" class="text-center mt-4">
        <v-btn
          variant="outlined"
          :loading="doneLoading"
          @click="fetchDonePage(false)"
        >
          Load more completed chores
        </v-btn>
      </div>
    </template>
  </v-container>
</template>

<style scoped>
.tasks-list__cards {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.tasks-search {
  max-width: 400px;
}

/* Filter selects sit at a comfortable width on desktop but stretch to fill
   the row on phones, so each stays an easy tap target instead of a cramped
   square. */
.tasks-filter__field {
  max-width: 220px;
}

@media (max-width: 600px) {
  .tasks-search {
    max-width: 100%;
  }

  .tasks-filter__field {
    max-width: none;
    flex: 1 1 100%;
  }
}
</style>
