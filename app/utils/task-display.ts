import type { TaskPriority, TaskStatus } from '~/services/tasks'
import type { CategorySummary } from '~/services/categories'

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

export function categoryDisplayName(
  categoryId: string | null,
  categories: Pick<CategorySummary, 'id' | 'name'>[] | null | undefined,
): { text: string; deleted: boolean } {
  if (categoryId === null) return { text: 'Uncategorized', deleted: false }
  const category = categories?.find((c) => c.id === categoryId)
  if (category) return { text: category.name, deleted: false }
  return { text: '(deleted category)', deleted: true }
}
