<script setup lang="ts">
const { fetchFarms, activeFarm, farmsError } = useFarms()
const { tasks, tasksError, loading, fetchTasks } = useTasks()

// Same fetch order as tasks/index.vue: farms first so the active farm resolves
// during SSR, then that farm's tasks.
await fetchFarms()
await fetchTasks()

const locatedTasks = computed(() =>
  (tasks.value ?? []).filter((task) => task.lat !== null && task.lng !== null),
)

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
      <div class="mb-4">
        <h1 class="text-h4 mb-1">Map</h1>
        <p class="text-body-2 text-medium-emphasis">{{ activeFarm.name }}</p>
      </div>

      <v-alert
        v-if="tasksError"
        type="error"
        variant="tonal"
        title="Couldn't load tasks"
        class="mb-4"
      >
        {{ tasksError }} — try reloading; if this persists, the database may not
        be reachable.
      </v-alert>

      <div v-else-if="loading && tasks === null" class="text-center py-8">
        <v-progress-circular indeterminate color="primary" />
      </div>

      <template v-else>
        <v-card v-if="locatedTasks.length === 0" variant="tonal" class="mb-4">
          <v-card-text>
            No tasks have a location yet. Add one from a task's More details.
          </v-card-text>
        </v-card>

        <div style="height: calc(100vh - 220px); min-height: 320px">
          <TaskMap
            :tasks="locatedTasks"
            :fallback-center="farmCenter"
            @open="onOpen"
          />
        </div>
      </template>
    </template>
  </v-container>
</template>
