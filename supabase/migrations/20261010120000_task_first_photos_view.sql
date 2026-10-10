-- Task first-photo view
--
-- Powers the photo thumbnail on chore cards (home screen and /tasks): one row
-- per task holding its first photo, "first" meaning earliest taken_at with id
-- as the tiebreak (the same order the task View page's gallery uses). Doing
-- the DISTINCT ON here means a list load fetches one row per photo-bearing
-- task instead of every photo row, which also keeps the response clear of
-- PostgREST's max-rows cap on photo-heavy farms.
--
-- security_invoker is safe here for the same reason as farm_recent_activity:
-- the view only reads task_photos, which `authenticated` already selects
-- directly (the app queries it everywhere photos are shown), so the view
-- simply inherits task_photos' existing farm-membership RLS.
create view task_first_photos
with (security_invoker = true) as
select distinct on (task_id)
  task_id,
  id as photo_id,
  storage_path
from task_photos
order by task_id, taken_at, id;

grant select on task_first_photos to authenticated;
