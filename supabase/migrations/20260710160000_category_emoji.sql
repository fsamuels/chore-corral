-- Optional per-category emoji. Purely decorative — shown in the category
-- picker and, on the home screen, inside each task card's circular
-- start-timer button so a category is recognizable at a glance. Nullable
-- (categories predate this and most won't set one); a short length cap keeps
-- it to a single emoji (which can be several codepoints, e.g. ZWJ sequences
-- or flags) rather than an arbitrary string.
alter table categories add column emoji text;

alter table categories add constraint categories_emoji_length
  check (emoji is null or char_length(emoji) between 1 and 16);
