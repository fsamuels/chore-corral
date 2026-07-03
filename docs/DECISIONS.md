# Chore Corral — Decisions

A running log of the reasoning behind non-obvious choices made during planning. This complements PR descriptions (which document the agentic development process per-change) by capturing project-level "why" in one place, rather than scattered across individual PRs.

## Open Questions (Unresolved)

Tracked here until decided. Once resolved, each moves out of this section and becomes its own dated entry below, following the same pattern used to resolve the priority-tier and `activity_log` TBDs.

### Default farm + persistence on login — resolve during M3

A user can belong to multiple farms. Nothing yet specifies which farm is active immediately after login, or whether the chosen farm persists across sessions (localStorage, a server-side preference, or always defaulting to the first membership row).

## Stack: Nuxt + Vuetify (diverging from Durak Tracker's Next.js/React)

Chosen deliberately to diversify framework depth rather than repeat the Next.js/React stack. Two factors drove this:

1. **Genuine learning value** — Vue's reactivity model and Nuxt's data-fetching conventions (loaders, composables) are architecturally distinct from React/Next, not just a syntax reskin.
2. **Portfolio credibility** — prior professional exposure to Vue (adjacent, not hands-on) meant Nuxt could convert that into demonstrable, shipped ownership, strengthening a multi-framework portfolio narrative for EM roles rather than showing depth in only one stack.

React remains the more market-dominant framework for EM hiring signal purposes, but depth across two frameworks (Next AND Nuxt) was judged a stronger signal of adaptability than repeated depth in one.

Vuetify was chosen over Nuxt UI, PrimeVue, and Quasar specifically for its Material Design foundation, given an explicit preference for Material's simplicity and mobile-friendliness, and its official, well-maintained Nuxt integration.

## Staying on Vercel + Supabase (not evaluating new hosting/DB platforms)

Explicitly ruled out setting up new accounts/infrastructure for this project. This kept the stack-selection conversation scoped to frontend framework and library choices rather than re-litigating hosting/backend platform choices already validated by Durak Tracker.

## Database: Postgres (no alternative DB considered)

Supabase's value (auto-generated APIs, RLS, Auth, Realtime, Storage) is built directly on Postgres internals — swapping the database engine isn't really separable from swapping Supabase itself, which would contradict the "no new infrastructure" constraint. Where a real decision existed, it was about Postgres _extensions_ (PostGIS for future boundary/geospatial work) rather than a different database engine entirely.

## Authorization: RLS + application-layer, deliberately combined

This was the most-discussed architectural decision in planning. The person's career background is entirely in application-layer security; Postgres RLS was genuinely unfamiliar. Two options were on the table:

- **Application-layer only** (skip RLS): more transferable skill, matches existing expertise, but loses defense-in-depth if Supabase's auto-generated REST API is ever exposed and a code path forgets a scoping check.
- **RLS as primary/only enforcement**: idiomatic Supabase pattern, real production-grade knowledge, but a net-new skill on top of an already-large pile of new things in this project (Nuxt, Vuetify, PostGIS potentially).

**Decision: use both.** RLS is enabled deny-by-default on every farm-scoped table as a backstop, while business-logic rules that don't map cleanly to declarative SQL (e.g. "can't delete a category with active tasks") live in application code. This was chosen specifically because RLS represented genuine new learning surface area the person wanted to invest in (reversing an earlier recommendation to skip it), while still leaning on application-layer judgment where that's the better tool.

## Multi-tenancy from day one (farms as top-level entity)

Even though MVP usage is just one person plus one collaborator, the data model was built multi-tenant (farms, many-to-many membership) from the very first migration, rather than single-workspace with a later retrofit. This was judged worth the small added complexity now because retrofitting multi-tenancy after the fact would touch nearly every table and RLS policy — an expensive migration to defer, given monetization was explicitly on the table as a possibility.

The person's own test/staging farm (Clarkson's Farm) doubles as a practical justification independent of monetization — multi-tenancy was needed anyway for a personal dev/test farm separate from the real one (Reign Cloud Ranch).

## Hard delete + activity log, not soft delete

Tasks are hard-deleted (a real DELETE, not a hidden flag) specifically because the person wanted true deletion available (mistakes/clutter shouldn't linger forever), while still preserving a historical trace via the activity log as a separate, independent record. This avoids the awkward middle ground of soft-deleted tasks cluttering queries indefinitely while still giving up nothing on historical visibility, since the activity log — not the task table — is the system of record for "this existed and was deleted."

## Photos: compress rather than auto-delete for storage management

Storage-cost concerns were initially raised via "delete photos on task completion" as a lever. After walking through Supabase Storage's free-tier limits (1 GB) against expected volume (<500 photos, growing), client-side compression (resize to 1600px, WebP conversion, targeting 500 KB–1 MB per photo) was judged sufficient to keep the project on the free tier indefinitely at stated scale — making deletion-on-completion unnecessary as a cost-control mechanism. Photos now persist regardless of task status; deletion strategy is deferred to ROADMAP.md only if actual usage significantly exceeds projections.

## Maps: Leaflet (not Mapbox GL JS or Google Maps SDK)

Leaflet was chosen specifically because it treats tile providers as swappable configuration (standard XYZ tile layers) rather than binding the app to one vendor's SDK. This mattered because satellite imagery provider comparison (Mapbox vs. Esri) was an explicit, stated goal — Leaflet keeps that comparison cheap. A Mapbox-GL-JS-first or Google-Maps-SDK-first choice would have made an Esri comparison a much larger rework later.

## Testing: moderate rigor (unit/component, no E2E) for MVP

Given the volume of genuinely new technology already in this project (Nuxt, Vue, Vuetify, RLS, PostGIS on the horizon), full E2E coverage was judged as spreading learning effort too thin for MVP. Unit/component testing targets the areas with real logic risk (validation schemas, status-transition logic, category-deletion guard rails) without the added Playwright learning curve. E2E is explicitly not abandoned — just sequenced after core flows stabilize, since this app has meaningfully more end-to-end-worthy flows (GPS capture, photo upload, map interaction) than Durak Tracker did.

## Documentation structure: granular from the start

Durak Tracker started as a single large spec document later split into README/ROADMAP/STATUS/ARCHITECTURE. For Chore Corral, the granular structure (SPEC, DATA_MODEL, ARCHITECTURE, ROADMAP, MILESTONES, STATUS, DECISIONS as separate files from day one) was chosen to avoid that same churn, given this project's larger scope (multi-tenancy, maps, photos, activity log) made a single document likely to become unwieldy even faster than Durak Tracker's did.

DATA_MODEL was split out from ARCHITECTURE specifically because of how much schema detail this project accumulated during planning (farms, memberships, tasks, categories, tags, activity log, photos) — enough to warrant its own home rather than crowding general architecture discussion.

MILESTONES was kept separate from ROADMAP on the reasoning that they serve different questions: ROADMAP answers "where is this headed" (open-ended, low-maintenance), while MILESTONES answers "what do I do next, in order, with a clear done-state" (scoped, sequential, actively maintained during build).

## Priority tiers: Urgent / Soon / Whenever, implemented as a Postgres enum

The tier set (SPEC.md, DATA_MODEL.md) was left as an open placeholder during initial planning. Resolved to three tiers — Urgent, Soon, Whenever — matching the casual, non-bureaucratic tone of the rest of the app (no "P0/P1/P2" enterprise-style labeling).

Implemented as a Postgres `enum` type rather than a `priorities` lookup table, since no admin tooling is planned to manage priorities as data — the spec is explicit that this list is fixed, global, and not user-editable, which is exactly the case an enum fits best. A lookup table's extra flexibility (renaming, reordering, adding tiers without a migration) isn't worth the added join for a value that's asserted to never change. If that assumption breaks later (e.g. a farm wants a 4th tier), migrating an enum to a table is a contained, well-understood change.

## `activity_log.task_id`: soft reference, not a hard FK

Tasks are hard-deleted (see the hard-delete decision above), but activity log entries must outlive the task they reference. Resolved by making `task_id` a plain nullable `uuid` column with **no FK constraint** — deletion of a task can never cascade into or orphan-error against its log entries, because the database enforces nothing there. To keep log entries meaningful without needing a join back to `tasks` (which may 404), `event_detail` always snapshots the task's title, on every event type, not just deletion.

## Storage RLS: derive `farm_id` from the object path via `storage.foldername()`

Resolved 2026-07-02 (during M2 planning). Supabase Storage policies can't join a `farm_id` column the way table policies do — `storage.objects` only exposes the path string. Since the bucket's path convention is `{farm_id}/{task_id}/{photo_id}.webp`, the policy extracts the first path segment with Supabase's `storage.foldername(name)` helper and checks it against `farm_memberships` directly:

```sql
(storage.foldername(name))[1]::uuid IN (
  SELECT farm_id FROM farm_memberships WHERE user_id = auth.uid()
)
```

No join through `tasks` is needed — the farm scoping is fully encoded in the path, which is exactly why the path convention leads with `farm_id`. This is implemented as **four separate policies** (SELECT, INSERT, UPDATE, DELETE) rather than one `FOR ALL` policy, so that `WITH CHECK` is properly enforced on writes (INSERT/UPDATE) and not just `USING` on reads — matching Supabase's documented storage-policy pattern.

The bucket is named `task-photos`, mirroring the `task_photos` metadata table. Buckets are scoped to the Supabase project (not global like S3 bucket names), and since dev/test (Clarkson's Farm) and production (Reign Cloud Ranch) share one Supabase project, both farms' photos share this single bucket, separated by the `farm_id` path prefix and these policies. The concrete SQL lives in DATA_MODEL.md's Storage section.

## Dev/test farm shares the production Supabase project

Clarkson's Farm (the personal dev/test farm) and Reign Cloud Ranch (production) live in the same Supabase project rather than separate projects, keeping infrastructure to a single set of environment variables and a single place to run migrations. This trades away hard isolation between dev iteration and production data — a buggy migration or test script run against the wrong farm's data has real blast radius, mitigated only by RLS's farm-scoping and by discipline about which farm_id you're operating against locally. Revisit this if the app moves toward real monetization or additional trusted users, where a bad dev-side mistake touching production data becomes a materially bigger deal than it is today.

## Farm-membership check: query `farms` under RLS, not `farm_memberships`

M3's unrecognized-login gate needs to answer "does this authenticated user belong to any farm?". The membership middleware answers it by selecting from `farms` and checking whether any rows come back, rather than querying `farm_memberships` directly. The RLS policy on `farms` already restricts visibility to farms the user is a member of, so the two queries are equivalent — but the `farms` result doubles as the data the farm switcher and home view need anyway (id + name), so one query serves both purposes and the result is cached in shared state for the session.

A deliberate distinction rides along with this: **zero rows means no access; a query _error_ does not.** If the farms query fails outright (schema not yet migrated, network trouble), the middleware lets the user through to the page, which surfaces the error, instead of redirecting to `/no-access`. Misreporting an infrastructure failure as "you haven't been invited" would send the user chasing the farm owner for a problem membership can't fix — relevant right now, since the M2 migration hasn't been applied to the hosted project yet.

## Overdue-flag timezone semantics: device-local calendar date, not UTC

Resolved during M5. `due_date` is a plain `date` column with no timezone, so "overdue" needed a defined reference point to avoid an off-by-one-day bug. Resolved to the device's **local** calendar date: a task is overdue only once its due date is strictly before today's local date (due-today is not overdue), computed by formatting the current moment as a local `YYYY-MM-DD` string and comparing it against `due_date` lexically. This matches how a farm worker actually experiences "today" — the alternative (comparing against UTC midnight) would flip a task overdue up to several hours early or late depending on the user's timezone relative to UTC, which reads as a bug in a single-timezone farm-ops context where there's no cross-timezone user base to serve instead.

## Task list tiebreaker sort: oldest-created-first within a priority tier

Resolved during M5. Priority is the primary sort key (Urgent → Soon → Whenever), but ties within a tier needed a defined secondary order. Resolved to `created_at` ascending — the oldest task in a tier surfaces first, on the reasoning that an aging urgent task deserves more visual priority than one just added, and this avoids the list silently reordering itself as new same-priority tasks are created (which a `created_at` descending or an unstable sort would both do). The comparator (`compareTasks` in `app/services/tasks.ts`) also breaks any remaining tie by `id` for a fully deterministic order, since a real timestamp collision — however unlikely — shouldn't leave row order undefined.

## Task deletion: confirmation dialog required, no undo

Resolved during M5. Task deletion is a real, irreversible hard `DELETE` with no soft-delete or recovery path (see the hard-delete decision above). The UI requires an explicit confirm-dialog step before deleting ("Delete “<title>”? This can't be undone."), matching the pattern already established for category soft-deletion in M4, rather than deleting immediately on the first click. Given there's no undo and the audit trail is `activity_log`-only (not a restorable history), a single accidental click permanently losing a task's title/notes/history was judged worse than the extra tap a confirmation costs.

## Mapbox usage tier: free-tier headroom is ample at expected scale

Resolved 2026-07-03 (during M7), closing the open question above the same way the Supabase Storage check was done for photos. Serving raster tiles from a Mapbox style into Leaflet (as `app/utils/map-tiles.ts` does) bills against the Static Tiles API, whose free tier is **200,000 tile requests/month** (per mapbox.com/pricing as of this writing; the more widely quoted 50,000 free "map loads" tier applies to Mapbox GL JS, not to XYZ raster consumption). Expected usage — two farms, two users, a few map/mini-map sessions a day at roughly 30–100 tiles per session — lands around a few thousand tiles a month, two orders of magnitude under the cap. Even a 10× misestimate stays comfortably free. Two mitigations ride along at zero cost: browser tile caching (repeat visits to the same farm view mostly re-serve cached tiles), and the OSM street layer fallback, which costs nothing against Mapbox at all. No paid tier or usage alerting is warranted at this scale; revisit only if the app gains real multi-tenant usage.

## Tag matching: case-insensitive in application code, not the database

Resolved during M6. SPEC.md's stated goal for tag autocomplete is reducing near-duplicate tags like "fence" vs. "fencing" — the same reasoning extends to pure case variants ("Fence" vs. "fence"), which autocomplete alone doesn't prevent if a user ignores the suggestion list and just types. The `tags` table's `unique(farm_id, name)` constraint is case-sensitive (`text` comparison), and Postgres `.in('name', [...])` filters are likewise case-sensitive, so neither the DB constraint nor a straightforward query can dedupe "Fence" against an existing "fence" row. `resolveTags` (`app/services/tags.ts`) instead fetches the farm's full tag list and matches candidate names against it case-insensitively in JS, preserving whichever casing already exists in the DB when reusing a tag and the first-seen casing when creating a new one. This trades a bit of query efficiency (one extra `listTags` call per resolve, already cheap at this app's per-farm tag volumes) for actually meeting the near-duplicate-reduction goal, rather than technically satisfying "autocomplete exists" while leaving a casing-based loophole.
