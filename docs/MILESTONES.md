# Chore Corral — Milestones

The ordered, scoped build plan to reach a working MVP. Each milestone has a concrete done-state. This mirrors the Durak Tracker M1/M2/M3 pattern, extended for this project's larger scope.

For the broader, less-ordered future feature list, see ROADMAP.md.

## M1 — Scaffold & Deploy

**Goal:** A minimal Nuxt + Vuetify app deployed to Vercel, connected to a Supabase project, with nothing functional yet beyond "it loads."

- Nuxt project initialized with `vuetify-nuxt-module`
- ESLint (`@nuxt/eslint`), Prettier, `vue-tsc`, Husky + lint-staged configured
- GitHub Actions CI pipeline (lint → typecheck → test → build) passing on an empty/trivial app
- Deployed to Vercel, connected to GitHub repo
- Supabase project created, environment variables wired (not yet used for real data)

**Done when:** a blank Vuetify-styled page is live at a Vercel URL, CI is green, and the repo has the doc set from `docs/` committed.

## M2 — Schema & Data Layer

**Goal:** The full schema from DATA_MODEL.md exists in Supabase, with RLS policies in place.

- All tables created: `farms`, `farm_memberships`, `categories`, `priorities`, `tasks`, `tags`, `task_tags`, `task_photos`, `activity_log`
- RLS enabled and policies applied per DATA_MODEL.md's farm-membership pattern
- The two initial farms (Reign Cloud Ranch, Clarkson's Farm) manually created
- Storage bucket created for photos, with matching access policies

**Done when:** schema is fully migrated, RLS policies are verified via Supabase's SQL editor (impersonating a test user's JWT), and both farms exist with at least one manually-added membership row each.

## M3 — Auth

**Goal:** Google OAuth login works end-to-end, including the unrecognized-login error state.

- Supabase Auth configured with Google OAuth provider
- Login flow implemented in Nuxt (likely via `@nuxtjs/supabase` module)
- Unrecognized-login state: a user with no `farm_memberships` row sees a clear, actionable error message (not a blank screen)
- Farm switcher UI scaffolded (even with only one farm to switch to initially)

**Done when:** you can log in with Google, land on an authenticated view scoped to your farm membership(s), and a test account with no membership sees the correct error state.

## M4 — Core Task CRUD (List View)

**Goal:** Tasks can be created, viewed, edited, and deleted, in list form, without location or photos yet.

- Task creation form: required fields (Title, Category, Priority) with "More details" expand for Notes, Tags, Due date
- Task list view: sorted by priority, filterable by category, shows status
- Task editing: full expanded-fields view
- Status transitions: Not Started / In Progress / Done, with `completed_at` set/cleared correctly
- Overdue flagging for tasks with a passed due date
- Hard delete with corresponding `activity_log` entry
- Category management: create, soft-delete (blocked while active tasks reference it)
- Tag autocomplete against existing per-farm tags

**Done when:** a full task lifecycle — create, edit, change status, delete — works correctly against Supabase, respecting RLS, with activity log entries generated for create/status-change/delete events.

## M5 — Location & Map View

**Goal:** Tasks can have a location, and the map view is functional.

- GPS auto-capture on task creation, shown on a mini-map for confirm/adjust before save
- Manual pin placement fallback when GPS is unavailable/denied
- Location editable after task creation
- Map view: Mapbox Satellite hybrid tiles with street/OSM toggle
- Pins rendered per task; tapping a pin opens the task

**Done when:** you can create a task from the field with an accurate captured location, see it correctly placed on the map view, and tap it to open the task.

## M6 — Photos

**Goal:** Tasks can have photos attached, compressed appropriately.

- Camera capture and gallery upload both supported
- Client-side compression pipeline (resize to 1600px max edge, WebP conversion) before upload
- Caption and timestamp stored per photo
- Photos displayed on the task detail view

**Done when:** a photo taken on a mobile device is compressed, uploaded, and displayed correctly, staying within the ~500 KB–1 MB target size.

## M7 — Polish & Hardening

**Goal:** MVP is genuinely usable day-to-day, not just feature-complete.

- Mobile responsiveness pass across all views
- Empty states (no tasks, no categories, no photos, etc.)
- Loading/error states throughout
- Unit/component test coverage for the priority areas listed in ARCHITECTURE.md
- STATUS.md reflects actual current state

**Done when:** you'd be comfortable using this as your actual daily task tracker for Reign Cloud Ranch.

---

Milestones beyond M7 (named locations, boundaries, recurring tasks, pasture module, etc.) live in ROADMAP.md and will get their own milestone breakdowns when prioritized.
