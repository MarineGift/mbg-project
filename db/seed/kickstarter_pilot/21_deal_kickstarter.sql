INSERT INTO app.deals (
  id, organization_id, party_id, pipeline_id, current_stage_id,
  deal_name, description, status, probability_pct,
  value_amount, value_currency,
  start_date, end_date, expected_close_date,
  priority, source, next_step, next_step_date, stage_entered_at
)
VALUES (
  'fb2249de-9a2d-4bab-81f9-4d8208db78a3',
  'b25de8f2-1020-482f-9012-183f63883169',
  '5d88a6a7-3959-4284-806b-b03fc0aad411',
  '69460e08-b65e-4a8a-bae7-03b6393c6c73',
  'ed43f78a-2a24-4883-98f4-c659bdef685a',
  'Kickstarter - MarineBio Crowdfunding (Pilot)',
  'Pilot run to test full Kickstarter preparation in URM. Funding goal 50,000 USD. Campaign window Sep 2026. Checklists, tasks, reward tiers, backers and Google Drive attachments are exercised end to end.',
  'active',
  5,
  50000,
  'USD',
  DATE '2026-09-01',
  DATE '2026-09-30',
  DATE '2026-09-30',
  'high',
  'kickstarter_pilot_2026Q3',
  'Confirm funding goal and budget',
  DATE '2026-06-19',
  now()
)
ON CONFLICT (id) DO NOTHING;
