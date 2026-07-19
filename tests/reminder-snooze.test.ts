import { describe, expect, it } from 'vitest'
import {
  isValidSnoozeMinutes,
  SNOOZE_OPTIONS,
  snoozeTargetIso,
} from '../app/utils/reminder-snooze'

describe('SNOOZE_OPTIONS', () => {
  it('offers exactly the two fixed durations', () => {
    expect(SNOOZE_OPTIONS.map((o) => o.minutes)).toEqual([10, 60])
  })

  it('uses short, "chore"-flavored labels', () => {
    expect(SNOOZE_OPTIONS.map((o) => o.label)).toEqual([
      'Snooze 10 min',
      'Snooze 1 hr',
    ])
  })
})

describe('isValidSnoozeMinutes', () => {
  it('accepts the two whitelisted values', () => {
    expect(isValidSnoozeMinutes(10)).toBe(true)
    expect(isValidSnoozeMinutes(60)).toBe(true)
  })

  it('rejects numbers not on the whitelist', () => {
    expect(isValidSnoozeMinutes(15)).toBe(false)
    expect(isValidSnoozeMinutes(0)).toBe(false)
    expect(isValidSnoozeMinutes(-10)).toBe(false)
    expect(isValidSnoozeMinutes(120)).toBe(false)
  })

  it('rejects floats, even ones equal to a whitelisted value plus fraction', () => {
    expect(isValidSnoozeMinutes(10.5)).toBe(false)
    expect(isValidSnoozeMinutes(60.0001)).toBe(false)
  })

  it('rejects numeric strings', () => {
    expect(isValidSnoozeMinutes('10')).toBe(false)
    expect(isValidSnoozeMinutes('60')).toBe(false)
  })

  it('rejects other non-number types', () => {
    expect(isValidSnoozeMinutes(null)).toBe(false)
    expect(isValidSnoozeMinutes(undefined)).toBe(false)
    expect(isValidSnoozeMinutes(true)).toBe(false)
    expect(isValidSnoozeMinutes({})).toBe(false)
    expect(isValidSnoozeMinutes([10])).toBe(false)
    expect(isValidSnoozeMinutes(NaN)).toBe(false)
    expect(isValidSnoozeMinutes(Infinity)).toBe(false)
  })
})

describe('snoozeTargetIso', () => {
  const fixedNowMs = Date.UTC(2026, 6, 19, 12, 0, 0) // 2026-07-19T12:00:00.000Z

  it('adds 10 minutes for the short snooze', () => {
    expect(snoozeTargetIso(10, fixedNowMs)).toBe('2026-07-19T12:10:00.000Z')
  })

  it('adds 60 minutes for the long snooze', () => {
    expect(snoozeTargetIso(60, fixedNowMs)).toBe('2026-07-19T13:00:00.000Z')
  })

  it('defaults nowMs to Date.now() when omitted', () => {
    const before = Date.now()
    const iso = snoozeTargetIso(10)
    const after = Date.now()
    const targetMs = new Date(iso).getTime()
    expect(targetMs).toBeGreaterThanOrEqual(before + 10 * 60_000)
    expect(targetMs).toBeLessThanOrEqual(after + 10 * 60_000)
  })
})
