import { describe, expect, it } from 'vitest'
import {
  deleteTaskPhoto,
  getTaskPhotoUrl,
  listPhotos,
  updateTaskPhotoCaption,
  uploadTaskPhoto,
} from '../app/services/photos'
import { FakeSupabaseClient, asSupabaseClient } from './helpers/fake-supabase'
import type { Database } from '../app/types/database.types'

type PhotoRow = Database['public']['Tables']['task_photos']['Row']

const FARM_A = 'farm-a'
const TASK_A = 'task-a'

function photo(overrides: Partial<PhotoRow> = {}): PhotoRow {
  return {
    id: 'photo-seed',
    task_id: TASK_A,
    storage_path: `${FARM_A}/${TASK_A}/photo-seed.webp`,
    caption: null,
    taken_at: '2026-01-01T00:00:00.000Z',
    ...overrides,
  }
}

describe('uploadTaskPhoto', () => {
  it('uploads to storage and inserts a task_photos row with the expected path', async () => {
    const fake = new FakeSupabaseClient({ task_photos: [] })
    const supabase = asSupabaseClient(fake)

    const result = await uploadTaskPhoto(supabase, {
      farmId: FARM_A,
      taskId: TASK_A,
      blob: new Blob(['fake-bytes']),
    })

    expect(result.storage_path).toMatch(
      new RegExp(`^${FARM_A}/${TASK_A}/[^/]+\\.webp$`),
    )
    expect(fake.getTable('task_photos')).toHaveLength(1)
    expect(fake.getStorageObjects()).toEqual([result.storage_path])
  })

  it('trims a caption, and turns empty/whitespace-only captions into null', async () => {
    const fake = new FakeSupabaseClient({ task_photos: [] })
    const supabase = asSupabaseClient(fake)

    const withCaption = await uploadTaskPhoto(supabase, {
      farmId: FARM_A,
      taskId: TASK_A,
      blob: new Blob(['a']),
      caption: '  broken hinge  ',
    })
    expect(withCaption.caption).toBe('broken hinge')

    const emptyCaption = await uploadTaskPhoto(supabase, {
      farmId: FARM_A,
      taskId: TASK_A,
      blob: new Blob(['b']),
      caption: '',
    })
    expect(emptyCaption.caption).toBeNull()

    const whitespaceCaption = await uploadTaskPhoto(supabase, {
      farmId: FARM_A,
      taskId: TASK_A,
      blob: new Blob(['c']),
      caption: '   ',
    })
    expect(whitespaceCaption.caption).toBeNull()
  })

  it('propagates a storage upload failure and does not insert a task_photos row', async () => {
    const fake = new FakeSupabaseClient({ task_photos: [] }, undefined, {
      op: 'upload',
    })
    const supabase = asSupabaseClient(fake)

    await expect(
      uploadTaskPhoto(supabase, {
        farmId: FARM_A,
        taskId: TASK_A,
        blob: new Blob(['a']),
      }),
    ).rejects.toThrow()

    expect(fake.getTable('task_photos')).toHaveLength(0)
    expect(fake.getStorageObjects()).toHaveLength(0)
  })

  it('propagates a task_photos insert failure', async () => {
    const fake = new FakeSupabaseClient(
      { task_photos: [] },
      {
        table: 'task_photos',
        op: 'insert',
      },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      uploadTaskPhoto(supabase, {
        farmId: FARM_A,
        taskId: TASK_A,
        blob: new Blob(['a']),
      }),
    ).rejects.toThrow()
  })
})

describe('listPhotos', () => {
  it("returns only the given task's photos, ordered by taken_at ascending", async () => {
    const fake = new FakeSupabaseClient({
      task_photos: [
        photo({
          id: 'photo-2',
          task_id: TASK_A,
          taken_at: '2026-01-02T00:00:00.000Z',
        }),
        photo({
          id: 'photo-1',
          task_id: TASK_A,
          taken_at: '2026-01-01T00:00:00.000Z',
        }),
        photo({ id: 'photo-3', task_id: 'task-b' }),
      ],
    })
    const supabase = asSupabaseClient(fake)

    const result = await listPhotos(supabase, TASK_A)

    expect(result.map((p) => p.id)).toEqual(['photo-1', 'photo-2'])
  })
})

describe('deleteTaskPhoto', () => {
  it('removes both the storage object and the task_photos row', async () => {
    const path = `${FARM_A}/${TASK_A}/photo-1.webp`
    const fake = new FakeSupabaseClient({
      task_photos: [photo({ id: 'photo-1', storage_path: path })],
    })
    fake.storage.from('task-photos').upload(path, new Blob(['a']))
    const supabase = asSupabaseClient(fake)

    await deleteTaskPhoto(supabase, { photoId: 'photo-1', storagePath: path })

    expect(fake.getTable('task_photos')).toHaveLength(0)
    expect(fake.getStorageObjects()).not.toContain(path)
  })

  it('propagates a storage remove failure without deleting the DB row', async () => {
    const path = `${FARM_A}/${TASK_A}/photo-1.webp`
    const fake = new FakeSupabaseClient(
      { task_photos: [photo({ id: 'photo-1', storage_path: path })] },
      undefined,
      { op: 'remove' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      deleteTaskPhoto(supabase, { photoId: 'photo-1', storagePath: path }),
    ).rejects.toThrow()

    expect(fake.getTable('task_photos')).toHaveLength(1)
  })

  it('propagates a DB delete failure', async () => {
    const path = `${FARM_A}/${TASK_A}/photo-1.webp`
    const fake = new FakeSupabaseClient(
      { task_photos: [photo({ id: 'photo-1', storage_path: path })] },
      { table: 'task_photos', op: 'delete' },
    )
    const supabase = asSupabaseClient(fake)

    await expect(
      deleteTaskPhoto(supabase, { photoId: 'photo-1', storagePath: path }),
    ).rejects.toThrow()
  })
})

describe('updateTaskPhotoCaption', () => {
  it('updates and returns the row with a trimmed caption', async () => {
    const fake = new FakeSupabaseClient({
      task_photos: [photo({ id: 'photo-1', caption: null })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await updateTaskPhotoCaption(supabase, {
      photoId: 'photo-1',
      caption: '  new caption  ',
    })

    expect(result.caption).toBe('new caption')
  })

  it('sets caption to null for an empty string', async () => {
    const fake = new FakeSupabaseClient({
      task_photos: [photo({ id: 'photo-1', caption: 'old caption' })],
    })
    const supabase = asSupabaseClient(fake)

    const result = await updateTaskPhotoCaption(supabase, {
      photoId: 'photo-1',
      caption: '',
    })

    expect(result.caption).toBeNull()
  })
})

describe('getTaskPhotoUrl', () => {
  it("returns the fake's deterministic signed URL", async () => {
    const fake = new FakeSupabaseClient()
    const supabase = asSupabaseClient(fake)

    const url = await getTaskPhotoUrl(supabase, `${FARM_A}/${TASK_A}/p.webp`)

    expect(url).toBe(
      `https://fake-storage.test/task-photos/${FARM_A}/${TASK_A}/p.webp?expires=3600`,
    )
  })

  it('propagates a createSignedUrl failure', async () => {
    const fake = new FakeSupabaseClient({}, undefined, {
      op: 'createSignedUrl',
    })
    const supabase = asSupabaseClient(fake)

    await expect(
      getTaskPhotoUrl(supabase, `${FARM_A}/${TASK_A}/p.webp`),
    ).rejects.toThrow()
  })
})
