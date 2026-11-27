-- Session labels on time entries
--
-- A timer session can carry a few short labels describing what that chunk of
-- time covered ("morning feeding", "mucking", "Aaron helped"), so sessions on
-- the same recurring chore can be compared by what was actually done. The
-- chore page shows average time per label combination.
--
-- A text[] column rather than a child table: labels belong to exactly one
-- session, carry no state of their own, and are always read with the entry.
-- Autocomplete suggestions are derived from the chore's other entries, so
-- there's no shared vocabulary table to keep in sync.
--
-- The app trims labels, drops duplicates case-insensitively and caps their
-- count and length (`normalizeLabels`); the check below backstops the count.
-- Existing RLS (through the parent task) and the user_id guard trigger already
-- cover updates to this column, so no policy changes are needed.

alter table task_time_entries
  add column labels text[] not null default '{}';

alter table task_time_entries
  add constraint task_time_entries_labels_max_count
    check (cardinality(labels) <= 8);
