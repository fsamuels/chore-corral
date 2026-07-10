import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'
import { ACTIVE_TASK_STATUSES } from './categories'

export interface LocationSummary {
  id: string
  name: string
  lat: number
  lng: number
  created_at: string
}

export type DeleteLocationResult =
  | { deleted: true }
  | { deleted: false; reason: 'active_tasks'; activeTaskCount: number }

type Client = SupabaseClient<Database>

/**
 * Validate a defined location's coordinates. Unlike a task's optional pin
 * (`assertValidLocation` in services/tasks.ts, where both-or-neither is
 * allowed), a defined location always has a point — both are required — and
 * each must be a finite number within range. `0` is a legitimate coordinate,
 * so this checks types/ranges, not falsiness.
 */
export function assertValidCoordinates(lat: number, lng: number): void {
  if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
    throw new Error('Location lat must be a number between -90 and 90')
  }
  if (!Number.isFinite(lng) || lng < -180 || lng > 180) {
    throw new Error('Location lng must be a number between -180 and 180')
  }
}

/** Active (non-soft-deleted) locations for one farm, sorted by name. */
export async function listLocations(
  supabase: Client,
  farmId: string,
): Promise<LocationSummary[]> {
  const { data, error } = await supabase
    .from('locations')
    .select('id, name, lat, lng, created_at')
    .eq('farm_id', farmId)
    .is('deleted_at', null)
    .order('name')
  if (error) throw new Error(error.message)
  return data
}

/**
 * Create a location and log a `location_created` event.
 *
 * Like the categories service, the two inserts are sequential, not
 * transactional (supabase-js has no client-side transactions): if the log
 * insert fails the location still exists and the thrown error surfaces the
 * partial failure. Acceptable for MVP; an RPC wrapping both in one
 * transaction is the upgrade path.
 */
export async function createLocation(
  supabase: Client,
  opts: {
    farmId: string
    name: string
    lat: number
    lng: number
    actorUserId: string
  },
): Promise<LocationSummary> {
  const name = opts.name.trim()
  if (!name) throw new Error('Location name is required')
  assertValidCoordinates(opts.lat, opts.lng)

  const { data, error } = await supabase
    .from('locations')
    .insert({ farm_id: opts.farmId, name, lat: opts.lat, lng: opts.lng })
    .select('id, name, lat, lng, created_at')
    .single()
  if (error) throw new Error(error.message)

  await logLocationEvent(supabase, 'location_created', data, opts)
  return data
}

/**
 * Edit a location's name and/or coordinates. Not logged (field edits, like a
 * task's, are not major events).
 */
export async function updateLocation(
  supabase: Client,
  opts: {
    farmId: string
    locationId: string
    name: string
    lat: number
    lng: number
  },
): Promise<LocationSummary> {
  const name = opts.name.trim()
  if (!name) throw new Error('Location name is required')
  assertValidCoordinates(opts.lat, opts.lng)

  const { data, error } = await supabase
    .from('locations')
    .update({ name, lat: opts.lat, lng: opts.lng })
    .eq('id', opts.locationId)
    .eq('farm_id', opts.farmId)
    .is('deleted_at', null)
    .select('id, name, lat, lng, created_at')
  if (error) throw new Error(error.message)
  const location = data[0]
  if (!location) throw new Error('Location not found or already deleted')
  return location
}

/**
 * Soft-delete a location, unless any active task still references it — the
 * check and the update are two statements, so a concurrent task creation can
 * slip between them; fine at this app's scale (mirrors deleteCategory). Logs
 * a `location_deleted` event on success.
 */
export async function deleteLocation(
  supabase: Client,
  opts: { farmId: string; locationId: string; actorUserId: string },
): Promise<DeleteLocationResult> {
  const { count, error: countError } = await supabase
    .from('tasks')
    .select('id', { count: 'exact', head: true })
    .eq('farm_id', opts.farmId)
    .eq('location_id', opts.locationId)
    .in('status', [...ACTIVE_TASK_STATUSES])
  if (countError) throw new Error(countError.message)
  if (count !== null && count > 0) {
    return { deleted: false, reason: 'active_tasks', activeTaskCount: count }
  }

  const { data, error } = await supabase
    .from('locations')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', opts.locationId)
    .eq('farm_id', opts.farmId)
    .is('deleted_at', null)
    .select('id, name')
  if (error) throw new Error(error.message)
  const location = data[0]
  if (!location) throw new Error('Location not found or already deleted')

  await logLocationEvent(supabase, 'location_deleted', location, opts)
  return { deleted: true }
}

// event_detail snapshots the location name (the location analog of the
// task_title / category_name snapshot) so log entries stay readable without
// joining back to a possibly-soft-deleted row.
async function logLocationEvent(
  supabase: Client,
  eventType: 'location_created' | 'location_deleted',
  location: { id: string; name: string },
  opts: { farmId: string; actorUserId: string },
): Promise<void> {
  const { error } = await supabase.from('activity_log').insert({
    farm_id: opts.farmId,
    task_id: null,
    event_type: eventType,
    event_detail: { location_id: location.id, location_name: location.name },
    actor_user_id: opts.actorUserId,
  })
  if (error) throw new Error(error.message)
}
