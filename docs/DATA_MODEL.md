# Chore Corral — Data Model

This document describes the Postgres schema (via Supabase) underlying Chore Corral: tables, relationships, and Row Level Security (RLS) policy intent. It complements ARCHITECTURE.md, which covers *why* RLS was chosen as the enforcement layer; this doc focuses on *what* the schema actually looks like.

All tables live in Postgres, managed via Supabase. Exact column types/constraints below are intended as an implementation-ready starting point, not frozen SQL — refine during M2 (schema setup) as needed.

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
                            │          ▼
                            │        tasks ──┬──► task_photos
                            │          │      └──► task_tags ──► tags
                            │          │
                            │          └──► activity_log
                            ▼
                        (tags are per-farm, not per-category)
```

## Tables

### `farms`

The top-level tenant entity.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid, PK | |
| `name` | text, not null | |
| `address` | text, nullable | Free text for MVP |
| `default_lat` | numeric, nullable | Manually set at farm creation (MVP) |
| `default_lng` | numeric, nullable | Manually set at farm creation (MVP) |
| `created_at` | timestamptz, default now() | |

No `deleted_at` or soft-delete column — farm deletion/orphan handling is explicitly out of scope for MVP (see SPEC.md non-goals).

### `farm_memberships`

Join table for the many-to-many user↔farm relationship.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid, PK | |
| `farm_id` | uuid, FK → `farms.id`, not null | |
| `user_id` | uuid, FK → `auth.users.id`, not null | Supabase-managed auth table |
| `created_at` | timestamptz, default now() | |

Unique constraint on (`farm_id`, `user_id`) — a user can't be added to the same farm twice.

No `role` column for MVP (see SPEC.md — no roles/permissions tiering). Adding a `role` column later is a straightforward additive migration when that feature is prioritized.

### `categories`

Per-farm, user-editable task categories.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid, PK | |
| `farm_id` | uuid, FK → `farms.id`, not null | Scopes category to one farm |
| `name` | text, not null | |
| `deleted_at` | timestamptz, nullable | Soft delete only — null = active |
| `created_at` | timestamptz, default now() | |

**Constraint (application-enforced, not DB-enforced):** a category cannot be soft-deleted while any task referencing it has `status != 'done'`. This check happens in application code at delete-time (see ARCHITECTURE.md for the app-layer vs. RLS authorization split).

A task with no category set represents "Uncategorized" — this is `category_id IS NULL` on the `tasks` table, not a real row in this table.

### Priority (enum, not a table)

Global, fixed priority tiers — **not** scoped to a farm, **not** a separate table.

Implemented as a Postgres enum type, declared in ascending-urgency order so `ORDER BY priority DESC` gives the correct default sort (Urgent first) for free:

```sql
CREATE TYPE task_priority AS ENUM ('whenever', 'soon', 'urgent');
```

No admin tooling is planned to manage priorities as data, so a lookup table's flexibility isn't needed — see DECISIONS.md.

### `tasks`

The core work-item entity.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid, PK | |
| `farm_id` | uuid, FK → `farms.id`, not null | |
| `title` | text, not null | |
| `category_id` | uuid, FK → `categories.id`, nullable | Null = Uncategorized |
| `priority` | `task_priority` enum, not null | See Priority section above |
| `status` | enum/text, not null, default 'not_started' | Values: `not_started`, `in_progress`, `done` |
| `due_date` | date, nullable | |
| `notes` | text, nullable | Single free-text field |
| `lat` | numeric, nullable | Single location pin (MVP) |
| `lng` | numeric, nullable | |
| `created_at` | timestamptz, default now() | |
| `created_by` | uuid, FK → `auth.users.id`, not null | For activity log / attribution, not for access control (all members have equal access) |
| `completed_at` | timestamptz, nullable | Set when status → done; **cleared** when status moves out of done |

**No `deleted_at`** — tasks are hard-deleted per SPEC.md. Deletion produces an `activity_log` entry as the only remaining trace.

**On multiple location pins:** the schema currently supports exactly one pin (`lat`/`lng` columns directly on `tasks`). If/when multiple pins per task becomes a real feature (see ROADMAP.md), this will require extracting location into a separate `task_locations` table with a one-to-many relationship — a real migration, not a config change. Worth keeping in mind if location-pin UI is built in a way that assumes a list rather than a single point, to ease that future migration.

### `tags`

Per-farm freeform tags.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid, PK | |
| `farm_id` | uuid, FK → `farms.id`, not null | Tags are scoped per farm for autocomplete purposes |
| `name` | text, not null | |
| `created_at` | timestamptz, default now() | |

Unique constraint on (`farm_id`, `name`) — avoids duplicate tags within a farm; autocomplete queries against this table filtered by `farm_id`.

### `task_tags`

Join table for the many-to-many task↔tag relationship.

| Column | Type | Notes |
|---|---|---|
| `task_id` | uuid, FK → `tasks.id`, not null | |
| `tag_id` | uuid, FK → `tags.id`, not null | |

Composite PK on (`task_id`, `tag_id`).

### `task_photos`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid, PK | |
| `task_id` | uuid, FK → `tasks.id`, not null | |
| `storage_path` | text, not null | Path in Supabase Storage bucket |
| `caption` | text, nullable | |
| `taken_at` | timestamptz, default now() | Auto-captured at upload time |

Actual image files live in Supabase Storage (a bucket, RLS-scoped by farm via the associated task), not in the database — this table stores metadata and the storage reference only.

### `activity_log`

Major-event-only log, per SPEC.md (not a full audit trail).

| Column | Type | Notes |
|---|---|---|
| `id` | uuid, PK | |
| `farm_id` | uuid, FK → `farms.id`, not null | Denormalized for query convenience even though most events reference a task |
| `task_id` | uuid, nullable, **no FK constraint** | Soft reference only — deliberately not enforced at the DB level, since a deleted task's row no longer exists but its log entries must survive |
| `event_type` | text, not null | `task_created`, `task_status_changed`, `task_deleted`, `category_created`, `category_deleted` |
| `event_detail` | jsonb, not null | Always includes a `task_title` snapshot (for every event type, not just deletion) plus event-specific context (e.g. old/new status). Snapshotting on every row means log entries stay readable without a join back to `tasks`, even for still-active tasks. |
| `actor_user_id` | uuid, FK → `auth.users.id`, not null | Who performed the action |
| `created_at` | timestamptz, default now() | |

**Resolved: task_id is a soft reference, not a hard FK.** `task_id` is a plain `uuid` column with no foreign key constraint, so a hard-deleted task never orphans or cascades against its log entries. `event_detail.task_title` is always populated (not just on delete) so the log stays meaningful without needing a join — see DECISIONS.md.

## Row Level Security (RLS) Policy Intent

All farm-scoped tables (`categories`, `tasks`, `tags`, `task_tags`, `task_photos`, `activity_log`) should have RLS **enabled by default** (deny-by-default), with policies granting access based on farm membership:

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

`farms` itself needs a policy allowing a user to see farms they belong to (via a subquery against `farm_memberships`), and `farm_memberships` needs a policy allowing a user to see their own membership rows.

Since Chore Corral is using **both** RLS and application-layer checks (a deliberate choice — see DECISIONS.md), RLS here functions as the defense-in-depth backstop: even if application code has a bug in its farm-scoping logic, RLS prevents cross-farm data leakage at the database level. Application code should not rely on RLS alone for business-logic enforcement (e.g. the "can't delete a category with active tasks" rule is application logic, not something RLS is well-suited to express).

## Storage (Supabase Storage)

- One bucket for task photos, path structure suggested as `{farm_id}/{task_id}/{photo_id}.webp` to keep farm-scoping visible in the path itself.
- RLS-equivalent access policies on Storage buckets should mirror the `farm_memberships` check used for database tables.

## PostGIS (Future)

Not part of the MVP schema. When boundary/measurement features are built (see ROADMAP.md), this will likely mean:
- Adding a `geometry` column (PostGIS type) to a future `farm_locations` or `farm_boundaries` table, rather than the simple `lat`/`lng` numeric columns used for task pins.
- Task-level location pins (`lat`/`lng` on `tasks`) can likely remain simple points even after PostGIS is introduced elsewhere — no need to migrate task locations to PostGIS types unless a specific future feature requires it (e.g. "show tasks within this boundary").
