# Chore Corral — Functional Specification

## Overview

Chore Corral is a mobile-first web app for tracking maintenance and upkeep tasks across one or more farm/homestead properties. It is explicitly **not** a crop-rotation, field-planning, or spray-compliance/audit tool — it's a shared task tracker with location and photo context, built for the day-to-day "stuff that needs fixing" reality of running a property.

## Non-Goals (MVP)

- Crop rotation or field-planning
- Spray-compliance / audit reporting
- Recurring/repeating tasks
- Named/saved locations (freeform pins only for now)
- Role-based permissions (all farm members have equal access)
- In-app farm invite flow (farm membership is provisioned manually via database)
- Offline support
- PWA install-to-homescreen
- Multiple location pins per task (single pin only for MVP)
- Farm orphan cleanup/deletion handling

## Core Entities

### Farm

The top-level tenant boundary. Each farm is a separate property/workspace.

- **Name** (required)
- **Address** (optional, free text)
- **Default map center** — lat/lng, manually set at farm creation for MVP (future: derived from address via geocoding, or user-dropped pin)
- Farms can be **orphaned** (all members leave) — this is an explicit non-goal; no cleanup logic is built for MVP.

For MVP, farms are created directly in the database (no in-app farm-creation flow). The first two farms are:
1. **Reign Cloud Ranch** (production/primary)
2. **Clarkson's Farm** (testing/feature review)

### Farm Membership

Many-to-many relationship between users and farms.

- A user can belong to multiple farms.
- A farm can have multiple users.
- No roles for MVP — every member has full access (create, edit, complete, delete any task).
- Membership is provisioned manually via the database for MVP (no invite flow).

### Task

The core unit of work.

| Field | Required | Notes |
|---|---|---|
| Title | Yes | |
| Category | Yes | Single category per task; can be "Uncategorized" |
| Priority | Yes | Single value from a **global, fixed** tier list |
| Due date | No | Optional; if passed and task isn't Done, task is flagged overdue |
| Status | Yes (defaults on create) | Not Started / In Progress / Done |
| Notes | No | Free text, single field (not a threaded log) |
| Tags | No | Freeform text, multiple per task, autocomplete against existing tags on that farm |
| Location | No | Single pin, optional (see Location section) |
| Photos | No | Zero or more (see Photos section) |
| Created date | Auto | |
| Completed date | Auto | Set when status moves to Done; **cleared** if status moves out of Done |
| Farm | Auto | Inherited from the active farm context; not user-editable |

**Task creation form**: shows required fields only (Title, Category, Priority) with a "More details" expand/link to reveal all other fields (Notes, Tags, Location, Photos, Due date) at creation time.

**Task editing**: opens with all fields expanded by default (no collapsed state when editing an existing task).

**Deletion**: Hard delete. The task record is permanently removed; only a trace remains in the Activity Log (see below). This applies given the app is intended for two trusted users and a full audit trail isn't required — see ARCHITECTURE.md for the delete + activity log rationale.

### Category

Per-farm, user-editable list of task categories.

- Categories are scoped to a single farm (not global/shared across farms).
- New farms start with **zero categories** — no seeded defaults for MVP. Sensible starter categories may be identified later based on real usage.
- A task can be **Uncategorized** (no category assigned).
- Categories can be **soft-deleted only** — never hard-deleted.
- A category **cannot be deleted while any active task** (status = Not Started or In Progress) is assigned to it. Only categories with zero active tasks (all tasks Done, or no tasks) can be soft-deleted.
- Categories are used for both filtering the task list and reporting/grouping.

### Tag

Freeform metadata on tasks, distinct from category.

- Multiple tags per task.
- Freeform text entry with **autocomplete** suggestions drawn from tags already used on that farm (reduces duplicate near-identical tags like "fence" vs. "fencing").
- Not filterable in the MVP task list (descriptive metadata only, category is the filterable dimension).

### Priority

Global, fixed tiers — **not** per-farm, **not** user-editable.

- Exact tier set (e.g. Urgent / Soon / Whenever) to be finalized at implementation — the important constraint is that the list is fixed and shared across every farm.
- Priority drives the **default sort order** of the task list.
- Independent of due date — a task can have high priority with no due date, or a due date with low priority.

### Status

Fixed, multi-state (not binary).

- **Not Started** (default on creation)
- **In Progress**
- **Done**

Moving to Done sets `completed_at`. Moving out of Done (reopening a task) **clears** `completed_at` — no historical record of prior completion times is kept beyond the Activity Log's "status changed" event.

Completed tasks remain visible and filterable in the task list (not hidden/archived).

### Location

Single optional pin per task (MVP). Multiple pins per task (e.g. for a fence line spanning an area) is a **deferred future feature** — the data model and UI support exactly one pin for now.

**Capture flow:**
1. When creating a task, the app attempts to auto-capture the device's current GPS position.
2. The captured location is shown on a small confirmation map (mini-map) before the task is saved, allowing the user to adjust the pin if GPS accuracy is off, or if they're logging a task for a location they aren't physically standing at.
3. If GPS is unavailable or permission is denied, the task can still be saved with **no location**, or the user can manually place a pin on a map.
4. Location can be edited after task creation at any time (not locked once set).

**Display:**
- Tasks with a location appear as pins on the farm's map view.
- Tapping a pin on the map opens the associated task (map is an interactive entry point, not just a visualization layer).
- The map is scoped to whichever farm is currently active (no cross-farm combined view).

**Base map:** Mapbox Satellite (hybrid style — satellite imagery with road/label overlay), toggleable against a plain street/OSM layer via a layer control. Esri World Imagery is planned for future comparison against Mapbox — the tile provider is abstracted in configuration so this is a low-effort swap, not a rework.

### Photo

Zero or more per task (data model supports many; typical usage expected to be 0–1).

| Field | Notes |
|---|---|
| Image file | Stored compressed (see limits below) |
| Caption | Optional, free text |
| Timestamp | Auto-captured at upload time |

**Source:** camera capture or gallery upload — both supported.

**Size limits:**
- **Max upload size: 10 MB** (accommodates raw phone camera output before compression).
- **Client-side compression before storage:** resize to a maximum of 1600px on the longest edge, convert to WebP. Target compressed size: roughly 500 KB–1 MB per photo.
- No auto-delete on task completion for MVP — photos persist regardless of task status. Storage-management strategy (deletion, archival) may be revisited later if usage grows well beyond current projections (see DECISIONS.md).

### Activity Log

Records **major events only** — not a field-by-field audit trail. Intended for historical progress tracking, not compliance/audit purposes.

**Logged events (MVP):**
- Task created
- Task status changed
- Task deleted
- Category created
- Category deleted (soft delete)

Field-level edits (e.g. changing a task's notes or due date) are **not** individually logged. There is no dedicated in-app UI for browsing the activity log in MVP — it's available to query directly (e.g. via Supabase dashboard) if needed, not a user-facing feature.

## Views

### List View (primary)

- Default view of the task list.
- Sorted by priority (descending) by default.
- Filterable by category.
- Shows completed tasks (filterable, not hidden).
- Overdue tasks (due date passed, not Done) are visually flagged.

### Map View

- Per-farm (scoped to active farm, no cross-farm view).
- Shows pins for all tasks with a location set.
- Tapping a pin opens the task.
- Static display for MVP; boundary drawing and area measurement are future features (see ROADMAP.md).

### Farm Switcher

- Required for MVP, since a user can belong to multiple farms.
- Lets the user switch the active farm context, which scopes the task list, map, categories, and tags to that farm.

## Authentication

- **OAuth via Google** (through Supabase Auth).
- **Invite-only, no public signup** — there is no self-service account creation.
- **Unrecognized logins are blocked.** If a user authenticates via Google but is not a member of any farm, they see a clear error message explaining the situation and how to resolve it (e.g. "Your account isn't linked to any farm yet — contact [owner] to be added.") rather than a generic failure or blank state.

## Multi-Tenancy Model

- **Farm** is the top-level tenant boundary.
- All farm-scoped data (tasks, categories, tags) is isolated per farm via Postgres Row Level Security (RLS), enforced at the database level.
- A user's access to a farm's data is determined by farm membership (many-to-many).
- No roles/permissions tiering for MVP — every member of a farm has equal, full access to that farm's data.

## Deferred / Future Features

See ROADMAP.md for the full list and rough sequencing. Referenced here for completeness since they were discussed during spec definition:

- Named/saved locations, evolving into boundary polygons (PostGIS)
- Multiple location pins per task
- Recurring/repeating tasks
- Roles and permissions within a farm
- In-app farm invite flow
- Pasture maintenance tracking module (separate data model — see ROADMAP.md)
- Offline support
- PWA install-to-homescreen
- Esri World Imagery comparison/option
- Photo storage management strategy revisit (deletion/archival) if volume grows
