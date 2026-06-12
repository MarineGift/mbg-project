INSERT INTO app.deal_backers (
  id, organization_id, deal_id, reward_tier_id, pledge_amount, currency,
  status, is_anonymous, display_name, email, country_code, note
)
VALUES
  ('1294076e-d8e3-4039-9fce-6b89ce27a61c', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', '2902adbd-94ef-4c97-a38b-3bcb6838acb4', 39, 'USD', 'pledged', false, 'Alex Kim', 'alex.kim@example.com', 'US', 'TEST SEED kickstarter_pilot_2026Q3'),
  ('da39453b-ec1b-495b-8a05-f93e354ccdce', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', '2902adbd-94ef-4c97-a38b-3bcb6838acb4', 39, 'USD', 'pledged', false, 'Minji Park', 'minji.park@example.com', 'KR', 'TEST SEED kickstarter_pilot_2026Q3'),
  ('fb52508a-3277-4f85-ad1f-a1ba6ed4277e', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', 'f86550e8-ada4-48d6-89b4-fda3b5443405', 49, 'USD', 'pledged', false, 'Sara Mueller', 'sara.mueller@example.com', 'DE', 'TEST SEED kickstarter_pilot_2026Q3'),
  ('6381b00d-cfe3-4dfa-8433-095ca14d1266', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', 'f86550e8-ada4-48d6-89b4-fda3b5443405', 49, 'USD', 'pledged', true, NULL, 'anon.backer@example.com', 'JP', 'TEST SEED kickstarter_pilot_2026Q3 - anonymous backer'),
  ('24481aee-0c26-4fed-b532-9f30cb784680', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', '1080d70c-6794-40ce-bd8f-9450999940ba', 89, 'USD', 'pledged', false, 'Tom Reilly', 'tom.reilly@example.com', 'US', 'TEST SEED kickstarter_pilot_2026Q3'),
  ('4a04d206-ee89-48cf-890f-d680ef1f6fc4', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', '1080d70c-6794-40ce-bd8f-9450999940ba', 95, 'USD', 'pledged', false, 'Yuki Tanaka', 'yuki.tanaka@example.com', 'JP', 'TEST SEED kickstarter_pilot_2026Q3 - pledged above tier minimum'),
  ('a6e0bbc6-e938-4062-a2e4-43b3499ca9da', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', '0886142c-82ac-4419-9439-b245cc15e69a', 149, 'USD', 'pledged', false, 'Claire Dubois', 'claire.dubois@example.com', 'FR', 'TEST SEED kickstarter_pilot_2026Q3'),
  ('a0334d10-594d-44ca-a90b-210713fcd421', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', NULL, 25, 'USD', 'pledged', false, 'No Reward Supporter', 'supporter@example.com', 'US', 'TEST SEED kickstarter_pilot_2026Q3 - pledge without reward')
ON CONFLICT (id) DO NOTHING;
