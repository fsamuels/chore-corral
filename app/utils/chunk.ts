// Ids per `.in()` filter. PostgREST takes `.in()` values in the GET URL;
// ~37 chars per uuid keeps 100 ids around 4 KB, well under typical proxy URL
// limits (~8 KB), however many ids the caller has.
export const IN_FILTER_CHUNK_SIZE = 100

/** Split `items` into consecutive slices of at most `size` items. */
export function chunk<T>(items: T[], size = IN_FILTER_CHUNK_SIZE): T[][] {
  const chunks: T[][] = []
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size))
  }
  return chunks
}
