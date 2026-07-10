<script setup lang="ts">
import { isTaskOverdue, type TaskSummary } from '~/services/tasks'
import { formatDueDate } from '~/utils/task-display'

const props = defineProps<{
  task: TaskSummary
  /** Resolved category display name (page owns the categories list). */
  categoryName: string
  /** Local calendar-date string ("YYYY-MM-DD") for due-date rendering. */
  today: string
  /** True while the page is persisting this task's completion. */
  updating?: boolean
  /** Hide the complete-checkbox for pages that don't offer status changes. */
  hideCheck?: boolean
}>()

const emit = defineEmits<{
  /** User clicked the complete-checkbox; the page calls setStatus(id, 'done'). */
  complete: [task: TaskSummary]
}>()

const overdue = computed(() => isTaskOverdue(props.task))

// Lowercased for the pill's "Soon · due tomorrow" form (formatDueDate
// returns "Due tomorrow").
const dueText = computed(() =>
  props.task.due_date
    ? formatDueDate(props.task.due_date, props.today).toLowerCase()
    : null,
)

// Whenever tasks only get a pill when they have a due date; urgent/soon
// always show their priority pill.
const showPill = computed(
  () => props.task.priority !== 'whenever' || dueText.value !== null,
)

const pillIcon = computed(() => {
  if (props.task.priority === 'urgent') return 'mdi-fire'
  if (props.task.priority === 'soon') return 'mdi-clock-outline'
  return null
})

const pillLabel = computed(() => {
  const priorityLabel =
    props.task.priority === 'urgent'
      ? 'Urgent'
      : props.task.priority === 'soon'
        ? 'Soon'
        : null
  if (priorityLabel && dueText.value) return `${priorityLabel} · `
  return priorityLabel ?? ''
})

const hasLocation = computed(
  () => props.task.lat !== null && props.task.lng !== null,
)

function onComplete() {
  if (props.updating) return
  emit('complete', props.task)
}
</script>

<template>
  <NuxtLink
    :to="`/tasks/${task.id}`"
    class="task-card"
    :class="`task-card--${task.priority}`"
  >
    <button
      v-if="!hideCheck"
      type="button"
      class="task-card__check"
      :class="`task-card__check--${task.priority}`"
      :aria-label="`Mark ${task.title} done`"
      :title="'Mark done'"
      :disabled="updating"
      @click.stop.prevent="onComplete"
    >
      <v-progress-circular
        v-if="updating"
        indeterminate
        size="20"
        width="2"
        class="task-card__check-spinner"
      />
      <v-icon v-else icon="mdi-check" size="20" class="task-card__check-tick" />
    </button>

    <div class="task-card__content">
      <div class="cc-eyebrow task-card__category">{{ categoryName }}</div>
      <div class="task-card__title">{{ task.title }}</div>
      <div class="task-card__meta">
        <span
          v-if="showPill"
          class="cc-pill task-card__pill"
          :class="`cc-pill--${task.priority}`"
        >
          <v-icon v-if="pillIcon" :icon="pillIcon" size="14" />
          <span>
            {{ pillLabel
            }}<span
              v-if="dueText"
              :class="{ 'task-card__due--overdue': overdue }"
              >{{ dueText }}</span
            >
          </span>
        </span>
        <v-icon
          v-if="hasLocation"
          icon="mdi-map-marker-outline"
          size="16"
          class="task-card__meta-icon"
          aria-label="Has location"
          title="Has location"
        />
        <span
          v-if="task.photo_count > 0"
          class="task-card__meta-photos"
          aria-label="Has photos"
          title="Has photos"
        >
          <v-icon
            icon="mdi-image-outline"
            size="16"
            class="task-card__meta-icon"
          />
          <span v-if="task.photo_count > 1">{{ task.photo_count }}</span>
        </span>
      </div>
    </div>
  </NuxtLink>
</template>

<style scoped>
.task-card {
  display: flex;
  align-items: center;
  gap: 14px;
  background: var(--cc-surface);
  border: 1px solid var(--cc-border);
  border-radius: var(--cc-radius);
  box-shadow: var(--cc-shadow);
  padding: 14px 16px;
  text-decoration: none;
  color: var(--cc-ink);
}

.task-card--urgent {
  border-color: var(--cc-border-urgent);
}

/* 44px circular complete-checkbox: 3px priority ring + soft priority fill. */
.task-card__check {
  flex: 0 0 44px;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  padding: 0;
}

.task-card__check--urgent {
  border: 3px solid var(--cc-urgent-ring);
  background: var(--cc-urgent-fill);
  color: var(--cc-urgent-ring);
}

.task-card__check--soon {
  border: 3px solid var(--cc-soon-ring);
  background: var(--cc-soon-fill);
  color: var(--cc-soon-ring);
}

.task-card__check--whenever {
  border: 3px solid var(--cc-whenever-ring);
  background: var(--cc-whenever-fill);
  color: var(--cc-whenever-ring);
}

/* Tick appears on hover/focus as an affordance; spinner while updating. */
.task-card__check-tick {
  opacity: 0;
  transition: opacity 0.15s ease;
}

.task-card__check:hover .task-card__check-tick,
.task-card__check:focus-visible .task-card__check-tick {
  opacity: 1;
}

.task-card__content {
  min-width: 0;
  flex: 1;
}

.task-card__category {
  margin-bottom: 2px;
}

.task-card__title {
  font-family: var(--cc-font-slab);
  font-size: 1.125rem;
  font-weight: 600;
  line-height: 1.3;
  color: var(--cc-ink);
  overflow-wrap: anywhere;
}

.task-card__meta {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 6px;
  min-height: 0;
}

.task-card__meta:empty {
  display: none;
}

.task-card__pill {
  font-size: 0.75rem;
  padding: 2px 10px;
}

.task-card__due--overdue {
  color: var(--cc-urgent-ring);
}

.task-card__meta-icon {
  color: var(--cc-ink-muted);
}

.task-card__meta-photos {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  color: var(--cc-ink-muted);
  font-size: 0.75rem;
}
</style>
