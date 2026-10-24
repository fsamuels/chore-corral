<script setup lang="ts">
import { isTaskOverdue, type TaskSummary } from '~/services/tasks'
import {
  formatDaysOld,
  formatDaysToComplete,
  formatDueDate,
} from '~/utils/task-display'

const props = defineProps<{
  task: TaskSummary
  /** Resolved category display name (page owns the categories list). */
  categoryName: string
  /** Optional category emoji, shown in the circular timer button. */
  categoryEmoji?: string | null
  /** Resolved defined-location name (page owns the locations list); null for
   * a freeform pin or no location. */
  locationName?: string | null
  /** Resolved short labels of this chore's assignees (page owns the member
   * list); empty/omitted when unassigned — nothing renders. */
  assigneeNames?: string[]
  /** Local calendar-date string ("YYYY-MM-DD") for due-date rendering. */
  today: string
  /** True while the page is persisting this task's timer change. */
  updating?: boolean
  /** True when this task has the user's running timer (shows a stop control). */
  timerRunning?: boolean
  /** Hide the circular timer button for pages that don't offer it. */
  hideCheck?: boolean
  /** Signed URL of the chore's first photo (page owns the fetch — see
   * useTaskThumbnails). `null` = nothing to show, so a chore with photos
   * falls back to the meta-row photo icon; `undefined` = still loading, so
   * neither renders (avoids an icon → image flicker). */
  thumbnailUrl?: string | null
}>()

const emit = defineEmits<{
  /** User tapped the circular button; the page starts or stops this task's timer. */
  toggleTimer: [task: TaskSummary]
  /** The thumbnail image failed to load (e.g. an expired signed URL); the
   * page re-signs it or gives up — see useTaskThumbnails. */
  thumbnailError: [task: TaskSummary]
}>()

const isDone = computed(() => props.task.status === 'done')

const overdue = computed(() => isTaskOverdue(props.task))

// A done task shows its frozen turnaround ("X days to complete") instead of
// the still-growing age — the age keeps counting up against `today` even
// after the chore is finished, which reads as wrong once it's done.
const ageOrTurnaroundText = computed(() =>
  isDone.value
    ? formatDaysToComplete(
        props.task.created_at,
        props.task.completed_at,
        props.today,
      )
    : formatDaysOld(props.task.created_at, props.today),
)

// Lowercased for the pill's "Soon · due tomorrow" form (formatDueDate
// returns "Due tomorrow"). Done tasks skip this entirely — a finished
// chore's due date (even one in the past) isn't overdue, so it gets a
// "Completed" pill instead below.
const dueText = computed(() =>
  !isDone.value && props.task.due_date
    ? formatDueDate(props.task.due_date, props.today).toLowerCase()
    : null,
)

// Whenever tasks only get a pill when they have a due date; urgent/soon
// always show their priority pill; done tasks always get the Completed pill.
const showPill = computed(
  () =>
    isDone.value ||
    props.task.priority !== 'whenever' ||
    dueText.value !== null,
)

const pillIcon = computed(() => {
  if (isDone.value) return 'mdi-check-circle'
  if (props.task.priority === 'urgent') return 'mdi-fire'
  if (props.task.priority === 'soon') return 'mdi-clock-outline'
  return null
})

const pillLabel = computed(() => {
  if (isDone.value) return 'Completed'
  const priorityLabel =
    props.task.priority === 'urgent'
      ? 'Urgent'
      : props.task.priority === 'soon'
        ? 'Soon'
        : null
  if (priorityLabel && dueText.value) return `${priorityLabel} · `
  return priorityLabel ?? ''
})

// Freeform pin (no name to show — a defined location instead renders
// `locationName` as text below).
const hasLocation = computed(
  () => props.task.lat !== null && props.task.lng !== null,
)

// Hides a thumbnail that failed to load until the page supplies a new URL,
// so the browser's broken-image glyph never shows.
const thumbnailFailed = ref(false)
watch(
  () => props.thumbnailUrl,
  () => {
    thumbnailFailed.value = false
  },
)

const showThumbnail = computed(
  () => !!props.thumbnailUrl && !thumbnailFailed.value,
)

// Photo icon is the fallback for a chore whose thumbnail can't be shown;
// skipped while the thumbnail is still loading (undefined).
const showPhotoIcon = computed(
  () =>
    props.task.photo_count > 0 &&
    !showThumbnail.value &&
    (props.thumbnailUrl === null || thumbnailFailed.value),
)

const photoCountLabel = computed(() =>
  props.task.photo_count === 1 ? '1 photo' : `${props.task.photo_count} photos`,
)

function onThumbnailError() {
  thumbnailFailed.value = true
  emit('thumbnailError', props.task)
}

function onToggleTimer() {
  if (props.updating) return
  emit('toggleTimer', props.task)
}
</script>

<template>
  <!-- Stretched-link pattern: the card is a plain element and the title link's
       ::after covers it, so the whole card is clickable while the timer
       button stays a sibling of (not nested in) the <a>. -->
  <div
    class="cc-card cc-card--row task-card"
    :class="[
      `task-card--${task.priority}`,
      { 'task-card--has-thumbnail': showThumbnail },
    ]"
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
      @click="onToggleTimer"
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
      <NuxtLink :to="`/tasks/${task.id}`" class="task-card__title">{{
        task.title
      }}</NuxtLink>
      <div class="task-card__meta">
        <span
          v-if="showPill"
          class="cc-pill cc-pill--sm"
          :class="isDone ? 'cc-pill--done' : `cc-pill--${task.priority}`"
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
        <span
          v-if="locationName"
          class="cc-meta task-card__truncate"
          :title="locationName"
        >
          <v-icon
            icon="mdi-map-marker-outline"
            size="16"
            class="task-card__meta-icon"
          />
          {{ locationName }}
        </span>
        <v-icon
          v-else-if="hasLocation"
          icon="mdi-map-marker-outline"
          size="16"
          class="task-card__meta-icon"
          role="img"
          aria-label="Has location"
          title="Has location"
        />
        <span
          v-if="assigneeNames && assigneeNames.length > 0"
          class="cc-meta task-card__truncate"
          :title="assigneeNames.join(', ')"
        >
          <v-icon
            icon="mdi-account-outline"
            size="16"
            class="task-card__meta-icon"
          />
          {{ assigneeNames.join(', ') }}
        </span>
        <span
          v-if="showPhotoIcon"
          class="cc-meta"
          :aria-label="photoCountLabel"
          :title="photoCountLabel"
        >
          <v-icon
            icon="mdi-image-outline"
            size="16"
            class="task-card__meta-icon"
          />
          <span v-if="task.photo_count > 1">{{ task.photo_count }}</span>
        </span>
        <ClientOnly>
          <span class="cc-meta">{{ ageOrTurnaroundText }}</span>
        </ClientOnly>
      </div>
    </div>

    <img
      v-if="showThumbnail"
      :src="thumbnailUrl!"
      :alt="photoCountLabel"
      class="task-card__thumbnail"
      loading="lazy"
      decoding="async"
      @error="onThumbnailError"
    />
  </div>
</template>

<style scoped>
.task-card {
  position: relative;
  display: flex;
  align-items: center;
  gap: 14px;
  color: var(--cc-ink);
}

/* Keyboard focus lands on the title link; ring the whole card since the
   link's own box is only the title text. */
.task-card:has(.task-card__title:focus-visible) {
  outline: 2px solid var(--cc-accent);
  outline-offset: 2px;
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
  /* Above the title link's stretched ::after so it receives its own taps. */
  z-index: 1;
}

.task-card__check:focus-visible {
  outline: 2px solid var(--cc-accent);
  outline-offset: 2px;
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
  display: block;
  text-decoration: none;
  font-family: var(--cc-font-slab);
  font-size: 1.125rem;
  font-weight: 600;
  line-height: 1.3;
  color: var(--cc-ink);
  overflow-wrap: anywhere;
}

.task-card__title:focus-visible {
  outline: none;
}

.task-card__title::after {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: var(--cc-radius);
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

/* Location / assignee text truncates instead of wrapping the meta row. */
.task-card__truncate {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.task-card__due--overdue {
  color: var(--cc-urgent-ring);
}

.task-card__meta-icon {
  color: var(--cc-ink-muted);
}

.task-card--has-thumbnail {
  position: relative;
  /* Lets the thumbnail size itself against the card's width (cqw) below. */
  container-type: inline-size;
}

/* Reserve the thumbnail's widest possible footprint, plus a gap, so text
   never runs underneath it. */
.task-card--has-thumbnail .task-card__content {
  margin-right: calc(min(20cqw, 80px) + 12px);
}

/* Square, fitted to the card's content height and vertically centered.
   Absolutely positioned because a flex item's stretched height can't drive
   its width through aspect-ratio; capped at ~20% of the card (80px max) so a
   tall wrapped title doesn't grow it past its reserved space. */
.task-card__thumbnail {
  position: absolute;
  top: 50%;
  right: 16px;
  transform: translateY(-50%);
  height: calc(100% - 28px);
  max-height: min(20cqw, 80px);
  aspect-ratio: 1;
  object-fit: cover;
  border-radius: calc(var(--cc-radius) / 2);
  background: var(--cc-border);
  /* Taps on the photo fall through to the stretched title link. */
  pointer-events: none;
}

/* Touch devices have no hover, so show the play glyph at rest (the emoji
   steps aside) to make the circle read as a button. */
@media (hover: none) {
  .task-card__check-play {
    opacity: 1;
  }

  .task-card__check-emoji {
    opacity: 0;
  }
}
</style>
