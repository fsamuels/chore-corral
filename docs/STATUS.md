# Chore Corral — Status

Current state of the project. Update this as work progresses — it should always reflect reality, not intent.

**Last updated:** 2026-07-02

## Current Phase

**M3 in progress** (M1's Vercel connection and M2's hosted migration still pending — see Known Issues / Next Steps). The app-side auth flow is implemented via `@nuxtjs/supabase`: a `/login` page with Google `signInWithOAuth`, the `/confirm` OAuth callback (with error/timeout states), and route protection through the module's auth middleware plus a global membership middleware. The unrecognized-login state is a dedicated `/no-access` page — an authenticated user whose RLS-scoped `farms` query returns zero rows is redirected there and sees the invite-only explanation, their signed-in email, and a sign-out button. The farm switcher is scaffolded as an app-bar dropdown (`FarmSwitcher.vue`) backed by a `useFarms` composable with the active-farm selection persisted in a cookie; `/` is now the authenticated home showing the active farm. Not yet done (all blocked on manual/hosted setup): enabling the Google provider in the Supabase dashboard + Google Cloud OAuth client, applying the M2 migration, and seeding farms/memberships — so no end-to-end login has been verified yet.

**M2 state:** the full MVP schema exists as a versioned Supabase CLI migration (`supabase/migrations/20260702154910_m2_schema_and_rls.sql`): both enums, all eight tables per DATA_MODEL.md, deny-by-default RLS with the farm-membership pattern on every farm-scoped table (append-only `activity_log`), and the private `task-photos` storage bucket with path-based per-operation policies. The migration and its RLS behavior were validated against a local Postgres 16 cluster with a shim of the Supabase-managed surface — 13 impersonation tests confirm cross-farm isolation for reads, writes, and storage paths. Not yet done: the migration hasn't been applied to the hosted Supabase project, and the two farms/memberships aren't seeded, so M2's done-state isn't met yet.

Earlier M1 state: Nuxt + Vuetify app scaffolded with the full tooling set (ESLint, Prettier, vue-tsc, Husky/lint-staged, Vitest, GitHub Actions CI); `app/pages/` file-based routing with the scaffold landing card at `/` and a Vuetify component sampler at `/components-demo` (demo/reference only). Supabase project `chore-corral` (us-east-2) created with public env vars wired into the local app and Vercel (Production/Development environments).

## Milestone Progress

| Milestone                | Status      |
| ------------------------ | ----------- |
| M1 — Scaffold & Deploy   | In Progress |
| M2 — Schema & Data Layer | In Progress |
| M3 — Auth                | In Progress |
| M4 — Category Management | Not started |
| M5 — Core Task CRUD      | Not started |
| M6 — Tags & Autocomplete | Not started |
| M7 — Location & Map View | Not started |
| M8 — Photos              | Not started |
| M9 — Polish & Hardening  | Not started |

## Known Issues

- The Vercel GitHub App is now connected and PR preview deploys run, but `NUXT_PUBLIC_SUPABASE_URL`/`KEY` are still only set for the Production and Development environments, not Preview — preview builds log `[@nuxt/supabase] WARN Missing NUXT_PUBLIC_SUPABASE_URL/KEY` as a result (harmless for now since nothing queries Supabase at build time, but needs closing out — see Next Steps).
- Vercel's PR preview build for the M3 branch initially failed with `[vite]: Rollup failed to resolve import "tslib" from ".../@supabase/functions-js/.../FunctionsClient.js"`, even though `pnpm build` passed both locally and in GitHub Actions CI on the same commit. It reproduced across multiple pushes (including one that added `tslib` as an explicit direct dependency, which didn't help) and was resolved by clearing Vercel's build cache and redeploying — pointing to a stale/corrupted cached `node_modules` on Vercel's side rather than a real dependency-resolution bug. Worth remembering if a future Vercel build fails on a dependency error that CI doesn't reproduce: try a cache-cleared redeploy before chasing a code fix.

## Next Steps

1. Apply the M2 migration to the hosted Supabase project from a machine with project credentials: `npx supabase link --project-ref <ref>`, then `npx supabase db push` (a future CI job for this is on ROADMAP.md)
2. Create the two farms (Reign Cloud Ranch, Clarkson's Farm) and at least one membership row each — auth users can be created manually in the Supabase dashboard ahead of M3's OAuth
3. Re-verify RLS in the Supabase SQL editor impersonating a test user's JWT, per M2's done-state (already verified against a local Postgres shim)
4. Grant the Vercel GitHub App access to the `chore-corral` repo, connect the repo in Vercel project settings, then add the Preview environment env vars to close out M1's done-state
5. Configure Google OAuth for M3: create an OAuth client in Google Cloud Console (authorized redirect URI: `https://<project-ref>.supabase.co/auth/v1/callback`), enable the Google provider in the Supabase dashboard with that client ID/secret, and set the Auth URL configuration (Site URL = production Vercel URL; additional redirect URLs for `http://localhost:3000/confirm` and Vercel previews)
6. Verify M3's done-state end-to-end: log in with a member account, confirm the farm-scoped home + farm switcher, and confirm a membership-less test account lands on `/no-access`
