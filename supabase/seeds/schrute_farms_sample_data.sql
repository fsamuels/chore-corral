-- Schrute Farms sample data seed
--
-- Populates Chore Corral with themed sample data for the 'Schrute Farms'
-- demo tenant (Dwight Schrute's beet farm and bed & breakfast, near
-- Honesdale, Pennsylvania), covering the farm itself, categories (with
-- emoji), tags, locations, tasks (with location, time estimate and
-- multi-person completion attribution via task_completers), task_tags,
-- task_photos, task_shopping_items, task_tools, task_time_entries and the
-- activity log.
--
-- Unlike the Clarkson's Farm seed, this farm does not exist yet: the
-- script INSERTs a new `farms` row and a `farm_memberships` row (owned by
-- the same account used for Clarkson's Farm, fab9883a-1a2b-4339-af66-81e122c74fa6) in
-- addition to the usual category/tag/location/task data.
--
-- DESTRUCTIVE (for this farm only): this script first hard-deletes any
-- existing task_photos, task_tags, task_completers, task_shopping_items,
-- task_tools, task_time_entries, tasks, tags, categories, locations, and
-- activity_log rows scoped to the farm below, then reinserts the full
-- sample data set.
-- It is rerunnable -- running it again wipes and reseeds the same farm's
-- data from scratch. It does not touch any other farm's data.
--
-- Apply with the Supabase CLI:
--   supabase db query --linked --file supabase/seeds/schrute_farms_sample_data.sql

BEGIN;

-- Target farm: Schrute Farms (e514354e-2d0c-4cf2-82f4-fccab8fc678a)

-- ---------------------------------------------------------------------------
-- Wipe existing farm-scoped data (hard delete, farm-scoped only)
-- ---------------------------------------------------------------------------

DELETE FROM task_photos WHERE task_id IN (SELECT id FROM tasks WHERE farm_id = 'e514354e-2d0c-4cf2-82f4-fccab8fc678a');
DELETE FROM task_tags WHERE task_id IN (SELECT id FROM tasks WHERE farm_id = 'e514354e-2d0c-4cf2-82f4-fccab8fc678a');
DELETE FROM task_completers WHERE task_id IN (SELECT id FROM tasks WHERE farm_id = 'e514354e-2d0c-4cf2-82f4-fccab8fc678a');
DELETE FROM task_shopping_items WHERE task_id IN (SELECT id FROM tasks WHERE farm_id = 'e514354e-2d0c-4cf2-82f4-fccab8fc678a');
DELETE FROM task_tools WHERE task_id IN (SELECT id FROM tasks WHERE farm_id = 'e514354e-2d0c-4cf2-82f4-fccab8fc678a');
DELETE FROM task_time_entries WHERE task_id IN (SELECT id FROM tasks WHERE farm_id = 'e514354e-2d0c-4cf2-82f4-fccab8fc678a');
DELETE FROM tasks WHERE farm_id = 'e514354e-2d0c-4cf2-82f4-fccab8fc678a';
DELETE FROM tags WHERE farm_id = 'e514354e-2d0c-4cf2-82f4-fccab8fc678a';
DELETE FROM categories WHERE farm_id = 'e514354e-2d0c-4cf2-82f4-fccab8fc678a';
DELETE FROM locations WHERE farm_id = 'e514354e-2d0c-4cf2-82f4-fccab8fc678a';
DELETE FROM activity_log WHERE farm_id = 'e514354e-2d0c-4cf2-82f4-fccab8fc678a';

-- ---------------------------------------------------------------------------
-- Farm + membership
-- ---------------------------------------------------------------------------

INSERT INTO farms (id, name, address, default_lat, default_lng, created_at)
VALUES
  ('e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Schrute Farms', 'Schrute Farms, Honesdale, Pennsylvania, United States', 41.5776, -75.2596, '2026-02-18 08:00:00+00')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  address = EXCLUDED.address,
  default_lat = EXCLUDED.default_lat,
  default_lng = EXCLUDED.default_lng;

INSERT INTO farm_memberships (id, farm_id, user_id, created_at)
VALUES
  ('d329d860-bab6-4fbe-b365-ee049aff6794', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-18 08:00:00+00')
ON CONFLICT (farm_id, user_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Categories
-- ---------------------------------------------------------------------------

INSERT INTO categories (id, farm_id, name, emoji, deleted_at, created_at)
VALUES
  ('f9694f19-bc9e-4d5c-9f92-9f34c2bdb77e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Beets', '🫜', NULL, '2026-02-21 13:47:45+00'),
  ('fe2a70e2-7dc5-4ca5-8edb-a64cefb44d1e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Bed & Breakfast', '🛏', NULL, '2026-02-22 08:50:08+00'),
  ('9206a95f-ab5b-4391-bbb7-73fc1444502d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Security & Bunker', '🔒', NULL, '2026-02-23 10:26:04+00'),
  ('b53023a9-5b67-4d8a-a64e-0a6c3aa15af2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Volunteer Sheriff''s Dept', '🚔', NULL, '2026-02-24 21:34:43+00'),
  ('fd9a036d-a649-4ebe-a4c2-b5c4647e0eb6', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Livestock', '🐐', NULL, '2026-02-25 19:08:45+00'),
  ('60022206-074c-4b73-bb83-63ed72372617', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Land & Fields', '🌾', NULL, '2026-02-26 16:36:56+00'),
  ('c7ac2347-5acf-4c1a-bc0e-27ed2f1144e9', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Fire Safety & Drills', '🔥', NULL, '2026-02-26 09:43:43+00'),
  ('f7dec3eb-441f-44ef-a8e4-860e5b280371', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Machinery & Repairs', '🚜', NULL, '2026-02-27 14:43:23+00'),
  ('fc4aa87e-9e1a-4e29-9a6b-d610b55de993', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Paperwork & Compliance', '📋', NULL, '2026-02-27 11:56:45+00'),
  ('63c3a991-2381-4f5c-b0ea-63b1010e7c2b', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Bunker Provisions', '🥫', NULL, '2026-03-02 13:28:18+00'),
  ('b956ffcd-e546-475c-a043-95ea847b7cc0', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Sales & Customers', '📞', NULL, '2026-03-02 18:06:49+00'),
  ('c30dc3a9-4136-4b72-94ca-6e66d464af3d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Haunted House & Maze', '🎃', NULL, '2026-03-06 09:17:49+00'),
  ('6287e686-8a3c-404d-a79e-2d1f5cf3e65b', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Manure & Composting', '💩', NULL, '2026-03-08 13:01:10+00');

-- ---------------------------------------------------------------------------
-- Tags
-- ---------------------------------------------------------------------------

INSERT INTO tags (id, farm_id, name, created_at)
VALUES
  ('477452f8-1fe9-4714-bf21-ab2c751381c6', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'dwight', '2026-02-27 11:06:57+00'),
  ('fae69544-43fb-4c13-b01d-8c5d599c9dee', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'mose', '2026-03-03 11:22:29+00'),
  ('460b24a6-7074-48d3-923e-283f8acc2d65', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'beets', '2026-03-09 19:28:20+00'),
  ('6285cfbd-a2a0-4af9-a128-cadd60638a5e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'goats', '2026-03-11 17:08:54+00'),
  ('4b3bb18a-5935-4471-b28e-87560692cf79', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'geese', '2026-03-15 13:04:27+00'),
  ('cc36a725-3c61-4f5c-aacc-0e53c1b12971', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'chickens', '2026-03-16 17:21:12+00'),
  ('c157135f-22c9-449d-a568-a926d44dab70', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'bnb', '2026-03-17 14:54:47+00'),
  ('3bfbe071-dd10-4b64-9d1e-caf8504b3ea2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'guests', '2026-03-17 10:10:10+00'),
  ('0d3d3565-1c0f-46f8-9127-1aa2d207066f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'bunker', '2026-03-23 21:13:49+00'),
  ('f4608832-8baa-4198-89bc-5ef6a51faa2b', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'sheriff-duties', '2026-03-24 09:07:34+00'),
  ('9dfea4a8-eab9-4657-95bc-44223453a5db', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'fire-drill', '2026-03-28 12:59:16+00'),
  ('5bb92c0a-bfd3-49cf-9533-523499a4408c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'gun-safety', '2026-04-01 11:32:40+00'),
  ('553c995f-2321-45bf-adee-0783b880dd97', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'crossbow', '2026-04-02 06:18:30+00'),
  ('f0a5d3ea-e672-47d9-bf96-f1029c934656', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'beekeeping', '2026-04-03 19:17:17+00'),
  ('83cb720c-2d64-480a-ba63-d4ef4c423598', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'honey', '2026-04-03 15:27:34+00'),
  ('723c8c54-becd-4393-bd2e-9460f1f0e622', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'compost', '2026-04-08 07:52:45+00'),
  ('6b6aa2a3-b92b-4ba1-8aa3-075ad9e0b61c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'manure', '2026-04-18 09:15:15+00'),
  ('f044031e-d126-473d-ace2-8f9dddb21459', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'cornfield', '2026-04-19 17:37:47+00'),
  ('d0b9bee0-76f7-4bbd-ba7b-1b54c64e7d8c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'haunted-house', '2026-04-20 11:50:22+00'),
  ('9a9b7621-1f09-4a3c-8f43-d43137764263', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'hay-king', '2026-05-04 17:38:43+00'),
  ('32de5002-f608-48a0-98fa-921d2a3d5541', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'wheat', '2026-05-11 15:11:32+00'),
  ('f07538fc-fb1a-4909-9ad9-f2a3eefd623c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'silo', '2026-05-13 16:41:24+00'),
  ('a1233eda-54a4-4380-93de-99a1e0e3d1e5', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'tractor', '2026-05-14 07:00:58+00'),
  ('0cd0f30e-a6dc-4c1f-8455-e99a41bbc0e6', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'plow', '2026-05-18 12:18:03+00'),
  ('417d34b7-eda3-4bd2-9333-ac2d4c630e76', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'well-water', '2026-05-20 08:40:02+00'),
  ('27646273-2ca9-4878-8125-ad408b76a806', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'outhouse', '2026-05-24 11:40:50+00'),
  ('c1947427-4914-4128-bc13-b2c4309dc352', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'taxidermy', '2026-05-25 16:09:22+00'),
  ('e2fda6bd-5023-4158-8b18-fc8759072108', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'salt-mine', '2026-05-26 15:35:41+00'),
  ('4aace591-730b-462b-9458-2377cdfa4e56', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'schrute-bucks', '2026-05-27 09:33:12+00'),
  ('fb197a1e-c000-4874-b132-b4d60f71f4b2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'thermostat', '2026-05-27 18:56:31+00'),
  ('92689be3-ba0c-45ef-bb42-a9dc2a7968f8', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'karate', '2026-05-31 13:10:25+00'),
  ('8f5b6c7a-12bd-40d4-9cc4-fe81c0a5ed5f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'security-system', '2026-06-08 10:50:14+00'),
  ('d3a5b481-bc73-4f90-8ef2-53459fbaaf2d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'land-survey', '2026-06-12 13:31:25+00'),
  ('2375dff4-8414-4dff-895d-f13a6dcc2edc', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'amish-cousins', '2026-06-13 12:52:59+00'),
  ('717dd376-4d73-4112-b9d1-ed5f1d6e9c32', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'root-cellar', '2026-06-13 17:13:10+00'),
  ('b5fb34ac-c266-4613-8bda-5daf4903c240', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'paintball', '2026-06-14 08:07:09+00'),
  ('025b30d0-0aaf-46f8-8fd2-78a40c613f2d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'prep', '2026-06-19 22:49:35+00'),
  ('f9d713d0-213d-4c4a-8a22-9b08e774a653', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'paperwork', '2026-06-19 07:50:22+00');

-- ---------------------------------------------------------------------------
-- Locations
-- ---------------------------------------------------------------------------

INSERT INTO locations (id, farm_id, name, lat, lng, deleted_at, created_at)
VALUES
  ('502be97f-5b8e-4cce-ad68-4175a221757e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Main House', 41.574454, -75.243744, NULL, '2026-07-08 08:36:20+00'),
  ('22a2ecfd-a5c4-4b55-a699-b057cfbb90b5', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'North Beet Field', 41.584494, -75.271005, NULL, '2026-07-10 15:31:24+00'),
  ('97684a5c-ce9b-4b8a-8e4a-9e736931f109', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Bunker Entrance', 41.580327, -75.263172, NULL, '2026-07-11 17:32:18+00'),
  ('1bbc1150-b09f-408f-adf1-f1590c06fbab', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Barn', 41.591091, -75.261507, NULL, '2026-07-11 15:04:58+00'),
  ('0273af56-a23c-4ead-b44b-bce362bbb4b6', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Chicken Coop', 41.563762, -75.264929, NULL, '2026-07-11 15:59:22+00'),
  ('84b0f762-fcb5-4a03-8b6c-b5c9586489fa', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Goat Pen', 41.563649, -75.259243, NULL, '2026-07-11 22:33:14+00'),
  ('07e359a3-c3b5-4606-b62c-0d8300141448', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Cornfield Maze', 41.581185, -75.269591, NULL, '2026-07-12 15:42:52+00'),
  ('95036e00-2bcc-4dad-aa7b-624466f7d323', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Root Cellar', 41.585378, -75.244132, NULL, '2026-07-13 17:48:59+00'),
  ('417fcab2-a3c6-491b-90d8-319fdae1fb55', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Outhouse', 41.592034, -75.249574, NULL, '2026-07-13 10:42:25+00'),
  ('b6edecf2-9b84-41ae-b78f-5c781f4cc1cf', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Silo', 41.564624, -75.26575, NULL, '2026-07-13 20:37:23+00');

-- ---------------------------------------------------------------------------
-- Tasks
-- ---------------------------------------------------------------------------

INSERT INTO tasks (id, farm_id, title, category_id, priority, status, due_date, notes, lat, lng, location_id, estimated_minutes, created_at, created_by, completed_at)
VALUES
  ('d1e09fac-9dda-4db0-8bfa-645284302ebd', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Sow the second beet crop before the last frost', 'f9694f19-bc9e-4d5c-9f92-9f34c2bdb77e', 'whenever', 'in_progress', NULL, 'Mose says the soil temperature is exactly right. He is never wrong about soil.', NULL, NULL, '22a2ecfd-a5c4-4b55-a699-b057cfbb90b5', 20, '2026-03-10 06:22:47+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('f8bf8dcd-2ac9-4e3a-9e3d-0e1de537f3b7', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Load the beet truck for the Saturday farmers market', 'f9694f19-bc9e-4d5c-9f92-9f34c2bdb77e', 'whenever', 'done', NULL, 'Two hundred pounds, give or take a few Dwight insisted on eating.', 41.584494, -75.271005, NULL, 15, '2026-07-05 21:59:00+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-15 06:35:28+00'),
  ('13752e12-9a16-45cb-bf9e-2fc61b6394f1', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Test the sugar content of this year''s beet crop', 'f9694f19-bc9e-4d5c-9f92-9f34c2bdb77e', 'soon', 'done', NULL, 'Refractometer says 18 brix. Dwight says it tastes like victory.', NULL, NULL, NULL, 30, '2026-06-21 16:42:59+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-25 12:18:52+00'),
  ('c27e7a5a-b604-4947-9f58-d8a3edfa613c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Repair the beet harvester''s conveyor belt', 'f9694f19-bc9e-4d5c-9f92-9f34c2bdb77e', 'soon', 'not_started', '2026-07-18', 'It ate a glove again. The glove was empty. This time.', 41.591091, -75.261507, NULL, 240, '2026-05-22 13:01:32+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('25476c46-ed4e-446c-83ac-d91263954b41', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Sort beets by size for the county fair entry', 'f9694f19-bc9e-4d5c-9f92-9f34c2bdb77e', 'urgent', 'in_progress', NULL, 'Only the top three percent are worthy. The rest go to soup.', NULL, NULL, '95036e00-2bcc-4dad-aa7b-624466f7d323', 30, '2026-06-02 20:52:46+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('7ca73e5c-c552-4ad5-a0c7-099b594dc739', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Weed the beet rows before they choke the seedlings', 'f9694f19-bc9e-4d5c-9f92-9f34c2bdb77e', 'whenever', 'done', NULL, 'Back-breaking. Mose hums the whole time. It helps, somehow.', NULL, NULL, '22a2ecfd-a5c4-4b55-a699-b057cfbb90b5', 30, '2026-06-18 07:54:15+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-26 16:35:50+00'),
  ('db868f19-f432-40e6-b7fa-f9cf4115298b', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Replant the beet seedlings the frost got last week', 'f9694f19-bc9e-4d5c-9f92-9f34c2bdb77e', 'urgent', 'not_started', '2026-09-10', 'A minor setback. Dwight has already forgiven the frost.', NULL, NULL, '22a2ecfd-a5c4-4b55-a699-b057cfbb90b5', 45, '2026-05-06 08:08:20+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('fc998e3f-4600-4a8f-a64b-c4f5a684f2ce', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Negotiate beet pricing with the grocery buyer in Scranton', 'f9694f19-bc9e-4d5c-9f92-9f34c2bdb77e', 'urgent', 'not_started', NULL, 'Opened at double market rate. Settled for slightly above market rate. A win.', NULL, NULL, NULL, 20, '2026-04-22 09:48:59+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('70852bed-47e5-4025-9cd7-7b42ab5ec410', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Change the linens in the guest rooms before the weekend booking', 'fe2a70e2-7dc5-4ca5-8edb-a64cefb44d1e', 'whenever', 'not_started', '2026-08-11', 'One guest requested a duvet. Schrute Farms does not do duvets.', NULL, NULL, '502be97f-5b8e-4cce-ad68-4175a221757e', 240, '2026-04-02 15:33:32+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('f3572656-474e-4e49-a2fe-de517c2f8034', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Deep clean the root cellar guest suite', 'fe2a70e2-7dc5-4ca5-8edb-a64cefb44d1e', 'soon', 'done', NULL, 'It''s the farm''s most requested room, somehow.', NULL, NULL, '95036e00-2bcc-4dad-aa7b-624466f7d323', 60, '2026-04-03 19:54:44+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-07 15:15:37+00'),
  ('02facb2b-e626-452c-b85f-8c98b61443f0', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Restock the outhouse before the weekend guests arrive', 'fe2a70e2-7dc5-4ca5-8edb-a64cefb44d1e', 'whenever', 'done', NULL, 'Authenticity is the whole selling point. Nobody complains twice.', NULL, NULL, '417fcab2-a3c6-491b-90d8-319fdae1fb55', 30, '2026-03-03 08:34:21+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 12:31:57+00'),
  ('d0648a52-4f8f-4b51-8927-a728df4648c6', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Update the B&B''s online listing photos', 'fe2a70e2-7dc5-4ca5-8edb-a64cefb44d1e', 'whenever', 'done', NULL, 'The old photo made the goat pen look bigger than the house.', NULL, NULL, NULL, 15, '2026-05-12 16:10:21+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-29 12:58:18+00'),
  ('128257bf-4de2-4e8c-aad2-82f54ac8187c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Fix the guest room thermostat that only does two temperatures', 'fe2a70e2-7dc5-4ca5-8edb-a64cefb44d1e', 'urgent', 'not_started', NULL, 'Sweltering or Siberia. Guests have learned to pack layers.', 41.574454, -75.243744, NULL, 30, '2026-03-14 21:35:14+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('affdb6da-8dc2-4f76-8a39-4bc6fe2e4521', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Prepare the welcome basket of beets for arriving guests', 'fe2a70e2-7dc5-4ca5-8edb-a64cefb44d1e', 'whenever', 'done', NULL, 'One guest asked for a fruit basket instead. That guest did not return.', NULL, NULL, '502be97f-5b8e-4cce-ad68-4175a221757e', 20, '2026-05-16 09:12:08+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 21:12:24+00'),
  ('04cdef75-0b62-406c-9655-e02481913fb3', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Replace the ''no running water after 9pm'' sign', 'fe2a70e2-7dc5-4ca5-8edb-a64cefb44d1e', 'urgent', 'not_started', '2026-08-01', 'The old one fell in a well. A different well.', NULL, NULL, NULL, 120, '2026-03-29 17:39:07+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('6b072305-8faf-4285-a42f-28ba16e9656f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Muck out the guest parking area before check-in', 'fe2a70e2-7dc5-4ca5-8edb-a64cefb44d1e', 'whenever', 'done', NULL, 'Technically it''s a pasture with a mailbox.', 41.574454, -75.243744, NULL, 45, '2026-05-13 22:23:14+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-15 06:41:47+00'),
  ('c70eb3f7-d9ce-4b1f-98a4-58e202c41b8b', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Inspect the perimeter fence for breaches', '9206a95f-ab5b-4391-bbb7-73fc1444502d', 'urgent', 'done', '2026-05-09', 'Found a hole. Also found a raccoon using it as a toll booth.', NULL, NULL, '97684a5c-ce9b-4b8a-8e4a-9e736931f109', 45, '2026-05-05 17:11:19+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-11 14:46:08+00'),
  ('06f2b0ba-f3b7-46d9-9357-5b6eba782432', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Test the motion-sensor alarms along the tree line', '9206a95f-ab5b-4391-bbb7-73fc1444502d', 'urgent', 'not_started', NULL, 'Triggered four times by the same confused goose.', NULL, NULL, '97684a5c-ce9b-4b8a-8e4a-9e736931f109', 60, '2026-03-19 06:40:37+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('2ba5820b-af54-4341-bfc3-a920a353bc37', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Sharpen the display katana in the great room', '9206a95f-ab5b-4391-bbb7-73fc1444502d', 'urgent', 'done', NULL, 'Purely decorative. Mostly decorative. Dwight insists on ''combat ready''.', NULL, NULL, '502be97f-5b8e-4cce-ad68-4175a221757e', 240, '2026-07-01 09:26:22+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-14 20:51:59+00'),
  ('a6744dc2-bfcb-4504-a564-9c1cf9352a4d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Inventory the gun safe and update the log', '9206a95f-ab5b-4391-bbb7-73fc1444502d', 'whenever', 'done', NULL, 'Everything accounted for. Mose double-checked anyway.', NULL, NULL, '97684a5c-ce9b-4b8a-8e4a-9e736931f109', 30, '2026-05-09 20:33:25+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 21:01:45+00');

INSERT INTO tasks (id, farm_id, title, category_id, priority, status, due_date, notes, lat, lng, location_id, estimated_minutes, created_at, created_by, completed_at)
VALUES
  ('706aac4f-7f92-4f40-99cd-0428bc8d6d62', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Replace batteries in the perimeter security cameras', '9206a95f-ab5b-4391-bbb7-73fc1444502d', 'whenever', 'done', NULL, 'Six cameras. One only points at the compost heap. Unclear why.', NULL, NULL, '97684a5c-ce9b-4b8a-8e4a-9e736931f109', 15, '2026-04-08 17:14:50+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-10 10:37:08+00'),
  ('46e55f5e-e680-43bc-8a3d-e74b8668569c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Patch the hinge on the bunker''s escape hatch', '9206a95f-ab5b-4391-bbb7-73fc1444502d', 'urgent', 'in_progress', '2026-11-11', 'Squeaked. Squeaking defeats the purpose of a secret hatch.', NULL, NULL, '97684a5c-ce9b-4b8a-8e4a-9e736931f109', 30, '2026-06-17 16:10:42+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('067d3cc5-63b8-4f56-a9fb-cefe27edb91d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Restock the bunker''s canned beet rations', '9206a95f-ab5b-4391-bbb7-73fc1444502d', 'whenever', 'not_started', NULL, 'Twelve years'' supply, per Dwight''s calculations. Recalculating to fifteen.', 41.580327, -75.263172, NULL, 240, '2026-04-02 07:21:29+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('63e51f7f-6a9c-469a-ad25-537cb365d768', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Run the full property lockdown drill', '9206a95f-ab5b-4391-bbb7-73fc1444502d', 'whenever', 'done', NULL, 'Forty seconds. A new personal best. Mose is unimpressed.', NULL, NULL, '97684a5c-ce9b-4b8a-8e4a-9e736931f109', 240, '2026-05-02 20:27:08+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-27 17:33:39+00'),
  ('a8d424d8-ee04-4193-b7bd-051c06dbc9eb', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Patrol the county fairgrounds ahead of the weekend event', 'b53023a9-5b67-4d8a-a64e-0a6c3aa15af2', 'whenever', 'done', NULL, 'Volunteer deputy duties. Unpaid. Deeply meaningful, according to Dwight.', NULL, NULL, NULL, 20, '2026-06-21 13:09:00+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-25 11:11:47+00'),
  ('17f076df-fc10-4f34-9e83-d1236b02a1dc', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Renew the volunteer sheriff''s department paperwork', 'b53023a9-5b67-4d8a-a64e-0a6c3aa15af2', 'whenever', 'not_started', NULL, 'Filed six weeks early. Dwight does not believe in deadlines, only in beating them.', NULL, NULL, NULL, 120, '2026-05-13 08:24:56+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('96ef0e6e-5aa9-4870-9852-3cafb683a2c2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Wax the department-issued patrol vehicle', 'b53023a9-5b67-4d8a-a64e-0a6c3aa15af2', 'whenever', 'done', NULL, 'It''s a golf cart with a siren zip-tied to the roof.', NULL, NULL, '1bbc1150-b09f-408f-adf1-f1590c06fbab', 60, '2026-03-29 10:13:37+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-28 12:05:24+00'),
  ('2d5e0e20-28c3-48c4-a54b-87f6f6ed59ec', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Restock the trunk first-aid kit', 'b53023a9-5b67-4d8a-a64e-0a6c3aa15af2', 'urgent', 'in_progress', '2026-08-14', 'Added a tourniquet, a beet, and a laminated pep talk.', NULL, NULL, NULL, 30, '2026-03-11 13:26:14+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('c66ba2b1-1420-49a4-8aeb-1e42d0b54aaf', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Attend the volunteer deputy refresher training', 'b53023a9-5b67-4d8a-a64e-0a6c3aa15af2', 'soon', 'not_started', NULL, 'Passed the written portion. The obstacle course portion is disputed.', NULL, NULL, NULL, 60, '2026-04-04 16:36:24+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('4d883b97-2ec7-4e4d-8777-d8d8b058869c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Replace the cracked badge holder', 'b53023a9-5b67-4d8a-a64e-0a6c3aa15af2', 'soon', 'done', NULL, 'The badge itself is fine. It has survived worse.', NULL, NULL, NULL, 90, '2026-03-30 16:52:18+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-15 21:57:42+00'),
  ('152ad141-87e4-4a37-9327-003414a12f29', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Submit the monthly ride-along report to the county', 'b53023a9-5b67-4d8a-a64e-0a6c3aa15af2', 'soon', 'done', '2026-07-22', 'Zero arrests. Several strongly worded warnings.', NULL, NULL, NULL, 45, '2026-04-16 08:18:52+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-02 14:20:38+00'),
  ('092b7dc7-4ba5-4e21-95b9-c2455eb3f369', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Clean and test the department-issued flashlight', 'b53023a9-5b67-4d8a-a64e-0a6c3aa15af2', 'whenever', 'in_progress', NULL, 'Works fine. Doubles as a bear deterrent, allegedly.', NULL, NULL, NULL, 30, '2026-03-25 12:43:37+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('130b9d85-b844-4e99-be78-5ecc08a9c08c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Feed the goats before the morning rounds', 'fd9a036d-a649-4ebe-a4c2-b5c4647e0eb6', 'whenever', 'done', NULL, 'One of them ate a garden hose last week. Recovering nicely.', NULL, NULL, '84b0f762-fcb5-4a03-8b6c-b5c9586489fa', 30, '2026-05-09 22:30:28+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-21 15:14:27+00'),
  ('d9c4e4ac-7b0b-495a-8762-14bef511e775', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Worm the goat herd on schedule', 'fd9a036d-a649-4ebe-a4c2-b5c4647e0eb6', 'whenever', 'done', '2026-06-23', 'All twelve done in under an hour. New record.', NULL, NULL, '84b0f762-fcb5-4a03-8b6c-b5c9586489fa', 20, '2026-06-11 15:13:50+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 18:59:18+00'),
  ('a448ade1-7bfb-47cf-9ee6-f7aa9904215a', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Clip the geese''s wings before they attack the mailman again', 'fd9a036d-a649-4ebe-a4c2-b5c4647e0eb6', 'whenever', 'in_progress', NULL, 'Third incident this season. The mailman has requested a different route.', NULL, NULL, '0273af56-a23c-4ead-b44b-bce362bbb4b6', 30, '2026-03-05 19:50:26+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('9f747efb-8253-4fb5-ab66-f0e0ac784669', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Collect eggs from the coop before the raccoons find them first', 'fd9a036d-a649-4ebe-a4c2-b5c4647e0eb6', 'soon', 'done', '2026-07-17', 'Fourteen eggs. Two suspicious dents. Investigating.', NULL, NULL, '0273af56-a23c-4ead-b44b-bce362bbb4b6', 180, '2026-07-05 07:39:39+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 16:16:59+00'),
  ('d533b324-1c42-4dee-8a31-2995f17dc36c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Repair the chicken coop door latch', 'fd9a036d-a649-4ebe-a4c2-b5c4647e0eb6', 'soon', 'not_started', NULL, 'A fox tried its luck overnight. The latch held. Barely.', NULL, NULL, '0273af56-a23c-4ead-b44b-bce362bbb4b6', 20, '2026-04-11 06:33:37+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('ef922ec7-a320-4b66-99f9-cdb5d9720984', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Move the goat herd to the north pasture for fresh grazing', 'fd9a036d-a649-4ebe-a4c2-b5c4647e0eb6', 'whenever', 'done', NULL, 'One goat refused. Negotiations are ongoing.', 41.563649, -75.259243, NULL, 15, '2026-04-01 21:36:43+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-16 14:33:05+00'),
  ('0bd8fa70-e870-440b-bf75-e1c3723b5564', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Treat a goat with a mild limp', 'fd9a036d-a649-4ebe-a4c2-b5c4647e0eb6', 'whenever', 'done', NULL, 'Nothing serious. Mose diagnosed it before the vet even called back.', NULL, NULL, '84b0f762-fcb5-4a03-8b6c-b5c9586489fa', 90, '2026-07-02 14:18:39+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 07:01:31+00'),
  ('e3a5f2dd-839e-437f-979e-fef462b15b19', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Order more chicken feed before the coop runs dry', 'fd9a036d-a649-4ebe-a4c2-b5c4647e0eb6', 'whenever', 'in_progress', '2026-08-23', 'Bulk order. Chickens do not negotiate on quantity.', NULL, NULL, NULL, 180, '2026-06-22 18:50:16+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL);

INSERT INTO tasks (id, farm_id, title, category_id, priority, status, due_date, notes, lat, lng, location_id, estimated_minutes, created_at, created_by, completed_at)
VALUES
  ('bc94a61a-a629-45bb-aec8-c1d08114d184', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Plow the north field before the ground freezes', '60022206-074c-4b73-bb83-63ed72372617', 'soon', 'done', NULL, 'Full day on the tractor. Dwight sang the entire time. Unclear what song.', NULL, NULL, NULL, 120, '2026-04-28 12:58:41+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-13 13:53:23+00'),
  ('1dfbdb28-6ddc-4f55-881f-d92c7c0fcf0d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Till the fallow field ahead of next season''s planting', '60022206-074c-4b73-bb83-63ed72372617', 'whenever', 'done', '2026-03-25', 'Soil''s in good shape. Mose says it ''smells right'', which is apparently a real metric.', NULL, NULL, NULL, 60, '2026-03-13 16:55:54+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-21 22:52:28+00'),
  ('788b8fa6-5cfe-4342-a5af-2c6f4ccf41d4', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Repair the irrigation line by the wheat field', '60022206-074c-4b73-bb83-63ed72372617', 'soon', 'not_started', '2026-07-31', 'A leak the size of a quarter. Fixed with the size of a dinner plate''s worth of tape.', NULL, NULL, NULL, 30, '2026-03-07 13:08:53+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('4cdd13da-0f2b-457c-80ab-eaaea441923e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Spread lime on the acidic patch near the tree line', '60022206-074c-4b73-bb83-63ed72372617', 'whenever', 'done', NULL, 'pH was off. It is now aggressively neutral.', NULL, NULL, NULL, 120, '2026-07-13 07:14:05+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-14 08:53:26+00'),
  ('5c2a0dc5-188b-4260-bf8d-21e947fff22c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Mow the fence line before it swallows the fence entirely', '60022206-074c-4b73-bb83-63ed72372617', 'soon', 'done', NULL, 'Overdue by a month. The fence had genuinely disappeared.', NULL, NULL, NULL, 30, '2026-04-20 20:28:20+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-24 19:56:10+00'),
  ('a3b0e74b-4630-4655-9a45-33d115c7e453', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Clear fallen branches from the tree line after the storm', '60022206-074c-4b73-bb83-63ed72372617', 'whenever', 'not_started', '2026-11-25', 'One branch nearly took out the mailbox. The geese were thrilled.', NULL, NULL, NULL, 180, '2026-03-26 14:27:28+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('e9399fa9-f4e0-45e8-997f-4097090dc2a1', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Till under the cover crop before spring planting', '60022206-074c-4b73-bb83-63ed72372617', 'whenever', 'not_started', NULL, 'Rye and clover, mixed in clean. Soil''s better for it.', NULL, NULL, NULL, 120, '2026-06-01 15:15:36+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('7a689278-fd27-42fb-891d-3b9702383e65', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Run the annual (unannounced) farm-wide fire drill', 'c7ac2347-5acf-4c1a-bc0e-27ed2f1144e9', 'whenever', 'done', NULL, 'Nobody was told. Nobody is ever told. That''s the point, Dwight says.', NULL, NULL, NULL, 20, '2026-05-10 06:16:16+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 10:03:15+00'),
  ('cd302ce1-bd1d-4ac1-b67c-71778aa96219', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Inspect the fire extinguishers in the barn', 'c7ac2347-5acf-4c1a-bc0e-27ed2f1144e9', 'soon', 'not_started', NULL, 'All charged. All within date. A rare, fully compliant afternoon.', NULL, NULL, '1bbc1150-b09f-408f-adf1-f1590c06fbab', 60, '2026-04-27 15:11:24+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('13f81fae-0699-41b3-a0c1-ace102d95d90', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Replace the smoke detector batteries across the property', 'c7ac2347-5acf-4c1a-bc0e-27ed2f1144e9', 'whenever', 'not_started', NULL, 'Fourteen detectors. Dwight insists this is not excessive.', NULL, NULL, '502be97f-5b8e-4cce-ad68-4175a221757e', 15, '2026-06-26 08:26:11+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('d8fd562d-7cd5-445d-9548-676f9a5ae008', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Clear brush from around the propane tank', 'c7ac2347-5acf-4c1a-bc0e-27ed2f1144e9', 'urgent', 'not_started', NULL, 'A whole season''s growth. It had become load-bearing.', NULL, NULL, NULL, 45, '2026-04-22 21:51:04+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('38e16680-3d47-443b-a979-3d3c066df962', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Test the bunker''s fire suppression system', 'c7ac2347-5acf-4c1a-bc0e-27ed2f1144e9', 'soon', 'done', '2026-05-19', 'Worked as designed. Slightly too well. The bunker smells like foam now.', NULL, NULL, '97684a5c-ce9b-4b8a-8e4a-9e736931f109', 45, '2026-04-04 11:24:36+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 15:26:26+00'),
  ('6cb4a6fc-0b1a-4ed6-a352-bca774b9c3a4', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Restock the burn barrel safety kit', 'c7ac2347-5acf-4c1a-bc0e-27ed2f1144e9', 'soon', 'not_started', NULL, 'Gloves, a bucket of sand, and a stern handwritten warning label.', NULL, NULL, NULL, 90, '2026-05-30 17:51:36+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('dd4a930e-2c28-4a8d-b7ca-0b867eada97c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Repair the hose reel by the barn', 'c7ac2347-5acf-4c1a-bc0e-27ed2f1144e9', 'whenever', 'in_progress', '2026-07-30', 'The crank had seized. WD-40 and persistence solved it.', NULL, NULL, '1bbc1150-b09f-408f-adf1-f1590c06fbab', 30, '2026-06-17 06:53:20+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('ee6e7fe6-0ece-4070-9194-9df3bb557768', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Review the fire escape route with Mose', 'c7ac2347-5acf-4c1a-bc0e-27ed2f1144e9', 'whenever', 'in_progress', '2026-09-01', 'He already knew it. He drew it from memory, unprompted.', NULL, NULL, NULL, 30, '2026-04-01 19:33:27+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('944f5592-4c56-44f0-ae8a-5bf556c86e1c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Change the oil in the tractor before the next big plow', 'f7dec3eb-441f-44ef-a8e4-860e5b280371', 'urgent', 'in_progress', '2026-08-28', 'Overdue by a few hundred hours. It forgave us.', NULL, NULL, NULL, 30, '2026-03-02 09:54:08+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('92ce94cf-3bd6-45a9-bbb3-23f525a3dfac', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Sharpen the plow blades before the fall till', 'f7dec3eb-441f-44ef-a8e4-860e5b280371', 'whenever', 'done', NULL, 'Took the edge back to factory sharp, more or less.', NULL, NULL, '1bbc1150-b09f-408f-adf1-f1590c06fbab', 30, '2026-06-23 10:16:17+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 22:41:08+00'),
  ('d46c67e5-a6d3-4f2b-b9e2-f90b5429fbf1', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Fix the flat tire on the flatbed trailer', 'f7dec3eb-441f-44ef-a8e4-860e5b280371', 'soon', 'not_started', '2026-10-16', 'A nail from the fence-repair pile. Ironic, given the fence.', NULL, NULL, '1bbc1150-b09f-408f-adf1-f1590c06fbab', 180, '2026-03-25 06:36:33+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('56d28867-b98a-4d8e-a71e-6eb781085a0f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Service the wood chipper before hedge-clearing season', 'f7dec3eb-441f-44ef-a8e4-860e5b280371', 'soon', 'in_progress', NULL, 'Blades sharpened, belt tightened. Ready to eat branches responsibly.', NULL, NULL, NULL, 30, '2026-07-05 13:30:20+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('abebaf9c-9115-43a0-b8a0-5872e440ed31', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Replace the tractor''s dead headlight', 'f7dec3eb-441f-44ef-a8e4-860e5b280371', 'soon', 'in_progress', NULL, 'Field work after dark is not recommended. Now it''s possible again.', 41.591091, -75.261507, NULL, 30, '2026-05-01 14:57:39+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL);

INSERT INTO tasks (id, farm_id, title, category_id, priority, status, due_date, notes, lat, lng, location_id, estimated_minutes, created_at, created_by, completed_at)
VALUES
  ('4ac69b13-b221-44d6-8b45-0722d877d316', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Grease the thresher''s bearings before harvest week', 'f7dec3eb-441f-44ef-a8e4-860e5b280371', 'urgent', 'done', NULL, 'Squeaked like a haunted house prop. Now silent.', NULL, NULL, NULL, 30, '2026-05-10 09:57:07+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-28 12:18:24+00'),
  ('da19283f-57e2-4be7-8626-e1572c056299', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Repair the fence-post driver''s cracked handle', 'f7dec3eb-441f-44ef-a8e4-860e5b280371', 'whenever', 'not_started', '2026-09-29', 'Duct tape and a length of pipe. Structurally questionable. Working fine.', 41.591091, -75.261507, NULL, 60, '2026-04-02 12:27:49+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('8922c6e9-784a-4867-a173-ad4c8a294817', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Tune up the chainsaw before hedge-laying season', 'f7dec3eb-441f-44ef-a8e4-860e5b280371', 'urgent', 'in_progress', NULL, 'New chain, fresh mix. Ready for the blackthorn.', NULL, NULL, '1bbc1150-b09f-408f-adf1-f1590c06fbab', 30, '2026-04-05 11:41:09+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('06be9f14-bdd6-495d-853b-1d91a7d408a2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'File the farm''s annual tax paperwork', 'fc4aa87e-9e1a-4e29-9a6b-d610b55de993', 'soon', 'in_progress', '2026-07-13', 'Filed early. Dwight reviewed it three times for typos that weren''t there.', NULL, NULL, NULL, 240, '2026-07-09 15:09:04+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('d06c3597-de4b-45b4-ba7a-eda287c056d2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Renew the B&B''s county health inspection certificate', 'fc4aa87e-9e1a-4e29-9a6b-d610b55de993', 'whenever', 'in_progress', '2026-10-26', 'Passed with one note about the outhouse''s ''rustic charm''.', NULL, NULL, NULL, 45, '2026-05-22 11:21:15+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('322770e4-c3c7-4e91-b213-96c0464747d4', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Update the liability insurance for the haunted maze', 'fc4aa87e-9e1a-4e29-9a6b-d610b55de993', 'whenever', 'done', NULL, 'The premium went up. So did the scare factor. Related, probably.', NULL, NULL, NULL, 20, '2026-05-01 07:52:41+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-16 18:14:13+00'),
  ('e506a02e-9798-47b2-8aff-39fd83c4ac3d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Submit the beet crop insurance claim after the hailstorm', 'fc4aa87e-9e1a-4e29-9a6b-d610b55de993', 'urgent', 'done', NULL, 'Photographic evidence attached. The hail was, in fact, beet-sized.', NULL, NULL, NULL, 60, '2026-03-13 21:24:12+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-15 07:46:50+00'),
  ('ddfc820e-69a1-4585-affa-e9047ba5e354', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'File the volunteer sheriff''s department expense report', 'fc4aa87e-9e1a-4e29-9a6b-d610b55de993', 'urgent', 'not_started', NULL, 'Mostly gas and one replacement badge holder.', NULL, NULL, NULL, 15, '2026-04-29 14:55:28+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('5801375a-9c57-4b23-813f-d3af12f361ff', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Renew the concealed carry permit before it lapses', 'fc4aa87e-9e1a-4e29-9a6b-d610b55de993', 'urgent', 'done', NULL, 'Filed with two months to spare, which counts as reckless by Dwight''s standards.', NULL, NULL, NULL, 45, '2026-05-03 09:57:57+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-03 14:20:28+00'),
  ('191ee997-7624-4289-92cf-c91fbc217520', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Organize the farm office filing cabinet', 'fc4aa87e-9e1a-4e29-9a6b-d610b55de993', 'whenever', 'not_started', NULL, 'Alphabetized, then re-alphabetized by a system only Dwight understands.', 41.574454, -75.243744, NULL, 45, '2026-03-18 15:07:46+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('71aa9c44-9aaf-4e70-9fea-3d706ed6b4ee', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Rotate the canned goods in the bunker by expiration date', '63c3a991-2381-4f5c-b0ea-63b1010e7c2b', 'whenever', 'done', NULL, 'Oldest cans moved to the front. A full afternoon, done with military precision.', 41.580327, -75.263172, NULL, 20, '2026-03-24 09:10:20+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-19 09:26:32+00'),
  ('388eefe7-5dd9-4eb2-b1eb-7cf16c81749f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Restock the water purification tablets', '63c3a991-2381-4f5c-b0ea-63b1010e7c2b', 'soon', 'in_progress', '2026-10-27', 'Enough for a small militia, per usual bunker logic.', NULL, NULL, '97684a5c-ce9b-4b8a-8e4a-9e736931f109', 20, '2026-05-28 21:17:41+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('38963936-bece-4f71-85a7-5876537c91ed', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Inventory the gas masks and replace the filters', '63c3a991-2381-4f5c-b0ea-63b1010e7c2b', 'whenever', 'done', NULL, 'All six accounted for. One had a suspicious beet smell.', NULL, NULL, '97684a5c-ce9b-4b8a-8e4a-9e736931f109', 90, '2026-05-08 16:06:24+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-23 17:31:49+00'),
  ('a98b69a9-fb3f-4d06-a571-6d13954472fd', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Test the hand-crank emergency radio', '63c3a991-2381-4f5c-b0ea-63b1010e7c2b', 'soon', 'done', NULL, 'Static, then a farm report from a station three counties over. Success.', NULL, NULL, '97684a5c-ce9b-4b8a-8e4a-9e736931f109', 30, '2026-03-28 14:23:35+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-24 12:08:11+00'),
  ('0f1ab644-b663-4181-ac78-f3e0895f256a', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Top off the propane reserve tanks', '63c3a991-2381-4f5c-b0ea-63b1010e7c2b', 'urgent', 'done', NULL, 'Filled to the recommended level, then filled a bit more, just in case.', NULL, NULL, NULL, 180, '2026-05-06 10:15:36+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 07:21:35+00'),
  ('88eac54c-219d-4838-8fd7-624ff27b95e5', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Restock the emergency beet rations shelf', '63c3a991-2381-4f5c-b0ea-63b1010e7c2b', 'soon', 'in_progress', NULL, 'Canned, pickled, and dehydrated. All beet-based. As intended.', NULL, NULL, '97684a5c-ce9b-4b8a-8e4a-9e736931f109', 45, '2026-06-02 14:30:59+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('72d44b7b-6ba5-443d-85d5-a37173710393', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Check expiration dates on the emergency ration kits', '63c3a991-2381-4f5c-b0ea-63b1010e7c2b', 'whenever', 'not_started', '2026-10-06', 'Two boxes expired in 2019. Quietly replaced, no questions asked.', NULL, NULL, '97684a5c-ce9b-4b8a-8e4a-9e736931f109', 180, '2026-07-07 14:38:32+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('d4c164cf-3452-44fe-8cfd-05bdf1cb90e2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Call the regional grocery chain about a beet supply contract', 'b956ffcd-e546-475c-a043-95ea847b7cc0', 'soon', 'done', NULL, 'They wanted a sample box. Sent two, in case one got ''lost in transit''.', NULL, NULL, NULL, 180, '2026-06-17 09:43:54+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-23 21:10:04+00'),
  ('bf56b2ec-3f26-4d92-b3ee-dce265d9c166', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Follow up with a restaurant lead about sourcing beets locally', 'b956ffcd-e546-475c-a043-95ea847b7cc0', 'soon', 'not_started', NULL, 'Chef wants exclusivity. Dwight is entertaining the idea, slowly.', NULL, NULL, NULL, 45, '2026-05-09 15:18:38+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('dd7a2a6b-ce7e-4e88-a819-b0b7949bd5b5', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Negotiate the county fair beet booth pricing', 'b956ffcd-e546-475c-a043-95ea847b7cc0', 'whenever', 'done', NULL, 'Held firm on the corner spot. Won it. The corner spot matters, apparently.', NULL, NULL, NULL, 120, '2026-06-26 08:00:44+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 19:58:11+00');

INSERT INTO tasks (id, farm_id, title, category_id, priority, status, due_date, notes, lat, lng, location_id, estimated_minutes, created_at, created_by, completed_at)
VALUES
  ('e2edf5ef-0281-43aa-b987-920039bdf412', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Draft a wholesale pitch for the honey line', 'b956ffcd-e546-475c-a043-95ea847b7cc0', 'soon', 'in_progress', '2026-07-13', 'First draft included a threat disguised as a closing line. Revised.', NULL, NULL, NULL, 45, '2026-07-09 17:01:03+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('db25bcc7-e9f3-4940-b202-714722c8fcdb', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Chase down payment from a beet buyer who''s gone quiet', 'b956ffcd-e546-475c-a043-95ea847b7cc0', 'whenever', 'not_started', NULL, 'Third invoice sent. Politely. Increasingly less politely.', NULL, NULL, NULL, 30, '2026-07-10 15:51:54+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('58deed68-9018-4a47-aab1-7d1c640e8f6e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Renew the roadside beet stand''s vendor permit', 'b956ffcd-e546-475c-a043-95ea847b7cc0', 'urgent', 'done', '2026-04-23', 'Approved without incident, which felt suspicious.', NULL, NULL, NULL, 60, '2026-04-17 08:26:46+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-01 13:30:05+00'),
  ('9775fcfa-459c-42f0-9dbe-417bd48a28e5', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Print new price tags for the farm stand', 'b956ffcd-e546-475c-a043-95ea847b7cc0', 'urgent', 'done', NULL, 'Beets went up a dime. Honey stayed the same, out of principle.', NULL, NULL, NULL, 180, '2026-07-03 14:01:06+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-04 19:34:51+00'),
  ('9f68a485-eb2a-49ff-a6ab-ab8fe79be97b', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Update the farm''s online store listing', 'b956ffcd-e546-475c-a043-95ea847b7cc0', 'urgent', 'not_started', NULL, 'New photos. The goat photobombed three of them. Kept all three.', NULL, NULL, NULL, 20, '2026-04-02 15:12:35+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('6e2e3288-a87c-4185-8823-de1db31f0f6a', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Cut this year''s corn maze pattern', 'c30dc3a9-4136-4b72-94ca-6e66d464af3d', 'soon', 'done', NULL, 'A beet silhouette, visible only from the air. Ambitious. Slightly lopsided.', NULL, NULL, '07e359a3-c3b5-4606-b62c-0d8300141448', 120, '2026-06-01 19:34:10+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 18:48:41+00'),
  ('7f615527-2c0a-41b6-badd-7e564ca851be', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Restock fake blood for the haunted house', 'c30dc3a9-4136-4b72-94ca-6e66d464af3d', 'soon', 'not_started', NULL, 'Corn syrup and food coloring. The recipe is a closely guarded secret.', NULL, NULL, NULL, 90, '2026-05-28 10:14:21+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('f071ad0b-439b-4163-a928-19ca67dc4c28', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Test the haunted house''s animatronic scarecrow', 'c30dc3a9-4136-4b72-94ca-6e66d464af3d', 'urgent', 'not_started', '2026-11-19', 'Jump-scared Mose. He did not react. He never reacts.', NULL, NULL, NULL, 90, '2026-04-27 17:54:40+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('69eb44e2-44e3-4148-92fa-4ee902efa6fd', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Replace the burnt-out lights along the maze path', 'c30dc3a9-4136-4b72-94ca-6e66d464af3d', 'urgent', 'done', NULL, 'Half the maze was pitch black. Now appropriately, deliberately dim.', NULL, NULL, '07e359a3-c3b5-4606-b62c-0d8300141448', 120, '2026-05-14 22:06:42+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-21 12:17:05+00'),
  ('93926fe1-f12f-4571-9731-c3e47fe39efc', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Recruit local teens as haunted house actors', 'c30dc3a9-4136-4b72-94ca-6e66d464af3d', 'soon', 'done', NULL, 'Pay is in schrute-bucks and pizza. Turnout was surprisingly strong.', NULL, NULL, NULL, 90, '2026-05-11 18:14:28+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 09:53:04+00'),
  ('3c8407ff-e732-4d18-85cd-598e49211280', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Build a new jump-scare prop for the barn section', 'c30dc3a9-4136-4b72-94ca-6e66d464af3d', 'soon', 'done', NULL, 'A taxidermied fox on a spring-loaded arm. Effective. Possibly too effective.', NULL, NULL, NULL, 90, '2026-04-23 15:03:47+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 12:58:37+00'),
  ('96bb0531-0dcf-43c2-b971-10f5276cb9ee', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Order more hay bales for the maze walls', 'c30dc3a9-4136-4b72-94ca-6e66d464af3d', 'urgent', 'done', NULL, 'Fifty bales. Structural, decorative, and mildly flammable, per the fire log.', NULL, NULL, '07e359a3-c3b5-4606-b62c-0d8300141448', 240, '2026-06-11 21:30:35+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 07:31:45+00'),
  ('3d324c99-65bd-4ea8-9102-1077d8b56b0b', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Print tickets for the Halloween haunted house event', 'c30dc3a9-4136-4b72-94ca-6e66d464af3d', 'whenever', 'done', NULL, 'Sold out the first weekend within a day. Second weekend added.', NULL, NULL, NULL, 15, '2026-04-07 16:52:19+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 20:40:23+00'),
  ('f6880308-2c44-415d-8dba-57a3226861bd', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Turn the compost pile before it overheats', '6287e686-8a3c-404d-a79e-2d1f5cf3e65b', 'whenever', 'done', '2026-06-22', 'Steam rising off it this morning. A good sign, apparently.', NULL, NULL, NULL, 30, '2026-05-05 09:45:58+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-29 12:18:25+00'),
  ('ad849efa-f395-4f21-8170-dca3b14e3f6b', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Spread manure on the fallow field before planting', '6287e686-8a3c-404d-a79e-2d1f5cf3e65b', 'whenever', 'in_progress', NULL, 'A full morning''s work. The smell followed everyone home.', NULL, NULL, '22a2ecfd-a5c4-4b55-a699-b057cfbb90b5', 15, '2026-04-10 16:17:08+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('79e3aa70-1c9e-45fd-a103-44e49a989edc', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Repair the manure spreader''s clogged chute', '6287e686-8a3c-404d-a79e-2d1f5cf3e65b', 'whenever', 'done', NULL, 'Cleared by hand. A task nobody volunteers for twice.', NULL, NULL, '1bbc1150-b09f-408f-adf1-f1590c06fbab', 20, '2026-04-03 16:06:04+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-15 19:38:34+00'),
  ('e75ed246-4c99-4b2e-bc40-0121d8783f38', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Clean out the goat pen bedding', '6287e686-8a3c-404d-a79e-2d1f5cf3e65b', 'whenever', 'done', '2026-06-09', 'Fresh straw down. The goats inspected it and approved.', 41.563649, -75.259243, NULL, 60, '2026-05-24 21:59:45+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-16 21:05:47+00'),
  ('417eda0c-0e6a-46f1-aa99-ccde9f96466f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Haul away the aged compost for sale to neighbors', '6287e686-8a3c-404d-a79e-2d1f5cf3e65b', 'urgent', 'not_started', NULL, 'Sold three trailer-loads. Compost is, unexpectedly, a solid revenue line.', NULL, NULL, NULL, 15, '2026-03-31 17:35:07+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('36826cd5-cbe9-4606-88e8-0d65061c8fec', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Test the compost pile''s nitrogen levels', '6287e686-8a3c-404d-a79e-2d1f5cf3e65b', 'whenever', 'done', '2026-03-08', 'Right in range. Mose predicted it within a percentage point.', NULL, NULL, NULL, 20, '2026-03-01 06:59:14+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-09 12:25:12+00'),
  ('75daf29d-6296-475d-b8be-8c0f56920692', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'Muck out the barn stalls', '6287e686-8a3c-404d-a79e-2d1f5cf3e65b', 'soon', 'in_progress', NULL, 'Weekly chore. Never gets easier. Always gets done.', NULL, NULL, NULL, 90, '2026-07-07 12:34:47+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL);

-- ---------------------------------------------------------------------------
-- Task completers (multi-person completion attribution)
-- ---------------------------------------------------------------------------
-- One row per person credited with finishing a done task: either a farm
-- member (user_id) or a free-text name (completer_name), never both. A
-- handful of tasks carry a mixed member + free-text pair (Dwight and Mose
-- worked it together); most done tasks carry zero or one.

INSERT INTO task_completers (task_id, user_id, completer_name)
VALUES
  ('f8bf8dcd-2ac9-4e3a-9e3d-0e1de537f3b7', NULL, 'Mose'),
  ('13752e12-9a16-45cb-bf9e-2fc61b6394f1', NULL, 'Mose'),
  ('7ca73e5c-c552-4ad5-a0c7-099b594dc739', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('f3572656-474e-4e49-a2fe-de517c2f8034', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('02facb2b-e626-452c-b85f-8c98b61443f0', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('d0648a52-4f8f-4b51-8927-a728df4648c6', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('6b072305-8faf-4285-a42f-28ba16e9656f', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('c70eb3f7-d9ce-4b1f-98a4-58e202c41b8b', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('c70eb3f7-d9ce-4b1f-98a4-58e202c41b8b', NULL, 'Mose'),
  ('2ba5820b-af54-4341-bfc3-a920a353bc37', NULL, 'Mose'),
  ('a6744dc2-bfcb-4504-a564-9c1cf9352a4d', NULL, 'Mose'),
  ('706aac4f-7f92-4f40-99cd-0428bc8d6d62', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('63e51f7f-6a9c-469a-ad25-537cb365d768', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('a8d424d8-ee04-4193-b7bd-051c06dbc9eb', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('96ef0e6e-5aa9-4870-9852-3cafb683a2c2', NULL, 'Mose'),
  ('152ad141-87e4-4a37-9327-003414a12f29', NULL, 'Mose'),
  ('130b9d85-b844-4e99-be78-5ecc08a9c08c', NULL, 'Mose'),
  ('9f747efb-8253-4fb5-ab66-f0e0ac784669', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('ef922ec7-a320-4b66-99f9-cdb5d9720984', NULL, 'Mose'),
  ('0bd8fa70-e870-440b-bf75-e1c3723b5564', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('bc94a61a-a629-45bb-aec8-c1d08114d184', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('1dfbdb28-6ddc-4f55-881f-d92c7c0fcf0d', NULL, 'Mose'),
  ('4cdd13da-0f2b-457c-80ab-eaaea441923e', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('4cdd13da-0f2b-457c-80ab-eaaea441923e', NULL, 'Mose'),
  ('5c2a0dc5-188b-4260-bf8d-21e947fff22c', NULL, 'Mose');

INSERT INTO task_completers (task_id, user_id, completer_name)
VALUES
  ('7a689278-fd27-42fb-891d-3b9702383e65', NULL, 'Mose'),
  ('38e16680-3d47-443b-a979-3d3c066df962', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('92ce94cf-3bd6-45a9-bbb3-23f525a3dfac', NULL, 'Mose'),
  ('4ac69b13-b221-44d6-8b45-0722d877d316', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('322770e4-c3c7-4e91-b213-96c0464747d4', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('e506a02e-9798-47b2-8aff-39fd83c4ac3d', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('5801375a-9c57-4b23-813f-d3af12f361ff', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('71aa9c44-9aaf-4e70-9fea-3d706ed6b4ee', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('38963936-bece-4f71-85a7-5876537c91ed', NULL, 'Mose'),
  ('a98b69a9-fb3f-4d06-a571-6d13954472fd', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('0f1ab644-b663-4181-ac78-f3e0895f256a', NULL, 'Mose'),
  ('d4c164cf-3452-44fe-8cfd-05bdf1cb90e2', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('d4c164cf-3452-44fe-8cfd-05bdf1cb90e2', NULL, 'Mose'),
  ('dd7a2a6b-ce7e-4e88-a819-b0b7949bd5b5', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('58deed68-9018-4a47-aab1-7d1c640e8f6e', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('6e2e3288-a87c-4185-8823-de1db31f0f6a', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('93926fe1-f12f-4571-9731-c3e47fe39efc', NULL, 'Mose'),
  ('3c8407ff-e732-4d18-85cd-598e49211280', NULL, 'Mose'),
  ('96bb0531-0dcf-43c2-b971-10f5276cb9ee', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('3d324c99-65bd-4ea8-9102-1077d8b56b0b', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('f6880308-2c44-415d-8dba-57a3226861bd', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('79e3aa70-1c9e-45fd-a103-44e49a989edc', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('e75ed246-4c99-4b2e-bc40-0121d8783f38', NULL, 'Mose'),
  ('36826cd5-cbe9-4606-88e8-0d65061c8fec', NULL, 'Mose');

-- ---------------------------------------------------------------------------
-- Task tags
-- ---------------------------------------------------------------------------

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('d1e09fac-9dda-4db0-8bfa-645284302ebd', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('d1e09fac-9dda-4db0-8bfa-645284302ebd', 'fae69544-43fb-4c13-b01d-8c5d599c9dee'),
  ('f8bf8dcd-2ac9-4e3a-9e3d-0e1de537f3b7', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('f8bf8dcd-2ac9-4e3a-9e3d-0e1de537f3b7', 'a1233eda-54a4-4380-93de-99a1e0e3d1e5'),
  ('13752e12-9a16-45cb-bf9e-2fc61b6394f1', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('c27e7a5a-b604-4947-9f58-d8a3edfa613c', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('c27e7a5a-b604-4947-9f58-d8a3edfa613c', 'a1233eda-54a4-4380-93de-99a1e0e3d1e5'),
  ('25476c46-ed4e-446c-83ac-d91263954b41', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('7ca73e5c-c552-4ad5-a0c7-099b594dc739', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('7ca73e5c-c552-4ad5-a0c7-099b594dc739', 'fae69544-43fb-4c13-b01d-8c5d599c9dee'),
  ('db868f19-f432-40e6-b7fa-f9cf4115298b', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('fc998e3f-4600-4a8f-a64b-c4f5a684f2ce', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('70852bed-47e5-4025-9cd7-7b42ab5ec410', 'c157135f-22c9-449d-a568-a926d44dab70'),
  ('70852bed-47e5-4025-9cd7-7b42ab5ec410', '3bfbe071-dd10-4b64-9d1e-caf8504b3ea2'),
  ('f3572656-474e-4e49-a2fe-de517c2f8034', 'c157135f-22c9-449d-a568-a926d44dab70'),
  ('f3572656-474e-4e49-a2fe-de517c2f8034', '717dd376-4d73-4112-b9d1-ed5f1d6e9c32'),
  ('02facb2b-e626-452c-b85f-8c98b61443f0', 'c157135f-22c9-449d-a568-a926d44dab70'),
  ('02facb2b-e626-452c-b85f-8c98b61443f0', '27646273-2ca9-4878-8125-ad408b76a806'),
  ('d0648a52-4f8f-4b51-8927-a728df4648c6', 'c157135f-22c9-449d-a568-a926d44dab70'),
  ('128257bf-4de2-4e8c-aad2-82f54ac8187c', 'c157135f-22c9-449d-a568-a926d44dab70'),
  ('128257bf-4de2-4e8c-aad2-82f54ac8187c', 'fb197a1e-c000-4874-b132-b4d60f71f4b2'),
  ('affdb6da-8dc2-4f76-8a39-4bc6fe2e4521', 'c157135f-22c9-449d-a568-a926d44dab70'),
  ('affdb6da-8dc2-4f76-8a39-4bc6fe2e4521', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('04cdef75-0b62-406c-9655-e02481913fb3', 'c157135f-22c9-449d-a568-a926d44dab70'),
  ('04cdef75-0b62-406c-9655-e02481913fb3', '417d34b7-eda3-4bd2-9333-ac2d4c630e76');

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('6b072305-8faf-4285-a42f-28ba16e9656f', 'c157135f-22c9-449d-a568-a926d44dab70'),
  ('c70eb3f7-d9ce-4b1f-98a4-58e202c41b8b', '8f5b6c7a-12bd-40d4-9cc4-fe81c0a5ed5f'),
  ('c70eb3f7-d9ce-4b1f-98a4-58e202c41b8b', '0d3d3565-1c0f-46f8-9127-1aa2d207066f'),
  ('06f2b0ba-f3b7-46d9-9357-5b6eba782432', '8f5b6c7a-12bd-40d4-9cc4-fe81c0a5ed5f'),
  ('06f2b0ba-f3b7-46d9-9357-5b6eba782432', '4b3bb18a-5935-4471-b28e-87560692cf79'),
  ('2ba5820b-af54-4341-bfc3-a920a353bc37', '477452f8-1fe9-4714-bf21-ab2c751381c6'),
  ('a6744dc2-bfcb-4504-a564-9c1cf9352a4d', '5bb92c0a-bfd3-49cf-9533-523499a4408c'),
  ('a6744dc2-bfcb-4504-a564-9c1cf9352a4d', 'fae69544-43fb-4c13-b01d-8c5d599c9dee'),
  ('706aac4f-7f92-4f40-99cd-0428bc8d6d62', '8f5b6c7a-12bd-40d4-9cc4-fe81c0a5ed5f'),
  ('46e55f5e-e680-43bc-8a3d-e74b8668569c', '0d3d3565-1c0f-46f8-9127-1aa2d207066f'),
  ('067d3cc5-63b8-4f56-a9fb-cefe27edb91d', '0d3d3565-1c0f-46f8-9127-1aa2d207066f'),
  ('067d3cc5-63b8-4f56-a9fb-cefe27edb91d', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('067d3cc5-63b8-4f56-a9fb-cefe27edb91d', '025b30d0-0aaf-46f8-8fd2-78a40c613f2d'),
  ('63e51f7f-6a9c-469a-ad25-537cb365d768', '0d3d3565-1c0f-46f8-9127-1aa2d207066f'),
  ('63e51f7f-6a9c-469a-ad25-537cb365d768', '9dfea4a8-eab9-4657-95bc-44223453a5db'),
  ('a8d424d8-ee04-4193-b7bd-051c06dbc9eb', 'f4608832-8baa-4198-89bc-5ef6a51faa2b'),
  ('17f076df-fc10-4f34-9e83-d1236b02a1dc', 'f4608832-8baa-4198-89bc-5ef6a51faa2b'),
  ('96ef0e6e-5aa9-4870-9852-3cafb683a2c2', 'f4608832-8baa-4198-89bc-5ef6a51faa2b'),
  ('2d5e0e20-28c3-48c4-a54b-87f6f6ed59ec', 'f4608832-8baa-4198-89bc-5ef6a51faa2b'),
  ('c66ba2b1-1420-49a4-8aeb-1e42d0b54aaf', 'f4608832-8baa-4198-89bc-5ef6a51faa2b'),
  ('4d883b97-2ec7-4e4d-8777-d8d8b058869c', 'f4608832-8baa-4198-89bc-5ef6a51faa2b'),
  ('152ad141-87e4-4a37-9327-003414a12f29', 'f4608832-8baa-4198-89bc-5ef6a51faa2b'),
  ('152ad141-87e4-4a37-9327-003414a12f29', 'f9d713d0-213d-4c4a-8a22-9b08e774a653'),
  ('092b7dc7-4ba5-4e21-95b9-c2455eb3f369', 'f4608832-8baa-4198-89bc-5ef6a51faa2b'),
  ('130b9d85-b844-4e99-be78-5ecc08a9c08c', '6285cfbd-a2a0-4af9-a128-cadd60638a5e');

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('d9c4e4ac-7b0b-495a-8762-14bef511e775', '6285cfbd-a2a0-4af9-a128-cadd60638a5e'),
  ('a448ade1-7bfb-47cf-9ee6-f7aa9904215a', '4b3bb18a-5935-4471-b28e-87560692cf79'),
  ('9f747efb-8253-4fb5-ab66-f0e0ac784669', 'cc36a725-3c61-4f5c-aacc-0e53c1b12971'),
  ('d533b324-1c42-4dee-8a31-2995f17dc36c', 'cc36a725-3c61-4f5c-aacc-0e53c1b12971'),
  ('ef922ec7-a320-4b66-99f9-cdb5d9720984', '6285cfbd-a2a0-4af9-a128-cadd60638a5e'),
  ('0bd8fa70-e870-440b-bf75-e1c3723b5564', '6285cfbd-a2a0-4af9-a128-cadd60638a5e'),
  ('0bd8fa70-e870-440b-bf75-e1c3723b5564', 'fae69544-43fb-4c13-b01d-8c5d599c9dee'),
  ('e3a5f2dd-839e-437f-979e-fef462b15b19', 'cc36a725-3c61-4f5c-aacc-0e53c1b12971'),
  ('bc94a61a-a629-45bb-aec8-c1d08114d184', 'a1233eda-54a4-4380-93de-99a1e0e3d1e5'),
  ('bc94a61a-a629-45bb-aec8-c1d08114d184', '0cd0f30e-a6dc-4c1f-8455-e99a41bbc0e6'),
  ('1dfbdb28-6ddc-4f55-881f-d92c7c0fcf0d', '0cd0f30e-a6dc-4c1f-8455-e99a41bbc0e6'),
  ('1dfbdb28-6ddc-4f55-881f-d92c7c0fcf0d', 'fae69544-43fb-4c13-b01d-8c5d599c9dee'),
  ('788b8fa6-5cfe-4342-a5af-2c6f4ccf41d4', '32de5002-f608-48a0-98fa-921d2a3d5541'),
  ('4cdd13da-0f2b-457c-80ab-eaaea441923e', 'd3a5b481-bc73-4f90-8ef2-53459fbaaf2d'),
  ('a3b0e74b-4630-4655-9a45-33d115c7e453', '4b3bb18a-5935-4471-b28e-87560692cf79'),
  ('e9399fa9-f4e0-45e8-997f-4097090dc2a1', '0cd0f30e-a6dc-4c1f-8455-e99a41bbc0e6'),
  ('7a689278-fd27-42fb-891d-3b9702383e65', '9dfea4a8-eab9-4657-95bc-44223453a5db'),
  ('cd302ce1-bd1d-4ac1-b67c-71778aa96219', '9dfea4a8-eab9-4657-95bc-44223453a5db'),
  ('13f81fae-0699-41b3-a0c1-ace102d95d90', '9dfea4a8-eab9-4657-95bc-44223453a5db'),
  ('d8fd562d-7cd5-445d-9548-676f9a5ae008', '9dfea4a8-eab9-4657-95bc-44223453a5db'),
  ('38e16680-3d47-443b-a979-3d3c066df962', '9dfea4a8-eab9-4657-95bc-44223453a5db'),
  ('38e16680-3d47-443b-a979-3d3c066df962', '0d3d3565-1c0f-46f8-9127-1aa2d207066f'),
  ('6cb4a6fc-0b1a-4ed6-a352-bca774b9c3a4', '9dfea4a8-eab9-4657-95bc-44223453a5db'),
  ('dd4a930e-2c28-4a8d-b7ca-0b867eada97c', '9dfea4a8-eab9-4657-95bc-44223453a5db'),
  ('ee6e7fe6-0ece-4070-9194-9df3bb557768', '9dfea4a8-eab9-4657-95bc-44223453a5db');

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('ee6e7fe6-0ece-4070-9194-9df3bb557768', 'fae69544-43fb-4c13-b01d-8c5d599c9dee'),
  ('944f5592-4c56-44f0-ae8a-5bf556c86e1c', 'a1233eda-54a4-4380-93de-99a1e0e3d1e5'),
  ('92ce94cf-3bd6-45a9-bbb3-23f525a3dfac', '0cd0f30e-a6dc-4c1f-8455-e99a41bbc0e6'),
  ('abebaf9c-9115-43a0-b8a0-5872e440ed31', 'a1233eda-54a4-4380-93de-99a1e0e3d1e5'),
  ('4ac69b13-b221-44d6-8b45-0722d877d316', 'd0b9bee0-76f7-4bbd-ba7b-1b54c64e7d8c'),
  ('d06c3597-de4b-45b4-ba7a-eda287c056d2', 'c157135f-22c9-449d-a568-a926d44dab70'),
  ('322770e4-c3c7-4e91-b213-96c0464747d4', 'd0b9bee0-76f7-4bbd-ba7b-1b54c64e7d8c'),
  ('e506a02e-9798-47b2-8aff-39fd83c4ac3d', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('ddfc820e-69a1-4585-affa-e9047ba5e354', 'f4608832-8baa-4198-89bc-5ef6a51faa2b'),
  ('5801375a-9c57-4b23-813f-d3af12f361ff', '5bb92c0a-bfd3-49cf-9533-523499a4408c'),
  ('71aa9c44-9aaf-4e70-9fea-3d706ed6b4ee', '0d3d3565-1c0f-46f8-9127-1aa2d207066f'),
  ('71aa9c44-9aaf-4e70-9fea-3d706ed6b4ee', '025b30d0-0aaf-46f8-8fd2-78a40c613f2d'),
  ('388eefe7-5dd9-4eb2-b1eb-7cf16c81749f', '0d3d3565-1c0f-46f8-9127-1aa2d207066f'),
  ('388eefe7-5dd9-4eb2-b1eb-7cf16c81749f', '417d34b7-eda3-4bd2-9333-ac2d4c630e76'),
  ('38963936-bece-4f71-85a7-5876537c91ed', '0d3d3565-1c0f-46f8-9127-1aa2d207066f'),
  ('38963936-bece-4f71-85a7-5876537c91ed', '5bb92c0a-bfd3-49cf-9533-523499a4408c'),
  ('a98b69a9-fb3f-4d06-a571-6d13954472fd', '0d3d3565-1c0f-46f8-9127-1aa2d207066f'),
  ('0f1ab644-b663-4181-ac78-f3e0895f256a', '0d3d3565-1c0f-46f8-9127-1aa2d207066f'),
  ('88eac54c-219d-4838-8fd7-624ff27b95e5', '0d3d3565-1c0f-46f8-9127-1aa2d207066f'),
  ('88eac54c-219d-4838-8fd7-624ff27b95e5', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('72d44b7b-6ba5-443d-85d5-a37173710393', '0d3d3565-1c0f-46f8-9127-1aa2d207066f'),
  ('72d44b7b-6ba5-443d-85d5-a37173710393', '025b30d0-0aaf-46f8-8fd2-78a40c613f2d'),
  ('d4c164cf-3452-44fe-8cfd-05bdf1cb90e2', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('bf56b2ec-3f26-4d92-b3ee-dce265d9c166', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('dd7a2a6b-ce7e-4e88-a819-b0b7949bd5b5', '460b24a6-7074-48d3-923e-283f8acc2d65');

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('e2edf5ef-0281-43aa-b987-920039bdf412', '83cb720c-2d64-480a-ba63-d4ef4c423598'),
  ('db25bcc7-e9f3-4940-b202-714722c8fcdb', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('58deed68-9018-4a47-aab1-7d1c640e8f6e', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('9775fcfa-459c-42f0-9dbe-417bd48a28e5', '460b24a6-7074-48d3-923e-283f8acc2d65'),
  ('9775fcfa-459c-42f0-9dbe-417bd48a28e5', '83cb720c-2d64-480a-ba63-d4ef4c423598'),
  ('9f68a485-eb2a-49ff-a6ab-ab8fe79be97b', '6285cfbd-a2a0-4af9-a128-cadd60638a5e'),
  ('6e2e3288-a87c-4185-8823-de1db31f0f6a', 'f044031e-d126-473d-ace2-8f9dddb21459'),
  ('6e2e3288-a87c-4185-8823-de1db31f0f6a', 'd0b9bee0-76f7-4bbd-ba7b-1b54c64e7d8c'),
  ('7f615527-2c0a-41b6-badd-7e564ca851be', 'd0b9bee0-76f7-4bbd-ba7b-1b54c64e7d8c'),
  ('f071ad0b-439b-4163-a928-19ca67dc4c28', 'd0b9bee0-76f7-4bbd-ba7b-1b54c64e7d8c'),
  ('f071ad0b-439b-4163-a928-19ca67dc4c28', 'fae69544-43fb-4c13-b01d-8c5d599c9dee'),
  ('69eb44e2-44e3-4148-92fa-4ee902efa6fd', 'd0b9bee0-76f7-4bbd-ba7b-1b54c64e7d8c'),
  ('69eb44e2-44e3-4148-92fa-4ee902efa6fd', 'f044031e-d126-473d-ace2-8f9dddb21459'),
  ('93926fe1-f12f-4571-9731-c3e47fe39efc', 'd0b9bee0-76f7-4bbd-ba7b-1b54c64e7d8c'),
  ('93926fe1-f12f-4571-9731-c3e47fe39efc', '4aace591-730b-462b-9458-2377cdfa4e56'),
  ('3c8407ff-e732-4d18-85cd-598e49211280', 'd0b9bee0-76f7-4bbd-ba7b-1b54c64e7d8c'),
  ('3c8407ff-e732-4d18-85cd-598e49211280', 'c1947427-4914-4128-bc13-b2c4309dc352'),
  ('96bb0531-0dcf-43c2-b971-10f5276cb9ee', 'd0b9bee0-76f7-4bbd-ba7b-1b54c64e7d8c'),
  ('96bb0531-0dcf-43c2-b971-10f5276cb9ee', '9dfea4a8-eab9-4657-95bc-44223453a5db'),
  ('3d324c99-65bd-4ea8-9102-1077d8b56b0b', 'd0b9bee0-76f7-4bbd-ba7b-1b54c64e7d8c'),
  ('f6880308-2c44-415d-8dba-57a3226861bd', '723c8c54-becd-4393-bd2e-9460f1f0e622'),
  ('ad849efa-f395-4f21-8170-dca3b14e3f6b', '6b6aa2a3-b92b-4ba1-8aa3-075ad9e0b61c'),
  ('79e3aa70-1c9e-45fd-a103-44e49a989edc', '6b6aa2a3-b92b-4ba1-8aa3-075ad9e0b61c'),
  ('e75ed246-4c99-4b2e-bc40-0121d8783f38', '6285cfbd-a2a0-4af9-a128-cadd60638a5e'),
  ('e75ed246-4c99-4b2e-bc40-0121d8783f38', '6b6aa2a3-b92b-4ba1-8aa3-075ad9e0b61c');

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('417eda0c-0e6a-46f1-aa99-ccde9f96466f', '723c8c54-becd-4393-bd2e-9460f1f0e622'),
  ('36826cd5-cbe9-4606-88e8-0d65061c8fec', '723c8c54-becd-4393-bd2e-9460f1f0e622'),
  ('36826cd5-cbe9-4606-88e8-0d65061c8fec', 'fae69544-43fb-4c13-b01d-8c5d599c9dee'),
  ('75daf29d-6296-475d-b8be-8c0f56920692', '6b6aa2a3-b92b-4ba1-8aa3-075ad9e0b61c');

-- ---------------------------------------------------------------------------
-- Task photos
-- ---------------------------------------------------------------------------

INSERT INTO task_photos (id, task_id, storage_path, caption, taken_at)
VALUES
  ('27be7ec9-5ec5-4693-8e5a-83289c230323', '9f747efb-8253-4fb5-ab66-f0e0ac784669', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a/9f747efb-8253-4fb5-ab66-f0e0ac784669/27be7ec9-5ec5-4693-8e5a-83289c230323.webp', 'Before', '2026-07-11 16:16:59.395621+00'),
  ('cb7a86b3-6a91-4893-9fd3-79270df1560d', 'f3572656-474e-4e49-a2fe-de517c2f8034', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a/f3572656-474e-4e49-a2fe-de517c2f8034/cb7a86b3-6a91-4893-9fd3-79270df1560d.webp', 'For the insurance claim', '2026-05-07 15:15:37.689677+00'),
  ('d18a4791-3352-4484-93d6-be5bb7d03c72', '6e2e3288-a87c-4185-8823-de1db31f0f6a', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a/6e2e3288-a87c-4185-8823-de1db31f0f6a/d18a4791-3352-4484-93d6-be5bb7d03c72.webp', 'Before', '2026-07-11 18:48:41.392379+00'),
  ('63b47c7b-63da-413b-a73b-71d3177d4291', '0bd8fa70-e870-440b-bf75-e1c3723b5564', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a/0bd8fa70-e870-440b-bf75-e1c3723b5564/63b47c7b-63da-413b-a73b-71d3177d4291.webp', 'Before', '2026-07-12 07:01:31.645558+00'),
  ('ed1e3950-cbb4-41bf-b91e-6bd26704d11c', '69eb44e2-44e3-4148-92fa-4ee902efa6fd', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a/69eb44e2-44e3-4148-92fa-4ee902efa6fd/ed1e3950-cbb4-41bf-b91e-6bd26704d11c.webp', 'For the insurance claim', '2026-05-21 12:17:05.162543+00');

-- ---------------------------------------------------------------------------
-- Task shopping items
-- ---------------------------------------------------------------------------

INSERT INTO task_shopping_items (id, task_id, name, checked, created_at)
VALUES
  ('0c64dd30-6c9d-41ca-95dd-a713d21f3913', 'd1e09fac-9dda-4db0-8bfa-645284302ebd', 'Canning jars', TRUE, '2026-03-23 18:56:34+00'),
  ('345c7d60-7f3f-4658-9176-91b1fc3731ed', 'd1e09fac-9dda-4db0-8bfa-645284302ebd', 'Pickling vinegar', FALSE, '2026-06-25 20:14:31+00'),
  ('1fe89488-86c9-4d42-9884-de08b8319230', 'd1e09fac-9dda-4db0-8bfa-645284302ebd', 'Fertilizer', FALSE, '2026-04-08 19:28:54+00'),
  ('2e5df770-8b54-4a2f-9d2a-0ce3d42f9f84', 'c27e7a5a-b604-4947-9f58-d8a3edfa613c', 'Pickling vinegar', FALSE, '2026-07-05 06:23:12+00'),
  ('a75e480f-2002-4e58-b434-a7baf6ad79bc', 'c27e7a5a-b604-4947-9f58-d8a3edfa613c', 'Beet seed packets', FALSE, '2026-05-31 22:27:03+00'),
  ('f404bfd5-d07c-40e7-b8d1-f8ea44d2561f', 'db868f19-f432-40e6-b7fa-f9cf4115298b', 'Fertilizer', TRUE, '2026-06-07 06:31:44+00'),
  ('7c6f7843-807b-4b21-9f86-454663ea01a3', 'db868f19-f432-40e6-b7fa-f9cf4115298b', 'Canning jars', FALSE, '2026-06-09 17:18:02+00'),
  ('89ff5001-4570-43ae-b825-7b2d202ec239', 'db868f19-f432-40e6-b7fa-f9cf4115298b', 'Beet seed packets', FALSE, '2026-05-14 18:00:07+00'),
  ('8e4c1d15-c2cf-4c5f-9ba1-c1898071284d', 'db868f19-f432-40e6-b7fa-f9cf4115298b', 'Pickling vinegar', TRUE, '2026-07-03 14:10:43+00'),
  ('461cd1bd-fd84-4058-9be1-8cd445f55d9d', 'f3572656-474e-4e49-a2fe-de517c2f8034', 'Firewood bundles', TRUE, '2026-05-21 10:02:08+00'),
  ('e7fcd304-56e9-4fc3-9f87-8954ad1229b2', 'f3572656-474e-4e49-a2fe-de517c2f8034', 'Replacement duvet covers', TRUE, '2026-07-07 17:35:09+00'),
  ('6fec53d3-c9fc-44bc-80ec-6b252e5b89cd', 'f3572656-474e-4e49-a2fe-de517c2f8034', 'Guest soap bars', FALSE, '2026-05-09 16:19:06+00'),
  ('50e8d202-301d-44a6-adcf-ebd159d4694e', 'f3572656-474e-4e49-a2fe-de517c2f8034', 'Honey jars', TRUE, '2026-05-01 13:30:05+00'),
  ('5f6a2d4a-a293-4153-8b8a-d1ae3040a86a', '128257bf-4de2-4e8c-aad2-82f54ac8187c', 'Honey jars', TRUE, '2026-06-11 16:27:47+00'),
  ('f36e4643-3a81-44ce-8158-3eaecd800be5', '128257bf-4de2-4e8c-aad2-82f54ac8187c', 'Replacement duvet covers', FALSE, '2026-06-12 07:46:04+00'),
  ('a0536bad-7487-4ce1-8adf-0defbd2ba5ac', '128257bf-4de2-4e8c-aad2-82f54ac8187c', 'Guest soap bars', FALSE, '2026-06-29 16:26:44+00'),
  ('c2e5a9cb-f409-4cc8-bbf9-a83490608e37', '6b072305-8faf-4285-a42f-28ba16e9656f', 'Guest soap bars', TRUE, '2026-06-07 09:12:04+00'),
  ('03bcbcb0-24d0-493c-9d94-d6f8fe35b1ad', '6b072305-8faf-4285-a42f-28ba16e9656f', 'Honey jars', FALSE, '2026-05-21 09:33:10+00'),
  ('adbef2d2-d084-4420-a4c0-ba9763cc35dc', '6b072305-8faf-4285-a42f-28ba16e9656f', 'Replacement duvet covers', TRUE, '2026-05-31 13:11:15+00'),
  ('724d60c0-e6fa-4204-b183-e3f7e04e4fcf', '2ba5820b-af54-4341-bfc3-a920a353bc37', 'Motion sensor kit', TRUE, '2026-07-08 20:37:24+00'),
  ('e591023c-31e9-4589-8348-2a3d161c5ea9', '2ba5820b-af54-4341-bfc3-a920a353bc37', 'Camera batteries', FALSE, '2026-07-05 12:01:49+00'),
  ('c479c25d-0f0c-44e2-8832-51f642ba60da', '46e55f5e-e680-43bc-8a3d-e74b8668569c', 'Camera batteries', TRUE, '2026-06-19 21:23:09+00'),
  ('e56a2f69-b8e3-4b63-8d33-5683fb7ec306', '46e55f5e-e680-43bc-8a3d-e74b8668569c', 'Motion sensor kit', TRUE, '2026-07-08 07:16:08+00'),
  ('c07c110c-e623-4a2e-a8f3-efff2cb10230', 'a8d424d8-ee04-4193-b7bd-051c06dbc9eb', 'Flashlight batteries', FALSE, '2026-07-06 14:30:54+00'),
  ('df1eecdd-ffa2-45f7-adf2-db432109a4eb', 'a8d424d8-ee04-4193-b7bd-051c06dbc9eb', 'Citation pads', TRUE, '2026-06-24 18:44:31+00');

INSERT INTO task_shopping_items (id, task_id, name, checked, created_at)
VALUES
  ('bf583a3c-a726-4b63-95d9-0fb23dba4269', '2d5e0e20-28c3-48c4-a54b-87f6f6ed59ec', 'Flashlight batteries', TRUE, '2026-03-14 07:49:54+00'),
  ('f55a4442-1427-4167-9fb8-b865dde45912', '2d5e0e20-28c3-48c4-a54b-87f6f6ed59ec', 'First-aid supplies', FALSE, '2026-06-08 10:39:28+00'),
  ('4012b282-56f7-4365-a5fd-cdb2fb237a0d', '2d5e0e20-28c3-48c4-a54b-87f6f6ed59ec', 'Reflective vest', TRUE, '2026-05-24 07:07:50+00'),
  ('9cf4de86-ed5e-488e-a0b8-1d2993252cc2', '2d5e0e20-28c3-48c4-a54b-87f6f6ed59ec', 'Citation pads', FALSE, '2026-03-22 20:52:53+00'),
  ('9be87fc6-33e7-40ac-9eac-a32167182063', '152ad141-87e4-4a37-9327-003414a12f29', 'Citation pads', TRUE, '2026-06-13 16:05:18+00'),
  ('e37130fe-6eaf-4e1d-99bf-1ebae970af58', '152ad141-87e4-4a37-9327-003414a12f29', 'Flashlight batteries', TRUE, '2026-06-08 07:31:05+00'),
  ('342223b1-99e5-4cec-bd01-d82667811c09', 'd9c4e4ac-7b0b-495a-8762-14bef511e775', 'Poultry netting', TRUE, '2026-06-20 15:07:50+00'),
  ('e14903c4-b369-41fd-a963-8a3b37621b43', 'd9c4e4ac-7b0b-495a-8762-14bef511e775', 'Wormer', FALSE, '2026-07-01 12:44:08+00'),
  ('34adf3c9-05d2-4762-bc78-c2f6307074fb', 'd9c4e4ac-7b0b-495a-8762-14bef511e775', 'Chicken feed', TRUE, '2026-07-04 15:49:48+00'),
  ('080d4ba9-6dfd-48c9-840b-558a1f6cccbb', 'd9c4e4ac-7b0b-495a-8762-14bef511e775', 'Goat feed', FALSE, '2026-06-26 17:29:25+00'),
  ('36c9137f-6202-4158-8956-dd8b1452163d', 'd533b324-1c42-4dee-8a31-2995f17dc36c', 'Wormer', FALSE, '2026-07-05 17:36:37+00'),
  ('c72ca742-7668-4efa-93a5-6abe78b250d2', 'd533b324-1c42-4dee-8a31-2995f17dc36c', 'Chicken feed', FALSE, '2026-05-08 18:53:35+00'),
  ('468975b0-9129-44d8-b38b-689043fdbe80', 'd533b324-1c42-4dee-8a31-2995f17dc36c', 'Poultry netting', TRUE, '2026-06-05 11:48:39+00'),
  ('79aa2efb-dc5a-4b82-900c-86c4b5d700c4', 'd533b324-1c42-4dee-8a31-2995f17dc36c', 'Goat feed', TRUE, '2026-05-21 21:59:10+00'),
  ('fb48d850-a298-4eb8-89ad-e6a63e889660', 'e3a5f2dd-839e-437f-979e-fef462b15b19', 'Wormer', TRUE, '2026-07-10 22:00:40+00'),
  ('378fa5ad-d282-4654-b4f0-e57d5b97d780', 'e3a5f2dd-839e-437f-979e-fef462b15b19', 'Poultry netting', FALSE, '2026-06-23 17:09:44+00'),
  ('b6eae2ed-d73e-4d7d-9e37-e044b3ed3df5', 'e3a5f2dd-839e-437f-979e-fef462b15b19', 'Goat feed', FALSE, '2026-07-06 08:11:23+00'),
  ('d5b132ed-5f4b-49a6-913e-df3c72876e72', '788b8fa6-5cfe-4342-a5af-2c6f4ccf41d4', 'Fence posts', FALSE, '2026-07-14 12:22:43+00'),
  ('364a54f3-3f87-4653-9b3d-1d0be648ccee', '788b8fa6-5cfe-4342-a5af-2c6f4ccf41d4', 'Lime pellets', FALSE, '2026-04-04 11:11:59+00'),
  ('e7d1b7db-07f6-49de-9445-ff67b203a190', '788b8fa6-5cfe-4342-a5af-2c6f4ccf41d4', 'Irrigation tubing', TRUE, '2026-04-14 18:27:11+00'),
  ('31c15556-b571-4a5b-a6b5-df6a2a721a11', '788b8fa6-5cfe-4342-a5af-2c6f4ccf41d4', 'Grass seed', FALSE, '2026-05-16 17:15:06+00'),
  ('ad16092d-c425-426d-bf4f-bb42ce0c9dd0', 'a3b0e74b-4630-4655-9a45-33d115c7e453', 'Lime pellets', FALSE, '2026-05-12 06:59:56+00'),
  ('74530bc6-39bf-457d-8252-ac28690a6f30', 'a3b0e74b-4630-4655-9a45-33d115c7e453', 'Irrigation tubing', FALSE, '2026-05-05 16:40:43+00'),
  ('722bfb63-45b3-41af-a58d-bf6fcf3766b2', 'cd302ce1-bd1d-4ac1-b67c-71778aa96219', 'Sand bucket', TRUE, '2026-06-10 17:18:43+00'),
  ('1f0b6be0-f39b-48b3-98c8-95255a0740cd', 'cd302ce1-bd1d-4ac1-b67c-71778aa96219', 'Smoke detector batteries', TRUE, '2026-06-07 16:26:29+00');

INSERT INTO task_shopping_items (id, task_id, name, checked, created_at)
VALUES
  ('ea71633e-761d-4585-af76-51ddfd4e4abb', '38e16680-3d47-443b-a979-3d3c066df962', 'Fire blanket', TRUE, '2026-07-07 17:19:27+00'),
  ('5a5931bc-e6fe-4345-8bb9-59cc59b9b8a4', '38e16680-3d47-443b-a979-3d3c066df962', 'Smoke detector batteries', TRUE, '2026-05-02 10:22:03+00'),
  ('04e2dc8c-ca5c-4853-8e5b-050258226d1b', '38e16680-3d47-443b-a979-3d3c066df962', 'Sand bucket', TRUE, '2026-07-09 15:26:54+00'),
  ('e8b5b90f-dd92-4a1c-974c-87bf90b9465c', '38e16680-3d47-443b-a979-3d3c066df962', 'Fire extinguisher refill', TRUE, '2026-04-04 13:52:55+00'),
  ('038c50df-c3f2-4b11-be9f-e04073c03836', 'ee6e7fe6-0ece-4070-9194-9df3bb557768', 'Sand bucket', TRUE, '2026-05-19 12:04:13+00'),
  ('963ef5db-b635-4b18-9e8a-ae5d01701641', 'ee6e7fe6-0ece-4070-9194-9df3bb557768', 'Fire extinguisher refill', FALSE, '2026-06-17 17:16:42+00'),
  ('9978b906-8160-4e2e-98f1-5dd5961064ca', 'ee6e7fe6-0ece-4070-9194-9df3bb557768', 'Fire blanket', FALSE, '2026-05-13 22:52:42+00'),
  ('a7816946-110f-435f-a8b3-3f17c089037d', 'd46c67e5-a6d3-4f2b-b9e2-f90b5429fbf1', 'Tractor headlight bulb', FALSE, '2026-03-30 10:01:19+00'),
  ('f44b4b7a-f540-4396-933c-b34bd5dd32ac', 'd46c67e5-a6d3-4f2b-b9e2-f90b5429fbf1', 'Engine oil', TRUE, '2026-05-16 18:44:20+00'),
  ('cb912052-5c7f-417a-8087-abdee252ef2f', 'd46c67e5-a6d3-4f2b-b9e2-f90b5429fbf1', 'Spare fuses', FALSE, '2026-06-18 16:32:51+00'),
  ('11f42321-951d-4162-b6fb-f093597a4788', '4ac69b13-b221-44d6-8b45-0722d877d316', 'Spare fuses', TRUE, '2026-05-30 19:30:18+00'),
  ('f097acf0-c0a6-4d0a-bd69-7a3e13f372ce', '4ac69b13-b221-44d6-8b45-0722d877d316', 'Grease cartridges', TRUE, '2026-07-15 13:55:10+00'),
  ('8277e73a-b6f8-465c-bfe5-b7e7952a6bae', '4ac69b13-b221-44d6-8b45-0722d877d316', 'Engine oil', FALSE, '2026-06-15 07:30:21+00'),
  ('34277cea-b0bf-45ba-b194-a38e3935ff03', '4ac69b13-b221-44d6-8b45-0722d877d316', 'Tractor headlight bulb', FALSE, '2026-05-10 11:11:11+00'),
  ('e97ca968-84d7-47fc-864e-f389c8b77512', '06be9f14-bdd6-495d-853b-1d91a7d408a2', 'Printer ink', TRUE, '2026-07-10 14:33:20+00'),
  ('d4d002d1-50b5-49f5-84e0-53900f4db32d', '06be9f14-bdd6-495d-853b-1d91a7d408a2', 'Filing folders', FALSE, '2026-07-15 09:07:15+00'),
  ('75ec5ab5-3bd1-48dc-b005-130861324e61', '06be9f14-bdd6-495d-853b-1d91a7d408a2', 'Certified mail envelopes', TRUE, '2026-07-09 09:55:15+00'),
  ('4d133fba-854a-4e53-b536-fd9a57b5cbdd', 'e506a02e-9798-47b2-8aff-39fd83c4ac3d', 'Filing folders', TRUE, '2026-06-30 06:43:17+00'),
  ('5f687020-46bd-42c2-bdb3-fcb0b397376d', 'e506a02e-9798-47b2-8aff-39fd83c4ac3d', 'Printer ink', TRUE, '2026-04-03 17:06:36+00'),
  ('85ea4c03-77e6-48c0-942c-5b8de6bf942a', 'e506a02e-9798-47b2-8aff-39fd83c4ac3d', 'Certified mail envelopes', TRUE, '2026-06-12 10:28:50+00'),
  ('286f59b1-de36-4353-b74f-9fddd5748e98', '191ee997-7624-4289-92cf-c91fbc217520', 'Certified mail envelopes', FALSE, '2026-05-30 07:19:37+00'),
  ('dba6e679-311f-4ec5-a76a-76fe1a7af222', '191ee997-7624-4289-92cf-c91fbc217520', 'Filing folders', TRUE, '2026-04-24 07:01:36+00'),
  ('0c52607f-da19-42e0-bf9d-5369cf2ce7c5', '191ee997-7624-4289-92cf-c91fbc217520', 'Printer ink', FALSE, '2026-06-20 07:27:04+00'),
  ('3ffe1131-0237-44aa-94a2-7f95f5b9fbcf', '38963936-bece-4f71-85a7-5876537c91ed', 'Gas mask filters', TRUE, '2026-07-08 10:16:45+00'),
  ('637bdd19-4cc5-400f-b71d-13290cfddd2b', '38963936-bece-4f71-85a7-5876537c91ed', 'Water purification tablets', TRUE, '2026-06-06 11:39:21+00');

INSERT INTO task_shopping_items (id, task_id, name, checked, created_at)
VALUES
  ('c3dbe9ca-e4e2-4031-ab3f-a0248fac8ade', '38963936-bece-4f71-85a7-5876537c91ed', 'AA batteries', TRUE, '2026-06-02 22:14:13+00'),
  ('c4f302eb-26c2-4601-91ab-a8d5b06f4a4e', '38963936-bece-4f71-85a7-5876537c91ed', 'MRE cases', TRUE, '2026-06-09 15:36:35+00'),
  ('e66b11eb-48d7-48e5-8cf7-6be6b04a1f50', '88eac54c-219d-4838-8fd7-624ff27b95e5', 'AA batteries', TRUE, '2026-06-10 14:12:54+00'),
  ('e7b81356-cc1b-4fa8-93cc-d57bf1e498bc', '88eac54c-219d-4838-8fd7-624ff27b95e5', 'Water purification tablets', TRUE, '2026-06-24 10:31:34+00'),
  ('bb8c29c0-16ac-4da0-b9d5-6150f6e3b710', 'bf56b2ec-3f26-4d92-b3ee-dce265d9c166', 'Price tag labels', FALSE, '2026-05-13 12:55:21+00'),
  ('668ac457-5442-4a24-86a6-93ce894a25e3', 'bf56b2ec-3f26-4d92-b3ee-dce265d9c166', 'Sample boxes', TRUE, '2026-05-24 15:52:11+00'),
  ('c09757c8-e293-4f3d-b7ca-ae7020c56dab', 'bf56b2ec-3f26-4d92-b3ee-dce265d9c166', 'Farm stand signage', FALSE, '2026-05-31 11:52:12+00'),
  ('8d192c1f-0cc7-44f9-a999-4cdd4c26539c', 'db25bcc7-e9f3-4940-b202-714722c8fcdb', 'Farm stand signage', FALSE, '2026-07-10 18:48:40+00'),
  ('57ec5c0b-3747-45e4-af73-c6eeb706bc23', 'db25bcc7-e9f3-4940-b202-714722c8fcdb', 'Price tag labels', FALSE, '2026-07-11 16:00:32+00'),
  ('f1652bb0-b73c-4a77-8765-b8f85d75ce8b', '9f68a485-eb2a-49ff-a6ab-ab8fe79be97b', 'Sample boxes', FALSE, '2026-04-06 06:30:33+00'),
  ('f5928b8e-02fc-4cde-8a63-f646ac4b2af8', '9f68a485-eb2a-49ff-a6ab-ab8fe79be97b', 'Farm stand signage', FALSE, '2026-06-22 12:06:11+00'),
  ('33c35f9a-1bbd-4553-9f41-e4ad1cae06e5', 'f071ad0b-439b-4163-a928-19ca67dc4c28', 'String lights', FALSE, '2026-07-04 11:14:10+00'),
  ('fcc3d807-db41-40af-a7cc-e1bca0d7bb57', 'f071ad0b-439b-4163-a928-19ca67dc4c28', 'Hay bales', TRUE, '2026-05-01 14:27:01+00'),
  ('2de63b1f-dd5d-46df-8263-395c11aaf4c2', 'f071ad0b-439b-4163-a928-19ca67dc4c28', 'Fake blood mix', FALSE, '2026-05-01 12:08:44+00'),
  ('baafbfc5-ed31-449e-a253-d0a1f28cf075', 'f071ad0b-439b-4163-a928-19ca67dc4c28', 'Fog fluid', TRUE, '2026-06-19 09:49:41+00'),
  ('e15af926-3b3c-42d1-bf2c-30bd16ac4594', '3c8407ff-e732-4d18-85cd-598e49211280', 'Hay bales', TRUE, '2026-05-15 21:52:00+00'),
  ('de0a1bf0-3cb9-432d-885a-0c254231369f', '3c8407ff-e732-4d18-85cd-598e49211280', 'Fake blood mix', FALSE, '2026-05-12 20:42:57+00'),
  ('8454057c-8a70-41bd-9df3-62190dda9bc0', '3c8407ff-e732-4d18-85cd-598e49211280', 'Fog fluid', FALSE, '2026-06-09 07:08:20+00'),
  ('adfbabea-4e2c-41d0-919a-49f5a1f23d3f', '3c8407ff-e732-4d18-85cd-598e49211280', 'String lights', TRUE, '2026-07-08 18:21:53+00'),
  ('e4b90f46-1307-46b5-acf2-a6e2d1a57691', 'f6880308-2c44-415d-8dba-57a3226861bd', 'Sawdust bedding', FALSE, '2026-06-10 20:54:33+00'),
  ('509dd950-1843-4efa-9c03-a20f2490d778', 'f6880308-2c44-415d-8dba-57a3226861bd', 'Compost thermometer', TRUE, '2026-06-10 17:49:23+00'),
  ('87706142-d58a-405f-b8a0-ed3259021d00', 'f6880308-2c44-415d-8dba-57a3226861bd', 'Pitchfork replacement handle', TRUE, '2026-05-09 14:00:07+00'),
  ('1d803afb-d398-4dc0-a7f8-285e21cdcbdc', 'e75ed246-4c99-4b2e-bc40-0121d8783f38', 'Sawdust bedding', TRUE, '2026-06-26 19:42:10+00'),
  ('f7160921-ba11-41de-9d7f-da1dfe5168e5', 'e75ed246-4c99-4b2e-bc40-0121d8783f38', 'Pitchfork replacement handle', TRUE, '2026-05-25 11:13:41+00'),
  ('d4360630-f047-402f-9dad-0bcbd327bd5c', 'e75ed246-4c99-4b2e-bc40-0121d8783f38', 'Compost thermometer', TRUE, '2026-06-27 10:55:05+00');

INSERT INTO task_shopping_items (id, task_id, name, checked, created_at)
VALUES
  ('9fbcd711-f1cd-4ff9-aa05-810516e880d8', '75daf29d-6296-475d-b8be-8c0f56920692', 'Sawdust bedding', FALSE, '2026-07-10 08:36:00+00'),
  ('4316b2f5-4b7d-4160-a22d-51b6b2ca22bd', '75daf29d-6296-475d-b8be-8c0f56920692', 'Compost thermometer', FALSE, '2026-07-12 18:35:27+00'),
  ('7aa801bf-c14b-46c4-a292-5dcafe690926', '75daf29d-6296-475d-b8be-8c0f56920692', 'Pitchfork replacement handle', TRUE, '2026-07-09 13:52:37+00');

-- ---------------------------------------------------------------------------
-- Task tools
-- ---------------------------------------------------------------------------

INSERT INTO task_tools (id, task_id, name, checked, created_at)
VALUES
  ('fa4662ec-711e-43b4-9c55-4237ab8af4b8', 'f8bf8dcd-2ac9-4e3a-9e3d-0e1de537f3b7', 'Hoe', TRUE, '2026-07-11 13:47:34+00'),
  ('a1c6f78e-a094-494f-a9b5-e9314b144a5b', 'f8bf8dcd-2ac9-4e3a-9e3d-0e1de537f3b7', 'Hand trowel', TRUE, '2026-07-12 13:50:49+00'),
  ('431f3e3e-07ae-44f7-a324-03f939f658ff', '25476c46-ed4e-446c-83ac-d91263954b41', 'Harvest crate', FALSE, '2026-06-30 08:05:28+00'),
  ('92fe95b5-6fb6-4c53-9f76-de347018dfcf', '25476c46-ed4e-446c-83ac-d91263954b41', 'Hoe', FALSE, '2026-07-01 11:11:57+00'),
  ('13269312-b52d-476f-8aaf-4edc237bedec', '25476c46-ed4e-446c-83ac-d91263954b41', 'Hand trowel', TRUE, '2026-07-13 18:03:40+00'),
  ('9690de1b-2527-4241-b13a-a16b2b8a4987', 'fc998e3f-4600-4a8f-a64b-c4f5a684f2ce', 'Hand trowel', TRUE, '2026-06-14 17:27:54+00'),
  ('9d882d07-6f2a-414b-a091-787637658907', 'fc998e3f-4600-4a8f-a64b-c4f5a684f2ce', 'Hoe', FALSE, '2026-07-11 21:55:13+00'),
  ('d0097308-6918-4530-b950-12f172a61707', 'fc998e3f-4600-4a8f-a64b-c4f5a684f2ce', 'Harvest crate', FALSE, '2026-06-29 16:15:11+00'),
  ('a045ab13-cdb3-4a0a-8be2-bd2fa2ebde9a', '02facb2b-e626-452c-b85f-8c98b61443f0', 'Ladder', TRUE, '2026-05-20 19:52:23+00'),
  ('44abe4f4-d6b5-4230-b950-efbc54624588', '02facb2b-e626-452c-b85f-8c98b61443f0', 'Paintbrush set', TRUE, '2026-03-14 08:05:34+00'),
  ('0796a72a-4779-4469-ab42-809b03559d05', 'affdb6da-8dc2-4f76-8a39-4bc6fe2e4521', 'Cordless drill', FALSE, '2026-05-30 18:53:35+00'),
  ('b2f3a9f2-e483-4e2f-bd81-6c30ff372305', 'affdb6da-8dc2-4f76-8a39-4bc6fe2e4521', 'Ladder', TRUE, '2026-06-18 16:35:13+00'),
  ('25776af3-21c9-41b2-be7a-26e5f8e8e738', 'c70eb3f7-d9ce-4b1f-98a4-58e202c41b8b', 'Crowbar', TRUE, '2026-07-13 19:02:38+00'),
  ('04ae5fd1-036f-4b4a-8a4b-966746dd4c86', 'c70eb3f7-d9ce-4b1f-98a4-58e202c41b8b', 'Bolt cutters', TRUE, '2026-06-04 09:55:34+00'),
  ('b08792c5-9da0-48c8-9d65-f9ca54d5eb70', 'c70eb3f7-d9ce-4b1f-98a4-58e202c41b8b', 'Wire strainer', TRUE, '2026-05-05 10:50:43+00'),
  ('81249fa3-9a82-4089-b95b-adfd40d93fee', 'a6744dc2-bfcb-4504-a564-9c1cf9352a4d', 'Crowbar', TRUE, '2026-06-25 17:21:08+00'),
  ('0834154e-aa8d-42f8-be8a-e21f4c0e48c6', 'a6744dc2-bfcb-4504-a564-9c1cf9352a4d', 'Bolt cutters', FALSE, '2026-05-13 13:24:07+00'),
  ('3a3629d3-2112-490e-8007-38cf30836173', 'a6744dc2-bfcb-4504-a564-9c1cf9352a4d', 'Wire strainer', TRUE, '2026-06-13 13:14:37+00'),
  ('92cfba9c-81bc-47c7-85c4-81d188fc648d', '067d3cc5-63b8-4f56-a9fb-cefe27edb91d', 'Crowbar', FALSE, '2026-04-07 22:21:47+00'),
  ('6713ba1b-a64e-446e-a99c-5b8e27deae46', '067d3cc5-63b8-4f56-a9fb-cefe27edb91d', 'Bolt cutters', FALSE, '2026-05-08 08:43:09+00'),
  ('0d4ebb0e-c907-4067-ae9b-cff441f8e3c9', '067d3cc5-63b8-4f56-a9fb-cefe27edb91d', 'Wire strainer', FALSE, '2026-04-17 14:13:32+00'),
  ('4cb8499c-942f-4a0e-b7a2-dadc989be13f', '17f076df-fc10-4f34-9e83-d1236b02a1dc', 'Tire iron', TRUE, '2026-05-13 17:18:28+00'),
  ('71b00b2b-ee33-428e-bb1c-e90c323bea1a', '17f076df-fc10-4f34-9e83-d1236b02a1dc', 'Jump starter', FALSE, '2026-06-11 20:35:51+00'),
  ('c56baf6c-cf38-4cba-bbe1-e785621a2d11', 'c66ba2b1-1420-49a4-8aeb-1e42d0b54aaf', 'Jump starter', FALSE, '2026-06-19 18:38:16+00'),
  ('f6c078e8-b911-4135-94a4-ac1645212c30', 'c66ba2b1-1420-49a4-8aeb-1e42d0b54aaf', 'Tire iron', FALSE, '2026-04-18 12:58:38+00');

INSERT INTO task_tools (id, task_id, name, checked, created_at)
VALUES
  ('e0db4617-267a-432e-991a-23b7260be924', '092b7dc7-4ba5-4e21-95b9-c2455eb3f369', 'Jump starter', FALSE, '2026-05-21 13:41:49+00'),
  ('131c5f96-286a-4644-97f0-a7a478a08f51', '092b7dc7-4ba5-4e21-95b9-c2455eb3f369', 'Tire iron', TRUE, '2026-03-27 08:19:16+00'),
  ('e9e50614-960f-492c-9d4d-986a4cdca5c2', 'a448ade1-7bfb-47cf-9ee6-f7aa9904215a', 'Hoof trimmers', TRUE, '2026-06-14 19:46:49+00'),
  ('e2e0aceb-6bd9-417b-88f2-f8982851d3cf', 'a448ade1-7bfb-47cf-9ee6-f7aa9904215a', 'Drenching gun', FALSE, '2026-04-06 07:14:12+00'),
  ('89d251fc-24c2-4bcf-8a76-30e76458977c', 'ef922ec7-a320-4b66-99f9-cdb5d9720984', 'Livestock crate', TRUE, '2026-04-09 08:22:45+00'),
  ('cba310a4-e3ed-4817-b8a0-721fecd59b93', 'ef922ec7-a320-4b66-99f9-cdb5d9720984', 'Drenching gun', FALSE, '2026-04-20 16:56:56+00'),
  ('10a64f6c-4706-4b25-a374-6b8ccaae9c47', 'bc94a61a-a629-45bb-aec8-c1d08114d184', 'Pickaxe', FALSE, '2026-05-04 10:15:45+00'),
  ('36b5b412-c957-45a4-a489-3f6d63afcad3', 'bc94a61a-a629-45bb-aec8-c1d08114d184', 'Shovel', FALSE, '2026-06-04 06:24:44+00'),
  ('8427283c-90ad-40b4-bbc8-a7d32c56f5c0', '4cdd13da-0f2b-457c-80ab-eaaea441923e', 'Shovel', TRUE, '2026-07-13 09:40:05+00'),
  ('31cd06aa-5f47-45d4-8d42-53e4ae3b413b', '4cdd13da-0f2b-457c-80ab-eaaea441923e', 'Wheelbarrow', TRUE, '2026-07-13 19:42:23+00'),
  ('b1a6ba37-4c06-46c7-af0a-ca04f5eaded0', 'e9399fa9-f4e0-45e8-997f-4097090dc2a1', 'Shovel', TRUE, '2026-06-01 11:47:20+00'),
  ('1911eae3-e0e3-43c6-842d-61693a065140', 'e9399fa9-f4e0-45e8-997f-4097090dc2a1', 'Post driver', FALSE, '2026-06-01 09:08:37+00'),
  ('ad1992df-6bc4-4691-bf10-f01be0395dee', 'e9399fa9-f4e0-45e8-997f-4097090dc2a1', 'Wheelbarrow', FALSE, '2026-07-01 20:35:00+00'),
  ('47c470f6-f7ce-4ef8-820c-4345b99533d8', '13f81fae-0699-41b3-a0c1-ace102d95d90', 'Ladder', TRUE, '2026-06-27 06:18:14+00'),
  ('35ebf3a3-b2cc-4274-b299-afa8219ffcf8', '13f81fae-0699-41b3-a0c1-ace102d95d90', 'Hose reel key', TRUE, '2026-06-27 08:40:30+00'),
  ('e28406be-6f57-44f0-a230-48601b55e543', '13f81fae-0699-41b3-a0c1-ace102d95d90', 'Fire extinguisher', TRUE, '2026-07-01 14:07:24+00'),
  ('8020a0a0-8ac3-4a5f-8aa2-4bd15cab61ac', '6cb4a6fc-0b1a-4ed6-a352-bca774b9c3a4', 'Ladder', FALSE, '2026-06-23 18:42:41+00'),
  ('4e855eec-294e-4aac-9ff3-3fd24e53d4c1', '6cb4a6fc-0b1a-4ed6-a352-bca774b9c3a4', 'Fire extinguisher', FALSE, '2026-07-15 19:16:54+00'),
  ('cc1e1e64-4373-415a-b44b-4fdcfee5ff9f', '944f5592-4c56-44f0-ae8a-5bf556c86e1c', 'Socket set', FALSE, '2026-03-20 12:33:37+00'),
  ('cde14c32-1f05-44e1-96b2-c7134f29e94a', '944f5592-4c56-44f0-ae8a-5bf556c86e1c', 'Grease gun', FALSE, '2026-04-14 21:14:32+00'),
  ('f9b4f53b-b3b1-4ff0-be3e-bf48af595b6c', '56d28867-b98a-4d8e-a71e-6eb781085a0f', 'Socket set', FALSE, '2026-07-12 15:33:42+00'),
  ('0f052284-60f4-4cc6-8477-11c6d9a498f5', '56d28867-b98a-4d8e-a71e-6eb781085a0f', 'Torque wrench', FALSE, '2026-07-15 06:43:00+00'),
  ('797fce78-2da1-484c-afae-4c431a82e084', '56d28867-b98a-4d8e-a71e-6eb781085a0f', 'Grease gun', FALSE, '2026-07-08 20:29:38+00'),
  ('81a749e6-70e1-4a6e-82db-fca89b2011ca', '56d28867-b98a-4d8e-a71e-6eb781085a0f', 'Impact driver', FALSE, '2026-07-05 08:33:18+00'),
  ('e2efe2c5-a328-4d24-98c0-85721cccb327', 'da19283f-57e2-4be7-8626-e1572c056299', 'Grease gun', FALSE, '2026-04-17 11:19:54+00');

INSERT INTO task_tools (id, task_id, name, checked, created_at)
VALUES
  ('f423943e-a550-4986-85c1-b07c5d878922', 'da19283f-57e2-4be7-8626-e1572c056299', 'Torque wrench', FALSE, '2026-07-11 21:43:15+00'),
  ('ffb979c5-2364-4603-a19e-85d1a7a99801', '6e2e3288-a87c-4185-8823-de1db31f0f6a', 'Extension cord', FALSE, '2026-07-07 17:21:11+00'),
  ('7b468fa1-b76b-4d87-aad3-6f2de9d65d0f', '6e2e3288-a87c-4185-8823-de1db31f0f6a', 'Utility knife', TRUE, '2026-06-17 12:55:31+00'),
  ('a62834b4-d81c-4381-9789-e8b1e3f6c190', '69eb44e2-44e3-4148-92fa-4ee902efa6fd', 'Utility knife', TRUE, '2026-05-22 08:15:47+00'),
  ('3f36024f-cc7b-4f56-989c-30dec0d3dba3', '69eb44e2-44e3-4148-92fa-4ee902efa6fd', 'Extension cord', FALSE, '2026-06-15 07:25:44+00'),
  ('b900e1ed-dbca-4ba7-b86d-f5f4f07d10c4', '69eb44e2-44e3-4148-92fa-4ee902efa6fd', 'Staple gun', FALSE, '2026-07-09 08:59:45+00'),
  ('383c5753-9723-4d36-825a-2dd4e69d707a', '96bb0531-0dcf-43c2-b971-10f5276cb9ee', 'Staple gun', TRUE, '2026-06-28 09:49:37+00'),
  ('95868b98-70f0-47cd-9231-ac6fe50e9a79', '96bb0531-0dcf-43c2-b971-10f5276cb9ee', 'Extension cord', FALSE, '2026-06-20 14:25:35+00'),
  ('960c9a3c-b568-48b4-89a0-622cb945576d', '96bb0531-0dcf-43c2-b971-10f5276cb9ee', 'Utility knife', FALSE, '2026-06-22 08:54:23+00'),
  ('b68685c5-58cd-4093-86d8-e2c215eb56f8', 'ad849efa-f395-4f21-8170-dca3b14e3f6b', 'Pitchfork', TRUE, '2026-05-22 22:16:02+00'),
  ('54e5e315-b504-4087-8749-87420b501abe', 'ad849efa-f395-4f21-8170-dca3b14e3f6b', 'Manure fork', FALSE, '2026-05-03 11:47:25+00'),
  ('932d92f1-108d-4fea-bc21-08efbff1534d', 'ad849efa-f395-4f21-8170-dca3b14e3f6b', 'Wheelbarrow', FALSE, '2026-05-30 15:22:57+00'),
  ('e8deab85-36cf-4132-9fa8-f4847f6ce2e9', '417eda0c-0e6a-46f1-aa99-ccde9f96466f', 'Wheelbarrow', FALSE, '2026-04-25 22:18:17+00'),
  ('bb24867f-fd92-4610-8118-7068ba948174', '417eda0c-0e6a-46f1-aa99-ccde9f96466f', 'Manure fork', TRUE, '2026-04-03 07:52:04+00'),
  ('0dcfca83-955c-4c77-b407-2a368485a991', '417eda0c-0e6a-46f1-aa99-ccde9f96466f', 'Pitchfork', TRUE, '2026-06-05 09:48:30+00');

-- ---------------------------------------------------------------------------
-- Task time entries
-- ---------------------------------------------------------------------------

INSERT INTO task_time_entries (id, task_id, user_id, started_at, ended_at, created_at)
VALUES
  ('5a3f5730-f307-4490-bf76-0dbdef96ab09', 'f8bf8dcd-2ac9-4e3a-9e3d-0e1de537f3b7', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-09 14:10:10.660+00', '2026-07-09 14:40:10.660+00', '2026-07-09 14:10:25.660+00'),
  ('db35961f-2005-4228-a2b8-3af01e5c8bfc', 'f8bf8dcd-2ac9-4e3a-9e3d-0e1de537f3b7', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 13:27:27.491+00', '2026-07-12 13:42:27.491+00', '2026-07-12 13:27:29.491+00'),
  ('e6a66eaa-4218-4b9f-ae8b-2bec64830039', '25476c46-ed4e-446c-83ac-d91263954b41', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-07 18:29:11.388+00', '2026-06-07 18:59:11.388+00', '2026-06-07 18:29:12.388+00'),
  ('a6068a71-8bfd-4c2f-9d63-b9a112018f1b', 'd0648a52-4f8f-4b51-8927-a728df4648c6', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-30 04:07:53.688+00', '2026-05-30 05:07:53.688+00', '2026-05-30 04:08:03.688+00'),
  ('276e319f-adf7-4fcc-a081-ba7f5fa029e1', 'affdb6da-8dc2-4f76-8a39-4bc6fe2e4521', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-06 01:06:36.104+00', '2026-06-06 01:36:36.104+00', '2026-06-06 01:06:39.104+00'),
  ('6e616401-e6b0-426b-9d58-f62d6f0d9bf3', '6b072305-8faf-4285-a42f-28ba16e9656f', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-14 02:20:18.939+00', '2026-05-14 03:05:18.939+00', '2026-05-14 02:20:27.939+00'),
  ('0d0c788d-142a-4980-a1ca-b8e0c899e000', '2ba5820b-af54-4341-bfc3-a920a353bc37', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-03 07:34:10.725+00', '2026-07-03 08:04:10.725+00', '2026-07-03 07:34:14.725+00'),
  ('b57d69cb-8546-484f-814f-849806217bb1', '706aac4f-7f92-4f40-99cd-0428bc8d6d62', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-30 14:01:13.171+00', '2026-05-30 14:16:13.171+00', '2026-05-30 14:01:15.171+00'),
  ('05f8fb85-6681-46a2-89c5-16f6ffd39257', '46e55f5e-e680-43bc-8a3d-e74b8668569c', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-23 15:41:56.663+00', '2026-06-23 15:56:56.663+00', '2026-06-23 15:42:09.663+00'),
  ('e3a6a219-8e21-40ba-a170-585f41d8663a', '63e51f7f-6a9c-469a-ad25-537cb365d768', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-13 21:17:33.435+00', '2026-06-13 22:17:33.435+00', '2026-06-13 21:17:42.435+00'),
  ('49cfb287-b25c-4d1f-bb15-ac00614684e8', '4d883b97-2ec7-4e4d-8777-d8d8b058869c', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-03 12:33:53.475+00', '2026-04-03 14:03:53.475+00', '2026-04-03 12:33:59.475+00'),
  ('445cf6f7-f471-4fe8-8321-c9ff90166e18', '092b7dc7-4ba5-4e21-95b9-c2455eb3f369', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-21 14:22:28.753+00', '2026-04-21 14:52:28.753+00', '2026-04-21 14:22:34.753+00'),
  ('d6c0acba-02cc-43c8-b15d-d98dbb438584', 'd9c4e4ac-7b0b-495a-8762-14bef511e775', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-12 07:46:44.269+00', '2026-06-12 08:06:44.269+00', '2026-06-12 07:46:54.269+00'),
  ('74fe0906-7c9c-4723-ba6f-ca491960fd32', 'd9c4e4ac-7b0b-495a-8762-14bef511e775', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-14 17:37:19.735+00', '2026-06-14 19:37:19.735+00', '2026-06-14 17:37:32.735+00'),
  ('59b4780e-4ce1-4264-a81d-6b2bfba87c98', 'a448ade1-7bfb-47cf-9ee6-f7aa9904215a', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-04 23:17:56.923+00', '2026-06-05 00:47:56.923+00', '2026-06-04 23:17:57.923+00'),
  ('e2295322-f5f1-4104-bc05-db18f4c9f906', 'a448ade1-7bfb-47cf-9ee6-f7aa9904215a', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 10:50:17.428+00', '2026-05-05 11:20:17.428+00', '2026-05-05 10:50:19.428+00'),
  ('365143e3-7341-41b7-8c92-0bd1b9cb5d56', 'e3a5f2dd-839e-437f-979e-fef462b15b19', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 03:26:50.752+00', '2026-07-12 04:11:50.752+00', '2026-07-12 03:26:59.752+00'),
  ('d89f4e5d-7772-4c2c-99ad-2d71797135cc', 'bc94a61a-a629-45bb-aec8-c1d08114d184', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-29 21:25:26.960+00', '2026-04-29 21:45:26.960+00', '2026-04-29 21:25:32.960+00'),
  ('dba0c925-fd84-447b-a994-f7d4acb8a91b', '4ac69b13-b221-44d6-8b45-0722d877d316', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-26 00:52:54.951+00', '2026-05-26 01:07:54.951+00', '2026-05-26 00:53:04.951+00'),
  ('0bd6bfaa-89ab-4885-b1ad-b6e1661fbacb', '4ac69b13-b221-44d6-8b45-0722d877d316', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-25 01:26:37.765+00', '2026-05-25 01:41:37.765+00', '2026-05-25 01:26:46.765+00'),
  ('4d2fac50-1746-4244-922c-44218b2810ba', '06be9f14-bdd6-495d-853b-1d91a7d408a2', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 16:07:21.339+00', '2026-07-11 16:27:21.339+00', '2026-07-11 16:07:34.339+00'),
  ('913e459e-5720-486f-920e-4cde22128f46', '06be9f14-bdd6-495d-853b-1d91a7d408a2', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 00:22:48.332+00', '2026-07-12 02:22:48.332+00', '2026-07-12 00:22:49.332+00'),
  ('10d35f73-f2ed-45d1-91f3-0f63c5f61448', 'd06c3597-de4b-45b4-ba7a-eda287c056d2', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-27 12:14:22.779+00', '2026-06-27 13:14:22.779+00', '2026-06-27 12:14:26.779+00'),
  ('8d27cf8a-f01a-4bdb-b67f-74b03dc2da16', 'd06c3597-de4b-45b4-ba7a-eda287c056d2', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 04:29:12.713+00', '2026-06-05 04:49:12.713+00', '2026-06-05 04:29:23.713+00'),
  ('832d480f-70e0-4657-bf2f-b2d76845ffe2', 'd4c164cf-3452-44fe-8cfd-05bdf1cb90e2', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-18 05:11:46.048+00', '2026-06-18 05:41:46.048+00', '2026-06-18 05:11:51.048+00');

INSERT INTO task_time_entries (id, task_id, user_id, started_at, ended_at, created_at)
VALUES
  ('cf5abe98-5f1d-49a2-8457-cfc492967dcb', 'dd7a2a6b-ce7e-4e88-a819-b0b7949bd5b5', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-03 07:42:44.858+00', '2026-07-03 07:57:44.858+00', '2026-07-03 07:42:50.858+00'),
  ('43c1f081-9f35-43b2-955c-17e8a343ad0b', '9775fcfa-459c-42f0-9dbe-417bd48a28e5', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-03 19:04:57.352+00', '2026-07-03 19:34:57.352+00', '2026-07-03 19:05:00.352+00'),
  ('d94ad0f9-2e11-44ac-8435-8573aa6b9e41', '69eb44e2-44e3-4148-92fa-4ee902efa6fd', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-16 11:24:32.616+00', '2026-05-16 11:54:32.616+00', '2026-05-16 11:24:47.616+00'),
  ('ac37876c-efbb-4988-b4b8-758c3cd97b56', '93926fe1-f12f-4571-9731-c3e47fe39efc', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-18 17:45:57.321+00', '2026-05-18 18:15:57.321+00', '2026-05-18 17:46:03.321+00'),
  ('35a7407d-92fd-48e1-b9a2-2b81e891945e', '3c8407ff-e732-4d18-85cd-598e49211280', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-12 18:04:27.915+00', '2026-05-12 20:04:27.915+00', '2026-05-12 18:04:33.915+00'),
  ('d2677fe2-e742-4440-a907-ef6e013a76e3', '3d324c99-65bd-4ea8-9102-1077d8b56b0b', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-09 04:46:03.234+00', '2026-07-09 05:01:03.234+00', '2026-07-09 04:46:08.234+00'),
  ('b5916b78-8d05-42ce-af7d-22d93e033d62', 'ad849efa-f395-4f21-8170-dca3b14e3f6b', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-14 15:33:13.159+00', '2026-07-14 15:53:13.159+00', '2026-07-14 15:33:19.159+00'),
  ('51aedfa2-46fe-4aac-b459-07bc7eaf0152', 'ad849efa-f395-4f21-8170-dca3b14e3f6b', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 11:32:21.697+00', '2026-07-13 11:47:21.697+00', '2026-07-13 11:32:25.697+00'),
  ('cce1a6da-a3fb-4f8b-9784-87fdf3a68b55', '79e3aa70-1c9e-45fd-a103-44e49a989edc', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-03 19:00:01.397+00', '2026-04-03 19:45:01.397+00', '2026-04-03 19:00:04.397+00'),
  ('5efa4a74-829c-4426-beb7-6cec8d89d812', '75daf29d-6296-475d-b8be-8c0f56920692', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 02:12:35.408+00', '2026-07-13 02:42:35.408+00', '2026-07-13 02:12:36.408+00');

-- ---------------------------------------------------------------------------
-- Activity log
-- ---------------------------------------------------------------------------

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('8bd32917-cfb3-4a95-9393-db8507f79fc2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'category_created', '{"category_id": "f9694f19-bc9e-4d5c-9f92-9f34c2bdb77e", "category_name": "Beets"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-21 22:19:02+00'),
  ('6acab478-55aa-4342-b1b8-21a3eabe7490', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'category_created', '{"category_id": "fe2a70e2-7dc5-4ca5-8edb-a64cefb44d1e", "category_name": "Bed & Breakfast"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-22 15:58:58+00'),
  ('2a9789d5-9532-4fb2-a182-d0822118d874', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'category_created', '{"category_id": "9206a95f-ab5b-4391-bbb7-73fc1444502d", "category_name": "Security & Bunker"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-23 11:12:59+00'),
  ('9144a83d-406f-4878-a435-4af4bbad72ce', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'category_created', '{"category_id": "b53023a9-5b67-4d8a-a64e-0a6c3aa15af2", "category_name": "Volunteer Sheriff''s Dept"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-24 14:13:02+00'),
  ('68a88c83-6e3b-4730-bcf3-c154dc1f0889', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'category_created', '{"category_id": "fd9a036d-a649-4ebe-a4c2-b5c4647e0eb6", "category_name": "Livestock"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-25 11:52:48+00'),
  ('ef36e4f5-07c4-4d96-8c04-50664a63a6e1', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'category_created', '{"category_id": "c7ac2347-5acf-4c1a-bc0e-27ed2f1144e9", "category_name": "Fire Safety & Drills"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-26 10:18:25+00'),
  ('59ad24c0-7d31-4e3b-9dba-f0fde2142c94', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'category_created', '{"category_id": "60022206-074c-4b73-bb83-63ed72372617", "category_name": "Land & Fields"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-26 12:30:46+00'),
  ('099c0fff-1f66-4594-8989-679685a9e27f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'category_created', '{"category_id": "fc4aa87e-9e1a-4e29-9a6b-d610b55de993", "category_name": "Paperwork & Compliance"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-27 10:47:13+00'),
  ('5dface53-4d22-4715-9755-2e595efc9d52', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'category_created', '{"category_id": "f7dec3eb-441f-44ef-a8e4-860e5b280371", "category_name": "Machinery & Repairs"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-27 15:55:03+00'),
  ('f512e000-1151-44c2-bc24-d7940d936fb6', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '36826cd5-cbe9-4606-88e8-0d65061c8fec', 'task_created', '{"task_title": "Test the compost pile''s nitrogen levels"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-01 06:59:14+00'),
  ('176d4d22-682f-42e3-9cc5-5c1ae550c531', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '944f5592-4c56-44f0-ae8a-5bf556c86e1c', 'task_created', '{"task_title": "Change the oil in the tractor before the next big plow"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-02 09:54:08+00'),
  ('41811d5b-273a-4310-b80a-9e85cf8f2506', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'category_created', '{"category_id": "63c3a991-2381-4f5c-b0ea-63b1010e7c2b", "category_name": "Bunker Provisions"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-02 14:24:31+00'),
  ('7739a18c-1b21-4bbf-af75-0b3e13eb478d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '944f5592-4c56-44f0-ae8a-5bf556c86e1c', 'task_priority_changed', '{"new_priority": "urgent", "old_priority": "soon", "task_title": "Change the oil in the tractor before the next big plow"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-02 15:47:55+00'),
  ('52c304f5-ea04-434f-b487-8a6542a9f2d4', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'category_created', '{"category_id": "b956ffcd-e546-475c-a043-95ea847b7cc0", "category_name": "Sales & Customers"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-02 20:07:25+00'),
  ('55eca9af-714c-493b-8486-6f6497903429', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '02facb2b-e626-452c-b85f-8c98b61443f0', 'task_created', '{"task_title": "Restock the outhouse before the weekend guests arrive"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-03 08:34:21+00'),
  ('4635caa7-b685-4930-a5d7-ef774508f4d4', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'a448ade1-7bfb-47cf-9ee6-f7aa9904215a', 'task_created', '{"task_title": "Clip the geese''s wings before they attack the mailman again"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-05 19:50:26+00'),
  ('70c399c9-3053-43e0-9222-6d2b0815f89e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'category_created', '{"category_id": "c30dc3a9-4136-4b72-94ca-6e66d464af3d", "category_name": "Haunted House & Maze"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-06 18:24:57+00'),
  ('a5c01d2e-1fcd-456e-8477-55378e834d3c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '788b8fa6-5cfe-4342-a5af-2c6f4ccf41d4', 'task_created', '{"task_title": "Repair the irrigation line by the wheat field"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-07 13:08:53+00'),
  ('d65061ff-44e9-40be-912e-aff2dbdb3f52', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'category_created', '{"category_id": "6287e686-8a3c-404d-a79e-2d1f5cf3e65b", "category_name": "Manure & Composting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-08 13:51:44+00'),
  ('36cef8f9-7951-4826-a00c-c0be35cc6203', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'd1e09fac-9dda-4db0-8bfa-645284302ebd', 'task_created', '{"task_title": "Sow the second beet crop before the last frost"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-10 06:22:47+00'),
  ('4e076387-dc63-40b3-b3b8-292b0a89d918', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '2d5e0e20-28c3-48c4-a54b-87f6f6ed59ec', 'task_created', '{"task_title": "Restock the trunk first-aid kit"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-11 13:26:14+00'),
  ('e038d788-c838-4af2-9747-f63a825e4196', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '1dfbdb28-6ddc-4f55-881f-d92c7c0fcf0d', 'task_created', '{"task_title": "Till the fallow field ahead of next season''s planting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-13 16:55:54+00'),
  ('9d442d33-80a6-415f-8299-b091bbf9b735', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'e506a02e-9798-47b2-8aff-39fd83c4ac3d', 'task_created', '{"task_title": "Submit the beet crop insurance claim after the hailstorm"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-13 21:24:12+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('a83e8488-308d-4f14-8787-2f6b1b8d9f84', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '128257bf-4de2-4e8c-aad2-82f54ac8187c', 'task_created', '{"task_title": "Fix the guest room thermostat that only does two temperatures"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-14 21:35:14+00'),
  ('0a6504b4-9942-4006-be3d-d9b9548452f6', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '191ee997-7624-4289-92cf-c91fbc217520', 'task_created', '{"task_title": "Organize the farm office filing cabinet"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-18 15:07:46+00'),
  ('b6262e21-5bd5-47ba-bbac-127f89b1ac12', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '06f2b0ba-f3b7-46d9-9357-5b6eba782432', 'task_created', '{"task_title": "Test the motion-sensor alarms along the tree line"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-19 06:40:37+00'),
  ('337c01c5-cec0-4747-8705-0f2b211fe107', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '71aa9c44-9aaf-4e70-9fea-3d706ed6b4ee', 'task_created', '{"task_title": "Rotate the canned goods in the bunker by expiration date"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-24 09:10:20+00'),
  ('3247be1d-80b7-46e7-9163-22670de4232e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'd46c67e5-a6d3-4f2b-b9e2-f90b5429fbf1', 'task_created', '{"task_title": "Fix the flat tire on the flatbed trailer"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-25 06:36:33+00'),
  ('0a65f091-6237-403f-ad7c-8ca6dd63d1ed', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '092b7dc7-4ba5-4e21-95b9-c2455eb3f369', 'task_created', '{"task_title": "Clean and test the department-issued flashlight"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-25 12:43:37+00'),
  ('a53ec763-654f-4199-a561-1f7cd54c90cf', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'a3b0e74b-4630-4655-9a45-33d115c7e453', 'task_created', '{"task_title": "Clear fallen branches from the tree line after the storm"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-26 14:27:28+00'),
  ('186523e6-1b58-49a2-a90f-b3f73f535ee2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'a98b69a9-fb3f-4d06-a571-6d13954472fd', 'task_created', '{"task_title": "Test the hand-crank emergency radio"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-28 14:23:35+00'),
  ('931d8cb7-a75e-41c6-955c-38e20035ea03', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '96ef0e6e-5aa9-4870-9852-3cafb683a2c2', 'task_created', '{"task_title": "Wax the department-issued patrol vehicle"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-29 10:13:37+00'),
  ('b706f4f9-a9c6-4154-a440-73d370f20775', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '04cdef75-0b62-406c-9655-e02481913fb3', 'task_created', '{"task_title": "Replace the ''no running water after 9pm'' sign"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-29 17:39:07+00'),
  ('0689d1b4-360b-41d6-a7c8-6e22d611d13f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '4d883b97-2ec7-4e4d-8777-d8d8b058869c', 'task_created', '{"task_title": "Replace the cracked badge holder"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-30 16:52:18+00'),
  ('ffa98b4c-2688-423f-922c-cabedb236813', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '417eda0c-0e6a-46f1-aa99-ccde9f96466f', 'task_created', '{"task_title": "Haul away the aged compost for sale to neighbors"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-31 17:35:07+00'),
  ('56af4bb0-ceef-4c47-831e-28e9f43e9e27', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'ee6e7fe6-0ece-4070-9194-9df3bb557768', 'task_created', '{"task_title": "Review the fire escape route with Mose"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-01 19:33:27+00'),
  ('50ecc822-810f-4ec7-8a00-c19e4f7c3d4a', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'ef922ec7-a320-4b66-99f9-cdb5d9720984', 'task_created', '{"task_title": "Move the goat herd to the north pasture for fresh grazing"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-01 21:36:43+00'),
  ('90af1a24-0f31-47f8-9aad-1cb7f17b1f1f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '71aa9c44-9aaf-4e70-9fea-3d706ed6b4ee', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Rotate the canned goods in the bunker by expiration date"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-02 04:01:42+00'),
  ('facc6457-1437-4b86-95e8-4fcb3f5990c5', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '067d3cc5-63b8-4f56-a9fb-cefe27edb91d', 'task_created', '{"task_title": "Restock the bunker''s canned beet rations"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-02 07:21:29+00'),
  ('0f4717a7-c3cd-4e13-b8db-5f2423ac8592', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'da19283f-57e2-4be7-8626-e1572c056299', 'task_created', '{"task_title": "Repair the fence-post driver''s cracked handle"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-02 12:27:49+00'),
  ('76c4a384-a240-448e-b910-ff437f094d44', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '9f68a485-eb2a-49ff-a6ab-ab8fe79be97b', 'task_created', '{"task_title": "Update the farm''s online store listing"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-02 15:12:35+00'),
  ('87a29d3a-23ee-4d19-bb2c-212c36120a41', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '70852bed-47e5-4025-9cd7-7b42ab5ec410', 'task_created', '{"task_title": "Change the linens in the guest rooms before the weekend booking"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-02 15:33:32+00'),
  ('6f253b89-2cf3-44e8-bb7e-9887ed5e4011', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '79e3aa70-1c9e-45fd-a103-44e49a989edc', 'task_created', '{"task_title": "Repair the manure spreader''s clogged chute"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-03 16:06:04+00'),
  ('5f966660-db4f-4a57-a9d1-80b168e30c1f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'f3572656-474e-4e49-a2fe-de517c2f8034', 'task_created', '{"task_title": "Deep clean the root cellar guest suite"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-03 19:54:44+00'),
  ('6cad4ff0-c1d3-482e-8b7c-5777ea19f143', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '38e16680-3d47-443b-a979-3d3c066df962', 'task_created', '{"task_title": "Test the bunker''s fire suppression system"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-04 11:24:36+00'),
  ('b5aff37e-0f33-491a-b1cc-fd85b2ed8c07', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'c66ba2b1-1420-49a4-8aeb-1e42d0b54aaf', 'task_created', '{"task_title": "Attend the volunteer deputy refresher training"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-04 16:36:24+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('2778c652-947a-4985-9709-776159ace9f2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '8922c6e9-784a-4867-a173-ad4c8a294817', 'task_created', '{"task_title": "Tune up the chainsaw before hedge-laying season"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-05 11:41:09+00'),
  ('6a5990f3-89ef-474a-9dd5-f85425d8bab3', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '3d324c99-65bd-4ea8-9102-1077d8b56b0b', 'task_created', '{"task_title": "Print tickets for the Halloween haunted house event"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-07 16:52:19+00'),
  ('def4081c-6197-47ef-953e-8356a4bfd709', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '706aac4f-7f92-4f40-99cd-0428bc8d6d62', 'task_created', '{"task_title": "Replace batteries in the perimeter security cameras"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-08 17:14:50+00'),
  ('78bc5a60-aff5-47aa-933c-3d7cd23309e6', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'ad849efa-f395-4f21-8170-dca3b14e3f6b', 'task_created', '{"task_title": "Spread manure on the fallow field before planting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-10 16:17:08+00'),
  ('793612a8-38ec-418d-a55c-5bd6525b08f2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'd533b324-1c42-4dee-8a31-2995f17dc36c', 'task_created', '{"task_title": "Repair the chicken coop door latch"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-11 06:33:37+00'),
  ('4ccc0b28-9a6d-43c1-9a12-50f215d6bc7e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'f3572656-474e-4e49-a2fe-de517c2f8034', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Deep clean the root cellar guest suite"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-14 02:37:40+00'),
  ('044c7516-5abc-4a24-87ba-4def6c087b52', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'e506a02e-9798-47b2-8aff-39fd83c4ac3d', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Submit the beet crop insurance claim after the hailstorm"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-15 07:46:50+00'),
  ('fb795a80-e8f3-40c6-ba61-fa90d23a454c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '4d883b97-2ec7-4e4d-8777-d8d8b058869c', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Replace the cracked badge holder"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-15 21:57:42+00'),
  ('6c107d9a-cdae-4393-a833-5b8cff6c0cd9', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '152ad141-87e4-4a37-9327-003414a12f29', 'task_created', '{"task_title": "Submit the monthly ride-along report to the county"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-16 08:18:52+00'),
  ('a6dc8225-3058-4536-ad37-2df56d1dad68', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'ef922ec7-a320-4b66-99f9-cdb5d9720984', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Move the goat herd to the north pasture for fresh grazing"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-16 14:33:05+00'),
  ('10c87b5a-7526-40f2-abf6-ed10435fbc55', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '58deed68-9018-4a47-aab1-7d1c640e8f6e', 'task_created', '{"task_title": "Renew the roadside beet stand''s vendor permit"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-17 08:26:46+00'),
  ('3cb7fd30-9fd5-4145-8925-ab1ccf7bd425', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '71aa9c44-9aaf-4e70-9fea-3d706ed6b4ee', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Rotate the canned goods in the bunker by expiration date"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-19 09:26:32+00'),
  ('6843e59c-9b2d-4fd3-92ce-3f183c20727c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '5c2a0dc5-188b-4260-bf8d-21e947fff22c', 'task_created', '{"task_title": "Mow the fence line before it swallows the fence entirely"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-20 20:28:20+00'),
  ('af93d8fc-3e05-4c27-8183-25004627d546', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '02facb2b-e626-452c-b85f-8c98b61443f0', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Restock the outhouse before the weekend guests arrive"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-21 13:31:33+00'),
  ('cd28ad80-ded5-4c6d-968f-08eb58643f4f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'fc998e3f-4600-4a8f-a64b-c4f5a684f2ce', 'task_created', '{"task_title": "Negotiate beet pricing with the grocery buyer in Scranton"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-22 09:48:59+00'),
  ('949b1577-2567-4593-b9d4-3ced891772ba', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'd8fd562d-7cd5-445d-9548-676f9a5ae008', 'task_created', '{"task_title": "Clear brush from around the propane tank"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-22 21:51:04+00'),
  ('4a7de228-db14-430d-b66b-b114582c8f7a', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '5c2a0dc5-188b-4260-bf8d-21e947fff22c', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Mow the fence line before it swallows the fence entirely"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-23 02:45:48+00'),
  ('1a2889fd-f024-4930-9f68-3a19c1e335cd', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '3c8407ff-e732-4d18-85cd-598e49211280', 'task_created', '{"task_title": "Build a new jump-scare prop for the barn section"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-23 15:03:47+00'),
  ('5dae21c0-2f10-48b3-bfa2-00430b73f0e7', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '5c2a0dc5-188b-4260-bf8d-21e947fff22c', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Mow the fence line before it swallows the fence entirely"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-24 19:56:10+00'),
  ('425da332-fd6c-4763-a30e-5a2a15f683a5', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'ef922ec7-a320-4b66-99f9-cdb5d9720984', 'task_priority_changed', '{"new_priority": "whenever", "old_priority": "soon", "task_title": "Move the goat herd to the north pasture for fresh grazing"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-27 11:02:15+00'),
  ('45fc9b1c-b8b1-42a9-960a-d7a38221cbb7', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'cd302ce1-bd1d-4ac1-b67c-71778aa96219', 'task_created', '{"task_title": "Inspect the fire extinguishers in the barn"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-27 15:11:24+00'),
  ('4223fe6a-6d11-498b-8ed0-be5fcbe33c76', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'f071ad0b-439b-4163-a928-19ca67dc4c28', 'task_created', '{"task_title": "Test the haunted house''s animatronic scarecrow"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-27 17:54:40+00'),
  ('a6880546-9de4-4cce-bb90-f52d197c7e21', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '944f5592-4c56-44f0-ae8a-5bf556c86e1c', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Change the oil in the tractor before the next big plow"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-28 12:21:33+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('3e90b6bb-82a3-4311-afce-7ae7c38b2fb5', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'bc94a61a-a629-45bb-aec8-c1d08114d184', 'task_created', '{"task_title": "Plow the north field before the ground freezes"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-28 12:58:41+00'),
  ('96e47031-5a56-43fa-9589-c52319e2e263', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '38e16680-3d47-443b-a979-3d3c066df962', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Test the bunker''s fire suppression system"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-28 13:39:43+00'),
  ('30344161-4e4c-49e0-abc2-3f35b109d150', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'ddfc820e-69a1-4585-affa-e9047ba5e354', 'task_created', '{"task_title": "File the volunteer sheriff''s department expense report"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-29 14:55:28+00'),
  ('eacf5a5c-1dfd-4a28-b306-de42527c748f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '322770e4-c3c7-4e91-b213-96c0464747d4', 'task_created', '{"task_title": "Update the liability insurance for the haunted maze"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-01 07:52:41+00'),
  ('0e1384e6-3b42-4e99-a4f6-ba0a794c2ea2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '58deed68-9018-4a47-aab1-7d1c640e8f6e', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Renew the roadside beet stand''s vendor permit"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-01 13:30:05+00'),
  ('76f4aa5e-f8cf-4265-9887-b4c2baccb648', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'abebaf9c-9115-43a0-b8a0-5872e440ed31', 'task_created', '{"task_title": "Replace the tractor''s dead headlight"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-01 14:57:39+00'),
  ('ac86ff98-ec20-49ca-b5d6-0f18d5fd6b84', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '36826cd5-cbe9-4606-88e8-0d65061c8fec', 'task_due_date_changed', '{"new_due_date": "2026-03-08", "old_due_date": "2026-03-03", "task_title": "Test the compost pile''s nitrogen levels"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-01 18:21:52+00'),
  ('916acd0e-8835-4941-81d1-fb05f0b471f4', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '152ad141-87e4-4a37-9327-003414a12f29', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Submit the monthly ride-along report to the county"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-02 14:20:38+00'),
  ('7ba6f0af-2ee3-469f-af89-fd97c55c36a2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'd1e09fac-9dda-4db0-8bfa-645284302ebd', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Sow the second beet crop before the last frost"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-02 19:33:58+00'),
  ('63ecee39-5c16-42a9-910d-508ae2d02689', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '63e51f7f-6a9c-469a-ad25-537cb365d768', 'task_created', '{"task_title": "Run the full property lockdown drill"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-02 20:27:08+00'),
  ('8342e245-fc99-4a14-b991-47f9e7a32cc5', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '5801375a-9c57-4b23-813f-d3af12f361ff', 'task_created', '{"task_title": "Renew the concealed carry permit before it lapses"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-03 09:57:57+00'),
  ('57892649-9eb4-4f5d-a4e3-a220bc6c2c98', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'f6880308-2c44-415d-8dba-57a3226861bd', 'task_created', '{"task_title": "Turn the compost pile before it overheats"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 09:45:58+00'),
  ('4eef7ad7-418b-46fa-81c9-f58003f0cd5a', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'bc94a61a-a629-45bb-aec8-c1d08114d184', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Plow the north field before the ground freezes"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 10:13:16+00'),
  ('f5d44463-aad8-4ae1-93da-a662e75a1c46', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'c70eb3f7-d9ce-4b1f-98a4-58e202c41b8b', 'task_created', '{"task_title": "Inspect the perimeter fence for breaches"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 17:11:19+00'),
  ('c6e5a849-a901-4211-b4f4-ebecbaa7177f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'db868f19-f432-40e6-b7fa-f9cf4115298b', 'task_created', '{"task_title": "Replant the beet seedlings the frost got last week"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-06 08:08:20+00'),
  ('ebacb6bf-0937-4e1d-9acc-1b6d5387ca2e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '0f1ab644-b663-4181-ac78-f3e0895f256a', 'task_created', '{"task_title": "Top off the propane reserve tanks"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-06 10:15:36+00'),
  ('9223c98f-49b2-4be6-9bf4-c641d008a3ac', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'f3572656-474e-4e49-a2fe-de517c2f8034', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Deep clean the root cellar guest suite"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-07 15:15:37+00'),
  ('2bb16186-bc22-4db6-9301-04217bfc2493', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '706aac4f-7f92-4f40-99cd-0428bc8d6d62', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Replace batteries in the perimeter security cameras"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-08 12:03:07+00'),
  ('25709b48-2af3-4806-947e-3a5399c1c552', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '1dfbdb28-6ddc-4f55-881f-d92c7c0fcf0d', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Till the fallow field ahead of next season''s planting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-08 14:03:46+00'),
  ('f1fdc759-6b6a-4c9a-8a2e-2e67feb623ba', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '38963936-bece-4f71-85a7-5876537c91ed', 'task_created', '{"task_title": "Inventory the gas masks and replace the filters"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-08 16:06:24+00'),
  ('1798dbb3-3aca-46df-98f2-f8acd3d5999d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '36826cd5-cbe9-4606-88e8-0d65061c8fec', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Test the compost pile''s nitrogen levels"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-09 12:25:12+00'),
  ('530529eb-841d-446e-bb93-8ea59e6dd1db', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'bf56b2ec-3f26-4d92-b3ee-dce265d9c166', 'task_created', '{"task_title": "Follow up with a restaurant lead about sourcing beets locally"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-09 15:18:38+00'),
  ('a104a08e-3af6-4a54-93bb-d265d30cc97c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'a6744dc2-bfcb-4504-a564-9c1cf9352a4d', 'task_created', '{"task_title": "Inventory the gun safe and update the log"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-09 20:33:25+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('b4fdcb66-5de9-4e6a-a367-684eec2b4e23', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '130b9d85-b844-4e99-be78-5ecc08a9c08c', 'task_created', '{"task_title": "Feed the goats before the morning rounds"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-09 22:30:28+00'),
  ('ab8a0819-0030-4706-a1ea-cf9bb0f9df3d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '7a689278-fd27-42fb-891d-3b9702383e65', 'task_created', '{"task_title": "Run the annual (unannounced) farm-wide fire drill"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-10 06:16:16+00'),
  ('c026a9ba-9a2d-4ec3-ae8c-336ede8d5eb7', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '4ac69b13-b221-44d6-8b45-0722d877d316', 'task_created', '{"task_title": "Grease the thresher''s bearings before harvest week"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-10 09:57:07+00'),
  ('a266b9d4-d8a9-452f-914b-f27538e429a2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'c70eb3f7-d9ce-4b1f-98a4-58e202c41b8b', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Inspect the perimeter fence for breaches"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-11 14:46:08+00'),
  ('194c0926-9b0d-464f-b5bb-4b83880a0af2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '93926fe1-f12f-4571-9731-c3e47fe39efc', 'task_created', '{"task_title": "Recruit local teens as haunted house actors"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-11 18:14:28+00'),
  ('9f5a78a6-841a-421b-9d80-7af03bb2ab2d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'd0648a52-4f8f-4b51-8927-a728df4648c6', 'task_created', '{"task_title": "Update the B&B''s online listing photos"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-12 16:10:21+00'),
  ('bb11ac9e-3cba-43e2-b3b3-884de92e78be', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '17f076df-fc10-4f34-9e83-d1236b02a1dc', 'task_created', '{"task_title": "Renew the volunteer sheriff''s department paperwork"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-13 08:24:56+00'),
  ('220eb15d-1e51-4a68-a60b-43c1aa1cdad0', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'bc94a61a-a629-45bb-aec8-c1d08114d184', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Plow the north field before the ground freezes"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-13 13:53:23+00'),
  ('a66b4628-0f91-4bf1-9391-5a5b348f8d15', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '6b072305-8faf-4285-a42f-28ba16e9656f', 'task_created', '{"task_title": "Muck out the guest parking area before check-in"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-13 22:23:14+00'),
  ('d761bd25-feb5-4df5-b1f0-4caebee640dd', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '69eb44e2-44e3-4148-92fa-4ee902efa6fd', 'task_created', '{"task_title": "Replace the burnt-out lights along the maze path"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-14 22:06:42+00'),
  ('b4c247e3-1c72-491f-b95e-4d6e6ebb7a48', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'a448ade1-7bfb-47cf-9ee6-f7aa9904215a', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Clip the geese''s wings before they attack the mailman again"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-15 01:29:17+00'),
  ('d0898e66-963c-4ab8-91e9-72e69baacdf7', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '6b072305-8faf-4285-a42f-28ba16e9656f', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Muck out the guest parking area before check-in"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-15 06:41:47+00'),
  ('a0a97258-829c-4c80-86a0-fad305f7b628', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '79e3aa70-1c9e-45fd-a103-44e49a989edc', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Repair the manure spreader''s clogged chute"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-15 19:38:34+00'),
  ('ec5e3de0-10cf-4e1b-b263-d9595e6977a6', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '38963936-bece-4f71-85a7-5876537c91ed', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Inventory the gas masks and replace the filters"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-15 20:23:04+00'),
  ('6d42602b-1293-4322-82aa-3c24c7d21eca', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'affdb6da-8dc2-4f76-8a39-4bc6fe2e4521', 'task_created', '{"task_title": "Prepare the welcome basket of beets for arriving guests"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-16 09:12:08+00'),
  ('5f3813b9-79e2-41c2-a2e9-c40d19c6a86f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'f6880308-2c44-415d-8dba-57a3226861bd', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Turn the compost pile before it overheats"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-19 09:20:38+00'),
  ('55c870dc-1552-4c2a-ad22-a86ece231ad2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '93926fe1-f12f-4571-9731-c3e47fe39efc', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Recruit local teens as haunted house actors"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-19 20:29:01+00'),
  ('87b5f481-db42-428e-a5d2-25dab4feb2da', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '96ef0e6e-5aa9-4870-9852-3cafb683a2c2', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Wax the department-issued patrol vehicle"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-19 23:07:20+00'),
  ('1a437ca1-b0a5-45bc-86dc-ecb94981303c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '69eb44e2-44e3-4148-92fa-4ee902efa6fd', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Replace the burnt-out lights along the maze path"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-21 12:17:05+00'),
  ('82eb1a87-9245-400b-9142-9a60377c8093', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '130b9d85-b844-4e99-be78-5ecc08a9c08c', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Feed the goats before the morning rounds"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-21 15:14:27+00'),
  ('29e3e3e6-0d7b-4dd5-8935-4e117a75a12d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '0f1ab644-b663-4181-ac78-f3e0895f256a', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Top off the propane reserve tanks"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-21 17:26:21+00'),
  ('b4216b2c-1db2-48e6-be7d-4e6c2888d926', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'd06c3597-de4b-45b4-ba7a-eda287c056d2', 'task_created', '{"task_title": "Renew the B&B''s county health inspection certificate"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-22 11:21:15+00'),
  ('472a89f6-517d-4c64-a66a-baf4fe3be321', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'a6744dc2-bfcb-4504-a564-9c1cf9352a4d', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Inventory the gun safe and update the log"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-22 12:20:45+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('bcb1c3aa-c276-4140-b188-3cf076dbecac', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'c27e7a5a-b604-4947-9f58-d8a3edfa613c', 'task_created', '{"task_title": "Repair the beet harvester''s conveyor belt"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-22 13:01:32+00'),
  ('1ae78a5a-fe69-4840-b4c1-ce1845bb8859', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '092b7dc7-4ba5-4e21-95b9-c2455eb3f369', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Clean and test the department-issued flashlight"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-22 17:44:30+00'),
  ('a49b68bb-7ac5-4603-b0e8-e938614d952b', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '38963936-bece-4f71-85a7-5876537c91ed', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Inventory the gas masks and replace the filters"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-23 17:31:49+00'),
  ('33ab949f-ee25-44f2-8ef2-e0b1c5d9e7c9', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'a98b69a9-fb3f-4d06-a571-6d13954472fd', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Test the hand-crank emergency radio"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-24 12:08:11+00'),
  ('f7f3856f-5339-4347-bf9e-347a11c3da34', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'e75ed246-4c99-4b2e-bc40-0121d8783f38', 'task_created', '{"task_title": "Clean out the goat pen bedding"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-24 21:59:45+00'),
  ('37d91750-ecf0-4900-bc3e-db77479c6624', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'ad849efa-f395-4f21-8170-dca3b14e3f6b', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Spread manure on the fallow field before planting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-25 23:16:51+00'),
  ('e336d159-28db-4ea3-8c78-e451ba78bbbd', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '7f615527-2c0a-41b6-badd-7e564ca851be', 'task_created', '{"task_title": "Restock fake blood for the haunted house"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-28 10:14:21+00'),
  ('b46d48a2-4a92-40e2-8c9f-52c6b9a4b76a', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '4ac69b13-b221-44d6-8b45-0722d877d316', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Grease the thresher''s bearings before harvest week"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-28 12:18:24+00'),
  ('d2d55103-e3b4-4567-ba23-d66cd7231a68', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '388eefe7-5dd9-4eb2-b1eb-7cf16c81749f', 'task_created', '{"task_title": "Restock the water purification tablets"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-28 21:17:41+00'),
  ('e597374d-3072-4540-9b37-837cb5c5421c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'ee6e7fe6-0ece-4070-9194-9df3bb557768', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Review the fire escape route with Mose"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-28 21:50:34+00'),
  ('422a1fc2-234e-41f9-a025-166e1620cec4', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '6cb4a6fc-0b1a-4ed6-a352-bca774b9c3a4', 'task_created', '{"task_title": "Restock the burn barrel safety kit"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-30 17:51:36+00'),
  ('6308e279-9260-42b6-9d08-5d9d8a328d9b', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'e9399fa9-f4e0-45e8-997f-4097090dc2a1', 'task_created', '{"task_title": "Till under the cover crop before spring planting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-01 15:15:36+00'),
  ('f08dc3c0-82a8-4371-9f2d-41c548a99e08', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '6e2e3288-a87c-4185-8823-de1db31f0f6a', 'task_created', '{"task_title": "Cut this year''s corn maze pattern"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-01 19:34:10+00'),
  ('2fb08adf-c0ed-4df0-bf78-7e4eb561a957', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '88eac54c-219d-4838-8fd7-624ff27b95e5', 'task_created', '{"task_title": "Restock the emergency beet rations shelf"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-02 14:30:59+00'),
  ('49a0c60b-697d-42dc-920b-4be4a8230954', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '25476c46-ed4e-446c-83ac-d91263954b41', 'task_created', '{"task_title": "Sort beets by size for the county fair entry"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-02 20:52:46+00'),
  ('7643240f-59be-4ba4-af2e-5e66de2911a9', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '88eac54c-219d-4838-8fd7-624ff27b95e5', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Restock the emergency beet rations shelf"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 01:38:47+00'),
  ('95deba37-479a-4d6d-af76-3b5f7777357e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '5801375a-9c57-4b23-813f-d3af12f361ff', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Renew the concealed carry permit before it lapses"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 07:41:31+00'),
  ('307b3a88-c1df-41c3-8735-c8fe5af41843', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '93926fe1-f12f-4571-9731-c3e47fe39efc', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Recruit local teens as haunted house actors"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 09:53:04+00'),
  ('66ed4f05-29ec-4afa-85e5-13133f3a4669', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'd0648a52-4f8f-4b51-8927-a728df4648c6', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Update the B&B''s online listing photos"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 01:48:16+00'),
  ('e6588ae5-8946-431d-bfd9-307e28ffd1f3', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '02facb2b-e626-452c-b85f-8c98b61443f0', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Restock the outhouse before the weekend guests arrive"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 12:31:57+00'),
  ('865b2abd-9176-4ff5-acf0-daa43d3928ea', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '3c8407ff-e732-4d18-85cd-598e49211280', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Build a new jump-scare prop for the barn section"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 12:58:37+00'),
  ('bad46741-a4db-4766-967b-798248e855c7', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '38e16680-3d47-443b-a979-3d3c066df962', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Test the bunker''s fire suppression system"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 15:26:26+00'),
  ('e9cf3560-0f25-4407-b7a7-9f32b8a2fc07', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'd9c4e4ac-7b0b-495a-8762-14bef511e775', 'task_created', '{"task_title": "Worm the goat herd on schedule"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-11 15:13:50+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('b4498974-b66f-4327-8a64-44230e6b87fa', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '96bb0531-0dcf-43c2-b971-10f5276cb9ee', 'task_created', '{"task_title": "Order more hay bales for the maze walls"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-11 21:30:35+00'),
  ('2dd4a950-9a37-4670-b3e7-2beb0ae75c3f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '2d5e0e20-28c3-48c4-a54b-87f6f6ed59ec', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Restock the trunk first-aid kit"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-15 14:56:05+00'),
  ('aaf576c1-4b72-4ab4-af71-a8ac91a327db', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '25476c46-ed4e-446c-83ac-d91263954b41', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Sort beets by size for the county fair entry"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-16 12:49:20+00'),
  ('c63e3103-86ae-4a5e-a78f-5946b61c8375', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '322770e4-c3c7-4e91-b213-96c0464747d4', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Update the liability insurance for the haunted maze"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-16 18:14:13+00'),
  ('39045264-b208-491c-a9bd-33cde8f88efe', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'e75ed246-4c99-4b2e-bc40-0121d8783f38', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Clean out the goat pen bedding"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-16 21:05:47+00'),
  ('1304397a-c0ea-4ce8-b742-08df20a34f3f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'dd4a930e-2c28-4a8d-b7ca-0b867eada97c', 'task_created', '{"task_title": "Repair the hose reel by the barn"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 06:53:20+00'),
  ('dd31fcb0-f008-45d5-adc8-ad70ea34e94e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '0f1ab644-b663-4181-ac78-f3e0895f256a', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Top off the propane reserve tanks"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 07:21:35+00'),
  ('80dc5e6e-f8b6-4d09-9509-872b55eea59d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'd4c164cf-3452-44fe-8cfd-05bdf1cb90e2', 'task_created', '{"task_title": "Call the regional grocery chain about a beet supply contract"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 09:43:54+00'),
  ('df43f575-551e-40d7-bb25-fa5055dac7dd', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '46e55f5e-e680-43bc-8a3d-e74b8668569c', 'task_created', '{"task_title": "Patch the hinge on the bunker''s escape hatch"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 16:10:42+00'),
  ('a81f5c1e-6216-4df5-8a34-738e8b1f86ae', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'd9c4e4ac-7b0b-495a-8762-14bef511e775', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Worm the goat herd on schedule"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 18:59:18+00'),
  ('da94c249-712b-4ffc-aeb2-ac1998abab60', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '6e2e3288-a87c-4185-8823-de1db31f0f6a', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Cut this year''s corn maze pattern"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 20:46:07+00'),
  ('c79e8e5e-b04e-4e6c-b36b-1c32b058552f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'a6744dc2-bfcb-4504-a564-9c1cf9352a4d', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Inventory the gun safe and update the log"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 21:01:45+00'),
  ('1e2f4d12-f86a-4e37-926d-5d023ae293fe', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '7ca73e5c-c552-4ad5-a0c7-099b594dc739', 'task_created', '{"task_title": "Weed the beet rows before they choke the seedlings"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-18 07:54:15+00'),
  ('d9487ad8-3873-418b-9d45-27d235bb3c43', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '8922c6e9-784a-4867-a173-ad4c8a294817', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Tune up the chainsaw before hedge-laying season"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-19 01:10:53+00'),
  ('30a14a9e-bfb8-4474-b2ea-5820c4149591', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '96bb0531-0dcf-43c2-b971-10f5276cb9ee', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Order more hay bales for the maze walls"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 07:31:45+00'),
  ('2bbd9aa0-dfd9-4f40-909c-e071cb4c8287', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '7a689278-fd27-42fb-891d-3b9702383e65', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Run the annual (unannounced) farm-wide fire drill"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 10:03:15+00'),
  ('2d533192-5e82-41ed-87c9-1379b86c8699', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '7ca73e5c-c552-4ad5-a0c7-099b594dc739', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Weed the beet rows before they choke the seedlings"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 17:03:43+00'),
  ('82967d1b-dc33-4017-9850-e1f145c0aa9e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'affdb6da-8dc2-4f76-8a39-4bc6fe2e4521', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Prepare the welcome basket of beets for arriving guests"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 21:12:24+00'),
  ('def745ea-ab52-4cab-a1c1-44b7efa8eda2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '46e55f5e-e680-43bc-8a3d-e74b8668569c', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Patch the hinge on the bunker''s escape hatch"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-21 08:44:07+00'),
  ('b5cb2f7d-0339-430c-99b9-70c00b6d9a85', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'a8d424d8-ee04-4193-b7bd-051c06dbc9eb', 'task_created', '{"task_title": "Patrol the county fairgrounds ahead of the weekend event"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-21 13:09:00+00'),
  ('020e4164-e9b1-4295-8417-0dd5dd058cd5', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '13752e12-9a16-45cb-bf9e-2fc61b6394f1', 'task_created', '{"task_title": "Test the sugar content of this year''s beet crop"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-21 16:42:59+00'),
  ('0617f2fb-05f2-4a09-83f5-bfa12d009c66', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '1dfbdb28-6ddc-4f55-881f-d92c7c0fcf0d', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Till the fallow field ahead of next season''s planting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-21 22:52:28+00'),
  ('d855f47b-c144-46d8-8791-4b52c7fd0adb', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'e3a5f2dd-839e-437f-979e-fef462b15b19', 'task_created', '{"task_title": "Order more chicken feed before the coop runs dry"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-22 18:50:16+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('1e521673-defe-4dbf-b2bb-46fa701904ae', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '92ce94cf-3bd6-45a9-bbb3-23f525a3dfac', 'task_created', '{"task_title": "Sharpen the plow blades before the fall till"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-23 10:16:17+00'),
  ('27530aba-58a3-40bc-97a5-8df7558f410f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'd4c164cf-3452-44fe-8cfd-05bdf1cb90e2', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Call the regional grocery chain about a beet supply contract"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-23 21:10:04+00'),
  ('2fd8dac0-c757-4747-ba3b-29c000f06def', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'e3a5f2dd-839e-437f-979e-fef462b15b19', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Order more chicken feed before the coop runs dry"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-24 05:53:06+00'),
  ('f79b0b2c-379c-4b32-8bf6-4d829e530aab', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'a8d424d8-ee04-4193-b7bd-051c06dbc9eb', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Patrol the county fairgrounds ahead of the weekend event"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-25 11:11:47+00'),
  ('773858e8-f81f-42dd-95f7-05be9043d34c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '13752e12-9a16-45cb-bf9e-2fc61b6394f1', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Test the sugar content of this year''s beet crop"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-25 12:18:52+00'),
  ('a2262194-806f-4d65-a352-8dcd0c565680', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'dd7a2a6b-ce7e-4e88-a819-b0b7949bd5b5', 'task_created', '{"task_title": "Negotiate the county fair beet booth pricing"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-26 08:00:44+00'),
  ('63128ca8-a8e3-49a7-8c55-dfc831e5163e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '13f81fae-0699-41b3-a0c1-ace102d95d90', 'task_created', '{"task_title": "Replace the smoke detector batteries across the property"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-26 08:26:11+00'),
  ('ab30bb5b-bcd1-475c-bf28-77fd420bf475', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '7ca73e5c-c552-4ad5-a0c7-099b594dc739', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Weed the beet rows before they choke the seedlings"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-26 16:35:50+00'),
  ('455ae445-8567-4c8c-aea7-6a74d5001c97', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '388eefe7-5dd9-4eb2-b1eb-7cf16c81749f', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Restock the water purification tablets"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-26 17:26:03+00'),
  ('c41b8cc7-610a-4e41-a575-e822f88a497d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '63e51f7f-6a9c-469a-ad25-537cb365d768', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Run the full property lockdown drill"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-27 17:33:39+00'),
  ('6b5971d3-d91d-4948-8282-22dc3e88193a', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '96ef0e6e-5aa9-4870-9852-3cafb683a2c2', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Wax the department-issued patrol vehicle"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-28 12:05:24+00'),
  ('21dbfb8a-1f93-42ee-8a59-eae9e3cda2b7', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'f6880308-2c44-415d-8dba-57a3226861bd', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Turn the compost pile before it overheats"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-29 12:18:25+00'),
  ('6e4f2cb3-0a92-43bd-9e22-3741d415e4a1', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'd0648a52-4f8f-4b51-8927-a728df4648c6', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Update the B&B''s online listing photos"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-29 12:58:18+00'),
  ('eae61763-fe3c-4d61-b78c-4779377e9dea', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '2ba5820b-af54-4341-bfc3-a920a353bc37', 'task_created', '{"task_title": "Sharpen the display katana in the great room"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-01 09:26:22+00'),
  ('c170abc8-b514-4122-817f-6d62b926653e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '0bd8fa70-e870-440b-bf75-e1c3723b5564', 'task_created', '{"task_title": "Treat a goat with a mild limp"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-02 14:18:39+00'),
  ('ef9b72b6-b3e4-4124-b7d3-e9427065ddfb', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '9775fcfa-459c-42f0-9dbe-417bd48a28e5', 'task_created', '{"task_title": "Print new price tags for the farm stand"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-03 14:01:06+00'),
  ('4196bf1a-ac4d-4163-9b1b-6f0a682c586b', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '5801375a-9c57-4b23-813f-d3af12f361ff', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Renew the concealed carry permit before it lapses"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-03 14:20:28+00'),
  ('5e5c5033-373b-4301-9060-3ad473816452', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '9775fcfa-459c-42f0-9dbe-417bd48a28e5', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Print new price tags for the farm stand"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-04 19:34:51+00'),
  ('b2a02dfb-9264-499f-9aec-b41f2aa6ee71', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '9f747efb-8253-4fb5-ab66-f0e0ac784669', 'task_created', '{"task_title": "Collect eggs from the coop before the raccoons find them first"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-05 07:39:39+00'),
  ('e7757b0c-769f-4b22-a112-cb5c5f07f127', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '0bd8fa70-e870-440b-bf75-e1c3723b5564', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Treat a goat with a mild limp"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-05 10:47:55+00'),
  ('aa1b77c9-25bf-4eac-8456-89e72e17da69', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '56d28867-b98a-4d8e-a71e-6eb781085a0f', 'task_created', '{"task_title": "Service the wood chipper before hedge-clearing season"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-05 13:30:20+00'),
  ('74f306b5-55f4-4804-8a58-e5b1d427c6f2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'f8bf8dcd-2ac9-4e3a-9e3d-0e1de537f3b7', 'task_created', '{"task_title": "Load the beet truck for the Saturday farmers market"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-05 21:59:00+00'),
  ('77b789df-75b9-40a1-86ed-6e5831b4979f', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'abebaf9c-9115-43a0-b8a0-5872e440ed31', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Replace the tractor''s dead headlight"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-06 15:04:24+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('6e1769bf-2ecb-440e-adf9-b13b521d0d41', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '75daf29d-6296-475d-b8be-8c0f56920692', 'task_created', '{"task_title": "Muck out the barn stalls"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-07 12:34:47+00'),
  ('d55701be-1921-419d-9b15-9cb0897dac9a', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '72d44b7b-6ba5-443d-85d5-a37173710393', 'task_created', '{"task_title": "Check expiration dates on the emergency ration kits"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-07 14:38:32+00'),
  ('72b01c52-9998-46c6-9044-7f435bbd5541', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'dd4a930e-2c28-4a8d-b7ca-0b867eada97c', 'task_due_date_changed', '{"new_due_date": "2026-07-30", "old_due_date": "2026-07-19", "task_title": "Repair the hose reel by the barn"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-07 16:24:21+00'),
  ('3c2d54b1-7af1-4e68-9d78-da0e251c3358', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '9f747efb-8253-4fb5-ab66-f0e0ac784669', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Collect eggs from the coop before the raccoons find them first"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-08 14:40:39+00'),
  ('29341148-5766-4dc2-a022-0af4d261896b', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'location_created', '{"location_id": "502be97f-5b8e-4cce-ad68-4175a221757e", "location_name": "Main House"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-08 21:26:55+00'),
  ('e9605c54-3ec7-412b-a39b-0f9e98bc614c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '06be9f14-bdd6-495d-853b-1d91a7d408a2', 'task_created', '{"task_title": "File the farm''s annual tax paperwork"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-09 15:09:04+00'),
  ('60ff5d03-99ee-462b-90d9-a51553023352', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'e2edf5ef-0281-43aa-b987-920039bdf412', 'task_created', '{"task_title": "Draft a wholesale pitch for the honey line"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-09 17:01:03+00'),
  ('3d93f223-f76f-41b2-9a5b-61f58157a73c', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '706aac4f-7f92-4f40-99cd-0428bc8d6d62', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Replace batteries in the perimeter security cameras"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-10 10:37:08+00'),
  ('be648624-2e47-49aa-af64-446434b04281', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'd06c3597-de4b-45b4-ba7a-eda287c056d2', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Renew the B&B''s county health inspection certificate"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-10 15:11:22+00'),
  ('71d9fba5-cda0-42e3-9cdc-2b15b3966108', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'db25bcc7-e9f3-4940-b202-714722c8fcdb', 'task_created', '{"task_title": "Chase down payment from a beet buyer who''s gone quiet"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-10 15:51:54+00'),
  ('b1687ce8-94e7-4f55-bc63-77c484f629d9', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'location_created', '{"location_id": "22a2ecfd-a5c4-4b55-a699-b057cfbb90b5", "location_name": "North Beet Field"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-10 17:18:56+00'),
  ('e33ecfb8-261b-4801-8e57-c92c138b1314', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'dd4a930e-2c28-4a8d-b7ca-0b867eada97c', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Repair the hose reel by the barn"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 01:55:03+00'),
  ('04f4b567-eedb-4c93-a562-a1c0fbb21b51', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'location_created', '{"location_id": "97684a5c-ce9b-4b8a-8e4a-9e736931f109", "location_name": "Bunker Entrance"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 06:24:42+00'),
  ('017ce5e3-8a33-481d-8597-3548d165860d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'location_created', '{"location_id": "1bbc1150-b09f-408f-adf1-f1590c06fbab", "location_name": "Barn"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 08:39:10+00'),
  ('b9a77606-b8fa-4e0b-accb-f773c22cd135', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'f8bf8dcd-2ac9-4e3a-9e3d-0e1de537f3b7', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Load the beet truck for the Saturday farmers market"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 09:48:19+00'),
  ('8e127b44-af92-41fb-a154-5a669f7d489e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'location_created', '{"location_id": "84b0f762-fcb5-4a03-8b6c-b5c9586489fa", "location_name": "Goat Pen"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 15:01:03+00'),
  ('49acc424-4c57-4007-9712-d4f6462cf0f8', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '9f747efb-8253-4fb5-ab66-f0e0ac784669', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Collect eggs from the coop before the raccoons find them first"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 16:16:59+00'),
  ('d6b44bb4-6b3e-4643-8fc0-fddb23a4a544', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '6e2e3288-a87c-4185-8823-de1db31f0f6a', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Cut this year''s corn maze pattern"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 18:48:41+00'),
  ('c97e8345-05b9-4307-8630-675216952aac', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'location_created', '{"location_id": "0273af56-a23c-4ead-b44b-bce362bbb4b6", "location_name": "Chicken Coop"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 20:02:49+00'),
  ('74a8a57d-3117-420c-9b12-8c9973e965a0', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '3d324c99-65bd-4ea8-9102-1077d8b56b0b', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Print tickets for the Halloween haunted house event"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 20:40:23+00'),
  ('659e17ea-e116-45bc-a3cb-b7983378f9da', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '06be9f14-bdd6-495d-853b-1d91a7d408a2', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "File the farm''s annual tax paperwork"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 00:41:19+00'),
  ('df4e9b34-c9b0-42c0-a78a-4d0198d62b3b', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '0bd8fa70-e870-440b-bf75-e1c3723b5564', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Treat a goat with a mild limp"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 07:01:31+00'),
  ('38ddd082-054f-4368-b889-43c62f86bf4e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'location_created', '{"location_id": "07e359a3-c3b5-4606-b62c-0d8300141448", "location_name": "Cornfield Maze"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 14:11:55+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('3a005989-903b-4a31-910a-8d61d03a7a90', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'dd7a2a6b-ce7e-4e88-a819-b0b7949bd5b5', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Negotiate the county fair beet booth pricing"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 19:58:11+00'),
  ('dd9ffa5a-2deb-4bef-9e04-4cfdd063a6f1', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '4cdd13da-0f2b-457c-80ab-eaaea441923e', 'task_created', '{"task_title": "Spread lime on the acidic patch near the tree line"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 07:14:05+00'),
  ('656195b7-bee5-46a2-bfd0-c33b22dee17d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'location_created', '{"location_id": "95036e00-2bcc-4dad-aa7b-624466f7d323", "location_name": "Root Cellar"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 14:33:22+00'),
  ('7dea6268-3ed2-45c2-87be-bb3c6289f003', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'location_created', '{"location_id": "417fcab2-a3c6-491b-90d8-319fdae1fb55", "location_name": "Outhouse"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 15:35:28+00'),
  ('cd387e64-3053-458e-802f-f0cc1c732c98', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', NULL, 'location_created', '{"location_id": "b6edecf2-9b84-41ae-b78f-5c781f4cc1cf", "location_name": "Silo"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 17:06:37+00'),
  ('3361ac1d-cbf2-4657-bfc8-c5713970a8d2', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '56d28867-b98a-4d8e-a71e-6eb781085a0f', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Service the wood chipper before hedge-clearing season"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 18:42:44+00'),
  ('c5daee1f-72fd-432f-a4aa-af5347c36f2e', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '92ce94cf-3bd6-45a9-bbb3-23f525a3dfac', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Sharpen the plow blades before the fall till"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 22:41:08+00'),
  ('c6a31e7f-bee4-479d-8aa6-db7f92626caa', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '75daf29d-6296-475d-b8be-8c0f56920692', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Muck out the barn stalls"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-14 00:05:41+00'),
  ('95de74b4-c748-469a-becf-81ccbd30e2e8', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '4cdd13da-0f2b-457c-80ab-eaaea441923e', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Spread lime on the acidic patch near the tree line"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-14 08:53:26+00'),
  ('ce1a821e-b486-43b2-8acd-9c92168fd7a8', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'e2edf5ef-0281-43aa-b987-920039bdf412', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Draft a wholesale pitch for the honey line"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-14 16:32:31+00'),
  ('9784d424-6dfe-4652-b269-de8fcb057d5d', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', '2ba5820b-af54-4341-bfc3-a920a353bc37', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Sharpen the display katana in the great room"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-14 20:51:59+00'),
  ('39963763-8144-4fcd-a3de-d322d2dc49b6', 'e514354e-2d0c-4cf2-82f4-fccab8fc678a', 'f8bf8dcd-2ac9-4e3a-9e3d-0e1de537f3b7', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Load the beet truck for the Saturday farmers market"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-15 06:35:28+00');

COMMIT;
