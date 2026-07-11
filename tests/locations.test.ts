import { describe, expect, it } from 'vitest'
import { listLocationsWithCounts } from '../app/services/locations'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type LocationRow = Database['public']['Tables']['locations']['Row']
type TaskRow = Database['public']['Tables']['tasks']['Row']

const FARM_A = 'farm-a'
const FARM_B = 'farm-b'

function location(overrides: Partial<LocationRow> = {}): LocationRow {
  return {
    id: 'loc-seed',
    farm_id: FARM_A,
    name: 'North Pasture',
    lat: 40.1,
    lng: -75.2,
    deleted_at: null,
    created_at: '2026-01-01T00:00:00.000Z',
    ...overrides,
  }
}

function task(overrides: Partial<TaskRow> = {}): TaskRow {
  return {
    id: 'task-seed',
    farm_id: FARM_A,
    title: 'Fix the gate',
    category_id: null,
    priority: 'soon',
    status: 'not_started',
    due_date: null,
    notes: null,
    lat: null,
    lng: null,
    location_id: 'loc-seed',
    created_at: '2026-01-01T00:00:00.000Z',
    created_by: 'user-1',
    completed_at: null,
    estimated_minutes: null,
    ...overrides,
  }
}

const ZERO_COUNTS = { not_started: 0, in_progress: 0, done: 0 }

describe('listLocationsWithCounts', () => {
  it('returns an empty array when the farm has no locations', async () => {
    const fake = new FakeSupabaseClient({ locations: [], tasks: [] })
    const supabase = asSupabaseClient(fake)

    const result = await listLocationsWithCounts(supabase, FARM_A)

    expect(result).toEqual([])
  })

  it('gives a location with no tasks a count of zero', async () => {
    const fake = new FakeSupabaseClient({
      locations: [
        location({ id: 'loc-1', farm_id: FARM_A, name: 'North Pasture' }),
      ],
      tasks: [],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listLocationsWithCounts(supabase, FARM_A)

    expect(result).toEqual([
      {
        id: 'loc-1',
        name: 'North Pasture',
        lat: 40.1,
        lng: -75.2,
        created_at: location().created_at,
        taskCount: 0,
        statusCounts: ZERO_COUNTS,
      },
    ])
  })

  it('counts tasks per location independently, broken down by status, sorted by name', async () => {
    const fake = new FakeSupabaseClient({
      locations: [
        location({ id: 'loc-1', farm_id: FARM_A, name: 'South Barn' }),
        location({ id: 'loc-2', farm_id: FARM_A, name: 'North Pasture' }),
      ],
      tasks: [
        task({ id: 'task-1', location_id: 'loc-1', status: 'not_started' }),
        task({ id: 'task-2', location_id: 'loc-1', status: 'done' }),
        task({ id: 'task-3', location_id: 'loc-2', status: 'in_progress' }),
        task({ id: 'task-4', location_id: null, status: 'not_started' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listLocationsWithCounts(supabase, FARM_A)

    expect(result).toEqual([
      {
        id: 'loc-2',
        name: 'North Pasture',
        lat: 40.1,
        lng: -75.2,
        created_at: location().created_at,
        taskCount: 1,
        statusCounts: { not_started: 0, in_progress: 1, done: 0 },
      },
      {
        id: 'loc-1',
        name: 'South Barn',
        lat: 40.1,
        lng: -75.2,
        created_at: location().created_at,
        taskCount: 2,
        statusCounts: { not_started: 1, in_progress: 0, done: 1 },
      },
    ])
  })

  it("does not count another farm's tasks", async () => {
    const fake = new FakeSupabaseClient({
      locations: [
        location({ id: 'loc-1', farm_id: FARM_A, name: 'South Barn' }),
        location({ id: 'loc-2', farm_id: FARM_B, name: 'Other Farm Barn' }),
      ],
      tasks: [
        task({
          id: 'task-1',
          farm_id: FARM_A,
          location_id: 'loc-1',
          status: 'not_started',
        }),
        task({
          id: 'task-2',
          farm_id: FARM_B,
          location_id: 'loc-2',
          status: 'not_started',
        }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listLocationsWithCounts(supabase, FARM_A)

    expect(result).toEqual([
      {
        id: 'loc-1',
        name: 'South Barn',
        lat: 40.1,
        lng: -75.2,
        created_at: location().created_at,
        taskCount: 1,
        statusCounts: { not_started: 1, in_progress: 0, done: 0 },
      },
    ])
  })
})
