import { describe, expect, it } from 'vitest'
import {
  getActorUserId,
  getUserAvatarUrl,
  getUserDisplayName,
} from '../app/utils/auth'

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

describe('getUserDisplayName', () => {
  it('prefers full_name over name', () => {
    expect(
      getUserDisplayName({
        user_metadata: { full_name: 'Forrest Samuels', name: 'Forrest' },
      }),
    ).toBe('Forrest Samuels')
  })

  it('falls back to name and trims whitespace', () => {
    expect(getUserDisplayName({ user_metadata: { name: '  Forrest  ' } })).toBe(
      'Forrest',
    )
  })

  it('treats blank values as missing', () => {
    expect(
      getUserDisplayName({ user_metadata: { full_name: '   ', name: '' } }),
    ).toBeNull()
  })

  it('returns null for a missing user or metadata claim', () => {
    expect(getUserDisplayName(null)).toBeNull()
    expect(getUserDisplayName({})).toBeNull()
  })

  it('ignores non-string metadata values', () => {
    expect(
      getUserDisplayName({ user_metadata: { full_name: 42 as unknown } }),
    ).toBeNull()
  })
})

describe('getUserAvatarUrl', () => {
  it('prefers avatar_url over picture', () => {
    expect(
      getUserAvatarUrl({
        user_metadata: {
          avatar_url: 'https://example.com/a.png',
          picture: 'https://example.com/p.png',
        },
      }),
    ).toBe('https://example.com/a.png')
  })

  it('falls back to picture', () => {
    expect(
      getUserAvatarUrl({
        user_metadata: { picture: 'https://example.com/p.png' },
      }),
    ).toBe('https://example.com/p.png')
  })

  it('returns null for a missing user, metadata claim, or blank values', () => {
    expect(getUserAvatarUrl(null)).toBeNull()
    expect(getUserAvatarUrl({})).toBeNull()
    expect(getUserAvatarUrl({ user_metadata: { avatar_url: '  ' } })).toBeNull()
  })
})
