import { describe, expect, it } from 'vitest'
import {
  assigneeDisplayNames,
  combineDateAndTime,
  formatDaysOld,
  formatDaysToComplete,
  formatElapsedDuration,
  formatElapsedWithSeconds,
  formatEstimatedMinutes,
  formatTimeForInput,
  locationDisplayName,
  parseEstimatedMinutesInput,
  taskTimeProgress,
} from '../app/utils/task-display'

describe('parseEstimatedMinutesInput', () => {
  it('treats empty and whitespace-only input as no estimate', () => {
    expect(parseEstimatedMinutesInput('')).toBeNull()
    expect(parseEstimatedMinutesInput('   ')).toBeNull()
  })

  it('converts numeric input, including values the service guard will reject', () => {
    expect(parseEstimatedMinutesInput('90')).toBe(90)
    expect(parseEstimatedMinutesInput(' 45 ')).toBe(45)
    expect(parseEstimatedMinutesInput('1.5')).toBe(1.5)
    expect(parseEstimatedMinutesInput('0')).toBe(0)
  })

  it('passes non-numeric input through as NaN for the guard to reject', () => {
    expect(parseEstimatedMinutesInput('soon')).toBeNaN()
  })
})

describe('formatEstimatedMinutes', () => {
  it('renders sub-hour estimates as minutes only', () => {
    expect(formatEstimatedMinutes(1)).toBe('1m')
    expect(formatEstimatedMinutes(45)).toBe('45m')
    expect(formatEstimatedMinutes(59)).toBe('59m')
  })

  it('renders whole-hour estimates as hours only', () => {
    expect(formatEstimatedMinutes(60)).toBe('1h')
    expect(formatEstimatedMinutes(120)).toBe('2h')
  })

  it('renders mixed estimates as hours and minutes', () => {
    expect(formatEstimatedMinutes(61)).toBe('1h 1m')
    expect(formatEstimatedMinutes(90)).toBe('1h 30m')
    expect(formatEstimatedMinutes(1441)).toBe('24h 1m')
  })
})

describe('formatElapsedDuration', () => {
  it('renders sub-minute durations as "<1m" rather than "0m"', () => {
    expect(formatElapsedDuration(0)).toBe('<1m')
    expect(formatElapsedDuration(59_000)).toBe('<1m')
  })

  it('renders whole minutes/hours the same way formatEstimatedMinutes does', () => {
    expect(formatElapsedDuration(60_000)).toBe('1m')
    expect(formatElapsedDuration(90 * 60_000)).toBe('1h 30m')
  })
})

describe('formatElapsedWithSeconds', () => {
  it('renders sub-minute durations as seconds only', () => {
    expect(formatElapsedWithSeconds(0)).toBe('0s')
    expect(formatElapsedWithSeconds(45_000)).toBe('45s')
  })

  it('renders minutes/hours with a trailing seconds component', () => {
    expect(formatElapsedWithSeconds(65_000)).toBe('1m 5s')
    expect(formatElapsedWithSeconds(90 * 60_000 + 5_000)).toBe('1h 30m 5s')
  })
})

describe('formatTimeForInput', () => {
  it('renders zero-padded 24-hour "HH:mm"', () => {
    expect(formatTimeForInput(new Date(2026, 6, 9, 9, 5))).toBe('09:05')
    expect(formatTimeForInput(new Date(2026, 6, 9, 23, 59))).toBe('23:59')
    expect(formatTimeForInput(new Date(2026, 6, 9, 0, 0))).toBe('00:00')
  })
})

describe('combineDateAndTime', () => {
  it("combines a date's Y/M/D with an HH:mm time into one local Date", () => {
    const date = new Date(2026, 6, 9)
    const result = combineDateAndTime(date, '14:30')
    expect(result).toEqual(new Date(2026, 6, 9, 14, 30))
  })

  it('ignores any time-of-day already on the date argument, using only Y/M/D', () => {
    const date = new Date(2026, 6, 9, 8, 0)
    const result = combineDateAndTime(date, '00:00')
    expect(result).toEqual(new Date(2026, 6, 9, 0, 0))
  })

  it('rejects a malformed time string', () => {
    expect(combineDateAndTime(new Date(2026, 6, 9), '25:00')).toBeNull()
    expect(combineDateAndTime(new Date(2026, 6, 9), '10:75')).toBeNull()
    expect(combineDateAndTime(new Date(2026, 6, 9), 'nope')).toBeNull()
    expect(combineDateAndTime(new Date(2026, 6, 9), '')).toBeNull()
  })
})

describe('formatDaysOld', () => {
  it('renders same-calendar-day as "0 days old"', () => {
    expect(formatDaysOld('2026-07-09T12:00:00.000Z', '2026-07-09')).toBe(
      '0 days old',
    )
  })

  it('renders singular "1 day old"', () => {
    expect(formatDaysOld('2026-07-08T12:00:00.000Z', '2026-07-09')).toBe(
      '1 day old',
    )
  })

  it('renders plural "X days old"', () => {
    expect(formatDaysOld('2026-07-01T12:00:00.000Z', '2026-07-09')).toBe(
      '8 days old',
    )
  })
})

describe('formatDaysToComplete', () => {
  it('measures created_at to completed_at when the task is done', () => {
    expect(
      formatDaysToComplete(
        '2026-07-01T12:00:00.000Z',
        '2026-07-04T12:00:00.000Z',
        '2026-07-09',
      ),
    ).toBe('3 days to complete')
  })

  it('falls back to today when the task is still open', () => {
    expect(
      formatDaysToComplete('2026-07-01T12:00:00.000Z', null, '2026-07-09'),
    ).toBe('8 days to complete')
  })

  it('renders singular "1 day to complete"', () => {
    expect(
      formatDaysToComplete(
        '2026-07-08T12:00:00.000Z',
        '2026-07-09T12:00:00.000Z',
        '2026-07-09',
      ),
    ).toBe('1 day to complete')
  })

  it('renders same-day completion as "0 days to complete"', () => {
    expect(
      formatDaysToComplete(
        '2026-07-09T08:00:00.000Z',
        '2026-07-09T10:00:00.000Z',
        '2026-07-09',
      ),
    ).toBe('0 days to complete')
  })
})

describe('locationDisplayName', () => {
  const locations = [{ id: 'loc-1', name: 'Barn' }]

  it('resolves the name for a task with a defined location', () => {
    expect(locationDisplayName('loc-1', locations)).toBe('Barn')
  })

  it('is null when the task has no location', () => {
    expect(locationDisplayName(null, locations)).toBeNull()
  })

  it('is null when location_id points at a location no longer in the list', () => {
    expect(locationDisplayName('deleted-loc', locations)).toBeNull()
  })

  it('is null when the locations list is null/undefined', () => {
    expect(locationDisplayName('loc-1', null)).toBeNull()
    expect(locationDisplayName('loc-1', undefined)).toBeNull()
  })
})

describe('assigneeDisplayNames', () => {
  const labels = new Map([
    ['user-1', 'Steve'],
    ['user-2', 'Kaleb'],
  ])

  it('resolves and sorts assignee labels', () => {
    expect(assigneeDisplayNames(['user-2', 'user-1'], labels)).toEqual([
      'Kaleb',
      'Steve',
    ])
  })

  it('is empty for an unassigned chore', () => {
    expect(assigneeDisplayNames([], labels)).toEqual([])
  })

  it('drops an assignee whose id no longer resolves (left the farm)', () => {
    expect(assigneeDisplayNames(['user-1', 'gone'], labels)).toEqual(['Steve'])
  })
})

describe('taskTimeProgress', () => {
  const MIN = 60000

  it('returns null when nothing has been tracked', () => {
    expect(taskTimeProgress(0, 60)).toBeNull()
    expect(taskTimeProgress(0, null)).toBeNull()
  })

  it('shows tracked time alone without an estimate', () => {
    expect(taskTimeProgress(90 * MIN, null)).toEqual({
      trackedLabel: '1h 30m',
      percent: null,
      level: 'none',
    })
    expect(taskTimeProgress(90 * MIN, 0)?.level).toBe('none')
  })

  it('is ok below 80% of the estimate', () => {
    expect(taskTimeProgress(30 * MIN, 60)).toEqual({
      trackedLabel: '30m',
      percent: 50,
      level: 'ok',
    })
    expect(taskTimeProgress(47 * MIN, 60)?.level).toBe('ok')
  })

  it('warns from 80% up to just under 100%', () => {
    expect(taskTimeProgress(48 * MIN, 60)).toMatchObject({
      percent: 80,
      level: 'warn',
    })
    // 99.9% rounds down, so the label never says 100% before it's reached.
    expect(taskTimeProgress(60 * MIN - 1000, 60)).toMatchObject({
      percent: 99,
      level: 'warn',
    })
  })

  it('is over at 100% or more, uncapped', () => {
    expect(taskTimeProgress(60 * MIN, 60)).toMatchObject({
      percent: 100,
      level: 'over',
    })
    expect(taskTimeProgress(81 * MIN, 60)).toMatchObject({
      percent: 135,
      level: 'over',
    })
  })
})
