-- Cross-farm reference and attribution guards
--
-- Every farm-scoped RLS policy checks that the row's *task* (or farm) belongs
-- to the caller, but none checked the *other* ids a row points at. A farm
-- member could therefore:
--   - point a task at another farm's category or location, or tag it with
--     another farm's tag (the ids aren't secret: they show up in URLs);
--   - assign a task to, or credit its completion to, an arbitrary user id
--     who isn't a member of the farm;
--   - write rows attributed to someone else (`tasks.created_by`,
--     `task_time_entries.user_id`, `task_reminders.created_by`), because the
--     client supplies those columns and only `activity_log` checked them.
-- Nothing leaked across farms (the other farm's rows stay invisible under
-- RLS), but the data stopped being trustworthy. See DECISIONS.md D-3.
--
-- Enforced with BEFORE triggers rather than RLS `with check` clauses because
-- the membership checks need to see *other* users' farm_memberships rows,
-- which the caller's RLS hides. The trigger functions are security definer
-- (empty search_path, everything schema-qualified) so they read the real
-- tables; they return `trigger`, so clients can't call them via RPC.
--
-- Attribution columns are set from auth.uid() on insert rather than rejected
-- when they differ: the app already sends the caller's id, so this changes
-- nothing for it, and a forged value is simply replaced. When auth.uid() is
-- null (service role: seeds, e2e setup, the dashboard) the supplied value is
-- kept. On update the columns are pinned to their old values.

-- ---------------------------------------------------------------------------
-- Membership helper (internal: callers are the trigger functions below)
-- ---------------------------------------------------------------------------

create function public.user_is_farm_member(p_farm_id uuid, p_user_id uuid)
returns boolean
language sql
security definer
set search_path = ''
stable
as $$
  select exists (
    select 1 from public.farm_memberships
    where farm_id = p_farm_id and user_id = p_user_id
  );
$$;

-- Not an RPC: it would let any signed-in user probe who belongs to which
-- farm. Trigger functions run it with their owner's rights, so no grant is
-- needed for them to call it.
revoke all on function public.user_is_farm_member(uuid, uuid)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- tasks: same-farm category/location, fixed farm, real creator
-- ---------------------------------------------------------------------------

create function public.guard_task_row()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.farm_id <> old.farm_id then
    raise exception 'a task cannot move to another farm'
      using errcode = '23514';
  end if;

  if new.category_id is not null and not exists (
    select 1 from public.categories
    where id = new.category_id and farm_id = new.farm_id
  ) then
    raise exception 'category does not belong to this farm'
      using errcode = '23503';
  end if;

  if new.location_id is not null and not exists (
    select 1 from public.locations
    where id = new.location_id and farm_id = new.farm_id
  ) then
    raise exception 'location does not belong to this farm'
      using errcode = '23503';
  end if;

  if tg_op = 'INSERT' then
    if (select auth.uid()) is not null then
      new.created_by := (select auth.uid());
    end if;
  else
    new.created_by := old.created_by;
  end if;

  return new;
end;
$$;

create trigger guard_task_row
  before insert or update on public.tasks
  for each row execute function public.guard_task_row();

-- ---------------------------------------------------------------------------
-- task_tags: tag from the task's farm
-- ---------------------------------------------------------------------------

create function public.guard_task_tag_row()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.tasks t
    join public.tags g on g.farm_id = t.farm_id
    where t.id = new.task_id and g.id = new.tag_id
  ) then
    raise exception 'tag does not belong to this task''s farm'
      using errcode = '23503';
  end if;
  return new;
end;
$$;

create trigger guard_task_tag_row
  before insert or update on public.task_tags
  for each row execute function public.guard_task_tag_row();

-- ---------------------------------------------------------------------------
-- task_assignees / task_completers: members of the task's farm only
-- ---------------------------------------------------------------------------

create function public.guard_task_member_ref()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- task_completers rows may name a non-user instead (user_id null).
  if new.user_id is not null and not public.user_is_farm_member(
    (select farm_id from public.tasks where id = new.task_id),
    new.user_id
  ) then
    raise exception 'user is not a member of this task''s farm'
      using errcode = '23503';
  end if;
  return new;
end;
$$;

create trigger guard_task_assignee_row
  before insert or update on public.task_assignees
  for each row execute function public.guard_task_member_ref();

create trigger guard_task_completer_row
  before insert or update on public.task_completers
  for each row execute function public.guard_task_member_ref();

-- ---------------------------------------------------------------------------
-- task_time_entries / task_reminders: real author
-- ---------------------------------------------------------------------------
-- Any member may still stop or edit another member's time entry (the app's
-- equal-access rule); only who the entry belongs to is fixed.

create function public.guard_time_entry_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if (select auth.uid()) is not null then
      new.user_id := (select auth.uid());
    end if;
  else
    new.user_id := old.user_id;
  end if;
  return new;
end;
$$;

create trigger guard_time_entry_user
  before insert or update on public.task_time_entries
  for each row execute function public.guard_time_entry_user();

create function public.guard_reminder_creator()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if (select auth.uid()) is not null then
      new.created_by := (select auth.uid());
    end if;
  else
    new.created_by := old.created_by;
  end if;
  return new;
end;
$$;

create trigger guard_reminder_creator
  before insert or update on public.task_reminders
  for each row execute function public.guard_reminder_creator();

-- Trigger functions are never meant to be called directly.
revoke all on function public.guard_task_row() from public, anon, authenticated;
revoke all on function public.guard_task_tag_row() from public, anon, authenticated;
revoke all on function public.guard_task_member_ref() from public, anon, authenticated;
revoke all on function public.guard_time_entry_user() from public, anon, authenticated;
revoke all on function public.guard_reminder_creator() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- task-photos bucket: size and type limits
-- ---------------------------------------------------------------------------
-- The bucket had neither, so any member could upload up to the project-wide
-- limit (50 MiB) of any content type, including HTML or SVG served back from
-- the storage domain. The app only uploads compressed images (WebP, ~1 MB
-- target; see app/utils/photo-compression.ts). JPEG and PNG are also allowed
-- because a browser that can't encode WebP hands back PNG from the same
-- canvas call; none of the three can run script. 10 MiB matches the app's
-- pre-compression cap (MAX_UPLOAD_BYTES), so nothing the app sends is
-- rejected.

update storage.buckets
set
  file_size_limit = 10485760,
  allowed_mime_types = array['image/webp', 'image/jpeg', 'image/png']
where id = 'task-photos';
