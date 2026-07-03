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
