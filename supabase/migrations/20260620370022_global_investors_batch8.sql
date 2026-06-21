-- ============================================================
-- 20260620370022_global_investors_batch8.sql
-- BATCH 8: materials/chemical CVCs (4 firms). source='investor_global_2026Q3_b8'.
-- All investor_type cvc=3, priority='high'. Idempotent. ASCII only.
-- ============================================================
begin;

insert into app.parties (party_type_id, entity_type_id, party_name, status, source, country_code, region, city, website, organization_id)
select v.* from (values
  (1::smallint,1::smallint,'MC Global Innovation','active','investor_global_2026Q3_b8','JP',NULL,'Tokyo','https://www.mitsubishicorp.com','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'JSR Corporation','active','investor_global_2026Q3_b8','JP',NULL,'Tokyo','https://www.jsr.co.jp','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Sumitomo Chemical','active','investor_global_2026Q3_b8','US',NULL,'Cambridge','https://www.sumitomo-chem.co.jp','b25de8f2-1020-482f-9012-183f63883169'::uuid),
  (1::smallint,1::smallint,'Asahi Kasei Corporate Venture Capital','active','investor_global_2026Q3_b8','US',NULL,'Menlo Park','https://www.asahikaseiventures.com','b25de8f2-1020-482f-9012-183f63883169'::uuid)
) as v(party_type_id, entity_type_id, party_name, status, source, country_code, region, city, website, organization_id)
where not exists (select 1 from app.parties p where p.party_name=v.party_name and p.deleted_at is null);

insert into app.investor_profile (party_id, investor_type_id, sector_focus, geographic_focus, is_lead_investor, priority, organization_id)
select p.id, 3::smallint, v.sector_focus, v.geographic_focus, true, 'high', 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join (values
  ('MC Global Innovation', array['industrial','advanced_materials','energy','mobility','deep_tech']::text[], array['Asia','Global']::text[]),
  ('JSR Corporation', array['advanced_materials','deep_tech','life_science','healthcare']::text[], array['Asia','North America','Global']::text[]),
  ('Sumitomo Chemical', array['advanced_materials','healthcare','food_ag','climate']::text[], array['North America','Global']::text[]),
  ('Asahi Kasei Corporate Venture Capital', array['advanced_materials','energy','climate','healthcare']::text[], array['North America','Europe','Global']::text[])
) as v(party_name, sector_focus, geographic_focus) on v.party_name=p.party_name
where p.source='investor_global_2026Q3_b8' and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id=p.id);

insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, v.sector_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join app.investor_profile ip on ip.party_id=p.id join (values
  ('MC Global Innovation', 2),('MC Global Innovation', 1),('MC Global Innovation', 5),('MC Global Innovation', 11),('MC Global Innovation', 3),
  ('JSR Corporation', 1),('JSR Corporation', 3),('JSR Corporation', 16),('JSR Corporation', 9),
  ('Sumitomo Chemical', 1),('Sumitomo Chemical', 9),('Sumitomo Chemical', 12),('Sumitomo Chemical', 4),
  ('Asahi Kasei Corporate Venture Capital', 1),('Asahi Kasei Corporate Venture Capital', 5),('Asahi Kasei Corporate Venture Capital', 4),('Asahi Kasei Corporate Venture Capital', 9)
) as v(party_name, sector_id) on v.party_name=p.party_name
where p.source='investor_global_2026Q3_b8' and p.deleted_at is null
  and not exists (select 1 from app.investor_sector_focus z where z.investor_profile_id=ip.id and z.sector_id=v.sector_id::smallint);

insert into app.investor_stage_focus (investor_profile_id, stage_id, organization_id)
select ip.id, v.stage_id::smallint, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p join app.investor_profile ip on ip.party_id=p.id join (values
  ('MC Global Innovation', 2),('MC Global Innovation', 3),('MC Global Innovation', 4),('MC Global Innovation', 10),
  ('JSR Corporation', 3),('JSR Corporation', 4),('JSR Corporation', 10),
  ('Sumitomo Chemical', 2),('Sumitomo Chemical', 3),('Sumitomo Chemical', 4),
  ('Asahi Kasei Corporate Venture Capital', 2),('Asahi Kasei Corporate Venture Capital', 3),('Asahi Kasei Corporate Venture Capital', 4),('Asahi Kasei Corporate Venture Capital', 10)
) as v(party_name, stage_id) on v.party_name=p.party_name
where p.source='investor_global_2026Q3_b8' and p.deleted_at is null
  and not exists (select 1 from app.investor_stage_focus z where z.investor_profile_id=ip.id and z.stage_id=v.stage_id::smallint);

update app.parties set intro_en='Mitsubishi Corporation company-wide CVC (est. 2025, ~USD 700M), investing across industrial materials, energy, and mobility. Fit: MBG calcium-carbonate filler / bio-based materials align with its industrial-materials portfolio transformation.'
where party_name='MC Global Innovation' and source='investor_global_2026Q3_b8' and deleted_at is null;
update app.parties set intro_en='Tokyo-based advanced-materials maker (semiconductor/display materials, life sciences) running corporate venture funds. Fit: materials-innovation focus matches MBG functional-mineral / bio-material platform.'
where party_name='JSR Corporation' and source='investor_global_2026Q3_b8' and deleted_at is null;
update app.parties set intro_en='Sumitomo Chemical corporate venturing (Cambridge, MA office) in advanced materials, healthcare, and sustainable food. Fit: sustainability + materials thesis aligns with MBG bio-based filler.'
where party_name='Sumitomo Chemical' and source='investor_global_2026Q3_b8' and deleted_at is null;
update app.parties set intro_en='Asahi Kasei CVC (Menlo Park, since 2011; 50+ deals) in materials, energy, and carbon-neutrality startups. Fit: Care-for-Earth decarbonization thesis aligns with MBG low-carbon mineral materials.'
where party_name='Asahi Kasei Corporate Venture Capital' and source='investor_global_2026Q3_b8' and deleted_at is null;

insert into app.deals
  (party_id, pipeline_id, current_stage_id, deal_name, status, value_currency, priority,
   source, extra_data, organization_id, owner_user_id, next_step, next_step_date,
   expected_close_date, probability_pct, stage_entered_at, created_at, updated_at)
select p.id,
       'de80525d-5537-4971-ad8f-d2080a8e65b0'::uuid,
       '1147f55e-297d-4c82-b74d-0e7976a2db8e'::uuid,
       p.party_name || ' - Investor outreach',
       'active', 'USD', 'high', 'pipeline_seed_2026Q3', '{}'::jsonb,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       o.id, 'Send cold outreach email',
       (current_date + interval '3 days')::date,
       (current_date + interval '120 days')::date,
       10, now(), now(), now()
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
cross join (select id from app.users where is_owner=true and is_active=true order by created_at limit 1) o
where p.source='investor_global_2026Q3_b8' and p.party_type_id=1 and p.deleted_at is null
  and ip.priority='high'
  and not exists (select 1 from app.deals d where d.party_id=p.id
                  and d.pipeline_id='de80525d-5537-4971-ad8f-d2080a8e65b0'::uuid and d.deleted_at is null);

commit;
