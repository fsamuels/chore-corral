# Chore Corral — Data Model

This document describes the Postgres schema (via Supabase) underlying Chore Corral: tables, relationships, and Row Level Security (RLS) policy intent. It complements ARCHITECTURE.md, which covers _why_ RLS was chosen as the enforcement layer; this doc focuses on _what_ the schema actually looks like.

All tables live in Postgres, managed via Supabase. The schema is implemented as versioned Supabase CLI migration files under `supabase/migrations/` (applied with `supabase db push`) — the M2 migration is the authoritative SQL; this doc describes intent and relationships.

## Entity Relationship Overview

```
users (Supabase Auth managed)
  │
  │  many-to-many
  ▼
farm_memberships ──────► farms
                            │
                            │ one-to-many
                            ▼
                          categories ──┐
                            │          │ referenced by
                          locations ───┤
                            │          ▼
                            │        tasks ──┬──► task_photos
                            │          │      ├──► task_shopping_items
                            │          │      ├──► task_tools
                            │          │      ├──► task_time_entries
                            │          │      ├──► task_completers
                            │          │      └──► task_tags ──► tags
                            │          │
                            │          └──► activity_log
                            ▼
                        (tags are per-farm, not per-category)
```

## Tables

### `farms`

The top-level tenant entity.

| Column        | Type                       | Notes                               |
| ------------- | -------------------------- | ----------------------------------- |
| `id`          | uuid, PK                   |                                     |
| `name`        | text, not null             |                                     |
| `address`     | text, nullable             | Free text for MVP                   |
| `default_lat` | numeric, nullable          | Manually set at farm creation (MVP) |
| `default_lng` | numeric, nullable          | Manually set at farm creation (MVP) |
| `created_at`  | timestamptz, default now() |                                     |

No `deleted_at` or soft-delete column — farm deletion/orphan handling is explicitly out of scope for MVP (see SPEC.md non-goals).

### `farm_memberships`

Join table for the many-to-many user↔farm relationship.

| Column       | Type                                           | Notes                               |
| ------------ | ---------------------------------------------- | ----------------------------------- |
| `id`         | uuid, PK                                       |                                     |
| `farm_id`    | uuid, FK → `farms.id`, not null                |                                     |
| `user_id`    | uuid, FK → `auth.users.id`, not null           | Supabase-managed auth table         |
| `role`       | `farm_role` enum, not null, default `'member'` | `'owner'` or `'member'` — see below |
| `created_at` | timestamptz, default now()                     |                                     |

Unique constraint on (`farm_id`, `user_id`) — a user can't be added to the same farm twice.

`role` (migration `20260718120000_farm_invites_roles_and_signup.sql`) is a Postgres enum:

```sql
CREATE TYPE farm_role AS ENUM ('owner', 'member');
```

It gates one thing only — invite management via `farm_invites` (below); task-level access is unaffected by role and stays equal for every member (SPEC.md). Every membership row that predated this migration was backfilled to `'owner'`, since those rows were provisioned by hand and are the de facto owners of their farms. `create_farm()` grants `'owner'` to a farm's creator; `accept_farm_invites()` grants whatever role the accepted invite specifies (currently always `'member'` — see `farm_invites`).

### `farm_invites`

Email pre-authorization for joining a farm — no invite emails are sent. An owner records an email address; whoever next signs in with Google using that exact address is auto-joined via `accept_farm_invites()` (see Functions below).

| Column        | Type                                           | Notes                                                                                                                                                                                                  |
| ------------- | ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `id`          | uuid, PK                                       |                                                                                                                                                                                                        |
| `farm_id`     | uuid, FK → `farms.id`, not null                |                                                                                                                                                                                                        |
| `email`       | text, not null                                 | Stored trimmed + lowercased (the app normalizes before insert; `CHECK`s backstop both the normalization and a minimal `@`/length shape), so acceptance is a plain equality match against the JWT email |
| `role`        | `farm_role` enum, not null, default `'member'` | Role the invitee joins with once accepted                                                                                                                                                              |
| `invited_by`  | uuid, FK → `auth.users.id`, not null           |                                                                                                                                                                                                        |
| `created_at`  | timestamptz, default now()                     |                                                                                                                                                                                                        |
| `accepted_at` | timestamptz, nullable                          | Null = pending. `CHECK` requires `accepted_at`/`accepted_by` to be both null or both set                                                                                                               |
| `accepted_by` | uuid, FK → `auth.users.id`, nullable           |                                                                                                                                                                                                        |

**At most one pending invite per (`farm_id`, `email`)**, via a partial unique index on `(farm_id, email) WHERE accepted_at IS NULL` — accepted invites are kept as history and don't block re-inviting the same address later (e.g. after a member is removed). A second partial index on `email WHERE accepted_at IS NULL` keeps `accept_farm_invites()`'s per-session lookup off a sequential scan.

**RLS:** owners of the farm (`role = 'owner'` in `farm_memberships`) can `SELECT`/`INSERT` invites for their farm, and `DELETE` (= revoke) a _pending_ invite only — accepted invites can't be deleted from the client. There is no `UPDATE` policy at all; acceptance happens exclusively inside the `accept_farm_invites()` security-definer function below, never via a client-side update.

### `categories`

Per-farm, user-editable task categories.

| Column       | Type                            | Notes                                                             |
| ------------ | ------------------------------- | ----------------------------------------------------------------- |
| `id`         | uuid, PK                        |                                                                   |
| `farm_id`    | uuid, FK → `farms.id`, not null | Scopes category to one farm                                       |
| `name`       | text, not null                  |                                                                   |
| `emoji`      | text, nullable                  | Optional decorative emoji; `CHECK` `char_length` between 1 and 16 |
| `deleted_at` | timestamptz, nullable           | Soft delete only — null = active                                  |
| `created_at` | timestamptz, default now()      |                                                                   |

The optional `emoji` is purely decorative — shown in the category picker and, on the home screen, inside each task card's circular start-timer button so a category is recognizable at a glance. The length cap (`categories_emoji_length`) keeps it to a single emoji, which can itself be several codepoints (ZWJ sequences, flags), rather than an arbitrary string.

**Constraint (application-enforced, not DB-enforced):** a category cannot be soft-deleted while any task referencing it has `status != 'done'`. This check happens in application code at delete-time (see ARCHITECTURE.md for the app-layer vs. RLS authorization split).

A task with no category set represents "Uncategorized" — this is `category_id IS NULL` on the `tasks` table, not a real row in this table.

### `locations`

Per-farm defined locations — reusable named places with coordinates (e.g. Shop, Front Barn, Back Barn) that a task can point at instead of dropping a one-off `lat`/`lng` pin. Farm-scoped and soft-deletable, structurally parallel to `categories`.

| Column       | Type                            | Notes                            |
| ------------ | ------------------------------- | -------------------------------- |
| `id`         | uuid, PK                        |                                  |
| `farm_id`    | uuid, FK → `farms.id`, not null | Scopes location to one farm      |
| `name`       | text, not null                  |                                  |
| `lat`        | numeric, **not null**           | Single point — always set        |
| `lng`        | numeric, **not null**           |                                  |
| `deleted_at` | timestamptz, nullable           | Soft delete only — null = active |
| `created_at` | timestamptz, default now()      |                                  |

Unlike `tasks.lat`/`lng` (an optional both-or-neither pin), a defined location always has a point, so `lat`/`lng` are `NOT NULL` here.

**Uniqueness:** a partial unique index on (`farm_id`, `lower(name)`) `WHERE deleted_at IS NULL` makes names case-insensitively unique per farm among active rows — `categories` has no such constraint, but a location is a picker where duplicate names are confusing, so this one adds it. A soft-deleted name can be reused.

**Constraint (application-enforced, not DB-enforced):** a location cannot be soft-deleted while any task referencing it (`tasks.location_id`) has `status != 'done'`. This check happens in application code at delete-time (`services/locations.ts`), mirroring the `categories` delete guard.

### Priority (enum, not a table)

Global, fixed priority tiers — **not** scoped to a farm, **not** a separate table.

Implemented as a Postgres enum type, declared in ascending-urgency order so `ORDER BY priority DESC` gives the correct default sort (Urgent first) for free:

```sql
CREATE TYPE task_priority AS ENUM ('whenever', 'soon', 'urgent');
```

No admin tooling is planned to manage priorities as data, so a lookup table's flexibility isn't needed — see DECISIONS.md.

### `tasks`

The core work-item entity.

| Column              | Type                                                                            | Notes                                                                                                                                                                                                                                                                                       |
| ------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                | uuid, PK                                                                        |                                                                                                                                                                                                                                                                                             |
| `farm_id`           | uuid, FK → `farms.id`, not null                                                 |                                                                                                                                                                                                                                                                                             |
| `title`             | text, not null                                                                  |                                                                                                                                                                                                                                                                                             |
| `category_id`       | uuid, FK → `categories.id`, nullable                                            | Null = Uncategorized                                                                                                                                                                                                                                                                        |
| `priority`          | `task_priority` enum, not null                                                  | See Priority section above                                                                                                                                                                                                                                                                  |
| `status`            | `task_status` enum, not null, default 'not_started'                             | Values: `not_started`, `in_progress`, `done`                                                                                                                                                                                                                                                |
| `due_date`          | date, nullable                                                                  |                                                                                                                                                                                                                                                                                             |
| `notes`             | text, nullable                                                                  | Single free-text field                                                                                                                                                                                                                                                                      |
| `lat`               | numeric, nullable                                                               | Freeform location pin (MVP)                                                                                                                                                                                                                                                                 |
| `lng`               | numeric, nullable                                                               |                                                                                                                                                                                                                                                                                             |
| `location_id`       | uuid, FK → `locations.id`, nullable                                             | Optional defined location (see `locations`). Mutually exclusive with the freeform `lat`/`lng` pin — see the constraint below.                                                                                                                                                               |
| `created_at`        | timestamptz, default now()                                                      |                                                                                                                                                                                                                                                                                             |
| `created_by`        | uuid, FK → `auth.users.id`, not null                                            | For activity log / attribution, not for access control (all members have equal access)                                                                                                                                                                                                      |
| `completed_at`      | timestamptz, nullable                                                           | Set when status → done; **cleared** when status moves out of done                                                                                                                                                                                                                           |
| `estimated_minutes` | integer, nullable, `CHECK (estimated_minutes IS NULL OR estimated_minutes > 0)` | Optional user-entered estimate of how long the task should take, in whole minutes, set at create/edit time. Null = no estimate (no backfill, no default). Distinct from a future timer-measured "actual" counterpart (e.g. `actual_minutes`) that a separate feature will add alongside it. |

**No `deleted_at`** — tasks are hard-deleted per SPEC.md. Deletion produces an `activity_log` entry as the only remaining trace.

**Constraint (DB-enforced): a task has a defined location OR a freeform pin, never both.** `CHECK (location_id IS NULL OR (lat IS NULL AND lng IS NULL))` — setting `location_id` requires `lat`/`lng` to be null, and vice versa. The app layer enforces the same rule up front (`assertLocationXorPin` in `services/tasks.ts`) so bad combinations fail with a readable message instead of a Postgres error. The freeform pin remains for ad-hoc spots that aren't worth naming; a defined location is a reusable named place (see `locations`).

**Completion attribution lives in `task_completers`, not on this table.** `tasks` originally carried `completed_by` (uuid) / `completed_by_name` (text) scalar columns, mutually exclusive via a `tasks_completed_by_xor_name` CHECK, crediting at most one person per task. Migration `20260715120000_task_completers.sql` backfilled both columns into the new `task_completers` join table (below) and dropped them, so a task can now be credited to any number of people. See `task_completers` for the current shape and DECISIONS.md for why.

**On multiple location pins:** the schema currently supports exactly one pin (`lat`/`lng` columns directly on `tasks`). If/when multiple pins per task becomes a real feature (see ROADMAP.md), this will require extracting location into a separate `task_locations` table with a one-to-many relationship — a real migration, not a config change. Worth keeping in mind if location-pin UI is built in a way that assumes a list rather than a single point, to ease that future migration.

### `tags`

Per-farm freeform tags.

| Column       | Type                            | Notes                                              |
| ------------ | ------------------------------- | -------------------------------------------------- |
| `id`         | uuid, PK                        |                                                    |
| `farm_id`    | uuid, FK → `farms.id`, not null | Tags are scoped per farm for autocomplete purposes |
| `name`       | text, not null                  |                                                    |
| `created_at` | timestamptz, default now()      |                                                    |

Unique constraint on (`farm_id`, `name`) — avoids duplicate tags within a farm; autocomplete queries against this table filtered by `farm_id`. `name` is stored normalized — lowercase, internal whitespace collapsed to single spaces (e.g. "fence repair") — per the naming-convention decision in DECISIONS.md.

### `task_tags`

Join table for the many-to-many task↔tag relationship.

| Column    | Type                            | Notes |
| --------- | ------------------------------- | ----- |
| `task_id` | uuid, FK → `tasks.id`, not null |       |
| `tag_id`  | uuid, FK → `tags.id`, not null  |       |

Composite PK on (`task_id`, `tag_id`).

### `task_completers`

Who actually did the work — a set, not a single credit. Replaces the two scalar columns described under `tasks` above; a task's completer set may freely mix app members and free-text names.

| Column           | Type                                 | Notes                                                                                                  |
| ---------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| `id`             | uuid, PK                             |                                                                                                        |
| `task_id`        | uuid, FK → `tasks.id`, not null      | `ON DELETE CASCADE` with the task                                                                      |
| `user_id`        | uuid, FK → `auth.users.id`, nullable | A farm member credited with finishing the task                                                         |
| `completer_name` | text, nullable                       | Free-text credit for whoever finished the task but isn't an app user (a contractor, a kid, a neighbor) |

**Per-row XOR: `CHECK ((user_id IS NULL) <> (completer_name IS NULL))`** — every row is exactly one of a member or a free-text name, never both and never neither. The app layer enforces the same rule up front (`assertValidCompleters` in `services/completers.ts`) so a bad combination fails with a readable message before the Postgres constraint fires. This XOR is per-row only — the composition of a task's whole completer set is unconstrained, so mixing members and free-text names on the same task is allowed (unlike the task-level XOR it replaced).

**No duplicates within a task's set**, enforced by two partial unique indexes rather than a single composite one (since `user_id`/`completer_name` are never both non-null on the same row, a shared index couldn't do this): `task_completers_task_user_uniq` on (`task_id`, `user_id`) `WHERE user_id IS NOT NULL`, and `task_completers_task_name_uniq` on (`task_id`, `completer_name`) `WHERE completer_name IS NOT NULL`.

Like the other task-child tables, this table carries no `farm_id`; it is scoped to a farm through its parent task, and its RLS policy joins through `tasks` (`auth.uid()` wrapped in a scalar subselect so it's evaluated once per statement, not once per row — same pattern as elsewhere). `setTaskCompleters` (`services/completers.ts`) replaces a task's whole completer set in one call, patterned on how `task_tags` is written.

**Auto-credit behavior:** marking a task done credits the acting member only if the task has zero completers already; leaving done deletes the whole set. Attribution stays optional — a done task may legitimately have zero completers. See DECISIONS.md.

### `task_photos`

| Column         | Type                            | Notes                           |
| -------------- | ------------------------------- | ------------------------------- |
| `id`           | uuid, PK                        |                                 |
| `task_id`      | uuid, FK → `tasks.id`, not null |                                 |
| `storage_path` | text, not null                  | Path in Supabase Storage bucket |
| `caption`      | text, nullable                  |                                 |
| `taken_at`     | timestamptz, default now()      | Auto-captured at upload time    |

Actual image files live in Supabase Storage (a bucket, RLS-scoped by farm via the associated task), not in the database — this table stores metadata and the storage reference only.

### `task_shopping_items`

Optional per-task shopping list — items to buy for a task (parts, supplies), each independently checkable. A task may have zero such items (the feature is opt-in).

| Column       | Type                             | Notes                               |
| ------------ | -------------------------------- | ----------------------------------- |
| `id`         | uuid, PK                         |                                     |
| `task_id`    | uuid, FK → `tasks.id`, not null  | `ON DELETE CASCADE` with the task   |
| `name`       | text, not null                   | Free-text item description          |
| `checked`    | boolean, not null, default false | Per-item bought/not-bought toggle   |
| `created_at` | timestamptz, default now()       | Insertion order = stable list order |

Like `task_tags` and `task_photos`, this table carries no `farm_id`; it is scoped to a farm through its parent task, and its RLS policy joins through `tasks`. No unique constraint on (`task_id`, `name`) — duplicate item names on the same task are intentionally allowed (e.g. two separate "bolts" line items). Items are listed per task in insertion order: `ORDER BY created_at ASC, id ASC` (the `id` tiebreaker keeps order deterministic if rows are ever bulk-inserted in one transaction, where `created_at` values would be identical).

### `task_tools`

Optional per-task tool list — tools needed to do a task (e.g. chainsaw, post driver), each independently checkable. A task may have zero such items (the feature is opt-in). Structurally identical to `task_shopping_items` but deliberately a separate table — see DECISIONS.md.

| Column       | Type                             | Notes                               |
| ------------ | -------------------------------- | ----------------------------------- |
| `id`         | uuid, PK                         |                                     |
| `task_id`    | uuid, FK → `tasks.id`, not null  | `ON DELETE CASCADE` with the task   |
| `name`       | text, not null                   | Free-text tool description          |
| `checked`    | boolean, not null, default false | Per-item ready/not-ready toggle     |
| `created_at` | timestamptz, default now()       | Insertion order = stable list order |

Like `task_shopping_items`, this table carries no `farm_id`; it is scoped to a farm through its parent task, and its RLS policy joins through `tasks`. No unique constraint on (`task_id`, `name`) — duplicate tool names on the same task are intentionally allowed. Items are listed per task in insertion order: `ORDER BY created_at ASC, id ASC` (the `id` tiebreaker keeps order deterministic if rows are ever bulk-inserted in one transaction, where `created_at` values would be identical).

### `task_time_entries`

Per-task time tracking: one row per start/stop timer session. A task's "actual" time is **derived** — the sum of `ended_at - started_at` across its entries (a running entry counts up to now) — deliberately not denormalized into an `actual_minutes` column on `tasks`, so there's nothing to keep in sync. Displayed beside `tasks.estimated_minutes` as actual-vs-estimate.

| Column       | Type                                 | Notes                                                                                   |
| ------------ | ------------------------------------ | --------------------------------------------------------------------------------------- |
| `id`         | uuid, PK                             |                                                                                         |
| `task_id`    | uuid, FK → `tasks.id`, not null      | `ON DELETE CASCADE` with the task                                                       |
| `user_id`    | uuid, FK → `auth.users.id`, not null | Who ran the timer — attribution when two people work the same task                      |
| `started_at` | timestamptz, not null, default now() |                                                                                         |
| `ended_at`   | timestamptz, nullable                | **Null = timer currently running.** `CHECK (ended_at IS NULL OR ended_at > started_at)` |
| `created_at` | timestamptz, default now()           |                                                                                         |

**One running timer per user, farm-wide** (the Toggl model), enforced by a partial unique index on `user_id` where `ended_at IS NULL`. Application code auto-stops the user's running entry when they start a timer on another task; the index is the backstop against races.

Behavior decisions (see DECISIONS.md):

- Starting a timer on a `not_started` task flips it to `in_progress` (with the normal `task_status_changed` activity-log entry). The link is one-way: stopping never touches status, and marking a task done does not auto-stop timers.
- Timer start/stop is **not** an `activity_log` event — the log is major-events-only, and the entries table is its own record.
- Manual add/edit of entries ("forgot to start the timer") is out of scope for now, but needs no future migration — it's just inserting a row with both timestamps set.

Like the other task-child tables, this table carries no `farm_id`; it is scoped to a farm through its parent task, and its RLS policy joins through `tasks`. Entries are listed per task oldest-session-first: `ORDER BY started_at ASC, id ASC`.

### `activity_log`

Major-event-only log, per SPEC.md (not a full audit trail).

| Column          | Type                                 | Notes                                                                                                                                                                                                                                                                                                                                                                                                       |
| --------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`            | uuid, PK                             |                                                                                                                                                                                                                                                                                                                                                                                                             |
| `farm_id`       | uuid, FK → `farms.id`, not null      | Denormalized for query convenience even though most events reference a task                                                                                                                                                                                                                                                                                                                                 |
| `task_id`       | uuid, nullable, **no FK constraint** | Soft reference only — deliberately not enforced at the DB level, since a deleted task's row no longer exists but its log entries must survive                                                                                                                                                                                                                                                               |
| `event_type`    | text, not null                       | `task_created`, `task_status_changed`, `task_priority_changed`, `task_due_date_changed`, `task_deleted`, `category_created`, `category_deleted`, `location_created`, `location_deleted`                                                                                                                                                                                                                     |
| `event_detail`  | jsonb, not null                      | Always includes a name snapshot plus event-specific context (e.g. old/new status): task events snapshot `task_title`, category events (`task_id` null) snapshot `category_id`/`category_name`, location events (`task_id` null) snapshot `location_id`/`location_name`. Snapshotting on every row means log entries stay readable without a join back to a row that may be deleted (or soft-deleted) later. |
| `actor_user_id` | uuid, FK → `auth.users.id`, not null | Who performed the action                                                                                                                                                                                                                                                                                                                                                                                    |
| `created_at`    | timestamptz, default now()           |                                                                                                                                                                                                                                                                                                                                                                                                             |

**Resolved: task_id is a soft reference, not a hard FK.** `task_id` is a plain `uuid` column with no foreign key constraint, so a hard-deleted task never orphans or cascades against its log entries. `event_detail.task_title` is always populated (not just on delete) so the log stays meaningful without needing a join — see DECISIONS.md.

`activity_log` is now read by the app (a task's View page renders its history), not just written — see DECISIONS.md for the reversal of the original "Supabase-dashboard-only" MVP scoping call.

## Views

### `farm_member_profiles`

Not a table — a view joining `farm_memberships` to `auth.users`, exposing just enough of `auth.users` (id, email, Google profile name and picture) to attribute `activity_log` entries and task completions to a person, plus the membership's `role`. `auth.users` itself is never exposed directly via PostgREST.

| Column         | Type             | Notes                                                                                                                                                                                                                                                                         |
| -------------- | ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `farm_id`      | uuid             | From `farm_memberships`                                                                                                                                                                                                                                                       |
| `user_id`      | uuid             | From `farm_memberships.user_id`                                                                                                                                                                                                                                               |
| `email`        | text, nullable   | From `auth.users.email`                                                                                                                                                                                                                                                       |
| `display_name` | text, nullable   | From `auth.users.raw_user_meta_data` — `full_name` first, `name` fallback, blank-trimmed to null. Google-profile sourced: GoTrue writes it on first sign-in and refreshes it on every subsequent sign-in, so it needs no app-side capture step and tracks Google-side renames |
| `avatar_url`   | text, nullable   | From `auth.users.raw_user_meta_data` — `avatar_url` (Supabase's normalized key) first, `picture` (raw OIDC claim) fallback, blank-trimmed to null. Same Google-profile sourcing and refresh-on-sign-in behavior as `display_name`                                             |
| `role`         | `farm_role` enum | From `farm_memberships.role` — powers the members page's owner/you chips and its client-side "invites are owner-only" gate (RLS on `farm_invites` is the real enforcement)                                                                                                    |

The view was recreated by `20260718120000_farm_invites_roles_and_signup.sql` to add `role`, again by `20260718150000_member_display_names.sql` to add `display_name`, and again by `20260718160000_member_avatar_urls.sql` to add `avatar_url`, keeping the same shape otherwise. How `display_name` becomes an on-screen label (first name; last initial or more only on collision; email fallback) is app-side — `app/utils/member-display.ts`, see DECISIONS.md. It runs with its owner's privileges (the Postgres default for views — the owner can read `auth.users` and isn't subject to `farm_memberships`' RLS), and carries its membership scoping in its own definition: a `where` clause restricts output to farms the querying user (`auth.uid()`) belongs to, and `security_barrier` keeps caller-supplied predicates from being evaluated ahead of that filter. Only `authenticated` holds a SELECT grant on the view. A view can't carry its own `create policy` the way a table can, so the in-view predicate is the equivalent mechanism. It was originally created as a `security_invoker` view instead, which failed in production — see DECISIONS.md for why that didn't work. One row per `(farm_id, user_id)` pair — a user who belongs to multiple farms appears once per farm, which is expected since callers always filter by a specific `farm_id`.

### `farm_recent_activity`

Not a table — a view over `tasks`, one row per farm, giving the timestamp of that farm's most recent task activity. Powers the default-farm fallback in `resolveActiveFarmId` (`app/utils/active-farm.ts`): when a user has no valid saved farm selection, the app picks the farm with the latest activity here instead of the alphabetically-first farm — see DECISIONS.md.

| Column             | Type        | Notes                                                                                                                      |
| ------------------ | ----------- | -------------------------------------------------------------------------------------------------------------------------- |
| `farm_id`          | uuid        | From `tasks.farm_id`, one row per distinct farm with any tasks                                                             |
| `last_activity_at` | timestamptz | `max(greatest(created_at, coalesce(completed_at, created_at)))` per farm — the newer of each task's creation or completion |

Unlike `farm_member_profiles`, this view is `security_invoker`: it only reads `tasks`, which `authenticated` already has an ordinary table-level grant on (the app queries `tasks` directly everywhere else), so it inherits `tasks`' existing farm-membership RLS as-is with no in-view scoping needed. A farm with no tasks at all has no row here, which is fine — the fallback chain in `resolveActiveFarmId` moves on to the alphabetically-first farm in that case.

## Functions

Two security-definer Postgres functions perform the only writes to `farms`/`farm_memberships` — neither table has a client-side INSERT/UPDATE/DELETE policy (see RLS below), so both actions have to go through server-side logic that can deliberately and safely bypass RLS on the caller's behalf.

### `accept_farm_invites()`

Called by the app once per session, right after sign-in (`app/middleware/membership.global.ts`). Matches the caller's own JWT email (lowercased) against pending `farm_invites` rows, inserts a `farm_memberships` row for each match (`on conflict do nothing` — the membership may already exist), marks those invites accepted, and returns the ids of the farms joined. Scoping comes entirely from `auth.uid()`/the JWT's email claim, never from anything caller-supplied, so a caller can only ever accept invites addressed to their own verified email.

### `create_farm(farm_name, farm_address default null)`

Self-serve farm creation. Validates `farm_name` (trimmed, 1–120 characters), inserts the `farms` row and the caller's `'owner'` `farm_memberships` row in one transaction, and returns the new farm's id. Backs both the `/welcome` first-farm flow and the "New farm" form on `/farm`.

## Row Level Security (RLS) Policy Intent

All farm-scoped tables (`categories`, `locations`, `tasks`, `tags`, `task_tags`, `task_photos`, `task_shopping_items`, `task_tools`, `task_time_entries`, `activity_log`) should have RLS **enabled by default** (deny-by-default), with policies granting access based on farm membership:

```sql
-- Illustrative pattern, not final SQL
CREATE POLICY "farm members can access their farm's tasks"
ON tasks
FOR ALL
USING (
  farm_id IN (
    SELECT farm_id FROM farm_memberships WHERE user_id = auth.uid()
  )
);
```

This same pattern applies across every farm-scoped table — a user can only see/modify rows whose `farm_id` corresponds to a farm they're a member of, via `farm_memberships`.

`farms` itself needs a policy allowing a user to see farms they belong to (via a subquery against `farm_memberships`), and `farm_memberships` needs a policy allowing a user to see their own membership rows. Neither table has an INSERT/UPDATE/DELETE policy for `authenticated` — all writes to `farms` and `farm_memberships` go through the `create_farm()`/`accept_farm_invites()` security-definer functions above instead of a client-side write path.

Since Chore Corral is using **both** RLS and application-layer checks (a deliberate choice — see DECISIONS.md), RLS here functions as the defense-in-depth backstop: even if application code has a bug in its farm-scoping logic, RLS prevents cross-farm data leakage at the database level. Application code should not rely on RLS alone for business-logic enforcement (e.g. the "can't delete a category with active tasks" rule is application logic, not something RLS is well-suited to express).

## Storage (Supabase Storage)

- One bucket, `task-photos` (private, not public), path structure `{farm_id}/{task_id}/{photo_id}.webp` — the leading `farm_id` segment is what makes path-based policy scoping possible.
- Access policies mirror the `farm_memberships` check used for database tables, but since `storage.objects` has no `farm_id` column, the farm is extracted from the object path via `storage.foldername(name)` (see DECISIONS.md for the reasoning):

```sql
-- One policy per operation; SELECT/DELETE use USING, INSERT uses WITH CHECK,
-- UPDATE uses both. Shown here for SELECT and INSERT; UPDATE/DELETE repeat the
-- same expression.
CREATE POLICY "farm members can read their farm's task photos"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'task-photos'
  AND (storage.foldername(name))[1]::uuid IN (
    SELECT farm_id FROM farm_memberships WHERE user_id = auth.uid()
  )
);

CREATE POLICY "farm members can upload their farm's task photos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'task-photos'
  AND (storage.foldername(name))[1]::uuid IN (
    SELECT farm_id FROM farm_memberships WHERE user_id = auth.uid()
  )
);
```

## PostGIS (Future)

Not part of the MVP schema. When boundary/measurement features are built (see ROADMAP.md), this will likely mean:

- Adding a `geometry` column (PostGIS type) to a future `farm_locations` or `farm_boundaries` table, rather than the simple `lat`/`lng` numeric columns used for task pins.
- Task-level location pins (`lat`/`lng` on `tasks`) can likely remain simple points even after PostGIS is introduced elsewhere — no need to migrate task locations to PostGIS types unless a specific future feature requires it (e.g. "show tasks within this boundary").
