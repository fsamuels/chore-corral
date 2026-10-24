import { ALL, type TaskFilters } from './task-filters'

export type FilterChipKey =
  'category' | 'tag' | 'location' | 'priority' | 'dueDate' | 'overdueOnly'

export interface FilterChip {
  key: FilterChipKey
  /** Human-readable label, e.g. "Priority: Urgent". */
  label: string
}

export interface FilterChipInput {
  /** Category id, `null` for Uncategorized, or `ALL` for no filter. */
  category: string | null
  /** Tag name, or `ALL`. */
  tag: string
  /** Location id, or `ALL`. */
  location: string
  filters: TaskFilters
  categories: { id: string; name: string }[]
  locations: { id: string; name: string }[]
}

const PRIORITY_LABELS: Record<string, string> = {
  urgent: 'Urgent',
  soon: 'Soon',
  whenever: 'Whenever',
}

const DUE_DATE_LABELS: Record<string, string> = {
  has_due_date: 'Has due date',
  no_due_date: 'No due date',
}

/**
 * Describe every active filter that lives in the collapsible panel (status
 * and search stay visible on the page, so they're not chips). Returned in
 * the same order as the panel's fields.
 */
export function describeActiveFilters(input: FilterChipInput): FilterChip[] {
  const chips: FilterChip[] = []

  if (input.category !== ALL) {
    const name =
      input.category === null
        ? 'Uncategorized'
        : (input.categories.find((c) => c.id === input.category)?.name ??
          'Unknown')
    chips.push({ key: 'category', label: `Category: ${name}` })
  }
  if (input.tag !== ALL) {
    chips.push({ key: 'tag', label: `Tag: ${input.tag}` })
  }
  if (input.location !== ALL) {
    const name =
      input.locations.find((l) => l.id === input.location)?.name ?? 'Unknown'
    chips.push({ key: 'location', label: `Location: ${name}` })
  }
  if (input.filters.priority !== ALL) {
    chips.push({
      key: 'priority',
      label: `Priority: ${PRIORITY_LABELS[input.filters.priority] ?? input.filters.priority}`,
    })
  }
  if (input.filters.dueDate !== ALL) {
    chips.push({
      key: 'dueDate',
      label: `Due date: ${DUE_DATE_LABELS[input.filters.dueDate] ?? input.filters.dueDate}`,
    })
  }
  if (input.filters.overdueOnly) {
    chips.push({ key: 'overdueOnly', label: 'Overdue only' })
  }
  return chips
}
