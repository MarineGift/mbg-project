INSERT INTO app.deal_parties (
  id, organization_id, deal_id, party_id, role, currency
)
VALUES (
  '6d771e14-f128-4b73-aa84-6c5d26a05c82',
  'b25de8f2-1020-482f-9012-183f63883169',
  'fb2249de-9a2d-4bab-81f9-4d8208db78a3',
  '5d88a6a7-3959-4284-806b-b03fc0aad411',
  'primary',
  'USD'
)
ON CONFLICT (id) DO NOTHING;
