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

## M4 — Category Management

**Goal:** Per-farm categories can be created and soft-deleted, so the task creation form (M5) has something real to select from. Split out from the original "Core Task CRUD" milestone since it's a self-contained feature and Task's `category_id` is a required field — categories need to exist first.

- Category management UI: create a new category, view existing per-farm categories
- Soft-delete: blocked while any active (`Not Started` / `In Progress`) task references the category. Since M5's tasks don't exist yet, cover this guard with a unit/service-layer test against seeded data rather than the UI (also called out as a priority test area in ARCHITECTURE.md)
- `activity_log` entries for `category_created` and `category_deleted` events
- Categories list scoped to the active farm (per the farm switcher from M3)

**Done when:** categories can be created and soft-deleted for the active farm, the active-task deletion guard is enforced and unit-tested, and both events land in `activity_log`.

## M5 — Core Task CRUD (List View)

**Goal:** Tasks can be created, viewed, edited, and deleted, in list form, without tags, location, or photos yet.

- Task creation form: required fields (Title, Category, Priority) with "More details" expand for Notes, Due date (Tags added in M6)
- Task list view: sorted by priority, filterable by category, shows status
- Task editing: full expanded-fields view
- Status transitions: Not Started / In Progress / Done, with `completed_at` set/cleared correctly
- Overdue flagging for tasks with a passed due date
- Hard delete with corresponding `activity_log` entry

**Done when:** a full task lifecycle — create, edit, change status, delete — works correctly against Supabase, respecting RLS, with activity log entries generated for create/status-change/delete events.

## M6 — Tags & Autocomplete

**Goal:** Tasks can be tagged with freeform, autocompleted tags.

- Tags field added to the task creation "More details" expand and to the task editing view
- Autocomplete suggestions drawn from existing per-farm tags (`tags` + `task_tags`)
- Entering new tag text creates a new per-farm `tags` row on save

**Done when:** tags can be added to a task at creation or edit time, autocomplete surfaces existing per-farm tags, and near-duplicate tags are reduced via the suggestion list.

## M7 — Location & Map View

**Goal:** Tasks can have a location, and the map view is functional.

- GPS auto-capture on task creation, shown on a mini-map for confirm/adjust before save
- Manual pin placement fallback when GPS is unavailable/denied
- Location editable after task creation
- Map view: Mapbox Satellite hybrid tiles with street/OSM toggle
- Pins rendered per task; tapping a pin opens the task

**Done when:** you can create a task from the field with an accurate captured location, see it correctly placed on the map view, and tap it to open the task.

## M8 — Photos

**Goal:** Tasks can have photos attached, compressed appropriately.

- Camera capture and gallery upload both supported
- Client-side compression pipeline (resize to 1600px max edge, WebP conversion) before upload
- Caption and timestamp stored per photo
- Photos displayed on the task detail view

**Done when:** a photo taken on a mobile device is compressed, uploaded, and displayed correctly, staying within the ~500 KB–1 MB target size.

## M9 — Polish & Hardening

**Goal:** MVP is genuinely usable day-to-day, not just feature-complete.

- Mobile responsiveness pass across all views
- Empty states (no tasks, no categories, no photos, etc.)
- Loading/error states throughout
- Unit/component test coverage for the priority areas listed in ARCHITECTURE.md
- STATUS.md reflects actual current state

**Done when:** you'd be comfortable using this as your actual daily task tracker for Reign Cloud Ranch.

### Backlog items (collected 2026-07-06)

Specific, scoped items from a brainstorming pass, each small enough to land as its own PR per the "not a single PR" note above:

- **Done (2026-07-06): Material Design FAB on home page** — a fixed bottom-right floating `mdi-plus` button on `/` linking to `/tasks/new`, shifted up on mobile to clear the bottom nav bar.
- **Done (2026-07-06): Move the "UI components demo" link out of the footer** — moved from `AppFooter.vue` into the authenticated nav drawer (`app/layouts/default.vue`). The footer/link is kept only on the `blank` layout (login/confirm/no-access), since those pages have no nav drawer to hold it.
- **Done (2026-07-06): Larger buttons on task-management actions** — New task, Edit, Save, Cancel, and Delete buttons across `/`, `/tasks`, and the task view/edit/create pages bumped to `size="large"`; the home list's per-row status-advance icon button dropped its `size="small"` to the default (larger) size.
- **Done (2026-07-06): Nav drawer moves from left to right** — a right-handed-user preference. `v-navigation-drawer` (`app/layouts/default.vue`) gained `location="end"`, and the hamburger trigger moved from the app bar's `#prepend` slot to `#append` so it opens from and is triggered from the right.
- **Done (2026-07-06): New Tags page** — a read-only `/tags` page listing every tag on the active farm with a usage count (number of tasks tagged with it), following `/categories`' layout/empty/error-state patterns. `listTagsWithCounts` (`app/services/tags.ts`) adds the count via the existing two-sequential-query style. Linked from the nav drawer alongside "Categories".
- **Done (2026-07-06): Icon accessibility pass (home page)** — the home list's previously-bare status/location/photo/priority icons (`app/pages/index.vue`) gained `aria-label`/`title`. Icons elsewhere already sit next to visible text (chips, list items) and were left as-is since that text already carries the meaning.
- **Done (2026-07-06): Standardize tag naming convention** — resolved to **lowercase, spaces allowed** (e.g. "fence repair", not "fence-repair" or "Fence Repair"). `resolveTags` (`app/services/tags.ts`) now normalizes candidate names (lowercase, trimmed, internal whitespace collapsed) before matching/creating, so the stored name itself is always the normalized form rather than preserving first-seen casing. A new migration (`supabase/migrations/20260706150000_normalize_tag_names.sql`) backfills existing tag rows, merging any tags that collide once normalized. See DECISIONS.md for the tag-matching background this extends and the merge algorithm.
- **Done (2026-07-09): Ranch UI rework** — replaced the four equipment-brand Vuetify themes and `/settings` page with a single warm "ranch" design system (`app/assets/css/main.css`, one `ranch` Vuetify theme, Zilla Slab + Inter fonts). Custom app header replaces `v-app-bar`; home queue renders via `TaskCard` (priority-ring complete checkbox, priority/due pills, location/photo meta) with a pill-style "+ New chore" FAB; task View page sections, list pages, and auth/empty states adopt shared `cc-card`/`cc-pill`/`cc-eyebrow` styling. Home complete action now marks a task done directly (was start → mark done). See DECISIONS.md for why the multi-theme system was retired.

Unlike prior milestones, this one is not intended to land as a single PR — "across all views" and "throughout" mean it naturally decomposes into one PR per problem area (e.g. a mobile-responsiveness pass, an empty-states pass, an error-states pass). Track sub-scope informally in STATUS.md as each lands rather than holding it open as one branch.

---

Milestones beyond M9 (named locations, boundaries, recurring tasks, pasture module, etc.) live in ROADMAP.md and will get their own milestone breakdowns when prioritized.
