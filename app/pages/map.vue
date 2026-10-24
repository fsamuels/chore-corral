<script setup lang="ts">
import type { TaskSummary } from '~/services/tasks'

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
const selectedCategory = ref<string | null>(ALL_CATEGORIES)

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
const locatedTasks = computed<TaskSummary[]>(() => {
  const byId = new Map((locations.value ?? []).map((l) => [l.id, l]))
  const resolved: TaskSummary[] = []
  for (const task of tasks.value ?? []) {
    if (
      selectedCategory.value !== ALL_CATEGORIES &&
      task.category_id !== selectedCategory.value
    )
      continue
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

        <div class="map-frame">
          <TaskMap
            :tasks="locatedTasks"
            :locations="locations ?? []"
            :fallback-center="farmCenter"
            @open="onOpen"
          />
        </div>
      </template>
    </template>
  </div>
</template>

<style scoped>
.map-frame {
  height: calc((100dvh - 220px) * 0.9);
  min-height: 288px;
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
