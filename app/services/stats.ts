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

export type AppStats =
  Database['public']['Functions']['get_app_stats']['Returns'][number]

/**
 * App-wide totals for the About page (farms, accounts, chores, photos, …),
 * via the `get_app_stats` security-definer function. Aggregates only — no
 * row data — and granted to `authenticated` only (see DATA_MODEL.md).
 */
export async function getAppStats(supabase: Client): Promise<AppStats | null> {
  const { data, error } = await supabase.rpc('get_app_stats')
  if (error) throw new Error(error.message)
  return data?.[0] ?? null
}
