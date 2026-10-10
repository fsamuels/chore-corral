import { describe, expect, it, vi } from 'vitest'
import {
  THUMBNAIL_URL_TTL_SECONDS,
  createTaskThumbnailStore,
} from '../app/utils/task-thumbnails'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type PhotoRow = Database['public']['Tables']['task_photos']['Row']

function photo(taskId: string, id: string): PhotoRow {
  return {
    id,
    task_id: taskId,
    storage_path: `farm/${taskId}/${id}.webp`,
    caption: null,
    taken_at: '2026-01-01T00:00:00.000Z',
  }
}

function setup(photos: PhotoRow[]) {
  const fake = new FakeSupabaseClient({ task_photos: photos })
  const fromSpy = vi.spyOn(fake, 'from')
  const storageSpy = vi.spyOn(fake, 'storage', 'get')
  let clock = 1_000_000
  const store = createTaskThumbnailStore(asSupabaseClient(fake), {
    now: () => clock,
  })
  return {
    fake,
    store,
    fromSpy,
    storageSpy,
    advance(ms: number) {
      clock += ms
    },
  }
}

const A = { id: 'task-a', photo_count: 1 }
const B = { id: 'task-b', photo_count: 2 }

describe('createTaskThumbnailStore', () => {
  it('is undefined (loading) before sync and resolves to a signed URL after', async () => {
    const { store } = setup([photo('task-a', 'p1')])

    expect(store.thumbnailFor(A)).toBeUndefined()
    await store.sync([A])

    expect(store.thumbnailFor(A)).toContain('farm/task-a/p1.webp')
  })

  it('is null for a task with no photos, without querying', async () => {
    const { store, fromSpy } = setup([])
    const none = { id: 'task-x', photo_count: 0 }

    await store.sync([none])

    expect(store.thumbnailFor(none)).toBeNull()
    expect(fromSpy).not.toHaveBeenCalled()
  })

  it('only looks up and signs tasks it has not seen when the list grows', async () => {
    const { store, fromSpy, storageSpy } = setup([
      photo('task-a', 'p1'),
      photo('task-b', 'p2'),
    ])

    await store.sync([A])
    await store.sync([A, B])
    await store.sync([A, B])

    expect(fromSpy).toHaveBeenCalledTimes(2)
    expect(fromSpy.mock.calls.map((c) => c[0])).toEqual([
      'task_first_photos',
      'task_first_photos',
    ])
    expect(storageSpy).toHaveBeenCalledTimes(2)
    expect(store.thumbnailFor(B)).toContain('farm/task-b/p2.webp')
  })

  it('re-looks up a task whose photo count changed', async () => {
    const { store, fake } = setup([photo('task-a', 'p1')])
    await store.sync([A])

    fake.getTable('task_photos').length = 0
    fake
      .getTable('task_photos')
      .push(photo('task-a', 'p9') as unknown as Record<string, unknown>)
    const changed = { id: 'task-a', photo_count: 2 }
    await store.sync([changed])

    expect(store.thumbnailFor(changed)).toContain('p9.webp')
  })

  it('re-signs a cached URL once it nears expiry', async () => {
    const { store, storageSpy, advance } = setup([photo('task-a', 'p1')])
    await store.sync([A])
    await store.sync([A])
    expect(storageSpy).toHaveBeenCalledTimes(1)

    advance(THUMBNAIL_URL_TTL_SECONDS * 1000)
    await store.sync([A])

    expect(storageSpy).toHaveBeenCalledTimes(2)
  })

  it('falls back to null when the lookup fails, and retries on the next sync', async () => {
    const fake = new FakeSupabaseClient(
      { task_photos: [photo('task-a', 'p1')] },
      { table: 'task_first_photos', op: 'select' },
    )
    const store = createTaskThumbnailStore(asSupabaseClient(fake))

    await store.sync([A])
    expect(store.thumbnailFor(A)).toBeNull()

    // Clear the injected failure and sync again.
    ;(fake as unknown as { failSpecs: unknown[] }).failSpecs.length = 0
    await store.sync([A])
    expect(store.thumbnailFor(A)).toContain('p1.webp')
  })

  it('falls back to null when signing fails', async () => {
    const fake = new FakeSupabaseClient(
      { task_photos: [photo('task-a', 'p1')] },
      undefined,
      { op: 'createSignedUrls' },
    )
    const store = createTaskThumbnailStore(asSupabaseClient(fake))

    await store.sync([A])

    expect(store.thumbnailFor(A)).toBeNull()
  })

  it('on an image error, re-looks up and re-signs once, then gives up', async () => {
    const { store, fake, fromSpy } = setup([photo('task-a', 'p1')])
    await store.sync([A])
    const first = store.thumbnailFor(A)

    // The first photo was replaced without changing the count.
    fake.getTable('task_photos').length = 0
    fake
      .getTable('task_photos')
      .push(photo('task-a', 'p2') as unknown as Record<string, unknown>)
    await store.reportError(A)

    expect(fromSpy).toHaveBeenCalledTimes(2)
    expect(store.thumbnailFor(A)).not.toBe(first)
    expect(store.thumbnailFor(A)).toContain('p2.webp')

    await store.reportError(A)
    expect(store.thumbnailFor(A)).toBeNull()
  })

  it('re-signs an expired URL on an image error without using up the retry', async () => {
    const { store, fromSpy, storageSpy, advance } = setup([
      photo('task-a', 'p1'),
    ])
    await store.sync([A])

    // Two full TTLs pass with the page open; each expiry errors once.
    for (let i = 0; i < 2; i++) {
      advance(THUMBNAIL_URL_TTL_SECONDS * 1000)
      await store.reportError(A)
      expect(store.thumbnailFor(A)).toContain('p1.webp')
    }

    expect(fromSpy).toHaveBeenCalledTimes(1)
    expect(storageSpy).toHaveBeenCalledTimes(3)
  })

  it('keeps a slow earlier sync from hiding a later one’s results', async () => {
    const { store } = setup([photo('task-a', 'p1'), photo('task-b', 'p2')])

    const slow = store.sync([A])
    await store.sync([A, B])
    await slow

    expect(store.thumbnailFor(A)).toContain('p1.webp')
    expect(store.thumbnailFor(B)).toContain('p2.webp')
  })
})
