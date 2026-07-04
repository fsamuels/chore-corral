import type { Ref } from 'vue'
import type { Database } from '~/types/database.types'
import { compressImage, MAX_UPLOAD_BYTES } from '~/utils/photo-compression'
import {
  deleteTaskPhoto,
  getTaskPhotoUrl,
  listPhotos,
  updateTaskPhotoCaption,
  uploadTaskPhoto,
  type PhotoSummary,
} from '~/services/photos'

/**
 * Photos for a single task. Unlike the per-farm composables (`useTasks`,
 * `useCategories`), this is keyed on a *task*, so it watches the passed task
 * id ref and refetches whenever it changes — including clearing to the
 * "not fetched" state when the edit dialog closes and the id goes null.
 *
 * Each photo needs both its metadata (`PhotoSummary`) and a displayable
 * `<img src>`, so signed URLs are fetched alongside the list and stored in a
 * separate map keyed by photo id.
 */
export function useTaskPhotos(taskId: Ref<string | null | undefined>) {
  const supabase = useSupabaseClient<Database>()
  const { activeFarmId } = useFarms()

  // null = not fetched yet; [] = fetched, task has no photos.
  const photos = ref<PhotoSummary[] | null>(null)
  const photoUrls = ref<Map<string, string>>(new Map())
  const photosError = ref<string | null>(null)
  const loading = ref(false)

  const uploading = ref(false)
  // Single surface for write-action failures (upload/delete/caption), shown
  // inline by the component near the upload controls.
  const uploadError = ref<string | null>(null)

  async function fetchPhotos(): Promise<void> {
    const id = taskId.value
    if (!id) {
      photos.value = null
      photoUrls.value = new Map()
      photosError.value = null
      return
    }
    loading.value = true
    try {
      const list = await listPhotos(supabase, id)
      const urls = new Map<string, string>()
      await Promise.all(
        list.map(async (photo) => {
          urls.set(
            photo.id,
            await getTaskPhotoUrl(supabase, photo.storage_path),
          )
        }),
      )
      photos.value = list
      photoUrls.value = urls
      photosError.value = null
    } catch (error) {
      photosError.value =
        error instanceof Error ? error.message : 'Failed to load photos'
    } finally {
      loading.value = false
    }
  }

  // Refetch whenever the open task changes (and on initial mount).
  watch(taskId, () => fetchPhotos(), { immediate: true })

  async function upload(file: File, caption?: string): Promise<void> {
    uploadError.value = null
    const id = taskId.value
    const farmId = activeFarmId.value
    if (!id || !farmId) {
      uploadError.value = 'No active task or farm'
      return
    }
    if (file.size > MAX_UPLOAD_BYTES) {
      uploadError.value = 'Photo is too large — the maximum is 10MB.'
      return
    }
    uploading.value = true
    try {
      const blob = await compressImage(file)
      const photo = await uploadTaskPhoto(supabase, {
        farmId,
        taskId: id,
        blob,
        caption,
      })
      const url = await getTaskPhotoUrl(supabase, photo.storage_path)
      photos.value = [...(photos.value ?? []), photo]
      const nextUrls = new Map(photoUrls.value)
      nextUrls.set(photo.id, url)
      photoUrls.value = nextUrls
    } catch (error) {
      uploadError.value =
        error instanceof Error ? error.message : 'Failed to upload photo'
    } finally {
      uploading.value = false
    }
  }

  async function remove(photo: PhotoSummary): Promise<void> {
    uploadError.value = null
    try {
      await deleteTaskPhoto(supabase, {
        photoId: photo.id,
        storagePath: photo.storage_path,
      })
      photos.value = photos.value?.filter((p) => p.id !== photo.id) ?? null
      const nextUrls = new Map(photoUrls.value)
      nextUrls.delete(photo.id)
      photoUrls.value = nextUrls
    } catch (error) {
      uploadError.value =
        error instanceof Error ? error.message : 'Failed to delete photo'
    }
  }

  async function updateCaption(
    photo: PhotoSummary,
    caption: string,
  ): Promise<void> {
    uploadError.value = null
    try {
      const updated = await updateTaskPhotoCaption(supabase, {
        photoId: photo.id,
        caption,
      })
      photos.value =
        photos.value?.map((p) => (p.id === updated.id ? updated : p)) ?? null
    } catch (error) {
      uploadError.value =
        error instanceof Error ? error.message : 'Failed to save caption'
    }
  }

  return {
    photos,
    photoUrls,
    photosError,
    loading,
    uploading,
    uploadError,
    fetchPhotos,
    upload,
    remove,
    updateCaption,
  }
}
