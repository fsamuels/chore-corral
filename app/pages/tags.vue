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
  <div class="cc-page">
    <LoadErrorAlert
      v-if="farmsError"
      title="Couldn't load your farms"
      :message="farmsError"
      :retry="() => fetchFarms()"
    />
    <template v-else-if="activeFarm">
      <PageHeader title="Tags" />

      <LoadErrorAlert
        v-if="tagsError"
        title="Couldn't load tags"
        :message="tagsError"
        :retry="() => fetchTags()"
      />

      <ListSkeleton v-else-if="loading && tags === null" />

      <EmptyState
        v-else-if="!tags || tags.length === 0"
        icon="mdi-tag-multiple-outline"
      >
        No tags yet. Tags are created by adding them to a chore.
      </EmptyState>

      <div v-else class="cc-card-list">
        <div v-for="tag in tags" :key="tag.id" class="cc-card cc-card--row">
          <NuxtLink :to="tasksLink(tag)" class="tag-row__head">
            <v-icon icon="mdi-tag-outline" size="20" class="tag-row__icon" />
            <span class="cc-slab tag-row__name">{{ tag.name }}</span>
            <span class="cc-pill cc-pill--muted tag-row__total">
              {{ tag.taskCount }} chore{{ tag.taskCount === 1 ? '' : 's' }}
            </span>
          </NuxtLink>

          <div class="tag-row__statuses">
            <template v-for="entry in statusEntries(tag)" :key="entry.status">
              <NuxtLink
                v-if="entry.count > 0"
                :to="entry.to"
                class="cc-status-chip cc-status-chip--link"
              >
                <v-icon :icon="entry.icon" size="14" />
                <span>{{ entry.count }} {{ entry.label.toLowerCase() }}</span>
              </NuxtLink>
              <span v-else class="cc-status-chip cc-status-chip--empty">
                <v-icon :icon="entry.icon" size="14" />
                <span>0 {{ entry.label.toLowerCase() }}</span>
              </span>
            </template>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
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
</style>
