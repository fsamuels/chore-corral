import type { TaskPriority } from '~/services/tasks'
import type { CategorySummary } from '~/services/categories'

// Shared between /tasks and / (home) so the two task views agree on how a
// priority or a soft-deleted category renders.
export const PRIORITY_DISPLAY: Record<
  TaskPriority,
  { color: string; label: string }
> = {
  urgent: { color: 'error', label: 'Urgent' },
  soon: { color: 'warning', label: 'Soon' },
  whenever: { color: '', label: 'Whenever' },
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
