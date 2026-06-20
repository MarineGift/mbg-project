-- ============================================================
-- 20260620370018_pipeline_seed_deals.sql
-- Link promising parties into pipelines by creating deals at the initial stage.
--  (1) Investors pipeline  -> stage 'Cold outreach' : every priority='high' investor.
--  (2) Government Grant pipeline -> stage 'Identified' : grants noted HIGH / VERY HIGH fit.
-- Idempotent: NOT EXISTS on (party_id, pipeline_id) live deal. source='pipeline_seed_2026Q3'.
-- ASSUMED enum values (adjust if your deals CHECKs differ): status='open', value_currency='USD'.
--   If this errors on status/priority/currency, run the vocab query in chat and tell me.
-- ============================================================

begin;

-- (1) Investors: one deal per high-priority investor
insert into app.deals
  (party_id, pipeline_id, current_stage_id, deal_name, status, value_currency, priority,
   source, extra_data, organization_id, stage_entered_at, created_at, updated_at)
select p.id, 'de80525d-5537-4971-ad8f-d2080a8e65b0'::uuid, '1147f55e-297d-4c82-b74d-0e7976a2db8e'::uuid, p.party_name || ' - Investor outreach',
       'open', 'USD', coalesce(ip.priority,'medium'), 'pipeline_seed_2026Q3', '{}'::jsonb,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid, now(), now(), now()
from app.parties p join app.investor_profile ip on ip.party_id = p.id
where p.party_type_id = 1 and p.deleted_at is null and ip.priority = 'high'
  and not exists (select 1 from app.deals d where d.party_id = p.id
                  and d.pipeline_id = 'de80525d-5537-4971-ad8f-d2080a8e65b0'::uuid and d.deleted_at is null);

-- (2) Government grants: one deal per HIGH / VERY HIGH fit program
insert into app.deals
  (party_id, pipeline_id, current_stage_id, deal_name, status, value_currency, priority,
   source, extra_data, organization_id, stage_entered_at, created_at, updated_at)
select p.id, '4f898bc2-27ef-45d0-8aea-14143888b850'::uuid, 'a6059681-3965-45d7-9bc2-d45902cee290'::uuid, p.party_name || ' - Grant application',
       'open', 'USD', 'high', 'pipeline_seed_2026Q3', '{}'::jsonb,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid, now(), now(), now()
from app.parties p
where p.party_type_id = 7 and p.deleted_at is null and p.source = 'gov_grant_2026Q3'
  and (p.notes ilike '%%fit: HIGH%%' or p.notes ilike '%%fit: VERY HIGH%%')
  and not exists (select 1 from app.deals d where d.party_id = p.id
                  and d.pipeline_id = '4f898bc2-27ef-45d0-8aea-14143888b850'::uuid and d.deleted_at is null);

commit;

-- Verify:
-- select pl.name pipeline, count(*) from app.deals d join app.pipelines pl on pl.id=d.pipeline_id
-- where d.source='pipeline_seed_2026Q3' group by pl.name;
