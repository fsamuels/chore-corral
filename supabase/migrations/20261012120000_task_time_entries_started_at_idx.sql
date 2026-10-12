-- Index task_time_entries by started_at
--
-- The Progress page now loads one week of time entries at a time
-- (`listTaskActivity` filters `started_at` to a padded week window; see
-- DECISIONS.md D-2) instead of looking entries up by task id. Without an
-- index on started_at that query scans the whole table, which grows with every
-- timer session ever recorded.
create index task_time_entries_started_at_idx
  on task_time_entries (started_at);
