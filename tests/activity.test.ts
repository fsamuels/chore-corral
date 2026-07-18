import { describe, expect, it } from 'vitest'
import { listActivityForTask } from '../app/services/activity'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type ActivityLogRow = Database['public']['Tables']['activity_log']['Row']
type ProfileRow = Database['public']['Views']['farm_member_profiles']['Row']

const FARM_A = 'farm-a'
const FARM_B = 'farm-b'
const TASK_A = 'task-a'
const ACTOR = 'user-1'

function entry(overrides: Partial<ActivityLogRow> = {}): ActivityLogRow {
  return {
    id: 'entry-seed',
    farm_id: FARM_A,
    task_id: TASK_A,
    event_type: 'task_created',
    event_detail: { task_title: 'Fix the gate' },
    actor_user_id: ACTOR,
    created_at: '2026-01-01T00:00:00.000Z',
    ...overrides,
  }
}

function profile(overrides: Partial<ProfileRow> = {}): ProfileRow {
  return {
    farm_id: FARM_A,
    user_id: ACTOR,
    email: 'forrest@example.com',
    display_name: null,
    avatar_url: null,
    ...overrides,
  }
}

describe('listActivityForTask', () => {
  it("returns only the given task and farm's entries", async () => {
    const fake = new FakeSupabaseClient({
      activity_log: [
        entry({ id: 'entry-1', task_id: TASK_A, farm_id: FARM_A }),
        entry({ id: 'entry-2', task_id: 'task-b', farm_id: FARM_A }),
        entry({ id: 'entry-3', task_id: TASK_A, farm_id: FARM_B }),
      ],
      farm_member_profiles: [profile()],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listActivityForTask(supabase, {
      farmId: FARM_A,
      taskId: TASK_A,
    })

    expect(result.map((e) => e.id)).toEqual(['entry-1'])
  })

  it('returns entries most-recent-first', async () => {
    const fake = new FakeSupabaseClient({
      activity_log: [
        entry({
          id: 'entry-old',
          created_at: '2026-01-01T00:00:00.000Z',
        }),
        entry({
          id: 'entry-new',
          created_at: '2026-01-03T00:00:00.000Z',
        }),
        entry({
          id: 'entry-mid',
          created_at: '2026-01-02T00:00:00.000Z',
        }),
      ],
      farm_member_profiles: [profile()],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listActivityForTask(supabase, {
      farmId: FARM_A,
      taskId: TASK_A,
    })

    expect(result.map((e) => e.id)).toEqual([
      'entry-new',
      'entry-mid',
      'entry-old',
    ])
  })

  it("attaches the actor's first name when their profile has a display name", async () => {
    const fake = new FakeSupabaseClient({
      activity_log: [entry({ id: 'entry-1', actor_user_id: ACTOR })],
      farm_member_profiles: [
        profile({ user_id: ACTOR, display_name: 'Forrest Samuels' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listActivityForTask(supabase, {
      farmId: FARM_A,
      taskId: TASK_A,
    })

    expect(result[0]?.actor_label).toBe('Forrest')
  })

  it('disambiguates against the whole farm, not just the entry actors', async () => {
    const fake = new FakeSupabaseClient({
      activity_log: [entry({ id: 'entry-1', actor_user_id: ACTOR })],
      farm_member_profiles: [
        profile({ user_id: ACTOR, display_name: 'Steve Adams' }),
        profile({
          user_id: 'user-2',
          email: 'other-steve@example.com',
          display_name: 'Steve Brown',
        }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listActivityForTask(supabase, {
      farmId: FARM_A,
      taskId: TASK_A,
    })

    expect(result[0]?.actor_label).toBe('Steve A.')
  })

  it("falls back to the actor's email when their profile has no display name", async () => {
    const fake = new FakeSupabaseClient({
      activity_log: [entry({ id: 'entry-1', actor_user_id: ACTOR })],
      farm_member_profiles: [
        profile({ user_id: ACTOR, email: 'forrest@example.com' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listActivityForTask(supabase, {
      farmId: FARM_A,
      taskId: TASK_A,
    })

    expect(result[0]?.actor_label).toBe('forrest@example.com')
  })

  it('falls back to null when the actor has no resolvable profile row', async () => {
    const fake = new FakeSupabaseClient({
      activity_log: [entry({ id: 'entry-1', actor_user_id: 'ghost-user' })],
      farm_member_profiles: [profile({ user_id: ACTOR })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listActivityForTask(supabase, {
      farmId: FARM_A,
      taskId: TASK_A,
    })

    expect(result[0]?.actor_label).toBeNull()
  })

  it('returns [] for a task with no activity', async () => {
    const fake = new FakeSupabaseClient({ activity_log: [] })
    const supabase = asSupabaseClient(fake)

    const result = await listActivityForTask(supabase, {
      farmId: FARM_A,
      taskId: TASK_A,
    })

    expect(result).toEqual([])
  })
})
