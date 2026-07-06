<script setup lang="ts">
const { fetchFarms, activeFarm, farmsError } = useFarms()
const { tagSummaries, tagSummariesError, loading, fetchTagSummaries } =
  useTagSummaries()

// Fetch farms first so the active farm resolves during SSR, then load its
// tags (the composable's watch covers later farm switches).
await fetchFarms()
await fetchTagSummaries()
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
      <h1 class="text-h4 mb-1">Tags</h1>
      <p class="text-body-2 text-medium-emphasis mb-6">{{ activeFarm.name }}</p>

      <v-alert
        v-if="tagSummariesError"
        type="error"
        variant="tonal"
        title="Couldn't load tags"
        class="mb-4"
      >
        {{ tagSummariesError }} — try reloading; if this persists, the database
        may not be reachable.
      </v-alert>

      <div
        v-else-if="loading && tagSummaries === null"
        class="text-center py-8"
      >
        <v-progress-circular indeterminate color="primary" />
      </div>

      <div
        v-else-if="!tagSummaries || tagSummaries.length === 0"
        class="text-center py-12 text-medium-emphasis"
      >
        <v-icon icon="mdi-tag-multiple-outline" size="64" class="mb-4" />
        <p class="text-body-1">
          No tags yet. Tags are added from a task's Tags field.
        </p>
      </div>

      <v-list v-else lines="one" elevation="1" rounded>
        <v-list-item
          v-for="tag in tagSummaries"
          :key="tag.id"
          :title="tag.name"
          prepend-icon="mdi-tag-outline"
        >
          <template #append>
            <v-chip size="small" variant="tonal">
              {{ tag.taskCount }} task{{ tag.taskCount === 1 ? '' : 's' }}
            </v-chip>
          </template>
        </v-list-item>
      </v-list>
    </template>
  </v-container>
</template>
