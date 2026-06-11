INSERT INTO app.reward_tiers (
  id, organization_id, deal_id, name, description, min_amount, currency,
  limit_qty, estimated_delivery, sort_order, is_active
)
VALUES
  ('2902adbd-94ef-4c97-a38b-3bcb6838acb4', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', 'Early Bird', 'First 200 backers. One unit at launch discount.', 39, 'USD', 200, DATE '2026-12-15', 1, true),
  ('f86550e8-ada4-48d6-89b4-fda3b5443405', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', 'Standard', 'One unit at standard campaign price.', 49, 'USD', NULL, DATE '2026-12-15', 2, true),
  ('1080d70c-6794-40ce-bd8f-9450999940ba', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', 'Double Pack', 'Two units bundled.', 89, 'USD', NULL, DATE '2026-12-15', 3, true),
  ('0886142c-82ac-4419-9439-b245cc15e69a', 'b25de8f2-1020-482f-9012-183f63883169', 'fb2249de-9a2d-4bab-81f9-4d8208db78a3', 'Collector Limited', 'Limited 50. Numbered edition with extras.', 149, 'USD', 50, DATE '2026-12-20', 4, true)
ON CONFLICT (id) DO NOTHING;
