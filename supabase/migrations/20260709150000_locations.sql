-- Defined locations: named places on a farm (Shop, Front Barn, Back Barn),
-- each a single point (lat/lng required). A task points at EITHER a defined
-- location (tasks.location_id) OR a freeform pin (tasks.lat/lng), never both.
-- Farm-scoped and soft-deletable, mirroring categories: a location can't be
-- soft-deleted while an active task still references it (app-layer guard, see
-- app/services/locations.ts).

create table locations (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references farms (id) on delete cascade,
  name text not null,
  lat numeric not null,
  lng numeric not null,
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

create index locations_farm_id_idx on locations (farm_id);

-- Case-insensitive uniqueness of name per farm among non-deleted rows.
-- categories has no name-uniqueness constraint, but a location is a picker
-- and duplicate names are confusing there — so this adds the constraint
-- categories lacks. Partial (deleted_at IS NULL) so a soft-deleted name can
-- be reused.
create unique index locations_farm_id_name_unique
  on locations (farm_id, lower(name))
  where deleted_at is null;

-- A task references at most one location; nullable, like category_id.
alter table tasks add column location_id uuid references locations (id);

create index tasks_location_id_idx on tasks (location_id);

-- A task has a defined location OR a freeform pin, never both. location_id is
-- brand new (null on every existing row), so this can't conflict with current
-- data — the pre-existing lat/lng pins all satisfy `location_id is null`.
alter table tasks add constraint tasks_location_xor_pin
  check (location_id is null or (lat is null and lng is null));

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
-- Deny-by-default; access granted via farm membership (identical in shape to
-- categories / tasks / tags). auth.uid() is wrapped in a scalar subselect so
-- Postgres evaluates it once per statement (initplan) instead of once per row.

alter table locations enable row level security;

create policy "farm members can access their farm's locations"
on locations for all
to authenticated
using (
  farm_id in (
    select farm_id from farm_memberships
    where user_id = (select auth.uid())
  )
)
with check (
  farm_id in (
    select farm_id from farm_memberships
    where user_id = (select auth.uid())
  )
);
