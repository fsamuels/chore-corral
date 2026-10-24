import { describe, expect, it } from 'vitest'
import { describeActiveFilters } from '../app/utils/task-filter-chips'
import { ALL, defaultTaskFilters } from '../app/utils/task-filters'

const base = {
  category: ALL as string | null,
  tag: ALL as string,
  location: ALL as string,
  filters: defaultTaskFilters(),
  categories: [{ id: 'c1', name: 'Barn' }],
  locations: [{ id: 'l1', name: 'North field' }],
}

describe('describeActiveFilters', () => {
  it('returns nothing when no hidden filter is active', () => {
    expect(describeActiveFilters(base)).toEqual([])
  })

  it('ignores status and search (they stay visible on the page)', () => {
    const filters = { ...defaultTaskFilters(), status: 'done' as const }
    filters.search = 'fence'
    expect(describeActiveFilters({ ...base, filters })).toEqual([])
  })

  it('describes each active filter in panel order', () => {
    const chips = describeActiveFilters({
      ...base,
      category: 'c1',
      tag: 'fencing',
      location: 'l1',
      filters: {
        ...defaultTaskFilters(),
        priority: 'urgent',
        dueDate: 'has_due_date',
        overdueOnly: true,
      },
    })
    expect(chips.map((c) => c.key)).toEqual([
      'category',
      'tag',
      'location',
      'priority',
      'dueDate',
      'overdueOnly',
    ])
    expect(chips.map((c) => c.label)).toEqual([
      'Category: Barn',
      'Tag: fencing',
      'Location: North field',
      'Priority: Urgent',
      'Due date: Has due date',
      'Overdue only',
    ])
  })

  it('labels the Uncategorized (null) category', () => {
    expect(describeActiveFilters({ ...base, category: null })).toEqual([
      { key: 'category', label: 'Category: Uncategorized' },
    ])
  })

  it('falls back when a category or location id is unknown', () => {
    const chips = describeActiveFilters({
      ...base,
      category: 'gone',
      location: 'gone',
    })
    expect(chips.map((c) => c.label)).toEqual([
      'Category: Unknown',
      'Location: Unknown',
    ])
  })
})
