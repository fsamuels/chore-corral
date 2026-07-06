import { describe, expect, it } from 'vitest'
import {
  compareBacklog,
  compareUpNext,
  isCollapsibleBacklogTask,
  isUpNext,
  partitionHomeTasks,
  type TaskSummary,
} from '../app/services/tasks'
import { formatDueDate } from '../app/utils/task-display'

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
    tags: [],
    photo_count: 0,
    ...overrides,
  }
}

const TODAY = '2026-07-05'

describe('isUpNext / partitionHomeTasks', () => {
  it('includes a task due today', () => {
    expect(isUpNext(task({ due_date: '2026-07-05' }), TODAY)).toBe(true)
  })

  it('includes a task due exactly today + 7 days', () => {
    expect(isUpNext(task({ due_date: '2026-07-12' }), TODAY)).toBe(true)
  })

  it('excludes a task due today + 8 days', () => {
    expect(isUpNext(task({ due_date: '2026-07-13' }), TODAY)).toBe(false)
  })

  it('includes an overdue task', () => {
    expect(isUpNext(task({ due_date: '2026-06-01' }), TODAY)).toBe(true)
  })

  it('excludes a task with no due date', () => {
    expect(isUpNext(task({ due_date: null }), TODAY)).toBe(false)
  })

  it('partitions a mixed list into upNext and backlog', () => {
    const tasks = [
      task({ id: 'overdue', due_date: '2026-06-01' }),
      task({ id: 'today', due_date: TODAY }),
      task({ id: 'boundary', due_date: '2026-07-12' }),
      task({ id: 'beyond', due_date: '2026-07-13' }),
      task({ id: 'no-date', due_date: null }),
    ]
    const { upNext, backlog } = partitionHomeTasks(tasks, TODAY)
    expect(upNext.map((t) => t.id)).toEqual(['overdue', 'today', 'boundary'])
    expect(backlog.map((t) => t.id)).toEqual(['beyond', 'no-date'])
  })
})

describe('compareUpNext', () => {
  it('sorts by due date ascending first', () => {
    const tasks = [
      task({ id: 'later', due_date: '2026-07-10' }),
      task({ id: 'sooner', due_date: '2026-07-05' }),
    ]
    expect([...tasks].sort(compareUpNext).map((t) => t.id)).toEqual([
      'sooner',
      'later',
    ])
  })

  it('breaks a due-date tie with priority descending (urgent first)', () => {
    const tasks = [
      task({ id: 'soon', due_date: '2026-07-05', priority: 'soon' }),
      task({ id: 'urgent', due_date: '2026-07-05', priority: 'urgent' }),
    ]
    expect([...tasks].sort(compareUpNext).map((t) => t.id)).toEqual([
      'urgent',
      'soon',
    ])
  })

  it('breaks a due-date+priority tie with in_progress before not_started', () => {
    const tasks = [
      task({
        id: 'not-started',
        due_date: '2026-07-05',
        priority: 'soon',
        status: 'not_started',
      }),
      task({
        id: 'in-progress',
        due_date: '2026-07-05',
        priority: 'soon',
        status: 'in_progress',
      }),
    ]
    expect([...tasks].sort(compareUpNext).map((t) => t.id)).toEqual([
      'in-progress',
      'not-started',
    ])
  })

  it('breaks remaining ties with oldest-created first, then id', () => {
    const tasks = [
      task({
        id: 'newer',
        due_date: '2026-07-05',
        created_at: '2026-01-02T00:00:00.000Z',
      }),
      task({
        id: 'older',
        due_date: '2026-07-05',
        created_at: '2026-01-01T00:00:00.000Z',
      }),
    ]
    expect([...tasks].sort(compareUpNext).map((t) => t.id)).toEqual([
      'older',
      'newer',
    ])
  })
})

describe('compareBacklog', () => {
  it('sorts by priority descending first', () => {
    const tasks = [
      task({ id: 'whenever', priority: 'whenever' }),
      task({ id: 'urgent', priority: 'urgent' }),
      task({ id: 'soon', priority: 'soon' }),
    ]
    expect([...tasks].sort(compareBacklog).map((t) => t.id)).toEqual([
      'urgent',
      'soon',
      'whenever',
    ])
  })

  it('breaks a priority tie with due date ascending, nulls last', () => {
    const tasks = [
      task({ id: 'no-date', priority: 'soon', due_date: null }),
      task({ id: 'later', priority: 'soon', due_date: '2026-08-01' }),
      task({ id: 'sooner', priority: 'soon', due_date: '2026-07-20' }),
    ]
    expect([...tasks].sort(compareBacklog).map((t) => t.id)).toEqual([
      'sooner',
      'later',
      'no-date',
    ])
  })

  it('breaks a priority+due-date tie with in_progress before not_started', () => {
    const tasks = [
      task({
        id: 'not-started',
        priority: 'soon',
        due_date: null,
        status: 'not_started',
      }),
      task({
        id: 'in-progress',
        priority: 'soon',
        due_date: null,
        status: 'in_progress',
      }),
    ]
    expect([...tasks].sort(compareBacklog).map((t) => t.id)).toEqual([
      'in-progress',
      'not-started',
    ])
  })

  it('breaks remaining ties with oldest-created first, then id', () => {
    const tasks = [
      task({
        id: 'newer',
        priority: 'soon',
        due_date: null,
        created_at: '2026-01-02T00:00:00.000Z',
      }),
      task({
        id: 'older',
        priority: 'soon',
        due_date: null,
        created_at: '2026-01-01T00:00:00.000Z',
      }),
    ]
    expect([...tasks].sort(compareBacklog).map((t) => t.id)).toEqual([
      'older',
      'newer',
    ])
  })
})

describe('isCollapsibleBacklogTask', () => {
  it('is true only for whenever priority with no due date', () => {
    expect(
      isCollapsibleBacklogTask(task({ priority: 'whenever', due_date: null })),
    ).toBe(true)
  })

  it('is false when a due date is set, even for whenever priority', () => {
    expect(
      isCollapsibleBacklogTask(
        task({ priority: 'whenever', due_date: '2026-08-01' }),
      ),
    ).toBe(false)
  })

  it('is false for a higher priority with no due date', () => {
    expect(
      isCollapsibleBacklogTask(task({ priority: 'soon', due_date: null })),
    ).toBe(false)
    expect(
      isCollapsibleBacklogTask(task({ priority: 'urgent', due_date: null })),
    ).toBe(false)
  })
})

describe('formatDueDate', () => {
  it('renders singular overdue for 1 day', () => {
    expect(formatDueDate('2026-07-04', TODAY)).toBe('1 day overdue')
  })

  it('renders plural overdue for multiple days', () => {
    expect(formatDueDate('2026-07-01', TODAY)).toBe('4 days overdue')
  })

  it('renders "Due today"', () => {
    expect(formatDueDate('2026-07-05', TODAY)).toBe('Due today')
  })

  it('renders "Due tomorrow"', () => {
    expect(formatDueDate('2026-07-06', TODAY)).toBe('Due tomorrow')
  })

  it('renders "Due in N days" for 2-7 days out', () => {
    expect(formatDueDate('2026-07-07', TODAY)).toBe('Due in 2 days')
    expect(formatDueDate('2026-07-12', TODAY)).toBe('Due in 7 days')
  })

  it('falls back to the absolute date beyond 7 days', () => {
    expect(formatDueDate('2026-07-13', TODAY)).toBe('Due 2026-07-13')
  })

  it('uses the passed `today`, not the wall clock', () => {
    const otherToday = '2000-01-01'
    expect(formatDueDate('2000-01-01', otherToday)).toBe('Due today')
    expect(formatDueDate('2000-01-02', otherToday)).toBe('Due tomorrow')
  })
})
