export function isSupabaseConfigured(
  url: string | undefined,
  key: string | undefined,
): boolean {
  return Boolean(url && key)
}
