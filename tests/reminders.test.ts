import { describe, expect, it } from 'vitest'
import {
  addReminder,
  assertValidReminderTime,
  listReminders,
  removeReminder,
  snoozeReminder,
  type ReminderSummary,
} from '../app/services/reminders'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type ReminderRow = Database['public']['Tables']['task_reminders']['Row']

const USER = 'user-1'

function futureIso(msFromNow = 60_000): string {
  return new Date(Date.now() + msFromNow).toISOString()
}

function pastIso(msAgo = 60_000): string {
  return new Date(Date.now() - msAgo).toISOString()
}

function reminder(overrides: Partial<ReminderRow> = {}): ReminderRow {
  return {
    id: 'reminder-seed',
    task_id: 'task-1',
    remind_at: futureIso(),
    created_by: USER,
    sent_at: null,
    created_at: '2026-07-18T10:00:00Z',
    ...overrides,
  }
}

describe('assertValidReminderTime', () => {
  it('accepts a future instant', () => {
    expect(() => assertValidReminderTime(futureIso())).not.toThrow()
  })

  it('rejects an unparseable string', () => {
    expect(() => assertValidReminderTime('not-a-date')).toThrow(
      'Enter a valid reminder date and time.',
    )
  })

  it('rejects a past instant', () => {
    expect(() => assertValidReminderTime(pastIso())).toThrow(
      'Reminder time must be in the future.',
    )
  })

  it('rejects the current instant (not strictly in the future)', () => {
    expect(() => assertValidReminderTime(new Date().toISOString())).toThrow(
      'Reminder time must be in the future.',
    )
  })
})

describe('listReminders', () => {
  it('returns only the given task’s reminders, soonest first', async () => {
    const fake = new FakeSupabaseClient({
      task_reminders: [
        reminder({
          id: 'r-late',
          task_id: 'task-1',
          remind_at: futureIso(120_000),
        }),
        reminder({
          id: 'r-soon',
          task_id: 'task-1',
          remind_at: futureIso(60_000),
        }),
        reminder({ id: 'r-other-task', task_id: 'task-2' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const list = await listReminders(supabase, 'task-1')

    expect(list.map((r) => r.id)).toEqual(['r-soon', 'r-late'])
  })

  it('returns an empty list for a task with no reminders', async () => {
    const fake = new FakeSupabaseClient({ task_reminders: [] })
    const supabase = asSupabaseClient(fake)

    expect(await listReminders(supabase, 'task-1')).toEqual([])
  })
})

describe('addReminder', () => {
  it('schedules a reminder and returns it', async () => {
    const fake = new FakeSupabaseClient({ task_reminders: [] })
    const supabase = asSupabaseClient(fake)
    const remindAt = futureIso()

    const created = await addReminder(supabase, 'task-1', remindAt, USER)

    expect(created.task_id).toBe('task-1')
    expect(created.remind_at).toBe(remindAt)
    expect(created.sent_at).toBeNull()

    const rows = fake.getTable('task_reminders') as ReminderRow[]
    expect(rows).toHaveLength(1)
    expect(rows[0]!.created_by).toBe(USER)
  })

  it('rejects a past reminder time without writing anything', async () => {
    const fake = new FakeSupabaseClient({ task_reminders: [] })
    const supabase = asSupabaseClient(fake)

    await expect(
      addReminder(supabase, 'task-1', pastIso(), USER),
    ).rejects.toThrow('Reminder time must be in the future.')

    expect(fake.getTable('task_reminders')).toHaveLength(0)
  })

  it('propagates an injected insert failure', async () => {
    const fake = new FakeSupabaseClient(
      { task_reminders: [] },
      { table: 'task_reminders', op: 'insert', message: 'insert boom' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      addReminder(supabase, 'task-1', futureIso(), USER),
    ).rejects.toThrow('insert boom')
  })
})

describe('removeReminder', () => {
  it('deletes the given reminder', async () => {
    const fake = new FakeSupabaseClient({
      task_reminders: [
        reminder({ id: 'keep', task_id: 'task-1' }),
        reminder({ id: 'gone', task_id: 'task-1' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    await removeReminder(supabase, 'gone')

    const rows = fake.getTable('task_reminders') as ReminderRow[]
    expect(rows.map((r) => r.id)).toEqual(['keep'])
  })

  it('propagates an injected delete failure', async () => {
    const fake = new FakeSupabaseClient(
      { task_reminders: [reminder({ id: 'r1' })] },
      { table: 'task_reminders', op: 'delete', message: 'delete boom' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(removeReminder(supabase, 'r1')).rejects.toThrow('delete boom')
  })
})

describe('snoozeReminder', () => {
  it('moves remind_at forward and clears sent_at', async () => {
    const fake = new FakeSupabaseClient({
      task_reminders: [
        reminder({ id: 'r1', task_id: 'task-1', sent_at: pastIso() }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const updated = await snoozeReminder(supabase, 'r1', 10)

    expect(updated.id).toBe('r1')
    expect(updated.sent_at).toBeNull()
    const targetMs = new Date(updated.remind_at).getTime()
    expect(targetMs).toBeGreaterThan(Date.now() + 9 * 60_000)
    expect(targetMs).toBeLessThan(Date.now() + 11 * 60_000)

    const rows = fake.getTable('task_reminders') as ReminderRow[]
    expect(rows[0]!.sent_at).toBeNull()
  })

  it('supports the 1-hour option too', async () => {
    const fake = new FakeSupabaseClient({
      task_reminders: [
        reminder({ id: 'r1', task_id: 'task-1', sent_at: pastIso() }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const updated = await snoozeReminder(supabase, 'r1', 60)

    const targetMs = new Date(updated.remind_at).getTime()
    expect(targetMs).toBeGreaterThan(Date.now() + 59 * 60_000)
    expect(targetMs).toBeLessThan(Date.now() + 61 * 60_000)
  })

  it('rejects a minutes value outside the whitelist with a readable message', async () => {
    const seedRow = reminder({ id: 'r1' })
    const fake = new FakeSupabaseClient({ task_reminders: [seedRow] })
    const supabase = asSupabaseClient(fake)

    await expect(snoozeReminder(supabase, 'r1', 15)).rejects.toThrow(
      'Snooze must be 10 minutes or 1 hour.',
    )

    // Nothing was written — the row is untouched.
    const rows = fake.getTable('task_reminders') as ReminderRow[]
    expect(rows[0]!.remind_at).toBe(seedRow.remind_at)
  })

  it('rejects a non-numeric minutes value', async () => {
    const fake = new FakeSupabaseClient({
      task_reminders: [reminder({ id: 'r1' })],
    })
    const supabase = asSupabaseClient(fake)

    await expect(snoozeReminder(supabase, 'r1', '10')).rejects.toThrow(
      'Snooze must be 10 minutes or 1 hour.',
    )
  })

  it('propagates an injected update failure', async () => {
    const fake = new FakeSupabaseClient(
      { task_reminders: [reminder({ id: 'r1' })] },
      { table: 'task_reminders', op: 'update', message: 'update boom' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(snoozeReminder(supabase, 'r1', 10)).rejects.toThrow(
      'update boom',
    )
  })

  it('throws "Reminder not found" when no row matches the id', async () => {
    const fake = new FakeSupabaseClient({
      task_reminders: [reminder({ id: 'other-id' })],
    })
    const supabase = asSupabaseClient(fake)

    await expect(snoozeReminder(supabase, 'missing-id', 10)).rejects.toThrow(
      'Reminder not found',
    )
  })
})

// Sanity check that the exported type stays structurally compatible with the
// service's own row shape (guards against a silent drift if the columns
// selected in REMINDER_COLUMNS ever stop matching ReminderSummary).
describe('ReminderSummary shape', () => {
  it('round-trips through addReminder', async () => {
    const fake = new FakeSupabaseClient({ task_reminders: [] })
    const supabase = asSupabaseClient(fake)
    const created: ReminderSummary = await addReminder(
      supabase,
      'task-1',
      futureIso(),
      USER,
    )
    expect(typeof created.id).toBe('string')
  })
})
