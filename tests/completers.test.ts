import { describe, expect, it } from 'vitest'
import {
  assertValidCompleters,
  listCompletersForTasks,
  setTaskCompleters,
  type TaskCompleter,
} from '../app/services/completers'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type TaskCompleterRow = Database['public']['Tables']['task_completers']['Row']

const ACTOR = 'user-1'
const OTHER = 'user-2'

function completer(
  overrides: Partial<TaskCompleterRow> = {},
): TaskCompleterRow {
  return {
    id: 'completer-seed',
    task_id: 'task-1',
    user_id: ACTOR,
    completer_name: null,
    ...overrides,
  }
}

describe('assertValidCompleters', () => {
  it('accepts an empty set, a lone member, a lone name, and a mixed set', () => {
    expect(() => assertValidCompleters([])).not.toThrow()
    expect(() =>
      assertValidCompleters([{ user_id: ACTOR, completer_name: null }]),
    ).not.toThrow()
    expect(() =>
      assertValidCompleters([{ user_id: null, completer_name: 'Kaleb' }]),
    ).not.toThrow()
    expect(() =>
      assertValidCompleters([
        { user_id: ACTOR, completer_name: null },
        { user_id: null, completer_name: 'Kaleb' },
        { user_id: OTHER, completer_name: null },
      ]),
    ).not.toThrow()
  })

  it('rejects an entry that sets both a member and a name (per-row XOR)', () => {
    expect(() =>
      assertValidCompleters([{ user_id: ACTOR, completer_name: 'Kaleb' }]),
    ).toThrow('A completer is either a member or a free-text name, not both')
  })

  it('rejects an entry that sets neither', () => {
    expect(() =>
      assertValidCompleters([{ user_id: null, completer_name: null }]),
    ).toThrow('A completer is either a member or a free-text name, not both')
  })

  it('rejects a duplicate member', () => {
    expect(() =>
      assertValidCompleters([
        { user_id: ACTOR, completer_name: null },
        { user_id: ACTOR, completer_name: null },
      ]),
    ).toThrow('A chore cannot list the same completer twice')
  })

  it('rejects a duplicate free-text name', () => {
    expect(() =>
      assertValidCompleters([
        { user_id: null, completer_name: 'Kaleb' },
        { user_id: null, completer_name: 'Kaleb' },
      ]),
    ).toThrow('A chore cannot list the same completer twice')
  })
})

describe('setTaskCompleters', () => {
  it('replaces the full set: clears old rows and inserts the new ones', async () => {
    const fake = new FakeSupabaseClient({
      task_completers: [
        completer({
          id: 'old',
          task_id: 'task-1',
          completer_name: 'Gerald',
          user_id: null,
        }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    await setTaskCompleters(supabase, {
      taskId: 'task-1',
      completers: [
        { user_id: ACTOR, completer_name: null },
        { user_id: null, completer_name: 'Kaleb' },
      ],
    })

    const rows = fake
      .getTable('task_completers')
      .filter((r) => (r as TaskCompleterRow).task_id === 'task-1')
    expect(rows).toHaveLength(2)
    expect((rows as TaskCompleterRow[]).some((r) => r.user_id === ACTOR)).toBe(
      true,
    )
    expect(
      (rows as TaskCompleterRow[]).some((r) => r.completer_name === 'Kaleb'),
    ).toBe(true)
    // The old Gerald row is gone.
    expect(
      (rows as TaskCompleterRow[]).some((r) => r.completer_name === 'Gerald'),
    ).toBe(false)
  })

  it('empties the set (delete-all, no insert)', async () => {
    const fake = new FakeSupabaseClient({
      task_completers: [
        completer({ id: 'c1', task_id: 'task-1', user_id: ACTOR }),
        completer({
          id: 'c2',
          task_id: 'task-1',
          user_id: null,
          completer_name: 'Kaleb',
        }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    await setTaskCompleters(supabase, { taskId: 'task-1', completers: [] })

    expect(
      fake
        .getTable('task_completers')
        .filter((r) => (r as TaskCompleterRow).task_id === 'task-1'),
    ).toHaveLength(0)
  })

  it('only touches the target task, leaving another task’s completers intact', async () => {
    const fake = new FakeSupabaseClient({
      task_completers: [
        completer({ id: 'keep', task_id: 'task-2', user_id: OTHER }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    await setTaskCompleters(supabase, {
      taskId: 'task-1',
      completers: [{ user_id: ACTOR, completer_name: null }],
    })

    expect(
      fake
        .getTable('task_completers')
        .filter((r) => (r as TaskCompleterRow).task_id === 'task-2'),
    ).toHaveLength(1)
  })

  it('trims free-text names and drops empty ones before writing', async () => {
    const fake = new FakeSupabaseClient({ task_completers: [] })
    const supabase = asSupabaseClient(fake)

    await setTaskCompleters(supabase, {
      taskId: 'task-1',
      completers: [
        { user_id: null, completer_name: '  Kaleb  ' },
        { user_id: null, completer_name: '   ' },
      ],
    })

    const rows = fake.getTable('task_completers') as TaskCompleterRow[]
    expect(rows).toHaveLength(1)
    expect(rows[0]!.completer_name).toBe('Kaleb')
  })

  it('rejects a duplicate member without writing anything', async () => {
    const fake = new FakeSupabaseClient({ task_completers: [] })
    const supabase = asSupabaseClient(fake)

    await expect(
      setTaskCompleters(supabase, {
        taskId: 'task-1',
        completers: [
          { user_id: ACTOR, completer_name: null },
          { user_id: ACTOR, completer_name: null },
        ],
      }),
    ).rejects.toThrow('A chore cannot list the same completer twice')

    expect(fake.getTable('task_completers')).toHaveLength(0)
  })

  it('propagates an injected insert failure', async () => {
    const fake = new FakeSupabaseClient(
      { task_completers: [] },
      { table: 'task_completers', op: 'insert', message: 'insert boom' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      setTaskCompleters(supabase, {
        taskId: 'task-1',
        completers: [{ user_id: ACTOR, completer_name: null }],
      }),
    ).rejects.toThrow('insert boom')
  })
})

describe('listCompletersForTasks', () => {
  it('keys completers by task id, members before names within a task', async () => {
    const fake = new FakeSupabaseClient({
      task_completers: [
        completer({
          id: 'c1',
          task_id: 'task-1',
          user_id: null,
          completer_name: 'Kaleb',
        }),
        completer({ id: 'c2', task_id: 'task-1', user_id: ACTOR }),
        completer({ id: 'c3', task_id: 'task-2', user_id: OTHER }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const byTask = await listCompletersForTasks(supabase, ['task-1', 'task-2'])

    expect(byTask.get('task-1')).toEqual([
      { user_id: ACTOR, completer_name: null },
      { user_id: null, completer_name: 'Kaleb' },
    ])
    expect(byTask.get('task-2')).toEqual([
      { user_id: OTHER, completer_name: null },
    ])
  })

  it('returns an empty map for no task ids, without querying', async () => {
    const fake = new FakeSupabaseClient(
      { task_completers: [completer()] },
      { table: 'task_completers', op: 'select', message: 'should not run' },
    )
    const supabase = asSupabaseClient(fake)

    const result = await listCompletersForTasks(supabase, [])
    expect(result.size).toBe(0)
  })

  it('has no key for a task with no completers', async () => {
    const fake = new FakeSupabaseClient({ task_completers: [] })
    const supabase = asSupabaseClient(fake)

    const byTask = await listCompletersForTasks(supabase, ['task-1'])
    expect(byTask.has('task-1')).toBe(false)
  })
})

// A round-trip guard that mixed member+name sets survive save→load unchanged.
describe('setTaskCompleters + listCompletersForTasks round-trip', () => {
  it('preserves a mixed member+name set', async () => {
    const fake = new FakeSupabaseClient({ task_completers: [] })
    const supabase = asSupabaseClient(fake)

    const completers: TaskCompleter[] = [
      { user_id: ACTOR, completer_name: null },
      { user_id: null, completer_name: 'Kaleb' },
      { user_id: null, completer_name: 'Gerald' },
    ]
    await setTaskCompleters(supabase, { taskId: 'task-1', completers })

    const loaded = (await listCompletersForTasks(supabase, ['task-1'])).get(
      'task-1',
    )!
    expect(loaded).toHaveLength(3)
    expect(loaded.filter((c) => c.user_id !== null)).toEqual([
      { user_id: ACTOR, completer_name: null },
    ])
    expect(
      loaded
        .filter((c) => c.completer_name !== null)
        .map((c) => c.completer_name)
        .sort(),
    ).toEqual(['Gerald', 'Kaleb'])
  })
})
