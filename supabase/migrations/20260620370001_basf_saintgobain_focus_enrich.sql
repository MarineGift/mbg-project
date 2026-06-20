-- ============================================================
-- 20260620370001_basf_saintgobain_focus_enrich.sql
-- Follow-up to 20260620370000: BASF Venture Capital and Saint-Gobain NOVA
-- already existed (source investor_enrich_2026Q3_b3, tagged US with their
-- US regional offices) so the batch-1 parties insert skipped them by name.
--
-- This patch ONLY ADDS missing investor_sector_focus / investor_stage_focus
-- rows (advanced_materials=1, industrial=2, climate=4; stages per firm),
-- idempotent. It does NOT modify the existing parties or investor_profile
-- rows (no clobbering of country/city/website per playbook).
--
-- Vocab: sectors advanced_materials=1, industrial=2, climate=4;
--        stages series_a=3, series_b=4, seed=2.
-- ============================================================

begin;

-- ---------- sector focus (add if missing) ----------
insert into app.investor_sector_focus
  (investor_profile_id, sector_id, organization_id)
select ip.id, v.sector_id::smallint,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
join (values
  ('BASF Venture Capital', 1),
  ('BASF Venture Capital', 2),
  ('BASF Venture Capital', 4),
  ('Saint-Gobain NOVA', 1),
  ('Saint-Gobain NOVA', 2),
  ('Saint-Gobain NOVA', 4)
) as v(party_name, sector_id)
  on v.party_name = p.party_name
where p.deleted_at is null
  and not exists (
    select 1 from app.investor_sector_focus x
    where x.investor_profile_id = ip.id and x.sector_id = v.sector_id
  );

-- ---------- stage focus (add if missing) ----------
insert into app.investor_stage_focus
  (investor_profile_id, stage_id, organization_id)
select ip.id, v.stage_id::smallint,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
join (values
  ('BASF Venture Capital', 3),
  ('BASF Venture Capital', 4),
  ('Saint-Gobain NOVA', 2),
  ('Saint-Gobain NOVA', 3)
) as v(party_name, stage_id)
  on v.party_name = p.party_name
where p.deleted_at is null
  and not exists (
    select 1 from app.investor_stage_focus x
    where x.investor_profile_id = ip.id and x.stage_id = v.stage_id
  );

commit;

-- ============================================================
-- OPTIONAL (commented out): correct HQ location to match true headquarters.
-- Only run if you prefer HQ-accurate over US-office tagging. This DOES
-- overwrite country_code/city, so it is intentionally manual / opt-in.
--
-- update app.parties set country_code='DE', city='Ludwigshafen'
--   where id='d8982528-1994-4f19-958f-f4c267946c6c';   -- BASF Venture Capital
-- update app.parties set country_code='FR', city='Courbevoie'
--   where id='f717bcc6-6b00-423e-bc97-371db7f3bd53';   -- Saint-Gobain NOVA
-- ============================================================

-- Verify (BASF + Saint-Gobain now carry sectors 1/2/4):
--   select p.party_name, array_agg(sec.code order by sec.code) as sectors
--   from app.parties p
--   join app.investor_profile ip on ip.party_id=p.id
--   join app.investor_sector_focus isf on isf.investor_profile_id=ip.id
--   join app.sectors sec on sec.id=isf.sector_id
--   where p.party_name in ('BASF Venture Capital','Saint-Gobain NOVA')
--   group by p.party_name;
