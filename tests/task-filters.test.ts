import { describe, expect, it } from 'vitest'
import {
  defaultTaskFilters,
  filterTasks,
  matchesDueDateFilter,
  matchesPriority,
  matchesSearch,
  matchesStatus,
} from '../app/utils/task-filters'
import type { TaskSummary } from '../app/services/tasks'

function task(overrides: Partial<TaskSummary> = {}): TaskSummary {
  return {
    id: 'task-1',
    title: 'Fix the gate',
    category_id: null,
    priority: 'soon',
    status: 'not_started',
    due_date: null,
    notes: null,
    lat: null,
    lng: null,
    created_at: '2026-01-01T00:00:00.000Z',
    completed_at: null,
    estimated_minutes: null,
    tags: [],
    photo_count: 0,
    ...overrides,
  }
}

const NOW = new Date('2026-07-04T12:00:00.000Z')

describe('matchesStatus', () => {
  it('matches any status when the filter is "all"', () => {
    expect(matchesStatus(task({ status: 'done' }), 'all')).toBe(true)
  })

  it('matches only the exact status otherwise', () => {
    expect(matchesStatus(task({ status: 'done' }), 'done')).toBe(true)
    expect(matchesStatus(task({ status: 'done' }), 'in_progress')).toBe(false)
  })
})

describe('matchesPriority', () => {
  it('matches any priority when the filter is "all"', () => {
    expect(matchesPriority(task({ priority: 'urgent' }), 'all')).toBe(true)
  })

  it('matches only the exact priority otherwise', () => {
    expect(matchesPriority(task({ priority: 'urgent' }), 'urgent')).toBe(true)
    expect(matchesPriority(task({ priority: 'urgent' }), 'whenever')).toBe(
      false,
    )
  })
})

describe('matchesDueDateFilter', () => {
  it('passes everything for "all"', () => {
    expect(matchesDueDateFilter(task({ due_date: null }), 'all')).toBe(true)
    expect(matchesDueDateFilter(task({ due_date: '2026-07-10' }), 'all')).toBe(
      true,
    )
  })

  it('"has_due_date" requires a non-null due date', () => {
    expect(
      matchesDueDateFilter(task({ due_date: '2026-07-10' }), 'has_due_date'),
    ).toBe(true)
    expect(matchesDueDateFilter(task({ due_date: null }), 'has_due_date')).toBe(
      false,
    )
  })

  it('"no_due_date" requires a null due date', () => {
    expect(matchesDueDateFilter(task({ due_date: null }), 'no_due_date')).toBe(
      true,
    )
    expect(
      matchesDueDateFilter(task({ due_date: '2026-07-10' }), 'no_due_date'),
    ).toBe(false)
  })
})

describe('matchesSearch', () => {
  it('matches any title when the query is empty or whitespace', () => {
    expect(matchesSearch(task({ title: 'Fix the gate' }), '')).toBe(true)
    expect(matchesSearch(task({ title: 'Fix the gate' }), '   ')).toBe(true)
  })

  it('matches a case-insensitive substring of the title', () => {
    expect(matchesSearch(task({ title: 'Fix the Gate' }), 'gate')).toBe(true)
    expect(matchesSearch(task({ title: 'Fix the Gate' }), 'GATE')).toBe(true)
    expect(matchesSearch(task({ title: 'Fix the Gate' }), 'fence')).toBe(false)
  })
})

describe('filterTasks', () => {
  it('returns every task when filters are all defaults', () => {
    const tasks = [task({ id: 'a' }), task({ id: 'b', status: 'done' })]
    expect(filterTasks(tasks, defaultTaskFilters(), NOW)).toHaveLength(2)
  })

  it('combines dimensions with AND, not OR', () => {
    const tasks = [
      task({ id: 'a', priority: 'urgent', status: 'not_started' }),
      task({ id: 'b', priority: 'urgent', status: 'done' }),
      task({ id: 'c', priority: 'soon', status: 'not_started' }),
    ]
    const result = filterTasks(
      tasks,
      { ...defaultTaskFilters(), priority: 'urgent', status: 'not_started' },
      NOW,
    )
    expect(result.map((t) => t.id)).toEqual(['a'])
  })

  it('overdueOnly reuses isTaskOverdue (due-in-the-past, not done)', () => {
    const tasks = [
      task({ id: 'overdue', due_date: '2026-07-01', status: 'not_started' }),
      task({ id: 'future', due_date: '2026-08-01', status: 'not_started' }),
      task({ id: 'done-overdue', due_date: '2026-07-01', status: 'done' }),
      task({ id: 'no-date', due_date: null }),
    ]
    const result = filterTasks(
      tasks,
      { ...defaultTaskFilters(), overdueOnly: true },
      NOW,
    )
    expect(result.map((t) => t.id)).toEqual(['overdue'])
  })

  it('applies search and due-date filters alongside the rest', () => {
    const tasks = [
      task({ id: 'a', title: 'Mow the pasture', due_date: '2026-07-10' }),
      task({ id: 'b', title: 'Mow the lawn', due_date: null }),
      task({ id: 'c', title: 'Fix the fence', due_date: '2026-07-10' }),
    ]
    const result = filterTasks(
      tasks,
      { ...defaultTaskFilters(), search: 'mow', dueDate: 'has_due_date' },
      NOW,
    )
    expect(result.map((t) => t.id)).toEqual(['a'])
  })
})
