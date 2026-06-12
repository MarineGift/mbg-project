WITH del_backers AS (
  DELETE FROM app.deal_backers
  WHERE deal_id = 'fb2249de-9a2d-4bab-81f9-4d8208db78a3'
  RETURNING id
), del_tiers AS (
  DELETE FROM app.reward_tiers
  WHERE deal_id = 'fb2249de-9a2d-4bab-81f9-4d8208db78a3'
  RETURNING id
), del_tasks AS (
  DELETE FROM app.tasks
  WHERE deal_id = 'fb2249de-9a2d-4bab-81f9-4d8208db78a3'
  RETURNING id
), del_checklists AS (
  DELETE FROM app.deal_checklists
  WHERE deal_id = 'fb2249de-9a2d-4bab-81f9-4d8208db78a3'
  RETURNING id
), del_links AS (
  DELETE FROM app.deal_parties
  WHERE deal_id = 'fb2249de-9a2d-4bab-81f9-4d8208db78a3'
  RETURNING id
), del_atts AS (
  DELETE FROM app.attachments
  WHERE entity_type IN ('task', 'deal_checklist', 'deal')
    AND entity_id IN (
      'fb2249de-9a2d-4bab-81f9-4d8208db78a3',
      'e5055cb2-6dc2-47a1-a695-9f7211bef77b', '31d36064-d871-49e3-b99a-f3c7864155fa',
      'dbe5a0f0-206f-493b-8419-78f7ee75f96c', '9e38a986-452a-4065-abdd-82e62a0ad4cb',
      'edceb03f-b5c0-4e60-880a-18e1b18e8aed', '7b318ffa-db17-49e7-a4c7-d59e50499ebb',
      '9c2b8998-b1b6-43ca-ac1a-299e6528d932', 'a8e79da1-d9c6-488b-a56d-d7061323dd8c',
      'c750eda2-9cce-460c-94bb-8cf1d51d2098', 'e10add1b-ecea-4fb9-aa4d-f97c7d316258',
      'a33e6860-8c73-422d-8e1d-322f34e776bf', 'ee27b89a-7d9b-4198-847f-c25f3262e115',
      '1b79f5a0-bc6b-4815-9189-baae7ab96120', 'cab29fb0-4a54-4449-8444-28192e41d942',
      '078dede2-3bdf-43a5-92a0-9e4ed40c81eb', '62d408fc-4095-4e25-b1c3-900555bb08e2',
      'bc614526-b879-47f5-b908-184338a96a83', '55a6ead9-d7ee-4fe2-a518-608bc63189c8',
      '9f7d4dce-e58d-41e6-a9d1-87df211a9a2b', '01883938-ea2e-485f-99c8-1c30e851940c',
      'b4ffd46e-f2d2-480f-8439-b7463c253dec', '4142bec4-295c-4c22-bda4-3b9a86217358'
    )
  RETURNING id
)
SELECT
  (SELECT count(*) FROM del_backers) AS backers_deleted,
  (SELECT count(*) FROM del_tiers) AS tiers_deleted,
  (SELECT count(*) FROM del_tasks) AS tasks_deleted,
  (SELECT count(*) FROM del_checklists) AS checklists_deleted,
  (SELECT count(*) FROM del_links) AS links_deleted,
  (SELECT count(*) FROM del_atts) AS attachments_deleted;
