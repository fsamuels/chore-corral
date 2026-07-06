-- Normalize tag names to the lowercase, whitespace-collapsed convention
-- (docs/DECISIONS.md's tag-naming-convention entry, dated 2026-07-06).
-- `resolveTags` (app/services/tags.ts) now normalizes every name it
-- creates/matches going forward; this is the one-time backfill for rows
-- created before that landed.
--
-- Normalizing two previously-distinct tags within the same farm can make
-- them collide (e.g. "Fence" and "fence " both normalize to "fence"), which
-- `unique(farm_id, name)` would reject on a naive rename. So this merges
-- colliding groups before renaming anything:
--   1. Group existing tags by (farm_id, normalized name); within each group,
--      the row with the smallest id is the canonical survivor (arbitrary
--      but deterministic).
--   2. Give every task_tags link currently pointing at a losing tag id an
--      equivalent link to the canonical id instead, via
--      `insert ... on conflict do nothing` — this is what actually avoids
--      the (task_id, tag_id) primary-key conflict when a task happens to
--      already be tagged with both the canonical tag and a losing one (or
--      with more than one losing variant of the same tag).
--   3. Delete the now-redundant links that still point at losing tag ids.
--   4. Delete the losing tag rows themselves.
--   5. Rename every surviving row (canonical merge survivors and tags that
--      never collided with another) to its normalized form.

-- Step 2: seed canonical task_tags links for every losing tag id.
with normalized as (
  select
    id,
    farm_id,
    lower(btrim(regexp_replace(name, '\s+', ' ', 'g'))) as normalized_name
  from tags
),
canonical as (
  select farm_id, normalized_name, min(id) as canonical_id
  from normalized
  group by farm_id, normalized_name
)
insert into task_tags (task_id, tag_id)
select distinct tt.task_id, c.canonical_id
from task_tags tt
join normalized n on n.id = tt.tag_id
join canonical c
  on c.farm_id = n.farm_id and c.normalized_name = n.normalized_name
where n.id <> c.canonical_id
on conflict (task_id, tag_id) do nothing;

-- Step 3: drop the old links now that the canonical ones exist.
with normalized as (
  select
    id,
    farm_id,
    lower(btrim(regexp_replace(name, '\s+', ' ', 'g'))) as normalized_name
  from tags
),
canonical as (
  select farm_id, normalized_name, min(id) as canonical_id
  from normalized
  group by farm_id, normalized_name
)
delete from task_tags tt
using normalized n, canonical c
where tt.tag_id = n.id
  and n.farm_id = c.farm_id
  and n.normalized_name = c.normalized_name
  and n.id <> c.canonical_id;

-- Step 4: delete the losing tag rows now that nothing references them.
with normalized as (
  select
    id,
    farm_id,
    lower(btrim(regexp_replace(name, '\s+', ' ', 'g'))) as normalized_name
  from tags
),
canonical as (
  select farm_id, normalized_name, min(id) as canonical_id
  from normalized
  group by farm_id, normalized_name
)
delete from tags t
using normalized n, canonical c
where t.id = n.id
  and n.farm_id = c.farm_id
  and n.normalized_name = c.normalized_name
  and n.id <> c.canonical_id;

-- Step 5: normalize the surviving rows' names. Safe as a direct per-row
-- update at this point — every remaining row is alone in its (farm_id,
-- normalized name) group, so no unique-constraint collision is possible.
update tags t
set name = lower(btrim(regexp_replace(t.name, '\s+', ' ', 'g')))
where t.name <> lower(btrim(regexp_replace(t.name, '\s+', ' ', 'g')));
