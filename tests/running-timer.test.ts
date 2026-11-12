import { describe, expect, it } from 'vitest'
import {
  isSameRunningEntry,
  reconcileRunningEntry,
} from '../app/utils/running-timer'
import type { TimeEntrySummary } from '../app/services/time-entries'

const entry = (over: Partial<TimeEntrySummary> = {}): TimeEntrySummary => ({
  id: 'e1',
  task_id: 't1',
  user_id: 'u1',
  started_at: '2026-11-12T10:00:00Z',
  ended_at: null,
  created_at: '2026-11-12T10:00:00Z',
  ...over,
})

describe('isSameRunningEntry', () => {
  it('matches the same id and start', () => {
    expect(isSameRunningEntry(entry(), entry())).toBe(true)
  })

  it('differs on id (switched to another session)', () => {
    expect(isSameRunningEntry(entry(), entry({ id: 'e2' }))).toBe(false)
  })

  it('differs when the start was edited elsewhere', () => {
    expect(
      isSameRunningEntry(
        entry(),
        entry({ started_at: '2026-11-12T09:00:00Z' }),
      ),
    ).toBe(false)
  })

  it('treats null as only equal to null', () => {
    expect(isSameRunningEntry(null, null)).toBe(true)
    expect(isSameRunningEntry(null, entry())).toBe(false)
    expect(isSameRunningEntry(entry(), null)).toBe(false)
  })
})

describe('reconcileRunningEntry', () => {
  it('keeps the existing object when the fetch found the same session', () => {
    const current = entry()
    expect(reconcileRunningEntry(current, entry())).toBe(current)
  })

  it('takes the fetched entry when it is a different session or task', () => {
    const fetched = entry({ id: 'e2', task_id: 't2' })
    expect(reconcileRunningEntry(entry(), fetched)).toBe(fetched)
  })

  it('takes null when the timer was stopped elsewhere', () => {
    expect(reconcileRunningEntry(entry(), null)).toBeNull()
  })

  it('takes the fetched entry when nothing was running before', () => {
    const fetched = entry()
    expect(reconcileRunningEntry(null, fetched)).toBe(fetched)
  })
})
