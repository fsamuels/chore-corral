import { describe, expect, it } from 'vitest'
import {
  combineDateAndTime,
  formatElapsedDuration,
  formatEstimatedMinutes,
  formatTimeForInput,
  parseEstimatedMinutesInput,
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
