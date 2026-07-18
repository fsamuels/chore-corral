// `useSupabaseUser()` returns the decoded access-token JWT payload, not a
// Supabase `User` object — the user's id is the standard `sub` claim, not
// `id` (which doesn't exist on the payload; TS didn't catch the mismatch
// because `JwtPayload` has a permissive `[key: string]: any` index
// signature). Centralized here so every actor-id read goes through one
// tested path instead of each composable reaching for `.id` again.
export function getActorUserId(
  user: { sub?: string } | null | undefined,
): string | undefined {
  return user?.sub
}

// The JWT payload also carries a `user_metadata` claim holding the Google
// profile GoTrue captured (and refreshes each sign-in) — the same source
// the `farm_member_profiles` view reads server-side. These two helpers
// mirror that view's key preference (`full_name`/`name`,
// `avatar_url`/`picture`, blank-trimmed to null) so the signed-in user's
// own name/avatar render identically to how other members see them,
// without a DB round-trip.

interface UserMetadataClaim {
  user_metadata?: {
    full_name?: unknown
    name?: unknown
    avatar_url?: unknown
    picture?: unknown
  }
}

function firstNonBlankString(...values: unknown[]): string | null {
  for (const value of values) {
    if (typeof value === 'string' && value.trim() !== '') return value.trim()
  }
  return null
}

export function getUserDisplayName(
  user: UserMetadataClaim | null | undefined,
): string | null {
  const metadata = user?.user_metadata
  return firstNonBlankString(metadata?.full_name, metadata?.name)
}

export function getUserAvatarUrl(
  user: UserMetadataClaim | null | undefined,
): string | null {
  const metadata = user?.user_metadata
  return firstNonBlankString(metadata?.avatar_url, metadata?.picture)
}
