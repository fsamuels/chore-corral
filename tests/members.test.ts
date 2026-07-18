import { describe, expect, it } from 'vitest'
import { listFarmMemberProfiles } from '../app/services/members'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type ProfileRow = Database['public']['Views']['farm_member_profiles']['Row']

const FARM_A = 'farm-a'
const FARM_B = 'farm-b'

function profile(overrides: Partial<ProfileRow> = {}): ProfileRow {
  return {
    farm_id: FARM_A,
    user_id: 'user-1',
    email: 'forrest@example.com',
    display_name: null,
    role: 'member',
    ...overrides,
  }
}

describe('listFarmMemberProfiles', () => {
  it("returns only the given farm's members, ordered by email", async () => {
    const fake = new FakeSupabaseClient({
      farm_member_profiles: [
        profile({ user_id: 'user-1', email: 'zoe@example.com' }),
        profile({ user_id: 'user-2', email: 'amy@example.com' }),
        profile({ user_id: 'user-3', email: 'nolan@example.com' }),
        profile({
          user_id: 'user-9',
          email: 'other@example.com',
          farm_id: FARM_B,
        }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listFarmMemberProfiles(supabase, FARM_A)

    expect(result.map((m) => m.email)).toEqual([
      'amy@example.com',
      'nolan@example.com',
      'zoe@example.com',
    ])
  })

  it('returns an empty list for a farm with no members', async () => {
    const fake = new FakeSupabaseClient({ farm_member_profiles: [] })
    const supabase = asSupabaseClient(fake)

    const result = await listFarmMemberProfiles(supabase, FARM_A)

    expect(result).toEqual([])
  })
})
