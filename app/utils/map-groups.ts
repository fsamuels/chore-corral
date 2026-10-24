import type { TaskPriority, TaskSummary } from '../services/tasks'
import type { LocationSummary } from '../services/locations'

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

export interface PlaceGroup<T> {
  /** Stable key, also usable as a DOM id suffix: `location-<id>`, `custom`, `none`. */
  key: string
  title: string
  tasks: T[]
}

export const CUSTOM_PINS_TITLE = 'Custom pins'
export const NO_LOCATION_TITLE = 'No location'

type Placed = Pick<
  TaskSummary,
  'lat' | 'lng' | 'location_id' | 'priority' | 'title'
>

/**
 * Groups chores by place for the list view: one group per defined location
 * (alphabetical), then "Custom pins" (lat/lng only), then "No location".
 * Empty groups are omitted. Chores within a group are ordered by priority,
 * then title. A location_id that no longer resolves falls back to its own
 * pin, or to no location, mirroring what the map can plot.
 */
export function groupTasksByPlace<T extends Placed>(
  tasks: T[],
  locations: Pick<LocationSummary, 'id' | 'name'>[],
): PlaceGroup<T>[] {
  const known = new Set(locations.map((location) => location.id))
  const byLocation = new Map<string, T[]>()
  const custom: T[] = []
  const none: T[] = []

  for (const task of tasks) {
    if (task.location_id !== null && known.has(task.location_id)) {
      const list = byLocation.get(task.location_id)
      if (list) list.push(task)
      else byLocation.set(task.location_id, [task])
    } else if (task.lat !== null && task.lng !== null) {
      custom.push(task)
    } else {
      none.push(task)
    }
  }

  const compare = (a: T, b: T) =>
    PRIORITY_ORDER.indexOf(a.priority) - PRIORITY_ORDER.indexOf(b.priority) ||
    a.title.localeCompare(b.title)

  const groups: PlaceGroup<T>[] = [...locations]
    .sort((a, b) => a.name.localeCompare(b.name))
    .filter((location) => byLocation.has(location.id))
    .map((location) => ({
      key: `location-${location.id}`,
      title: location.name,
      tasks: byLocation.get(location.id)!.sort(compare),
    }))
  if (custom.length)
    groups.push({
      key: 'custom',
      title: CUSTOM_PINS_TITLE,
      tasks: custom.sort(compare),
    })
  if (none.length)
    groups.push({
      key: 'none',
      title: NO_LOCATION_TITLE,
      tasks: none.sort(compare),
    })
  return groups
}
