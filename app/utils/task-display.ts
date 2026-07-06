import {
  parseLocalDateString,
  type TaskPriority,
  type TaskStatus,
} from '../services/tasks'
import type { CategorySummary } from '../services/categories'

// Shared between /tasks and / (home) so the two task views agree on how a
// priority or a soft-deleted category renders.
export const PRIORITY_DISPLAY: Record<
  TaskPriority,
  { color: string; label: string; icon: string }
> = {
  urgent: { color: 'error', label: 'Urgent', icon: 'mdi-fire' },
  soon: { color: 'warning', label: 'Soon', icon: 'mdi-clock-alert-outline' },
  whenever: {
    color: '',
    label: 'Whenever',
    icon: 'mdi-calendar-blank-outline',
  },
}

// Shared status icon set so any task list (table rows, dashboard list) uses
// the same glyph for a given status.
export const STATUS_DISPLAY: Record<
  TaskStatus,
  { label: string; icon: string }
> = {
  not_started: {
    label: 'Not started',
    icon: 'mdi-checkbox-blank-circle-outline',
  },
  in_progress: { label: 'In progress', icon: 'mdi-progress-clock' },
  done: { label: 'Done', icon: 'mdi-check-circle' },
}

export const OVERDUE_ICON = 'mdi-alert-circle'

/**
 * Human-friendly relative rendering of a due date against `today` (a local
 * calendar-date string, e.g. from `toLocalDateString` — never the wall
 * clock, so this stays pure and testable). Falls back to the raw date for
 * anything more than a week out.
 */
export function formatDueDate(dueDate: string, today: string): string {
  const diffDays = daysBetween(today, dueDate)
  if (diffDays < 0) {
    const overdueDays = -diffDays
    return overdueDays === 1 ? '1 day overdue' : `${overdueDays} days overdue`
  }
  if (diffDays === 0) return 'Due today'
  if (diffDays === 1) return 'Due tomorrow'
  if (diffDays <= 7) return `Due in ${diffDays} days`
  return `Due ${dueDate}`
}

// Both `today` and `dueDate` are local calendar-date strings ("YYYY-MM-DD");
// `parseLocalDateString` keeps the day-count in local calendar days,
// matching `isTaskOverdue`'s local-date comparison.
function daysBetween(today: string, dueDate: string): number {
  const todayMs = parseLocalDateString(today).getTime()
  const dueMs = parseLocalDateString(dueDate).getTime()
  const msPerDay = 24 * 60 * 60 * 1000
  return Math.round((dueMs - todayMs) / msPerDay)
}

/**
 * Parse the create/edit forms' estimated-time text input: empty or
 * whitespace-only means "no estimate" (null); anything else converts via
 * `Number`, leaving range/integer rejection (including the NaN a
 * non-numeric string produces) to the service's
 * `assertValidEstimatedMinutes` and its readable message.
 */
export function parseEstimatedMinutesInput(raw: string): number | null {
  const trimmed = raw.trim()
  return trimmed === '' ? null : Number(trimmed)
}

/**
 * Compact "1h 30m" rendering of a task's `estimated_minutes`. Expects a
 * positive integer (the service's `assertValidEstimatedMinutes` enforces
 * that on write); whole hours drop the minutes part ("2h") and sub-hour
 * estimates drop the hours part ("45m").
 */
export function formatEstimatedMinutes(minutes: number): string {
  const hours = Math.floor(minutes / 60)
  const remainder = minutes % 60
  if (hours === 0) return `${remainder}m`
  if (remainder === 0) return `${hours}h`
  return `${hours}h ${remainder}m`
}

export function categoryDisplayName(
  categoryId: string | null,
  categories: Pick<CategorySummary, 'id' | 'name'>[] | null | undefined,
): { text: string; deleted: boolean } {
  if (categoryId === null) return { text: 'Uncategorized', deleted: false }
  const category = categories?.find((c) => c.id === categoryId)
  if (category) return { text: category.name, deleted: false }
  return { text: '(deleted category)', deleted: true }
}
