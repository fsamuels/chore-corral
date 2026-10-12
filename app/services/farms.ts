import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

type Client = SupabaseClient<Database>

export const FARM_NAME_MAX_LENGTH = 120

/**
 * Create a farm owned by the current user, via the `create_farm`
 * security-definer function (neither `farms` nor `farm_memberships` accepts
 * client-side writes under RLS — see DATA_MODEL.md). Returns the new farm's
 * id. Throws on validation or database errors like the other services.
 */
export async function createFarm(
  supabase: Client,
  name: string,
  address?: string | null,
): Promise<string> {
  const trimmedName = name.trim()
  if (trimmedName.length === 0) {
    throw new Error('Farm name is required.')
  }
  if (trimmedName.length > FARM_NAME_MAX_LENGTH) {
    throw new Error(
      `Farm name must be ${FARM_NAME_MAX_LENGTH} characters or fewer.`,
    )
  }
  const trimmedAddress = address?.trim() ?? ''
  const { data, error } = await supabase.rpc('create_farm', {
    farm_name: trimmedName,
    farm_address: trimmedAddress.length > 0 ? trimmedAddress : null,
  })
  if (error) throw new Error(error.message)
  return data
}

/**
 * A `createFarm` for a form that can be retried: once a call succeeds, later
 * calls return the same farm id instead of creating another. The forms run
 * more steps after creating (refresh the farm list, navigate), and if one of
 * those fails the form becomes submittable again — without this, retrying
 * would insert a duplicate farm.
 */
export function createFarmOnce(supabase: Client) {
  let createdFarmId: string | null = null
  return async (name: string, address?: string | null): Promise<string> => {
    if (createdFarmId === null) {
      createdFarmId = await createFarm(supabase, name, address)
    }
    return createdFarmId
  }
}

/**
 * Join the current user to every farm with a pending invite matching their
 * Google account's email (the `accept_farm_invites` security-definer
 * function does the matching server-side against the caller's confirmed
 * `auth.users` email — nothing here is caller-supplied). Returns the ids of farms joined, usually empty.
 */
export async function acceptPendingInvites(
  supabase: Client,
): Promise<string[]> {
  const { data, error } = await supabase.rpc('accept_farm_invites')
  if (error) throw new Error(error.message)
  return data ?? []
}
