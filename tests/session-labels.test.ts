import { describe, expect, it } from 'vitest'
import {
  MAX_SESSION_LABELS,
  MAX_SESSION_LABEL_LENGTH,
  canonicalizeLabels,
  labelBreakdown,
  labelSuggestions,
  normalizeLabels,
  sameLabels,
} from '../app/utils/session-labels'

describe('normalizeLabels', () => {
  it('trims, collapses whitespace and drops blanks', () => {
    expect(normalizeLabels(['  morning   feeding ', '', '   '])).toEqual([
      'morning feeding',
    ])
  })

  it('drops case-insensitive duplicates, keeping the first spelling', () => {
    expect(
      normalizeLabels(['Aaron helped', 'aaron HELPED', 'mucking']),
    ).toEqual(['Aaron helped', 'mucking'])
  })

  it('caps the length of each label and the number of labels', () => {
    const long = 'x'.repeat(MAX_SESSION_LABEL_LENGTH + 10)
    expect(normalizeLabels([long])[0]).toHaveLength(MAX_SESSION_LABEL_LENGTH)
    const many = Array.from({ length: 12 }, (_, i) => `label ${i}`)
    expect(normalizeLabels(many)).toHaveLength(MAX_SESSION_LABELS)
  })
})

describe('canonicalizeLabels', () => {
  it("reuses a known label's spelling", () => {
    expect(
      canonicalizeLabels(['aaron helped', 'Night feeding'], ['Aaron helped']),
    ).toEqual(['Aaron helped', 'Night feeding'])
  })

  it('drops duplicates that only differ once canonicalized', () => {
    expect(canonicalizeLabels(['mucking', 'MUCKING'], ['Mucking'])).toEqual([
      'Mucking',
    ])
  })
})

describe('labelSuggestions', () => {
  it('lists distinct labels, most recently used first', () => {
    expect(
      labelSuggestions([
        {
          started_at: '2026-11-01T08:00:00Z',
          labels: ['morning feeding', 'mucking'],
        },
        { started_at: '2026-11-02T18:00:00Z', labels: ['night feeding'] },
        {
          started_at: '2026-11-03T08:00:00Z',
          labels: ['Morning feeding', 'Aaron helped'],
        },
      ]),
    ).toEqual(['Morning feeding', 'Aaron helped', 'night feeding', 'mucking'])
  })

  it('handles sessions without labels', () => {
    expect(
      labelSuggestions([{ started_at: '2026-11-01T08:00:00Z', labels: [] }]),
    ).toEqual([])
  })
})

describe('labelBreakdown', () => {
  const session = (
    start: string,
    minutes: number | null,
    labels: string[],
  ) => ({
    started_at: start,
    ended_at:
      minutes === null
        ? null
        : new Date(Date.parse(start) + minutes * 60_000).toISOString(),
    labels,
  })

  it('averages finished sessions per label combination, ignoring order and case', () => {
    const rows = labelBreakdown([
      session('2026-11-01T08:00:00Z', 40, ['morning feeding', 'mucking']),
      session('2026-11-02T08:00:00Z', 50, ['Mucking', 'Morning feeding']),
      session('2026-11-03T08:00:00Z', 20, [
        'morning feeding',
        'mucking',
        'Aaron helped',
      ]),
    ])
    expect(rows).toEqual([
      {
        labels: ['morning feeding', 'mucking'],
        count: 2,
        totalMs: 90 * 60_000,
        averageMs: 45 * 60_000,
      },
      {
        labels: ['morning feeding', 'mucking', 'Aaron helped'],
        count: 1,
        totalMs: 20 * 60_000,
        averageMs: 20 * 60_000,
      },
    ])
  })

  it('leaves out running, unlabelled and invalid sessions', () => {
    expect(
      labelBreakdown([
        session('2026-11-01T08:00:00Z', null, ['mucking']),
        session('2026-11-01T09:00:00Z', 30, []),
        { started_at: 'nope', ended_at: '2026-11-01T10:00:00Z', labels: ['x'] },
      ]),
    ).toEqual([])
  })

  it('orders equally used combinations by shorter average', () => {
    const rows = labelBreakdown([
      session('2026-11-01T08:00:00Z', 60, ['night feeding']),
      session('2026-11-01T09:00:00Z', 15, ['morning feeding']),
    ])
    expect(rows.map((row) => row.labels[0])).toEqual([
      'morning feeding',
      'night feeding',
    ])
  })
})

describe('sameLabels', () => {
  it('compares contents and order', () => {
    expect(sameLabels(['a', 'b'], ['a', 'b'])).toBe(true)
    expect(sameLabels(['a', 'b'], ['b', 'a'])).toBe(false)
    expect(sameLabels(undefined, [])).toBe(true)
  })
})
