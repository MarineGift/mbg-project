-- ============================================================
-- 20260620370020_filler_pipeline_seed_deals.sql
-- Link the 6 new filler suppliers (370013, source filler_gap_2026Q3) into the
-- 'Filler Suppliers' pipeline at the initial 'Prospect' stage by creating deals.
--   pipeline 'Filler Suppliers' = fb74a367-9b9a-4493-9277-ddf2c440c8a1
--   stage    'Prospect'         = 5e8737cc-f381-4987-9a1f-63617edc11d7
-- status='active' (live convention), priority='medium', currency='USD'.
-- Idempotent: NOT EXISTS on (party_id, pipeline_id) live deal. source='pipeline_seed_2026Q3'.
-- ============================================================

begin;

insert into app.deals
  (party_id, pipeline_id, current_stage_id, deal_name, status, value_currency, priority,
   source, extra_data, organization_id, stage_entered_at, created_at, updated_at)
select p.id,
       'fb74a367-9b9a-4493-9277-ddf2c440c8a1'::uuid,
       '5e8737cc-f381-4987-9a1f-63617edc11d7'::uuid,
       p.party_name || ' - Filler supplier eval',
       'active', 'USD', 'medium', 'pipeline_seed_2026Q3', '{}'::jsonb,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid, now(), now(), now()
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null
  and p.source = 'filler_gap_2026Q3'
  and not exists (select 1 from app.deals d
                  where d.party_id = p.id
                    and d.pipeline_id = 'fb74a367-9b9a-4493-9277-ddf2c440c8a1'::uuid
                    and d.deleted_at is null);

commit;
