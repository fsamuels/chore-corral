import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'
import { chunk } from '../utils/chunk'

export interface PhotoSummary {
  id: string
  storage_path: string
  caption: string | null
  taken_at: string
}

const PHOTO_COLUMNS = 'id, storage_path, caption, taken_at'
const BUCKET = 'task-photos'

type Client = SupabaseClient<Database>

/** All photos for one task, in upload/chronological order. */
export async function listPhotos(
  supabase: Client,
  taskId: string,
): Promise<PhotoSummary[]> {
  const { data, error } = await supabase
    .from('task_photos')
    .select(PHOTO_COLUMNS)
    .eq('task_id', taskId)
    .order('taken_at')
    // Tiebreak so photos sharing a taken_at keep a stable order, matching
    // the task_first_photos view's choice of "first".
    .order('id')
  if (error) throw new Error(error.message)
  return data
}

export interface UploadTaskPhotoInput {
  farmId: string
  taskId: string
  blob: Blob
  caption?: string | null
}

/**
 * Upload a compressed photo and record its `task_photos` row. The photo id
 * is generated client-side (rather than left to the DB default) because the
 * storage path must embed it before the row exists. Storage upload happens
 * before the DB insert; a failed upload never leaves behind a DB row.
 */
export async function uploadTaskPhoto(
  supabase: Client,
  input: UploadTaskPhotoInput,
): Promise<PhotoSummary> {
  const photoId = crypto.randomUUID()
  const path = `${input.farmId}/${input.taskId}/${photoId}.webp`

  const { error: uploadError } = await supabase.storage
    .from(BUCKET)
    .upload(path, input.blob, { contentType: 'image/webp' })
  if (uploadError) throw new Error(uploadError.message)

  const { data, error } = await supabase
    .from('task_photos')
    .insert({
      id: photoId,
      task_id: input.taskId,
      storage_path: path,
      caption: input.caption?.trim() || null,
    })
    .select(PHOTO_COLUMNS)
    .single()
  if (error) throw new Error(error.message)

  return data
}

/**
 * Delete a photo: removes the `task_photos` row first, then the storage
 * object. Row-first means an interrupted delete (the phone locks or the tab
 * closes between the two requests — likely now that removals commit as the
 * page is hidden) leaves at worst an unreferenced file nobody sees, never a
 * row pointing at a missing image. For the same reason a storage failure
 * after the row is gone isn't reported: the photo is already deleted as far
 * as the app is concerned.
 */
export async function deleteTaskPhoto(
  supabase: Client,
  opts: { photoId: string; storagePath: string },
): Promise<void> {
  const { error } = await supabase
    .from('task_photos')
    .delete()
    .eq('id', opts.photoId)
  if (error) throw new Error(error.message)

  await supabase.storage.from(BUCKET).remove([opts.storagePath])
}

/**
 * Update a photo's caption. The fake (and PostgREST in practice, per this
 * codebase's other services) doesn't support `.single()` chained after
 * `.update()`, so this follows `updateTask`'s pattern: `.update().eq()
 * .select()` returns an array, and the first element is taken.
 */
export async function updateTaskPhotoCaption(
  supabase: Client,
  opts: { photoId: string; caption: string | null },
): Promise<PhotoSummary> {
  const { data, error } = await supabase
    .from('task_photos')
    .update({ caption: opts.caption?.trim() || null })
    .eq('id', opts.photoId)
    .select(PHOTO_COLUMNS)
  if (error) throw new Error(error.message)
  const photo = data[0]
  if (!photo) throw new Error('Photo not found')
  return photo
}

/** A short-lived signed URL for displaying a private photo. */
export async function getTaskPhotoUrl(
  supabase: Client,
  storagePath: string,
  expiresInSeconds = 3600,
): Promise<string> {
  const { data, error } = await supabase.storage
    .from(BUCKET)
    .createSignedUrl(storagePath, expiresInSeconds)
  if (error) throw new Error(error.message)
  return data.signedUrl
}

/**
 * The first photo (earliest `taken_at`, then `id` — matching `listPhotos`'
 * order) of each given task, keyed by task id: what list views show as a
 * card thumbnail. Tasks with no photos are absent from the map.
 *
 * Reads the `task_first_photos` view, which does the DISTINCT ON in SQL, so
 * the response is one row per task rather than every photo row (which could
 * also hit PostgREST's max-rows cap on photo-heavy farms). Ids are queried
 * in parallel chunks to bound URL length.
 */
export async function listFirstPhotoPaths(
  supabase: Client,
  taskIds: string[],
): Promise<Map<string, string>> {
  const results = await Promise.all(
    chunk(taskIds).map(async (ids) => {
      const { data, error } = await supabase
        .from('task_first_photos')
        .select('task_id, storage_path')
        .in('task_id', ids)
      if (error) throw new Error(error.message)
      return data
    }),
  )
  const firstByTask = new Map<string, string>()
  for (const row of results.flat()) {
    firstByTask.set(row.task_id, row.storage_path)
  }
  return firstByTask
}

/**
 * Signed URLs for many private photos in one storage request, keyed by
 * storage path. Paths the storage API couldn't sign are left out of the map
 * rather than failing the whole batch.
 */
export async function getTaskPhotoUrls(
  supabase: Client,
  storagePaths: string[],
  expiresInSeconds = 3600,
): Promise<Map<string, string>> {
  const urls = new Map<string, string>()
  if (storagePaths.length === 0) return urls
  const { data, error } = await supabase.storage
    .from(BUCKET)
    .createSignedUrls(storagePaths, expiresInSeconds)
  if (error) throw new Error(error.message)
  for (const entry of data) {
    if (entry.path && entry.signedUrl && !entry.error) {
      urls.set(entry.path, entry.signedUrl)
    }
  }
  return urls
}
