<script setup lang="ts">
import { isTaskOverdue, type TaskSummary } from '~/services/tasks'
import { formatDueDate } from '~/utils/task-display'

const props = defineProps<{
  task: TaskSummary
  /** Resolved category display name (page owns the categories list). */
  categoryName: string
  /** Optional category emoji, shown in the circular timer button. */
  categoryEmoji?: string | null
  /** Local calendar-date string ("YYYY-MM-DD") for due-date rendering. */
  today: string
  /** True while the page is persisting this task's timer change. */
  updating?: boolean
  /** True when this task has the user's running timer (shows a stop control). */
  timerRunning?: boolean
  /** Hide the circular timer button for pages that don't offer it. */
  hideCheck?: boolean
}>()

const emit = defineEmits<{
  /** User tapped the circular button; the page starts or stops this task's timer. */
  toggleTimer: [task: TaskSummary]
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

function onToggleTimer() {
  if (props.updating) return
  emit('toggleTimer', props.task)
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
      :class="[
        `task-card__check--${task.priority}`,
        { 'task-card__check--running': timerRunning },
      ]"
      :aria-label="
        timerRunning
          ? `Stop timer for ${task.title}`
          : `Start timer for ${task.title}`
      "
      :title="timerRunning ? 'Stop timer' : 'Start timer'"
      :disabled="updating"
      @click.stop.prevent="onToggleTimer"
    >
      <v-progress-circular
        v-if="updating"
        indeterminate
        size="20"
        width="2"
        class="task-card__check-spinner"
      />
      <v-icon
        v-else-if="timerRunning"
        icon="mdi-stop"
        size="22"
        class="task-card__check-stop"
      />
      <template v-else>
        <span
          v-if="categoryEmoji"
          class="task-card__check-emoji"
          aria-hidden="true"
          >{{ categoryEmoji }}</span
        >
        <v-icon
          icon="mdi-play"
          size="20"
          class="task-card__check-play"
          :class="{ 'task-card__check-play--solo': !categoryEmoji }"
        />
      </template>
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

/* 44px circular start-timer button: 3px priority ring + soft priority fill.
   Holds the category emoji at rest and reveals a play icon on hover; a
   running timer swaps it for a stop icon in the accent color. */
.task-card__check {
  position: relative;
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

/* Running state: accent-filled circle with the stop glyph. Placed after the
   priority modifiers so it wins on source order without !important. */
.task-card__check--running {
  border-color: var(--cc-accent);
  background: var(--cc-accent);
  color: var(--cc-accent-contrast);
}

/* Emoji (rest) and play icon (hover) share the center via absolute overlap. */
.task-card__check-emoji,
.task-card__check-play {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  transition: opacity 0.15s ease;
}

.task-card__check-emoji {
  font-size: 1.25rem;
  line-height: 1;
}

/* Play hidden at rest when an emoji is showing; revealed on hover/focus. */
.task-card__check-play {
  opacity: 0;
}

/* No emoji to show — keep the play glyph faintly visible as the affordance. */
.task-card__check-play--solo {
  opacity: 0.55;
}

.task-card__check:hover .task-card__check-play,
.task-card__check:focus-visible .task-card__check-play {
  opacity: 1;
}

.task-card__check:hover .task-card__check-emoji,
.task-card__check:focus-visible .task-card__check-emoji {
  opacity: 0;
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
