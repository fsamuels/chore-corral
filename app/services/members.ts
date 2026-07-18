import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

export interface FarmMemberProfile {
  user_id: string
  email: string | null
  display_name: string | null
  role: Database['public']['Enums']['farm_role']
}

type Client = SupabaseClient<Database>

/**
 * A farm's members (user id + email + display name + role), ordered by
 * email — the source list for the task "Completed by" member picker and the
 * members page. `display_name` comes from the member's Google profile via
 * `farm_member_profiles` (refreshed on each sign-in), nullable; label
 * rendering (name-first, email fallback, first-name disambiguation) lives
 * in `app/utils/member-display.ts`. Throws on error like the other
 * services.
 */
export async function listFarmMemberProfiles(
  supabase: Client,
  farmId: string,
): Promise<FarmMemberProfile[]> {
  const { data, error } = await supabase
    .from('farm_member_profiles')
    .select('user_id, email, display_name, role')
    .eq('farm_id', farmId)
    .order('email')
  if (error) throw new Error(error.message)
  return data
}
