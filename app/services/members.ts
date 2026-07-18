import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

export interface FarmMemberProfile {
  user_id: string
  email: string | null
  role: Database['public']['Enums']['farm_role']
}

type Client = SupabaseClient<Database>

/**
 * A farm's members (user id + email + role), ordered by email — the source
 * list for the task "Completed by" member picker and the members page.
 * `farm_member_profiles` exposes only these columns (there's no display-name
 * concept in the schema). Throws on error like the other services.
 */
export async function listFarmMemberProfiles(
  supabase: Client,
  farmId: string,
): Promise<FarmMemberProfile[]> {
  const { data, error } = await supabase
    .from('farm_member_profiles')
    .select('user_id, email, role')
    .eq('farm_id', farmId)
    .order('email')
  if (error) throw new Error(error.message)
  return data
}
