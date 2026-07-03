import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '~/types/database.types'

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
 * Delete a photo: removes the storage object first, then the `task_photos`
 * row, mirroring `uploadTaskPhoto`'s storage-then-db ordering.
 */
export async function deleteTaskPhoto(
  supabase: Client,
  opts: { photoId: string; storagePath: string },
): Promise<void> {
  const { error: removeError } = await supabase.storage
    .from(BUCKET)
    .remove([opts.storagePath])
  if (removeError) throw new Error(removeError.message)

  const { error } = await supabase
    .from('task_photos')
    .delete()
    .eq('id', opts.photoId)
  if (error) throw new Error(error.message)
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
