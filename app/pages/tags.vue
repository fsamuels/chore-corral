<script setup lang="ts">
const { fetchFarms, activeFarm, farmsError } = useFarms()
const { tags, tagsError, loading, fetchTags } = useTagSummaries()

// Fetch farms first so the active farm resolves during SSR, then load its
// tags (the composable's watch covers later farm switches).
await fetchFarms()
await fetchTags()
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
      <p class="cc-eyebrow mb-6">{{ activeFarm.name }}</p>

      <v-alert
        v-if="tagsError"
        type="error"
        variant="tonal"
        title="Couldn't load tags"
        class="mb-4"
      >
        {{ tagsError }} — try reloading; if this persists, the database may not
        be reachable.
      </v-alert>

      <div v-else-if="loading && tags === null" class="text-center py-8">
        <v-progress-circular indeterminate color="primary" />
      </div>

      <div
        v-else-if="!tags || tags.length === 0"
        class="text-center py-12 text-medium-emphasis"
      >
        <v-icon icon="mdi-tag-multiple-outline" size="64" class="mb-4" />
        <p class="text-body-1">
          No tags yet. Tags are created by adding them to a task.
        </p>
      </div>

      <div v-else class="cc-card pa-0" style="overflow: hidden">
        <v-list lines="one">
          <v-list-item
            v-for="tag in tags"
            :key="tag.id"
            :title="tag.name"
            prepend-icon="mdi-tag-outline"
          >
            <template #append>
              <span class="cc-pill cc-pill--muted">
                {{ tag.taskCount }} task{{ tag.taskCount === 1 ? '' : 's' }}
              </span>
            </template>
          </v-list-item>
        </v-list>
      </div>
    </template>
  </v-container>
</template>
