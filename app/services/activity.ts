import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

export type ActivityEventType =
  | 'task_created'
  | 'task_status_changed'
  | 'task_priority_changed'
  | 'task_due_date_changed'
  | 'task_deleted'
  | 'category_created'
  | 'category_deleted'

export interface ActivityEntry {
  id: string
  event_type: ActivityEventType
  event_detail: Record<string, unknown>
  actor_email: string | null
  created_at: string
}

type Client = SupabaseClient<Database>

/**
 * A task's activity_log entries, most-recent-first (matches the
 * `activity_log_farm_id_created_at_idx` index shape), each attributed to
 * the actor's email where resolvable.
 *
 * Two sequential queries, not a join — this codebase's Supabase usage
 * doesn't do embedded-resource joins anywhere else, and the test fake has
 * no join support. The email lookup is best-effort: an actor whose
 * `farm_member_profiles` row can't be found (e.g. a since-removed member)
 * renders with `actor_email: null` rather than failing the whole page.
 */
export async function listActivityForTask(
  supabase: Client,
  opts: { farmId: string; taskId: string },
): Promise<ActivityEntry[]> {
  const { data, error } = await supabase
    .from('activity_log')
    .select('id, event_type, event_detail, actor_user_id, created_at')
    .eq('farm_id', opts.farmId)
    .eq('task_id', opts.taskId)
    .order('created_at', { ascending: false })
  if (error) throw new Error(error.message)

  const actorIds = [...new Set(data.map((entry) => entry.actor_user_id))]
  const emailByUserId = new Map<string, string | null>()
  if (actorIds.length > 0) {
    const { data: profiles, error: profilesError } = await supabase
      .from('farm_member_profiles')
      .select('user_id, email')
      .eq('farm_id', opts.farmId)
      .in('user_id', actorIds)
    if (profilesError) throw new Error(profilesError.message)
    for (const profile of profiles) {
      emailByUserId.set(profile.user_id, profile.email)
    }
  }

  return data.map((entry) => ({
    id: entry.id,
    event_type: entry.event_type as ActivityEventType,
    event_detail: entry.event_detail as Record<string, unknown>,
    actor_email: emailByUserId.get(entry.actor_user_id) ?? null,
    created_at: entry.created_at,
  }))
}
