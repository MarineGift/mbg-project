SELECT
  (SELECT count(*) FROM app.parties WHERE id = '5d88a6a7-3959-4284-806b-b03fc0aad411') AS party,
  (SELECT count(*) FROM app.deals WHERE id = 'fb2249de-9a2d-4bab-81f9-4d8208db78a3') AS deal,
  (SELECT count(*) FROM app.deal_parties WHERE deal_id = 'fb2249de-9a2d-4bab-81f9-4d8208db78a3') AS deal_parties,
  (SELECT count(*) FROM app.deal_checklists WHERE deal_id = 'fb2249de-9a2d-4bab-81f9-4d8208db78a3') AS checklists,
  (SELECT count(*) FROM app.tasks WHERE deal_id = 'fb2249de-9a2d-4bab-81f9-4d8208db78a3' AND deleted_at IS NULL) AS tasks,
  (SELECT count(*) FROM app.reward_tiers WHERE deal_id = 'fb2249de-9a2d-4bab-81f9-4d8208db78a3') AS reward_tiers,
  (SELECT count(*) FROM app.deal_backers WHERE deal_id = 'fb2249de-9a2d-4bab-81f9-4d8208db78a3') AS backers,
  (SELECT coalesce(sum(pledge_amount), 0) FROM app.deal_backers WHERE deal_id = 'fb2249de-9a2d-4bab-81f9-4d8208db78a3') AS pledged_total,
  (SELECT count(*) FROM app.attachments WHERE entity_id IN (SELECT id FROM app.tasks WHERE deal_id = 'fb2249de-9a2d-4bab-81f9-4d8208db78a3') AND deleted_at IS NULL) AS task_attachments;
