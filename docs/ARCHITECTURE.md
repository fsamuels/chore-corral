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

- `v-data-table` — full task list on `/tasks` (filters + table styling; the home queue uses a custom `TaskCard` component instead)
- `v-bottom-navigation` — primary mobile navigation (Home and Map only, on smAndDown)
- `v-navigation-drawer` — secondary navigation (Tasks management, Categories management, Change Farm page, Sign out) on all screen sizes, opened from the header hamburger button; includes signed-in user's email at the top
- Custom app header (`app/layouts/default.vue`) — replaces `v-app-bar`; shows "Chore Corral" eyebrow + active farm name (links home), circular Home/Map icon buttons on desktop, and the hamburger trigger on the right
- Ranch design system (`app/assets/css/main.css`) — warm cream/surface palette, priority color tokens (`--cc-urgent-*` / `--cc-soon-*` / `--cc-whenever-*`), shared utility classes (`cc-card`, `cc-pill`, `cc-eyebrow`, `cc-section-title`), and Zilla Slab + Inter typography loaded via `nuxt.config.ts`; a single Vuetify theme (`ranch`) mirrors the same palette for component defaults
- Form components paired with VeeValidate + Zod

### Forms: VeeValidate + Zod

The Vue-ecosystem equivalent of Durak Tracker's React Hook Form + Zod pattern — same validation philosophy (schema-first with Zod), different binding layer appropriate to Vue's reactivity model.

## Backend

### Supabase

Provides Postgres, Auth (OAuth via Google), Storage, and auto-generated APIs in one platform. Chosen to keep infrastructure minimal — no separate auth provider, storage service, or hand-rolled API layer.

**Auth flow**: Google OAuth via Supabase Auth — still the only sign-in method. Signup is self-serve: a user who authenticates but has no `farm_memberships` row lands on `/welcome`, where they can create their own farm (becoming its owner via the `create_farm` security-definer function) or wait to be invited, rather than seeing a blank screen or a dead-end error state (see SPEC.md — Authentication). A farm owner can also pre-authorize an email address (`farm_invites`); whoever next signs in with that address is auto-joined via `accept_farm_invites()`, run once per session from `app/middleware/membership.global.ts`.

**Authorization: RLS + application-layer, deliberately combined.** This project uses Postgres Row Level Security as a defense-in-depth backstop (every farm-scoped table is deny-by-default, scoped via `farm_memberships`), while business-logic rules that don't map cleanly to declarative SQL policies (e.g. "a category can't be soft-deleted while active tasks reference it") are enforced in application code. This is a deliberate divergence from a pure application-layer approach — see DECISIONS.md for the full reasoning, since RLS was a genuinely new skill investment for this project.

### Storage & Photo Pipeline

Photos are compressed client-side before upload:

1. Resize to a maximum of 1600px on the longest edge.
2. Convert to WebP.
3. Target compressed size: ~500 KB–1 MB per photo (from a 10 MB max raw upload).

This keeps storage well within Supabase's free-tier bucket limits at the project's stated scale (see DECISIONS.md for the cost analysis). Storage path structure is `{farm_id}/{task_id}/{photo_id}.webp`, keeping farm-scoping visible in the path itself and simplifying storage-level access policies.

### Push Notifications (Chore Reminders)

A chore can carry any number of scheduled reminders (`task_reminders`); when one comes due, every farm member's subscribed devices get a Web Push notification — screen off, app closed. The web platform has no way to schedule a notification client-side for a future instant (the Notification Triggers API was abandoned unshipped), so the timing lives server-side and the delivery pipeline is:

1. **pg_cron** (in Supabase Postgres) runs `invoke_send_reminders()` every minute. It exits immediately unless Vault is wired up **and** at least one unsent reminder is due, so the common case costs one cheap partial-index probe.
2. When something is due, it POSTs (via **pg_net**) to the **`send-reminders` Edge Function** — the project's first Edge Function (`supabase/functions/send-reminders/`), authenticated by a shared secret header (`x-cron-secret`), not a user JWT. Deployed manually via `supabase functions deploy send-reminders`, the same manual-step model as `supabase db push` for migrations.
3. The function **atomically claims** due rows (stamping `sent_at` in a single conditional `UPDATE … RETURNING`, so concurrent invocations can't double-send), skips chores already done and reminders more than ~an hour stale (no notification blasts after downtime), fans out one Web Push per `push_subscriptions` row across the farm's members (via `npm:web-push` with VAPID auth), and prunes subscriptions the push service reports dead (404/410).
4. On the device, `public/sw.js` — a deliberately **push-only** service worker (no offline caching; that remains its own roadmap item) — shows the notification and, on tap, focuses/opens the app at the chore's page.

Client-side, `usePushNotifications` handles the per-device opt-in from the nav drawer's "Chore reminders" item: register the worker, request permission (from a tap — browsers require a user gesture), `PushManager.subscribe()` with the VAPID public key, and persist the subscription to `push_subscriptions`. The VAPID **public** key is a client-exposed env var (`NUXT_PUBLIC_VAPID_PUBLIC_KEY`, same treatment as the Mapbox token); the **private** key exists only as an Edge Function secret. Platform note: on iOS (16.4+), Web Push only works once the app is added to the Home Screen — the composable detects that case and the UI hints to install first. Delivery is near-real-time but best-effort; reminders are a nudge, not an alarm clock.

**Snooze (10 min / 1 hr)** rides the same pipeline: a snooze mutates the _same_ `task_reminders` row (`remind_at` pushed out, `sent_at` cleared), so the reminder simply re-fires through the every-minute scan and reappears as upcoming in the chore's Reminders card. It has two surfaces because the platforms split: **notification action buttons** (Android/desktop Chrome — iOS web push renders no action buttons at all) handled in `sw.js`, and **in-app snooze buttons** on already-sent reminders in the chore's Reminders card (the iOS path, since tapping an iOS notification opens the chore). The service worker has no Supabase session, so its action-button path POSTs to `/api/reminders/snooze` — the project's **first Nitro server route** — which rebuilds a user-session Supabase client from the request's auth cookies (`#supabase/server`) and performs the update **under RLS**, exactly like a client-side query; the in-app buttons go through the normal services layer instead. Shared validation/math lives in `app/utils/reminder-snooze.ts`, used by both.

## Maps

### Leaflet + Mapbox Satellite

Leaflet was chosen as the mapping library specifically because it supports standard XYZ tile layers natively — swapping tile providers (OpenStreetMap → Mapbox → Esri, for comparison) is a configuration change, not a library change. The tile provider URL/config is kept in a single, centralized location (a composable or config file) rather than hardcoded into map components, so future provider comparisons remain low-effort.

**Current tile setup**: Mapbox Satellite Streets (hybrid — imagery + roads/labels), with a layer control (`L.control.layers`) offering at least a plain street/OSM fallback. Esri World Imagery is planned for future side-by-side comparison, particularly since Esri's ag-sector focus may yield better resolution over this specific rural property — the abstraction described above is what makes that comparison cheap to try.

**API key handling**: Mapbox's public access token is a client-exposed environment variable (e.g. `NUXT_PUBLIC_MAPBOX_TOKEN`), alongside Supabase's public keys.

### Boundaries & Measurement (Future)

Not part of MVP. When built, this will use Leaflet.draw for polygon drawing and Turf.js for area calculation — both are pure client-side geometry, not metered API calls, so this feature doesn't introduce new usage-based costs. The database side will require PostGIS (see DATA_MODEL.md).

## Testing Strategy

Two layers: unit/component tests (Vitest) plus a small Playwright E2E suite. Unit test coverage priorities:

- Form validation logic (VeeValidate + Zod schemas)
- Supabase query/data functions (mockable business logic)
- Task lifecycle logic (e.g. status transitions clearing `completed_at`, category deletion's active-task check)

**E2E (Playwright, `tests/e2e/`)**: real Google OAuth can't be scripted in CI, so tests authenticate by minting a real Supabase session out-of-band instead of adding any auth-bypass code path to the app. `tests/e2e/global-setup.ts` uses the Supabase **service-role key** (server/CLI-only, never shipped to the client) to seed a fixed test user + farm membership via the Admin API, signs in as that user with `signInWithPassword` to get a genuine access/refresh token pair, and writes it into Playwright's storage state using the same cookie format `@nuxtjs/supabase`/`@supabase/ssr` expect (`sb-<project-ref>-auth-token`, chunked and base64url-encoded). Every spec then starts already signed in, exercising real RLS as any user would. Requires `SUPABASE_SERVICE_ROLE_KEY` (and optional `E2E_TEST_USER_EMAIL`/`E2E_TEST_USER_PASSWORD`/`E2E_TEST_FARM_NAME`) — see `.env.example`. Run with `pnpm test:e2e`.

## CI/CD

GitHub Actions pipeline: lint → typecheck → test → build, run on every PR. Combined with the project's squash-merge workflow, this keeps `main` history clean while giving every merged PR a green-CI signal — relevant both for genuine build confidence and for portfolio credibility (a reviewer skimming PR history sees enforced quality gates, not just commits).

## Multi-Tenancy

Farms are the top-level tenant boundary, chosen deliberately from day one (see DECISIONS.md) rather than retrofitted later, since restructuring a single-workspace app into multi-tenant after the fact would touch nearly every table and RLS policy. See DATA_MODEL.md for the full schema.

## Future AWS Migration Considerations

Not planned for MVP, but worth noting given it was discussed during planning: the database itself (vanilla Postgres, RLS policies) migrates cleanly to AWS RDS if that ever becomes necessary post-monetization. The harder migration would be Supabase's bundled conveniences — Auth, Storage, Realtime (if adopted later) — which don't have drop-in AWS equivalents and would need to be re-implemented rather than migrated. Keeping Supabase calls wrapped in composables/services rather than scattered through components (standard practice here regardless) reduces the blast radius of that hypothetical future migration.
