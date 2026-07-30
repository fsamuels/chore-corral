import { describe, expect, it } from 'vitest'
import {
  assertValidAssignees,
  listAssigneesForTasks,
  setTaskAssignees,
} from '../app/services/assignees'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type TaskAssigneeRow = Database['public']['Tables']['task_assignees']['Row']

const ACTOR = 'user-1'
const OTHER = 'user-2'

function assignee(overrides: Partial<TaskAssigneeRow> = {}): TaskAssigneeRow {
  return {
    task_id: 'task-1',
    user_id: ACTOR,
    ...overrides,
  }
}

describe('assertValidAssignees', () => {
  it('accepts an empty set and a set of distinct members', () => {
    expect(() => assertValidAssignees([])).not.toThrow()
    expect(() => assertValidAssignees([ACTOR])).not.toThrow()
    expect(() => assertValidAssignees([ACTOR, OTHER])).not.toThrow()
  })

  it('rejects a duplicate member', () => {
    expect(() => assertValidAssignees([ACTOR, ACTOR])).toThrow(
      'A chore cannot list the same assignee twice',
    )
  })
})

describe('setTaskAssignees', () => {
  it('replaces the full set: clears old rows and inserts the new ones', async () => {
    const fake = new FakeSupabaseClient({
      task_assignees: [assignee({ task_id: 'task-1', user_id: OTHER })],
    })
    const supabase = asSupabaseClient(fake)

    await setTaskAssignees(supabase, {
      taskId: 'task-1',
      userIds: [ACTOR],
    })

    const rows = fake
      .getTable('task_assignees')
      .filter((r) => (r as TaskAssigneeRow).task_id === 'task-1')
    expect(rows).toHaveLength(1)
    expect((rows[0] as TaskAssigneeRow).user_id).toBe(ACTOR)
  })

  it('empties the set (delete-all, no insert) — assigned to nobody', async () => {
    const fake = new FakeSupabaseClient({
      task_assignees: [assignee({ task_id: 'task-1', user_id: ACTOR })],
    })
    const supabase = asSupabaseClient(fake)

    await setTaskAssignees(supabase, { taskId: 'task-1', userIds: [] })

    expect(
      fake
        .getTable('task_assignees')
        .filter((r) => (r as TaskAssigneeRow).task_id === 'task-1'),
    ).toHaveLength(0)
  })

  it('only touches the target task, leaving another task’s assignees intact', async () => {
    const fake = new FakeSupabaseClient({
      task_assignees: [assignee({ task_id: 'task-2', user_id: OTHER })],
    })
    const supabase = asSupabaseClient(fake)

    await setTaskAssignees(supabase, {
      taskId: 'task-1',
      userIds: [ACTOR],
    })

    expect(
      fake
        .getTable('task_assignees')
        .filter((r) => (r as TaskAssigneeRow).task_id === 'task-2'),
    ).toHaveLength(1)
  })

  it('rejects a duplicate member without writing anything', async () => {
    const fake = new FakeSupabaseClient({ task_assignees: [] })
    const supabase = asSupabaseClient(fake)

    await expect(
      setTaskAssignees(supabase, {
        taskId: 'task-1',
        userIds: [ACTOR, ACTOR],
      }),
    ).rejects.toThrow('A chore cannot list the same assignee twice')

    expect(fake.getTable('task_assignees')).toHaveLength(0)
  })

  it('propagates an injected insert failure', async () => {
    const fake = new FakeSupabaseClient(
      { task_assignees: [] },
      { table: 'task_assignees', op: 'insert', message: 'insert boom' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      setTaskAssignees(supabase, { taskId: 'task-1', userIds: [ACTOR] }),
    ).rejects.toThrow('insert boom')
  })
})

describe('listAssigneesForTasks', () => {
  it('keys assignee ids by task id, sorted', async () => {
    const fake = new FakeSupabaseClient({
      task_assignees: [
        assignee({ task_id: 'task-1', user_id: OTHER }),
        assignee({ task_id: 'task-1', user_id: ACTOR }),
        assignee({ task_id: 'task-2', user_id: OTHER }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const byTask = await listAssigneesForTasks(supabase, ['task-1', 'task-2'])

    expect(byTask.get('task-1')).toEqual([ACTOR, OTHER])
    expect(byTask.get('task-2')).toEqual([OTHER])
  })

  it('returns an empty map for no task ids, without querying', async () => {
    const fake = new FakeSupabaseClient(
      { task_assignees: [assignee()] },
      { table: 'task_assignees', op: 'select', message: 'should not run' },
    )
    const supabase = asSupabaseClient(fake)

    const result = await listAssigneesForTasks(supabase, [])
    expect(result.size).toBe(0)
  })

  it('has no key for a task with no assignees', async () => {
    const fake = new FakeSupabaseClient({ task_assignees: [] })
    const supabase = asSupabaseClient(fake)

    const byTask = await listAssigneesForTasks(supabase, ['task-1'])
    expect(byTask.has('task-1')).toBe(false)
  })
})

describe('setTaskAssignees + listAssigneesForTasks round-trip', () => {
  it('preserves a multi-member set', async () => {
    const fake = new FakeSupabaseClient({ task_assignees: [] })
    const supabase = asSupabaseClient(fake)

    await setTaskAssignees(supabase, {
      taskId: 'task-1',
      userIds: [ACTOR, OTHER],
    })

    const loaded = (await listAssigneesForTasks(supabase, ['task-1'])).get(
      'task-1',
    )!
    expect(loaded).toEqual([ACTOR, OTHER])
  })
})
