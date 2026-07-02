-- M2 — Schema & Data Layer
-- Full MVP schema per docs/DATA_MODEL.md: enums, tables, indexes, RLS
-- policies (farm-membership pattern), and the task-photos storage bucket
-- with path-based access policies (see docs/DECISIONS.md).

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

-- Ascending-urgency order so ORDER BY priority DESC sorts Urgent first.
create type task_priority as enum ('whenever', 'soon', 'urgent');

create type task_status as enum ('not_started', 'in_progress', 'done');

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table farms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  default_lat numeric,
  default_lng numeric,
  created_at timestamptz not null default now()
);

create table farm_memberships (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references farms (id),
  user_id uuid not null references auth.users (id),
  created_at timestamptz not null default now(),
  unique (farm_id, user_id)
);

-- RLS policies on every farm-scoped table subquery this table by user_id;
-- the unique index above leads with farm_id, so user_id needs its own index.
create index farm_memberships_user_id_idx on farm_memberships (user_id);

create table categories (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references farms (id),
  name text not null,
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

create index categories_farm_id_idx on categories (farm_id);

create table tasks (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references farms (id),
  title text not null,
  category_id uuid references categories (id),
  priority task_priority not null,
  status task_status not null default 'not_started',
  due_date date,
  notes text,
  lat numeric,
  lng numeric,
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users (id),
  completed_at timestamptz
);

create index tasks_farm_id_idx on tasks (farm_id);
create index tasks_category_id_idx on tasks (category_id);

create table tags (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references farms (id),
  name text not null,
  created_at timestamptz not null default now(),
  unique (farm_id, name)
);

create table task_tags (
  task_id uuid not null references tasks (id) on delete cascade,
  tag_id uuid not null references tags (id),
  primary key (task_id, tag_id)
);

create index task_tags_tag_id_idx on task_tags (tag_id);

create table task_photos (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references tasks (id) on delete cascade,
  storage_path text not null,
  caption text,
  taken_at timestamptz not null default now()
);

create index task_photos_task_id_idx on task_photos (task_id);

create table activity_log (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references farms (id),
  -- Soft reference, deliberately no FK: log entries must outlive hard-deleted
  -- tasks (see docs/DECISIONS.md).
  task_id uuid,
  event_type text not null,
  event_detail jsonb not null,
  actor_user_id uuid not null references auth.users (id),
  created_at timestamptz not null default now()
);

create index activity_log_farm_id_created_at_idx
  on activity_log (farm_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
-- Deny-by-default everywhere; access granted via farm membership.
-- auth.uid() is wrapped in a scalar subselect so Postgres evaluates it once
-- per statement (initplan) instead of once per row.

alter table farms enable row level security;
alter table farm_memberships enable row level security;
alter table categories enable row level security;
alter table tasks enable row level security;
alter table tags enable row level security;
alter table task_tags enable row level security;
alter table task_photos enable row level security;
alter table activity_log enable row level security;

-- Farms: members can see their farms. No client-side writes — farms are
-- provisioned manually via the dashboard (service role bypasses RLS).
create policy "members can view their farms"
on farms for select
to authenticated
using (
  id in (
    select farm_id from farm_memberships
    where user_id = (select auth.uid())
  )
);

-- Memberships: users can see their own membership rows. No client-side
-- writes — memberships are provisioned manually for MVP.
create policy "users can view their own memberships"
on farm_memberships for select
to authenticated
using (user_id = (select auth.uid()));

create policy "farm members can access their farm's categories"
on categories for all
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

create policy "farm members can access their farm's tasks"
on tasks for all
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

create policy "farm members can access their farm's tags"
on tags for all
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

-- task_tags and task_photos carry no farm_id; scope through the parent task.
create policy "farm members can access their farm's task tags"
on task_tags for all
to authenticated
using (
  task_id in (
    select t.id from tasks t
    where t.farm_id in (
      select farm_id from farm_memberships
      where user_id = (select auth.uid())
    )
  )
)
with check (
  task_id in (
    select t.id from tasks t
    where t.farm_id in (
      select farm_id from farm_memberships
      where user_id = (select auth.uid())
    )
  )
);

create policy "farm members can access their farm's task photos"
on task_photos for all
to authenticated
using (
  task_id in (
    select t.id from tasks t
    where t.farm_id in (
      select farm_id from farm_memberships
      where user_id = (select auth.uid())
    )
  )
)
with check (
  task_id in (
    select t.id from tasks t
    where t.farm_id in (
      select farm_id from farm_memberships
      where user_id = (select auth.uid())
    )
  )
);

-- Activity log is append-only: SELECT and INSERT for farm members, no
-- UPDATE/DELETE policies at all. Inserts must be attributed to the caller.
create policy "farm members can view their farm's activity log"
on activity_log for select
to authenticated
using (
  farm_id in (
    select farm_id from farm_memberships
    where user_id = (select auth.uid())
  )
);

create policy "farm members can append to their farm's activity log"
on activity_log for insert
to authenticated
with check (
  farm_id in (
    select farm_id from farm_memberships
    where user_id = (select auth.uid())
  )
  and actor_user_id = (select auth.uid())
);

-- ---------------------------------------------------------------------------
-- Storage: task-photos bucket
-- ---------------------------------------------------------------------------
-- Private bucket; objects live at {farm_id}/{task_id}/{photo_id}.webp.
-- farm_id is the first path segment, extracted via storage.foldername(),
-- so no join through tasks is needed (see docs/DECISIONS.md).

insert into storage.buckets (id, name, public)
values ('task-photos', 'task-photos', false)
on conflict (id) do nothing;

create policy "farm members can read their farm's task photos"
on storage.objects for select
to authenticated
using (
  bucket_id = 'task-photos'
  and (storage.foldername(name))[1]::uuid in (
    select farm_id from farm_memberships
    where user_id = (select auth.uid())
  )
);

create policy "farm members can upload their farm's task photos"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'task-photos'
  and (storage.foldername(name))[1]::uuid in (
    select farm_id from farm_memberships
    where user_id = (select auth.uid())
  )
);

create policy "farm members can update their farm's task photos"
on storage.objects for update
to authenticated
using (
  bucket_id = 'task-photos'
  and (storage.foldername(name))[1]::uuid in (
    select farm_id from farm_memberships
    where user_id = (select auth.uid())
  )
)
with check (
  bucket_id = 'task-photos'
  and (storage.foldername(name))[1]::uuid in (
    select farm_id from farm_memberships
    where user_id = (select auth.uid())
  )
);

create policy "farm members can delete their farm's task photos"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'task-photos'
  and (storage.foldername(name))[1]::uuid in (
    select farm_id from farm_memberships
    where user_id = (select auth.uid())
  )
);
