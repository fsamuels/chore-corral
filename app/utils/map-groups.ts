import type { TaskPriority, TaskSummary } from '../services/tasks'

/** User-facing priority wording, shared by map popups, pins and the legend. */
export const PRIORITY_LABELS: Record<TaskPriority, string> = {
  urgent: 'Urgent',
  soon: 'Soon',
  whenever: 'Whenever',
}

/** Most to least pressing; the order the legend and list sorting use. */
export const PRIORITY_ORDER: TaskPriority[] = ['urgent', 'soon', 'whenever']

/**
 * The most pressing priority among `tasks` (a shared map pin takes this so an
 * urgent chore is never hidden behind a calmer one). Falls back to
 * 'whenever' for an empty list.
 */
export function highestPriority(
  tasks: Pick<TaskSummary, 'priority'>[],
): TaskPriority {
  for (const priority of PRIORITY_ORDER) {
    if (tasks.some((task) => task.priority === priority)) return priority
  }
  return 'whenever'
}
