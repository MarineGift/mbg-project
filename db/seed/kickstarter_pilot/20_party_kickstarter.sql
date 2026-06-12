INSERT INTO app.parties (
  id, organization_id, party_type_id, entity_type_id, party_name,
  country_code, website, status, source, notes
)
VALUES (
  '5d88a6a7-3959-4284-806b-b03fc0aad411',
  'b25de8f2-1020-482f-9012-183f63883169',
  9,
  1,
  'Kickstarter',
  'US',
  'https://www.kickstarter.com',
  'active',
  'kickstarter_pilot_2026Q3',
  'Crowdfunding platform party for the MarineBio Kickstarter pilot deal'
)
ON CONFLICT (id) DO NOTHING;
