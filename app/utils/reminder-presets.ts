/**
 * One-tap reminder times for the chore Reminders card. Pure (takes `now`) so
 * it's testable; all "today"/"tomorrow" math is in the viewer's local time.
 */

export interface ReminderPreset {
  key: 'in-an-hour' | 'evening' | 'tomorrow-morning'
  label: string
  at: Date
}

const EVENING_HOUR = 18
const MORNING_HOUR = 8

function atLocalHour(base: Date, dayOffset: number, hour: number): Date {
  const d = new Date(base)
  d.setDate(d.getDate() + dayOffset)
  d.setHours(hour, 0, 0, 0)
  return d
}

export function reminderPresets(now: Date): ReminderPreset[] {
  // Once 6 PM has passed, "this evening" would be in the past.
  const eveningPassed = now.getHours() >= EVENING_HOUR
  return [
    {
      key: 'in-an-hour',
      label: 'In 1 hour',
      at: new Date(now.getTime() + 60 * 60_000),
    },
    {
      key: 'evening',
      label: eveningPassed ? 'Tomorrow evening' : 'This evening',
      at: atLocalHour(now, eveningPassed ? 1 : 0, EVENING_HOUR),
    },
    {
      key: 'tomorrow-morning',
      label: 'Tomorrow morning',
      at: atLocalHour(now, 1, MORNING_HOUR),
    },
  ]
}
