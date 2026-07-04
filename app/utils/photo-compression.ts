// Client-side photo compression pipeline (M8): resize to a max edge, convert
// to WebP, and iteratively lower quality until under a target byte size. See
// docs/ARCHITECTURE.md's "Storage & Photo Pipeline" section for the pipeline
// this implements and docs/DATA_MODEL.md for the storage path convention the
// resulting blob is uploaded under.

// SPEC: raw uploads are capped before client-side compression runs. Shared by
// every photo-upload entry point (`useTaskPhotos`, `StagedTaskPhotos`) so the
// limit isn't duplicated as a magic number in more than one place.
export const MAX_UPLOAD_BYTES = 10 * 1024 * 1024

/**
 * Compute output dimensions for an image so its longest edge is at most
 * `maxEdge`, preserving aspect ratio. Pure function, no browser APIs — kept
 * separate from `compressImage` so it's unit-testable in Vitest/happy-dom,
 * which has no real canvas/image decoding.
 */
export function computeResizedDimensions(
  width: number,
  height: number,
  maxEdge = 1600,
): { width: number; height: number } {
  const longestEdge = Math.max(width, height)
  if (longestEdge <= maxEdge) {
    return { width: Math.round(width), height: Math.round(height) }
  }

  const scale = maxEdge / longestEdge
  return {
    width: Math.round(width * scale),
    height: Math.round(height * scale),
  }
}

/**
 * Decode a raw image file/blob, resize it to at most `opts.maxEdge` on its
 * longest edge, and re-encode as WebP, stepping quality down from 0.82 in
 * 0.1 increments (floor `opts.minQuality`) until the result is under
 * `opts.targetMaxBytes` or quality can't drop any further.
 *
 * Browser-only (createImageBitmap/canvas) — not unit tested here, since
 * Vitest's happy-dom environment has no real image decoding or canvas
 * rendering to exercise. `computeResizedDimensions` carries the test
 * coverage for the pure sizing logic this function depends on.
 */
export async function compressImage(
  file: Blob,
  opts?: { maxEdge?: number; targetMaxBytes?: number; minQuality?: number },
): Promise<Blob> {
  const maxEdge = opts?.maxEdge ?? 1600
  const targetMaxBytes = opts?.targetMaxBytes ?? 1_000_000
  const minQuality = opts?.minQuality ?? 0.5

  const bitmap = await createImageBitmap(file)
  const { width, height } = computeResizedDimensions(
    bitmap.width,
    bitmap.height,
    maxEdge,
  )

  const canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height
  const ctx = canvas.getContext('2d')
  if (!ctx) throw new Error('Failed to get 2D canvas context for compression')
  ctx.drawImage(bitmap, 0, 0, width, height)

  let quality = 0.82
  let blob = await encodeWebp(canvas, quality)
  while (blob.size > targetMaxBytes && quality > minQuality) {
    quality = Math.max(minQuality, quality - 0.1)
    blob = await encodeWebp(canvas, quality)
    if (quality <= minQuality) break
  }

  return blob
}

function encodeWebp(canvas: HTMLCanvasElement, quality: number): Promise<Blob> {
  return new Promise((resolve, reject) => {
    canvas.toBlob(
      (blob) => {
        if (!blob) {
          reject(new Error('Failed to encode image to WebP'))
          return
        }
        resolve(blob)
      },
      'image/webp',
      quality,
    )
  })
}
