# Chore Corral — Decisions

A running log of the reasoning behind non-obvious choices made during planning. This complements PR descriptions (which document the agentic development process per-change) by capturing project-level "why" in one place, rather than scattered across individual PRs.

## Stack: Nuxt + Vuetify (diverging from Durak Tracker's Next.js/React)

Chosen deliberately to diversify framework depth rather than repeat the Next.js/React stack. Two factors drove this:
1. **Genuine learning value** — Vue's reactivity model and Nuxt's data-fetching conventions (loaders, composables) are architecturally distinct from React/Next, not just a syntax reskin.
2. **Portfolio credibility** — prior professional exposure to Vue (adjacent, not hands-on) meant Nuxt could convert that into demonstrable, shipped ownership, strengthening a multi-framework portfolio narrative for EM roles rather than showing depth in only one stack.

React remains the more market-dominant framework for EM hiring signal purposes, but depth across two frameworks (Next AND Nuxt) was judged a stronger signal of adaptability than repeated depth in one.

Vuetify was chosen over Nuxt UI, PrimeVue, and Quasar specifically for its Material Design foundation, given an explicit preference for Material's simplicity and mobile-friendliness, and its official, well-maintained Nuxt integration.

## Staying on Vercel + Supabase (not evaluating new hosting/DB platforms)

Explicitly ruled out setting up new accounts/infrastructure for this project. This kept the stack-selection conversation scoped to frontend framework and library choices rather than re-litigating hosting/backend platform choices already validated by Durak Tracker.

## Database: Postgres (no alternative DB considered)

Supabase's value (auto-generated APIs, RLS, Auth, Realtime, Storage) is built directly on Postgres internals — swapping the database engine isn't really separable from swapping Supabase itself, which would contradict the "no new infrastructure" constraint. Where a real decision existed, it was about Postgres *extensions* (PostGIS for future boundary/geospatial work) rather than a different database engine entirely.

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
