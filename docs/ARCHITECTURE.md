# Chore Corral — Architecture

This document covers the technical stack, why each piece was chosen, and how the major architectural pieces fit together. For schema details, see DATA_MODEL.md. For the reasoning behind specific non-obvious choices, see DECISIONS.md.

## Stack Summary

| Layer              | Choice                                                                           |
| ------------------ | -------------------------------------------------------------------------------- |
| Frontend framework | Nuxt (Vue 3)                                                                     |
| Component library  | Vuetify (Material Design)                                                        |
| Backend / database | Supabase (Postgres + Auth + Storage)                                             |
| Hosting            | Vercel                                                                           |
| Forms & validation | VeeValidate + Zod                                                                |
| Maps               | Leaflet + `@vue-leaflet/vue-leaflet`                                             |
| Base map tiles     | Mapbox Satellite (hybrid), toggleable; Esri World Imagery planned for comparison |
| Testing            | Vitest + `@vue/test-utils` (unit/component only for MVP)                         |
| Linting            | `@nuxt/eslint` + Prettier (`eslint-config-prettier` to avoid rule conflicts)     |
| Type checking      | `vue-tsc`, run in CI                                                             |
| Git hooks          | Husky + lint-staged                                                              |
| CI                 | GitHub Actions (lint → typecheck → test → build)                                 |

This is a deliberate divergence from the Durak Tracker stack (Next.js/React) — chosen partly for genuine architectural learning value (Vue's reactivity model, Nuxt's data-fetching conventions) and partly because it converts prior Vue-adjacent professional exposure into demonstrable, portfolio-visible ownership. See DECISIONS.md for the full reasoning.

## Frontend

### Nuxt + Vuetify

Nuxt deploys to Vercel via an official adapter, so hosting stays unchanged from Durak Tracker despite the frontend framework switching. Vuetify was chosen over alternatives (Nuxt UI, PrimeVue, Quasar) specifically for its Material Design foundation — Material's mobile-first design philosophy aligns directly with this app's mobile-first requirement, and Vuetify's official Nuxt module (`vuetify-nuxt-module`) handles SSR setup and tree-shaking automatically.

Relevant Vuetify components anticipated:

- `v-data-table` — task list, especially once category/priority filtering is active
- `v-bottom-navigation` — primary mobile navigation
- `v-navigation-drawer` — farm switcher and secondary navigation on larger screens
- Form components paired with VeeValidate + Zod

### Forms: VeeValidate + Zod

The Vue-ecosystem equivalent of Durak Tracker's React Hook Form + Zod pattern — same validation philosophy (schema-first with Zod), different binding layer appropriate to Vue's reactivity model.

## Backend

### Supabase

Provides Postgres, Auth (OAuth via Google), Storage, and auto-generated APIs in one platform. Chosen to keep infrastructure minimal — no separate auth provider, storage service, or hand-rolled API layer.

**Auth flow**: Google OAuth via Supabase Auth. Invite-only — no public signup path is exposed in the UI. A user who authenticates but has no `farm_memberships` row sees a clear, actionable error state rather than a blank screen or generic failure (see SPEC.md — Authentication).

**Authorization: RLS + application-layer, deliberately combined.** This project uses Postgres Row Level Security as a defense-in-depth backstop (every farm-scoped table is deny-by-default, scoped via `farm_memberships`), while business-logic rules that don't map cleanly to declarative SQL policies (e.g. "a category can't be soft-deleted while active tasks reference it") are enforced in application code. This is a deliberate divergence from a pure application-layer approach — see DECISIONS.md for the full reasoning, since RLS was a genuinely new skill investment for this project.

### Storage & Photo Pipeline

Photos are compressed client-side before upload:

1. Resize to a maximum of 1600px on the longest edge.
2. Convert to WebP.
3. Target compressed size: ~500 KB–1 MB per photo (from a 10 MB max raw upload).

This keeps storage well within Supabase's free-tier bucket limits at the project's stated scale (see DECISIONS.md for the cost analysis). Storage path structure is `{farm_id}/{task_id}/{photo_id}.webp`, keeping farm-scoping visible in the path itself and simplifying storage-level access policies.

## Maps

### Leaflet + Mapbox Satellite

Leaflet was chosen as the mapping library specifically because it supports standard XYZ tile layers natively — swapping tile providers (OpenStreetMap → Mapbox → Esri, for comparison) is a configuration change, not a library change. The tile provider URL/config is kept in a single, centralized location (a composable or config file) rather than hardcoded into map components, so future provider comparisons remain low-effort.

**Current tile setup**: Mapbox Satellite Streets (hybrid — imagery + roads/labels), with a layer control (`L.control.layers`) offering at least a plain street/OSM fallback. Esri World Imagery is planned for future side-by-side comparison, particularly since Esri's ag-sector focus may yield better resolution over this specific rural property — the abstraction described above is what makes that comparison cheap to try.

**API key handling**: Mapbox's public access token is a client-exposed environment variable (e.g. `NUXT_PUBLIC_MAPBOX_TOKEN`), alongside Supabase's public keys.

### Boundaries & Measurement (Future)

Not part of MVP. When built, this will use Leaflet.draw for polygon drawing and Turf.js for area calculation — both are pure client-side geometry, not metered API calls, so this feature doesn't introduce new usage-based costs. The database side will require PostGIS (see DATA_MODEL.md).

## Testing Strategy

Moderate rigor for MVP: **unit and component tests only, no E2E** (Playwright deferred). Test coverage priorities:

- Form validation logic (VeeValidate + Zod schemas)
- Supabase query/data functions (mockable business logic)
- Task lifecycle logic (e.g. status transitions clearing `completed_at`, category deletion's active-task check)

E2E (Playwright) is a reasonable addition once core flows stabilize post-MVP, given this app has more end-to-end-worthy flows (photo upload, map interaction, GPS capture) than Durak Tracker did.

## CI/CD

GitHub Actions pipeline: lint → typecheck → test → build, run on every PR. Combined with the project's squash-merge workflow, this keeps `main` history clean while giving every merged PR a green-CI signal — relevant both for genuine build confidence and for portfolio credibility (a reviewer skimming PR history sees enforced quality gates, not just commits).

## Multi-Tenancy

Farms are the top-level tenant boundary, chosen deliberately from day one (see DECISIONS.md) rather than retrofitted later, since restructuring a single-workspace app into multi-tenant after the fact would touch nearly every table and RLS policy. See DATA_MODEL.md for the full schema.

## Future AWS Migration Considerations

Not planned for MVP, but worth noting given it was discussed during planning: the database itself (vanilla Postgres, RLS policies) migrates cleanly to AWS RDS if that ever becomes necessary post-monetization. The harder migration would be Supabase's bundled conveniences — Auth, Storage, Realtime (if adopted later) — which don't have drop-in AWS equivalents and would need to be re-implemented rather than migrated. Keeping Supabase calls wrapped in composables/services rather than scattered through components (standard practice here regardless) reduces the blast radius of that hypothetical future migration.
