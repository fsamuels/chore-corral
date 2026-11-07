import { toLocalDateString, type CreateTaskInput } from '~/services/tasks'

/**
 * Fields the quick-start dialog collects. Everything else on a quick-started
 * chore is fixed: priority Whenever, due today, no estimate, location, tags
 * or assignees.
 */
export interface QuickStartFields {
  title: string
  categoryId: string | null
  notes: string
}

/**
 * The `createTask` input for a quick-started chore. `now` is injectable so
 * "due today" is testable; it's the local calendar date, like the full form's
 * date picker.
 */
export function quickStartTaskInput(
  fields: QuickStartFields,
  now: Date = new Date(),
): Omit<CreateTaskInput, 'farmId' | 'actorUserId'> {
  return {
    title: fields.title.trim(),
    categoryId: fields.categoryId,
    priority: 'whenever',
    dueDate: toLocalDateString(now),
    notes: fields.notes.trim() || null,
  }
}

export const QUICK_START_CATEGORY_KEY_PREFIX = 'cc:quick-start-category:'

// localStorage is absent during SSR and can throw (private mode / quota /
// blocked storage). The remembered category is a convenience only, so every
// failure just means "no remembered category".
function safeLocalStorage(): Storage | null {
  try {
    return typeof localStorage === 'undefined' ? null : localStorage
  } catch {
    return null
  }
}

/** The category last used for a quick start in this farm, if any. */
export function loadQuickStartCategory(farmId: string): string | null {
  const store = safeLocalStorage()
  if (!store) return null
  try {
    return store.getItem(QUICK_START_CATEGORY_KEY_PREFIX + farmId) || null
  } catch {
    return null
  }
}

/** Remember (or, for null, forget) the farm's last quick-start category. */
export function saveQuickStartCategory(
  farmId: string,
  categoryId: string | null,
): void {
  const store = safeLocalStorage()
  if (!store) return
  try {
    const key = QUICK_START_CATEGORY_KEY_PREFIX + farmId
    if (categoryId) store.setItem(key, categoryId)
    else store.removeItem(key)
  } catch {
    // Ignore: a convenience, never load-bearing.
  }
}

/**
 * The category to preselect: the remembered one if it still exists in the
 * farm's (non-deleted) category list, else Uncategorized.
 */
export function initialQuickStartCategory(
  remembered: string | null,
  categoryIds: readonly string[],
): string | null {
  return remembered && categoryIds.includes(remembered) ? remembered : null
}
