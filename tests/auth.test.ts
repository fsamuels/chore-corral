import { describe, expect, it } from 'vitest'
import { getActorUserId } from '../app/utils/auth'

describe('getActorUserId', () => {
  it('reads the id from the JWT payload sub claim', () => {
    expect(getActorUserId({ sub: 'user-123' })).toBe('user-123')
  })

  it('returns undefined when there is no signed-in user', () => {
    expect(getActorUserId(null)).toBeUndefined()
    expect(getActorUserId(undefined)).toBeUndefined()
  })

  it('ignores a decoy `id` field — Supabase JWT payloads only have `sub`', () => {
    // Regression guard: useTasks.ts/useCategories.ts used to read
    // `user.value?.id`, which doesn't exist on the decoded JWT payload
    // returned by useSupabaseUser() and was always undefined at runtime,
    // silently breaking every create/update/delete for a signed-in user.
    const jwtPayload = { sub: 'user-123', id: undefined } as {
      sub?: string
      id?: string
    }
    expect(getActorUserId(jwtPayload)).toBe('user-123')
  })
})
