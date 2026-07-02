# Chore Corral — Status

Current state of the project. Update this as work progresses — it should always reflect reality, not intent.

**Last updated:** 2026-07-02

## Current Phase

**M2 in progress** (M1's Vercel connection still pending — see Known Issues). The full MVP schema now exists as a versioned Supabase CLI migration (`supabase/migrations/20260702154910_m2_schema_and_rls.sql`): both enums, all eight tables per DATA_MODEL.md, deny-by-default RLS with the farm-membership pattern on every farm-scoped table (append-only `activity_log`), and the private `task-photos` storage bucket with path-based per-operation policies. The migration and its RLS behavior were validated against a local Postgres 16 cluster with a shim of the Supabase-managed surface — 13 impersonation tests confirm cross-farm isolation for reads, writes, and storage paths. Not yet done: the migration hasn't been applied to the hosted Supabase project, and the two farms/memberships aren't seeded, so M2's done-state isn't met yet.

Earlier M1 state: Nuxt + Vuetify app scaffolded with the full tooling set (ESLint, Prettier, vue-tsc, Husky/lint-staged, Vitest, GitHub Actions CI); `app/pages/` file-based routing with the scaffold landing card at `/` and a Vuetify component sampler at `/components-demo` (demo/reference only). Supabase project `chore-corral` (us-east-2) created with public env vars wired into the local app and Vercel (Production/Development environments).

## Milestone Progress

| Milestone                | Status      |
| ------------------------ | ----------- |
| M1 — Scaffold & Deploy   | In Progress |
| M2 — Schema & Data Layer | In Progress |
| M3 — Auth                | Not started |
| M4 — Category Management | Not started |
| M5 — Core Task CRUD      | Not started |
| M6 — Tags & Autocomplete | Not started |
| M7 — Location & Map View | Not started |
| M8 — Photos              | Not started |
| M9 — Polish & Hardening  | Not started |

## Known Issues

- Vercel project `fsamuels-projects/chore-corral` isn't connected to the `fsamuels/chore-corral` GitHub repo — the Vercel GitHub App needs repo access granted manually in GitHub settings before Git-based deploys (production or PR previews) will work. Until then, `NUXT_PUBLIC_SUPABASE_URL`/`KEY` are only set for the Production and Development environments, not Preview.

## Next Steps

1. Apply the M2 migration to the hosted Supabase project from a machine with project credentials: `npx supabase link --project-ref <ref>`, then `npx supabase db push` (a future CI job for this is on ROADMAP.md)
2. Create the two farms (Reign Cloud Ranch, Clarkson's Farm) and at least one membership row each — auth users can be created manually in the Supabase dashboard ahead of M3's OAuth
3. Re-verify RLS in the Supabase SQL editor impersonating a test user's JWT, per M2's done-state (already verified against a local Postgres shim)
4. Grant the Vercel GitHub App access to the `chore-corral` repo, connect the repo in Vercel project settings, then add the Preview environment env vars to close out M1's done-state
