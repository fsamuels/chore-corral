<script setup lang="ts">
import type { TaskSummary } from '~/services/tasks'
import {
  countUnlocated,
  groupTasksByPlace,
  PRIORITY_LABELS,
  PRIORITY_ORDER,
} from '~/utils/map-groups'

const { fetchFarms, activeFarm, farmsError } = useFarms()
// The map only ever plots outstanding work, so skip Done tasks entirely
// (see listTasks' `excludeDone` option) rather than fetching and discarding
// a farm's full completed history.
const { tasks, tasksError, loading, fetchTasks } = useTasks({
  excludeDone: true,
})
const { locations, fetchLocations } = useLocations()
const { categories, fetchCategories } = useCategories()

// Farms first so the active farm resolves during SSR (tasks/locations/
// categories all key off activeFarmId); the other three are independent of
// each other and fetched concurrently.
await fetchFarms()
await Promise.all([fetchTasks(), fetchLocations(), fetchCategories()])

// Sentinel for "no filter"; `null` is a real value (Uncategorized), so the
// filter needs a distinct value for "all categories" — same pattern as
// /tasks' category filter. Single-select only: the only use case so far
// ("where are the fences that need fixing") is one category at a time.
const ALL_CATEGORIES = 'all'

// The filter and the view live in the URL (`?category=<id|none>&view=list`)
// so a reload, back/forward and shared links keep them. `replace` rather
// than `push`: toggling a filter shouldn't pile up history entries.
const route = useRoute()
const router = useRouter()
const UNCATEGORIZED_QUERY = 'none'

function setQuery(changes: Record<string, string | undefined>) {
  const query = { ...route.query, ...changes }
  // An undefined value means "drop this param" (back to the default).
  return router.replace({
    query: Object.fromEntries(
      Object.entries(query).filter(([, value]) => value !== undefined),
    ),
  })
}

const selectedCategory = computed<string | null>({
  get() {
    const value = route.query.category
    if (typeof value !== 'string' || !value) return ALL_CATEGORIES
    return value === UNCATEGORIZED_QUERY ? null : value
  },
  set(value) {
    setQuery({
      category:
        value === ALL_CATEGORIES
          ? undefined
          : value === null
            ? UNCATEGORIZED_QUERY
            : value,
    })
  },
})

type MapView = 'map' | 'list'
const view = computed<MapView>({
  get: () => (route.query.view === 'list' ? 'list' : 'map'),
  set: (value) => {
    setQuery({ view: value === 'list' ? 'list' : undefined })
  },
})

const categoryFilterItems = computed(() => [
  { title: 'All categories', value: ALL_CATEGORIES },
  { title: '❓ Uncategorized', value: null },
  ...(categories.value ?? []).map((category) => ({
    title: `${category.emoji ?? '🏷️'} ${category.name}`,
    value: category.id,
  })),
])

// Tasks with a freeform pin already carry lat/lng; tasks with a defined
// location only carry `location_id`, so resolve those to the location's
// coords here before handing everything to TaskMap (which just draws
// whatever lat/lng it's given — it doesn't know about location_id at all).
const filteredTasks = computed<TaskSummary[]>(() =>
  (tasks.value ?? []).filter(
    (task) =>
      selectedCategory.value === ALL_CATEGORIES ||
      task.category_id === selectedCategory.value,
  ),
)

const locatedTasks = computed<TaskSummary[]>(() => {
  const byId = new Map((locations.value ?? []).map((l) => [l.id, l]))
  const resolved: TaskSummary[] = []
  for (const task of filteredTasks.value) {
    if (task.lat !== null && task.lng !== null) {
      resolved.push(task)
      continue
    }
    if (task.location_id !== null) {
      const location = byId.get(task.location_id)
      if (location) {
        resolved.push({ ...task, lat: location.lat, lng: location.lng })
      }
    }
  }
  return resolved
})

// List view: the same filtered chores, grouped by place.
const placeGroups = computed(() =>
  groupTasksByPlace(filteredTasks.value, locations.value ?? []),
)

// Same chore set the map draws (open, category-filtered), minus what it
// can't plot.
const unlocatedCount = computed(() =>
  countUnlocated(filteredTasks.value, locations.value ?? []),
)

async function showUnlocated() {
  await setQuery({ view: 'list' })
  await nextTick()
  document
    .getElementById('place-none')
    ?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

// Map starting point before any pins are fit — the farm's default center
// (SPEC: manually set at farm creation) when known.
const farmCenter = computed(() => {
  const farm = activeFarm.value
  return farm?.default_lat != null && farm?.default_lng != null
    ? { lat: farm.default_lat, lng: farm.default_lng }
    : null
})

function onOpen(taskId: string) {
  navigateTo(`/tasks/${taskId}`)
}
</script>

<template>
  <div class="cc-page">
    <LoadErrorAlert
      v-if="farmsError"
      title="Couldn't load your farms"
      :message="farmsError"
    />
    <template v-else-if="activeFarm">
      <PageHeader title="Map" />

      <div
        class="cc-segmented map-view-toggle mb-4"
        role="group"
        aria-label="View"
      >
        <button
          type="button"
          class="cc-segmented__option"
          :class="{ 'cc-segmented__option--active': view === 'map' }"
          :aria-pressed="view === 'map'"
          @click="view = 'map'"
        >
          Map
        </button>
        <button
          type="button"
          class="cc-segmented__option"
          :class="{ 'cc-segmented__option--active': view === 'list' }"
          :aria-pressed="view === 'list'"
          @click="view = 'list'"
        >
          List
        </button>
      </div>

      <div class="d-flex flex-wrap ga-4 align-center mb-4">
        <v-select
          v-model="selectedCategory"
          :items="categoryFilterItems"
          label="Category"
          density="comfortable"
          variant="outlined"
          hide-details
          class="map-filter__field"
        />
        <button
          v-if="selectedCategory !== ALL_CATEGORIES"
          type="button"
          class="cc-text-link"
          @click="selectedCategory = ALL_CATEGORIES"
        >
          Clear filter
        </button>
      </div>

      <LoadErrorAlert
        v-if="tasksError"
        title="Couldn't load chores"
        :message="tasksError"
      />

      <LoadingState v-else-if="loading && tasks === null" />

      <!-- Keyboard / screen-reader friendly alternative to the map. -->
      <template v-else-if="view === 'list'">
        <EmptyState
          v-if="placeGroups.length === 0"
          icon="mdi-format-list-bulleted"
        >
          <template v-if="selectedCategory === ALL_CATEGORIES">
            No open chores yet.
          </template>
          <template v-else>No open chores in this category.</template>
        </EmptyState>
        <section
          v-for="group in placeGroups"
          :id="`place-${group.key}`"
          :key="group.key"
          class="map-group"
        >
          <h2 class="cc-section-title mb-3">{{ group.title }}</h2>
          <div class="cc-card-list">
            <NuxtLink
              v-for="task in group.tasks"
              :key="task.id"
              :to="`/tasks/${task.id}`"
              class="cc-card cc-card--row map-row"
            >
              <span class="map-row__title">{{ task.title }}</span>
              <span
                class="cc-pill cc-pill--sm"
                :class="`cc-pill--${task.priority}`"
              >
                {{ PRIORITY_LABELS[task.priority] }}
              </span>
            </NuxtLink>
          </div>
        </section>
      </template>

      <template v-else>
        <EmptyState
          v-if="
            locatedTasks.length === 0 &&
            (selectedCategory !== ALL_CATEGORIES ||
              (locations ?? []).length === 0)
          "
          icon="mdi-map-marker-off-outline"
        >
          <template v-if="selectedCategory === ALL_CATEGORIES">
            No chores have a location yet. Add one from a chore's location
            field.
          </template>
          <template v-else>
            No chores in this category have a location yet.
          </template>
        </EmptyState>

        <!-- Pins are tinted by priority; this explains the colours. Above the
             map so it stays visible rather than ending up under the bottom nav. -->
        <ul class="map-legend" aria-label="Pin colours">
          <li v-for="priority in PRIORITY_ORDER" :key="priority">
            <span class="cc-pill cc-pill--surface">
              <span
                class="map-legend__dot"
                :class="`map-legend__dot--${priority}`"
                aria-hidden="true"
              ></span>
              {{ PRIORITY_LABELS[priority] }}
            </span>
          </li>
        </ul>

        <div class="map-frame">
          <TaskMap
            :tasks="locatedTasks"
            :locations="locations ?? []"
            :fallback-center="farmCenter"
            @open="onOpen"
          />
        </div>

        <p v-if="unlocatedCount > 0" class="cc-muted map-unlocated">
          <button type="button" class="cc-text-link" @click="showUnlocated">
            {{ unlocatedCount }}
            {{ unlocatedCount === 1 ? 'chore has' : 'chores have' }} no location
          </button>
        </p>
      </template>
    </template>
  </div>
</template>

<style scoped>
/* Leaves room above for the toggle, filter and legend, and below for the
   unlocated-chores link, on a typical phone. */
.map-frame {
  height: calc((100dvh - 280px) * 0.75);
  min-height: 260px;
}

.map-view-toggle {
  max-width: 280px;
}

.map-group {
  margin-bottom: 28px;
}

.map-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  min-height: 44px;
  color: var(--cc-ink);
  text-decoration: none;
  font-weight: 600;
}

.map-row:hover {
  border-color: var(--cc-accent);
}

.map-row__title {
  min-width: 0;
  overflow-wrap: anywhere;
}

.map-unlocated {
  margin: 12px 0 0;
}

.map-legend {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  list-style: none;
  margin: 0 0 12px;
  padding: 0;
}

.map-legend__dot {
  display: inline-block;
  width: 12px;
  height: 12px;
  border-radius: 50%;
}

.map-legend__dot--urgent {
  background: var(--cc-urgent-ring);
}

.map-legend__dot--soon {
  background: var(--cc-soon-ring);
}

.map-legend__dot--whenever {
  background: var(--cc-whenever-ring);
}

/* Matches /tasks' .tasks-filter__field: a comfortable fixed width on desktop,
   full-width on phones so it stays an easy tap target. */
.map-filter__field {
  max-width: 220px;
}

@media (max-width: 600px) {
  .map-filter__field {
    max-width: none;
    flex: 1 1 100%;
  }
}
</style>
