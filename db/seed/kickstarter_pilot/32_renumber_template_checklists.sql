UPDATE app.deal_checklists
SET sort_order = CASE title
      WHEN 'Confirm exit criteria for this stage' THEN 90
      WHEN 'Log latest notes and agree the next step' THEN 91
    END,
    updated_at = now()
WHERE deal_id = 'fb2249de-9a2d-4bab-81f9-4d8208db78a3'
  AND title IN (
    'Confirm exit criteria for this stage',
    'Log latest notes and agree the next step'
  );
