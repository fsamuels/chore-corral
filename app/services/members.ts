import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

export interface FarmMemberProfile {
  user_id: string
  email: string | null
}

type Client = SupabaseClient<Database>

/**
 * A farm's members (user id + email), ordered by email — the source list for
 * the task "Completed by" member picker. `farm_member_profiles` exposes only
 * `user_id` and `email` (there's no display-name concept in the schema), so
 * that's all this returns. Throws on error like the other services.
 */
export async function listFarmMemberProfiles(
  supabase: Client,
  farmId: string,
): Promise<FarmMemberProfile[]> {
  const { data, error } = await supabase
    .from('farm_member_profiles')
    .select('user_id, email')
    .eq('farm_id', farmId)
    .order('email')
  if (error) throw new Error(error.message)
  return data
}
