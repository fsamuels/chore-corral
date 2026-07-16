<script setup lang="ts">
import { TASK_STATUSES, type TagSummaryWithCount } from '~/services/tags'
import { STATUS_DISPLAY } from '~/utils/task-display'

const { fetchFarms, activeFarm, farmsError } = useFarms()
const { tags, tagsError, loading, fetchTags } = useTagSummaries()

// Fetch farms first so the active farm resolves during SSR, then load its
// tags (the composable's watch covers later farm switches).
await fetchFarms()
await fetchTags()

// Deep-link into the tasks page filtered by this tag (and optionally a status).
function tasksLink(tag: TagSummaryWithCount, status?: string): string {
  const params = new URLSearchParams({ tag: tag.name })
  if (status) params.set('status', status)
  return `/tasks?${params.toString()}`
}

// The three progress statuses with each one's count for a tag, in a stable
// order — rendered as filter links (non-zero) or dimmed labels (zero).
function statusEntries(tag: TagSummaryWithCount) {
  return TASK_STATUSES.map((status) => ({
    status,
    label: STATUS_DISPLAY[status].label,
    icon: STATUS_DISPLAY[status].icon,
    count: tag.statusCounts[status],
    to: tasksLink(tag, status),
  }))
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
          No tags yet. Tags are created by adding them to a chore.
        </p>
      </div>

      <div v-else class="tags-list">
        <div v-for="tag in tags" :key="tag.id" class="cc-card tag-row">
          <NuxtLink :to="tasksLink(tag)" class="tag-row__head">
            <v-icon icon="mdi-tag-outline" size="20" class="tag-row__icon" />
            <span class="tag-row__name">{{ tag.name }}</span>
            <span class="cc-pill cc-pill--muted tag-row__total">
              {{ tag.taskCount }} chore{{ tag.taskCount === 1 ? '' : 's' }}
            </span>
          </NuxtLink>

          <div class="tag-row__statuses">
            <template v-for="entry in statusEntries(tag)" :key="entry.status">
              <NuxtLink
                v-if="entry.count > 0"
                :to="entry.to"
                class="tag-status tag-status--link"
              >
                <v-icon :icon="entry.icon" size="14" />
                <span>{{ entry.count }} {{ entry.label.toLowerCase() }}</span>
              </NuxtLink>
              <span v-else class="tag-status tag-status--empty">
                <v-icon :icon="entry.icon" size="14" />
                <span>0 {{ entry.label.toLowerCase() }}</span>
              </span>
            </template>
          </div>
        </div>
      </div>
    </template>
  </v-container>
</template>

<style scoped>
.tags-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.tag-row {
  padding: 14px 16px;
}

.tag-row__head {
  display: flex;
  align-items: center;
  gap: 10px;
  text-decoration: none;
  color: var(--cc-ink);
}

.tag-row__icon {
  color: var(--cc-ink-muted);
}

.tag-row__name {
  font-family: var(--cc-font-slab);
  font-size: 1.125rem;
  font-weight: 600;
  overflow-wrap: anywhere;
}

.tag-row__total {
  margin-left: auto;
}

.tag-row__statuses {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 12px;
}

/* Status count chip: a filter link when non-zero, a dimmed label at zero. */
.tag-status {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  border-radius: 999px;
  padding: 6px 12px;
  font-size: 0.8125rem;
  font-weight: 600;
  line-height: 1.4;
  white-space: nowrap;
  text-decoration: none;
}

.tag-status--link {
  background: var(--cc-field);
  border: 1px solid var(--cc-field-border);
  color: var(--cc-ink);
}

.tag-status--link:hover {
  border-color: var(--cc-accent);
  color: var(--cc-accent);
}

.tag-status--empty {
  color: var(--cc-ink-muted);
  opacity: 0.6;
}
</style>
