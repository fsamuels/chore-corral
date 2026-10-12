-- Index activity_log by task
--
-- The task page's activity timeline (`listActivityForTask`) filters on
-- `farm_id` and `task_id` and orders by `created_at desc`. The only existing
-- index is `(farm_id, created_at desc)`, so each task page load walks the
-- farm's entire log to find one task's entries. `task_id` is the selective
-- column; leading with it lets the query read just that task's rows, already
-- in display order. `task_id` is a soft reference (no FK, see DECISIONS.md),
-- so this is the only index on it.
create index activity_log_task_id_created_at_idx
  on activity_log (task_id, created_at desc);
