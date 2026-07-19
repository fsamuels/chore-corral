import { describe, expect, it } from 'vitest'
import {
  removePushSubscription,
  savePushSubscription,
} from '../app/services/push'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type PushSubscriptionRow =
  Database['public']['Tables']['push_subscriptions']['Row']

const USER = 'user-1'
const OTHER = 'user-2'

function subscription(
  overrides: Partial<PushSubscriptionRow> = {},
): PushSubscriptionRow {
  return {
    id: 'sub-seed',
    user_id: USER,
    endpoint: 'https://push.example.com/abc',
    p256dh: 'p256dh-key',
    auth: 'auth-secret',
    created_at: '2026-07-18T10:00:00Z',
    ...overrides,
  }
}

describe('savePushSubscription', () => {
  it('inserts a new subscription', async () => {
    const fake = new FakeSupabaseClient({ push_subscriptions: [] })
    const supabase = asSupabaseClient(fake)

    await savePushSubscription(supabase, {
      userId: USER,
      endpoint: 'https://push.example.com/new',
      p256dh: 'key',
      auth: 'secret',
    })

    const rows = fake.getTable('push_subscriptions') as PushSubscriptionRow[]
    expect(rows).toHaveLength(1)
    expect(rows[0]).toMatchObject({
      user_id: USER,
      endpoint: 'https://push.example.com/new',
      p256dh: 'key',
      auth: 'secret',
    })
  })

  it('upserts on a matching endpoint instead of duplicating', async () => {
    const fake = new FakeSupabaseClient({
      push_subscriptions: [subscription({ id: 'existing' })],
    })
    const supabase = asSupabaseClient(fake)

    await savePushSubscription(supabase, {
      userId: USER,
      endpoint: subscription().endpoint,
      p256dh: 'rotated-key',
      auth: 'rotated-secret',
    })

    const rows = fake.getTable('push_subscriptions') as PushSubscriptionRow[]
    expect(rows).toHaveLength(1)
    expect(rows[0]!.id).toBe('existing')
    expect(rows[0]!.p256dh).toBe('rotated-key')
    expect(rows[0]!.auth).toBe('rotated-secret')
  })

  it('leaves other users’ subscriptions untouched', async () => {
    const fake = new FakeSupabaseClient({
      push_subscriptions: [
        subscription({
          id: 'other',
          user_id: OTHER,
          endpoint: 'https://push.example.com/other',
        }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    await savePushSubscription(supabase, {
      userId: USER,
      endpoint: 'https://push.example.com/mine',
      p256dh: 'key',
      auth: 'secret',
    })

    const rows = fake.getTable('push_subscriptions') as PushSubscriptionRow[]
    expect(rows).toHaveLength(2)
    expect(rows.some((r) => r.user_id === OTHER)).toBe(true)
  })

  it('throws a readable message on an injected upsert failure', async () => {
    const fake = new FakeSupabaseClient(
      { push_subscriptions: [] },
      { table: 'push_subscriptions', op: 'upsert', message: 'upsert boom' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      savePushSubscription(supabase, {
        userId: USER,
        endpoint: 'https://push.example.com/new',
        p256dh: 'key',
        auth: 'secret',
      }),
    ).rejects.toThrow('Could not save notification subscription.')
  })
})

describe('removePushSubscription', () => {
  it('deletes the subscription by endpoint', async () => {
    const fake = new FakeSupabaseClient({
      push_subscriptions: [
        subscription({ id: 'keep', endpoint: 'https://push.example.com/keep' }),
        subscription({ id: 'gone', endpoint: 'https://push.example.com/gone' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    await removePushSubscription(supabase, 'https://push.example.com/gone')

    const rows = fake.getTable('push_subscriptions') as PushSubscriptionRow[]
    expect(rows.map((r) => r.id)).toEqual(['keep'])
  })

  it('throws a readable message on an injected delete failure', async () => {
    const fake = new FakeSupabaseClient(
      { push_subscriptions: [subscription()] },
      { table: 'push_subscriptions', op: 'delete', message: 'delete boom' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      removePushSubscription(supabase, subscription().endpoint),
    ).rejects.toThrow('Could not remove notification subscription.')
  })
})
