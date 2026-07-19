import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

type Client = SupabaseClient<Database>

export interface SavePushSubscriptionInput {
  userId: string
  endpoint: string
  p256dh: string
  auth: string
}

/**
 * Save (or refresh) a browser push subscription. `endpoint` is globally
 * unique (see the migration), so re-subscribing on the same device/browser
 * — the same underlying push service registration — upserts the row instead
 * of accumulating a stale duplicate; a device with rotated keys just
 * overwrites `p256dh`/`auth` in place.
 *
 * `userId` is passed in rather than read here via `auth.getUser()`, matching
 * this codebase's actor-id convention (see `changeTaskStatus`'s
 * `actorUserId`, `createInvite`'s `invitedBy`): every write that needs "who
 * did this" takes it as an explicit argument, resolved by the caller via
 * `getActorUserId(useSupabaseUser().value)`.
 */
export async function savePushSubscription(
  supabase: Client,
  input: SavePushSubscriptionInput,
): Promise<void> {
  const { error } = await supabase.from('push_subscriptions').upsert(
    {
      user_id: input.userId,
      endpoint: input.endpoint,
      p256dh: input.p256dh,
      auth: input.auth,
    },
    { onConflict: 'endpoint' },
  )
  if (error) throw new Error('Could not save notification subscription.')
}

/**
 * Remove a push subscription by endpoint (the unique key both here and in
 * the browser's own PushManager) — used when disabling notifications on this
 * device. RLS (owner-only) means this silently matches zero rows for an
 * endpoint that isn't the caller's, same as any other user's row being
 * invisible rather than an authorization error.
 */
export async function removePushSubscription(
  supabase: Client,
  endpoint: string,
): Promise<void> {
  const { error } = await supabase
    .from('push_subscriptions')
    .delete()
    .eq('endpoint', endpoint)
  if (error) throw new Error('Could not remove notification subscription.')
}
