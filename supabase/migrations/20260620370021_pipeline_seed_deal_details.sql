-- ============================================================
-- 20260620370021_pipeline_seed_deal_details.sql
-- Fill detail fields on the 92 deals seeded as source='pipeline_seed_2026Q3'
--   (370018: Investors=78 + Government Grant=8 ; 370020: Filler Suppliers=6).
-- Owner resolved as the single active is_owner=true user; idempotent on next_step is null.
-- ============================================================
begin;

-- (1) Investors / Cold outreach (78)
update app.deals d
set owner_user_id=o.id, next_step='Send cold outreach email',
    next_step_date=(current_date + interval '3 days')::date,
    expected_close_date=(current_date + interval '120 days')::date,
    probability_pct=10, updated_at=now()
from (select id from app.users where is_owner=true and is_active=true order by created_at limit 1) o
where d.source='pipeline_seed_2026Q3'
  and d.pipeline_id='de80525d-5537-4971-ad8f-d2080a8e65b0'::uuid
  and d.deleted_at is null and d.next_step is null;

-- (2) Government Grant / Identified (8)
update app.deals d
set owner_user_id=o.id, next_step='Review eligibility and deadlines',
    next_step_date=(current_date + interval '7 days')::date,
    expected_close_date=(current_date + interval '180 days')::date,
    probability_pct=15, updated_at=now()
from (select id from app.users where is_owner=true and is_active=true order by created_at limit 1) o
where d.source='pipeline_seed_2026Q3'
  and d.pipeline_id='4f898bc2-27ef-45d0-8aea-14143888b850'::uuid
  and d.deleted_at is null and d.next_step is null;

-- (3) Filler Suppliers / Prospect (6)
update app.deals d
set owner_user_id=o.id, next_step='Initial qualification and contact',
    next_step_date=(current_date + interval '5 days')::date,
    expected_close_date=(current_date + interval '90 days')::date,
    probability_pct=10, updated_at=now()
from (select id from app.users where is_owner=true and is_active=true order by created_at limit 1) o
where d.source='pipeline_seed_2026Q3'
  and d.pipeline_id='fb74a367-9b9a-4493-9277-ddf2c440c8a1'::uuid
  and d.deleted_at is null and d.next_step is null;

commit;
