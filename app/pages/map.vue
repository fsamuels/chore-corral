<script setup lang="ts">
import type { TaskSummary } from '~/services/tasks'

const { fetchFarms, activeFarm, farmsError } = useFarms()
const { tasks, tasksError, loading, fetchTasks } = useTasks()
const { locations, fetchLocations } = useLocations()
const { categories, fetchCategories } = useCategories()

// Same fetch order as tasks/index.vue: farms first so the active farm resolves
// during SSR, then that farm's tasks, defined locations, and categories (for
// the category filter below).
await fetchFarms()
await fetchTasks()
await fetchLocations()
await fetchCategories()

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
    if (task.status === 'done') continue
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
        <v-btn
          v-if="selectedCategory !== ALL_CATEGORIES"
          variant="text"
          density="comfortable"
          prepend-icon="mdi-filter-remove-outline"
          @click="selectedCategory = ALL_CATEGORIES"
        >
          Clear filter
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

      <div v-else-if="loading && tasks === null" class="text-center py-8">
        <v-progress-circular indeterminate color="primary" />
      </div>

      <template v-else>
        <v-card
          v-if="
            locatedTasks.length === 0 &&
            (selectedCategory !== ALL_CATEGORIES ||
              (locations ?? []).length === 0)
          "
          variant="tonal"
          class="mb-4"
        >
          <v-card-text>
            <template v-if="selectedCategory === ALL_CATEGORIES">
              No chores have a location yet. Add one from a chore's location
              field.
            </template>
            <template v-else>
              No chores in this category have a location yet.
            </template>
          </v-card-text>
        </v-card>

        <div style="height: calc((100vh - 220px) * 0.9); min-height: 288px">
          <TaskMap
            :tasks="locatedTasks"
            :locations="locations ?? []"
            :fallback-center="farmCenter"
            @open="onOpen"
          />
        </div>
      </template>
    </template>
  </v-container>
</template>

<style scoped>
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
