INSERT INTO app.deal_checklists (
  id, organization_id, deal_id, title, sort_order, notes
)
VALUES
  ('e5055cb2-6dc2-47a1-a695-9f7211bef77b', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', 'Campaign preparation', 1, 'Budget, rewards, story, video, page assets'),
  ('31d36064-d871-49e3-b99a-f3c7864155fa', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', 'Prelaunch and backer recruiting', 2, 'Prelaunch page, email list, SNS, press, URM backer prospects'),
  ('dbe5a0f0-206f-493b-8419-78f7ee75f96c', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', 'Launch and operations', 3, 'Launch blast, first 48h push, updates, community replies'),
  ('9e38a986-452a-4065-abdd-82e62a0ad4cb', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', 'Post-funding', 4, 'Backer survey, production and shipping, accounting')
ON CONFLICT (id) DO NOTHING;
