-- Clarkson's Farm sample data seed
--
-- Populates Chore Corral with themed sample data for the 'Diddly Squat
-- Farm' demo tenant (Jeremy Clarkson's farm in Chipping Norton,
-- Oxfordshire), covering categories, tags, tasks, task_tags, and the
-- activity log.
--
-- DESTRUCTIVE: this script first hard-deletes all existing categories,
-- tags, tasks, task_tags, task_photos, and activity_log rows scoped to
-- the farm below, then reinserts the full sample data set. It is
-- rerunnable -- running it again wipes and reseeds the same farm's data
-- from scratch. It does not touch any other farm's data.
--
-- Apply with the Supabase CLI:
--   supabase db query --linked --file supabase/seeds/clarksons_farm_sample_data.sql

BEGIN;

-- Target farm: Diddly Squat Farm (9a150965-7ecb-4fa8-92e2-524a58343a52)

-- ---------------------------------------------------------------------------
-- Wipe existing farm-scoped data (hard delete, farm-scoped only)
-- ---------------------------------------------------------------------------

DELETE FROM task_photos WHERE task_id IN (SELECT id FROM tasks WHERE farm_id = '9a150965-7ecb-4fa8-92e2-524a58343a52');
DELETE FROM task_tags WHERE task_id IN (SELECT id FROM tasks WHERE farm_id = '9a150965-7ecb-4fa8-92e2-524a58343a52');
DELETE FROM tasks WHERE farm_id = '9a150965-7ecb-4fa8-92e2-524a58343a52';
DELETE FROM tags WHERE farm_id = '9a150965-7ecb-4fa8-92e2-524a58343a52';
DELETE FROM categories WHERE farm_id = '9a150965-7ecb-4fa8-92e2-524a58343a52';
DELETE FROM activity_log WHERE farm_id = '9a150965-7ecb-4fa8-92e2-524a58343a52';

-- ---------------------------------------------------------------------------
-- Farm details
-- ---------------------------------------------------------------------------

UPDATE farms
SET address = 'Diddly Squat Farm, Chipping Norton, Oxfordshire OX7, United Kingdom',
    default_lat = 51.9403,
    default_lng = -1.5449
WHERE id = '9a150965-7ecb-4fa8-92e2-524a58343a52';

-- ---------------------------------------------------------------------------
-- Categories
-- ---------------------------------------------------------------------------

INSERT INTO categories (id, farm_id, name, deleted_at, created_at)
VALUES
  ('02b2b2c8-6330-4dfd-833e-6eb0a4feb940', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Livestock', NULL, '2026-03-20 04:33:30+00'),
  ('6b3f2ef8-9b79-4cfa-bdc0-0978d24d54da', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Arable', NULL, '2026-03-21 02:51:54+00'),
  ('9bdb42e2-9da2-48cf-8488-a8f6042de0c7', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Farm Shop', NULL, '2026-03-21 12:07:04+00'),
  ('dfef6686-51b6-42dc-90a6-5f748dfc873b', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Machinery', NULL, '2026-04-01 05:09:51+00'),
  ('383e8fb7-1891-44a8-86d8-f180ddffc051', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Brewing', NULL, '2026-04-02 12:39:05+00'),
  ('e1817e9f-ed9d-4c5d-9708-1cf24f115696', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Restaurant', NULL, '2026-04-04 05:39:43+00'),
  ('f61404f5-1f6a-439e-a836-036b23998bcf', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Fencing & Walls', NULL, '2026-04-05 22:50:25+00'),
  ('89f49bb0-c2f5-45a8-be09-efb9c618d5d8', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Wilding', NULL, '2026-04-11 10:17:37+00'),
  ('dd4f70d1-eb6d-47f2-9f57-f024ac237097', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Buildings & Infrastructure', NULL, '2026-04-27 16:14:14+00'),
  ('a1990aba-60ed-4374-93fb-c51a21e57d00', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Paperwork & Compliance', NULL, '2026-05-01 21:16:43+00'),
  ('cf9274b2-3cf0-41b1-9592-6a0df9edc782', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Produce & Orchard', NULL, '2026-05-07 17:43:46+00'),
  ('ad637816-7c24-45f9-a8f1-88996e5b76b3', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Water & Drainage', NULL, '2026-06-05 06:17:53+00');

-- ---------------------------------------------------------------------------
-- Tags
-- ---------------------------------------------------------------------------

INSERT INTO tags (id, farm_id, name, created_at)
VALUES
  ('5c92725b-f19b-48c4-a4bf-c7bb3063c21a', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'kaleb', '2026-03-16 14:17:11+00'),
  ('0a800e55-b0b7-447d-b8d2-5fd0bf4e0cd4', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'gerald', '2026-03-20 11:39:59+00'),
  ('0a44d474-8919-4816-94c0-7d52433c5e86', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'lisa', '2026-03-23 18:29:37+00'),
  ('0103e8aa-d950-4d34-8cf2-fa129059cb3b', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'charlie', '2026-03-24 05:33:25+00'),
  ('4f3cf8d0-f8ea-4fd7-a9b1-d8bdef23fddc', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'sheep', '2026-03-28 20:09:01+00'),
  ('62f42e63-15c4-4951-b190-04da532189d3', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'pigs', '2026-03-30 15:14:07+00'),
  ('218ea584-b6c4-45cd-b991-3035bcfe5dc4', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'cows', '2026-04-02 08:13:37+00'),
  ('ab7f9da7-97ae-4d6b-b7e4-fda730601666', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'hens', '2026-04-03 02:43:51+00'),
  ('38100250-d759-4270-9747-2e90f2db7485', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'bees', '2026-04-04 04:20:03+00'),
  ('77905706-c566-4f69-9e77-2321a6710380', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'goats', '2026-04-08 13:43:55+00'),
  ('9845b2e2-46a4-4564-9e89-3279aff74c62', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'tractor', '2026-04-14 12:35:13+00'),
  ('2f568bdf-bd28-4c8f-bf92-6ddb09df036c', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'lamborghini', '2026-04-15 08:03:58+00'),
  ('12770790-5929-4647-8051-95df70040638', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'drilling', '2026-04-21 16:07:47+00'),
  ('ad20c5e0-075a-4a52-9ebb-cac41baf3eba', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'harvest', '2026-04-22 22:39:02+00'),
  ('95c7df1e-ec62-47b1-83d3-a046b7e96b00', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'spring-barley', '2026-04-26 03:26:05+00'),
  ('d1695b8b-839f-4ce4-ac7d-28e663f166ae', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'durum-wheat', '2026-04-26 18:55:36+00'),
  ('733cf027-2a1b-41d9-96b6-0d1a5ee6d95c', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'oilseed-rape', '2026-04-27 03:19:39+00'),
  ('5a273c53-c4b7-4da6-a2a2-82163ef344b6', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'potatoes', '2026-04-28 14:04:58+00'),
  ('5119df37-f637-415e-a56b-c75c44edc239', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'wasabi', '2026-04-29 12:16:42+00'),
  ('d8bf7db0-f33c-47b5-aa74-5bb47e959be7', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'hawkstone', '2026-05-05 16:45:23+00'),
  ('6c48e497-7c66-438d-a31c-cbc50961f753', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'farm-shop', '2026-05-08 06:58:27+00'),
  ('3002974c-ec62-4494-87d4-08becbbc357f', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'council', '2026-05-08 08:27:45+00'),
  ('a077d6fd-b9de-457c-a30f-6b53dac0eace', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'planning', '2026-05-10 12:38:44+00'),
  ('c1dae030-60c7-475e-b47d-595a46e10e5a', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'tb-testing', '2026-05-11 06:18:35+00'),
  ('dd0303cf-004e-4e35-9e38-4e6352fc9915', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'mushrooms', '2026-05-19 16:38:39+00'),
  ('e6c23750-77f1-4a92-9147-a1479f585466', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'spring-water', '2026-05-20 09:40:56+00'),
  ('e7e7ec5c-737b-499e-bb45-8ff0b8e1d2dd', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'badgers', '2026-05-21 02:56:59+00'),
  ('b74f7192-5ce7-46a0-80c9-500b827aef18', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'hedgerows', '2026-05-24 00:57:54+00'),
  ('340189d3-96b6-4eab-81d1-6e95944e9877', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'dry-stone-walls', '2026-05-24 13:20:28+00'),
  ('1aa4006e-ae9a-43ed-a7f4-512177edfd49', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'rewilding', '2026-05-27 20:05:53+00'),
  ('04d00a81-eeb3-46d3-9916-97ff5d94b306', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'restaurant', '2026-05-28 02:35:22+00'),
  ('ccb5ee3c-5fb5-4a28-9039-b648e67c9a40', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'chadlington', '2026-06-04 19:06:14+00'),
  ('c1fc11bc-1317-4c8c-bcb4-4e7661ccb843', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'red-tape', '2026-06-05 09:31:33+00'),
  ('b5596c10-d2d8-4c2c-947f-808f51cb5817', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'diversification', '2026-06-10 13:27:57+00'),
  ('55a69b01-012a-4b7c-b9ec-aee354b4d80a', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'sunflowers', '2026-06-12 13:04:30+00'),
  ('cb295e69-16db-4c5f-992f-2944e7ae97fb', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'muck-spreading', '2026-06-21 11:07:34+00');

-- ---------------------------------------------------------------------------
-- Tasks
-- ---------------------------------------------------------------------------

INSERT INTO tasks (id, farm_id, title, category_id, priority, status, due_date, notes, lat, lng, created_at, created_by, completed_at)
VALUES
  ('8b888e5f-4f9d-4610-a82a-c5f6d1dd4439', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Sow the sunflower strip for the pollinators', '6b3f2ef8-9b79-4cfa-bdc0-0978d24d54da', 'urgent', 'done', '2026-09-20', NULL, 51.950474, -1.537992, '2026-03-15 23:01:26+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-01 19:19:57+00'),
  ('b6d72a18-c669-4429-a4c1-04075b0f7900', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Update the farm''s public liability insurance for the new restaurant', 'a1990aba-60ed-4374-93fb-c51a21e57d00', 'whenever', 'not_started', '2026-10-19', NULL, NULL, NULL, '2026-03-17 03:33:50+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('7913e91f-ebbd-44c1-942d-38127bd15791', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Settle the argument about whether it''s a farm or a theme park now', NULL, 'soon', 'in_progress', '2026-05-20', 'Ongoing. No resolution expected.', 51.943301, -1.541032, '2026-03-19 20:47:03+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('1d349076-bfec-4983-8af5-5a532ca4d6c9', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Fix the fence the cows keep leaning through', 'f61404f5-1f6a-439e-a836-036b23998bcf', 'soon', 'not_started', '2026-09-28', 'Needs doing before the weekend crowd arrives.', NULL, NULL, '2026-03-20 02:00:46+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('325d87d2-89a0-47ec-9095-69010dbff2ac', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Fix the burst pipe near the wasabi polytunnel', 'ad637816-7c24-45f9-a8f1-88996e5b76b3', 'whenever', 'not_started', '2026-05-27', 'Charlie flagged this as urgent, for once.', NULL, NULL, '2026-03-20 15:07:40+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('2207129d-0477-4549-b065-e3195fb9b14b', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Finalise the restaurant menu with the wasabi mash', 'e1817e9f-ed9d-4c5d-9708-1cf24f115696', 'urgent', 'not_started', '2026-10-11', NULL, NULL, NULL, '2026-03-22 06:24:11+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('d649a01b-e70a-4d52-973f-09af3f993a9e', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Check for badger setts near the cattle troughs', '02b2b2c8-6330-4dfd-833e-6eb0a4feb940', 'urgent', 'in_progress', '2026-07-28', 'Charlie flagged this as urgent, for once.', NULL, NULL, '2026-03-22 16:47:29+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('a209876c-e5c2-456b-ae6b-0756ad44c46e', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Separate Leonardo DiCaprio from the ewes ahead of tupping season', '02b2b2c8-6330-4dfd-833e-6eb0a4feb940', 'whenever', 'done', NULL, 'Gerald says it''ll take ''as long as it takes''.', NULL, NULL, '2026-03-22 18:58:11+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-08 11:57:37+00'),
  ('76e1886d-048e-4e44-bd7c-8bf413672c7e', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Order more hops for the next Hawkstone brew', '383e8fb7-1891-44a8-86d8-f180ddffc051', 'urgent', 'not_started', '2026-05-08', NULL, 51.950708, -1.546697, '2026-03-23 00:25:24+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('00be8248-c24d-4a60-9a40-0b03131194c1', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Chase Cheerful Charlie for the updated land agent report', 'a1990aba-60ed-4374-93fb-c51a21e57d00', 'soon', 'in_progress', '2026-10-16', 'Charlie''s cheerful about everything except the paperwork backlog.', NULL, NULL, '2026-03-23 09:26:11+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('449181e4-c850-4ffe-838b-05f73faa9e55', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Bottle the latest batch of Hawkstone cider', '383e8fb7-1891-44a8-86d8-f180ddffc051', 'urgent', 'done', NULL, NULL, 51.941369, -1.541357, '2026-03-23 19:57:33+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-24 07:42:49+00'),
  ('86351466-1ef7-48f6-9f4b-3912626395c1', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Shear the flock before the heatwave', '02b2b2c8-6330-4dfd-833e-6eb0a4feb940', 'soon', 'done', '2026-07-07', 'Kaleb says we''ve left it late. Kaleb is always right about this sort of thing, annoyingly.', NULL, NULL, '2026-03-25 03:14:24+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-28 11:37:59+00'),
  ('4e73fa1a-43b4-4537-ae17-4ab171ae6f9a', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Design new labels for the Hawkstone cider bottles', '383e8fb7-1891-44a8-86d8-f180ddffc051', 'whenever', 'done', NULL, NULL, NULL, NULL, '2026-03-28 18:01:26+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-11 07:20:46+00'),
  ('7306a62f-ac22-46da-982c-7ca18c431a21', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Taste-test the new potato and wasabi side dish', 'e1817e9f-ed9d-4c5d-9708-1cf24f115696', 'whenever', 'in_progress', '2026-09-06', 'Verdict: surprisingly good. Kaleb had three helpings.', NULL, NULL, '2026-03-29 21:09:42+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('a2b9fe03-fbbd-48a9-b4e9-4172271b9bf9', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Check the flock for flystrike after the warm spell', '02b2b2c8-6330-4dfd-833e-6eb0a4feb940', 'soon', 'not_started', '2026-10-27', 'Kaleb reckons it''s the worst he''s seen it. Smells about right too.', 51.950102, -1.537061, '2026-04-02 04:38:31+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('0df5bdde-0254-4746-81cc-dd8f715b58df', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Coppice a section of the wilding woodland', '89f49bb0-c2f5-45a8-be09-efb9c618d5d8', 'whenever', 'not_started', '2026-05-25', 'Charlie flagged this as urgent, for once.', NULL, NULL, '2026-04-04 05:33:10+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('83d0b568-f631-4eff-8ad7-65ea9a19ce4f', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Fix the restaurant kitchen''s extractor fan', 'e1817e9f-ed9d-4c5d-9708-1cf24f115696', 'urgent', 'done', '2026-07-05', NULL, NULL, NULL, '2026-04-04 09:14:53+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 09:54:56+00'),
  ('52b209e3-6755-4087-ac73-0f6e76241f7d', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Restock the farm shop shelves before the Saturday rush', '9bdb42e2-9da2-48cf-8488-a8f6042de0c7', 'whenever', 'not_started', '2026-06-19', NULL, 51.930014, -1.552918, '2026-04-05 01:19:25+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('f2896d0f-8d44-46cb-a98c-bb19e92b2b32', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Fix the loader that Jeremy reversed into the barn wall', 'dfef6686-51b6-42dc-90a6-5f748dfc873b', 'urgent', 'done', NULL, 'Ask him about it and he''ll say ''it was already like that''.', 51.935683, -1.538925, '2026-04-05 06:15:43+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-06 23:26:29+00'),
  ('38c4dc22-09f3-4e4b-ba27-be110a06239a', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Chase the brewery about the delayed Hawkstone delivery', '383e8fb7-1891-44a8-86d8-f180ddffc051', 'whenever', 'not_started', '2026-08-27', 'Jeremy has opinions about this. Strong ones.', NULL, NULL, '2026-04-05 07:41:32+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL);

INSERT INTO tasks (id, farm_id, title, category_id, priority, status, due_date, notes, lat, lng, created_at, created_by, completed_at)
VALUES
  ('c6404a5a-b75a-45ee-84bf-d3e18f1e9d8f', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Reorder Hawkstone lager for the shop fridge', '9bdb42e2-9da2-48cf-8488-a8f6042de0c7', 'urgent', 'not_started', '2026-05-25', NULL, 51.941961, -1.549973, '2026-04-05 23:52:12+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('262f84fb-2b85-4f4a-ae8b-cf52a251100b', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Get the baler fixed before the hay''s ready', 'dfef6686-51b6-42dc-90a6-5f748dfc873b', 'soon', 'done', NULL, NULL, 51.931284, -1.540372, '2026-04-06 16:01:53+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-15 17:51:41+00'),
  ('e9cbadd1-0785-4068-b608-f4789a348514', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Clear the drainage ditch along the bottom field before the rain sets in', 'ad637816-7c24-45f9-a8f1-88996e5b76b3', 'urgent', 'done', '2026-07-03', 'Kaleb''s on it, allegedly.', NULL, NULL, '2026-04-06 16:26:11+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 07:03:17+00'),
  ('0cde65cd-18e8-4915-941f-f9831df968f6', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Move Wayne Rooney to the top field before he does something biblical', '02b2b2c8-6330-4dfd-833e-6eb0a4feb940', 'whenever', 'done', '2026-08-24', 'He head-butted the quad bike again. Twice. On purpose.', NULL, NULL, '2026-04-06 17:26:54+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-28 06:48:19+00'),
  ('4363f7b0-5bbf-4b1a-93f5-adb43c8ff3b5', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Dig the first potatoes for the farm shop', '6b3f2ef8-9b79-4cfa-bdc0-0978d24d54da', 'soon', 'in_progress', '2026-05-12', NULL, NULL, NULL, '2026-04-09 00:26:21+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('fed190df-6edb-4cb7-9776-5b247ff4daf7', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Meet the wildlife trust about the rewilding grant', '89f49bb0-c2f5-45a8-be09-efb9c618d5d8', 'whenever', 'done', NULL, 'They love the badgers. Jeremy has more complicated feelings about the badgers.', NULL, NULL, '2026-04-09 16:09:49+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-18 23:29:11+00'),
  ('f3d99c99-19db-4630-b0bd-ecb47e0e161b', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Get the TB testing paperwork filed with the vet', 'a1990aba-60ed-4374-93fb-c51a21e57d00', 'soon', 'not_started', '2026-05-16', NULL, 51.945094, -1.534276, '2026-04-10 08:20:31+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('d093ea2e-9aa1-4661-b2a9-c1cc6e0ca2fb', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Replace the gate Jeremy reversed the pickup into', 'f61404f5-1f6a-439e-a836-036b23998bcf', 'soon', 'not_started', '2026-10-23', 'He blamed the gate for ''jumping out'' at him.', NULL, NULL, '2026-04-13 00:40:01+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('0083dfe0-6b39-4c68-941a-5798248f4083', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Test the wasabi polytunnel''s water temperature', '6b3f2ef8-9b79-4cfa-bdc0-0978d24d54da', 'whenever', 'not_started', '2026-07-08', 'Wasabi is fussier than a Michelin-star chef about its water. Charlie is not thrilled at the running costs.', 51.940311, -1.545049, '2026-04-13 05:08:35+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('425b1864-9b4e-48b0-9d0d-4df50557b6f0', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Deep clean the farm shop fridge before the food hygiene inspection', '9bdb42e2-9da2-48cf-8488-a8f6042de0c7', 'soon', 'not_started', '2026-09-11', NULL, NULL, NULL, '2026-04-14 06:46:14+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('266e0fe8-1a03-433b-874d-382523643f71', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Figure out why there''s a goat in the farm shop again', NULL, 'whenever', 'done', NULL, 'Second time this week. Lisa is losing her patience.', NULL, NULL, '2026-04-14 10:56:23+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 15:55:14+00'),
  ('ff43a1e1-5236-4b35-926c-a9f7ed2cb804', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Get quotes for repairing the farmyard''s crumbling wall', 'dd4f70d1-eb6d-47f2-9f57-f024ac237097', 'whenever', 'not_started', NULL, 'Kaleb''s on it, allegedly.', NULL, NULL, '2026-04-15 04:24:56+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('a920d3b8-27fc-443b-85a0-3c0b699f4e9e', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Install a new borehole pump for the spring water bottling plant', 'ad637816-7c24-45f9-a8f1-88996e5b76b3', 'soon', 'done', NULL, NULL, 51.930231, -1.555943, '2026-04-15 15:31:35+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-09 07:28:06+00'),
  ('c235f92f-0e0a-4f89-aea7-fba941d57a8f', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Draft the Chadlington village fete stall plan', NULL, 'soon', 'in_progress', '2026-10-04', 'Charlie flagged this as urgent, for once.', 51.938669, -1.549164, '2026-04-15 19:48:47+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('14f9d8c5-2fb4-436b-b3ed-625e3ecbdd0a', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Repair the storm-damaged stretch of dry-stone wall by the road', 'f61404f5-1f6a-439e-a836-036b23998bcf', 'urgent', 'done', NULL, 'Gerald says it''ll take ''as long as it takes''.', 51.934309, -1.554708, '2026-04-18 15:37:25+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-18 10:08:07+00'),
  ('421f6574-be03-4998-9b4c-9b82ef10b225', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'File the DEFRA subsidy paperwork before the deadline', 'a1990aba-60ed-4374-93fb-c51a21e57d00', 'urgent', 'in_progress', '2026-09-26', NULL, NULL, NULL, '2026-04-18 22:41:10+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('87d5b11a-fba9-4706-8bfe-3b03c4c7c330', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Count the Oxford Sandy and Blacks, again, because Jeremy keeps losing track', '02b2b2c8-6330-4dfd-833e-6eb0a4feb940', 'soon', 'not_started', '2026-06-09', 'There are meant to be fourteen. There are eleven. Nobody knows where three pigs have gone.', NULL, NULL, '2026-04-19 02:22:52+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('b693dd75-691c-47db-8775-61474449216a', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'TB test the whole herd, brace for bad news', '02b2b2c8-6330-4dfd-833e-6eb0a4feb940', 'whenever', 'not_started', NULL, 'Vet''s coming Tuesday. Kaleb is not optimistic given the badger activity up by the top wood.', NULL, NULL, '2026-04-21 18:33:00+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('cfbf5b85-b093-4bdd-ac8b-9758ebfde113', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Survey the wilding area for returning birdlife', '89f49bb0-c2f5-45a8-be09-efb9c618d5d8', 'soon', 'done', '2026-10-15', 'Gerald says it''ll take ''as long as it takes''.', NULL, NULL, '2026-04-23 00:34:36+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-26 12:42:56+00'),
  ('bfbb97cb-bec4-4ca7-a2e6-59de8425c41d', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Change the oil on the Lamborghini before the big drilling push', 'dfef6686-51b6-42dc-90a6-5f748dfc873b', 'whenever', 'done', NULL, NULL, 51.951386, -1.536837, '2026-04-23 19:19:56+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-19 07:27:17+00');

INSERT INTO tasks (id, farm_id, title, category_id, priority, status, due_date, notes, lat, lng, created_at, created_by, completed_at)
VALUES
  ('7dcb7da4-e743-49c6-be5b-48a0e634df12', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Lay the hedge along the bottom lane before the birds nest', 'f61404f5-1f6a-439e-a836-036b23998bcf', 'soon', 'in_progress', '2026-08-20', 'Jeremy has opinions about this. Strong ones.', NULL, NULL, '2026-04-25 01:31:39+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('1198318c-7158-44c6-96a8-2adef6f77ced', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Harvest the spring barley, weather permitting', '6b3f2ef8-9b79-4cfa-bdc0-0978d24d54da', 'soon', 'done', '2026-07-12', NULL, 51.942105, -1.534081, '2026-04-25 04:06:19+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-31 00:59:06+00'),
  ('fce5719d-b10b-4642-95f9-e8988ede5bd3', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Redesign the farm shop layout so people stop nicking the honey', '9bdb42e2-9da2-48cf-8488-a8f6042de0c7', 'soon', 'in_progress', NULL, 'Lisa''s had enough. CCTV goes up this week.', 51.952290, -1.540765, '2026-04-27 11:06:58+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('f6c52ad6-878b-4cc5-b62a-caf5bfe1ccd2', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Harvest the chillis and box them for the shop', 'cf9274b2-3cf0-41b1-9592-6a0df9edc782', 'soon', 'not_started', NULL, NULL, NULL, NULL, '2026-04-27 13:23:56+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('7a53d5ad-cd9c-485d-86a6-a9b2bc0c180a', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Ask Kaleb what he actually meant by ''that''ll be reet''', NULL, 'urgent', 'in_progress', '2026-08-10', NULL, 51.934768, -1.555934, '2026-04-28 11:10:18+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('de2c3402-541c-42f8-a07f-77f14a1ee46f', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Clear invasive scrub from the rewilding margin', '89f49bb0-c2f5-45a8-be09-efb9c618d5d8', 'soon', 'not_started', '2026-05-19', NULL, 51.946450, -1.545608, '2026-04-30 05:46:33+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('f29faa65-a7bf-4971-9e7a-429480a8aa0d', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Wash the Lamborghini down after the muck-spreading disaster', 'dfef6686-51b6-42dc-90a6-5f748dfc873b', 'soon', 'not_started', '2026-07-01', 'It went everywhere. Genuinely everywhere. There is muck on the roof.', NULL, NULL, '2026-05-02 11:02:35+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('f0490172-a786-427f-b869-110434a50234', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Sort out the leaking roof on the lambing barn', 'dd4f70d1-eb6d-47f2-9f57-f024ac237097', 'whenever', 'in_progress', '2026-09-18', NULL, 51.943936, -1.534914, '2026-05-02 17:23:34+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('b353331c-7319-48cc-9d46-bda76d70a844', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Order more blackthorn whips for the hedge-laying', 'f61404f5-1f6a-439e-a836-036b23998bcf', 'soon', 'done', '2026-07-05', 'Kaleb''s on it, allegedly.', 51.932656, -1.542852, '2026-05-03 00:48:35+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-18 00:35:11+00'),
  ('a14a9aaf-f38a-4492-b628-9b62b8d99344', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Fit new shelving in the mushroom bunker', 'dd4f70d1-eb6d-47f2-9f57-f024ac237097', 'soon', 'in_progress', '2026-05-11', 'Gerald says it''ll take ''as long as it takes''.', 51.943535, -1.545099, '2026-05-04 23:51:03+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('57e8da24-e22d-468b-b33d-0002b582fb32', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Sort the diversification ideas list before the next Charlie meeting', NULL, 'soon', 'done', NULL, NULL, NULL, NULL, '2026-05-05 03:18:00+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-27 21:59:07+00'),
  ('fa9a9337-a19d-4b0d-91d6-8c1a2597f824', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Unblock the culvert under the Chadlington road', 'ad637816-7c24-45f9-a8f1-88996e5b76b3', 'urgent', 'in_progress', '2026-07-02', 'Gerald says it''ll take ''as long as it takes''.', 51.930490, -1.548549, '2026-05-05 12:45:14+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('33569d86-4381-4a23-889f-4a3c5c060adb', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Chase down a buyer for the durum wheat', '6b3f2ef8-9b79-4cfa-bdc0-0978d24d54da', 'soon', 'not_started', '2026-09-11', 'Apparently everyone wants it for pasta. Who knew Chipping Norton would end up feeding Italy.', NULL, NULL, '2026-05-05 15:00:01+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('5d36be63-a9bf-4d0f-9db2-5b9c7e4366e6', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Reinforce the wartime bunker roof before the mushroom crop goes in', 'dd4f70d1-eb6d-47f2-9f57-f024ac237097', 'soon', 'not_started', NULL, NULL, 51.936299, -1.540817, '2026-05-05 19:39:46+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('48d67393-c691-45e3-a97a-da3cf89b8964', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Plant the potatoes in the field behind the lambing barn', '6b3f2ef8-9b79-4cfa-bdc0-0978d24d54da', 'urgent', 'in_progress', '2026-05-27', NULL, NULL, NULL, '2026-05-06 01:54:17+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('089a1cbf-500d-4136-8f7e-3ceae315b872', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Check the wasabi tunnel''s shading before the hot weather', 'cf9274b2-3cf0-41b1-9592-6a0df9edc782', 'soon', 'in_progress', '2026-06-13', 'Needs doing before the weekend crowd arrives.', NULL, NULL, '2026-05-07 03:44:04+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('2867b9e7-fad5-450b-9744-2c14e5753e35', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Insulate the honey extraction room', 'dd4f70d1-eb6d-47f2-9f57-f024ac237097', 'soon', 'not_started', '2026-07-29', 'Gerald says it''ll take ''as long as it takes''.', NULL, NULL, '2026-05-07 23:55:23+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('17c992eb-83ad-4153-b671-98e2f2ac78a1', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Fence off the rewilding block from the sheep', '89f49bb0-c2f5-45a8-be09-efb9c618d5d8', 'whenever', 'not_started', '2026-07-20', NULL, 51.948886, -1.548985, '2026-05-08 08:53:03+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('c57f1e7b-328c-4b7f-8405-67683058b1c7', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Put up stock fencing around the new wilding block', 'f61404f5-1f6a-439e-a836-036b23998bcf', 'soon', 'done', NULL, NULL, 51.944948, -1.549983, '2026-05-08 11:19:00+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-29 01:27:15+00'),
  ('de80406b-f3f3-47e5-9d82-cbfc5a6d3634', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Sort out the car park overflow for the farm shop', '9bdb42e2-9da2-48cf-8488-a8f6042de0c7', 'whenever', 'done', NULL, 'Needs doing before the weekend crowd arrives.', 51.950985, -1.537374, '2026-05-08 23:34:45+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-11 09:35:31+00');

INSERT INTO tasks (id, farm_id, title, category_id, priority, status, due_date, notes, lat, lng, created_at, created_by, completed_at)
VALUES
  ('1507c8f4-098a-444a-ac87-a0795b97d922', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Prune the orchard trees before the sap rises', 'cf9274b2-3cf0-41b1-9592-6a0df9edc782', 'urgent', 'not_started', '2026-06-30', 'Charlie flagged this as urgent, for once.', NULL, NULL, '2026-05-13 12:47:33+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('1da59239-ba48-45ba-b689-50c429b2cf97', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Submit the revised planning application to West Oxfordshire council', 'a1990aba-60ed-4374-93fb-c51a21e57d00', 'whenever', 'not_started', NULL, 'Charlie''s drafted it twice already. Third time''s the charm, allegedly.', NULL, NULL, '2026-05-14 03:05:16+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('0d7c1e0c-4bb5-4173-b276-828eb3821ec8', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Spray the oilseed rape for flea beetle before it''s too late', '6b3f2ef8-9b79-4cfa-bdc0-0978d24d54da', 'urgent', 'done', '2026-10-08', 'Flea beetle absolutely hammered it last year. Not doing that again.', NULL, NULL, '2026-05-15 04:20:32+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-25 12:50:16+00'),
  ('5002f6cb-df91-4c6b-8bbf-350a50b7d800', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Pick the first apples for the farm shop cider press', 'cf9274b2-3cf0-41b1-9592-6a0df9edc782', 'soon', 'done', NULL, NULL, NULL, NULL, '2026-05-18 00:18:41+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-23 06:23:20+00'),
  ('4c60525c-9758-4637-871d-70b759f74ad1', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Stock the shop with the new wasabi mayonnaise', '9bdb42e2-9da2-48cf-8488-a8f6042de0c7', 'soon', 'not_started', '2026-05-21', NULL, NULL, NULL, '2026-05-18 13:46:12+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('330c9017-aa3f-417b-854c-be8f9e390b34', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Fox-proof the hen run after last night''s carnage', '02b2b2c8-6330-4dfd-833e-6eb0a4feb940', 'soon', 'in_progress', '2026-09-01', 'Lost four. Gerald says it''s a dog fox, bold as brass, seen him in daylight.', NULL, NULL, '2026-05-18 18:35:47+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('60e9e897-ea3f-4f7c-8726-4c4717b2396e', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Renew the food hygiene certificate for the farm shop', 'a1990aba-60ed-4374-93fb-c51a21e57d00', 'soon', 'done', '2026-10-12', 'Kaleb''s on it, allegedly.', NULL, NULL, '2026-05-19 00:59:10+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-14 19:14:06+00'),
  ('37ad0903-cba8-4d46-ab97-de3be51ac570', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Re-lay the dry-stone wall along the top field', 'f61404f5-1f6a-439e-a836-036b23998bcf', 'urgent', 'done', '2026-07-19', 'Gerald''s been at it three weeks and won''t be rushed. Fair enough, it''ll outlive all of us.', NULL, NULL, '2026-05-20 20:26:16+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 22:50:15+00'),
  ('d991b695-a2de-4ba1-ab94-353fc01f88df', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Fix the bottling line before it jams again', '383e8fb7-1891-44a8-86d8-f180ddffc051', 'whenever', 'done', NULL, 'Charlie flagged this as urgent, for once.', NULL, NULL, '2026-05-21 09:31:07+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-07 12:24:27+00'),
  ('0fd333a8-5f3d-4ae9-97f7-388159c107b8', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Fix the pig fence the boar keeps flattening', '02b2b2c8-6330-4dfd-833e-6eb0a4feb940', 'urgent', 'in_progress', '2026-08-03', 'Third time this month. He''s basically a small tank.', 51.941502, -1.545984, '2026-05-22 04:01:34+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('3843c43f-c965-47fb-a7d7-eb106df80a1e', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Track down the missing dry-stone wall hammer Gerald swears he left ''right there''', NULL, 'whenever', 'done', NULL, 'Needs doing before the weekend crowd arrives.', NULL, NULL, '2026-05-22 10:57:34+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-25 14:50:41+00'),
  ('75eb37d3-5c75-41eb-a018-78f931ce171a', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Collect eggs and restock the honesty box by the gate', '02b2b2c8-6330-4dfd-833e-6eb0a4feb940', 'soon', 'done', NULL, NULL, NULL, NULL, '2026-05-22 22:45:42+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-14 00:24:47+00'),
  ('c10eccb9-b891-4bfa-87f2-6b5524df6568', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Get the new Hawkstone lager batch tested for quality', '383e8fb7-1891-44a8-86d8-f180ddffc051', 'urgent', 'done', NULL, 'Kaleb''s unofficial quality control involves drinking three pints ''for research''.', 51.935848, -1.549141, '2026-05-23 18:00:42+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 22:39:07+00'),
  ('5171ec7d-6fcf-4e48-b54b-ebca3674a0c4', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Negotiate with the council over the farm shop''s opening hours', '9bdb42e2-9da2-48cf-8488-a8f6042de0c7', 'soon', 'done', '2026-09-03', 'Same argument as last year. Different council officer, same objections.', 51.951584, -1.547200, '2026-05-25 01:53:57+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 00:08:27+00'),
  ('c4f52b4d-33c0-4689-a045-6ce7a2c66cf9', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Fix the barn door that won''t close since the storm', 'dd4f70d1-eb6d-47f2-9f57-f024ac237097', 'whenever', 'not_started', '2026-07-01', NULL, 51.940650, -1.533185, '2026-05-25 23:10:16+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('def49c6b-c615-45bb-a351-b8b632e496b1', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Test the spring water for mineral content before bottling', 'ad637816-7c24-45f9-a8f1-88996e5b76b3', 'soon', 'not_started', NULL, NULL, NULL, NULL, '2026-05-28 13:16:25+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('562200f6-487b-4a66-b56c-8be4c8740b54', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Work out what to do with the field the council won''t let us touch', NULL, 'soon', 'not_started', NULL, NULL, NULL, NULL, '2026-05-31 15:29:09+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('ab5dc91f-f2d3-4fff-9973-16d54b889571', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Plant the wildflower mix on the rewilding strip', '89f49bb0-c2f5-45a8-be09-efb9c618d5d8', 'urgent', 'done', NULL, NULL, NULL, NULL, '2026-05-31 21:08:10+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-13 03:02:33+00'),
  ('84ea9594-8e27-4c29-a878-5f1f5e7610ba', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Check the cattle trough float valves across the whole farm', 'ad637816-7c24-45f9-a8f1-88996e5b76b3', 'whenever', 'done', '2026-10-22', NULL, 51.944084, -1.543878, '2026-06-02 04:21:21+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-13 09:57:07+00'),
  ('9835771d-165f-49df-9fb9-b6f4a5fb0657', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Get the Lamborghini R8 tractor''s hydraulics looked at', 'dfef6686-51b6-42dc-90a6-5f748dfc873b', 'soon', 'in_progress', '2026-07-22', 'Making a noise Jeremy describes as ''expensive''.', NULL, NULL, '2026-06-03 05:13:20+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL);

INSERT INTO tasks (id, farm_id, title, category_id, priority, status, due_date, notes, lat, lng, created_at, created_by, completed_at)
VALUES
  ('02bb6df3-e199-4d2f-8b8a-0170ec0ad633', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Rewire the old cow shed before the inspector visits', 'dd4f70d1-eb6d-47f2-9f57-f024ac237097', 'whenever', 'not_started', '2026-10-13', NULL, 51.938218, -1.552398, '2026-06-03 07:55:52+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('3fc504df-9b42-44c9-8f89-aee29273e1db', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Sort the chilli harvest into mild, hot, and ''why did we grow these''', '6b3f2ef8-9b79-4cfa-bdc0-0978d24d54da', 'urgent', 'in_progress', '2026-10-07', 'Kaleb ate one raw on a dare. He is fine. Mostly.', 51.936983, -1.538745, '2026-06-05 12:30:22+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('a114ff84-b8fa-41e3-bf9a-bfa798e89178', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Find out where the missing set of keys to the Lamborghini went', NULL, 'urgent', 'not_started', '2026-08-04', 'Needs doing before the weekend crowd arrives.', NULL, NULL, '2026-06-06 07:39:55+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('c6d24c9f-a750-4396-b316-9bfc89c7c233', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Appeal the council''s decision on the restaurant planning', 'a1990aba-60ed-4374-93fb-c51a21e57d00', 'whenever', 'in_progress', '2026-07-13', 'Charlie thinks we have a decent shot on appeal. Jeremy thinks the council ''just enjoys saying no''.', 51.943310, -1.538660, '2026-06-06 17:27:04+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('f37a340a-03b0-41fd-9591-4bb4686d5df5', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Rebuild the goat pen after the great escape into the wildflower meadow', '02b2b2c8-6330-4dfd-833e-6eb0a4feb940', 'soon', 'not_started', NULL, 'They ate an entire row of sunflowers. Every single one.', NULL, NULL, '2026-06-07 15:42:50+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('ad374ed3-241e-411c-b686-873c5d85b573', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Plant a new row of fruit trees along the orchard boundary', 'cf9274b2-3cf0-41b1-9592-6a0df9edc782', 'urgent', 'in_progress', '2026-06-05', NULL, 51.933185, -1.543719, '2026-06-08 00:14:34+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('d662c48c-3b93-469a-a66c-4f5370461c05', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Service the quad bikes before lambing', 'dfef6686-51b6-42dc-90a6-5f748dfc873b', 'whenever', 'done', '2026-08-03', NULL, 51.950564, -1.546385, '2026-06-09 01:36:09+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-14 23:10:36+00'),
  ('e686e3cd-3c71-4fe9-b8ba-d1b1e8ee93c5', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Bottle the first run of spring water for sale', 'ad637816-7c24-45f9-a8f1-88996e5b76b3', 'soon', 'not_started', '2026-09-20', 'Charlie thinks it''s a great diversification. Jeremy thinks it''s ''just tap water with better branding''.', NULL, NULL, '2026-06-12 15:40:06+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('755097cb-6db8-4158-ae7a-c1f31335d2f5', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Fix the leaking farm shop roof before the next storm', '9bdb42e2-9da2-48cf-8488-a8f6042de0c7', 'soon', 'in_progress', NULL, 'Third bucket this month. Someone needs to get up there with a proper look, not just a tarp.', NULL, NULL, '2026-06-14 16:04:28+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('e8a16810-3187-4acb-a2f2-984516f23a0e', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Interview chefs for the farm restaurant', 'e1817e9f-ed9d-4c5d-9708-1cf24f115696', 'soon', 'not_started', '2026-05-20', NULL, NULL, NULL, '2026-06-18 03:13:24+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('4107d0b4-dbc5-45e5-8ee1-185fcbc4aa19', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Source local suppliers for the restaurant''s beef and pork', 'e1817e9f-ed9d-4c5d-9708-1cf24f115696', 'whenever', 'in_progress', '2026-06-09', 'Kaleb''s on it, allegedly.', NULL, NULL, '2026-06-21 09:52:36+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('f946b348-9353-49b1-a4a0-c801257968ad', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Harvest the first wasabi crop and get it to the restaurant', '6b3f2ef8-9b79-4cfa-bdc0-0978d24d54da', 'whenever', 'in_progress', '2026-10-27', NULL, NULL, NULL, '2026-06-22 04:30:09+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('0e4b48d5-cfbd-4716-bb11-c0831f473ad4', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Sort the restaurant''s planning permission paperwork', 'e1817e9f-ed9d-4c5d-9708-1cf24f115696', 'soon', 'in_progress', '2026-07-15', 'Charlie says the council will ''need convincing''. Charlie always says that.', NULL, NULL, '2026-06-22 13:54:15+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('734784e0-3fd7-46c3-86e4-050690614a43', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Net the soft fruit before the birds get there first', 'cf9274b2-3cf0-41b1-9592-6a0df9edc782', 'soon', 'not_started', '2026-06-29', 'Charlie flagged this as urgent, for once.', 51.945058, -1.553986, '2026-06-27 09:26:47+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('ea4108f2-fbe8-4ed9-8073-e04770d17c4d', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Gerald''s assessment of the wall by the sheep pen: ''it''ll do, for now''', 'f61404f5-1f6a-439e-a836-036b23998bcf', 'urgent', 'not_started', '2026-06-11', 'Charlie flagged this as urgent, for once.', NULL, NULL, '2026-06-29 05:08:06+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('280aaedc-71e3-4842-805c-01393ca497bd', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Sort the workshop out, nobody can find a single spanner', 'dfef6686-51b6-42dc-90a6-5f748dfc873b', 'whenever', 'not_started', '2026-05-24', 'Kaleb''s on it, allegedly.', NULL, NULL, '2026-06-30 09:31:01+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('c44681bc-6ac4-432b-b497-2702a479c6a5', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Book the restaurant''s soft opening night', 'e1817e9f-ed9d-4c5d-9708-1cf24f115696', 'soon', 'not_started', '2026-06-06', 'Kaleb''s on it, allegedly.', 51.951656, -1.542287, '2026-06-30 13:27:12+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL),
  ('82d3c465-617a-4848-89d1-cbdd14d6d2e0', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Drill the spring barley in the thirty-acre field', '6b3f2ef8-9b79-4cfa-bdc0-0978d24d54da', 'soon', 'done', '2026-08-24', NULL, NULL, NULL, '2026-06-30 16:42:32+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-01 21:45:21+00'),
  ('bf534775-e90d-41a2-acd5-4d6ebaa08038', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Train the new farm shop staff on the till and the honesty box', '9bdb42e2-9da2-48cf-8488-a8f6042de0c7', 'whenever', 'done', NULL, 'Jeremy has opinions about this. Strong ones.', 51.934043, -1.553099, '2026-07-01 23:44:46+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-02 23:43:25+00'),
  ('bc8dab58-4e96-466e-bfb6-e4ce8c6569ea', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'Extract the first batch of Bee Juice honey of the season', '02b2b2c8-6330-4dfd-833e-6eb0a4feb940', 'urgent', 'not_started', '2026-08-14', 'Lisa wants it jarred and on the shelf by Friday. Label says ''Bee Juice'', obviously.', NULL, NULL, '2026-07-02 04:30:55+00', 'fab9883a-1a2b-4339-af66-81e122c74fa6', NULL);

-- ---------------------------------------------------------------------------
-- Task tags
-- ---------------------------------------------------------------------------

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('8b888e5f-4f9d-4610-a82a-c5f6d1dd4439', 'b5596c10-d2d8-4c2c-947f-808f51cb5817'),
  ('8b888e5f-4f9d-4610-a82a-c5f6d1dd4439', '38100250-d759-4270-9747-2e90f2db7485'),
  ('b6d72a18-c669-4429-a4c1-04075b0f7900', 'c1fc11bc-1317-4c8c-bcb4-4e7661ccb843'),
  ('b6d72a18-c669-4429-a4c1-04075b0f7900', '04d00a81-eeb3-46d3-9916-97ff5d94b306'),
  ('b6d72a18-c669-4429-a4c1-04075b0f7900', '5a273c53-c4b7-4da6-a2a2-82163ef344b6'),
  ('b6d72a18-c669-4429-a4c1-04075b0f7900', 'e7e7ec5c-737b-499e-bb45-8ff0b8e1d2dd'),
  ('7913e91f-ebbd-44c1-942d-38127bd15791', 'b5596c10-d2d8-4c2c-947f-808f51cb5817'),
  ('1d349076-bfec-4983-8af5-5a532ca4d6c9', '218ea584-b6c4-45cd-b991-3035bcfe5dc4'),
  ('1d349076-bfec-4983-8af5-5a532ca4d6c9', '5c92725b-f19b-48c4-a4bf-c7bb3063c21a'),
  ('325d87d2-89a0-47ec-9095-69010dbff2ac', '5119df37-f637-415e-a56b-c75c44edc239'),
  ('325d87d2-89a0-47ec-9095-69010dbff2ac', 'b5596c10-d2d8-4c2c-947f-808f51cb5817'),
  ('325d87d2-89a0-47ec-9095-69010dbff2ac', '77905706-c566-4f69-9e77-2321a6710380'),
  ('2207129d-0477-4549-b065-e3195fb9b14b', '5119df37-f637-415e-a56b-c75c44edc239'),
  ('2207129d-0477-4549-b065-e3195fb9b14b', '04d00a81-eeb3-46d3-9916-97ff5d94b306'),
  ('2207129d-0477-4549-b065-e3195fb9b14b', 'b5596c10-d2d8-4c2c-947f-808f51cb5817'),
  ('2207129d-0477-4549-b065-e3195fb9b14b', 'c1fc11bc-1317-4c8c-bcb4-4e7661ccb843'),
  ('d649a01b-e70a-4d52-973f-09af3f993a9e', 'c1dae030-60c7-475e-b47d-595a46e10e5a'),
  ('d649a01b-e70a-4d52-973f-09af3f993a9e', 'e7e7ec5c-737b-499e-bb45-8ff0b8e1d2dd'),
  ('d649a01b-e70a-4d52-973f-09af3f993a9e', '218ea584-b6c4-45cd-b991-3035bcfe5dc4'),
  ('a209876c-e5c2-456b-ae6b-0756ad44c46e', '4f3cf8d0-f8ea-4fd7-a9b1-d8bdef23fddc'),
  ('a209876c-e5c2-456b-ae6b-0756ad44c46e', 'cb295e69-16db-4c5f-992f-2944e7ae97fb'),
  ('76e1886d-048e-4e44-bd7c-8bf413672c7e', 'd8bf7db0-f33c-47b5-aa74-5bb47e959be7'),
  ('00be8248-c24d-4a60-9a40-0b03131194c1', 'c1fc11bc-1317-4c8c-bcb4-4e7661ccb843'),
  ('00be8248-c24d-4a60-9a40-0b03131194c1', '0103e8aa-d950-4d34-8cf2-fa129059cb3b'),
  ('00be8248-c24d-4a60-9a40-0b03131194c1', '733cf027-2a1b-41d9-96b6-0d1a5ee6d95c'),
  ('00be8248-c24d-4a60-9a40-0b03131194c1', 'c1dae030-60c7-475e-b47d-595a46e10e5a'),
  ('449181e4-c850-4ffe-838b-05f73faa9e55', 'd8bf7db0-f33c-47b5-aa74-5bb47e959be7'),
  ('449181e4-c850-4ffe-838b-05f73faa9e55', '340189d3-96b6-4eab-81d1-6e95944e9877'),
  ('86351466-1ef7-48f6-9f4b-3912626395c1', '4f3cf8d0-f8ea-4fd7-a9b1-d8bdef23fddc'),
  ('86351466-1ef7-48f6-9f4b-3912626395c1', '5c92725b-f19b-48c4-a4bf-c7bb3063c21a'),
  ('86351466-1ef7-48f6-9f4b-3912626395c1', '38100250-d759-4270-9747-2e90f2db7485'),
  ('4e73fa1a-43b4-4537-ae17-4ab171ae6f9a', 'd8bf7db0-f33c-47b5-aa74-5bb47e959be7'),
  ('4e73fa1a-43b4-4537-ae17-4ab171ae6f9a', '340189d3-96b6-4eab-81d1-6e95944e9877'),
  ('4e73fa1a-43b4-4537-ae17-4ab171ae6f9a', '04d00a81-eeb3-46d3-9916-97ff5d94b306'),
  ('0df5bdde-0254-4746-81cc-dd8f715b58df', '1aa4006e-ae9a-43ed-a7f4-512177edfd49'),
  ('0df5bdde-0254-4746-81cc-dd8f715b58df', '0103e8aa-d950-4d34-8cf2-fa129059cb3b'),
  ('0df5bdde-0254-4746-81cc-dd8f715b58df', '38100250-d759-4270-9747-2e90f2db7485'),
  ('83d0b568-f631-4eff-8ad7-65ea9a19ce4f', '04d00a81-eeb3-46d3-9916-97ff5d94b306'),
  ('52b209e3-6755-4087-ac73-0f6e76241f7d', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('52b209e3-6755-4087-ac73-0f6e76241f7d', '0a44d474-8919-4816-94c0-7d52433c5e86');

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('52b209e3-6755-4087-ac73-0f6e76241f7d', '5a273c53-c4b7-4da6-a2a2-82163ef344b6'),
  ('f2896d0f-8d44-46cb-a98c-bb19e92b2b32', '9845b2e2-46a4-4564-9e89-3279aff74c62'),
  ('f2896d0f-8d44-46cb-a98c-bb19e92b2b32', 'dd0303cf-004e-4e35-9e38-4e6352fc9915'),
  ('f2896d0f-8d44-46cb-a98c-bb19e92b2b32', '5119df37-f637-415e-a56b-c75c44edc239'),
  ('f2896d0f-8d44-46cb-a98c-bb19e92b2b32', 'ccb5ee3c-5fb5-4a28-9039-b648e67c9a40'),
  ('38c4dc22-09f3-4e4b-ba27-be110a06239a', 'c1fc11bc-1317-4c8c-bcb4-4e7661ccb843'),
  ('38c4dc22-09f3-4e4b-ba27-be110a06239a', 'd8bf7db0-f33c-47b5-aa74-5bb47e959be7'),
  ('38c4dc22-09f3-4e4b-ba27-be110a06239a', 'a077d6fd-b9de-457c-a30f-6b53dac0eace'),
  ('262f84fb-2b85-4f4a-ae8b-cf52a251100b', 'ad20c5e0-075a-4a52-9ebb-cac41baf3eba'),
  ('262f84fb-2b85-4f4a-ae8b-cf52a251100b', 'a077d6fd-b9de-457c-a30f-6b53dac0eace'),
  ('262f84fb-2b85-4f4a-ae8b-cf52a251100b', 'c1fc11bc-1317-4c8c-bcb4-4e7661ccb843'),
  ('e9cbadd1-0785-4068-b608-f4789a348514', 'ab7f9da7-97ae-4d6b-b7e4-fda730601666'),
  ('e9cbadd1-0785-4068-b608-f4789a348514', 'ad20c5e0-075a-4a52-9ebb-cac41baf3eba'),
  ('0cde65cd-18e8-4915-941f-f9831df968f6', '4f3cf8d0-f8ea-4fd7-a9b1-d8bdef23fddc'),
  ('0cde65cd-18e8-4915-941f-f9831df968f6', '5c92725b-f19b-48c4-a4bf-c7bb3063c21a'),
  ('fed190df-6edb-4cb7-9776-5b247ff4daf7', 'c1fc11bc-1317-4c8c-bcb4-4e7661ccb843'),
  ('fed190df-6edb-4cb7-9776-5b247ff4daf7', '1aa4006e-ae9a-43ed-a7f4-512177edfd49'),
  ('fed190df-6edb-4cb7-9776-5b247ff4daf7', '0a800e55-b0b7-447d-b8d2-5fd0bf4e0cd4'),
  ('f3d99c99-19db-4630-b0bd-ecb47e0e161b', 'c1fc11bc-1317-4c8c-bcb4-4e7661ccb843'),
  ('d093ea2e-9aa1-4661-b2a9-c1cc6e0ca2fb', '218ea584-b6c4-45cd-b991-3035bcfe5dc4'),
  ('d093ea2e-9aa1-4661-b2a9-c1cc6e0ca2fb', 'a077d6fd-b9de-457c-a30f-6b53dac0eace'),
  ('0083dfe0-6b39-4c68-941a-5798248f4083', 'e6c23750-77f1-4a92-9147-a1479f585466'),
  ('0083dfe0-6b39-4c68-941a-5798248f4083', '5119df37-f637-415e-a56b-c75c44edc239'),
  ('0083dfe0-6b39-4c68-941a-5798248f4083', '4f3cf8d0-f8ea-4fd7-a9b1-d8bdef23fddc'),
  ('0083dfe0-6b39-4c68-941a-5798248f4083', '218ea584-b6c4-45cd-b991-3035bcfe5dc4'),
  ('425b1864-9b4e-48b0-9d0d-4df50557b6f0', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('266e0fe8-1a03-433b-874d-382523643f71', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('266e0fe8-1a03-433b-874d-382523643f71', '77905706-c566-4f69-9e77-2321a6710380'),
  ('ff43a1e1-5236-4b35-926c-a9f7ed2cb804', '340189d3-96b6-4eab-81d1-6e95944e9877'),
  ('ff43a1e1-5236-4b35-926c-a9f7ed2cb804', '5a273c53-c4b7-4da6-a2a2-82163ef344b6'),
  ('c235f92f-0e0a-4f89-aea7-fba941d57a8f', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('14f9d8c5-2fb4-436b-b3ed-625e3ecbdd0a', '340189d3-96b6-4eab-81d1-6e95944e9877'),
  ('14f9d8c5-2fb4-436b-b3ed-625e3ecbdd0a', '0a800e55-b0b7-447d-b8d2-5fd0bf4e0cd4'),
  ('14f9d8c5-2fb4-436b-b3ed-625e3ecbdd0a', 'cb295e69-16db-4c5f-992f-2944e7ae97fb'),
  ('87d5b11a-fba9-4706-8bfe-3b03c4c7c330', '62f42e63-15c4-4951-b190-04da532189d3'),
  ('87d5b11a-fba9-4706-8bfe-3b03c4c7c330', '77905706-c566-4f69-9e77-2321a6710380'),
  ('cfbf5b85-b093-4bdd-ac8b-9758ebfde113', '1aa4006e-ae9a-43ed-a7f4-512177edfd49'),
  ('cfbf5b85-b093-4bdd-ac8b-9758ebfde113', 'a077d6fd-b9de-457c-a30f-6b53dac0eace'),
  ('bfbb97cb-bec4-4ca7-a2e6-59de8425c41d', '9845b2e2-46a4-4564-9e89-3279aff74c62'),
  ('7dcb7da4-e743-49c6-be5b-48a0e634df12', 'b74f7192-5ce7-46a0-80c9-500b827aef18');

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('7dcb7da4-e743-49c6-be5b-48a0e634df12', 'ad20c5e0-075a-4a52-9ebb-cac41baf3eba'),
  ('1198318c-7158-44c6-96a8-2adef6f77ced', '95c7df1e-ec62-47b1-83d3-a046b7e96b00'),
  ('1198318c-7158-44c6-96a8-2adef6f77ced', 'ad20c5e0-075a-4a52-9ebb-cac41baf3eba'),
  ('fce5719d-b10b-4642-95f9-e8988ede5bd3', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('fce5719d-b10b-4642-95f9-e8988ede5bd3', '0a44d474-8919-4816-94c0-7d52433c5e86'),
  ('f6c52ad6-878b-4cc5-b62a-caf5bfe1ccd2', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('f6c52ad6-878b-4cc5-b62a-caf5bfe1ccd2', '04d00a81-eeb3-46d3-9916-97ff5d94b306'),
  ('f6c52ad6-878b-4cc5-b62a-caf5bfe1ccd2', 'dd0303cf-004e-4e35-9e38-4e6352fc9915'),
  ('7a53d5ad-cd9c-485d-86a6-a9b2bc0c180a', '5c92725b-f19b-48c4-a4bf-c7bb3063c21a'),
  ('de2c3402-541c-42f8-a07f-77f14a1ee46f', '1aa4006e-ae9a-43ed-a7f4-512177edfd49'),
  ('de2c3402-541c-42f8-a07f-77f14a1ee46f', '2f568bdf-bd28-4c8f-bf92-6ddb09df036c'),
  ('f29faa65-a7bf-4971-9e7a-429480a8aa0d', 'cb295e69-16db-4c5f-992f-2944e7ae97fb'),
  ('f0490172-a786-427f-b869-110434a50234', 'd1695b8b-839f-4ce4-ac7d-28e663f166ae'),
  ('f0490172-a786-427f-b869-110434a50234', '62f42e63-15c4-4951-b190-04da532189d3'),
  ('f0490172-a786-427f-b869-110434a50234', 'c1fc11bc-1317-4c8c-bcb4-4e7661ccb843'),
  ('b353331c-7319-48cc-9d46-bda76d70a844', 'b74f7192-5ce7-46a0-80c9-500b827aef18'),
  ('b353331c-7319-48cc-9d46-bda76d70a844', '62f42e63-15c4-4951-b190-04da532189d3'),
  ('b353331c-7319-48cc-9d46-bda76d70a844', 'dd0303cf-004e-4e35-9e38-4e6352fc9915'),
  ('a14a9aaf-f38a-4492-b628-9b62b8d99344', 'dd0303cf-004e-4e35-9e38-4e6352fc9915'),
  ('a14a9aaf-f38a-4492-b628-9b62b8d99344', 'b5596c10-d2d8-4c2c-947f-808f51cb5817'),
  ('a14a9aaf-f38a-4492-b628-9b62b8d99344', '0a800e55-b0b7-447d-b8d2-5fd0bf4e0cd4'),
  ('57e8da24-e22d-468b-b33d-0002b582fb32', 'b5596c10-d2d8-4c2c-947f-808f51cb5817'),
  ('57e8da24-e22d-468b-b33d-0002b582fb32', '0103e8aa-d950-4d34-8cf2-fa129059cb3b'),
  ('57e8da24-e22d-468b-b33d-0002b582fb32', '0a44d474-8919-4816-94c0-7d52433c5e86'),
  ('fa9a9337-a19d-4b0d-91d6-8c1a2597f824', 'ccb5ee3c-5fb5-4a28-9039-b648e67c9a40'),
  ('fa9a9337-a19d-4b0d-91d6-8c1a2597f824', '62f42e63-15c4-4951-b190-04da532189d3'),
  ('fa9a9337-a19d-4b0d-91d6-8c1a2597f824', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('33569d86-4381-4a23-889f-4a3c5c060adb', 'd1695b8b-839f-4ce4-ac7d-28e663f166ae'),
  ('33569d86-4381-4a23-889f-4a3c5c060adb', 'b5596c10-d2d8-4c2c-947f-808f51cb5817'),
  ('5d36be63-a9bf-4d0f-9db2-5b9c7e4366e6', 'dd0303cf-004e-4e35-9e38-4e6352fc9915'),
  ('5d36be63-a9bf-4d0f-9db2-5b9c7e4366e6', '0103e8aa-d950-4d34-8cf2-fa129059cb3b'),
  ('48d67393-c691-45e3-a97a-da3cf89b8964', '5a273c53-c4b7-4da6-a2a2-82163ef344b6'),
  ('48d67393-c691-45e3-a97a-da3cf89b8964', '340189d3-96b6-4eab-81d1-6e95944e9877'),
  ('48d67393-c691-45e3-a97a-da3cf89b8964', '9845b2e2-46a4-4564-9e89-3279aff74c62'),
  ('089a1cbf-500d-4136-8f7e-3ceae315b872', '5119df37-f637-415e-a56b-c75c44edc239'),
  ('089a1cbf-500d-4136-8f7e-3ceae315b872', '218ea584-b6c4-45cd-b991-3035bcfe5dc4'),
  ('089a1cbf-500d-4136-8f7e-3ceae315b872', '38100250-d759-4270-9747-2e90f2db7485'),
  ('2867b9e7-fad5-450b-9744-2c14e5753e35', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('17c992eb-83ad-4153-b671-98e2f2ac78a1', '1aa4006e-ae9a-43ed-a7f4-512177edfd49'),
  ('17c992eb-83ad-4153-b671-98e2f2ac78a1', '4f3cf8d0-f8ea-4fd7-a9b1-d8bdef23fddc');

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('c57f1e7b-328c-4b7f-8405-67683058b1c7', '1aa4006e-ae9a-43ed-a7f4-512177edfd49'),
  ('c57f1e7b-328c-4b7f-8405-67683058b1c7', '0a800e55-b0b7-447d-b8d2-5fd0bf4e0cd4'),
  ('de80406b-f3f3-47e5-9d82-cbfc5a6d3634', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('1507c8f4-098a-444a-ac87-a0795b97d922', 'c1dae030-60c7-475e-b47d-595a46e10e5a'),
  ('1507c8f4-098a-444a-ac87-a0795b97d922', '5c92725b-f19b-48c4-a4bf-c7bb3063c21a'),
  ('1507c8f4-098a-444a-ac87-a0795b97d922', '95c7df1e-ec62-47b1-83d3-a046b7e96b00'),
  ('1da59239-ba48-45ba-b689-50c429b2cf97', '3002974c-ec62-4494-87d4-08becbbc357f'),
  ('1da59239-ba48-45ba-b689-50c429b2cf97', 'c1fc11bc-1317-4c8c-bcb4-4e7661ccb843'),
  ('5002f6cb-df91-4c6b-8bbf-350a50b7d800', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('5002f6cb-df91-4c6b-8bbf-350a50b7d800', 'd8bf7db0-f33c-47b5-aa74-5bb47e959be7'),
  ('4c60525c-9758-4637-871d-70b759f74ad1', '5119df37-f637-415e-a56b-c75c44edc239'),
  ('4c60525c-9758-4637-871d-70b759f74ad1', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('330c9017-aa3f-417b-854c-be8f9e390b34', 'ab7f9da7-97ae-4d6b-b7e4-fda730601666'),
  ('60e9e897-ea3f-4f7c-8726-4c4717b2396e', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('60e9e897-ea3f-4f7c-8726-4c4717b2396e', 'c1fc11bc-1317-4c8c-bcb4-4e7661ccb843'),
  ('60e9e897-ea3f-4f7c-8726-4c4717b2396e', '62f42e63-15c4-4951-b190-04da532189d3'),
  ('d991b695-a2de-4ba1-ab94-353fc01f88df', 'd8bf7db0-f33c-47b5-aa74-5bb47e959be7'),
  ('0fd333a8-5f3d-4ae9-97f7-388159c107b8', '62f42e63-15c4-4951-b190-04da532189d3'),
  ('3843c43f-c965-47fb-a7d7-eb106df80a1e', '0a800e55-b0b7-447d-b8d2-5fd0bf4e0cd4'),
  ('3843c43f-c965-47fb-a7d7-eb106df80a1e', '340189d3-96b6-4eab-81d1-6e95944e9877'),
  ('75eb37d3-5c75-41eb-a018-78f931ce171a', 'ab7f9da7-97ae-4d6b-b7e4-fda730601666'),
  ('75eb37d3-5c75-41eb-a018-78f931ce171a', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('c10eccb9-b891-4bfa-87f2-6b5524df6568', 'd8bf7db0-f33c-47b5-aa74-5bb47e959be7'),
  ('c10eccb9-b891-4bfa-87f2-6b5524df6568', '55a69b01-012a-4b7c-b9ec-aee354b4d80a'),
  ('c4f52b4d-33c0-4689-a045-6ce7a2c66cf9', '55a69b01-012a-4b7c-b9ec-aee354b4d80a'),
  ('c4f52b4d-33c0-4689-a045-6ce7a2c66cf9', '12770790-5929-4647-8051-95df70040638'),
  ('def49c6b-c615-45bb-a351-b8b632e496b1', 'e6c23750-77f1-4a92-9147-a1479f585466'),
  ('def49c6b-c615-45bb-a351-b8b632e496b1', '9845b2e2-46a4-4564-9e89-3279aff74c62'),
  ('562200f6-487b-4a66-b56c-8be4c8740b54', 'a077d6fd-b9de-457c-a30f-6b53dac0eace'),
  ('562200f6-487b-4a66-b56c-8be4c8740b54', 'c1fc11bc-1317-4c8c-bcb4-4e7661ccb843'),
  ('ab5dc91f-f2d3-4fff-9973-16d54b889571', '1aa4006e-ae9a-43ed-a7f4-512177edfd49'),
  ('84ea9594-8e27-4c29-a878-5f1f5e7610ba', '218ea584-b6c4-45cd-b991-3035bcfe5dc4'),
  ('84ea9594-8e27-4c29-a878-5f1f5e7610ba', 'd1695b8b-839f-4ce4-ac7d-28e663f166ae'),
  ('84ea9594-8e27-4c29-a878-5f1f5e7610ba', '0a800e55-b0b7-447d-b8d2-5fd0bf4e0cd4'),
  ('9835771d-165f-49df-9fb9-b6f4a5fb0657', '2f568bdf-bd28-4c8f-bf92-6ddb09df036c'),
  ('9835771d-165f-49df-9fb9-b6f4a5fb0657', '9845b2e2-46a4-4564-9e89-3279aff74c62'),
  ('9835771d-165f-49df-9fb9-b6f4a5fb0657', '95c7df1e-ec62-47b1-83d3-a046b7e96b00'),
  ('02bb6df3-e199-4d2f-8b8a-0170ec0ad633', '218ea584-b6c4-45cd-b991-3035bcfe5dc4'),
  ('3fc504df-9b42-44c9-8f89-aee29273e1db', 'b74f7192-5ce7-46a0-80c9-500b827aef18'),
  ('3fc504df-9b42-44c9-8f89-aee29273e1db', 'a077d6fd-b9de-457c-a30f-6b53dac0eace');

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('3fc504df-9b42-44c9-8f89-aee29273e1db', 'd1695b8b-839f-4ce4-ac7d-28e663f166ae'),
  ('a114ff84-b8fa-41e3-bf9a-bfa798e89178', '2f568bdf-bd28-4c8f-bf92-6ddb09df036c'),
  ('a114ff84-b8fa-41e3-bf9a-bfa798e89178', '55a69b01-012a-4b7c-b9ec-aee354b4d80a'),
  ('c6d24c9f-a750-4396-b316-9bfc89c7c233', 'a077d6fd-b9de-457c-a30f-6b53dac0eace'),
  ('c6d24c9f-a750-4396-b316-9bfc89c7c233', '04d00a81-eeb3-46d3-9916-97ff5d94b306'),
  ('f37a340a-03b0-41fd-9591-4bb4686d5df5', '1aa4006e-ae9a-43ed-a7f4-512177edfd49'),
  ('f37a340a-03b0-41fd-9591-4bb4686d5df5', '77905706-c566-4f69-9e77-2321a6710380'),
  ('f37a340a-03b0-41fd-9591-4bb4686d5df5', 'e7e7ec5c-737b-499e-bb45-8ff0b8e1d2dd'),
  ('ad374ed3-241e-411c-b686-873c5d85b573', '1aa4006e-ae9a-43ed-a7f4-512177edfd49'),
  ('ad374ed3-241e-411c-b686-873c5d85b573', '95c7df1e-ec62-47b1-83d3-a046b7e96b00'),
  ('ad374ed3-241e-411c-b686-873c5d85b573', '04d00a81-eeb3-46d3-9916-97ff5d94b306'),
  ('d662c48c-3b93-469a-a66c-4f5370461c05', 'ad20c5e0-075a-4a52-9ebb-cac41baf3eba'),
  ('d662c48c-3b93-469a-a66c-4f5370461c05', 'b74f7192-5ce7-46a0-80c9-500b827aef18'),
  ('d662c48c-3b93-469a-a66c-4f5370461c05', 'd1695b8b-839f-4ce4-ac7d-28e663f166ae'),
  ('e686e3cd-3c71-4fe9-b8ba-d1b1e8ee93c5', 'e6c23750-77f1-4a92-9147-a1479f585466'),
  ('e686e3cd-3c71-4fe9-b8ba-d1b1e8ee93c5', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('755097cb-6db8-4158-ae7a-c1f31335d2f5', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('755097cb-6db8-4158-ae7a-c1f31335d2f5', '0103e8aa-d950-4d34-8cf2-fa129059cb3b'),
  ('755097cb-6db8-4158-ae7a-c1f31335d2f5', 'ad20c5e0-075a-4a52-9ebb-cac41baf3eba'),
  ('e8a16810-3187-4acb-a2f2-984516f23a0e', '04d00a81-eeb3-46d3-9916-97ff5d94b306'),
  ('e8a16810-3187-4acb-a2f2-984516f23a0e', '5a273c53-c4b7-4da6-a2a2-82163ef344b6'),
  ('4107d0b4-dbc5-45e5-8ee1-185fcbc4aa19', '218ea584-b6c4-45cd-b991-3035bcfe5dc4'),
  ('4107d0b4-dbc5-45e5-8ee1-185fcbc4aa19', '62f42e63-15c4-4951-b190-04da532189d3'),
  ('4107d0b4-dbc5-45e5-8ee1-185fcbc4aa19', '04d00a81-eeb3-46d3-9916-97ff5d94b306'),
  ('4107d0b4-dbc5-45e5-8ee1-185fcbc4aa19', 'e6c23750-77f1-4a92-9147-a1479f585466'),
  ('f946b348-9353-49b1-a4a0-c801257968ad', '04d00a81-eeb3-46d3-9916-97ff5d94b306'),
  ('0e4b48d5-cfbd-4716-bb11-c0831f473ad4', 'a077d6fd-b9de-457c-a30f-6b53dac0eace'),
  ('0e4b48d5-cfbd-4716-bb11-c0831f473ad4', 'c1fc11bc-1317-4c8c-bcb4-4e7661ccb843'),
  ('0e4b48d5-cfbd-4716-bb11-c0831f473ad4', '04d00a81-eeb3-46d3-9916-97ff5d94b306'),
  ('734784e0-3fd7-46c3-86e4-050690614a43', 'ad20c5e0-075a-4a52-9ebb-cac41baf3eba'),
  ('734784e0-3fd7-46c3-86e4-050690614a43', '04d00a81-eeb3-46d3-9916-97ff5d94b306'),
  ('ea4108f2-fbe8-4ed9-8073-e04770d17c4d', '340189d3-96b6-4eab-81d1-6e95944e9877'),
  ('ea4108f2-fbe8-4ed9-8073-e04770d17c4d', '0a800e55-b0b7-447d-b8d2-5fd0bf4e0cd4'),
  ('280aaedc-71e3-4842-805c-01393ca497bd', 'b74f7192-5ce7-46a0-80c9-500b827aef18'),
  ('280aaedc-71e3-4842-805c-01393ca497bd', '2f568bdf-bd28-4c8f-bf92-6ddb09df036c'),
  ('c44681bc-6ac4-432b-b497-2702a479c6a5', '04d00a81-eeb3-46d3-9916-97ff5d94b306'),
  ('c44681bc-6ac4-432b-b497-2702a479c6a5', 'd1695b8b-839f-4ce4-ac7d-28e663f166ae'),
  ('82d3c465-617a-4848-89d1-cbdd14d6d2e0', '95c7df1e-ec62-47b1-83d3-a046b7e96b00'),
  ('82d3c465-617a-4848-89d1-cbdd14d6d2e0', '12770790-5929-4647-8051-95df70040638'),
  ('82d3c465-617a-4848-89d1-cbdd14d6d2e0', '9845b2e2-46a4-4564-9e89-3279aff74c62');

INSERT INTO task_tags (task_id, tag_id)
VALUES
  ('bf534775-e90d-41a2-acd5-4d6ebaa08038', '0a44d474-8919-4816-94c0-7d52433c5e86'),
  ('bf534775-e90d-41a2-acd5-4d6ebaa08038', '6c48e497-7c66-438d-a31c-cbc50961f753'),
  ('bf534775-e90d-41a2-acd5-4d6ebaa08038', '5c92725b-f19b-48c4-a4bf-c7bb3063c21a'),
  ('bf534775-e90d-41a2-acd5-4d6ebaa08038', '733cf027-2a1b-41d9-96b6-0d1a5ee6d95c'),
  ('bc8dab58-4e96-466e-bfb6-e4ce8c6569ea', '38100250-d759-4270-9747-2e90f2db7485'),
  ('bc8dab58-4e96-466e-bfb6-e4ce8c6569ea', '6c48e497-7c66-438d-a31c-cbc50961f753');

-- ---------------------------------------------------------------------------
-- Activity log
-- ---------------------------------------------------------------------------

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('4d4130d1-123a-4033-a473-ddf756a3f991', '9a150965-7ecb-4fa8-92e2-524a58343a52', '8b888e5f-4f9d-4610-a82a-c5f6d1dd4439', 'task_created', '{"task_title": "Sow the sunflower strip for the pollinators"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-15 23:01:26+00'),
  ('0fa32480-7ef6-408a-8c15-d492f204ba17', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'b6d72a18-c669-4429-a4c1-04075b0f7900', 'task_created', '{"task_title": "Update the farm''s public liability insurance for the new restaurant"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-17 03:33:50+00'),
  ('eee2b589-6161-4217-a7b2-710caaa74a43', '9a150965-7ecb-4fa8-92e2-524a58343a52', '7913e91f-ebbd-44c1-942d-38127bd15791', 'task_created', '{"task_title": "Settle the argument about whether it''s a farm or a theme park now"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-19 20:47:03+00'),
  ('c628f783-bafe-4457-b7e7-90efb1fd2bb8', '9a150965-7ecb-4fa8-92e2-524a58343a52', '1d349076-bfec-4983-8af5-5a532ca4d6c9', 'task_created', '{"task_title": "Fix the fence the cows keep leaning through"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-20 02:00:46+00'),
  ('cb68625a-f81f-4cb2-8bdb-494d0cf5bae0', '9a150965-7ecb-4fa8-92e2-524a58343a52', NULL, 'category_created', '{"category_id": "02b2b2c8-6330-4dfd-833e-6eb0a4feb940", "category_name": "Livestock"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-20 04:33:30+00'),
  ('098fd043-894f-43f2-aa5a-597b28d3deed', '9a150965-7ecb-4fa8-92e2-524a58343a52', '325d87d2-89a0-47ec-9095-69010dbff2ac', 'task_created', '{"task_title": "Fix the burst pipe near the wasabi polytunnel"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-20 15:07:40+00'),
  ('ca3b6a26-441b-4721-bda2-777ba357076e', '9a150965-7ecb-4fa8-92e2-524a58343a52', NULL, 'category_created', '{"category_id": "6b3f2ef8-9b79-4cfa-bdc0-0978d24d54da", "category_name": "Arable"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-21 02:51:54+00'),
  ('c20f7e81-c423-40fb-845e-e8f2bbc083fb', '9a150965-7ecb-4fa8-92e2-524a58343a52', NULL, 'category_created', '{"category_id": "9bdb42e2-9da2-48cf-8488-a8f6042de0c7", "category_name": "Farm Shop"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-21 12:07:04+00'),
  ('5fd073d8-a17a-4ead-89d7-001a8177c27d', '9a150965-7ecb-4fa8-92e2-524a58343a52', '2207129d-0477-4549-b065-e3195fb9b14b', 'task_created', '{"task_title": "Finalise the restaurant menu with the wasabi mash"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-22 06:24:11+00'),
  ('c71c3b35-69f9-4a20-9183-db074782abea', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'd649a01b-e70a-4d52-973f-09af3f993a9e', 'task_created', '{"task_title": "Check for badger setts near the cattle troughs"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-22 16:47:29+00'),
  ('84e43f54-8e58-44bd-ba31-418ed4d9d673', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'a209876c-e5c2-456b-ae6b-0756ad44c46e', 'task_created', '{"task_title": "Separate Leonardo DiCaprio from the ewes ahead of tupping season"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-22 18:58:11+00'),
  ('f9c1aaa3-2173-41cf-af32-e5e21cfee944', '9a150965-7ecb-4fa8-92e2-524a58343a52', '76e1886d-048e-4e44-bd7c-8bf413672c7e', 'task_created', '{"task_title": "Order more hops for the next Hawkstone brew"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-23 00:25:24+00'),
  ('1f2bf845-ba5d-4970-ad09-48d4b47418b5', '9a150965-7ecb-4fa8-92e2-524a58343a52', '00be8248-c24d-4a60-9a40-0b03131194c1', 'task_created', '{"task_title": "Chase Cheerful Charlie for the updated land agent report"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-23 09:26:11+00'),
  ('70354861-43fc-4bb4-83ed-ac35ee4de124', '9a150965-7ecb-4fa8-92e2-524a58343a52', '449181e4-c850-4ffe-838b-05f73faa9e55', 'task_created', '{"task_title": "Bottle the latest batch of Hawkstone cider"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-23 19:57:33+00'),
  ('c720c738-e5c2-4e54-9c19-c7372252e3ec', '9a150965-7ecb-4fa8-92e2-524a58343a52', '86351466-1ef7-48f6-9f4b-3912626395c1', 'task_created', '{"task_title": "Shear the flock before the heatwave"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-25 03:14:24+00'),
  ('cd86cfa0-094a-4834-a0e2-366253258ce0', '9a150965-7ecb-4fa8-92e2-524a58343a52', '4e73fa1a-43b4-4537-ae17-4ab171ae6f9a', 'task_created', '{"task_title": "Design new labels for the Hawkstone cider bottles"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-28 18:01:26+00'),
  ('84142b4d-d9c9-4e48-8caf-4ad1f4fbaf4a', '9a150965-7ecb-4fa8-92e2-524a58343a52', '7306a62f-ac22-46da-982c-7ca18c431a21', 'task_created', '{"task_title": "Taste-test the new potato and wasabi side dish"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-29 21:09:42+00'),
  ('1bc1b2b5-8c26-4449-91ac-f51bc32ef831', '9a150965-7ecb-4fa8-92e2-524a58343a52', '00be8248-c24d-4a60-9a40-0b03131194c1', 'task_status_changed', '{"task_title": "Chase Cheerful Charlie for the updated land agent report", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-03-31 11:31:19+00'),
  ('8de0ebfc-4914-420e-b791-005b1e18dfb2', '9a150965-7ecb-4fa8-92e2-524a58343a52', NULL, 'category_created', '{"category_id": "dfef6686-51b6-42dc-90a6-5f748dfc873b", "category_name": "Machinery"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-01 05:09:51+00'),
  ('9d2a2995-84c9-4b61-8d6e-69da388c8807', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'a2b9fe03-fbbd-48a9-b4e9-4172271b9bf9', 'task_created', '{"task_title": "Check the flock for flystrike after the warm spell"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-02 04:38:31+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('b293d87b-91f8-4ee7-a65e-fad7ddac5047', '9a150965-7ecb-4fa8-92e2-524a58343a52', NULL, 'category_created', '{"category_id": "383e8fb7-1891-44a8-86d8-f180ddffc051", "category_name": "Brewing"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-02 12:39:05+00'),
  ('d3f5c34c-9e87-4e6f-98b3-0fa8eb405c51', '9a150965-7ecb-4fa8-92e2-524a58343a52', '0df5bdde-0254-4746-81cc-dd8f715b58df', 'task_created', '{"task_title": "Coppice a section of the wilding woodland"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-04 05:33:10+00'),
  ('d5964c60-afdb-4cea-b252-1eb50e54d4b2', '9a150965-7ecb-4fa8-92e2-524a58343a52', NULL, 'category_created', '{"category_id": "e1817e9f-ed9d-4c5d-9708-1cf24f115696", "category_name": "Restaurant"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-04 05:39:43+00'),
  ('0582b2bc-aaff-4b18-95a1-827c18f40b48', '9a150965-7ecb-4fa8-92e2-524a58343a52', '83d0b568-f631-4eff-8ad7-65ea9a19ce4f', 'task_created', '{"task_title": "Fix the restaurant kitchen''s extractor fan"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-04 09:14:53+00'),
  ('3ef9dde2-4889-4663-ac03-f9fbd8077384', '9a150965-7ecb-4fa8-92e2-524a58343a52', '52b209e3-6755-4087-ac73-0f6e76241f7d', 'task_created', '{"task_title": "Restock the farm shop shelves before the Saturday rush"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-05 01:19:25+00'),
  ('c1fcfe3e-4f2d-4e54-8e62-a20fcc603f7f', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'f2896d0f-8d44-46cb-a98c-bb19e92b2b32', 'task_created', '{"task_title": "Fix the loader that Jeremy reversed into the barn wall"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-05 06:15:43+00'),
  ('2fb4cf4d-b2e4-43fc-9432-e6a00a4f64ce', '9a150965-7ecb-4fa8-92e2-524a58343a52', '38c4dc22-09f3-4e4b-ba27-be110a06239a', 'task_created', '{"task_title": "Chase the brewery about the delayed Hawkstone delivery"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-05 07:41:32+00'),
  ('8378204c-d60d-46a4-a46c-7c5f0051c0f3', '9a150965-7ecb-4fa8-92e2-524a58343a52', NULL, 'category_created', '{"category_id": "f61404f5-1f6a-439e-a836-036b23998bcf", "category_name": "Fencing & Walls"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-05 22:50:25+00'),
  ('5976f34f-4f35-4c43-b632-afe56de02ced', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'c6404a5a-b75a-45ee-84bf-d3e18f1e9d8f', 'task_created', '{"task_title": "Reorder Hawkstone lager for the shop fridge"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-05 23:52:12+00'),
  ('bb187239-0734-441f-83da-fa76a418d2af', '9a150965-7ecb-4fa8-92e2-524a58343a52', '262f84fb-2b85-4f4a-ae8b-cf52a251100b', 'task_created', '{"task_title": "Get the baler fixed before the hay''s ready"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-06 16:01:53+00'),
  ('01ba5503-ad4e-4000-9275-339891a73a35', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'e9cbadd1-0785-4068-b608-f4789a348514', 'task_created', '{"task_title": "Clear the drainage ditch along the bottom field before the rain sets in"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-06 16:26:11+00'),
  ('a573b072-1b59-47f1-bc82-a8166b7d45e1', '9a150965-7ecb-4fa8-92e2-524a58343a52', '0cde65cd-18e8-4915-941f-f9831df968f6', 'task_created', '{"task_title": "Move Wayne Rooney to the top field before he does something biblical"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-06 17:26:54+00'),
  ('8ee8d838-ba75-4983-8274-a8e9827a6f89', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'f2896d0f-8d44-46cb-a98c-bb19e92b2b32', 'task_status_changed', '{"task_title": "Fix the loader that Jeremy reversed into the barn wall", "old_status": "not_started", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-06 23:26:29+00'),
  ('6f2dee89-8ed6-4053-bf21-6470fc420fa0', '9a150965-7ecb-4fa8-92e2-524a58343a52', '4363f7b0-5bbf-4b1a-93f5-adb43c8ff3b5', 'task_created', '{"task_title": "Dig the first potatoes for the farm shop"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-09 00:26:21+00'),
  ('b1dbd46f-dd13-4ad4-af21-e24f5a713561', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'fed190df-6edb-4cb7-9776-5b247ff4daf7', 'task_created', '{"task_title": "Meet the wildlife trust about the rewilding grant"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-09 16:09:49+00'),
  ('83c40316-f48c-47c8-bc90-7579c0f60a09', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'f3d99c99-19db-4630-b0bd-ecb47e0e161b', 'task_created', '{"task_title": "Get the TB testing paperwork filed with the vet"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-10 08:20:31+00'),
  ('492853d7-db0f-49da-abc6-9a5bd30d3681', '9a150965-7ecb-4fa8-92e2-524a58343a52', NULL, 'category_created', '{"category_id": "89f49bb0-c2f5-45a8-be09-efb9c618d5d8", "category_name": "Wilding"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-11 10:17:37+00'),
  ('145a967a-cc80-4007-8f16-504b9263b8c6', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'e9cbadd1-0785-4068-b608-f4789a348514', 'task_status_changed', '{"task_title": "Clear the drainage ditch along the bottom field before the rain sets in", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-11 15:55:36+00'),
  ('b6f49da4-0a86-40d2-a80d-f1d147039dba', '9a150965-7ecb-4fa8-92e2-524a58343a52', '262f84fb-2b85-4f4a-ae8b-cf52a251100b', 'task_status_changed', '{"task_title": "Get the baler fixed before the hay''s ready", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-11 20:02:00+00'),
  ('d4ec4138-faff-455f-8b3a-c31f006ffdeb', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'd093ea2e-9aa1-4661-b2a9-c1cc6e0ca2fb', 'task_created', '{"task_title": "Replace the gate Jeremy reversed the pickup into"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-13 00:40:01+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('0fc5b2f1-34e9-46bc-85ff-404110feef1e', '9a150965-7ecb-4fa8-92e2-524a58343a52', '0083dfe0-6b39-4c68-941a-5798248f4083', 'task_created', '{"task_title": "Test the wasabi polytunnel''s water temperature"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-13 05:08:35+00'),
  ('65bdd6d5-15b0-48e5-a0fa-2245b429af33', '9a150965-7ecb-4fa8-92e2-524a58343a52', '425b1864-9b4e-48b0-9d0d-4df50557b6f0', 'task_created', '{"task_title": "Deep clean the farm shop fridge before the food hygiene inspection"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-14 06:46:14+00'),
  ('1f7457b1-956d-4e96-b39f-14b79e004b21', '9a150965-7ecb-4fa8-92e2-524a58343a52', '266e0fe8-1a03-433b-874d-382523643f71', 'task_created', '{"task_title": "Figure out why there''s a goat in the farm shop again"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-14 10:56:23+00'),
  ('e95a4921-1614-4065-a369-34a662e44e72', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'ff43a1e1-5236-4b35-926c-a9f7ed2cb804', 'task_created', '{"task_title": "Get quotes for repairing the farmyard''s crumbling wall"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-15 04:24:56+00'),
  ('1de24ec1-8b3d-4875-92b2-1e73f1265f1d', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'a920d3b8-27fc-443b-85a0-3c0b699f4e9e', 'task_created', '{"task_title": "Install a new borehole pump for the spring water bottling plant"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-15 15:31:35+00'),
  ('91007d4d-31ed-4eee-87fc-cb13329a8a20', '9a150965-7ecb-4fa8-92e2-524a58343a52', '262f84fb-2b85-4f4a-ae8b-cf52a251100b', 'task_status_changed', '{"task_title": "Get the baler fixed before the hay''s ready", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-15 17:51:41+00'),
  ('07c8e939-6b7f-47fa-92f0-fcf4b219afda', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'c235f92f-0e0a-4f89-aea7-fba941d57a8f', 'task_created', '{"task_title": "Draft the Chadlington village fete stall plan"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-15 19:48:47+00'),
  ('1a7ecea9-bcff-4e40-9302-1f0451e345b6', '9a150965-7ecb-4fa8-92e2-524a58343a52', '14f9d8c5-2fb4-436b-b3ed-625e3ecbdd0a', 'task_created', '{"task_title": "Repair the storm-damaged stretch of dry-stone wall by the road"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-18 15:37:25+00'),
  ('73222b91-75a2-4038-8207-fcffe5c860c1', '9a150965-7ecb-4fa8-92e2-524a58343a52', '421f6574-be03-4998-9b4c-9b82ef10b225', 'task_created', '{"task_title": "File the DEFRA subsidy paperwork before the deadline"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-18 22:41:10+00'),
  ('12165356-5a54-4453-8e3d-f59a10f598e2', '9a150965-7ecb-4fa8-92e2-524a58343a52', '87d5b11a-fba9-4706-8bfe-3b03c4c7c330', 'task_created', '{"task_title": "Count the Oxford Sandy and Blacks, again, because Jeremy keeps losing track"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-19 02:22:52+00'),
  ('3eb97e6e-b350-4064-bf89-2705cd7bdda2', '9a150965-7ecb-4fa8-92e2-524a58343a52', '4e73fa1a-43b4-4537-ae17-4ab171ae6f9a', 'task_status_changed', '{"task_title": "Design new labels for the Hawkstone cider bottles", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-19 04:25:11+00'),
  ('b4f7bc52-289f-4e67-9824-880738dff704', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'b693dd75-691c-47db-8775-61474449216a', 'task_created', '{"task_title": "TB test the whole herd, brace for bad news"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-21 18:33:00+00'),
  ('8374d6eb-9f4b-4b90-b34e-53fb36103fd7', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'cfbf5b85-b093-4bdd-ac8b-9758ebfde113', 'task_created', '{"task_title": "Survey the wilding area for returning birdlife"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-23 00:34:36+00'),
  ('d7d14eec-cc44-4f9d-ae91-710d21599ed7', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'bfbb97cb-bec4-4ca7-a2e6-59de8425c41d', 'task_created', '{"task_title": "Change the oil on the Lamborghini before the big drilling push"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-23 19:19:56+00'),
  ('5765f379-3fb5-4078-b48c-12fa2f1e762d', '9a150965-7ecb-4fa8-92e2-524a58343a52', '7dcb7da4-e743-49c6-be5b-48a0e634df12', 'task_created', '{"task_title": "Lay the hedge along the bottom lane before the birds nest"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-25 01:31:39+00'),
  ('410a9ac3-367a-40f0-972e-ce9dd08dc8a1', '9a150965-7ecb-4fa8-92e2-524a58343a52', '1198318c-7158-44c6-96a8-2adef6f77ced', 'task_created', '{"task_title": "Harvest the spring barley, weather permitting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-25 04:06:19+00'),
  ('de8fb9b9-8314-41ff-a58a-612e935a53eb', '9a150965-7ecb-4fa8-92e2-524a58343a52', '83d0b568-f631-4eff-8ad7-65ea9a19ce4f', 'task_status_changed', '{"task_title": "Fix the restaurant kitchen''s extractor fan", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-25 14:39:15+00'),
  ('29bf5e21-1c69-40cb-b47b-848d9564425b', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'cfbf5b85-b093-4bdd-ac8b-9758ebfde113', 'task_status_changed', '{"task_title": "Survey the wilding area for returning birdlife", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-26 03:50:44+00'),
  ('9568084f-3e31-4baf-b811-06d7b2b4612c', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'fce5719d-b10b-4642-95f9-e8988ede5bd3', 'task_created', '{"task_title": "Redesign the farm shop layout so people stop nicking the honey"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-27 11:06:58+00'),
  ('dc5422c5-e2a8-4f92-a8b2-94d5d06c827f', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'f6c52ad6-878b-4cc5-b62a-caf5bfe1ccd2', 'task_created', '{"task_title": "Harvest the chillis and box them for the shop"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-27 13:23:56+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('e39b46bb-3265-4fe4-a05f-60ee7e4c6848', '9a150965-7ecb-4fa8-92e2-524a58343a52', NULL, 'category_created', '{"category_id": "dd4f70d1-eb6d-47f2-9f57-f024ac237097", "category_name": "Buildings & Infrastructure"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-27 16:14:14+00'),
  ('35c4ee3c-2f9a-48f8-bd23-3d51cfcc1158', '9a150965-7ecb-4fa8-92e2-524a58343a52', '0cde65cd-18e8-4915-941f-f9831df968f6', 'task_status_changed', '{"task_title": "Move Wayne Rooney to the top field before he does something biblical", "old_status": "not_started", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-28 06:48:19+00'),
  ('4d6fef11-3050-4484-9c64-59a51fee3f14', '9a150965-7ecb-4fa8-92e2-524a58343a52', '7a53d5ad-cd9c-485d-86a6-a9b2bc0c180a', 'task_created', '{"task_title": "Ask Kaleb what he actually meant by ''that''ll be reet''"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-28 11:10:18+00'),
  ('3f5d9560-0725-4b47-8dec-955e4c6368d5', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'de2c3402-541c-42f8-a07f-77f14a1ee46f', 'task_created', '{"task_title": "Clear invasive scrub from the rewilding margin"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-30 05:46:33+00'),
  ('2a3cb96c-7f76-499a-99cd-7689078230a2', '9a150965-7ecb-4fa8-92e2-524a58343a52', '14f9d8c5-2fb4-436b-b3ed-625e3ecbdd0a', 'task_status_changed', '{"task_title": "Repair the storm-damaged stretch of dry-stone wall by the road", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-04-30 16:11:07+00'),
  ('f648ae94-e5ec-40c5-ab3c-5dfbec0f4234', '9a150965-7ecb-4fa8-92e2-524a58343a52', NULL, 'category_created', '{"category_id": "a1990aba-60ed-4374-93fb-c51a21e57d00", "category_name": "Paperwork & Compliance"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-01 21:16:43+00'),
  ('ead84cd6-03a2-4c48-aa89-26c02b480bde', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'f29faa65-a7bf-4971-9e7a-429480a8aa0d', 'task_created', '{"task_title": "Wash the Lamborghini down after the muck-spreading disaster"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-02 11:02:35+00'),
  ('e45ceff6-fa8e-4f12-9440-5092ced986d7', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'f0490172-a786-427f-b869-110434a50234', 'task_created', '{"task_title": "Sort out the leaking roof on the lambing barn"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-02 17:23:34+00'),
  ('0a05fc01-50fb-4d6d-8ac9-c21b09691bd7', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'b353331c-7319-48cc-9d46-bda76d70a844', 'task_created', '{"task_title": "Order more blackthorn whips for the hedge-laying"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-03 00:48:35+00'),
  ('99dda1f9-3a66-4e53-aa6b-477e48f5752d', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'a14a9aaf-f38a-4492-b628-9b62b8d99344', 'task_created', '{"task_title": "Fit new shelving in the mushroom bunker"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-04 23:51:03+00'),
  ('2efff9cf-818b-42c3-b1b4-3f227957f5d6', '9a150965-7ecb-4fa8-92e2-524a58343a52', '57e8da24-e22d-468b-b33d-0002b582fb32', 'task_created', '{"task_title": "Sort the diversification ideas list before the next Charlie meeting"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 03:18:00+00'),
  ('110823a4-18a4-484a-b099-95ee06e71b5d', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'e9cbadd1-0785-4068-b608-f4789a348514', 'task_status_changed', '{"task_title": "Clear the drainage ditch along the bottom field before the rain sets in", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 07:03:17+00'),
  ('9ec35cae-7364-4166-9d76-beedeb15d891', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'fa9a9337-a19d-4b0d-91d6-8c1a2597f824', 'task_created', '{"task_title": "Unblock the culvert under the Chadlington road"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 12:45:14+00'),
  ('04a27f79-fbaf-4b1b-a236-c58bb8869939', '9a150965-7ecb-4fa8-92e2-524a58343a52', '33569d86-4381-4a23-889f-4a3c5c060adb', 'task_created', '{"task_title": "Chase down a buyer for the durum wheat"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 15:00:01+00'),
  ('15457d81-6f46-46c0-bcd1-d713876cc272', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'a920d3b8-27fc-443b-85a0-3c0b699f4e9e', 'task_status_changed', '{"task_title": "Install a new borehole pump for the spring water bottling plant", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 19:14:39+00'),
  ('30a0d790-083c-452c-8768-d3053aa3eb10', '9a150965-7ecb-4fa8-92e2-524a58343a52', '5d36be63-a9bf-4d0f-9db2-5b9c7e4366e6', 'task_created', '{"task_title": "Reinforce the wartime bunker roof before the mushroom crop goes in"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 19:39:46+00'),
  ('6c177a82-b97a-4fda-9e19-82000152f638', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'fce5719d-b10b-4642-95f9-e8988ede5bd3', 'task_status_changed', '{"task_title": "Redesign the farm shop layout so people stop nicking the honey", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-05 21:58:04+00'),
  ('f6ad9861-c3ec-46f1-bbc9-38bb11ca8ea3', '9a150965-7ecb-4fa8-92e2-524a58343a52', '48d67393-c691-45e3-a97a-da3cf89b8964', 'task_created', '{"task_title": "Plant the potatoes in the field behind the lambing barn"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-06 01:54:17+00'),
  ('90fac2cb-e5b5-4bf0-bc66-e73b5fcb628a', '9a150965-7ecb-4fa8-92e2-524a58343a52', '8b888e5f-4f9d-4610-a82a-c5f6d1dd4439', 'task_status_changed', '{"task_title": "Sow the sunflower strip for the pollinators", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-06 23:38:36+00'),
  ('f54d8cd7-3b0e-49ee-ab02-0966f48c1703', '9a150965-7ecb-4fa8-92e2-524a58343a52', '089a1cbf-500d-4136-8f7e-3ceae315b872', 'task_created', '{"task_title": "Check the wasabi tunnel''s shading before the hot weather"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-07 03:44:04+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('baea5e1e-398b-4acc-890b-0a5e1e0d18c7', '9a150965-7ecb-4fa8-92e2-524a58343a52', NULL, 'category_created', '{"category_id": "cf9274b2-3cf0-41b1-9592-6a0df9edc782", "category_name": "Produce & Orchard"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-07 17:43:46+00'),
  ('4454269d-bdfb-43e2-abf4-7e90c96d0c8a', '9a150965-7ecb-4fa8-92e2-524a58343a52', '2867b9e7-fad5-450b-9744-2c14e5753e35', 'task_created', '{"task_title": "Insulate the honey extraction room"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-07 23:55:23+00'),
  ('6296a96e-c52e-4b3b-9039-fd2bbb66fd20', '9a150965-7ecb-4fa8-92e2-524a58343a52', '17c992eb-83ad-4153-b671-98e2f2ac78a1', 'task_created', '{"task_title": "Fence off the rewilding block from the sheep"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-08 08:53:03+00'),
  ('c32e84ba-d586-4af7-a559-402fae5c1890', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'c57f1e7b-328c-4b7f-8405-67683058b1c7', 'task_created', '{"task_title": "Put up stock fencing around the new wilding block"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-08 11:19:00+00'),
  ('502eaeac-c39f-4172-aef0-7717dac3e404', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'a209876c-e5c2-456b-ae6b-0756ad44c46e', 'task_status_changed', '{"task_title": "Separate Leonardo DiCaprio from the ewes ahead of tupping season", "old_status": "not_started", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-08 11:57:37+00'),
  ('f41839e6-28cb-493e-ad82-c6f9cc906417', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'de80406b-f3f3-47e5-9d82-cbfc5a6d3634', 'task_created', '{"task_title": "Sort out the car park overflow for the farm shop"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-08 23:34:45+00'),
  ('7a4c9cc1-b3da-4512-807f-f7b5f347c614', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'a920d3b8-27fc-443b-85a0-3c0b699f4e9e', 'task_status_changed', '{"task_title": "Install a new borehole pump for the spring water bottling plant", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-09 07:28:06+00'),
  ('9643a04a-4743-47cf-bb5d-a98a53e56ee3', '9a150965-7ecb-4fa8-92e2-524a58343a52', '4e73fa1a-43b4-4537-ae17-4ab171ae6f9a', 'task_status_changed', '{"task_title": "Design new labels for the Hawkstone cider bottles", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-11 07:20:46+00'),
  ('90bd0288-9611-4450-8687-51eefe442b92', '9a150965-7ecb-4fa8-92e2-524a58343a52', '1198318c-7158-44c6-96a8-2adef6f77ced', 'task_status_changed', '{"task_title": "Harvest the spring barley, weather permitting", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-12 02:23:36+00'),
  ('77ee1abd-a15d-4326-8719-ed092183c60f', '9a150965-7ecb-4fa8-92e2-524a58343a52', '1507c8f4-098a-444a-ac87-a0795b97d922', 'task_created', '{"task_title": "Prune the orchard trees before the sap rises"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-13 12:47:33+00'),
  ('5d4aa967-86a5-4949-a488-36e6a2101693', '9a150965-7ecb-4fa8-92e2-524a58343a52', '1da59239-ba48-45ba-b689-50c429b2cf97', 'task_created', '{"task_title": "Submit the revised planning application to West Oxfordshire council"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-14 03:05:16+00'),
  ('d788e63d-3351-4d0a-8d65-436e246ec1e0', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'f0490172-a786-427f-b869-110434a50234', 'task_status_changed', '{"task_title": "Sort out the leaking roof on the lambing barn", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-14 03:05:19+00'),
  ('6d0792cd-09e5-4216-8049-6dfcc3bf57d5', '9a150965-7ecb-4fa8-92e2-524a58343a52', '0d7c1e0c-4bb5-4173-b276-828eb3821ec8', 'task_created', '{"task_title": "Spray the oilseed rape for flea beetle before it''s too late"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-15 04:20:32+00'),
  ('68114fd8-073a-415b-8fae-3ecbb9f6606e', '9a150965-7ecb-4fa8-92e2-524a58343a52', '421f6574-be03-4998-9b4c-9b82ef10b225', 'task_status_changed', '{"task_title": "File the DEFRA subsidy paperwork before the deadline", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-17 20:33:53+00'),
  ('c877dcf5-612b-4a35-9d97-2bf1181aa19e', '9a150965-7ecb-4fa8-92e2-524a58343a52', '5002f6cb-df91-4c6b-8bbf-350a50b7d800', 'task_created', '{"task_title": "Pick the first apples for the farm shop cider press"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-18 00:18:41+00'),
  ('e34c2cd4-5c20-424f-8983-8ecee4ac93da', '9a150965-7ecb-4fa8-92e2-524a58343a52', '14f9d8c5-2fb4-436b-b3ed-625e3ecbdd0a', 'task_status_changed', '{"task_title": "Repair the storm-damaged stretch of dry-stone wall by the road", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-18 10:08:07+00'),
  ('8ca4d376-d8b1-4568-bfee-b9cbeb730f97', '9a150965-7ecb-4fa8-92e2-524a58343a52', '4c60525c-9758-4637-871d-70b759f74ad1', 'task_created', '{"task_title": "Stock the shop with the new wasabi mayonnaise"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-18 13:46:12+00'),
  ('053266fa-d7c3-465c-a633-4b37aee5e41d', '9a150965-7ecb-4fa8-92e2-524a58343a52', '330c9017-aa3f-417b-854c-be8f9e390b34', 'task_created', '{"task_title": "Fox-proof the hen run after last night''s carnage"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-18 18:35:47+00'),
  ('d5c69692-3dbe-41e3-ac25-11c60753a08f', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'fed190df-6edb-4cb7-9776-5b247ff4daf7', 'task_status_changed', '{"task_title": "Meet the wildlife trust about the rewilding grant", "old_status": "not_started", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-18 23:29:11+00'),
  ('4ea8ef4c-5aef-484d-92e6-fe754677832c', '9a150965-7ecb-4fa8-92e2-524a58343a52', '60e9e897-ea3f-4f7c-8726-4c4717b2396e', 'task_created', '{"task_title": "Renew the food hygiene certificate for the farm shop"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-19 00:59:10+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('699b4260-e90f-4857-a41a-7ca9582908ed', '9a150965-7ecb-4fa8-92e2-524a58343a52', '7dcb7da4-e743-49c6-be5b-48a0e634df12', 'task_status_changed', '{"task_title": "Lay the hedge along the bottom lane before the birds nest", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-20 14:05:52+00'),
  ('1abcea55-d76c-49c1-a690-6b216afb0772', '9a150965-7ecb-4fa8-92e2-524a58343a52', '37ad0903-cba8-4d46-ab97-de3be51ac570', 'task_created', '{"task_title": "Re-lay the dry-stone wall along the top field"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-20 20:26:16+00'),
  ('0b5cb833-5207-41a1-ad43-96b2994e81f3', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'd991b695-a2de-4ba1-ab94-353fc01f88df', 'task_created', '{"task_title": "Fix the bottling line before it jams again"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-21 09:31:07+00'),
  ('72db0e32-6f0b-4ab4-8bcd-3530d0c0d677', '9a150965-7ecb-4fa8-92e2-524a58343a52', '7306a62f-ac22-46da-982c-7ca18c431a21', 'task_status_changed', '{"task_title": "Taste-test the new potato and wasabi side dish", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-21 22:25:25+00'),
  ('ccddd53f-8a57-4e38-98af-e7f2da374f60', '9a150965-7ecb-4fa8-92e2-524a58343a52', '0fd333a8-5f3d-4ae9-97f7-388159c107b8', 'task_created', '{"task_title": "Fix the pig fence the boar keeps flattening"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-22 04:01:34+00'),
  ('e73da280-cd4f-4a04-8931-a30e2dc6ef92', '9a150965-7ecb-4fa8-92e2-524a58343a52', '3843c43f-c965-47fb-a7d7-eb106df80a1e', 'task_created', '{"task_title": "Track down the missing dry-stone wall hammer Gerald swears he left ''right there''"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-22 10:57:34+00'),
  ('32f31db4-4a2f-4ce5-a7b6-f446776ca33e', '9a150965-7ecb-4fa8-92e2-524a58343a52', '75eb37d3-5c75-41eb-a018-78f931ce171a', 'task_created', '{"task_title": "Collect eggs and restock the honesty box by the gate"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-22 22:45:42+00'),
  ('ab307acc-05fd-4de1-8968-bcbc85bfe0a1', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'c10eccb9-b891-4bfa-87f2-6b5524df6568', 'task_created', '{"task_title": "Get the new Hawkstone lager batch tested for quality"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-23 18:00:42+00'),
  ('2789aeec-562d-4a80-bc40-1b0723169e86', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'd991b695-a2de-4ba1-ab94-353fc01f88df', 'task_status_changed', '{"task_title": "Fix the bottling line before it jams again", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-24 18:47:43+00'),
  ('677e62a3-88cd-4081-bbdd-7616d1cec3b1', '9a150965-7ecb-4fa8-92e2-524a58343a52', '5171ec7d-6fcf-4e48-b54b-ebca3674a0c4', 'task_created', '{"task_title": "Negotiate with the council over the farm shop''s opening hours"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-25 01:53:57+00'),
  ('60a46afb-9672-4e9c-8a16-18e11425fdb1', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'fa9a9337-a19d-4b0d-91d6-8c1a2597f824', 'task_status_changed', '{"task_title": "Unblock the culvert under the Chadlington road", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-25 21:58:19+00'),
  ('f00f495b-aeb7-4b28-a03e-9ae30827c34e', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'c4f52b4d-33c0-4689-a045-6ce7a2c66cf9', 'task_created', '{"task_title": "Fix the barn door that won''t close since the storm"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-25 23:10:16+00'),
  ('f19e1f24-8376-437f-8424-42987c23f52f', '9a150965-7ecb-4fa8-92e2-524a58343a52', '330c9017-aa3f-417b-854c-be8f9e390b34', 'task_status_changed', '{"task_title": "Fox-proof the hen run after last night''s carnage", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-26 20:08:44+00'),
  ('57afef5e-ee18-48cb-a079-52cbdce13d41', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'a14a9aaf-f38a-4492-b628-9b62b8d99344', 'task_status_changed', '{"task_title": "Fit new shelving in the mushroom bunker", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-28 00:08:30+00'),
  ('a39c788e-5a38-43cd-8f29-0c050df9b61c', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'def49c6b-c615-45bb-a351-b8b632e496b1', 'task_created', '{"task_title": "Test the spring water for mineral content before bottling"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-28 13:16:25+00'),
  ('1987c74e-0a46-4e26-a718-107d575ba6f4', '9a150965-7ecb-4fa8-92e2-524a58343a52', '1198318c-7158-44c6-96a8-2adef6f77ced', 'task_status_changed', '{"task_title": "Harvest the spring barley, weather permitting", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-31 00:59:06+00'),
  ('c292c4d9-ce80-446a-9c4a-676de8554944', '9a150965-7ecb-4fa8-92e2-524a58343a52', '562200f6-487b-4a66-b56c-8be4c8740b54', 'task_created', '{"task_title": "Work out what to do with the field the council won''t let us touch"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-31 15:29:09+00'),
  ('f67f14eb-0b22-4bc1-b04d-c72cfe6e1b24', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'ab5dc91f-f2d3-4fff-9973-16d54b889571', 'task_created', '{"task_title": "Plant the wildflower mix on the rewilding strip"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-05-31 21:08:10+00'),
  ('8be58d36-1fa7-40e3-8283-99747810787f', '9a150965-7ecb-4fa8-92e2-524a58343a52', '3843c43f-c965-47fb-a7d7-eb106df80a1e', 'task_status_changed', '{"task_title": "Track down the missing dry-stone wall hammer Gerald swears he left ''right there''", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-01 11:51:19+00'),
  ('acf29ac5-9a1f-4aa8-bd91-7e357bc31018', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'd649a01b-e70a-4d52-973f-09af3f993a9e', 'task_status_changed', '{"task_title": "Check for badger setts near the cattle troughs", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-01 22:39:28+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('1920213d-d6b3-4d4c-bc94-697075e71c8b', '9a150965-7ecb-4fa8-92e2-524a58343a52', '84ea9594-8e27-4c29-a878-5f1f5e7610ba', 'task_created', '{"task_title": "Check the cattle trough float valves across the whole farm"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-02 04:21:21+00'),
  ('2d3b7e21-786b-4e41-82ba-4db2cae1c0f6', '9a150965-7ecb-4fa8-92e2-524a58343a52', '86351466-1ef7-48f6-9f4b-3912626395c1', 'task_status_changed', '{"task_title": "Shear the flock before the heatwave", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-02 22:45:07+00'),
  ('ef7cda50-21a9-4a89-b15b-15a4a322a2b0', '9a150965-7ecb-4fa8-92e2-524a58343a52', '9835771d-165f-49df-9fb9-b6f4a5fb0657', 'task_created', '{"task_title": "Get the Lamborghini R8 tractor''s hydraulics looked at"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-03 05:13:20+00'),
  ('cad3be73-e777-4f65-8093-e175932a7b75', '9a150965-7ecb-4fa8-92e2-524a58343a52', '02bb6df3-e199-4d2f-8b8a-0170ec0ad633', 'task_created', '{"task_title": "Rewire the old cow shed before the inspector visits"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-03 07:55:52+00'),
  ('822f9f55-77c0-4a66-be2c-6f0abd3829f3', '9a150965-7ecb-4fa8-92e2-524a58343a52', '37ad0903-cba8-4d46-ab97-de3be51ac570', 'task_status_changed', '{"task_title": "Re-lay the dry-stone wall along the top field", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-04 19:32:18+00'),
  ('90ad6b9e-a695-42fc-913d-e0ec7daf7887', '9a150965-7ecb-4fa8-92e2-524a58343a52', NULL, 'category_created', '{"category_id": "ad637816-7c24-45f9-a8f1-88996e5b76b3", "category_name": "Water & Drainage"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 06:17:53+00'),
  ('db21e0d0-9b63-4cef-9e7c-b0d0e1fc1305', '9a150965-7ecb-4fa8-92e2-524a58343a52', '3fc504df-9b42-44c9-8f89-aee29273e1db', 'task_created', '{"task_title": "Sort the chilli harvest into mild, hot, and ''why did we grow these''"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 12:30:22+00'),
  ('053a8e52-10fd-41f1-9a7a-ef8cd6f96523', '9a150965-7ecb-4fa8-92e2-524a58343a52', '449181e4-c850-4ffe-838b-05f73faa9e55', 'task_status_changed', '{"task_title": "Bottle the latest batch of Hawkstone cider", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 15:03:49+00'),
  ('388da589-4135-4014-ae4f-d1199d4c1f31', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'ab5dc91f-f2d3-4fff-9973-16d54b889571', 'task_status_changed', '{"task_title": "Plant the wildflower mix on the rewilding strip", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 21:51:20+00'),
  ('6754fe5a-7884-4e90-9ef6-ee3f7b59e888', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'c10eccb9-b891-4bfa-87f2-6b5524df6568', 'task_status_changed', '{"task_title": "Get the new Hawkstone lager batch tested for quality", "old_status": "not_started", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 22:39:07+00'),
  ('fc5deba2-f32c-4bdc-aa4b-b5c3b842c487', '9a150965-7ecb-4fa8-92e2-524a58343a52', '37ad0903-cba8-4d46-ab97-de3be51ac570', 'task_status_changed', '{"task_title": "Re-lay the dry-stone wall along the top field", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-05 22:50:15+00'),
  ('e6f469ac-d46b-45b6-ab5b-e1641570f064', '9a150965-7ecb-4fa8-92e2-524a58343a52', '9835771d-165f-49df-9fb9-b6f4a5fb0657', 'task_status_changed', '{"task_title": "Get the Lamborghini R8 tractor''s hydraulics looked at", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-06 02:32:44+00'),
  ('0574ce7f-23b0-4022-9e2a-c5e22ee8340c', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'a114ff84-b8fa-41e3-bf9a-bfa798e89178', 'task_created', '{"task_title": "Find out where the missing set of keys to the Lamborghini went"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-06 07:39:55+00'),
  ('577503cc-fe12-4f13-80f4-d31abb62b6e7', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'bfbb97cb-bec4-4ca7-a2e6-59de8425c41d', 'task_status_changed', '{"task_title": "Change the oil on the Lamborghini before the big drilling push", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-06 11:27:04+00'),
  ('d4738b4c-0eac-4980-95b7-d0a00643b652', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'c6d24c9f-a750-4396-b316-9bfc89c7c233', 'task_created', '{"task_title": "Appeal the council''s decision on the restaurant planning"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-06 17:27:04+00'),
  ('849012ef-4915-4e96-9bd8-fa76c12a7834', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'd991b695-a2de-4ba1-ab94-353fc01f88df', 'task_status_changed', '{"task_title": "Fix the bottling line before it jams again", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-07 12:24:27+00'),
  ('3bf06abf-5967-4be5-8fc1-d8354e0e3cd2', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'de80406b-f3f3-47e5-9d82-cbfc5a6d3634', 'task_status_changed', '{"task_title": "Sort out the car park overflow for the farm shop", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-07 14:45:08+00'),
  ('85b26de6-2252-47bb-807e-d5f79ab831a8', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'f37a340a-03b0-41fd-9591-4bb4686d5df5', 'task_created', '{"task_title": "Rebuild the goat pen after the great escape into the wildflower meadow"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-07 15:42:50+00'),
  ('2dc3da71-4ffa-4377-9bee-3228d4f07991', '9a150965-7ecb-4fa8-92e2-524a58343a52', '5002f6cb-df91-4c6b-8bbf-350a50b7d800', 'task_status_changed', '{"task_title": "Pick the first apples for the farm shop cider press", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-07 19:19:43+00'),
  ('06d1ed93-07be-4b07-b4e8-e7c6c657c5f5', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'ad374ed3-241e-411c-b686-873c5d85b573', 'task_created', '{"task_title": "Plant a new row of fruit trees along the orchard boundary"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-08 00:14:34+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('5889eb5f-04f9-4a76-828d-ef2a6bf83505', '9a150965-7ecb-4fa8-92e2-524a58343a52', '5171ec7d-6fcf-4e48-b54b-ebca3674a0c4', 'task_status_changed', '{"task_title": "Negotiate with the council over the farm shop''s opening hours", "old_status": "not_started", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 00:08:27+00'),
  ('c3d01aeb-bcd6-41b0-a966-689bbbc5ac86', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'd662c48c-3b93-469a-a66c-4f5370461c05', 'task_created', '{"task_title": "Service the quad bikes before lambing"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 01:36:09+00'),
  ('d0f33f2a-fbc8-4dd4-ac95-c7193482c9d0', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'b353331c-7319-48cc-9d46-bda76d70a844', 'task_status_changed', '{"task_title": "Order more blackthorn whips for the hedge-laying", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-09 16:39:09+00'),
  ('185ebb8b-ce88-477e-bb15-80136cbdee14', '9a150965-7ecb-4fa8-92e2-524a58343a52', '7a53d5ad-cd9c-485d-86a6-a9b2bc0c180a', 'task_status_changed', '{"task_title": "Ask Kaleb what he actually meant by ''that''ll be reet''", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-10 02:26:43+00'),
  ('e4a9697f-6ae0-4ab3-9870-d69d1cdb43c2', '9a150965-7ecb-4fa8-92e2-524a58343a52', '089a1cbf-500d-4136-8f7e-3ceae315b872', 'task_status_changed', '{"task_title": "Check the wasabi tunnel''s shading before the hot weather", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-10 04:55:48+00'),
  ('3f196713-6e6b-4c6d-aab7-e1cfa74d45df', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'de80406b-f3f3-47e5-9d82-cbfc5a6d3634', 'task_status_changed', '{"task_title": "Sort out the car park overflow for the farm shop", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-11 09:35:31+00'),
  ('049c497a-1543-4cae-b630-23a4cc8ce4c4', '9a150965-7ecb-4fa8-92e2-524a58343a52', '75eb37d3-5c75-41eb-a018-78f931ce171a', 'task_status_changed', '{"task_title": "Collect eggs and restock the honesty box by the gate", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-11 16:50:37+00'),
  ('e329d0d2-cfca-4134-80e2-30c76f2a7791', '9a150965-7ecb-4fa8-92e2-524a58343a52', '84ea9594-8e27-4c29-a878-5f1f5e7610ba', 'task_status_changed', '{"task_title": "Check the cattle trough float valves across the whole farm", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-11 23:07:26+00'),
  ('04afcf0e-4748-464f-9d6b-34aa6245a370', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'e686e3cd-3c71-4fe9-b8ba-d1b1e8ee93c5', 'task_created', '{"task_title": "Bottle the first run of spring water for sale"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-12 15:40:06+00'),
  ('4a622f43-aca9-4d7a-8207-03ed83e959aa', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'ab5dc91f-f2d3-4fff-9973-16d54b889571', 'task_status_changed', '{"task_title": "Plant the wildflower mix on the rewilding strip", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-13 03:02:33+00'),
  ('6b0bb697-50c4-46f1-92a1-85e2f8091b29', '9a150965-7ecb-4fa8-92e2-524a58343a52', '84ea9594-8e27-4c29-a878-5f1f5e7610ba', 'task_status_changed', '{"task_title": "Check the cattle trough float valves across the whole farm", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-13 09:57:07+00'),
  ('beeff85e-9ab7-442f-bd8f-cd0c1d1df445', '9a150965-7ecb-4fa8-92e2-524a58343a52', '75eb37d3-5c75-41eb-a018-78f931ce171a', 'task_status_changed', '{"task_title": "Collect eggs and restock the honesty box by the gate", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-14 00:24:47+00'),
  ('d5b8acc1-1d00-42cd-ae29-9117cdd255d9', '9a150965-7ecb-4fa8-92e2-524a58343a52', '755097cb-6db8-4158-ae7a-c1f31335d2f5', 'task_created', '{"task_title": "Fix the leaking farm shop roof before the next storm"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-14 16:04:28+00'),
  ('09b6a8e1-6492-4d5e-896d-0c698b6326af', '9a150965-7ecb-4fa8-92e2-524a58343a52', '60e9e897-ea3f-4f7c-8726-4c4717b2396e', 'task_status_changed', '{"task_title": "Renew the food hygiene certificate for the farm shop", "old_status": "not_started", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-14 19:14:06+00'),
  ('8c3a2e41-db73-4ad3-9faa-1585e0660183', '9a150965-7ecb-4fa8-92e2-524a58343a52', '0d7c1e0c-4bb5-4173-b276-828eb3821ec8', 'task_status_changed', '{"task_title": "Spray the oilseed rape for flea beetle before it''s too late", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-14 21:44:24+00'),
  ('ed66feaa-8ad0-49be-b55c-f523fc4d5259', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'd662c48c-3b93-469a-a66c-4f5370461c05', 'task_status_changed', '{"task_title": "Service the quad bikes before lambing", "old_status": "not_started", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-14 23:10:36+00'),
  ('d01db8ea-6cb7-4e8d-9f21-250e49533d30', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'b353331c-7319-48cc-9d46-bda76d70a844', 'task_status_changed', '{"task_title": "Order more blackthorn whips for the hedge-laying", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-18 00:35:11+00'),
  ('df441bfc-f9a1-44ba-9dd0-d0ee12557428', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'e8a16810-3187-4acb-a2f2-984516f23a0e', 'task_created', '{"task_title": "Interview chefs for the farm restaurant"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-18 03:13:24+00'),
  ('95f917fe-b144-4642-8239-bfbdee45d4c4', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'c235f92f-0e0a-4f89-aea7-fba941d57a8f', 'task_status_changed', '{"task_title": "Draft the Chadlington village fete stall plan", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-18 07:08:42+00'),
  ('f6b67514-73b7-49c2-a7a2-a7f248921395', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'bfbb97cb-bec4-4ca7-a2e6-59de8425c41d', 'task_status_changed', '{"task_title": "Change the oil on the Lamborghini before the big drilling push", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-19 07:27:17+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('a4654b30-6a5d-48a3-bb29-77a0457b54d9', '9a150965-7ecb-4fa8-92e2-524a58343a52', '4363f7b0-5bbf-4b1a-93f5-adb43c8ff3b5', 'task_status_changed', '{"task_title": "Dig the first potatoes for the farm shop", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-19 11:35:01+00'),
  ('9aa3617a-27ac-4418-896b-6fa164bb0fb5', '9a150965-7ecb-4fa8-92e2-524a58343a52', '83d0b568-f631-4eff-8ad7-65ea9a19ce4f', 'task_status_changed', '{"task_title": "Fix the restaurant kitchen''s extractor fan", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 09:54:56+00'),
  ('a00a3a7d-5a94-4f05-83e4-0c17982dbf8c', '9a150965-7ecb-4fa8-92e2-524a58343a52', '266e0fe8-1a03-433b-874d-382523643f71', 'task_status_changed', '{"task_title": "Figure out why there''s a goat in the farm shop again", "old_status": "not_started", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-20 15:55:14+00'),
  ('5f54e23b-4a7b-4dde-a3f9-3f2ad37df708', '9a150965-7ecb-4fa8-92e2-524a58343a52', '4107d0b4-dbc5-45e5-8ee1-185fcbc4aa19', 'task_created', '{"task_title": "Source local suppliers for the restaurant''s beef and pork"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-21 09:52:36+00'),
  ('9e9aee50-4551-4fa1-950e-c1e76b93c692', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'ad374ed3-241e-411c-b686-873c5d85b573', 'task_status_changed', '{"task_title": "Plant a new row of fruit trees along the orchard boundary", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-21 15:53:50+00'),
  ('40ba6306-6857-4036-97d1-8b8508ed996a', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'f946b348-9353-49b1-a4a0-c801257968ad', 'task_created', '{"task_title": "Harvest the first wasabi crop and get it to the restaurant"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-22 04:30:09+00'),
  ('dc78add5-0eac-457b-aae5-ac3d0dfa4fce', '9a150965-7ecb-4fa8-92e2-524a58343a52', '0e4b48d5-cfbd-4716-bb11-c0831f473ad4', 'task_created', '{"task_title": "Sort the restaurant''s planning permission paperwork"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-22 13:54:15+00'),
  ('a101f557-8696-45a3-a580-998a424b9714', '9a150965-7ecb-4fa8-92e2-524a58343a52', '5002f6cb-df91-4c6b-8bbf-350a50b7d800', 'task_status_changed', '{"task_title": "Pick the first apples for the farm shop cider press", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-23 06:23:20+00'),
  ('8b02d40d-3218-452b-a81b-db40e4280b64', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'c6d24c9f-a750-4396-b316-9bfc89c7c233', 'task_status_changed', '{"task_title": "Appeal the council''s decision on the restaurant planning", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-23 18:20:50+00'),
  ('639b6a8f-7a3e-4c9e-9f5b-fcc6de9e4e4b', '9a150965-7ecb-4fa8-92e2-524a58343a52', '449181e4-c850-4ffe-838b-05f73faa9e55', 'task_status_changed', '{"task_title": "Bottle the latest batch of Hawkstone cider", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-24 07:42:49+00'),
  ('2082d647-05e3-41f0-a9fe-5470a9ebe473', '9a150965-7ecb-4fa8-92e2-524a58343a52', '4107d0b4-dbc5-45e5-8ee1-185fcbc4aa19', 'task_status_changed', '{"task_title": "Source local suppliers for the restaurant''s beef and pork", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-25 12:07:48+00'),
  ('ccfa8eaa-df74-4b75-bd36-96e01d11adda', '9a150965-7ecb-4fa8-92e2-524a58343a52', '0d7c1e0c-4bb5-4173-b276-828eb3821ec8', 'task_status_changed', '{"task_title": "Spray the oilseed rape for flea beetle before it''s too late", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-25 12:50:16+00'),
  ('e0eb0733-fbeb-48d5-9731-a24388369bf3', '9a150965-7ecb-4fa8-92e2-524a58343a52', '3843c43f-c965-47fb-a7d7-eb106df80a1e', 'task_status_changed', '{"task_title": "Track down the missing dry-stone wall hammer Gerald swears he left ''right there''", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-25 14:50:41+00'),
  ('e7647432-446c-4e7b-be76-e18c197a5c6c', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'f946b348-9353-49b1-a4a0-c801257968ad', 'task_status_changed', '{"task_title": "Harvest the first wasabi crop and get it to the restaurant", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-26 02:56:24+00'),
  ('9e26d572-3684-4d08-9d9d-4b2b13bdd33e', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'cfbf5b85-b093-4bdd-ac8b-9758ebfde113', 'task_status_changed', '{"task_title": "Survey the wilding area for returning birdlife", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-26 12:42:56+00'),
  ('084b3d08-364f-48a8-9bd5-1b60085e8808', '9a150965-7ecb-4fa8-92e2-524a58343a52', '734784e0-3fd7-46c3-86e4-050690614a43', 'task_created', '{"task_title": "Net the soft fruit before the birds get there first"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-27 09:26:47+00'),
  ('752b354e-e7a1-4f4d-a3e9-8cf5aeef9811', '9a150965-7ecb-4fa8-92e2-524a58343a52', '57e8da24-e22d-468b-b33d-0002b582fb32', 'task_status_changed', '{"task_title": "Sort the diversification ideas list before the next Charlie meeting", "old_status": "not_started", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-27 21:59:07+00'),
  ('d386da12-20e1-4cd4-a4df-d1c065bb094b', '9a150965-7ecb-4fa8-92e2-524a58343a52', '86351466-1ef7-48f6-9f4b-3912626395c1', 'task_status_changed', '{"task_title": "Shear the flock before the heatwave", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-28 11:37:59+00'),
  ('edbca65f-b094-4543-94f7-27c470ebe0cf', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'c57f1e7b-328c-4b7f-8405-67683058b1c7', 'task_status_changed', '{"task_title": "Put up stock fencing around the new wilding block", "old_status": "not_started", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-29 01:27:15+00'),
  ('566ff022-dd7e-49fc-a8c6-be62722ce106', '9a150965-7ecb-4fa8-92e2-524a58343a52', '755097cb-6db8-4158-ae7a-c1f31335d2f5', 'task_status_changed', '{"task_title": "Fix the leaking farm shop roof before the next storm", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-29 03:56:09+00');

INSERT INTO activity_log (id, farm_id, task_id, event_type, event_detail, actor_user_id, created_at)
VALUES
  ('8c5847c4-1ebf-4e85-8bcb-de3598c048f7', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'ea4108f2-fbe8-4ed9-8073-e04770d17c4d', 'task_created', '{"task_title": "Gerald''s assessment of the wall by the sheep pen: ''it''ll do, for now''"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-29 05:08:06+00'),
  ('ea3da110-012e-4735-9461-bcb247cf6463', '9a150965-7ecb-4fa8-92e2-524a58343a52', '0fd333a8-5f3d-4ae9-97f7-388159c107b8', 'task_status_changed', '{"task_title": "Fix the pig fence the boar keeps flattening", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-29 06:36:30+00'),
  ('3a34585d-77c6-470a-9207-1d21e5093492', '9a150965-7ecb-4fa8-92e2-524a58343a52', '280aaedc-71e3-4842-805c-01393ca497bd', 'task_created', '{"task_title": "Sort the workshop out, nobody can find a single spanner"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-30 09:31:01+00'),
  ('2e15bab0-cd8d-456a-9b0c-101cd434ca7c', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'c44681bc-6ac4-432b-b497-2702a479c6a5', 'task_created', '{"task_title": "Book the restaurant''s soft opening night"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-30 13:27:12+00'),
  ('e370da33-1d1d-4580-9361-35fad6f3d289', '9a150965-7ecb-4fa8-92e2-524a58343a52', '82d3c465-617a-4848-89d1-cbdd14d6d2e0', 'task_created', '{"task_title": "Drill the spring barley in the thirty-acre field"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-06-30 16:42:32+00'),
  ('62801eae-fc4f-40b2-9424-718f3c1e64a4', '9a150965-7ecb-4fa8-92e2-524a58343a52', '0e4b48d5-cfbd-4716-bb11-c0831f473ad4', 'task_status_changed', '{"task_title": "Sort the restaurant''s planning permission paperwork", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-01 03:08:28+00'),
  ('8ce9a272-229b-4f36-be17-2fb787a29f25', '9a150965-7ecb-4fa8-92e2-524a58343a52', '82d3c465-617a-4848-89d1-cbdd14d6d2e0', 'task_status_changed', '{"task_title": "Drill the spring barley in the thirty-acre field", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-01 03:31:48+00'),
  ('6d45f1cc-9883-429a-97cc-c099506b81cb', '9a150965-7ecb-4fa8-92e2-524a58343a52', '8b888e5f-4f9d-4610-a82a-c5f6d1dd4439', 'task_status_changed', '{"task_title": "Sow the sunflower strip for the pollinators", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-01 19:19:57+00'),
  ('efc8c3e7-89dd-4496-b6f8-17bfad8bbf30', '9a150965-7ecb-4fa8-92e2-524a58343a52', '82d3c465-617a-4848-89d1-cbdd14d6d2e0', 'task_status_changed', '{"task_title": "Drill the spring barley in the thirty-acre field", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-01 21:45:21+00'),
  ('a5ef99a7-d02a-424c-b93e-a324e418edfc', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'bf534775-e90d-41a2-acd5-4d6ebaa08038', 'task_created', '{"task_title": "Train the new farm shop staff on the till and the honesty box"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-01 23:44:46+00'),
  ('a4d4b72a-ec13-4ee2-8bb9-9417282295d1', '9a150965-7ecb-4fa8-92e2-524a58343a52', '48d67393-c691-45e3-a97a-da3cf89b8964', 'task_status_changed', '{"task_title": "Plant the potatoes in the field behind the lambing barn", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-02 04:02:00+00'),
  ('944bdfd0-ac8c-4672-a8d7-79bb37a78387', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'bc8dab58-4e96-466e-bfb6-e4ce8c6569ea', 'task_created', '{"task_title": "Extract the first batch of Bee Juice honey of the season"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-02 04:30:55+00'),
  ('04202065-2cb8-44e2-806e-4ca530faea19', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'bf534775-e90d-41a2-acd5-4d6ebaa08038', 'task_status_changed', '{"task_title": "Train the new farm shop staff on the till and the honesty box", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-02 10:26:49+00'),
  ('2fd0775b-d2c4-4c45-b99e-4bdc9a4f339a', '9a150965-7ecb-4fa8-92e2-524a58343a52', 'bf534775-e90d-41a2-acd5-4d6ebaa08038', 'task_status_changed', '{"task_title": "Train the new farm shop staff on the till and the honesty box", "old_status": "in_progress", "new_status": "done"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-02 23:43:25+00'),
  ('58a0b6db-3c0c-4f76-9714-c3c0ea3062e7', '9a150965-7ecb-4fa8-92e2-524a58343a52', '3fc504df-9b42-44c9-8f89-aee29273e1db', 'task_status_changed', '{"task_title": "Sort the chilli harvest into mild, hot, and ''why did we grow these''", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-03 04:51:27+00'),
  ('52b8e8e9-db90-439d-b6d3-3937c0aaf72b', '9a150965-7ecb-4fa8-92e2-524a58343a52', '7913e91f-ebbd-44c1-942d-38127bd15791', 'task_status_changed', '{"task_title": "Settle the argument about whether it''s a farm or a theme park now", "old_status": "not_started", "new_status": "in_progress"}'::jsonb, 'fab9883a-1a2b-4339-af66-81e122c74fa6', '2026-07-03 08:00:32+00');

COMMIT;
