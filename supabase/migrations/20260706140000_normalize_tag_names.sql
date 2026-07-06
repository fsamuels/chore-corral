-- Normalize existing tag names to this app's naming convention: lowercase,
-- with internal whitespace collapsed to single spaces (e.g. "Fence   Repair"
-- and "fence repair" both become "fence repair"). `resolveTags`
-- (app/services/tags.ts) now normalizes on every write going forward; this
-- migration backfills tags created before that change landed.
--
-- A naive `update tags set name = normalize(name)` would violate
-- `unique(farm_id, name)` whenever two previously-distinct tags normalize to
-- the same string within a farm (e.g. "Fence" and "fence " both become
-- "fence"). So instead this migration merges colliding tags rather than
-- just renaming them:
--   1. Groups existing tags by (farm_id, normalized name).
--   2. Within each group with more than one row, picks one canonical tag —
--      the oldest by created_at, tag id as a tiebreaker — to survive.
--   3. Repoints `task_tags` rows from the losing tag ids to the canonical
--      id. Two tags in the same merge group can each already tag the same
--      task (e.g. a task tagged with both "Fence" and "fence"), which would
--      collide on `task_tags`' (task_id, tag_id) composite PK once both
--      point at the canonical id — so surviving rows are deduped per
--      (task_id, canonical tag) first (keeping an arbitrary one), then the
--      remainder are updated to the canonical tag id.
--   4. Deletes the now-unreferenced losing tag rows.
--   5. Renames each surviving (canonical) row to its normalized name.
-- See docs/DECISIONS.md's dated entry for the full reasoning.

create temporary table tag_merge_plan as
select
  t.id as tag_id,
  t.farm_id,
  lower(trim(regexp_replace(t.name, '\s+', ' ', 'g'))) as normalized_name,
  first_value(t.id) over (
    partition by t.farm_id, lower(trim(regexp_replace(t.name, '\s+', ' ', 'g')))
    order by t.created_at, t.id
  ) as canonical_id
from tags t;

-- Dedupe task_tags rows within each (task, canonical tag) pair down to one,
-- regardless of which specific tag in the merge group each row currently
-- references — this covers both "task already tagged with the canonical
-- tag" and "task tagged with two different losing tags" collisions.
delete from task_tags tt
using (
  select
    tt2.ctid,
    row_number() over (
      partition by tt2.task_id, p.canonical_id
      order by tt2.ctid
    ) as rn
  from task_tags tt2
  join tag_merge_plan p on p.tag_id = tt2.tag_id
) dup
where tt.ctid = dup.ctid
  and dup.rn > 1;

-- Repoint the surviving losing-tag rows to their canonical tag id.
update task_tags tt
set tag_id = p.canonical_id
from tag_merge_plan p
where tt.tag_id = p.tag_id
  and p.tag_id <> p.canonical_id;

-- Losing tags are now unreferenced by task_tags; delete them.
delete from tags t
using tag_merge_plan p
where t.id = p.tag_id
  and p.tag_id <> p.canonical_id;

-- Normalize the surviving (canonical) rows' names.
update tags t
set name = p.normalized_name
from tag_merge_plan p
where t.id = p.canonical_id
  and t.name <> p.normalized_name;

drop table tag_merge_plan;
