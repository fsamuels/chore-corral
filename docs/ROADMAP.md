# Chore Corral — Roadmap

A lightweight, directional list of features and phases beyond MVP. This is intentionally low-ceremony — a running list to append to, not a detailed plan. For the concrete, ordered MVP build plan, see MILESTONES.md.

## Near-Term (Post-MVP)

- **Task estimated time** — **Done (2026-07-06).** An optional field on a task for how long it's expected to take, set at creation/edit time (a plain user estimate, not derived from anything). Stored as `tasks.estimated_minutes` (nullable integer), named to pair with the future actual-time feature below.
- **Task actual time via in-app start/stop timer** — a separate, distinct feature from the estimate above: start/stop a timer while actively working a task, with the actual elapsed time tracked from those sessions. A task could be started/stopped multiple times across sessions, so this likely needs its own time-entry log rather than a single duration field on `tasks` — scope the data model out properly before building. Once both exist, the task view can show estimated vs. actual side by side.
- **Optional shopping list per task** — **Done (2026-07-06).** A task can carry an optional list of items to buy for it (e.g. parts, supplies), checked off independently of the task's own status. Modeled as its own feature/table (`task_shopping_items`) rather than reusing the tags or notes fields.
- **Optional tool list per task** — a task can carry an optional list of tools needed to do it, checked off independently of task status. Structurally similar to the shopping list above but kept as a separate concept per an explicit choice not to unify them, in case the two diverge later (e.g. a shopping list wanting price/store fields a tool list wouldn't need).
- **Named/saved locations** — a defined set of named property locations (e.g. "Barn", "North Pond", "East Pasture") to tag tasks with, rather than freeform pins only. Likely the natural predecessor to boundary polygons below.
- **Multiple location pins per task** — e.g. a fence repair spanning several points. Requires extracting task location into its own table (see DATA_MODEL.md).
- **Esri World Imagery comparison** — try Esri's satellite tiles alongside Mapbox and compare resolution/quality over this specific property, given Esri's ag-sector focus.
- **Automated migrations in the deploy pipeline** — migrations currently have to be applied from a local machine (`supabase db push` / `supabase migration up` with the linked project). Add a GitHub Actions job that runs pending migrations from `supabase/migrations/` against the Supabase project on merge to `main` (using the Supabase CLI with `SUPABASE_ACCESS_TOKEN` + `SUPABASE_DB_PASSWORD` repo secrets), so deploys don't depend on anyone remembering to run migrations by hand. Worth sequencing carefully with Vercel deploys: the migration job should complete before (or gate) the app deploy that depends on the new schema.

## Medium-Term

- **Property boundaries & area measurement** — draw pasture/field/property boundaries and calculate area. Requires PostGIS on the database side and Leaflet.draw + Turf.js on the frontend (both already anticipated in ARCHITECTURE.md).
- **Recurring/repeating tasks** — farm work often repeats (mow every 2 weeks, check fence monthly). Deferred from MVP to keep the initial task model simple.
- **Roles & permissions within a farm** — currently all farm members have equal access; owner/member distinction (e.g. who can remove people from a farm) may become relevant if farms grow beyond two trusted users.
- **In-app farm invite flow** — generate an invite link/code so new members can join a farm without manual database provisioning.

## Longer-Term / Exploratory

- **Pasture Maintenance Tracking** — a separate module from the task tracker: a history/log per pasture rather than a to-do item. Fields anticipated:
  - Watering events (date, duration/amount)
  - Rest periods (date range, which pasture, duration)
  - Overseeding (date, what was seeded)
  - Aeration (date)
  - Mowing (date)

  This needs its own data model — a pasture as an entity with a timestamped event log — kept deliberately separate from the task tracker's single-task structure so the two don't become tangled.

- **Offline support** — relevant given the rural, potentially spotty-connectivity context, but has real architectural implications (PWA offline caching, optimistic UI, sync conflict handling) and is explicitly a "well into the future" item, not a near-term one.
- **PWA install-to-homescreen** — nice-to-have once the app is otherwise stable.
- **Photo storage management strategy** — revisit if photo volume grows well beyond current projections (see DECISIONS.md for the current cost analysis); could include auto-archival or deletion tied to task completion.

## Explicit Non-Goals (Not on this roadmap at all)

Carried over from SPEC.md for visibility — these are deliberate exclusions, not just low-priority items:

- Crop rotation / field-planning
- Spray-compliance / audit reporting
- Farm orphan cleanup/deletion handling
