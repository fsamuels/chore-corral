# Chore Corral — Status

Current state of the project. Update this as work progresses — it should always reflect reality, not intent.

**Last updated:** 2026-07-02

## Current Phase

**M1 in progress.** Nuxt + Vuetify app scaffolded with the full M1 tooling set (ESLint, Prettier, vue-tsc, Husky/lint-staged, Vitest, GitHub Actions CI) — lint, typecheck, test, and build all pass locally. The app now uses `app/pages/` file-based routing: the scaffold landing card lives at `/` (`pages/index.vue`) and links to a Vuetify component sampler at `/components-demo` (demo/reference only, not a milestone deliverable). Supabase project `chore-corral` (us-east-2) is created and its public env vars are wired into both the local app and Vercel (Production/Development environments). Not yet done: the Vercel project isn't connected to the GitHub repo, so there's no live production URL and no PR preview deploys yet.

## Milestone Progress

| Milestone                | Status      |
| ------------------------ | ----------- |
| M1 — Scaffold & Deploy   | In Progress |
| M2 — Schema & Data Layer | Not started |
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

1. Grant the Vercel GitHub App access to the `chore-corral` repo, connect the repo in Vercel project settings, then add the Preview environment env vars
2. Merge this PR to get a live production URL and close out M1's done-state
3. Before/during M2, resolve the storage-bucket RLS open question in DECISIONS.md — the schema migration needs a concrete policy expression, not a placeholder
