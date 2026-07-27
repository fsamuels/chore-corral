import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

type Client = SupabaseClient<Database>

/**
 * Aggregate task count across every farm, via the `get_public_task_count`
 * security-definer function — the only RPC granted to `anon`, since it
 * returns a single integer and never row data (see DATA_MODEL.md). Callable
 * before sign-in, so the login page can show it as a stat.
 */
export async function getPublicTaskCount(supabase: Client): Promise<number> {
  const { data, error } = await supabase.rpc('get_public_task_count')
  if (error) throw new Error(error.message)
  return data
}
