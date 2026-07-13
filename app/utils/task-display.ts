import {
  parseLocalDateString,
  type TaskPriority,
  type TaskStatus,
} from '../services/tasks'
import type { CategorySummary } from '../services/categories'

/**
 * The ranch-design priority color system (design tokens). The same values
 * exist as CSS custom properties in app/assets/css/main.css
 * (--cc-<priority>-ring/-fill/-text/-pill-bg); this constant is for code
 * that needs the hex values in script (e.g. TaskCard inline styles).
 *
 * - ring:   3px circle ring on the TaskCard complete-checkbox
 * - fill:   soft interior fill of that circle
 * - text:   pill/label text color for the priority
 * - pillBg: background of the priority pill in card meta rows & stat pills
 */
export const PRIORITY_COLORS: Record<
  TaskPriority,
  { ring: string; fill: string; text: string; pillBg: string }
> = {
  urgent: {
    ring: '#c0391f',
    fill: '#f6ddd5',
    text: '#993d1f',
    pillBg: '#efd4c8',
  },
  soon: {
    ring: '#d98a1a',
    fill: '#f7e8c9',
    text: '#8a5a00',
    pillBg: '#f7e8c9',
  },
  whenever: {
    ring: '#8ba06b',
    fill: '#e7ecdb',
    text: '#5d6e3a',
    pillBg: '#e7ecdb',
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

/**
 * Compact "1h 30m" rendering of an elapsed duration in milliseconds, for
 * the running-timer dock bar — reuses `formatEstimatedMinutes`'s
 * hour/minute split since the two read identically. The bar's cadence
 * is a periodic tick rather than a per-second one, so anything under a
 * minute renders as "<1m" instead of "0m" (which would look stuck).
 */
export function formatElapsedDuration(ms: number): string {
  const minutes = Math.floor(ms / 60000)
  if (minutes < 1) return '<1m'
  return formatEstimatedMinutes(minutes)
}

/**
 * The "HH:mm" (24-hour, zero-padded) local time of a `Date`, for seeding a
 * `<v-text-field type="time">` draft from an existing timestamp (e.g. the
 * task View page's completed-at editor). Companion to `parseLocalDateString`
 * (the date half); this is the time half.
 */
export function formatTimeForInput(date: Date): string {
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  return `${hours}:${minutes}`
}

/**
 * Combine a calendar `Date` (only its year/month/day are used) with an
 * "HH:mm" time-of-day string into a single local `Date` — the inverse pairing
 * of `formatTimeForInput`. Used to merge a `<v-date-picker>` date draft with a
 * `<v-text-field type="time">` draft into one timestamp before saving.
 * Returns null if `time` isn't in "HH:mm" form.
 */
export function combineDateAndTime(date: Date, time: string): Date | null {
  const match = /^(\d{1,2}):(\d{2})$/.exec(time)
  if (!match) return null
  const hours = Number(match[1])
  const minutes = Number(match[2])
  if (hours > 23 || minutes > 59) return null
  return new Date(
    date.getFullYear(),
    date.getMonth(),
    date.getDate(),
    hours,
    minutes,
  )
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
