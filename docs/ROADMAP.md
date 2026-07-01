# Chore Corral — Roadmap

A lightweight, directional list of features and phases beyond MVP. This is intentionally low-ceremony — a running list to append to, not a detailed plan. For the concrete, ordered MVP build plan, see MILESTONES.md.

## Near-Term (Post-MVP)

- **Named/saved locations** — a defined set of named property locations (e.g. "Barn", "North Pond", "East Pasture") to tag tasks with, rather than freeform pins only. Likely the natural predecessor to boundary polygons below.
- **Multiple location pins per task** — e.g. a fence repair spanning several points. Requires extracting task location into its own table (see DATA_MODEL.md).
- **Esri World Imagery comparison** — try Esri's satellite tiles alongside Mapbox and compare resolution/quality over this specific property, given Esri's ag-sector focus.

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
