import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

export interface FarmInvite {
  id: string
  email: string
  role: Database['public']['Enums']['farm_role']
  created_at: string
}

type Client = SupabaseClient<Database>

// Deliberately loose — the real validation is Google's (the invitee has to
// sign in with this exact address); this just catches obvious typos before
// they become a silently-never-matching invite.
const EMAIL_SHAPE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

/**
 * Normalize an invite email the same way `accept_farm_invites()` normalizes
 * the JWT email (trim + lowercase), so acceptance is a plain equality match.
 * Throws on anything that doesn't look like an email address.
 */
export function normalizeInviteEmail(email: string): string {
  const normalized = email.trim().toLowerCase()
  if (!EMAIL_SHAPE.test(normalized)) {
    throw new Error(`"${email.trim()}" doesn't look like an email address.`)
  }
  return normalized
}

/** A farm's pending (not yet accepted) invites, oldest first. */
export async function listPendingInvites(
  supabase: Client,
  farmId: string,
): Promise<FarmInvite[]> {
  const { data, error } = await supabase
    .from('farm_invites')
    .select('id, email, role, created_at')
    .eq('farm_id', farmId)
    .is('accepted_at', null)
    .order('created_at')
  if (error) throw new Error(error.message)
  return data
}

/**
 * Invite an email address to a farm. Whoever signs in with Google using this
 * address is auto-joined on their next session (no email is sent). RLS
 * restricts this to owners of the farm; a duplicate pending invite for the
 * same address fails on the partial unique index with a Postgres error.
 */
export async function createInvite(
  supabase: Client,
  farmId: string,
  email: string,
  invitedBy: string,
): Promise<FarmInvite> {
  const normalized = normalizeInviteEmail(email)
  const { data, error } = await supabase
    .from('farm_invites')
    .insert({
      farm_id: farmId,
      email: normalized,
      // Everyone invited joins as a plain member; farm creation is the only
      // path to ownership for now.
      role: 'member',
      invited_by: invitedBy,
    })
    .select('id, email, role, created_at')
    .single()
  if (error) throw new Error(error.message)
  return data
}

/**
 * Revoke a pending invite. The `accepted_at` filter (and the matching RLS
 * policy) keeps accepted invites as history — revocation only makes sense
 * before the invitee has signed in.
 */
export async function revokeInvite(
  supabase: Client,
  inviteId: string,
): Promise<void> {
  const { error } = await supabase
    .from('farm_invites')
    .delete()
    .eq('id', inviteId)
    .is('accepted_at', null)
  if (error) throw new Error(error.message)
}
