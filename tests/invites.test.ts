import { describe, expect, it } from 'vitest'
import {
  createInvite,
  listPendingInvites,
  normalizeInviteEmail,
  revokeInvite,
} from '../app/services/invites'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type InviteRow = Database['public']['Tables']['farm_invites']['Row']

const FARM_A = 'farm-a'
const FARM_B = 'farm-b'

function invite(overrides: Partial<InviteRow> = {}): InviteRow {
  return {
    id: 'invite-1',
    farm_id: FARM_A,
    email: 'partner@example.com',
    role: 'member',
    invited_by: 'user-1',
    created_at: '2026-07-18T10:00:00Z',
    accepted_at: null,
    accepted_by: null,
    ...overrides,
  }
}

describe('normalizeInviteEmail', () => {
  it('trims and lowercases', () => {
    expect(normalizeInviteEmail('  Partner@Gmail.COM  ')).toBe(
      'partner@gmail.com',
    )
  })

  it('rejects strings that do not look like an email address', () => {
    for (const bad of [
      '',
      '   ',
      'partner',
      'partner@',
      '@gmail.com',
      'a b@c.d',
      'a@b',
    ]) {
      expect(() => normalizeInviteEmail(bad)).toThrow(
        "doesn't look like an email address",
      )
    }
  })
})

describe('listPendingInvites', () => {
  it('returns only the given farm’s pending invites, oldest first', async () => {
    const fake = new FakeSupabaseClient({
      farm_invites: [
        invite({
          id: 'invite-2',
          email: 'second@example.com',
          created_at: '2026-07-18T12:00:00Z',
        }),
        invite({ id: 'invite-1', email: 'first@example.com' }),
        invite({
          id: 'invite-3',
          email: 'done@example.com',
          accepted_at: '2026-07-18T11:00:00Z',
          accepted_by: 'user-2',
        }),
        invite({ id: 'invite-4', farm_id: FARM_B }),
      ],
    })

    const result = await listPendingInvites(asSupabaseClient(fake), FARM_A)

    expect(result.map((i) => i.email)).toEqual([
      'first@example.com',
      'second@example.com',
    ])
  })
})

describe('createInvite', () => {
  it('inserts a normalized member invite and returns it', async () => {
    const fake = new FakeSupabaseClient()

    const result = await createInvite(
      asSupabaseClient(fake),
      FARM_A,
      '  Partner@Gmail.com ',
      'user-1',
    )

    expect(result.email).toBe('partner@gmail.com')
    expect(result.role).toBe('member')
    expect(fake.getTable('farm_invites')).toMatchObject([
      {
        farm_id: FARM_A,
        email: 'partner@gmail.com',
        role: 'member',
        invited_by: 'user-1',
      },
    ])
  })

  it('rejects an invalid email without touching the database', async () => {
    const fake = new FakeSupabaseClient()

    await expect(
      createInvite(asSupabaseClient(fake), FARM_A, 'not-an-email', 'user-1'),
    ).rejects.toThrow("doesn't look like an email address")
    expect(fake.getTable('farm_invites')).toEqual([])
  })

  it('surfaces insert errors (e.g. duplicate pending invite)', async () => {
    const fake = new FakeSupabaseClient(
      {},
      {
        table: 'farm_invites',
        op: 'insert',
        message: 'duplicate key value violates unique constraint',
      },
    )

    await expect(
      createInvite(
        asSupabaseClient(fake),
        FARM_A,
        'partner@example.com',
        'user-1',
      ),
    ).rejects.toThrow('duplicate key')
  })
})

describe('revokeInvite', () => {
  it('deletes a pending invite', async () => {
    const fake = new FakeSupabaseClient({
      farm_invites: [invite({ id: 'invite-1' }), invite({ id: 'invite-2' })],
    })

    await revokeInvite(asSupabaseClient(fake), 'invite-1')

    expect(fake.getTable('farm_invites').map((r) => r.id)).toEqual(['invite-2'])
  })

  it('leaves an already-accepted invite alone', async () => {
    const fake = new FakeSupabaseClient({
      farm_invites: [
        invite({
          id: 'invite-1',
          accepted_at: '2026-07-18T11:00:00Z',
          accepted_by: 'user-2',
        }),
      ],
    })

    await revokeInvite(asSupabaseClient(fake), 'invite-1')

    expect(fake.getTable('farm_invites')).toHaveLength(1)
  })

  it('surfaces delete errors', async () => {
    const fake = new FakeSupabaseClient(
      { farm_invites: [invite()] },
      { table: 'farm_invites', op: 'delete' },
    )

    await expect(
      revokeInvite(asSupabaseClient(fake), 'invite-1'),
    ).rejects.toThrow('Simulated delete error on farm_invites')
  })
})
