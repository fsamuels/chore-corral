-- Schrute Farms sample data seed
--
-- Populates Chore Corral with themed sample data for the 'Schrute Farms'
-- demo tenant (Dwight Schrute's beet farm and bed & breakfast, near
-- Honesdale, Pennsylvania), covering the farm itself, categories (with
-- emoji), tags, locations, tasks (with location, time estimate and
-- completion attribution), task_tags, task_photos, task_shopping_items,
-- task_tools, task_time_entries and the activity log.
--
-- Unlike the Clarkson's Farm seed, this farm does not exist yet: the
-- script INSERTs a new `farms` row and a `farm_memberships` row (owned by
-- the same account used for Clarkson's Farm, fab9883a-1a2b-4339-af66-81e122c74fa6) in
-- addition to the usual category/tag/location/task data.
--
-- DESTRUCTIVE (for this farm only): this script first hard-deletes any
-- existing task_photos, task_tags, task_shopping_items, task_tools,
-- task_time_entries, tasks, tags, categories, locations, and activity_log
-- rows scoped to the farm below, then reinserts the full sample data set.
-- It is rerunnable -- running it again wipes and reseeds the same farm's
-- data from scratch. It does not touch any other farm's data.
--
-- Apply with the Supabase CLI:
--   supabase db query --linked --file supabase/seeds/schrute_farms_sample_data.sql

BEGIN;

-- Target farm: Schrute Farms (d3c5bc02-aa7d-49cd-85b7-1302f1056e0e)

-- ---------------------------------------------------------------------------
-- Wipe existing farm-scoped data (hard delete, farm-scoped only)
-- ---------------------------------------------------------------------------

DELETE FROM task_photos WHERE task_id IN (SELECT id FROM tasks WHERE farm_id = 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e');
DELETE FROM task_tags WHERE task_id IN (SELECT id FROM tasks WHERE farm_id = 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e');
DELETE FROM task_shopping_items WHERE task_id IN (SELECT id FROM tasks WHERE farm_id = 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e');
DELETE FROM task_tools WHERE task_id IN (SELECT id FROM tasks WHERE farm_id = 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e');
DELETE FROM task_time_entries WHERE task_id IN (SELECT id FROM tasks WHERE farm_id = 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e');
DELETE FROM tasks WHERE farm_id = 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e';
DELETE FROM tags WHERE farm_id = 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e';
DELETE FROM categories WHERE farm_id = 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e';
DELETE FROM locations WHERE farm_id = 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e';
DELETE FROM activity_log WHERE farm_id = 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e';

-- ---------------------------------------------------------------------------
-- Farm + membership
-- ---------------------------------------------------------------------------

INSERT INTO farms (id, name, address, default_lat, default_lng, created_at)
VALUES
  ('d3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Schrute Farms', 'Schrute Farms, Honesdale, Pennsylvania, United States', 41.5776, -75.2596, '2026-02-18 08:00:00+00')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  address = EXCLUDED.address,
  default_lat = EXCLUDED.default_lat,
  default_lng = EXCLUDED.default_lng;

INSERT INTO farm_memberships (id, farm_id, user_id, created_at)
VALUES
  ('fb9bc90d-ce58-4c7c-98bc-e4b0275acea5', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-18 08:00:00+00')
ON CONFLICT (farm_id, user_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Categories
-- ---------------------------------------------------------------------------

INSERT INTO categories (id, farm_id, name, emoji, deleted_at, created_at)
VALUES
  ('ed5373e3-7df6-4787-8fec-dbccf16d7d2b', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Beets', '🫜', NULL, '2026-02-21 13:47:45+00'),
  ('b77093f4-829e-4c34-90fb-f907ef6f00d9', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Bed & Breakfast', '🛏', NULL, '2026-02-22 08:50:08+00'),
  ('6eead71b-9b15-417c-95af-dc21efc8583b', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Security & Bunker', '🔒', NULL, '2026-02-23 10:26:04+00'),
  ('57f6371d-085d-459b-bbfb-933786a8c391', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Volunteer Sheriff''s Dept', '🚔', NULL, '2026-02-24 21:34:43+00'),
  ('59b12413-8b34-4639-8f8c-cedebd452bd8', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Livestock', '🐐', NULL, '2026-02-25 19:08:45+00'),
  ('3161f1b6-ca0b-40de-b203-ed43a988a431', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Land & Fields', '🌾', NULL, '2026-02-26 16:36:56+00'),
  ('77982b80-16a6-4d7f-93c7-b6744c1f3af3', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Fire Safety & Drills', '🔥', NULL, '2026-02-26 09:43:43+00'),
  ('45686050-73fd-4e14-9505-dfc1a8d5b833', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Machinery & Repairs', '🚜', NULL, '2026-02-27 14:43:23+00'),
  ('d0c3ab3a-cc0b-45fb-a309-0bd1d83de563', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Paperwork & Compliance', '📋', NULL, '2026-02-27 11:56:45+00'),
  ('2ebd1f55-9513-4605-a716-72a9ac3c85f3', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Bunker Provisions', '🥫', NULL, '2026-03-02 13:28:18+00'),
  ('1b6336f4-28ac-4684-a0b1-b55d65aa1e3e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Sales & Customers', '📞', NULL, '2026-03-02 18:06:49+00'),
  ('d8d8eb08-0e03-4684-9f3f-899dcdb9d0de', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Haunted House & Maze', '🎃', NULL, '2026-03-06 09:17:49+00'),
  ('8c2a4844-e870-4ab7-b247-5406377d3c03', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Manure & Composting', '💩', NULL, '2026-03-08 13:01:10+00');

-- ---------------------------------------------------------------------------
-- Tags
-- ---------------------------------------------------------------------------

INSERT INTO tags (id, farm_id, name, created_at)
VALUES
  ('0b3f238f-c45d-4d59-8354-c4082127602e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'dwight', '2026-02-27 11:06:57+00'),
  ('cb085931-121b-4c76-bfb9-9ff78b6d5d30', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'mose', '2026-03-03 11:22:29+00'),
  ('4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'beets', '2026-03-09 19:28:20+00'),
  ('dde34e2e-373c-4d27-a37e-b7c3002d9023', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'goats', '2026-03-11 17:08:54+00'),
  ('16af03c2-6c34-49d1-aa2d-3f57c01f6dd9', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'geese', '2026-03-15 13:04:27+00'),
  ('ae7b285d-fc15-44c7-a7ab-898eef004d23', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'chickens', '2026-03-16 17:21:12+00'),
  ('a828f87e-79df-4009-8356-1e840263dc65', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'bnb', '2026-03-17 14:54:47+00'),
  ('3577aa58-5805-4fba-96b5-2114d43a54cc', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'guests', '2026-03-17 10:10:10+00'),
  ('a7f04cb5-9035-49ff-9b92-4b69157cfaa1', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'bunker', '2026-03-23 21:13:49+00'),
  ('19683371-bf72-495b-964e-dccb89991aa0', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'sheriff-duties', '2026-03-24 09:07:34+00'),
  ('7a8513d6-3e59-4b60-a184-f585648f6401', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'fire-drill', '2026-03-28 12:59:16+00'),
  ('d782a503-421b-45d9-92e9-1cb680ea8ee6', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'gun-safety', '2026-04-01 11:32:40+00'),
  ('03efe0c1-35d4-44ac-b9b3-b43e0e49a7b1', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'crossbow', '2026-04-02 06:18:30+00'),
  ('117f414a-4ae2-4cf3-aef1-292d13184b5b', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'beekeeping', '2026-04-03 19:17:17+00'),
  ('f18ee02e-c875-4e55-a514-99a4e2857b04', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'honey', '2026-04-03 15:27:34+00'),
  ('990d1f4e-613a-44fd-8dbd-7a6e71caf627', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'compost', '2026-04-08 07:52:45+00'),
  ('b28acd21-f361-4b14-b87b-561bfd2bca0e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'manure', '2026-04-18 09:15:15+00'),
  ('a8a75c48-7665-49cf-840f-5301569ae362', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'cornfield', '2026-04-19 17:37:47+00'),
  ('e3b4dc3f-49c2-47d0-972d-09a9c9eb5dbb', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'haunted-house', '2026-04-20 11:50:22+00'),
  ('33c02cfe-dc6a-485a-8218-fd206d574b24', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'hay-king', '2026-05-04 17:38:43+00'),
  ('c75f19fc-9d6f-431d-ae44-147923fa5f98', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'wheat', '2026-05-11 15:11:32+00'),
  ('d631b291-5ee2-4565-b4db-8b88adac59c7', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'silo', '2026-05-13 16:41:24+00'),
  ('02317cab-7ee7-4cda-b3fb-413d13dd7b18', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'tractor', '2026-05-14 07:00:58+00'),
  ('d7cb5998-c105-4260-8cb2-12b98748add6', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'plow', '2026-05-18 12:18:03+00'),
  ('1d8de7bd-92b5-420c-b21a-5e2c63d3aa95', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'well-water', '2026-05-20 08:40:02+00'),
  ('d4f61126-db88-41a7-b611-a6ffdcd385d1', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'outhouse', '2026-05-24 11:40:50+00'),
  ('43b7f15d-bf21-48c2-b184-014bbdd27130', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'taxidermy', '2026-05-25 16:09:22+00'),
  ('45436fb5-d936-4681-a87d-82a437662064', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'salt-mine', '2026-05-26 15:35:41+00'),
  ('5797df59-6178-47b7-94b8-7b320d5cd853', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'schrute-bucks', '2026-05-27 09:33:12+00'),
  ('a5285487-d92a-4d18-8a22-e35468cfd627', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'thermostat', '2026-05-27 18:56:31+00'),
  ('bc2cea12-b86b-408e-887b-2cfb775a237e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'karate', '2026-05-31 13:10:25+00'),
  ('0891c72e-82ca-48fa-b1b4-9f26311febf5', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'security-system', '2026-06-08 10:50:14+00'),
  ('23cbc677-9974-4893-93c5-026053ef1b82', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'land-survey', '2026-06-12 13:31:25+00'),
  ('71ad03df-9bfd-48e3-b4fd-fab728661546', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'amish-cousins', '2026-06-13 12:52:59+00'),
  ('db188e28-ffed-4ca4-b3bc-d73564178b30', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'root-cellar', '2026-06-13 17:13:10+00'),
  ('e45c4887-040c-4314-ae41-3f527b7af24c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'paintball', '2026-06-14 08:07:09+00'),
  ('a3dadde6-00c9-4893-868c-dbbf2ac02f72', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'prep', '2026-06-19 22:49:35+00'),
  ('6f92eeea-1a2e-4186-b085-eb12ae94b5e1', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'paperwork', '2026-06-19 07:50:22+00');

-- ---------------------------------------------------------------------------
-- Locations
-- ---------------------------------------------------------------------------

INSERT INTO locations (id, farm_id, name, lat, lng, deleted_at, created_at)
VALUES
  ('0973c219-2cfe-42ac-a524-8e1c7795da3a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Main House', 41.574454, -75.243744, NULL, '2026-07-08 08:36:20+00'),
  ('c6132f4e-089e-4f95-bf1d-a88d98ff597a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'North Beet Field', 41.584494, -75.271005, NULL, '2026-07-10 15:31:24+00'),
  ('70516c49-27aa-4408-8bbc-12ccff39a516', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Bunker Entrance', 41.580327, -75.263172, NULL, '2026-07-11 17:32:18+00'),
  ('7c0e7905-c9bd-4189-ac34-b03e5f94741e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Barn', 41.591091, -75.261507, NULL, '2026-07-11 15:04:58+00'),
  ('27e8ae39-4d92-4f52-9625-3c4cf19f1290', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Chicken Coop', 41.563762, -75.264929, NULL, '2026-07-11 15:59:22+00'),
  ('ffbc1348-ebdf-472f-a25d-3c27fece7a66', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Goat Pen', 41.563649, -75.259243, NULL, '2026-07-11 22:33:14+00'),
  ('38bcb8d0-1f77-4bf6-ab82-ca3338eb1dde', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Cornfield Maze', 41.581185, -75.269591, NULL, '2026-07-12 15:42:52+00'),
  ('25654847-e3eb-43b6-80f3-84c1bcbea603', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Root Cellar', 41.585378, -75.244132, NULL, '2026-07-13 17:48:59+00'),
  ('2566ba1b-9bb1-4243-a1f5-537ae07940a9', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Outhouse', 41.592034, -75.249574, NULL, '2026-07-13 10:42:25+00'),
  ('a3f69e4a-7259-4e42-9980-bd0dfb39ae5d', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Silo', 41.564624, -75.26575, NULL, '2026-07-13 20:37:23+00');

-- ---------------------------------------------------------------------------
-- Tasks
-- ---------------------------------------------------------------------------

INSERT INTO tasks (id, farm_id, title, category_id, priority, status, due_date, notes, lat, lng, location_id, estimated_minutes, completed_by, completed_by_name, created_at, created_by, completed_at)
VALUES
  ('e2b08f3c-4a3e-470c-92a2-731f48a98b9f', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Sow the second beet crop before the last frost', 'ed5373e3-7df6-4787-8fec-dbccf16d7d2b', 'whenever', 'in_progress', NULL, 'Mose says the soil temperature is exactly right. He is never wrong about soil.', NULL, NULL, 'c6132f4e-089e-4f95-bf1d-a88d98ff597a', 20, NULL, NULL, '2026-03-10 06:22:47+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('a4f5452c-ea94-4eda-a157-2589c0bb5809', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Load the beet truck for the Saturday farmers market', 'ed5373e3-7df6-4787-8fec-dbccf16d7d2b', 'whenever', 'done', NULL, 'Two hundred pounds, give or take a few Dwight insisted on eating.', 41.584494, -75.271005, NULL, 15, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-07-05 21:59:00+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-15 06:35:28+00'),
  ('eeff2a51-062b-46c3-9592-1f315afbf6d9', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Test the sugar content of this year''s beet crop', 'ed5373e3-7df6-4787-8fec-dbccf16d7d2b', 'soon', 'done', NULL, 'Refractometer says 18 brix. Dwight says it tastes like victory.', NULL, NULL, NULL, 30, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-06-21 16:42:59+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-25 12:18:52+00'),
  ('f2d5e658-ee7a-4766-9207-a267728c4714', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Repair the beet harvester''s conveyor belt', 'ed5373e3-7df6-4787-8fec-dbccf16d7d2b', 'soon', 'not_started', '2026-07-18', 'It ate a glove again. The glove was empty. This time.', 41.591091, -75.261507, NULL, 240, NULL, NULL, '2026-05-22 13:01:32+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('bec527a9-86e2-4a5d-a37d-eff55edb3794', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Sort beets by size for the county fair entry', 'ed5373e3-7df6-4787-8fec-dbccf16d7d2b', 'urgent', 'in_progress', NULL, 'Only the top three percent are worthy. The rest go to soup.', NULL, NULL, '25654847-e3eb-43b6-80f3-84c1bcbea603', 30, NULL, NULL, '2026-06-02 20:52:46+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('0f80724f-ca56-46ee-8f22-a031a289a451', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Weed the beet rows before they choke the seedlings', 'ed5373e3-7df6-4787-8fec-dbccf16d7d2b', 'whenever', 'done', NULL, 'Back-breaking. Mose hums the whole time. It helps, somehow.', NULL, NULL, 'c6132f4e-089e-4f95-bf1d-a88d98ff597a', 30, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-06-18 07:54:15+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-26 16:35:50+00'),
  ('455f307e-3ef1-49cf-9ec2-559633619b4d', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Replant the beet seedlings the frost got last week', 'ed5373e3-7df6-4787-8fec-dbccf16d7d2b', 'urgent', 'not_started', '2026-09-10', 'A minor setback. Dwight has already forgiven the frost.', NULL, NULL, 'c6132f4e-089e-4f95-bf1d-a88d98ff597a', 45, NULL, NULL, '2026-05-06 08:08:20+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('945d7fae-d509-4609-89e8-c9a2234d0808', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Negotiate beet pricing with the grocery buyer in Scranton', 'ed5373e3-7df6-4787-8fec-dbccf16d7d2b', 'urgent', 'not_started', NULL, 'Opened at double market rate. Settled for slightly above market rate. A win.', NULL, NULL, NULL, 20, NULL, NULL, '2026-04-22 09:48:59+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('b4ade48b-15e0-4d3b-9167-d1b86089ac58', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Change the linens in the guest rooms before the weekend booking', 'b77093f4-829e-4c34-90fb-f907ef6f00d9', 'whenever', 'not_started', '2026-08-11', 'One guest requested a duvet. Schrute Farms does not do duvets.', NULL, NULL, '0973c219-2cfe-42ac-a524-8e1c7795da3a', 240, NULL, NULL, '2026-04-02 15:33:32+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('71dbba96-8602-405b-9bee-d6a8e143b45a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Deep clean the root cellar guest suite', 'b77093f4-829e-4c34-90fb-f907ef6f00d9', 'soon', 'done', NULL, 'It''s the farm''s most requested room, somehow.', NULL, NULL, '25654847-e3eb-43b6-80f3-84c1bcbea603', 60, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-04-03 19:54:44+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-07 15:15:37+00'),
  ('f897e37b-9b2d-4984-a518-2285a343eaf7', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Restock the outhouse before the weekend guests arrive', 'b77093f4-829e-4c34-90fb-f907ef6f00d9', 'whenever', 'done', NULL, 'Authenticity is the whole selling point. Nobody complains twice.', NULL, NULL, '2566ba1b-9bb1-4243-a1f5-537ae07940a9', 30, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-03-03 08:34:21+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 12:31:57+00'),
  ('9c74230d-924d-4b61-ab60-467264073c9b', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Update the B&B''s online listing photos', 'b77093f4-829e-4c34-90fb-f907ef6f00d9', 'whenever', 'done', NULL, 'The old photo made the goat pen look bigger than the house.', NULL, NULL, NULL, 15, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-05-12 16:10:21+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-29 12:58:18+00'),
  ('3b005460-a27f-44c4-8221-6a3f9d31eb10', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Fix the guest room thermostat that only does two temperatures', 'b77093f4-829e-4c34-90fb-f907ef6f00d9', 'urgent', 'not_started', NULL, 'Sweltering or Siberia. Guests have learned to pack layers.', 41.574454, -75.243744, NULL, 30, NULL, NULL, '2026-03-14 21:35:14+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('229fbf5c-5ac5-4036-8796-9acc203d5486', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Prepare the welcome basket of beets for arriving guests', 'b77093f4-829e-4c34-90fb-f907ef6f00d9', 'whenever', 'done', NULL, 'One guest asked for a fruit basket instead. That guest did not return.', NULL, NULL, '0973c219-2cfe-42ac-a524-8e1c7795da3a', 20, NULL, NULL, '2026-05-16 09:12:08+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 21:12:24+00'),
  ('dcfe2ac5-7519-4c23-8441-4420ce3c1668', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Replace the ''no running water after 9pm'' sign', 'b77093f4-829e-4c34-90fb-f907ef6f00d9', 'urgent', 'not_started', '2026-08-01', 'The old one fell in a well. A different well.', NULL, NULL, NULL, 120, NULL, NULL, '2026-03-29 17:39:07+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('8c5a2118-13b1-408f-a93d-bac9728928b7', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Muck out the guest parking area before check-in', 'b77093f4-829e-4c34-90fb-f907ef6f00d9', 'whenever', 'done', NULL, 'Technically it''s a pasture with a mailbox.', 41.574454, -75.243744, NULL, 45, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-05-13 22:23:14+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-15 06:41:47+00'),
  ('fcf54815-e82c-49ae-9982-818722c7d068', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Inspect the perimeter fence for breaches', '6eead71b-9b15-417c-95af-dc21efc8583b', 'urgent', 'done', '2026-05-09', 'Found a hole. Also found a raccoon using it as a toll booth.', NULL, NULL, '70516c49-27aa-4408-8bbc-12ccff39a516', 45, NULL, 'Mose', '2026-05-05 17:11:19+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-11 14:46:08+00'),
  ('ff5c4f12-a436-4cef-8284-12a677d35046', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Test the motion-sensor alarms along the tree line', '6eead71b-9b15-417c-95af-dc21efc8583b', 'urgent', 'not_started', NULL, 'Triggered four times by the same confused goose.', NULL, NULL, '70516c49-27aa-4408-8bbc-12ccff39a516', 60, NULL, NULL, '2026-03-19 06:40:37+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('c5753255-55dc-40f5-9f3d-a8d538725321', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Sharpen the display katana in the great room', '6eead71b-9b15-417c-95af-dc21efc8583b', 'urgent', 'done', NULL, 'Purely decorative. Mostly decorative. Dwight insists on ''combat ready''.', NULL, NULL, '0973c219-2cfe-42ac-a524-8e1c7795da3a', 240, NULL, 'Mose', '2026-07-01 09:26:22+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-14 20:51:59+00'),
  ('8b35db4e-da98-41ff-b942-a6e255be8687', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Inventory the gun safe and update the log', '6eead71b-9b15-417c-95af-dc21efc8583b', 'whenever', 'done', NULL, 'Everything accounted for. Mose double-checked anyway.', NULL, NULL, '70516c49-27aa-4408-8bbc-12ccff39a516', 30, NULL, 'Mose', '2026-05-09 20:33:25+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 21:01:45+00');

INSERT INTO tasks (id, farm_id, title, category_id, priority, status, due_date, notes, lat, lng, location_id, estimated_minutes, completed_by, completed_by_name, created_at, created_by, completed_at)
VALUES
  ('391a2f94-d078-465e-91db-937ebc233c17', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Replace batteries in the perimeter security cameras', '6eead71b-9b15-417c-95af-dc21efc8583b', 'whenever', 'done', NULL, 'Six cameras. One only points at the compost heap. Unclear why.', NULL, NULL, '70516c49-27aa-4408-8bbc-12ccff39a516', 15, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-04-08 17:14:50+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-10 10:37:08+00'),
  ('2151a3b6-19fe-45d3-9c96-40bcc77f8c0e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Patch the hinge on the bunker''s escape hatch', '6eead71b-9b15-417c-95af-dc21efc8583b', 'urgent', 'in_progress', '2026-11-11', 'Squeaked. Squeaking defeats the purpose of a secret hatch.', NULL, NULL, '70516c49-27aa-4408-8bbc-12ccff39a516', 30, NULL, NULL, '2026-06-17 16:10:42+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('9386f1e3-aa7a-419f-9a15-43a91642a1bc', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Restock the bunker''s canned beet rations', '6eead71b-9b15-417c-95af-dc21efc8583b', 'whenever', 'not_started', NULL, 'Twelve years'' supply, per Dwight''s calculations. Recalculating to fifteen.', 41.580327, -75.263172, NULL, 240, NULL, NULL, '2026-04-02 07:21:29+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('d94b69d2-d7e6-4a52-8cc4-22ca2f368b62', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Run the full property lockdown drill', '6eead71b-9b15-417c-95af-dc21efc8583b', 'whenever', 'done', NULL, 'Forty seconds. A new personal best. Mose is unimpressed.', NULL, NULL, '70516c49-27aa-4408-8bbc-12ccff39a516', 240, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-05-02 20:27:08+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-27 17:33:39+00'),
  ('62c944a3-6d7e-45d5-8e63-35815720aa62', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Patrol the county fairgrounds ahead of the weekend event', '57f6371d-085d-459b-bbfb-933786a8c391', 'whenever', 'done', NULL, 'Volunteer deputy duties. Unpaid. Deeply meaningful, according to Dwight.', NULL, NULL, NULL, 20, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-06-21 13:09:00+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-25 11:11:47+00'),
  ('dbc08262-c84b-4003-a065-2cb18874a68e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Renew the volunteer sheriff''s department paperwork', '57f6371d-085d-459b-bbfb-933786a8c391', 'whenever', 'not_started', NULL, 'Filed six weeks early. Dwight does not believe in deadlines, only in beating them.', NULL, NULL, NULL, 120, NULL, NULL, '2026-05-13 08:24:56+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('affaa6ac-263e-4b32-b175-f9b0ec2fe499', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Wax the department-issued patrol vehicle', '57f6371d-085d-459b-bbfb-933786a8c391', 'whenever', 'done', NULL, 'It''s a golf cart with a siren zip-tied to the roof.', NULL, NULL, '7c0e7905-c9bd-4189-ac34-b03e5f94741e', 60, NULL, 'Mose', '2026-03-29 10:13:37+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-28 12:05:24+00'),
  ('1f801b47-4312-45af-94f1-7e7b4d7f0df7', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Restock the trunk first-aid kit', '57f6371d-085d-459b-bbfb-933786a8c391', 'urgent', 'in_progress', '2026-08-14', 'Added a tourniquet, a beet, and a laminated pep talk.', NULL, NULL, NULL, 30, NULL, NULL, '2026-03-11 13:26:14+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('4ac6a381-e24a-48bf-a3e0-6eb91f042fd0', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Attend the volunteer deputy refresher training', '57f6371d-085d-459b-bbfb-933786a8c391', 'soon', 'not_started', NULL, 'Passed the written portion. The obstacle course portion is disputed.', NULL, NULL, NULL, 60, NULL, NULL, '2026-04-04 16:36:24+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('37733cbe-eb05-4bb4-bfc1-e42dc88a8191', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Replace the cracked badge holder', '57f6371d-085d-459b-bbfb-933786a8c391', 'soon', 'done', NULL, 'The badge itself is fine. It has survived worse.', NULL, NULL, NULL, 90, NULL, NULL, '2026-03-30 16:52:18+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-15 21:57:42+00'),
  ('b17c1238-3f82-4f23-a3ea-3d5f51d75591', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Submit the monthly ride-along report to the county', '57f6371d-085d-459b-bbfb-933786a8c391', 'soon', 'done', '2026-07-22', 'Zero arrests. Several strongly worded warnings.', NULL, NULL, NULL, 45, NULL, 'Mose', '2026-04-16 08:18:52+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-02 14:20:38+00'),
  ('331268e6-2f4a-4214-87a6-4d6f69a66bfb', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Clean and test the department-issued flashlight', '57f6371d-085d-459b-bbfb-933786a8c391', 'whenever', 'in_progress', NULL, 'Works fine. Doubles as a bear deterrent, allegedly.', NULL, NULL, NULL, 30, NULL, NULL, '2026-03-25 12:43:37+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('9997ac19-376a-488a-b415-618093fa6112', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Feed the goats before the morning rounds', '59b12413-8b34-4639-8f8c-cedebd452bd8', 'whenever', 'done', NULL, 'One of them ate a garden hose last week. Recovering nicely.', NULL, NULL, 'ffbc1348-ebdf-472f-a25d-3c27fece7a66', 30, NULL, 'Mose', '2026-05-09 22:30:28+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-21 15:14:27+00'),
  ('e584deca-c1ad-4b7a-a891-1cc277ffd050', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Worm the goat herd on schedule', '59b12413-8b34-4639-8f8c-cedebd452bd8', 'whenever', 'done', '2026-06-23', 'All twelve done in under an hour. New record.', NULL, NULL, 'ffbc1348-ebdf-472f-a25d-3c27fece7a66', 20, NULL, NULL, '2026-06-11 15:13:50+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 18:59:18+00'),
  ('be7eed33-b00a-419e-8609-e33b4e29eb7b', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Clip the geese''s wings before they attack the mailman again', '59b12413-8b34-4639-8f8c-cedebd452bd8', 'whenever', 'in_progress', NULL, 'Third incident this season. The mailman has requested a different route.', NULL, NULL, '27e8ae39-4d92-4f52-9625-3c4cf19f1290', 30, NULL, NULL, '2026-03-05 19:50:26+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('6114ec78-d2d1-48d8-8c95-5cca2bcb39a4', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Collect eggs from the coop before the raccoons find them first', '59b12413-8b34-4639-8f8c-cedebd452bd8', 'soon', 'done', '2026-07-17', 'Fourteen eggs. Two suspicious dents. Investigating.', NULL, NULL, '27e8ae39-4d92-4f52-9625-3c4cf19f1290', 180, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-07-05 07:39:39+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 16:16:59+00'),
  ('bad9bdb4-9030-4bd2-9c1c-a5b8c9a07034', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Repair the chicken coop door latch', '59b12413-8b34-4639-8f8c-cedebd452bd8', 'soon', 'not_started', NULL, 'A fox tried its luck overnight. The latch held. Barely.', NULL, NULL, '27e8ae39-4d92-4f52-9625-3c4cf19f1290', 20, NULL, NULL, '2026-04-11 06:33:37+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('87a5145c-239a-42f5-8569-804a7fcac378', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Move the goat herd to the north pasture for fresh grazing', '59b12413-8b34-4639-8f8c-cedebd452bd8', 'whenever', 'done', NULL, 'One goat refused. Negotiations are ongoing.', 41.563649, -75.259243, NULL, 15, NULL, 'Mose', '2026-04-01 21:36:43+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-16 14:33:05+00'),
  ('8bea4b46-6969-4f42-a676-262121cd4308', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Treat a goat with a mild limp', '59b12413-8b34-4639-8f8c-cedebd452bd8', 'whenever', 'done', NULL, 'Nothing serious. Mose diagnosed it before the vet even called back.', NULL, NULL, 'ffbc1348-ebdf-472f-a25d-3c27fece7a66', 90, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-07-02 14:18:39+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 07:01:31+00'),
  ('289c9d13-6f47-4d7c-bd3c-11624df31073', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Order more chicken feed before the coop runs dry', '59b12413-8b34-4639-8f8c-cedebd452bd8', 'whenever', 'in_progress', '2026-08-23', 'Bulk order. Chickens do not negotiate on quantity.', NULL, NULL, NULL, 180, NULL, NULL, '2026-06-22 18:50:16+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL);

INSERT INTO tasks (id, farm_id, title, category_id, priority, status, due_date, notes, lat, lng, location_id, estimated_minutes, completed_by, completed_by_name, created_at, created_by, completed_at)
VALUES
  ('a1648893-0b28-40c6-8eca-e7386ceb211c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Plow the north field before the ground freezes', '3161f1b6-ca0b-40de-b203-ed43a988a431', 'soon', 'done', NULL, 'Full day on the tractor. Dwight sang the entire time. Unclear what song.', NULL, NULL, NULL, 120, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-04-28 12:58:41+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-13 13:53:23+00'),
  ('44b1630e-de80-40be-80cc-a375253aedfd', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Till the fallow field ahead of next season''s planting', '3161f1b6-ca0b-40de-b203-ed43a988a431', 'whenever', 'done', '2026-03-25', 'Soil''s in good shape. Mose says it ''smells right'', which is apparently a real metric.', NULL, NULL, NULL, 60, NULL, 'Mose', '2026-03-13 16:55:54+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-21 22:52:28+00'),
  ('c0c98bf7-0c27-44a7-9b95-4f4891c8e43e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Repair the irrigation line by the wheat field', '3161f1b6-ca0b-40de-b203-ed43a988a431', 'soon', 'not_started', '2026-07-31', 'A leak the size of a quarter. Fixed with the size of a dinner plate''s worth of tape.', NULL, NULL, NULL, 30, NULL, NULL, '2026-03-07 13:08:53+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('10e9ad27-d6c9-484c-88e8-333ab2787359', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Spread lime on the acidic patch near the tree line', '3161f1b6-ca0b-40de-b203-ed43a988a431', 'whenever', 'done', NULL, 'pH was off. It is now aggressively neutral.', NULL, NULL, NULL, 120, NULL, 'Mose', '2026-07-13 07:14:05+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-14 08:53:26+00'),
  ('84000432-2af4-41f0-8a98-987dde96ec94', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Mow the fence line before it swallows the fence entirely', '3161f1b6-ca0b-40de-b203-ed43a988a431', 'soon', 'done', NULL, 'Overdue by a month. The fence had genuinely disappeared.', NULL, NULL, NULL, 30, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-04-20 20:28:20+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-24 19:56:10+00'),
  ('f644e91e-788f-47b5-bfc1-193bc7dfcc13', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Clear fallen branches from the tree line after the storm', '3161f1b6-ca0b-40de-b203-ed43a988a431', 'whenever', 'not_started', '2026-11-25', 'One branch nearly took out the mailbox. The geese were thrilled.', NULL, NULL, NULL, 180, NULL, NULL, '2026-03-26 14:27:28+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('5daae9be-abbb-473e-8e1e-06342c531257', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Till under the cover crop before spring planting', '3161f1b6-ca0b-40de-b203-ed43a988a431', 'whenever', 'not_started', NULL, 'Rye and clover, mixed in clean. Soil''s better for it.', NULL, NULL, NULL, 120, NULL, NULL, '2026-06-01 15:15:36+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('05857c60-5db1-4705-8f72-91646a0f8166', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Run the annual (unannounced) farm-wide fire drill', '77982b80-16a6-4d7f-93c7-b6744c1f3af3', 'whenever', 'done', NULL, 'Nobody was told. Nobody is ever told. That''s the point, Dwight says.', NULL, NULL, NULL, 20, NULL, 'Mose', '2026-05-10 06:16:16+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 10:03:15+00'),
  ('b966c270-6640-49dc-b09d-d40df1520f4d', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Inspect the fire extinguishers in the barn', '77982b80-16a6-4d7f-93c7-b6744c1f3af3', 'soon', 'not_started', NULL, 'All charged. All within date. A rare, fully compliant afternoon.', NULL, NULL, '7c0e7905-c9bd-4189-ac34-b03e5f94741e', 60, NULL, NULL, '2026-04-27 15:11:24+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('6f281ad7-27ef-4959-b3b9-649547aa6660', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Replace the smoke detector batteries across the property', '77982b80-16a6-4d7f-93c7-b6744c1f3af3', 'whenever', 'not_started', NULL, 'Fourteen detectors. Dwight insists this is not excessive.', NULL, NULL, '0973c219-2cfe-42ac-a524-8e1c7795da3a', 15, NULL, NULL, '2026-06-26 08:26:11+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('6d225de2-4174-496d-96fb-c555ed141352', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Clear brush from around the propane tank', '77982b80-16a6-4d7f-93c7-b6744c1f3af3', 'urgent', 'not_started', NULL, 'A whole season''s growth. It had become load-bearing.', NULL, NULL, NULL, 45, NULL, NULL, '2026-04-22 21:51:04+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('d02f89e3-03c3-49b8-ad14-1f9a7cb35b6b', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Test the bunker''s fire suppression system', '77982b80-16a6-4d7f-93c7-b6744c1f3af3', 'soon', 'done', '2026-05-19', 'Worked as designed. Slightly too well. The bunker smells like foam now.', NULL, NULL, '70516c49-27aa-4408-8bbc-12ccff39a516', 45, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-04-04 11:24:36+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 15:26:26+00'),
  ('8fc8bb1e-c026-457f-a46b-496583431a6f', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Restock the burn barrel safety kit', '77982b80-16a6-4d7f-93c7-b6744c1f3af3', 'soon', 'not_started', NULL, 'Gloves, a bucket of sand, and a stern handwritten warning label.', NULL, NULL, NULL, 90, NULL, NULL, '2026-05-30 17:51:36+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('5c58efaf-888c-471e-871a-fc4e3d2fbfc8', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Repair the hose reel by the barn', '77982b80-16a6-4d7f-93c7-b6744c1f3af3', 'whenever', 'in_progress', '2026-07-30', 'The crank had seized. WD-40 and persistence solved it.', NULL, NULL, '7c0e7905-c9bd-4189-ac34-b03e5f94741e', 30, NULL, NULL, '2026-06-17 06:53:20+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('165f87cd-f67e-4cd5-8e00-ac19a374ab7c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Review the fire escape route with Mose', '77982b80-16a6-4d7f-93c7-b6744c1f3af3', 'whenever', 'in_progress', '2026-09-01', 'He already knew it. He drew it from memory, unprompted.', NULL, NULL, NULL, 30, NULL, NULL, '2026-04-01 19:33:27+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('85e8c7a0-e192-4b51-8c87-8731bbaeb183', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Change the oil in the tractor before the next big plow', '45686050-73fd-4e14-9505-dfc1a8d5b833', 'urgent', 'in_progress', '2026-08-28', 'Overdue by a few hundred hours. It forgave us.', NULL, NULL, NULL, 30, NULL, NULL, '2026-03-02 09:54:08+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('b232b35e-cfb2-49a7-9866-c7bb839b413c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Sharpen the plow blades before the fall till', '45686050-73fd-4e14-9505-dfc1a8d5b833', 'whenever', 'done', NULL, 'Took the edge back to factory sharp, more or less.', NULL, NULL, '7c0e7905-c9bd-4189-ac34-b03e5f94741e', 30, NULL, 'Mose', '2026-06-23 10:16:17+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 22:41:08+00'),
  ('9eb37833-f93f-4cc7-8c30-1bcfe9e61c99', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Fix the flat tire on the flatbed trailer', '45686050-73fd-4e14-9505-dfc1a8d5b833', 'soon', 'not_started', '2026-10-16', 'A nail from the fence-repair pile. Ironic, given the fence.', NULL, NULL, '7c0e7905-c9bd-4189-ac34-b03e5f94741e', 180, NULL, NULL, '2026-03-25 06:36:33+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('d6ae4465-c102-4c42-b0fe-3dda82c0afd3', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Service the wood chipper before hedge-clearing season', '45686050-73fd-4e14-9505-dfc1a8d5b833', 'soon', 'in_progress', NULL, 'Blades sharpened, belt tightened. Ready to eat branches responsibly.', NULL, NULL, NULL, 30, NULL, NULL, '2026-07-05 13:30:20+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('cb81f8b6-fe00-471f-b2e4-93da0c5548b8', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Replace the tractor''s dead headlight', '45686050-73fd-4e14-9505-dfc1a8d5b833', 'soon', 'in_progress', NULL, 'Field work after dark is not recommended. Now it''s possible again.', 41.591091, -75.261507, NULL, 30, NULL, NULL, '2026-05-01 14:57:39+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL);

INSERT INTO tasks (id, farm_id, title, category_id, priority, status, due_date, notes, lat, lng, location_id, estimated_minutes, completed_by, completed_by_name, created_at, created_by, completed_at)
VALUES
  ('1403f8b9-2ddc-40d1-a7a7-dfc51831fc80', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Grease the thresher''s bearings before harvest week', '45686050-73fd-4e14-9505-dfc1a8d5b833', 'urgent', 'done', NULL, 'Squeaked like a haunted house prop. Now silent.', NULL, NULL, NULL, 30, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-05-10 09:57:07+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-28 12:18:24+00'),
  ('a4296a13-b1ea-432f-9739-d45011006dcb', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Repair the fence-post driver''s cracked handle', '45686050-73fd-4e14-9505-dfc1a8d5b833', 'whenever', 'not_started', '2026-09-29', 'Duct tape and a length of pipe. Structurally questionable. Working fine.', 41.591091, -75.261507, NULL, 60, NULL, NULL, '2026-04-02 12:27:49+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('7db5f9d9-9177-4019-b0ff-ac09a710cf5c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Tune up the chainsaw before hedge-laying season', '45686050-73fd-4e14-9505-dfc1a8d5b833', 'urgent', 'in_progress', NULL, 'New chain, fresh mix. Ready for the blackthorn.', NULL, NULL, '7c0e7905-c9bd-4189-ac34-b03e5f94741e', 30, NULL, NULL, '2026-04-05 11:41:09+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('a6269100-8118-4b6a-b398-4289f9b4bada', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'File the farm''s annual tax paperwork', 'd0c3ab3a-cc0b-45fb-a309-0bd1d83de563', 'soon', 'in_progress', '2026-07-13', 'Filed early. Dwight reviewed it three times for typos that weren''t there.', NULL, NULL, NULL, 240, NULL, NULL, '2026-07-09 15:09:04+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('bb9cd5be-3e30-4775-88bc-17605fdcfbb0', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Renew the B&B''s county health inspection certificate', 'd0c3ab3a-cc0b-45fb-a309-0bd1d83de563', 'whenever', 'in_progress', '2026-10-26', 'Passed with one note about the outhouse''s ''rustic charm''.', NULL, NULL, NULL, 45, NULL, NULL, '2026-05-22 11:21:15+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('5d31ff78-d58f-4423-ad0f-dbcb40e6c3de', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Update the liability insurance for the haunted maze', 'd0c3ab3a-cc0b-45fb-a309-0bd1d83de563', 'whenever', 'done', NULL, 'The premium went up. So did the scare factor. Related, probably.', NULL, NULL, NULL, 20, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-05-01 07:52:41+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-16 18:14:13+00'),
  ('f423330a-1db5-4d83-b8de-0faa853c60e7', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Submit the beet crop insurance claim after the hailstorm', 'd0c3ab3a-cc0b-45fb-a309-0bd1d83de563', 'urgent', 'done', NULL, 'Photographic evidence attached. The hail was, in fact, beet-sized.', NULL, NULL, NULL, 60, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-03-13 21:24:12+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-15 07:46:50+00'),
  ('eb1e43f3-9d08-4f53-a0d5-1f35cdb345d0', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'File the volunteer sheriff''s department expense report', 'd0c3ab3a-cc0b-45fb-a309-0bd1d83de563', 'urgent', 'not_started', NULL, 'Mostly gas and one replacement badge holder.', NULL, NULL, NULL, 15, NULL, NULL, '2026-04-29 14:55:28+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('68368f53-75d6-4608-b80b-d2bcc107fc45', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Renew the concealed carry permit before it lapses', 'd0c3ab3a-cc0b-45fb-a309-0bd1d83de563', 'urgent', 'done', NULL, 'Filed with two months to spare, which counts as reckless by Dwight''s standards.', NULL, NULL, NULL, 45, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-05-03 09:57:57+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-03 14:20:28+00'),
  ('fb0d4096-aed4-47d3-97f5-03716529a404', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Organize the farm office filing cabinet', 'd0c3ab3a-cc0b-45fb-a309-0bd1d83de563', 'whenever', 'not_started', NULL, 'Alphabetized, then re-alphabetized by a system only Dwight understands.', 41.574454, -75.243744, NULL, 45, NULL, NULL, '2026-03-18 15:07:46+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('6b6d2609-b65a-4dce-a582-1683360a529a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Rotate the canned goods in the bunker by expiration date', '2ebd1f55-9513-4605-a716-72a9ac3c85f3', 'whenever', 'done', NULL, 'Oldest cans moved to the front. A full afternoon, done with military precision.', 41.580327, -75.263172, NULL, 20, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-03-24 09:10:20+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-19 09:26:32+00'),
  ('5354b2b2-bc30-4b8a-b381-e842d832f035', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Restock the water purification tablets', '2ebd1f55-9513-4605-a716-72a9ac3c85f3', 'soon', 'in_progress', '2026-10-27', 'Enough for a small militia, per usual bunker logic.', NULL, NULL, '70516c49-27aa-4408-8bbc-12ccff39a516', 20, NULL, NULL, '2026-05-28 21:17:41+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('31234b28-8dfe-4a3f-abf0-66b9247193a5', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Inventory the gas masks and replace the filters', '2ebd1f55-9513-4605-a716-72a9ac3c85f3', 'whenever', 'done', NULL, 'All six accounted for. One had a suspicious beet smell.', NULL, NULL, '70516c49-27aa-4408-8bbc-12ccff39a516', 90, NULL, 'Mose', '2026-05-08 16:06:24+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-23 17:31:49+00'),
  ('26809967-59d6-4f11-b89b-19bee1ad7c76', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Test the hand-crank emergency radio', '2ebd1f55-9513-4605-a716-72a9ac3c85f3', 'soon', 'done', NULL, 'Static, then a farm report from a station three counties over. Success.', NULL, NULL, '70516c49-27aa-4408-8bbc-12ccff39a516', 30, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-03-28 14:23:35+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-24 12:08:11+00'),
  ('47449a19-9ddd-4e2a-82e8-79cffde6c47e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Top off the propane reserve tanks', '2ebd1f55-9513-4605-a716-72a9ac3c85f3', 'urgent', 'done', NULL, 'Filled to the recommended level, then filled a bit more, just in case.', NULL, NULL, NULL, 180, NULL, 'Mose', '2026-05-06 10:15:36+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 07:21:35+00'),
  ('6e83d543-5485-42bf-9c98-fc8cded7a7a5', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Restock the emergency beet rations shelf', '2ebd1f55-9513-4605-a716-72a9ac3c85f3', 'soon', 'in_progress', NULL, 'Canned, pickled, and dehydrated. All beet-based. As intended.', NULL, NULL, '70516c49-27aa-4408-8bbc-12ccff39a516', 45, NULL, NULL, '2026-06-02 14:30:59+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('057885bb-865c-4800-9f27-9c3b934be049', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Check expiration dates on the emergency ration kits', '2ebd1f55-9513-4605-a716-72a9ac3c85f3', 'whenever', 'not_started', '2026-10-06', 'Two boxes expired in 2019. Quietly replaced, no questions asked.', NULL, NULL, '70516c49-27aa-4408-8bbc-12ccff39a516', 180, NULL, NULL, '2026-07-07 14:38:32+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('2b0b2176-fe4d-4709-a757-92421b648f99', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Call the regional grocery chain about a beet supply contract', '1b6336f4-28ac-4684-a0b1-b55d65aa1e3e', 'soon', 'done', NULL, 'They wanted a sample box. Sent two, in case one got ''lost in transit''.', NULL, NULL, NULL, 180, NULL, NULL, '2026-06-17 09:43:54+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-23 21:10:04+00'),
  ('7d80d6ca-da1a-4726-918f-cc25e3022bb6', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Follow up with a restaurant lead about sourcing beets locally', '1b6336f4-28ac-4684-a0b1-b55d65aa1e3e', 'soon', 'not_started', NULL, 'Chef wants exclusivity. Dwight is entertaining the idea, slowly.', NULL, NULL, NULL, 45, NULL, NULL, '2026-05-09 15:18:38+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('87be8b9a-0893-4d45-86f6-4891dc03f208', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Negotiate the county fair beet booth pricing', '1b6336f4-28ac-4684-a0b1-b55d65aa1e3e', 'whenever', 'done', NULL, 'Held firm on the corner spot. Won it. The corner spot matters, apparently.', NULL, NULL, NULL, 120, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-06-26 08:00:44+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 19:58:11+00');

INSERT INTO tasks (id, farm_id, title, category_id, priority, status, due_date, notes, lat, lng, location_id, estimated_minutes, completed_by, completed_by_name, created_at, created_by, completed_at)
VALUES
  ('e13f1054-3471-45ad-9776-f01e256571f6', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Draft a wholesale pitch for the honey line', '1b6336f4-28ac-4684-a0b1-b55d65aa1e3e', 'soon', 'in_progress', '2026-07-13', 'First draft included a threat disguised as a closing line. Revised.', NULL, NULL, NULL, 45, NULL, NULL, '2026-07-09 17:01:03+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('fdb8eeac-7605-4d69-b189-a3b156ae10af', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Chase down payment from a beet buyer who''s gone quiet', '1b6336f4-28ac-4684-a0b1-b55d65aa1e3e', 'whenever', 'not_started', NULL, 'Third invoice sent. Politely. Increasingly less politely.', NULL, NULL, NULL, 30, NULL, NULL, '2026-07-10 15:51:54+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('d29de48a-5062-4d5d-85eb-e69e04bdb7bc', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Renew the roadside beet stand''s vendor permit', '1b6336f4-28ac-4684-a0b1-b55d65aa1e3e', 'urgent', 'done', '2026-04-23', 'Approved without incident, which felt suspicious.', NULL, NULL, NULL, 60, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-04-17 08:26:46+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-01 13:30:05+00'),
  ('6c21b4ca-a9a3-42ce-96e0-3efa32bea330', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Print new price tags for the farm stand', '1b6336f4-28ac-4684-a0b1-b55d65aa1e3e', 'urgent', 'done', NULL, 'Beets went up a dime. Honey stayed the same, out of principle.', NULL, NULL, NULL, 180, NULL, NULL, '2026-07-03 14:01:06+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-04 19:34:51+00'),
  ('708cb7ee-b2bd-4caa-ae8b-280d0bdd5291', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Update the farm''s online store listing', '1b6336f4-28ac-4684-a0b1-b55d65aa1e3e', 'urgent', 'not_started', NULL, 'New photos. The goat photobombed three of them. Kept all three.', NULL, NULL, NULL, 20, NULL, NULL, '2026-04-02 15:12:35+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('4a1eeaba-71c6-4f42-bf72-5cfd4ded8142', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Cut this year''s corn maze pattern', 'd8d8eb08-0e03-4684-9f3f-899dcdb9d0de', 'soon', 'done', NULL, 'A beet silhouette, visible only from the air. Ambitious. Slightly lopsided.', NULL, NULL, '38bcb8d0-1f77-4bf6-ab82-ca3338eb1dde', 120, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-06-01 19:34:10+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 18:48:41+00'),
  ('961d19e7-93c8-4406-981d-d4eed693ee00', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Restock fake blood for the haunted house', 'd8d8eb08-0e03-4684-9f3f-899dcdb9d0de', 'soon', 'not_started', NULL, 'Corn syrup and food coloring. The recipe is a closely guarded secret.', NULL, NULL, NULL, 90, NULL, NULL, '2026-05-28 10:14:21+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('fe087dec-dd4c-4fac-a061-4d6b21294695', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Test the haunted house''s animatronic scarecrow', 'd8d8eb08-0e03-4684-9f3f-899dcdb9d0de', 'urgent', 'not_started', '2026-11-19', 'Jump-scared Mose. He did not react. He never reacts.', NULL, NULL, NULL, 90, NULL, NULL, '2026-04-27 17:54:40+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('88ed8fa7-dd81-4843-bcac-d9d110a44be5', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Replace the burnt-out lights along the maze path', 'd8d8eb08-0e03-4684-9f3f-899dcdb9d0de', 'urgent', 'done', NULL, 'Half the maze was pitch black. Now appropriately, deliberately dim.', NULL, NULL, '38bcb8d0-1f77-4bf6-ab82-ca3338eb1dde', 120, NULL, NULL, '2026-05-14 22:06:42+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-21 12:17:05+00'),
  ('81ed676a-53b8-46a6-b549-e1fe9bda2ce1', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Recruit local teens as haunted house actors', 'd8d8eb08-0e03-4684-9f3f-899dcdb9d0de', 'soon', 'done', NULL, 'Pay is in schrute-bucks and pizza. Turnout was surprisingly strong.', NULL, NULL, NULL, 90, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-05-11 18:14:28+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 09:53:04+00'),
  ('ad010faa-716a-4b60-8488-b6bf5542448f', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Build a new jump-scare prop for the barn section', 'd8d8eb08-0e03-4684-9f3f-899dcdb9d0de', 'soon', 'done', NULL, 'A taxidermied fox on a spring-loaded arm. Effective. Possibly too effective.', NULL, NULL, NULL, 90, NULL, 'Mose', '2026-04-23 15:03:47+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 12:58:37+00'),
  ('3608ba23-e27a-423f-8237-339e8f4fd71c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Order more hay bales for the maze walls', 'd8d8eb08-0e03-4684-9f3f-899dcdb9d0de', 'urgent', 'done', NULL, 'Fifty bales. Structural, decorative, and mildly flammable, per the fire log.', NULL, NULL, '38bcb8d0-1f77-4bf6-ab82-ca3338eb1dde', 240, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-06-11 21:30:35+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 07:31:45+00'),
  ('893b2202-d55e-4279-9555-6aa8a2c30c57', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Print tickets for the Halloween haunted house event', 'd8d8eb08-0e03-4684-9f3f-899dcdb9d0de', 'whenever', 'done', NULL, 'Sold out the first weekend within a day. Second weekend added.', NULL, NULL, NULL, 15, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-04-07 16:52:19+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 20:40:23+00'),
  ('a21364ca-e498-492e-b6f0-b0e06f1027de', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Turn the compost pile before it overheats', '8c2a4844-e870-4ab7-b247-5406377d3c03', 'whenever', 'done', '2026-06-22', 'Steam rising off it this morning. A good sign, apparently.', NULL, NULL, NULL, 30, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-05-05 09:45:58+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-29 12:18:25+00'),
  ('b32576d5-d8fa-43ce-8b44-8fceae266e93', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Spread manure on the fallow field before planting', '8c2a4844-e870-4ab7-b247-5406377d3c03', 'whenever', 'in_progress', NULL, 'A full morning''s work. The smell followed everyone home.', NULL, NULL, 'c6132f4e-089e-4f95-bf1d-a88d98ff597a', 15, NULL, NULL, '2026-04-10 16:17:08+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('50ba9271-2a7b-4ae8-a1c2-9dc490aec656', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Repair the manure spreader''s clogged chute', '8c2a4844-e870-4ab7-b247-5406377d3c03', 'whenever', 'done', NULL, 'Cleared by hand. A task nobody volunteers for twice.', NULL, NULL, '7c0e7905-c9bd-4189-ac34-b03e5f94741e', 20, 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL, '2026-04-03 16:06:04+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-15 19:38:34+00'),
  ('6af68202-7a92-4b44-9173-aca475f963be', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Clean out the goat pen bedding', '8c2a4844-e870-4ab7-b247-5406377d3c03', 'whenever', 'done', '2026-06-09', 'Fresh straw down. The goats inspected it and approved.', 41.563649, -75.259243, NULL, 60, NULL, 'Mose', '2026-05-24 21:59:45+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-16 21:05:47+00'),
  ('b83d06c8-3100-4c92-8237-471fcc866328', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Haul away the aged compost for sale to neighbors', '8c2a4844-e870-4ab7-b247-5406377d3c03', 'urgent', 'not_started', NULL, 'Sold three trailer-loads. Compost is, unexpectedly, a solid revenue line.', NULL, NULL, NULL, 15, NULL, NULL, '2026-03-31 17:35:07+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('21a8aba3-463f-429e-be5c-47274e4f1541', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Test the compost pile''s nitrogen levels', '8c2a4844-e870-4ab7-b247-5406377d3c03', 'whenever', 'done', '2026-03-08', 'Right in range. Mose predicted it within a percentage point.', NULL, NULL, NULL, 20, NULL, 'Mose', '2026-03-01 06:59:14+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-09 12:25:12+00'),
  ('467061a7-f6db-4232-9882-fbd8a2d1c92d', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'Muck out the barn stalls', '8c2a4844-e870-4ab7-b247-5406377d3c03', 'soon', 'in_progress', NULL, 'Weekly chore. Never gets easier. Always gets done.', NULL, NULL, NULL, 90, NULL, NULL, '2026-07-07 12:34:47+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL);

-- ---------------------------------------------------------------------------
-- Task tags
-- ---------------------------------------------------------------------------

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('e2b08f3c-4a3e-470c-92a2-731f48a98b9f', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('e2b08f3c-4a3e-470c-92a2-731f48a98b9f', 'cb085931-121b-4c76-bfb9-9ff78b6d5d30'),
  ('a4f5452c-ea94-4eda-a157-2589c0bb5809', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('a4f5452c-ea94-4eda-a157-2589c0bb5809', '02317cab-7ee7-4cda-b3fb-413d13dd7b18'),
  ('eeff2a51-062b-46c3-9592-1f315afbf6d9', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('f2d5e658-ee7a-4766-9207-a267728c4714', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('f2d5e658-ee7a-4766-9207-a267728c4714', '02317cab-7ee7-4cda-b3fb-413d13dd7b18'),
  ('bec527a9-86e2-4a5d-a37d-eff55edb3794', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('0f80724f-ca56-46ee-8f22-a031a289a451', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('0f80724f-ca56-46ee-8f22-a031a289a451', 'cb085931-121b-4c76-bfb9-9ff78b6d5d30'),
  ('455f307e-3ef1-49cf-9ec2-559633619b4d', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('945d7fae-d509-4609-89e8-c9a2234d0808', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('b4ade48b-15e0-4d3b-9167-d1b86089ac58', 'a828f87e-79df-4009-8356-1e840263dc65'),
  ('b4ade48b-15e0-4d3b-9167-d1b86089ac58', '3577aa58-5805-4fba-96b5-2114d43a54cc'),
  ('71dbba96-8602-405b-9bee-d6a8e143b45a', 'a828f87e-79df-4009-8356-1e840263dc65'),
  ('71dbba96-8602-405b-9bee-d6a8e143b45a', 'db188e28-ffed-4ca4-b3bc-d73564178b30'),
  ('f897e37b-9b2d-4984-a518-2285a343eaf7', 'a828f87e-79df-4009-8356-1e840263dc65'),
  ('f897e37b-9b2d-4984-a518-2285a343eaf7', 'd4f61126-db88-41a7-b611-a6ffdcd385d1'),
  ('9c74230d-924d-4b61-ab60-467264073c9b', 'a828f87e-79df-4009-8356-1e840263dc65'),
  ('3b005460-a27f-44c4-8221-6a3f9d31eb10', 'a828f87e-79df-4009-8356-1e840263dc65'),
  ('3b005460-a27f-44c4-8221-6a3f9d31eb10', 'a5285487-d92a-4d18-8a22-e35468cfd627'),
  ('229fbf5c-5ac5-4036-8796-9acc203d5486', 'a828f87e-79df-4009-8356-1e840263dc65'),
  ('229fbf5c-5ac5-4036-8796-9acc203d5486', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('dcfe2ac5-7519-4c23-8441-4420ce3c1668', 'a828f87e-79df-4009-8356-1e840263dc65'),
  ('dcfe2ac5-7519-4c23-8441-4420ce3c1668', '1d8de7bd-92b5-420c-b21a-5e2c63d3aa95');

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('8c5a2118-13b1-408f-a93d-bac9728928b7', 'a828f87e-79df-4009-8356-1e840263dc65'),
  ('fcf54815-e82c-49ae-9982-818722c7d068', '0891c72e-82ca-48fa-b1b4-9f26311febf5'),
  ('fcf54815-e82c-49ae-9982-818722c7d068', 'a7f04cb5-9035-49ff-9b92-4b69157cfaa1'),
  ('ff5c4f12-a436-4cef-8284-12a677d35046', '0891c72e-82ca-48fa-b1b4-9f26311febf5'),
  ('ff5c4f12-a436-4cef-8284-12a677d35046', '16af03c2-6c34-49d1-aa2d-3f57c01f6dd9'),
  ('c5753255-55dc-40f5-9f3d-a8d538725321', '0b3f238f-c45d-4d59-8354-c4082127602e'),
  ('8b35db4e-da98-41ff-b942-a6e255be8687', 'd782a503-421b-45d9-92e9-1cb680ea8ee6'),
  ('8b35db4e-da98-41ff-b942-a6e255be8687', 'cb085931-121b-4c76-bfb9-9ff78b6d5d30'),
  ('391a2f94-d078-465e-91db-937ebc233c17', '0891c72e-82ca-48fa-b1b4-9f26311febf5'),
  ('2151a3b6-19fe-45d3-9c96-40bcc77f8c0e', 'a7f04cb5-9035-49ff-9b92-4b69157cfaa1'),
  ('9386f1e3-aa7a-419f-9a15-43a91642a1bc', 'a7f04cb5-9035-49ff-9b92-4b69157cfaa1'),
  ('9386f1e3-aa7a-419f-9a15-43a91642a1bc', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('9386f1e3-aa7a-419f-9a15-43a91642a1bc', 'a3dadde6-00c9-4893-868c-dbbf2ac02f72'),
  ('d94b69d2-d7e6-4a52-8cc4-22ca2f368b62', 'a7f04cb5-9035-49ff-9b92-4b69157cfaa1'),
  ('d94b69d2-d7e6-4a52-8cc4-22ca2f368b62', '7a8513d6-3e59-4b60-a184-f585648f6401'),
  ('62c944a3-6d7e-45d5-8e63-35815720aa62', '19683371-bf72-495b-964e-dccb89991aa0'),
  ('dbc08262-c84b-4003-a065-2cb18874a68e', '19683371-bf72-495b-964e-dccb89991aa0'),
  ('affaa6ac-263e-4b32-b175-f9b0ec2fe499', '19683371-bf72-495b-964e-dccb89991aa0'),
  ('1f801b47-4312-45af-94f1-7e7b4d7f0df7', '19683371-bf72-495b-964e-dccb89991aa0'),
  ('4ac6a381-e24a-48bf-a3e0-6eb91f042fd0', '19683371-bf72-495b-964e-dccb89991aa0'),
  ('37733cbe-eb05-4bb4-bfc1-e42dc88a8191', '19683371-bf72-495b-964e-dccb89991aa0'),
  ('b17c1238-3f82-4f23-a3ea-3d5f51d75591', '19683371-bf72-495b-964e-dccb89991aa0'),
  ('b17c1238-3f82-4f23-a3ea-3d5f51d75591', '6f92eeea-1a2e-4186-b085-eb12ae94b5e1'),
  ('331268e6-2f4a-4214-87a6-4d6f69a66bfb', '19683371-bf72-495b-964e-dccb89991aa0'),
  ('9997ac19-376a-488a-b415-618093fa6112', 'dde34e2e-373c-4d27-a37e-b7c3002d9023');

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('e584deca-c1ad-4b7a-a891-1cc277ffd050', 'dde34e2e-373c-4d27-a37e-b7c3002d9023'),
  ('be7eed33-b00a-419e-8609-e33b4e29eb7b', '16af03c2-6c34-49d1-aa2d-3f57c01f6dd9'),
  ('6114ec78-d2d1-48d8-8c95-5cca2bcb39a4', 'ae7b285d-fc15-44c7-a7ab-898eef004d23'),
  ('bad9bdb4-9030-4bd2-9c1c-a5b8c9a07034', 'ae7b285d-fc15-44c7-a7ab-898eef004d23'),
  ('87a5145c-239a-42f5-8569-804a7fcac378', 'dde34e2e-373c-4d27-a37e-b7c3002d9023'),
  ('8bea4b46-6969-4f42-a676-262121cd4308', 'dde34e2e-373c-4d27-a37e-b7c3002d9023'),
  ('8bea4b46-6969-4f42-a676-262121cd4308', 'cb085931-121b-4c76-bfb9-9ff78b6d5d30'),
  ('289c9d13-6f47-4d7c-bd3c-11624df31073', 'ae7b285d-fc15-44c7-a7ab-898eef004d23'),
  ('a1648893-0b28-40c6-8eca-e7386ceb211c', '02317cab-7ee7-4cda-b3fb-413d13dd7b18'),
  ('a1648893-0b28-40c6-8eca-e7386ceb211c', 'd7cb5998-c105-4260-8cb2-12b98748add6'),
  ('44b1630e-de80-40be-80cc-a375253aedfd', 'd7cb5998-c105-4260-8cb2-12b98748add6'),
  ('44b1630e-de80-40be-80cc-a375253aedfd', 'cb085931-121b-4c76-bfb9-9ff78b6d5d30'),
  ('c0c98bf7-0c27-44a7-9b95-4f4891c8e43e', 'c75f19fc-9d6f-431d-ae44-147923fa5f98'),
  ('10e9ad27-d6c9-484c-88e8-333ab2787359', '23cbc677-9974-4893-93c5-026053ef1b82'),
  ('f644e91e-788f-47b5-bfc1-193bc7dfcc13', '16af03c2-6c34-49d1-aa2d-3f57c01f6dd9'),
  ('5daae9be-abbb-473e-8e1e-06342c531257', 'd7cb5998-c105-4260-8cb2-12b98748add6'),
  ('05857c60-5db1-4705-8f72-91646a0f8166', '7a8513d6-3e59-4b60-a184-f585648f6401'),
  ('b966c270-6640-49dc-b09d-d40df1520f4d', '7a8513d6-3e59-4b60-a184-f585648f6401'),
  ('6f281ad7-27ef-4959-b3b9-649547aa6660', '7a8513d6-3e59-4b60-a184-f585648f6401'),
  ('6d225de2-4174-496d-96fb-c555ed141352', '7a8513d6-3e59-4b60-a184-f585648f6401'),
  ('d02f89e3-03c3-49b8-ad14-1f9a7cb35b6b', '7a8513d6-3e59-4b60-a184-f585648f6401'),
  ('d02f89e3-03c3-49b8-ad14-1f9a7cb35b6b', 'a7f04cb5-9035-49ff-9b92-4b69157cfaa1'),
  ('8fc8bb1e-c026-457f-a46b-496583431a6f', '7a8513d6-3e59-4b60-a184-f585648f6401'),
  ('5c58efaf-888c-471e-871a-fc4e3d2fbfc8', '7a8513d6-3e59-4b60-a184-f585648f6401'),
  ('165f87cd-f67e-4cd5-8e00-ac19a374ab7c', '7a8513d6-3e59-4b60-a184-f585648f6401');

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('165f87cd-f67e-4cd5-8e00-ac19a374ab7c', 'cb085931-121b-4c76-bfb9-9ff78b6d5d30'),
  ('85e8c7a0-e192-4b51-8c87-8731bbaeb183', '02317cab-7ee7-4cda-b3fb-413d13dd7b18'),
  ('b232b35e-cfb2-49a7-9866-c7bb839b413c', 'd7cb5998-c105-4260-8cb2-12b98748add6'),
  ('cb81f8b6-fe00-471f-b2e4-93da0c5548b8', '02317cab-7ee7-4cda-b3fb-413d13dd7b18'),
  ('1403f8b9-2ddc-40d1-a7a7-dfc51831fc80', 'e3b4dc3f-49c2-47d0-972d-09a9c9eb5dbb'),
  ('bb9cd5be-3e30-4775-88bc-17605fdcfbb0', 'a828f87e-79df-4009-8356-1e840263dc65'),
  ('5d31ff78-d58f-4423-ad0f-dbcb40e6c3de', 'e3b4dc3f-49c2-47d0-972d-09a9c9eb5dbb'),
  ('f423330a-1db5-4d83-b8de-0faa853c60e7', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('eb1e43f3-9d08-4f53-a0d5-1f35cdb345d0', '19683371-bf72-495b-964e-dccb89991aa0'),
  ('68368f53-75d6-4608-b80b-d2bcc107fc45', 'd782a503-421b-45d9-92e9-1cb680ea8ee6'),
  ('6b6d2609-b65a-4dce-a582-1683360a529a', 'a7f04cb5-9035-49ff-9b92-4b69157cfaa1'),
  ('6b6d2609-b65a-4dce-a582-1683360a529a', 'a3dadde6-00c9-4893-868c-dbbf2ac02f72'),
  ('5354b2b2-bc30-4b8a-b381-e842d832f035', 'a7f04cb5-9035-49ff-9b92-4b69157cfaa1'),
  ('5354b2b2-bc30-4b8a-b381-e842d832f035', '1d8de7bd-92b5-420c-b21a-5e2c63d3aa95'),
  ('31234b28-8dfe-4a3f-abf0-66b9247193a5', 'a7f04cb5-9035-49ff-9b92-4b69157cfaa1'),
  ('31234b28-8dfe-4a3f-abf0-66b9247193a5', 'd782a503-421b-45d9-92e9-1cb680ea8ee6'),
  ('26809967-59d6-4f11-b89b-19bee1ad7c76', 'a7f04cb5-9035-49ff-9b92-4b69157cfaa1'),
  ('47449a19-9ddd-4e2a-82e8-79cffde6c47e', 'a7f04cb5-9035-49ff-9b92-4b69157cfaa1'),
  ('6e83d543-5485-42bf-9c98-fc8cded7a7a5', 'a7f04cb5-9035-49ff-9b92-4b69157cfaa1'),
  ('6e83d543-5485-42bf-9c98-fc8cded7a7a5', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('057885bb-865c-4800-9f27-9c3b934be049', 'a7f04cb5-9035-49ff-9b92-4b69157cfaa1'),
  ('057885bb-865c-4800-9f27-9c3b934be049', 'a3dadde6-00c9-4893-868c-dbbf2ac02f72'),
  ('2b0b2176-fe4d-4709-a757-92421b648f99', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('7d80d6ca-da1a-4726-918f-cc25e3022bb6', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('87be8b9a-0893-4d45-86f6-4891dc03f208', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82');

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('e13f1054-3471-45ad-9776-f01e256571f6', 'f18ee02e-c875-4e55-a514-99a4e2857b04'),
  ('fdb8eeac-7605-4d69-b189-a3b156ae10af', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('d29de48a-5062-4d5d-85eb-e69e04bdb7bc', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('6c21b4ca-a9a3-42ce-96e0-3efa32bea330', '4d9fb0e1-ac4e-45d3-a12e-ce477e9c5b82'),
  ('6c21b4ca-a9a3-42ce-96e0-3efa32bea330', 'f18ee02e-c875-4e55-a514-99a4e2857b04'),
  ('708cb7ee-b2bd-4caa-ae8b-280d0bdd5291', 'dde34e2e-373c-4d27-a37e-b7c3002d9023'),
  ('4a1eeaba-71c6-4f42-bf72-5cfd4ded8142', 'a8a75c48-7665-49cf-840f-5301569ae362'),
  ('4a1eeaba-71c6-4f42-bf72-5cfd4ded8142', 'e3b4dc3f-49c2-47d0-972d-09a9c9eb5dbb'),
  ('961d19e7-93c8-4406-981d-d4eed693ee00', 'e3b4dc3f-49c2-47d0-972d-09a9c9eb5dbb'),
  ('fe087dec-dd4c-4fac-a061-4d6b21294695', 'e3b4dc3f-49c2-47d0-972d-09a9c9eb5dbb'),
  ('fe087dec-dd4c-4fac-a061-4d6b21294695', 'cb085931-121b-4c76-bfb9-9ff78b6d5d30'),
  ('88ed8fa7-dd81-4843-bcac-d9d110a44be5', 'e3b4dc3f-49c2-47d0-972d-09a9c9eb5dbb'),
  ('88ed8fa7-dd81-4843-bcac-d9d110a44be5', 'a8a75c48-7665-49cf-840f-5301569ae362'),
  ('81ed676a-53b8-46a6-b549-e1fe9bda2ce1', 'e3b4dc3f-49c2-47d0-972d-09a9c9eb5dbb'),
  ('81ed676a-53b8-46a6-b549-e1fe9bda2ce1', '5797df59-6178-47b7-94b8-7b320d5cd853'),
  ('ad010faa-716a-4b60-8488-b6bf5542448f', 'e3b4dc3f-49c2-47d0-972d-09a9c9eb5dbb'),
  ('ad010faa-716a-4b60-8488-b6bf5542448f', '43b7f15d-bf21-48c2-b184-014bbdd27130'),
  ('3608ba23-e27a-423f-8237-339e8f4fd71c', 'e3b4dc3f-49c2-47d0-972d-09a9c9eb5dbb'),
  ('3608ba23-e27a-423f-8237-339e8f4fd71c', '7a8513d6-3e59-4b60-a184-f585648f6401'),
  ('893b2202-d55e-4279-9555-6aa8a2c30c57', 'e3b4dc3f-49c2-47d0-972d-09a9c9eb5dbb'),
  ('a21364ca-e498-492e-b6f0-b0e06f1027de', '990d1f4e-613a-44fd-8dbd-7a6e71caf627'),
  ('b32576d5-d8fa-43ce-8b44-8fceae266e93', 'b28acd21-f361-4b14-b87b-561bfd2bca0e'),
  ('50ba9271-2a7b-4ae8-a1c2-9dc490aec656', 'b28acd21-f361-4b14-b87b-561bfd2bca0e'),
  ('6af68202-7a92-4b44-9173-aca475f963be', 'dde34e2e-373c-4d27-a37e-b7c3002d9023'),
  ('6af68202-7a92-4b44-9173-aca475f963be', 'b28acd21-f361-4b14-b87b-561bfd2bca0e');

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('b83d06c8-3100-4c92-8237-471fcc866328', '990d1f4e-613a-44fd-8dbd-7a6e71caf627'),
  ('21a8aba3-463f-429e-be5c-47274e4f1541', '990d1f4e-613a-44fd-8dbd-7a6e71caf627'),
  ('21a8aba3-463f-429e-be5c-47274e4f1541', 'cb085931-121b-4c76-bfb9-9ff78b6d5d30'),
  ('467061a7-f6db-4232-9882-fbd8a2d1c92d', 'b28acd21-f361-4b14-b87b-561bfd2bca0e');

-- ---------------------------------------------------------------------------
-- Task photos
-- ---------------------------------------------------------------------------

INSERT INTO task_photos (id, task_id, storage_path, caption, taken_at)
VALUES
  ('03fea3a6-acbd-4eb5-9f0b-870413f9cf83', '6114ec78-d2d1-48d8-8c95-5cca2bcb39a4', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e/6114ec78-d2d1-48d8-8c95-5cca2bcb39a4/03fea3a6-acbd-4eb5-9f0b-870413f9cf83.webp', 'Before', '2026-07-11 16:16:59.395621+00'),
  ('01299b8e-841a-4ae0-acea-3e640f46c95f', '71dbba96-8602-405b-9bee-d6a8e143b45a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e/71dbba96-8602-405b-9bee-d6a8e143b45a/01299b8e-841a-4ae0-acea-3e640f46c95f.webp', 'For the insurance claim', '2026-05-07 15:15:37.689677+00'),
  ('cc6d7534-9e01-4d91-b3dc-6aac4cca6fcb', '4a1eeaba-71c6-4f42-bf72-5cfd4ded8142', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e/4a1eeaba-71c6-4f42-bf72-5cfd4ded8142/cc6d7534-9e01-4d91-b3dc-6aac4cca6fcb.webp', 'Before', '2026-07-11 18:48:41.392379+00'),
  ('3b876b5b-90c6-4554-84ad-10f871f0acb2', '8bea4b46-6969-4f42-a676-262121cd4308', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e/8bea4b46-6969-4f42-a676-262121cd4308/3b876b5b-90c6-4554-84ad-10f871f0acb2.webp', 'Before', '2026-07-12 07:01:31.645558+00'),
  ('5ed46e29-86e0-4bf1-8cad-4e963177a1e8', '88ed8fa7-dd81-4843-bcac-d9d110a44be5', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e/88ed8fa7-dd81-4843-bcac-d9d110a44be5/5ed46e29-86e0-4bf1-8cad-4e963177a1e8.webp', 'For the insurance claim', '2026-05-21 12:17:05.162543+00');

-- ---------------------------------------------------------------------------
-- Task shopping items
-- ---------------------------------------------------------------------------

INSERT INTO task_shopping_items (id, task_id, name, checked, created_at)
VALUES
  ('19637946-568f-45a6-9169-829599ffe8d9', 'e2b08f3c-4a3e-470c-92a2-731f48a98b9f', 'Canning jars', TRUE, '2026-03-23 18:56:34+00'),
  ('3f0edec6-ffdd-484c-9e90-2675bf538b92', 'e2b08f3c-4a3e-470c-92a2-731f48a98b9f', 'Pickling vinegar', FALSE, '2026-06-25 20:14:31+00'),
  ('a61d31c0-5be8-4bb5-a82e-ccbeec99d854', 'e2b08f3c-4a3e-470c-92a2-731f48a98b9f', 'Fertilizer', FALSE, '2026-04-08 19:28:54+00'),
  ('ab3f56b0-3ab8-42ca-874a-1e0487fa5d7f', 'f2d5e658-ee7a-4766-9207-a267728c4714', 'Pickling vinegar', FALSE, '2026-07-05 06:23:12+00'),
  ('2cefb876-a280-45a5-b343-87cf2a596b7d', 'f2d5e658-ee7a-4766-9207-a267728c4714', 'Beet seed packets', FALSE, '2026-05-31 22:27:03+00'),
  ('337b1f12-9121-41d8-ad9a-58c6e074aba0', '455f307e-3ef1-49cf-9ec2-559633619b4d', 'Fertilizer', TRUE, '2026-06-07 06:31:44+00'),
  ('ff4224ef-fec9-44fa-9976-47cff2e66ce3', '455f307e-3ef1-49cf-9ec2-559633619b4d', 'Canning jars', FALSE, '2026-06-09 17:18:02+00'),
  ('c18c3eaf-a8aa-40cd-9607-e62ab51105b8', '455f307e-3ef1-49cf-9ec2-559633619b4d', 'Beet seed packets', FALSE, '2026-05-14 18:00:07+00'),
  ('cc574efd-72d6-4632-a5a0-2a3c56c43b42', '455f307e-3ef1-49cf-9ec2-559633619b4d', 'Pickling vinegar', TRUE, '2026-07-03 14:10:43+00'),
  ('aca72871-8461-4258-8b77-7fe98be82645', '71dbba96-8602-405b-9bee-d6a8e143b45a', 'Firewood bundles', TRUE, '2026-05-21 10:02:08+00'),
  ('f3cb2fda-ee5f-4030-a449-e0806bf36b82', '71dbba96-8602-405b-9bee-d6a8e143b45a', 'Replacement duvet covers', TRUE, '2026-07-07 17:35:09+00'),
  ('cd2867cd-24ff-4ec4-9727-c6dfb1df9fa5', '71dbba96-8602-405b-9bee-d6a8e143b45a', 'Guest soap bars', FALSE, '2026-05-09 16:19:06+00'),
  ('d7d32716-bd85-41e9-9162-211a222f803b', '71dbba96-8602-405b-9bee-d6a8e143b45a', 'Honey jars', TRUE, '2026-05-01 13:30:05+00'),
  ('a2cb5ef6-ddc1-4f54-a20d-296b0c559bc4', '3b005460-a27f-44c4-8221-6a3f9d31eb10', 'Honey jars', TRUE, '2026-06-11 16:27:47+00'),
  ('358be6a6-3859-4dfa-970f-56675991f2b4', '3b005460-a27f-44c4-8221-6a3f9d31eb10', 'Replacement duvet covers', FALSE, '2026-06-12 07:46:04+00'),
  ('a6c90e46-b3b3-447c-b162-ee031563b2ae', '3b005460-a27f-44c4-8221-6a3f9d31eb10', 'Guest soap bars', FALSE, '2026-06-29 16:26:44+00'),
  ('1d8450c2-2a39-4923-9e6a-d9071b49c858', '8c5a2118-13b1-408f-a93d-bac9728928b7', 'Guest soap bars', TRUE, '2026-06-07 09:12:04+00'),
  ('a0add28e-ea0a-4363-ab43-7876ecd7372e', '8c5a2118-13b1-408f-a93d-bac9728928b7', 'Honey jars', FALSE, '2026-05-21 09:33:10+00'),
  ('14a42fee-ae39-412b-b20b-7da518d8dd17', '8c5a2118-13b1-408f-a93d-bac9728928b7', 'Replacement duvet covers', TRUE, '2026-05-31 13:11:15+00'),
  ('71190585-d22d-4747-8290-e1d12cfa3e74', 'c5753255-55dc-40f5-9f3d-a8d538725321', 'Motion sensor kit', TRUE, '2026-07-08 20:37:24+00'),
  ('3008520e-9326-41a5-af95-3e7328353da9', 'c5753255-55dc-40f5-9f3d-a8d538725321', 'Camera batteries', FALSE, '2026-07-05 12:01:49+00'),
  ('5f88d911-7a98-477d-9443-ae90c445fec7', '2151a3b6-19fe-45d3-9c96-40bcc77f8c0e', 'Camera batteries', TRUE, '2026-06-19 21:23:09+00'),
  ('2ca13a27-b8e3-4642-a984-a7d13445522d', '2151a3b6-19fe-45d3-9c96-40bcc77f8c0e', 'Motion sensor kit', TRUE, '2026-07-08 07:16:08+00'),
  ('1abd6a1a-74ec-4c11-aeb0-e6b034303089', '62c944a3-6d7e-45d5-8e63-35815720aa62', 'Flashlight batteries', FALSE, '2026-07-06 14:30:54+00'),
  ('4f0dfb00-ab9a-41d3-8a7e-78ba22dcbb39', '62c944a3-6d7e-45d5-8e63-35815720aa62', 'Citation pads', TRUE, '2026-06-24 18:44:31+00');

INSERT INTO task_shopping_items (id, task_id, name, checked, created_at)
VALUES
  ('c6a1da92-c375-46d9-971a-679cb741cdc7', '1f801b47-4312-45af-94f1-7e7b4d7f0df7', 'Flashlight batteries', TRUE, '2026-03-14 07:49:54+00'),
  ('5d5ec7a7-6fdd-455e-9b10-def11d93901c', '1f801b47-4312-45af-94f1-7e7b4d7f0df7', 'First-aid supplies', FALSE, '2026-06-08 10:39:28+00'),
  ('d21e2cbc-97ae-4f64-b08e-ca5ea700dc41', '1f801b47-4312-45af-94f1-7e7b4d7f0df7', 'Reflective vest', TRUE, '2026-05-24 07:07:50+00'),
  ('4d02ffc2-c4d6-42e7-8ab1-5d9e030242d8', '1f801b47-4312-45af-94f1-7e7b4d7f0df7', 'Citation pads', FALSE, '2026-03-22 20:52:53+00'),
  ('6cff9904-58c4-4625-b8b4-ba577a5d4b4c', 'b17c1238-3f82-4f23-a3ea-3d5f51d75591', 'Citation pads', TRUE, '2026-06-13 16:05:18+00'),
  ('80722c9c-8b4c-4c80-b6e6-6a500dc74252', 'b17c1238-3f82-4f23-a3ea-3d5f51d75591', 'Flashlight batteries', TRUE, '2026-06-08 07:31:05+00'),
  ('111303c8-6f32-4285-b054-47d2748bcda2', 'e584deca-c1ad-4b7a-a891-1cc277ffd050', 'Poultry netting', TRUE, '2026-06-20 15:07:50+00'),
  ('c53acf1c-1e3f-4f41-90bf-6d2b9e1d178d', 'e584deca-c1ad-4b7a-a891-1cc277ffd050', 'Wormer', FALSE, '2026-07-01 12:44:08+00'),
  ('a059e92e-9d10-474a-8f61-4909463e4865', 'e584deca-c1ad-4b7a-a891-1cc277ffd050', 'Chicken feed', TRUE, '2026-07-04 15:49:48+00'),
  ('d4e7bc66-d718-4a14-82c5-f5c56c7e7483', 'e584deca-c1ad-4b7a-a891-1cc277ffd050', 'Goat feed', FALSE, '2026-06-26 17:29:25+00'),
  ('e00465d2-99ac-45e3-9429-5db68567f2cd', 'bad9bdb4-9030-4bd2-9c1c-a5b8c9a07034', 'Wormer', FALSE, '2026-07-05 17:36:37+00'),
  ('6a4ab610-b60e-4148-a7cc-79adf33d5d16', 'bad9bdb4-9030-4bd2-9c1c-a5b8c9a07034', 'Chicken feed', FALSE, '2026-05-08 18:53:35+00'),
  ('c120d5bd-5ffd-48a2-a98a-0fdee58033d6', 'bad9bdb4-9030-4bd2-9c1c-a5b8c9a07034', 'Poultry netting', TRUE, '2026-06-05 11:48:39+00'),
  ('dfde92a6-6e6b-414a-9e4c-97c3aecafdfb', 'bad9bdb4-9030-4bd2-9c1c-a5b8c9a07034', 'Goat feed', TRUE, '2026-05-21 21:59:10+00'),
  ('f760430e-db63-4277-a789-98c4fd234200', '289c9d13-6f47-4d7c-bd3c-11624df31073', 'Wormer', TRUE, '2026-07-10 22:00:40+00'),
  ('c64e91d5-9ddc-4204-97a9-b9cd63442dfe', '289c9d13-6f47-4d7c-bd3c-11624df31073', 'Poultry netting', FALSE, '2026-06-23 17:09:44+00'),
  ('99cbfc42-c076-40f9-bada-1b8b24df32b7', '289c9d13-6f47-4d7c-bd3c-11624df31073', 'Goat feed', FALSE, '2026-07-06 08:11:23+00'),
  ('5584d463-a30b-4836-88d7-35dd40af63b9', 'c0c98bf7-0c27-44a7-9b95-4f4891c8e43e', 'Fence posts', FALSE, '2026-07-14 12:22:43+00'),
  ('0641e132-9c88-4399-8801-4a8895011f75', 'c0c98bf7-0c27-44a7-9b95-4f4891c8e43e', 'Lime pellets', FALSE, '2026-04-04 11:11:59+00'),
  ('3d1efcfd-50c6-41b3-af57-f49ef206b645', 'c0c98bf7-0c27-44a7-9b95-4f4891c8e43e', 'Irrigation tubing', TRUE, '2026-04-14 18:27:11+00'),
  ('89234dc2-8f52-40c7-8dd9-e481680315b5', 'c0c98bf7-0c27-44a7-9b95-4f4891c8e43e', 'Grass seed', FALSE, '2026-05-16 17:15:06+00'),
  ('7413e43a-e941-453f-803c-87f26d721a23', 'f644e91e-788f-47b5-bfc1-193bc7dfcc13', 'Lime pellets', FALSE, '2026-05-12 06:59:56+00'),
  ('594f3577-eef0-4175-ad4b-0f574e91afba', 'f644e91e-788f-47b5-bfc1-193bc7dfcc13', 'Irrigation tubing', FALSE, '2026-05-05 16:40:43+00'),
  ('f50bf5de-60a4-417b-a449-624183273148', 'b966c270-6640-49dc-b09d-d40df1520f4d', 'Sand bucket', TRUE, '2026-06-10 17:18:43+00'),
  ('aaf54064-a664-4b9d-b1ec-0619f449b3eb', 'b966c270-6640-49dc-b09d-d40df1520f4d', 'Smoke detector batteries', TRUE, '2026-06-07 16:26:29+00');

INSERT INTO task_shopping_items (id, task_id, name, checked, created_at)
VALUES
  ('96682b6f-a497-4e19-bd68-3ce1a255d725', 'd02f89e3-03c3-49b8-ad14-1f9a7cb35b6b', 'Fire blanket', TRUE, '2026-07-07 17:19:27+00'),
  ('e402ed98-54e2-4591-a38a-a7564417ebec', 'd02f89e3-03c3-49b8-ad14-1f9a7cb35b6b', 'Smoke detector batteries', TRUE, '2026-05-02 10:22:03+00'),
  ('7a41035a-2e14-4b2f-8022-e6e001041898', 'd02f89e3-03c3-49b8-ad14-1f9a7cb35b6b', 'Sand bucket', TRUE, '2026-07-09 15:26:54+00'),
  ('36e6feb0-3ffe-48af-9a2c-801248032f4e', 'd02f89e3-03c3-49b8-ad14-1f9a7cb35b6b', 'Fire extinguisher refill', TRUE, '2026-04-04 13:52:55+00'),
  ('0325663a-ad80-4bf1-8325-007810abf519', '165f87cd-f67e-4cd5-8e00-ac19a374ab7c', 'Sand bucket', TRUE, '2026-05-19 12:04:13+00'),
  ('455296d9-9c78-4d4e-a008-d82903ca3dbf', '165f87cd-f67e-4cd5-8e00-ac19a374ab7c', 'Fire extinguisher refill', FALSE, '2026-06-17 17:16:42+00'),
  ('20958336-9cc2-4fff-81f4-e598426fcbc3', '165f87cd-f67e-4cd5-8e00-ac19a374ab7c', 'Fire blanket', FALSE, '2026-05-13 22:52:42+00'),
  ('7e3d97cd-c8fc-4f29-81fe-423b76d8ad94', '9eb37833-f93f-4cc7-8c30-1bcfe9e61c99', 'Tractor headlight bulb', FALSE, '2026-03-30 10:01:19+00'),
  ('ae5e6b4b-bbb1-4788-a68e-aa5361099a23', '9eb37833-f93f-4cc7-8c30-1bcfe9e61c99', 'Engine oil', TRUE, '2026-05-16 18:44:20+00'),
  ('f552f902-eafa-42d7-93e2-f635f45f402a', '9eb37833-f93f-4cc7-8c30-1bcfe9e61c99', 'Spare fuses', FALSE, '2026-06-18 16:32:51+00'),
  ('08498ee1-81ab-403c-804c-398fe13b5ae6', '1403f8b9-2ddc-40d1-a7a7-dfc51831fc80', 'Spare fuses', TRUE, '2026-05-30 19:30:18+00'),
  ('61369f33-a843-4f23-8800-90a4433535f4', '1403f8b9-2ddc-40d1-a7a7-dfc51831fc80', 'Grease cartridges', TRUE, '2026-07-15 13:55:10+00'),
  ('e391ae4c-32c1-4f52-a3f1-f1e61e000ea4', '1403f8b9-2ddc-40d1-a7a7-dfc51831fc80', 'Engine oil', FALSE, '2026-06-15 07:30:21+00'),
  ('5a79d167-965e-48b2-8ed7-db624233fa8c', '1403f8b9-2ddc-40d1-a7a7-dfc51831fc80', 'Tractor headlight bulb', FALSE, '2026-05-10 11:11:11+00'),
  ('5cbd79e2-8cc6-4a8c-80ee-c9c4d1f8ad76', 'a6269100-8118-4b6a-b398-4289f9b4bada', 'Printer ink', TRUE, '2026-07-10 14:33:20+00'),
  ('7e7bb984-59e0-4fdb-9cf4-36ae117f7d83', 'a6269100-8118-4b6a-b398-4289f9b4bada', 'Filing folders', FALSE, '2026-07-15 09:07:15+00'),
  ('54e4ad66-91cb-403a-94e2-d9cddfeed0b9', 'a6269100-8118-4b6a-b398-4289f9b4bada', 'Certified mail envelopes', TRUE, '2026-07-09 09:55:15+00'),
  ('63f6937c-34ef-4760-b965-44cd547c55db', 'f423330a-1db5-4d83-b8de-0faa853c60e7', 'Filing folders', TRUE, '2026-06-30 06:43:17+00'),
  ('d48d5246-f433-461c-8958-98a50dd0987c', 'f423330a-1db5-4d83-b8de-0faa853c60e7', 'Printer ink', TRUE, '2026-04-03 17:06:36+00'),
  ('319e1c79-48de-458b-acab-742c8be0fbd8', 'f423330a-1db5-4d83-b8de-0faa853c60e7', 'Certified mail envelopes', TRUE, '2026-06-12 10:28:50+00'),
  ('3eb4638b-9186-454c-bf2c-b1adce8e5101', 'fb0d4096-aed4-47d3-97f5-03716529a404', 'Certified mail envelopes', FALSE, '2026-05-30 07:19:37+00'),
  ('7bdfc39f-ee4f-4d9f-b9dc-ea44e3c39c60', 'fb0d4096-aed4-47d3-97f5-03716529a404', 'Filing folders', TRUE, '2026-04-24 07:01:36+00'),
  ('0ecb56cb-cb47-46cf-b046-759c195b7b0f', 'fb0d4096-aed4-47d3-97f5-03716529a404', 'Printer ink', FALSE, '2026-06-20 07:27:04+00'),
  ('321d1efd-226b-4c9d-836c-85a73ffaddd2', '31234b28-8dfe-4a3f-abf0-66b9247193a5', 'Gas mask filters', TRUE, '2026-07-08 10:16:45+00'),
  ('aae5f956-8233-459c-9815-f0a59bfcb122', '31234b28-8dfe-4a3f-abf0-66b9247193a5', 'Water purification tablets', TRUE, '2026-06-06 11:39:21+00');

INSERT INTO task_shopping_items (id, task_id, name, checked, created_at)
VALUES
  ('99b55f5c-0701-4bfe-9fcd-d0deed808ee1', '31234b28-8dfe-4a3f-abf0-66b9247193a5', 'AA batteries', TRUE, '2026-06-02 22:14:13+00'),
  ('6e4a64b6-6ebe-4dc1-8427-277b55539aa2', '31234b28-8dfe-4a3f-abf0-66b9247193a5', 'MRE cases', TRUE, '2026-06-09 15:36:35+00'),
  ('4f68bc98-0f1f-47fb-a54f-c60714cbd17a', '6e83d543-5485-42bf-9c98-fc8cded7a7a5', 'AA batteries', TRUE, '2026-06-10 14:12:54+00'),
  ('8cba8e45-d33d-4baa-9e97-4cd93b59d6a2', '6e83d543-5485-42bf-9c98-fc8cded7a7a5', 'Water purification tablets', TRUE, '2026-06-24 10:31:34+00'),
  ('0a071161-8bb1-4ecf-bf6f-bbfba0dcb83b', '7d80d6ca-da1a-4726-918f-cc25e3022bb6', 'Price tag labels', FALSE, '2026-05-13 12:55:21+00'),
  ('f855a6b7-9ac3-4180-8269-4031efd39bdd', '7d80d6ca-da1a-4726-918f-cc25e3022bb6', 'Sample boxes', TRUE, '2026-05-24 15:52:11+00'),
  ('d4a69dc7-ef68-4548-8ed4-62469a44d7e6', '7d80d6ca-da1a-4726-918f-cc25e3022bb6', 'Farm stand signage', FALSE, '2026-05-31 11:52:12+00'),
  ('91dce310-67c9-4c95-8024-930b53924545', 'fdb8eeac-7605-4d69-b189-a3b156ae10af', 'Farm stand signage', FALSE, '2026-07-10 18:48:40+00'),
  ('267cdbaf-8f50-408d-9f64-842d8f88ff26', 'fdb8eeac-7605-4d69-b189-a3b156ae10af', 'Price tag labels', FALSE, '2026-07-11 16:00:32+00'),
  ('e3022180-01a5-4b14-afd9-a9530ae30bbc', '708cb7ee-b2bd-4caa-ae8b-280d0bdd5291', 'Sample boxes', FALSE, '2026-04-06 06:30:33+00'),
  ('d7788391-2d6e-4250-8eca-6c6db95f8935', '708cb7ee-b2bd-4caa-ae8b-280d0bdd5291', 'Farm stand signage', FALSE, '2026-06-22 12:06:11+00'),
  ('8374fcdb-d9dd-43d9-ad01-4cf10261d357', 'fe087dec-dd4c-4fac-a061-4d6b21294695', 'String lights', FALSE, '2026-07-04 11:14:10+00'),
  ('f8f3df3b-9c8f-4f8a-a98a-de2afacd4fa5', 'fe087dec-dd4c-4fac-a061-4d6b21294695', 'Hay bales', TRUE, '2026-05-01 14:27:01+00'),
  ('376b51c7-d9a6-4c17-80b0-83887cabdcd1', 'fe087dec-dd4c-4fac-a061-4d6b21294695', 'Fake blood mix', FALSE, '2026-05-01 12:08:44+00'),
  ('e08e8502-71a1-4370-9e80-a8a7bb758daf', 'fe087dec-dd4c-4fac-a061-4d6b21294695', 'Fog fluid', TRUE, '2026-06-19 09:49:41+00'),
  ('7038070b-fe5e-48ba-98fb-4ffac4705d01', 'ad010faa-716a-4b60-8488-b6bf5542448f', 'Hay bales', TRUE, '2026-05-15 21:52:00+00'),
  ('9b8bcf1f-9110-4651-aa37-838ab8febdd1', 'ad010faa-716a-4b60-8488-b6bf5542448f', 'Fake blood mix', FALSE, '2026-05-12 20:42:57+00'),
  ('1e9e775c-7d2b-4510-9b5f-3bbde1e21c14', 'ad010faa-716a-4b60-8488-b6bf5542448f', 'Fog fluid', FALSE, '2026-06-09 07:08:20+00'),
  ('7cce8646-ad8f-4761-a070-474a6804daea', 'ad010faa-716a-4b60-8488-b6bf5542448f', 'String lights', TRUE, '2026-07-08 18:21:53+00'),
  ('ec62eb40-b22e-472d-b54f-635def0696ea', 'a21364ca-e498-492e-b6f0-b0e06f1027de', 'Sawdust bedding', FALSE, '2026-06-10 20:54:33+00'),
  ('e5b674fd-983c-49d0-9093-f94287e6507d', 'a21364ca-e498-492e-b6f0-b0e06f1027de', 'Compost thermometer', TRUE, '2026-06-10 17:49:23+00'),
  ('ce5cc66b-cbd5-4971-8d60-b78fa1c52f3d', 'a21364ca-e498-492e-b6f0-b0e06f1027de', 'Pitchfork replacement handle', TRUE, '2026-05-09 14:00:07+00'),
  ('5dee2d1b-b72e-444d-8ef8-d3fddfabbf7e', '6af68202-7a92-4b44-9173-aca475f963be', 'Sawdust bedding', TRUE, '2026-06-26 19:42:10+00'),
  ('12e27567-316b-4f34-9d76-a9e7b44f5a31', '6af68202-7a92-4b44-9173-aca475f963be', 'Pitchfork replacement handle', TRUE, '2026-05-25 11:13:41+00'),
  ('2d4af7cb-4578-4274-9280-dd2529c9ebf1', '6af68202-7a92-4b44-9173-aca475f963be', 'Compost thermometer', TRUE, '2026-06-27 10:55:05+00');

INSERT INTO task_shopping_items (id, task_id, name, checked, created_at)
VALUES
  ('7ce957d5-bacb-49d9-bec9-10c86c2643a1', '467061a7-f6db-4232-9882-fbd8a2d1c92d', 'Sawdust bedding', FALSE, '2026-07-10 08:36:00+00'),
  ('a3e673d6-ad68-433a-a44d-3dad9740c451', '467061a7-f6db-4232-9882-fbd8a2d1c92d', 'Compost thermometer', FALSE, '2026-07-12 18:35:27+00'),
  ('dc1b4b5b-b1b0-48cd-95c1-472b20d45a13', '467061a7-f6db-4232-9882-fbd8a2d1c92d', 'Pitchfork replacement handle', TRUE, '2026-07-09 13:52:37+00');

-- ---------------------------------------------------------------------------
-- Task tools
-- ---------------------------------------------------------------------------

INSERT INTO task_tools (id, task_id, name, checked, created_at)
VALUES
  ('77eca4ad-70cf-4940-bbbb-76799ed30d3f', 'a4f5452c-ea94-4eda-a157-2589c0bb5809', 'Hoe', TRUE, '2026-07-11 13:47:34+00'),
  ('7e1d4330-c66f-4274-9c34-03035ff9c764', 'a4f5452c-ea94-4eda-a157-2589c0bb5809', 'Hand trowel', TRUE, '2026-07-12 13:50:49+00'),
  ('3a6db8ed-0f30-4f15-b97a-7965f8b84349', 'bec527a9-86e2-4a5d-a37d-eff55edb3794', 'Harvest crate', FALSE, '2026-06-30 08:05:28+00'),
  ('f1e75edc-6fcd-492a-9de7-fb17aefefbe9', 'bec527a9-86e2-4a5d-a37d-eff55edb3794', 'Hoe', FALSE, '2026-07-01 11:11:57+00'),
  ('5091d50e-7c29-4b2c-9b55-f75fe3a969a3', 'bec527a9-86e2-4a5d-a37d-eff55edb3794', 'Hand trowel', TRUE, '2026-07-13 18:03:40+00'),
  ('6fbefb1b-e723-417e-b8cf-e7771c758262', '945d7fae-d509-4609-89e8-c9a2234d0808', 'Hand trowel', TRUE, '2026-06-14 17:27:54+00'),
  ('05208307-166e-4584-98d9-54c7f4c360b9', '945d7fae-d509-4609-89e8-c9a2234d0808', 'Hoe', FALSE, '2026-07-11 21:55:13+00'),
  ('b2522f8f-9d4a-46ce-89e6-32dab0a13271', '945d7fae-d509-4609-89e8-c9a2234d0808', 'Harvest crate', FALSE, '2026-06-29 16:15:11+00'),
  ('ead61461-3025-427f-9532-28e98c7f6807', 'f897e37b-9b2d-4984-a518-2285a343eaf7', 'Ladder', TRUE, '2026-05-20 19:52:23+00'),
  ('b82a6ab1-2b11-402a-8780-89b858b84e87', 'f897e37b-9b2d-4984-a518-2285a343eaf7', 'Paintbrush set', TRUE, '2026-03-14 08:05:34+00'),
  ('6429fed5-bd30-4bce-b5cd-c78d2e76f1f0', '229fbf5c-5ac5-4036-8796-9acc203d5486', 'Cordless drill', FALSE, '2026-05-30 18:53:35+00'),
  ('18eb8e58-6777-41b1-b2a2-de5b866bc64c', '229fbf5c-5ac5-4036-8796-9acc203d5486', 'Ladder', TRUE, '2026-06-18 16:35:13+00'),
  ('026efc24-29b2-44d0-a43f-aad61090cc59', 'fcf54815-e82c-49ae-9982-818722c7d068', 'Crowbar', TRUE, '2026-07-13 19:02:38+00'),
  ('75796e16-da98-45b4-af01-2c296a939c7c', 'fcf54815-e82c-49ae-9982-818722c7d068', 'Bolt cutters', TRUE, '2026-06-04 09:55:34+00'),
  ('b347a76a-aef6-4758-9ee7-ff6fccd89315', 'fcf54815-e82c-49ae-9982-818722c7d068', 'Wire strainer', TRUE, '2026-05-05 10:50:43+00'),
  ('07ad1e3b-d587-4d11-940e-c6da668856b6', '8b35db4e-da98-41ff-b942-a6e255be8687', 'Crowbar', TRUE, '2026-06-25 17:21:08+00'),
  ('f2fa644a-8823-4d40-a0f6-e724a3673d90', '8b35db4e-da98-41ff-b942-a6e255be8687', 'Bolt cutters', FALSE, '2026-05-13 13:24:07+00'),
  ('9abd9248-f27b-40c1-861c-25157a01aefd', '8b35db4e-da98-41ff-b942-a6e255be8687', 'Wire strainer', TRUE, '2026-06-13 13:14:37+00'),
  ('d5729c49-9446-4b14-a5e4-549252adde52', '9386f1e3-aa7a-419f-9a15-43a91642a1bc', 'Crowbar', FALSE, '2026-04-07 22:21:47+00'),
  ('1b81091f-4b66-4826-ada6-9bda770d9869', '9386f1e3-aa7a-419f-9a15-43a91642a1bc', 'Bolt cutters', FALSE, '2026-05-08 08:43:09+00'),
  ('88c780ff-efc9-44fa-89d7-dee09bd91ebc', '9386f1e3-aa7a-419f-9a15-43a91642a1bc', 'Wire strainer', FALSE, '2026-04-17 14:13:32+00'),
  ('f44c3712-3251-4b0e-a19c-753543c96d83', 'dbc08262-c84b-4003-a065-2cb18874a68e', 'Tire iron', TRUE, '2026-05-13 17:18:28+00'),
  ('d0451061-e8f7-4635-af04-5a11602ac6aa', 'dbc08262-c84b-4003-a065-2cb18874a68e', 'Jump starter', FALSE, '2026-06-11 20:35:51+00'),
  ('59c90a94-a699-46e2-87d9-059fccba6ecb', '4ac6a381-e24a-48bf-a3e0-6eb91f042fd0', 'Jump starter', FALSE, '2026-06-19 18:38:16+00'),
  ('ae875f1d-c40c-4be8-945a-d3fd075c331f', '4ac6a381-e24a-48bf-a3e0-6eb91f042fd0', 'Tire iron', FALSE, '2026-04-18 12:58:38+00');

INSERT INTO task_tools (id, task_id, name, checked, created_at)
VALUES
  ('39986bef-0ff7-4f38-b1e2-9b77ab2be3e8', '331268e6-2f4a-4214-87a6-4d6f69a66bfb', 'Jump starter', FALSE, '2026-05-21 13:41:49+00'),
  ('d4379f3a-cee3-41c9-b5a4-183195bed660', '331268e6-2f4a-4214-87a6-4d6f69a66bfb', 'Tire iron', TRUE, '2026-03-27 08:19:16+00'),
  ('69a5285f-d5b5-462b-baa3-64a40e6e097b', 'be7eed33-b00a-419e-8609-e33b4e29eb7b', 'Hoof trimmers', TRUE, '2026-06-14 19:46:49+00'),
  ('4567e9a4-ca9e-45d8-917d-66dd813ec497', 'be7eed33-b00a-419e-8609-e33b4e29eb7b', 'Drenching gun', FALSE, '2026-04-06 07:14:12+00'),
  ('24894ce0-2e96-4565-8bd4-c503c54550d6', '87a5145c-239a-42f5-8569-804a7fcac378', 'Livestock crate', TRUE, '2026-04-09 08:22:45+00'),
  ('98eece0a-bf76-47df-8e5b-0eac6245fbe9', '87a5145c-239a-42f5-8569-804a7fcac378', 'Drenching gun', FALSE, '2026-04-20 16:56:56+00'),
  ('56b2f61f-0fc4-42f2-b744-94d4416b5d58', 'a1648893-0b28-40c6-8eca-e7386ceb211c', 'Pickaxe', FALSE, '2026-05-04 10:15:45+00'),
  ('bcb2164c-f8d5-4661-9ce9-d2ebac9cd758', 'a1648893-0b28-40c6-8eca-e7386ceb211c', 'Shovel', FALSE, '2026-06-04 06:24:44+00'),
  ('787c1e54-a754-4023-ad37-963a0305d0c0', '10e9ad27-d6c9-484c-88e8-333ab2787359', 'Shovel', TRUE, '2026-07-13 09:40:05+00'),
  ('740c35b4-33a7-4515-8fc1-223c4e1793fa', '10e9ad27-d6c9-484c-88e8-333ab2787359', 'Wheelbarrow', TRUE, '2026-07-13 19:42:23+00'),
  ('581afb39-79dc-4ed1-a290-bbaa407da994', '5daae9be-abbb-473e-8e1e-06342c531257', 'Shovel', TRUE, '2026-06-01 11:47:20+00'),
  ('95d2ff6e-2778-45d6-b9cf-fd930582d762', '5daae9be-abbb-473e-8e1e-06342c531257', 'Post driver', FALSE, '2026-06-01 09:08:37+00'),
  ('a63fdcfc-e615-40d9-bcda-3bac5589c589', '5daae9be-abbb-473e-8e1e-06342c531257', 'Wheelbarrow', FALSE, '2026-07-01 20:35:00+00'),
  ('f70738d9-a034-4133-984e-c0863c1a3bbd', '6f281ad7-27ef-4959-b3b9-649547aa6660', 'Ladder', TRUE, '2026-06-27 06:18:14+00'),
  ('74e1445b-3c9b-43ac-820e-5631f23c9d44', '6f281ad7-27ef-4959-b3b9-649547aa6660', 'Hose reel key', TRUE, '2026-06-27 08:40:30+00'),
  ('e491bab0-2e78-4845-8eed-2e70f80880d6', '6f281ad7-27ef-4959-b3b9-649547aa6660', 'Fire extinguisher', TRUE, '2026-07-01 14:07:24+00'),
  ('7b217ce5-62e6-47cd-93e4-e4f2c90fe190', '8fc8bb1e-c026-457f-a46b-496583431a6f', 'Ladder', FALSE, '2026-06-23 18:42:41+00'),
  ('66263302-3962-42ce-95c0-61206fc6b021', '8fc8bb1e-c026-457f-a46b-496583431a6f', 'Fire extinguisher', FALSE, '2026-07-15 19:16:54+00'),
  ('443803fe-10d3-4cb0-8bd2-c9af238c3b03', '85e8c7a0-e192-4b51-8c87-8731bbaeb183', 'Socket set', FALSE, '2026-03-20 12:33:37+00'),
  ('f8bd109b-f8eb-4639-83cb-de6b80c66c0c', '85e8c7a0-e192-4b51-8c87-8731bbaeb183', 'Grease gun', FALSE, '2026-04-14 21:14:32+00'),
  ('aa4130e1-fd25-4fbf-992d-3a5130ba3a7c', 'd6ae4465-c102-4c42-b0fe-3dda82c0afd3', 'Socket set', FALSE, '2026-07-12 15:33:42+00'),
  ('8bfb3c61-61a1-4352-9d47-59d5d15bb290', 'd6ae4465-c102-4c42-b0fe-3dda82c0afd3', 'Torque wrench', FALSE, '2026-07-15 06:43:00+00'),
  ('74971b36-8165-4b02-bd9d-7f7e98a01376', 'd6ae4465-c102-4c42-b0fe-3dda82c0afd3', 'Grease gun', FALSE, '2026-07-08 20:29:38+00'),
  ('0307ba90-abbd-4c47-a481-c964b85ea69c', 'd6ae4465-c102-4c42-b0fe-3dda82c0afd3', 'Impact driver', FALSE, '2026-07-05 08:33:18+00'),
  ('0ccec25c-ab7d-4eca-b66b-b90161d9f718', 'a4296a13-b1ea-432f-9739-d45011006dcb', 'Grease gun', FALSE, '2026-04-17 11:19:54+00');

INSERT INTO task_tools (id, task_id, name, checked, created_at)
VALUES
  ('aa0aaa8b-1e71-4172-9196-2efdfe8cac80', 'a4296a13-b1ea-432f-9739-d45011006dcb', 'Torque wrench', FALSE, '2026-07-11 21:43:15+00'),
  ('c66d8eda-31f9-47be-8d30-b7bbe318aad1', '4a1eeaba-71c6-4f42-bf72-5cfd4ded8142', 'Extension cord', FALSE, '2026-07-07 17:21:11+00'),
  ('1cf4aba3-32b2-472b-99f3-855d78bc7a26', '4a1eeaba-71c6-4f42-bf72-5cfd4ded8142', 'Utility knife', TRUE, '2026-06-17 12:55:31+00'),
  ('eb8b3a5c-739f-4243-8e89-23ee5ff2e845', '88ed8fa7-dd81-4843-bcac-d9d110a44be5', 'Utility knife', TRUE, '2026-05-22 08:15:47+00'),
  ('251df341-4131-49b4-bfe0-5d1c344689a6', '88ed8fa7-dd81-4843-bcac-d9d110a44be5', 'Extension cord', FALSE, '2026-06-15 07:25:44+00'),
  ('58f5c3f8-0446-44b8-b78d-ccf3449fdf26', '88ed8fa7-dd81-4843-bcac-d9d110a44be5', 'Staple gun', FALSE, '2026-07-09 08:59:45+00'),
  ('1429a932-25f0-41b2-a76e-8bb9e0a031ba', '3608ba23-e27a-423f-8237-339e8f4fd71c', 'Staple gun', TRUE, '2026-06-28 09:49:37+00'),
  ('7d1e41e6-a8e5-480d-8767-5cd700b1469e', '3608ba23-e27a-423f-8237-339e8f4fd71c', 'Extension cord', FALSE, '2026-06-20 14:25:35+00'),
  ('b17b111e-4289-4a28-8973-7a84b9486443', '3608ba23-e27a-423f-8237-339e8f4fd71c', 'Utility knife', FALSE, '2026-06-22 08:54:23+00'),
  ('975bfd0d-5d75-4768-aad0-a3c9fada34bd', 'b32576d5-d8fa-43ce-8b44-8fceae266e93', 'Pitchfork', TRUE, '2026-05-22 22:16:02+00'),
  ('e8bc1eb0-5c8f-4b71-bec2-786b3dfd07b3', 'b32576d5-d8fa-43ce-8b44-8fceae266e93', 'Manure fork', FALSE, '2026-05-03 11:47:25+00'),
  ('87b2f168-21d1-47c1-97af-8b64ebc9135f', 'b32576d5-d8fa-43ce-8b44-8fceae266e93', 'Wheelbarrow', FALSE, '2026-05-30 15:22:57+00'),
  ('edf2fa13-eaa1-4a54-8858-7bda7005e4da', 'b83d06c8-3100-4c92-8237-471fcc866328', 'Wheelbarrow', FALSE, '2026-04-25 22:18:17+00'),
  ('5fd27e22-ef6a-412b-91a6-9aa938c5a839', 'b83d06c8-3100-4c92-8237-471fcc866328', 'Manure fork', TRUE, '2026-04-03 07:52:04+00'),
  ('067ba4fd-0c88-45d9-b583-0e6960c84098', 'b83d06c8-3100-4c92-8237-471fcc866328', 'Pitchfork', TRUE, '2026-06-05 09:48:30+00');

-- ---------------------------------------------------------------------------
-- Task time entries
-- ---------------------------------------------------------------------------

INSERT INTO task_time_entries (id, task_id, user_id, started_at, ended_at, created_at)
VALUES
  ('41014af2-378c-4811-ab63-7a3dda87d37a', 'a4f5452c-ea94-4eda-a157-2589c0bb5809', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-09 14:10:10.660+00', '2026-07-09 14:40:10.660+00', '2026-07-09 14:10:25.660+00'),
  ('d98126fd-03d2-42f7-985b-537b2ebde71c', 'a4f5452c-ea94-4eda-a157-2589c0bb5809', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 13:27:27.491+00', '2026-07-12 13:42:27.491+00', '2026-07-12 13:27:29.491+00'),
  ('27b2b95c-e710-4943-99ff-1fa122d67d75', 'bec527a9-86e2-4a5d-a37d-eff55edb3794', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-07 18:29:11.388+00', '2026-06-07 18:59:11.388+00', '2026-06-07 18:29:12.388+00'),
  ('e2c47701-c1a6-424f-9579-67aa119eb64a', '9c74230d-924d-4b61-ab60-467264073c9b', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-30 04:07:53.688+00', '2026-05-30 05:07:53.688+00', '2026-05-30 04:08:03.688+00'),
  ('dc5f0097-5a3d-4198-a2fe-c9500fe7c6f7', '229fbf5c-5ac5-4036-8796-9acc203d5486', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-06 01:06:36.104+00', '2026-06-06 01:36:36.104+00', '2026-06-06 01:06:39.104+00'),
  ('007b3ea6-5203-475d-81e8-952022786fec', '8c5a2118-13b1-408f-a93d-bac9728928b7', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-14 02:20:18.939+00', '2026-05-14 03:05:18.939+00', '2026-05-14 02:20:27.939+00'),
  ('0d9531fe-626c-44c4-b91c-d92d09768309', 'c5753255-55dc-40f5-9f3d-a8d538725321', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-03 07:34:10.725+00', '2026-07-03 08:04:10.725+00', '2026-07-03 07:34:14.725+00'),
  ('527f81d8-534e-48c2-98e9-1898e754a390', '391a2f94-d078-465e-91db-937ebc233c17', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-30 14:01:13.171+00', '2026-05-30 14:16:13.171+00', '2026-05-30 14:01:15.171+00'),
  ('ebdbdfca-f665-4697-bdd2-a2b5d0a0d562', '2151a3b6-19fe-45d3-9c96-40bcc77f8c0e', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-23 15:41:56.663+00', '2026-06-23 15:56:56.663+00', '2026-06-23 15:42:09.663+00'),
  ('43d723ff-1fee-4bd4-bdb0-ac9fc78eaaa8', 'd94b69d2-d7e6-4a52-8cc4-22ca2f368b62', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-13 21:17:33.435+00', '2026-06-13 22:17:33.435+00', '2026-06-13 21:17:42.435+00'),
  ('779eb48c-d206-4246-bee0-745b23240625', '37733cbe-eb05-4bb4-bfc1-e42dc88a8191', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-03 12:33:53.475+00', '2026-04-03 14:03:53.475+00', '2026-04-03 12:33:59.475+00'),
  ('6d184e45-5266-4cdc-a3ac-f1a02ae43835', '331268e6-2f4a-4214-87a6-4d6f69a66bfb', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-21 14:22:28.753+00', '2026-04-21 14:52:28.753+00', '2026-04-21 14:22:34.753+00'),
  ('15a5db0f-3f78-4b91-8088-38f4f5e0e303', 'e584deca-c1ad-4b7a-a891-1cc277ffd050', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-12 07:46:44.269+00', '2026-06-12 08:06:44.269+00', '2026-06-12 07:46:54.269+00'),
  ('b882b771-2537-4af2-b689-4ec6adfa942b', 'e584deca-c1ad-4b7a-a891-1cc277ffd050', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-14 17:37:19.735+00', '2026-06-14 19:37:19.735+00', '2026-06-14 17:37:32.735+00'),
  ('ea5e92cd-2349-4f40-94b7-63d2c138bb15', 'be7eed33-b00a-419e-8609-e33b4e29eb7b', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-04 23:17:56.923+00', '2026-06-05 00:47:56.923+00', '2026-06-04 23:17:57.923+00'),
  ('1476de5b-f382-438f-9d68-b2c417240060', 'be7eed33-b00a-419e-8609-e33b4e29eb7b', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 10:50:17.428+00', '2026-05-05 11:20:17.428+00', '2026-05-05 10:50:19.428+00'),
  ('bbc290c3-cea1-4ca2-b40e-461b89e69351', '289c9d13-6f47-4d7c-bd3c-11624df31073', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 03:26:50.752+00', '2026-07-12 04:11:50.752+00', '2026-07-12 03:26:59.752+00'),
  ('f5c23776-7439-489d-8ae5-dd25a668af5e', 'a1648893-0b28-40c6-8eca-e7386ceb211c', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-29 21:25:26.960+00', '2026-04-29 21:45:26.960+00', '2026-04-29 21:25:32.960+00'),
  ('07a94f45-cc67-4687-bb15-ad9195f86e82', '1403f8b9-2ddc-40d1-a7a7-dfc51831fc80', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-26 00:52:54.951+00', '2026-05-26 01:07:54.951+00', '2026-05-26 00:53:04.951+00'),
  ('a7be9db4-10b7-4025-91c7-46c75b8aae29', '1403f8b9-2ddc-40d1-a7a7-dfc51831fc80', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-25 01:26:37.765+00', '2026-05-25 01:41:37.765+00', '2026-05-25 01:26:46.765+00'),
  ('a8ca6db9-9dcd-4c10-89a9-7f242ef7e1f2', 'a6269100-8118-4b6a-b398-4289f9b4bada', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 16:07:21.339+00', '2026-07-11 16:27:21.339+00', '2026-07-11 16:07:34.339+00'),
  ('2592fe4c-1a2b-4d37-93f8-5f3fd4bbc5f3', 'a6269100-8118-4b6a-b398-4289f9b4bada', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 00:22:48.332+00', '2026-07-12 02:22:48.332+00', '2026-07-12 00:22:49.332+00'),
  ('1736687b-6ceb-435b-9158-8e64a30a09c3', 'bb9cd5be-3e30-4775-88bc-17605fdcfbb0', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-27 12:14:22.779+00', '2026-06-27 13:14:22.779+00', '2026-06-27 12:14:26.779+00'),
  ('3b525b2e-cc19-4622-880c-2794feedd7bb', 'bb9cd5be-3e30-4775-88bc-17605fdcfbb0', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 04:29:12.713+00', '2026-06-05 04:49:12.713+00', '2026-06-05 04:29:23.713+00'),
  ('9b9de61b-aa3c-4ea6-a045-ec864a61e52e', '2b0b2176-fe4d-4709-a757-92421b648f99', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-18 05:11:46.048+00', '2026-06-18 05:41:46.048+00', '2026-06-18 05:11:51.048+00');

INSERT INTO task_time_entries (id, task_id, user_id, started_at, ended_at, created_at)
VALUES
  ('7b23181c-f640-4500-8dbd-300d43ff17e0', '87be8b9a-0893-4d45-86f6-4891dc03f208', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-03 07:42:44.858+00', '2026-07-03 07:57:44.858+00', '2026-07-03 07:42:50.858+00'),
  ('85f357e3-d91f-4af2-8bf5-a02e23ff920b', '6c21b4ca-a9a3-42ce-96e0-3efa32bea330', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-03 19:04:57.352+00', '2026-07-03 19:34:57.352+00', '2026-07-03 19:05:00.352+00'),
  ('e460f1f6-2b6b-4f9a-bdd2-aa6d0c2aaaf6', '88ed8fa7-dd81-4843-bcac-d9d110a44be5', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-16 11:24:32.616+00', '2026-05-16 11:54:32.616+00', '2026-05-16 11:24:47.616+00'),
  ('c5e3819b-4eaf-49ed-98e2-517394b7d84b', '81ed676a-53b8-46a6-b549-e1fe9bda2ce1', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-18 17:45:57.321+00', '2026-05-18 18:15:57.321+00', '2026-05-18 17:46:03.321+00'),
  ('a7b6d2f0-b183-4ccc-9ebf-74ffe1bfdb95', 'ad010faa-716a-4b60-8488-b6bf5542448f', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-12 18:04:27.915+00', '2026-05-12 20:04:27.915+00', '2026-05-12 18:04:33.915+00'),
  ('783d84fa-66e1-4281-a6bf-33c901448024', '893b2202-d55e-4279-9555-6aa8a2c30c57', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-09 04:46:03.234+00', '2026-07-09 05:01:03.234+00', '2026-07-09 04:46:08.234+00'),
  ('c09e87c0-76ca-4052-9471-e322342019c3', 'b32576d5-d8fa-43ce-8b44-8fceae266e93', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-14 15:33:13.159+00', '2026-07-14 15:53:13.159+00', '2026-07-14 15:33:19.159+00'),
  ('b27f8dd4-d771-4466-988a-128f7f97da82', 'b32576d5-d8fa-43ce-8b44-8fceae266e93', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 11:32:21.697+00', '2026-07-13 11:47:21.697+00', '2026-07-13 11:32:25.697+00'),
  ('6eefba7b-96a9-4886-ab88-e4b4441d35cf', '50ba9271-2a7b-4ae8-a1c2-9dc490aec656', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-03 19:00:01.397+00', '2026-04-03 19:45:01.397+00', '2026-04-03 19:00:04.397+00'),
  ('06cac15e-9388-4044-b213-9bb19765d160', '467061a7-f6db-4232-9882-fbd8a2d1c92d', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 02:12:35.408+00', '2026-07-13 02:42:35.408+00', '2026-07-13 02:12:36.408+00');

-- ---------------------------------------------------------------------------
-- Activity log
-- ---------------------------------------------------------------------------

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('1931b5a1-ab8f-447e-9bcf-927ac427071e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'category_created', '{"category_id": "ed5373e3-7df6-4787-8fec-dbccf16d7d2b", "category_name": "Beets"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-21 22:19:02+00'),
  ('a5da8043-a592-49b8-86b2-a1d84a0d193c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'category_created', '{"category_id": "b77093f4-829e-4c34-90fb-f907ef6f00d9", "category_name": "Bed & Breakfast"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-22 15:58:58+00'),
  ('88572833-920d-47ba-9439-e3bf80a93d4a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'category_created', '{"category_id": "6eead71b-9b15-417c-95af-dc21efc8583b", "category_name": "Security & Bunker"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-23 11:12:59+00'),
  ('4035f5da-a05a-4d64-a9eb-ac0424b043b9', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'category_created', '{"category_id": "57f6371d-085d-459b-bbfb-933786a8c391", "category_name": "Volunteer Sheriff''s Dept"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-24 14:13:02+00'),
  ('4f2c55cb-d75d-41fe-9058-3bb1cfd969df', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'category_created', '{"category_id": "59b12413-8b34-4639-8f8c-cedebd452bd8", "category_name": "Livestock"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-25 11:52:48+00'),
  ('0d1afdd0-9b0f-49a4-9735-1b486f1d9d63', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'category_created', '{"category_id": "77982b80-16a6-4d7f-93c7-b6744c1f3af3", "category_name": "Fire Safety & Drills"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-26 10:18:25+00'),
  ('fdd44d39-f75a-4593-b90d-26dcaa5460a4', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'category_created', '{"category_id": "3161f1b6-ca0b-40de-b203-ed43a988a431", "category_name": "Land & Fields"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-26 12:30:46+00'),
  ('45aa37d7-ba3c-4953-9309-4316e4cd0932', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'category_created', '{"category_id": "d0c3ab3a-cc0b-45fb-a309-0bd1d83de563", "category_name": "Paperwork & Compliance"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-27 10:47:13+00'),
  ('15a02149-e9e3-40d5-a9ab-d34cd8baee42', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'category_created', '{"category_id": "45686050-73fd-4e14-9505-dfc1a8d5b833", "category_name": "Machinery & Repairs"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-02-27 15:55:03+00'),
  ('23d44794-b240-4c90-9e55-000dd51486d5', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '21a8aba3-463f-429e-be5c-47274e4f1541', 'task_created', '{"task_title": "Test the compost pile''s nitrogen levels"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-01 06:59:14+00'),
  ('61d883e6-8e11-4be1-b266-fb79de22d5c3', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '85e8c7a0-e192-4b51-8c87-8731bbaeb183', 'task_created', '{"task_title": "Change the oil in the tractor before the next big plow"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-02 09:54:08+00'),
  ('e57e627f-6824-46e1-8fd7-d44078107cc1', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'category_created', '{"category_id": "2ebd1f55-9513-4605-a716-72a9ac3c85f3", "category_name": "Bunker Provisions"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-02 14:24:31+00'),
  ('e477a48e-3826-4927-b46f-0837445fa862', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '85e8c7a0-e192-4b51-8c87-8731bbaeb183', 'task_priority_changed', '{"new_priority": "urgent", "old_priority": "soon", "task_title": "Change the oil in the tractor before the next big plow"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-02 15:47:55+00'),
  ('087a34c2-d979-4b45-99fc-eec52832126c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'category_created', '{"category_id": "1b6336f4-28ac-4684-a0b1-b55d65aa1e3e", "category_name": "Sales & Customers"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-02 20:07:25+00'),
  ('32aa369e-32b3-49b3-b9e3-03a52c5078e6', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'f897e37b-9b2d-4984-a518-2285a343eaf7', 'task_created', '{"task_title": "Restock the outhouse before the weekend guests arrive"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-03 08:34:21+00'),
  ('6424807e-b7bd-4b4b-8775-87cc5db6fac0', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'be7eed33-b00a-419e-8609-e33b4e29eb7b', 'task_created', '{"task_title": "Clip the geese''s wings before they attack the mailman again"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-05 19:50:26+00'),
  ('60b30c28-92ec-46d6-820e-7b544f4af8f5', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'category_created', '{"category_id": "d8d8eb08-0e03-4684-9f3f-899dcdb9d0de", "category_name": "Haunted House & Maze"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-06 18:24:57+00'),
  ('7126a618-a492-4b32-b243-c4813a9237fb', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'c0c98bf7-0c27-44a7-9b95-4f4891c8e43e', 'task_created', '{"task_title": "Repair the irrigation line by the wheat field"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-07 13:08:53+00'),
  ('b7295cbd-e923-4223-94e2-e54a1510d930', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'category_created', '{"category_id": "8c2a4844-e870-4ab7-b247-5406377d3c03", "category_name": "Manure & Composting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-08 13:51:44+00'),
  ('c70acfbc-814d-469f-ad9f-bdfd5cc892c3', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'e2b08f3c-4a3e-470c-92a2-731f48a98b9f', 'task_created', '{"task_title": "Sow the second beet crop before the last frost"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-10 06:22:47+00'),
  ('ea56f3b5-90b3-4d5f-b93a-810e780b5ec5', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '1f801b47-4312-45af-94f1-7e7b4d7f0df7', 'task_created', '{"task_title": "Restock the trunk first-aid kit"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-11 13:26:14+00'),
  ('6b357c5a-65d9-4a50-8de1-5ef64730dbb3', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '44b1630e-de80-40be-80cc-a375253aedfd', 'task_created', '{"task_title": "Till the fallow field ahead of next season''s planting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-13 16:55:54+00'),
  ('e96a4aa3-90ae-4c2c-915b-b9a8604a5d69', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'f423330a-1db5-4d83-b8de-0faa853c60e7', 'task_created', '{"task_title": "Submit the beet crop insurance claim after the hailstorm"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-13 21:24:12+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('d1ef1284-9565-4425-b4e4-d9053955722c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '3b005460-a27f-44c4-8221-6a3f9d31eb10', 'task_created', '{"task_title": "Fix the guest room thermostat that only does two temperatures"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-14 21:35:14+00'),
  ('4f7d013c-b0e1-4e94-a537-3e1092ab6233', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'fb0d4096-aed4-47d3-97f5-03716529a404', 'task_created', '{"task_title": "Organize the farm office filing cabinet"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-18 15:07:46+00'),
  ('ef98d315-7db0-4265-b928-c6a5024d219c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'ff5c4f12-a436-4cef-8284-12a677d35046', 'task_created', '{"task_title": "Test the motion-sensor alarms along the tree line"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-19 06:40:37+00'),
  ('fd3ac633-d4f9-454b-a181-e8eda2a6a858', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '6b6d2609-b65a-4dce-a582-1683360a529a', 'task_created', '{"task_title": "Rotate the canned goods in the bunker by expiration date"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-24 09:10:20+00'),
  ('46f2807c-a2c5-4456-8d2e-5fa1bd6c2917', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '9eb37833-f93f-4cc7-8c30-1bcfe9e61c99', 'task_created', '{"task_title": "Fix the flat tire on the flatbed trailer"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-25 06:36:33+00'),
  ('d3ec6df8-6d16-4f2b-b38b-045610baffff', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '331268e6-2f4a-4214-87a6-4d6f69a66bfb', 'task_created', '{"task_title": "Clean and test the department-issued flashlight"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-25 12:43:37+00'),
  ('80287d85-a3e4-4b14-9a38-92a375e9428f', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'f644e91e-788f-47b5-bfc1-193bc7dfcc13', 'task_created', '{"task_title": "Clear fallen branches from the tree line after the storm"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-26 14:27:28+00'),
  ('2cb86b8b-dae8-4df2-81c7-e4f34786ae85', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '26809967-59d6-4f11-b89b-19bee1ad7c76', 'task_created', '{"task_title": "Test the hand-crank emergency radio"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-28 14:23:35+00'),
  ('06cf1b6f-4bbf-4e69-bc0d-9b84b717db21', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'affaa6ac-263e-4b32-b175-f9b0ec2fe499', 'task_created', '{"task_title": "Wax the department-issued patrol vehicle"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-29 10:13:37+00'),
  ('884ce7e5-4f3a-44ff-a237-19589124498d', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'dcfe2ac5-7519-4c23-8441-4420ce3c1668', 'task_created', '{"task_title": "Replace the ''no running water after 9pm'' sign"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-29 17:39:07+00'),
  ('773edd31-6629-4210-b932-aa9b9aa3a6f9', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '37733cbe-eb05-4bb4-bfc1-e42dc88a8191', 'task_created', '{"task_title": "Replace the cracked badge holder"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-30 16:52:18+00'),
  ('045b6d2d-86f7-4a52-9ad0-600eaa2bf295', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'b83d06c8-3100-4c92-8237-471fcc866328', 'task_created', '{"task_title": "Haul away the aged compost for sale to neighbors"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-31 17:35:07+00'),
  ('0a858290-1912-45b9-87f7-c516cafb00af', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '165f87cd-f67e-4cd5-8e00-ac19a374ab7c', 'task_created', '{"task_title": "Review the fire escape route with Mose"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-01 19:33:27+00'),
  ('75b75c52-7449-405e-841c-68eea794ecdc', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '87a5145c-239a-42f5-8569-804a7fcac378', 'task_created', '{"task_title": "Move the goat herd to the north pasture for fresh grazing"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-01 21:36:43+00'),
  ('6346749a-41a4-4c2b-858e-8fb1bb3b2b69', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '6b6d2609-b65a-4dce-a582-1683360a529a', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Rotate the canned goods in the bunker by expiration date"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-02 04:01:42+00'),
  ('5057ae6e-ec5c-43b6-8011-b7ff700401a5', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '9386f1e3-aa7a-419f-9a15-43a91642a1bc', 'task_created', '{"task_title": "Restock the bunker''s canned beet rations"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-02 07:21:29+00'),
  ('a34afddb-263e-472e-9a1a-8e82a5081b6e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'a4296a13-b1ea-432f-9739-d45011006dcb', 'task_created', '{"task_title": "Repair the fence-post driver''s cracked handle"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-02 12:27:49+00'),
  ('9763841d-0b70-439b-a052-68d1cccb5325', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '708cb7ee-b2bd-4caa-ae8b-280d0bdd5291', 'task_created', '{"task_title": "Update the farm''s online store listing"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-02 15:12:35+00'),
  ('2b574110-71cf-4abd-a3a8-bbb11b476afa', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'b4ade48b-15e0-4d3b-9167-d1b86089ac58', 'task_created', '{"task_title": "Change the linens in the guest rooms before the weekend booking"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-02 15:33:32+00'),
  ('8751b77f-2855-4ceb-ab04-319147d220c3', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '50ba9271-2a7b-4ae8-a1c2-9dc490aec656', 'task_created', '{"task_title": "Repair the manure spreader''s clogged chute"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-03 16:06:04+00'),
  ('4815020c-644e-4900-a844-77171ff3a7eb', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '71dbba96-8602-405b-9bee-d6a8e143b45a', 'task_created', '{"task_title": "Deep clean the root cellar guest suite"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-03 19:54:44+00'),
  ('6b76ce01-bd97-4b39-9cee-e6b6042f5af7', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'd02f89e3-03c3-49b8-ad14-1f9a7cb35b6b', 'task_created', '{"task_title": "Test the bunker''s fire suppression system"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-04 11:24:36+00'),
  ('e42fa065-fdb5-4a0f-8ab3-fa2237aa0ae9', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '4ac6a381-e24a-48bf-a3e0-6eb91f042fd0', 'task_created', '{"task_title": "Attend the volunteer deputy refresher training"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-04 16:36:24+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('ee3b5ccf-1424-420c-b331-dd902a4f2cb2', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '7db5f9d9-9177-4019-b0ff-ac09a710cf5c', 'task_created', '{"task_title": "Tune up the chainsaw before hedge-laying season"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-05 11:41:09+00'),
  ('5a754aa2-9d37-4e97-a2f2-c0304d00eb45', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '893b2202-d55e-4279-9555-6aa8a2c30c57', 'task_created', '{"task_title": "Print tickets for the Halloween haunted house event"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-07 16:52:19+00'),
  ('ce6ee587-7406-4bf5-a071-e627be0e32b3', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '391a2f94-d078-465e-91db-937ebc233c17', 'task_created', '{"task_title": "Replace batteries in the perimeter security cameras"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-08 17:14:50+00'),
  ('7e3d907d-7a6b-4085-815f-c5b684aa6d22', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'b32576d5-d8fa-43ce-8b44-8fceae266e93', 'task_created', '{"task_title": "Spread manure on the fallow field before planting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-10 16:17:08+00'),
  ('dadc48e2-7ffd-41b8-a156-c50cd1d68d4b', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'bad9bdb4-9030-4bd2-9c1c-a5b8c9a07034', 'task_created', '{"task_title": "Repair the chicken coop door latch"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-11 06:33:37+00'),
  ('ea287d09-4d35-49b9-96e5-1c57a496845b', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '71dbba96-8602-405b-9bee-d6a8e143b45a', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Deep clean the root cellar guest suite"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-14 02:37:40+00'),
  ('95262173-8b0e-4625-8242-494670f8cc95', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'f423330a-1db5-4d83-b8de-0faa853c60e7', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Submit the beet crop insurance claim after the hailstorm"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-15 07:46:50+00'),
  ('9502b3b9-6f30-42dd-aa64-34889cbe3d5e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '37733cbe-eb05-4bb4-bfc1-e42dc88a8191', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Replace the cracked badge holder"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-15 21:57:42+00'),
  ('5720a765-9f8d-4186-b12b-b558da872cee', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'b17c1238-3f82-4f23-a3ea-3d5f51d75591', 'task_created', '{"task_title": "Submit the monthly ride-along report to the county"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-16 08:18:52+00'),
  ('900b74c0-2ade-49f4-b644-b37ee40ca2b6', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '87a5145c-239a-42f5-8569-804a7fcac378', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Move the goat herd to the north pasture for fresh grazing"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-16 14:33:05+00'),
  ('e4b4331f-4a90-4e04-90a0-b3e9a3883264', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'd29de48a-5062-4d5d-85eb-e69e04bdb7bc', 'task_created', '{"task_title": "Renew the roadside beet stand''s vendor permit"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-17 08:26:46+00'),
  ('034f1a80-149a-4086-b196-8d721e3c9c77', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '6b6d2609-b65a-4dce-a582-1683360a529a', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Rotate the canned goods in the bunker by expiration date"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-19 09:26:32+00'),
  ('82a7a636-a4bf-4ff5-820f-bbf226f0ddca', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '84000432-2af4-41f0-8a98-987dde96ec94', 'task_created', '{"task_title": "Mow the fence line before it swallows the fence entirely"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-20 20:28:20+00'),
  ('448f1d25-8731-4b27-857a-7d826ac51615', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'f897e37b-9b2d-4984-a518-2285a343eaf7', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Restock the outhouse before the weekend guests arrive"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-21 13:31:33+00'),
  ('45b27cd5-7c10-48da-908a-4af60009d018', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '945d7fae-d509-4609-89e8-c9a2234d0808', 'task_created', '{"task_title": "Negotiate beet pricing with the grocery buyer in Scranton"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-22 09:48:59+00'),
  ('d96000f7-8483-44fe-b237-9fdd739c2e86', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '6d225de2-4174-496d-96fb-c555ed141352', 'task_created', '{"task_title": "Clear brush from around the propane tank"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-22 21:51:04+00'),
  ('e2ce806a-0f80-444a-863d-786e6caa406a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '84000432-2af4-41f0-8a98-987dde96ec94', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Mow the fence line before it swallows the fence entirely"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-23 02:45:48+00'),
  ('ff0bbc55-a8eb-4fc7-b99a-93528ab2afd3', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'ad010faa-716a-4b60-8488-b6bf5542448f', 'task_created', '{"task_title": "Build a new jump-scare prop for the barn section"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-23 15:03:47+00'),
  ('d7cb1e5a-e9a1-4d72-a670-97cdf5e08167', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '84000432-2af4-41f0-8a98-987dde96ec94', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Mow the fence line before it swallows the fence entirely"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-24 19:56:10+00'),
  ('5ace5c5e-7299-4c86-8309-691af0681267', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '87a5145c-239a-42f5-8569-804a7fcac378', 'task_priority_changed', '{"new_priority": "whenever", "old_priority": "soon", "task_title": "Move the goat herd to the north pasture for fresh grazing"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-27 11:02:15+00'),
  ('a9b24210-71d3-48ca-a1e0-562e2300b23a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'b966c270-6640-49dc-b09d-d40df1520f4d', 'task_created', '{"task_title": "Inspect the fire extinguishers in the barn"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-27 15:11:24+00'),
  ('ed543cc7-3508-4d54-b76a-d66d4f40bd5c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'fe087dec-dd4c-4fac-a061-4d6b21294695', 'task_created', '{"task_title": "Test the haunted house''s animatronic scarecrow"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-27 17:54:40+00'),
  ('531c2854-d201-4103-a8c3-c3a8e61a87db', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '85e8c7a0-e192-4b51-8c87-8731bbaeb183', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Change the oil in the tractor before the next big plow"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-28 12:21:33+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('b77e7bc4-4aba-4359-b2d1-38c85a86c69d', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'a1648893-0b28-40c6-8eca-e7386ceb211c', 'task_created', '{"task_title": "Plow the north field before the ground freezes"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-28 12:58:41+00'),
  ('28f8f697-e1a3-430b-a0da-718e585678b9', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'd02f89e3-03c3-49b8-ad14-1f9a7cb35b6b', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Test the bunker''s fire suppression system"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-28 13:39:43+00'),
  ('74d4e4d7-8ac0-42c3-827f-a712f94d382a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'eb1e43f3-9d08-4f53-a0d5-1f35cdb345d0', 'task_created', '{"task_title": "File the volunteer sheriff''s department expense report"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-29 14:55:28+00'),
  ('9037cad8-7061-4cc0-b171-39906cdd1ecb', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '5d31ff78-d58f-4423-ad0f-dbcb40e6c3de', 'task_created', '{"task_title": "Update the liability insurance for the haunted maze"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-01 07:52:41+00'),
  ('25faf94b-dd74-488b-9c1a-4a165044de2f', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'd29de48a-5062-4d5d-85eb-e69e04bdb7bc', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Renew the roadside beet stand''s vendor permit"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-01 13:30:05+00'),
  ('59eab518-df32-4d7e-813b-b85f2d7a94c8', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'cb81f8b6-fe00-471f-b2e4-93da0c5548b8', 'task_created', '{"task_title": "Replace the tractor''s dead headlight"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-01 14:57:39+00'),
  ('f9f24878-c1f2-4209-8b52-356fea6eb06e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '21a8aba3-463f-429e-be5c-47274e4f1541', 'task_due_date_changed', '{"new_due_date": "2026-03-08", "old_due_date": "2026-03-03", "task_title": "Test the compost pile''s nitrogen levels"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-01 18:21:52+00'),
  ('7bb1dd36-e9ff-4547-8753-89c20b9aa865', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'b17c1238-3f82-4f23-a3ea-3d5f51d75591', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Submit the monthly ride-along report to the county"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-02 14:20:38+00'),
  ('3737fc7f-566e-42ad-be6a-239dab46e802', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'e2b08f3c-4a3e-470c-92a2-731f48a98b9f', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Sow the second beet crop before the last frost"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-02 19:33:58+00'),
  ('1de4a27a-c875-4a3b-a52e-dde336c9ded3', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'd94b69d2-d7e6-4a52-8cc4-22ca2f368b62', 'task_created', '{"task_title": "Run the full property lockdown drill"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-02 20:27:08+00'),
  ('b2d9b6f2-a208-4fa2-88e9-bbd230ea341e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '68368f53-75d6-4608-b80b-d2bcc107fc45', 'task_created', '{"task_title": "Renew the concealed carry permit before it lapses"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-03 09:57:57+00'),
  ('d94028f6-d468-4474-89ad-ab0d3c52ffe8', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'a21364ca-e498-492e-b6f0-b0e06f1027de', 'task_created', '{"task_title": "Turn the compost pile before it overheats"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 09:45:58+00'),
  ('61356a05-cdd6-4f17-99d0-3fdff7e4171c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'a1648893-0b28-40c6-8eca-e7386ceb211c', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Plow the north field before the ground freezes"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 10:13:16+00'),
  ('aadc765a-b2b7-47d2-8e1f-8c1e4edaedaf', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'fcf54815-e82c-49ae-9982-818722c7d068', 'task_created', '{"task_title": "Inspect the perimeter fence for breaches"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 17:11:19+00'),
  ('4b68ae79-6024-4bbc-8f36-6bf8c0ba1a51', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '455f307e-3ef1-49cf-9ec2-559633619b4d', 'task_created', '{"task_title": "Replant the beet seedlings the frost got last week"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-06 08:08:20+00'),
  ('51e65d2e-1166-4943-96f8-20d456b8ba3f', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '47449a19-9ddd-4e2a-82e8-79cffde6c47e', 'task_created', '{"task_title": "Top off the propane reserve tanks"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-06 10:15:36+00'),
  ('c2e5fd89-63fd-492d-9470-b6d1f6a2badc', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '71dbba96-8602-405b-9bee-d6a8e143b45a', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Deep clean the root cellar guest suite"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-07 15:15:37+00'),
  ('36f66006-62bd-40d1-a801-365bc5437010', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '391a2f94-d078-465e-91db-937ebc233c17', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Replace batteries in the perimeter security cameras"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-08 12:03:07+00'),
  ('dced3070-2f65-4fc2-b614-156789fc0001', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '44b1630e-de80-40be-80cc-a375253aedfd', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Till the fallow field ahead of next season''s planting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-08 14:03:46+00'),
  ('2f89e085-6e50-4afb-a957-1105d86e64a5', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '31234b28-8dfe-4a3f-abf0-66b9247193a5', 'task_created', '{"task_title": "Inventory the gas masks and replace the filters"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-08 16:06:24+00'),
  ('81d58415-f866-4b3d-b312-501cbb0c3c4a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '21a8aba3-463f-429e-be5c-47274e4f1541', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Test the compost pile''s nitrogen levels"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-09 12:25:12+00'),
  ('de33e8df-fde8-41b5-a185-bfa7b6b4b026', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '7d80d6ca-da1a-4726-918f-cc25e3022bb6', 'task_created', '{"task_title": "Follow up with a restaurant lead about sourcing beets locally"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-09 15:18:38+00'),
  ('3d610d74-45e7-4f6d-a20e-153ba6da9d6a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '8b35db4e-da98-41ff-b942-a6e255be8687', 'task_created', '{"task_title": "Inventory the gun safe and update the log"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-09 20:33:25+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('f1f704d4-98eb-48cf-b50e-d77e595a7799', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '9997ac19-376a-488a-b415-618093fa6112', 'task_created', '{"task_title": "Feed the goats before the morning rounds"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-09 22:30:28+00'),
  ('0793eed8-d94d-431c-8de1-50f49e18171d', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '05857c60-5db1-4705-8f72-91646a0f8166', 'task_created', '{"task_title": "Run the annual (unannounced) farm-wide fire drill"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-10 06:16:16+00'),
  ('f57cd5c5-ec6e-4f58-bb92-0a4636aea07c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '1403f8b9-2ddc-40d1-a7a7-dfc51831fc80', 'task_created', '{"task_title": "Grease the thresher''s bearings before harvest week"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-10 09:57:07+00'),
  ('fd7521fe-e3b9-446f-8f85-c6bcdbf78d46', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'fcf54815-e82c-49ae-9982-818722c7d068', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Inspect the perimeter fence for breaches"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-11 14:46:08+00'),
  ('54bad1ff-3157-4ee6-9ee5-addf43fb2b52', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '81ed676a-53b8-46a6-b549-e1fe9bda2ce1', 'task_created', '{"task_title": "Recruit local teens as haunted house actors"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-11 18:14:28+00'),
  ('5801b34d-1c7d-40bc-accc-d70c1fca34bf', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '9c74230d-924d-4b61-ab60-467264073c9b', 'task_created', '{"task_title": "Update the B&B''s online listing photos"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-12 16:10:21+00'),
  ('812dceea-22e1-4dd6-b6b2-760cdb5d7e4a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'dbc08262-c84b-4003-a065-2cb18874a68e', 'task_created', '{"task_title": "Renew the volunteer sheriff''s department paperwork"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-13 08:24:56+00'),
  ('8664d689-339f-4b17-b6d1-54fc84a9c1b5', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'a1648893-0b28-40c6-8eca-e7386ceb211c', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Plow the north field before the ground freezes"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-13 13:53:23+00'),
  ('8ab04655-bbdc-494f-a97c-0d9cb29401c8', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '8c5a2118-13b1-408f-a93d-bac9728928b7', 'task_created', '{"task_title": "Muck out the guest parking area before check-in"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-13 22:23:14+00'),
  ('6dd32f10-b0f7-43de-b411-8584cf23971b', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '88ed8fa7-dd81-4843-bcac-d9d110a44be5', 'task_created', '{"task_title": "Replace the burnt-out lights along the maze path"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-14 22:06:42+00'),
  ('23b7b504-76c8-4fd5-b21c-6dfbeb16642f', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'be7eed33-b00a-419e-8609-e33b4e29eb7b', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Clip the geese''s wings before they attack the mailman again"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-15 01:29:17+00'),
  ('cc3c3ba9-1e83-498e-a43c-690b8189212f', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '8c5a2118-13b1-408f-a93d-bac9728928b7', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Muck out the guest parking area before check-in"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-15 06:41:47+00'),
  ('4f9f003e-a143-4b3d-ac52-f4d3c125e880', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '50ba9271-2a7b-4ae8-a1c2-9dc490aec656', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Repair the manure spreader''s clogged chute"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-15 19:38:34+00'),
  ('1e50efb9-1dcc-40f3-a215-7098091f73bf', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '31234b28-8dfe-4a3f-abf0-66b9247193a5', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Inventory the gas masks and replace the filters"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-15 20:23:04+00'),
  ('0854c313-1fb6-4735-995a-eebde54069a0', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '229fbf5c-5ac5-4036-8796-9acc203d5486', 'task_created', '{"task_title": "Prepare the welcome basket of beets for arriving guests"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-16 09:12:08+00'),
  ('7ef3951b-9fb6-4a32-a59c-5d8526d17ca2', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'a21364ca-e498-492e-b6f0-b0e06f1027de', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Turn the compost pile before it overheats"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-19 09:20:38+00'),
  ('792af822-08ef-45e3-950e-62198bac6de3', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '81ed676a-53b8-46a6-b549-e1fe9bda2ce1', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Recruit local teens as haunted house actors"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-19 20:29:01+00'),
  ('e08cbdd0-ba81-4b82-a74b-f061e6f46f9f', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'affaa6ac-263e-4b32-b175-f9b0ec2fe499', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Wax the department-issued patrol vehicle"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-19 23:07:20+00'),
  ('a1c83b53-dfe0-4fee-9317-1089dedc3888', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '88ed8fa7-dd81-4843-bcac-d9d110a44be5', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Replace the burnt-out lights along the maze path"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-21 12:17:05+00'),
  ('e4c3c02e-175a-49a2-b754-4d5131d2d508', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '9997ac19-376a-488a-b415-618093fa6112', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Feed the goats before the morning rounds"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-21 15:14:27+00'),
  ('2aedcd52-c285-452c-b81a-d11020dd6079', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '47449a19-9ddd-4e2a-82e8-79cffde6c47e', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Top off the propane reserve tanks"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-21 17:26:21+00'),
  ('5e62cd43-7b2c-4e63-883f-96131e7cda35', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'bb9cd5be-3e30-4775-88bc-17605fdcfbb0', 'task_created', '{"task_title": "Renew the B&B''s county health inspection certificate"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-22 11:21:15+00'),
  ('a22bca16-72c7-484a-a4cc-8bc134139226', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '8b35db4e-da98-41ff-b942-a6e255be8687', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Inventory the gun safe and update the log"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-22 12:20:45+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('fe612bd0-51b7-458b-ac9e-503a31b337e7', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'f2d5e658-ee7a-4766-9207-a267728c4714', 'task_created', '{"task_title": "Repair the beet harvester''s conveyor belt"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-22 13:01:32+00'),
  ('160ecd01-4f44-43b8-81c7-a5f272979059', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '331268e6-2f4a-4214-87a6-4d6f69a66bfb', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Clean and test the department-issued flashlight"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-22 17:44:30+00'),
  ('f77941f7-b44d-4668-842c-8809707c9ffe', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '31234b28-8dfe-4a3f-abf0-66b9247193a5', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Inventory the gas masks and replace the filters"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-23 17:31:49+00'),
  ('0da6f979-eb92-4296-b015-56f94c9bff63', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '26809967-59d6-4f11-b89b-19bee1ad7c76', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Test the hand-crank emergency radio"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-24 12:08:11+00'),
  ('f1702afa-b984-4bce-ab1b-7defc8fcefbb', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '6af68202-7a92-4b44-9173-aca475f963be', 'task_created', '{"task_title": "Clean out the goat pen bedding"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-24 21:59:45+00'),
  ('462b6866-c37d-4b3b-b5b0-da539c6082a9', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'b32576d5-d8fa-43ce-8b44-8fceae266e93', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Spread manure on the fallow field before planting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-25 23:16:51+00'),
  ('56eeefa9-9e70-4003-993b-12ec7296c44e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '961d19e7-93c8-4406-981d-d4eed693ee00', 'task_created', '{"task_title": "Restock fake blood for the haunted house"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-28 10:14:21+00'),
  ('5ab484cd-e5db-498e-8c9c-6623211a8fdd', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '1403f8b9-2ddc-40d1-a7a7-dfc51831fc80', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Grease the thresher''s bearings before harvest week"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-28 12:18:24+00'),
  ('07df116f-ef85-405a-92ca-12f6aaf30f3b', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '5354b2b2-bc30-4b8a-b381-e842d832f035', 'task_created', '{"task_title": "Restock the water purification tablets"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-28 21:17:41+00'),
  ('03bf0d82-d747-40d1-b9b2-1f70e57293ed', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '165f87cd-f67e-4cd5-8e00-ac19a374ab7c', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Review the fire escape route with Mose"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-28 21:50:34+00'),
  ('c1cc3afa-a503-4ba0-b9f4-32f01d54b968', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '8fc8bb1e-c026-457f-a46b-496583431a6f', 'task_created', '{"task_title": "Restock the burn barrel safety kit"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-30 17:51:36+00'),
  ('46277f90-b92d-433d-bb8b-1490158a0868', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '5daae9be-abbb-473e-8e1e-06342c531257', 'task_created', '{"task_title": "Till under the cover crop before spring planting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-01 15:15:36+00'),
  ('0ab15f51-06b1-467a-8cd8-2418d74d33b9', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '4a1eeaba-71c6-4f42-bf72-5cfd4ded8142', 'task_created', '{"task_title": "Cut this year''s corn maze pattern"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-01 19:34:10+00'),
  ('63b91b4d-bf2a-4573-949d-6acc1948ffa1', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '6e83d543-5485-42bf-9c98-fc8cded7a7a5', 'task_created', '{"task_title": "Restock the emergency beet rations shelf"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-02 14:30:59+00'),
  ('159f4aad-a9d0-41c6-bc9b-7312567903c9', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'bec527a9-86e2-4a5d-a37d-eff55edb3794', 'task_created', '{"task_title": "Sort beets by size for the county fair entry"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-02 20:52:46+00'),
  ('33edede5-069a-40ae-bd08-3b131c74c971', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '6e83d543-5485-42bf-9c98-fc8cded7a7a5', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Restock the emergency beet rations shelf"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 01:38:47+00'),
  ('bd9e297f-6ade-464e-abf3-6721afb7598a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '68368f53-75d6-4608-b80b-d2bcc107fc45', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Renew the concealed carry permit before it lapses"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 07:41:31+00'),
  ('f43de4b7-c22b-45d4-bc9f-32497fd387f0', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '81ed676a-53b8-46a6-b549-e1fe9bda2ce1', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Recruit local teens as haunted house actors"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 09:53:04+00'),
  ('84520979-654c-4cba-8989-2dd1abaf615f', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '9c74230d-924d-4b61-ab60-467264073c9b', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Update the B&B''s online listing photos"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 01:48:16+00'),
  ('20a9f5c8-5984-4f70-8542-33efe68ff844', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'f897e37b-9b2d-4984-a518-2285a343eaf7', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Restock the outhouse before the weekend guests arrive"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 12:31:57+00'),
  ('9c93477e-1b6a-4610-a8f8-6fd050a1617d', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'ad010faa-716a-4b60-8488-b6bf5542448f', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Build a new jump-scare prop for the barn section"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 12:58:37+00'),
  ('af397853-6d12-4363-a32c-52ca81c62868', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'd02f89e3-03c3-49b8-ad14-1f9a7cb35b6b', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Test the bunker''s fire suppression system"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 15:26:26+00'),
  ('d9e6a412-6653-49e0-90cd-93669fe00988', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'e584deca-c1ad-4b7a-a891-1cc277ffd050', 'task_created', '{"task_title": "Worm the goat herd on schedule"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-11 15:13:50+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('33b38c83-534c-4d0a-b5c5-bb359844861d', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '3608ba23-e27a-423f-8237-339e8f4fd71c', 'task_created', '{"task_title": "Order more hay bales for the maze walls"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-11 21:30:35+00'),
  ('11fa5db1-7660-477e-a89a-fc72ada8a892', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '1f801b47-4312-45af-94f1-7e7b4d7f0df7', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Restock the trunk first-aid kit"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-15 14:56:05+00'),
  ('8453a269-5298-4466-984b-5ef9aee1a09c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'bec527a9-86e2-4a5d-a37d-eff55edb3794', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Sort beets by size for the county fair entry"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-16 12:49:20+00'),
  ('ab389254-ae54-4ea7-8f75-4714addf6a95', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '5d31ff78-d58f-4423-ad0f-dbcb40e6c3de', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Update the liability insurance for the haunted maze"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-16 18:14:13+00'),
  ('89957bbd-ed70-4bd5-8e7a-c822f561398a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '6af68202-7a92-4b44-9173-aca475f963be', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Clean out the goat pen bedding"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-16 21:05:47+00'),
  ('01c94048-3b6a-44fe-b00a-7aaed3c03632', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '5c58efaf-888c-471e-871a-fc4e3d2fbfc8', 'task_created', '{"task_title": "Repair the hose reel by the barn"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 06:53:20+00'),
  ('3dad3392-d9a4-4ed2-8064-a8109dd5df63', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '47449a19-9ddd-4e2a-82e8-79cffde6c47e', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Top off the propane reserve tanks"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 07:21:35+00'),
  ('5e277921-b1de-48ab-8265-8233561a269f', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '2b0b2176-fe4d-4709-a757-92421b648f99', 'task_created', '{"task_title": "Call the regional grocery chain about a beet supply contract"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 09:43:54+00'),
  ('0a1167b9-dece-4332-a2d3-2a0d1933dacc', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '2151a3b6-19fe-45d3-9c96-40bcc77f8c0e', 'task_created', '{"task_title": "Patch the hinge on the bunker''s escape hatch"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 16:10:42+00'),
  ('a14ff4d9-5aa8-43c4-9a45-d21b92c14896', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'e584deca-c1ad-4b7a-a891-1cc277ffd050', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Worm the goat herd on schedule"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 18:59:18+00'),
  ('35bacdde-b064-4f18-8f5d-ecfdbb9544e5', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '4a1eeaba-71c6-4f42-bf72-5cfd4ded8142', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Cut this year''s corn maze pattern"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 20:46:07+00'),
  ('dd211e33-972b-4641-9873-855fd6a480e7', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '8b35db4e-da98-41ff-b942-a6e255be8687', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Inventory the gun safe and update the log"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-17 21:01:45+00'),
  ('516ea03c-29b7-4fea-a990-ea94ee4910db', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '0f80724f-ca56-46ee-8f22-a031a289a451', 'task_created', '{"task_title": "Weed the beet rows before they choke the seedlings"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-18 07:54:15+00'),
  ('804b311a-f415-4cca-9377-f2a66aa8b90a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '7db5f9d9-9177-4019-b0ff-ac09a710cf5c', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Tune up the chainsaw before hedge-laying season"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-19 01:10:53+00'),
  ('d910659b-c662-4768-8ff5-19732936f267', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '3608ba23-e27a-423f-8237-339e8f4fd71c', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Order more hay bales for the maze walls"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 07:31:45+00'),
  ('37ed0818-d995-4709-aa64-58b0941fec52', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '05857c60-5db1-4705-8f72-91646a0f8166', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Run the annual (unannounced) farm-wide fire drill"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 10:03:15+00'),
  ('aea17ea4-5f0f-4992-9fed-667d451e72c9', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '0f80724f-ca56-46ee-8f22-a031a289a451', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Weed the beet rows before they choke the seedlings"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 17:03:43+00'),
  ('b3335768-0641-40c7-bd69-fadaaea6ad53', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '229fbf5c-5ac5-4036-8796-9acc203d5486', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Prepare the welcome basket of beets for arriving guests"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 21:12:24+00'),
  ('172e5134-c123-47cf-8b20-2000bf3bfa57', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '2151a3b6-19fe-45d3-9c96-40bcc77f8c0e', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Patch the hinge on the bunker''s escape hatch"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-21 08:44:07+00'),
  ('fcc84f72-c447-43de-ae4b-b2d16a9f5a09', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '62c944a3-6d7e-45d5-8e63-35815720aa62', 'task_created', '{"task_title": "Patrol the county fairgrounds ahead of the weekend event"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-21 13:09:00+00'),
  ('6a4bd980-43fa-4079-a29a-1286164fd303', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'eeff2a51-062b-46c3-9592-1f315afbf6d9', 'task_created', '{"task_title": "Test the sugar content of this year''s beet crop"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-21 16:42:59+00'),
  ('5d7513f8-4142-4c14-8328-050418c5394e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '44b1630e-de80-40be-80cc-a375253aedfd', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Till the fallow field ahead of next season''s planting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-21 22:52:28+00'),
  ('38884b62-e677-4416-86a2-7a5bcf4b03cf', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '289c9d13-6f47-4d7c-bd3c-11624df31073', 'task_created', '{"task_title": "Order more chicken feed before the coop runs dry"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-22 18:50:16+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('6371a457-3a0a-4be1-8fe2-fbb768342859', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'b232b35e-cfb2-49a7-9866-c7bb839b413c', 'task_created', '{"task_title": "Sharpen the plow blades before the fall till"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-23 10:16:17+00'),
  ('d89491ba-1a38-4b99-b8e6-127e8d8afa4b', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '2b0b2176-fe4d-4709-a757-92421b648f99', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Call the regional grocery chain about a beet supply contract"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-23 21:10:04+00'),
  ('c7dcaeb9-03fc-4d24-8b28-ca4e6dbd443b', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '289c9d13-6f47-4d7c-bd3c-11624df31073', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Order more chicken feed before the coop runs dry"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-24 05:53:06+00'),
  ('7004e068-af00-4e97-b9d8-b30d8cb863f8', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '62c944a3-6d7e-45d5-8e63-35815720aa62', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Patrol the county fairgrounds ahead of the weekend event"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-25 11:11:47+00'),
  ('0a608298-09cf-4a27-89f4-f6813e27691a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'eeff2a51-062b-46c3-9592-1f315afbf6d9', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Test the sugar content of this year''s beet crop"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-25 12:18:52+00'),
  ('f9d9dac4-7047-4145-ba4d-c60bab525521', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '87be8b9a-0893-4d45-86f6-4891dc03f208', 'task_created', '{"task_title": "Negotiate the county fair beet booth pricing"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-26 08:00:44+00'),
  ('ec8b9f9b-4473-4715-bab1-651a9c27464f', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '6f281ad7-27ef-4959-b3b9-649547aa6660', 'task_created', '{"task_title": "Replace the smoke detector batteries across the property"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-26 08:26:11+00'),
  ('59219009-ddff-49b0-99c6-45e4c20cc220', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '0f80724f-ca56-46ee-8f22-a031a289a451', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Weed the beet rows before they choke the seedlings"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-26 16:35:50+00'),
  ('bab028d3-39b6-455f-a0d6-7cd1131a1cac', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '5354b2b2-bc30-4b8a-b381-e842d832f035', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Restock the water purification tablets"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-26 17:26:03+00'),
  ('f6c71bd7-ad26-4cee-8ec5-59b1e259aeca', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'd94b69d2-d7e6-4a52-8cc4-22ca2f368b62', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Run the full property lockdown drill"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-27 17:33:39+00'),
  ('c416c60b-ec08-4034-a575-a59cc48a0a6c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'affaa6ac-263e-4b32-b175-f9b0ec2fe499', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Wax the department-issued patrol vehicle"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-28 12:05:24+00'),
  ('74ed4ae2-a3d8-48ed-968c-7638aaa329e5', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'a21364ca-e498-492e-b6f0-b0e06f1027de', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Turn the compost pile before it overheats"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-29 12:18:25+00'),
  ('47edee34-7de3-497a-a4db-a74e2eff9b05', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '9c74230d-924d-4b61-ab60-467264073c9b', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Update the B&B''s online listing photos"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-29 12:58:18+00'),
  ('87202e74-f258-461c-a059-7a9134b607a8', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'c5753255-55dc-40f5-9f3d-a8d538725321', 'task_created', '{"task_title": "Sharpen the display katana in the great room"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-01 09:26:22+00'),
  ('9f19f4d9-3b70-4b27-8b5b-1a6bac81950a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '8bea4b46-6969-4f42-a676-262121cd4308', 'task_created', '{"task_title": "Treat a goat with a mild limp"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-02 14:18:39+00'),
  ('bb5b9c40-80e4-4e12-bd39-0e4740dfc6f3', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '6c21b4ca-a9a3-42ce-96e0-3efa32bea330', 'task_created', '{"task_title": "Print new price tags for the farm stand"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-03 14:01:06+00'),
  ('dc8889a8-438b-4e17-9fc5-11a028379d2e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '68368f53-75d6-4608-b80b-d2bcc107fc45', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Renew the concealed carry permit before it lapses"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-03 14:20:28+00'),
  ('c9369763-6b6c-490a-88c2-ee976166871b', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '6c21b4ca-a9a3-42ce-96e0-3efa32bea330', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Print new price tags for the farm stand"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-04 19:34:51+00'),
  ('57d85213-96f1-44f1-87b4-8246113a5951', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '6114ec78-d2d1-48d8-8c95-5cca2bcb39a4', 'task_created', '{"task_title": "Collect eggs from the coop before the raccoons find them first"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-05 07:39:39+00'),
  ('202a9877-7b50-42a7-9601-840faec1b6be', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '8bea4b46-6969-4f42-a676-262121cd4308', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Treat a goat with a mild limp"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-05 10:47:55+00'),
  ('07b78d7b-e60a-409e-a22d-ea4ffae430ff', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'd6ae4465-c102-4c42-b0fe-3dda82c0afd3', 'task_created', '{"task_title": "Service the wood chipper before hedge-clearing season"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-05 13:30:20+00'),
  ('8f5cfd38-3def-40a4-969b-8ae444504078', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'a4f5452c-ea94-4eda-a157-2589c0bb5809', 'task_created', '{"task_title": "Load the beet truck for the Saturday farmers market"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-05 21:59:00+00'),
  ('e0d8335e-b0a5-4491-b8f1-5ba5230cabfc', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'cb81f8b6-fe00-471f-b2e4-93da0c5548b8', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Replace the tractor''s dead headlight"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-06 15:04:24+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('382990b2-8608-41fb-b86b-d1cba2968999', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '467061a7-f6db-4232-9882-fbd8a2d1c92d', 'task_created', '{"task_title": "Muck out the barn stalls"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-07 12:34:47+00'),
  ('7a84cfac-cc5a-4fcb-a545-1ce01c80db01', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '057885bb-865c-4800-9f27-9c3b934be049', 'task_created', '{"task_title": "Check expiration dates on the emergency ration kits"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-07 14:38:32+00'),
  ('b32215be-5bc4-4876-8baa-0da9204b4eb9', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '5c58efaf-888c-471e-871a-fc4e3d2fbfc8', 'task_due_date_changed', '{"new_due_date": "2026-07-30", "old_due_date": "2026-07-19", "task_title": "Repair the hose reel by the barn"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-07 16:24:21+00'),
  ('dc52db61-e5af-4aaa-a122-f21c08b3765b', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '6114ec78-d2d1-48d8-8c95-5cca2bcb39a4', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Collect eggs from the coop before the raccoons find them first"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-08 14:40:39+00'),
  ('56a293a5-379b-4dc6-ac38-6bf3f0e2eb7c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'location_created', '{"location_id": "0973c219-2cfe-42ac-a524-8e1c7795da3a", "location_name": "Main House"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-08 21:26:55+00'),
  ('349bcd6a-c768-4464-b36f-4e8d009d4569', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'a6269100-8118-4b6a-b398-4289f9b4bada', 'task_created', '{"task_title": "File the farm''s annual tax paperwork"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-09 15:09:04+00'),
  ('5426ae67-c700-44d4-8a10-4de878aa11ec', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'e13f1054-3471-45ad-9776-f01e256571f6', 'task_created', '{"task_title": "Draft a wholesale pitch for the honey line"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-09 17:01:03+00'),
  ('e4af0ac7-6673-4bac-8cbb-de29a3574cb8', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '391a2f94-d078-465e-91db-937ebc233c17', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Replace batteries in the perimeter security cameras"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-10 10:37:08+00'),
  ('371a9a3b-d27b-489c-9ce7-b6dad0ed4fc7', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'bb9cd5be-3e30-4775-88bc-17605fdcfbb0', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Renew the B&B''s county health inspection certificate"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-10 15:11:22+00'),
  ('720b2471-0e61-43fe-a59a-e7cae83ce837', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'fdb8eeac-7605-4d69-b189-a3b156ae10af', 'task_created', '{"task_title": "Chase down payment from a beet buyer who''s gone quiet"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-10 15:51:54+00'),
  ('6152c6bc-9cd1-4504-bd94-da3815f2c448', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'location_created', '{"location_id": "c6132f4e-089e-4f95-bf1d-a88d98ff597a", "location_name": "North Beet Field"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-10 17:18:56+00'),
  ('164172f1-2eb2-4a0b-9e11-3220994eceb9', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '5c58efaf-888c-471e-871a-fc4e3d2fbfc8', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Repair the hose reel by the barn"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 01:55:03+00'),
  ('a58ab02d-0220-4654-813b-a8f3a173c73e', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'location_created', '{"location_id": "70516c49-27aa-4408-8bbc-12ccff39a516", "location_name": "Bunker Entrance"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 06:24:42+00'),
  ('ea264354-6c25-4174-9572-ba8e20e6c5f1', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'location_created', '{"location_id": "7c0e7905-c9bd-4189-ac34-b03e5f94741e", "location_name": "Barn"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 08:39:10+00'),
  ('c8715fd7-d59e-4a03-9bc4-2bb600162b0d', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'a4f5452c-ea94-4eda-a157-2589c0bb5809', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Load the beet truck for the Saturday farmers market"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 09:48:19+00'),
  ('78ef2f81-e3a9-451f-aed8-91025f9cda59', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'location_created', '{"location_id": "ffbc1348-ebdf-472f-a25d-3c27fece7a66", "location_name": "Goat Pen"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 15:01:03+00'),
  ('d1851506-ec5e-42ec-b497-1192be1a8e5c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '6114ec78-d2d1-48d8-8c95-5cca2bcb39a4', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Collect eggs from the coop before the raccoons find them first"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 16:16:59+00'),
  ('554d1c9b-e582-4cdb-b59d-0933f8e9fde6', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '4a1eeaba-71c6-4f42-bf72-5cfd4ded8142', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Cut this year''s corn maze pattern"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 18:48:41+00'),
  ('4ecdbcda-668d-4715-b092-b9df45b6edab', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'location_created', '{"location_id": "27e8ae39-4d92-4f52-9625-3c4cf19f1290", "location_name": "Chicken Coop"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 20:02:49+00'),
  ('1f317ea9-98be-49ca-962e-55d293bf8a75', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '893b2202-d55e-4279-9555-6aa8a2c30c57', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Print tickets for the Halloween haunted house event"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-11 20:40:23+00'),
  ('3e76c48a-2f56-4b41-b57f-a56f225bcb2c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'a6269100-8118-4b6a-b398-4289f9b4bada', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "File the farm''s annual tax paperwork"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 00:41:19+00'),
  ('6fcdecce-5c91-4181-946d-14ccb24a547b', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '8bea4b46-6969-4f42-a676-262121cd4308', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Treat a goat with a mild limp"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 07:01:31+00'),
  ('ef662571-fe87-4120-80c7-57c001adc42c', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'location_created', '{"location_id": "38bcb8d0-1f77-4bf6-ab82-ca3338eb1dde", "location_name": "Cornfield Maze"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 14:11:55+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('332bbc03-433a-4abe-9791-c1dad9192fb5', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '87be8b9a-0893-4d45-86f6-4891dc03f208', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Negotiate the county fair beet booth pricing"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-12 19:58:11+00'),
  ('357fe570-f1ab-4c8a-8b7e-049a5da50066', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '10e9ad27-d6c9-484c-88e8-333ab2787359', 'task_created', '{"task_title": "Spread lime on the acidic patch near the tree line"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 07:14:05+00'),
  ('d797bbec-5955-4257-a844-a2f58b87528a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'location_created', '{"location_id": "25654847-e3eb-43b6-80f3-84c1bcbea603", "location_name": "Root Cellar"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 14:33:22+00'),
  ('35dac59d-f3b8-4f56-8d47-fc55bed086c1', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'location_created', '{"location_id": "2566ba1b-9bb1-4243-a1f5-537ae07940a9", "location_name": "Outhouse"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 15:35:28+00'),
  ('2b5857ad-54ac-4a37-85fe-591865ee1fd6', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', NULL, 'location_created', '{"location_id": "a3f69e4a-7259-4e42-9980-bd0dfb39ae5d", "location_name": "Silo"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 17:06:37+00'),
  ('4809be2a-2d66-40b4-a5db-feff2efcea35', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'd6ae4465-c102-4c42-b0fe-3dda82c0afd3', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Service the wood chipper before hedge-clearing season"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 18:42:44+00'),
  ('a814a02e-5b14-4e91-804b-ffa2217427a0', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'b232b35e-cfb2-49a7-9866-c7bb839b413c', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Sharpen the plow blades before the fall till"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-13 22:41:08+00'),
  ('23fef4dc-0165-41de-a402-47358b8ad07a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '467061a7-f6db-4232-9882-fbd8a2d1c92d', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Muck out the barn stalls"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-14 00:05:41+00'),
  ('2cce5454-1502-49b3-a724-e70b9020b6b3', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', '10e9ad27-d6c9-484c-88e8-333ab2787359', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Spread lime on the acidic patch near the tree line"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-14 08:53:26+00'),
  ('888310c2-a986-4e6a-95c1-f550116d60c1', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'e13f1054-3471-45ad-9776-f01e256571f6', 'task_status_changed', '{"new_status": "in_progress", "old_status": "not_started", "task_title": "Draft a wholesale pitch for the honey line"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-14 16:32:31+00'),
  ('7b14a15b-f931-40f3-9e44-b406c8e8b37a', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'c5753255-55dc-40f5-9f3d-a8d538725321', 'task_status_changed', '{"new_status": "done", "old_status": "not_started", "task_title": "Sharpen the display katana in the great room"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-14 20:51:59+00'),
  ('e575efd4-0c69-4f5a-a71c-ca0d78f746c2', 'd3c5bc02-aa7d-49cd-85b7-1302f1056e0e', 'a4f5452c-ea94-4eda-a157-2589c0bb5809', 'task_status_changed', '{"new_status": "done", "old_status": "in_progress", "task_title": "Load the beet truck for the Saturday farmers market"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-15 06:35:28+00');

COMMIT;
