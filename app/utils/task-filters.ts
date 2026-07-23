import type { TaskPriority, TaskStatus, TaskSummary } from '../services/tasks'
import { isTaskOverdue } from '../services/tasks'

// Sentinel for "no filter" on enum-valued dimensions — `'all'` can't collide
// with a real TaskStatus/TaskPriority value.
export const ALL = 'all' as const

export type DueDateFilter = 'all' | 'has_due_date' | 'no_due_date'

export interface TaskFilters {
  status: TaskStatus | typeof ALL
  priority: TaskPriority | typeof ALL
  dueDate: DueDateFilter
  overdueOnly: boolean
  search: string
}

export function defaultTaskFilters(): TaskFilters {
  return {
    status: ALL,
    priority: ALL,
    dueDate: ALL,
    overdueOnly: false,
    search: '',
  }
}

export function matchesStatus(
  task: Pick<TaskSummary, 'status'>,
  status: TaskStatus | typeof ALL,
): boolean {
  return status === ALL || task.status === status
}

export function matchesPriority(
  task: Pick<TaskSummary, 'priority'>,
  priority: TaskPriority | typeof ALL,
): boolean {
  return priority === ALL || task.priority === priority
}

export function matchesDueDateFilter(
  task: Pick<TaskSummary, 'due_date'>,
  filter: DueDateFilter,
): boolean {
  if (filter === 'has_due_date') return task.due_date !== null
  if (filter === 'no_due_date') return task.due_date === null
  return true
}

export function matchesSearch(
  task: Pick<TaskSummary, 'title'>,
  search: string | null | undefined,
): boolean {
  // Vuetify's `clearable` resets a text field's v-model to `null` (not
  // `''`) when the X is clicked, so this has to tolerate that directly
  // rather than relying on callers to normalize it first.
  const query = (search ?? '').trim().toLowerCase()
  if (!query) return true
  return task.title.toLowerCase().includes(query)
}

/**
 * Apply every dimension in `filters` to `tasks`. `overdueOnly` reuses
 * `isTaskOverdue`'s local-calendar-date comparison, so `now` is threaded
 * through the same way for testability.
 */
export function filterTasks(
  tasks: TaskSummary[],
  filters: TaskFilters,
  now: Date = new Date(),
): TaskSummary[] {
  return tasks.filter(
    (task) =>
      matchesStatus(task, filters.status) &&
      matchesPriority(task, filters.priority) &&
      matchesDueDateFilter(task, filters.dueDate) &&
      matchesSearch(task, filters.search) &&
      (!filters.overdueOnly || isTaskOverdue(task, now)),
  )
}
