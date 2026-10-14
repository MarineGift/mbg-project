-- ============================================================
-- seed_20261014q_saudi_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Saudi Arabia update (report "Saudi paper companies", 2026-10). Already in
-- URM: MEPCO, WARAQ, Obeikan, NAPCO (converter - not a target).
--
-- 1) Filler rows if missing + profiles: Saudi Carbonate (Riyadh, about
--    200 kt GCC and PCC, Omya partner - IMFORMED), Saudi Marble (Jeddah,
--    about 80 kt), Arabian Carbonate (named in the report - to verify).
-- 2) Mill rows if missing: Saudi Paper Dammam, Juthor KAEC, Al-Faris Jeddah.
-- 3) Plant blocks, Saudi priority 1-6:
--      1 Saudi Paper (tissue, 190 kt, PM5 2025-09)  2 Juthor (13.5-15.5 gsm
--      virgin facial, TM6 moved to 2027 Q1)  3 Al-Faris (virgin tissue)
--      4 Obeikan (duplex 220 kt)  5 MEPCO (500 kt + PM5 450 kt 2027)
--      6 WARAQ   context: Gulf Paper Industries
--    No FCC scenarios (tissue and board need trial data first). No supply
--    links - no mill-filler pair publicly confirmed.
--
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 1) FILLER ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 3::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 3 and x.deleted_at is null and x.country_code = 'SA'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'SA', v.region, v.city, v.website, 'active', 'saudi_update_20261014', v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Saudi Carbonate Company (SCC)', '%Saudi Carbonate%', 'Riyadh', 'Riyadh', null, 'Riyadh GCC and PCC producer, about 200,000 t/yr plant (IMFORMED). Names Jordan Carbonate and Omya among its partners and has promoted PCC with Omya at trade shows. Paper supply in Saudi Arabia not confirmed.'),
  ('Saudi Marble Company', '%Saudi Marble%', 'Makkah Province', 'Jeddah', null, 'Jeddah GCC producer, about 80,000 t/yr plant (IMFORMED). Paper grades not confirmed.'),
  ('Arabian Carbonate', '%Arabian Carbonate%', 'Makkah Province', 'Jeddah', null, 'Western-region GCC maker named in the 2026-10 report near the Jeddah and KAEC mills. Plant, capacity and paper grades to confirm.')
) as v(party_name, guard_like, region, city, website, notes)
where not exists (
  select 1 from app.parties p
  where p.party_type_id = 3 and p.deleted_at is null and p.party_name ilike v.guard_like
);

insert into app.filler_supplier_profile
  (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
   mineral_class, industry_source, extra_data, created_at, updated_at)
select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
       d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
from app.parties p
join (values
  ('Saudi Carbonate Company (SCC)', 'GCC producer', 'Saudi GCC and PCC - Omya partner', 'merchant', 'C', 'gcc'),
  ('Saudi Marble Company', 'GCC producer', 'Jeddah GCC', 'merchant', 'C', 'gcc'),
  ('Arabian Carbonate', 'GCC producer', 'Western Saudi GCC - to verify', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'saudi_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null and x.country_code = 'SA'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'SA', v.region, v.city, v.website, 'active', 'saudi_update_20261014', v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Saudi Paper%', '%SPMC%', 'Saudi Paper Manufacturing - Dammam Mill (Dammam)', 'Eastern Province', 'Dammam', 'https://www.saudipaper.com', 'Saudi Paper Manufacturing Company (Tadawul 2300), founded 1989 - tissue base paper mill in Dammam, virgin and recycled fibre, deinking and recycling.'),
  ('%Juthor%', '%Juthor%', 'Juthor Paper Manufacturing - KAEC Mill (King Abdullah Economic City)', 'Makkah Province', 'King Abdullah Economic City', 'https://www.juthor.com.sa', 'Juthor Paper Manufacturing (MEPCO group) premium tissue mill at King Abdullah Economic City.'),
  ('%Faris%', '%Al Faris%', 'Al-Faris Paper Mill (Jeddah)', 'Makkah Province', 'Jeddah', 'https://www.fpm.sa', 'Al-Faris Paper Mill, Jeddah Third Industrial City - SAR 200m tissue base paper mill, 2.8 m width, 100 pct virgin wood pulp, feeds the group converting plant at Khamis Mushait.')
) as v(name_like, alt_like, party_name, region, city, website, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SA'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- ---------- 3) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (values
  ('%Saudi Paper%', '%SPMC%', '%Saudi Paper%'),
  ('%Juthor%', '%Juthor%', '%Juthor%'),
  ('%Faris%', '%Al Faris%', '%Faris%'),
  ('%Obeikan%', '%Obeikan Paper%', '%Obeikan%'),
  ('%MEPCO%', '%Middle East Paper%', '%MEPCO%'),
  ('%WARAQ%', '%Arab Paper%', '%WARAQ%'),
  ('%Gulf Paper%', '%Gulf Paper%', '%Gulf Paper%')
) as v(name_like, alt_like, owner_like)
cross join lateral (
  select y.id from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SA'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
  order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
  limit 1
) m
where not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);

update app.paper_mill_profile mp
set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', m.plant),
    main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
    updated_at = now()
from (
  select v.plant,
         (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SA'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Saudi Paper%', '%SPMC%', '%Saudi Paper%',
   $pj${"owner": "Saudi Paper Group (Tadawul 2300)", "priority": 1, "products": "Toilet, facial, napkin and kitchen towel base paper", "grades": ["Toilet tissue", "Facial tissue", "Towel", "Napkin"], "machines": 5, "capacity_split": [{"label": "Nameplate, all five machines", "value_t": 190000}, {"label": "PM5 (Toscotec AHEAD 2.2L, 5,600 mm, 2,200 m/min)", "value_t": 60000}], "pitch": "Tissue FCC - MBG 15 gsm virgin-pulp trial (5 pct FCC) as the opening case", "approach": "Lead Saudi account. High-speed line - show pulp saving and quality held together: tensile, absorbency, softness, roughness, dust, retention. Filler partner later (Saudi Carbonate).", "recent": [{"date": "2025-09-29", "text": "PM5 tissue line in commercial operation (Tadawul announcement)"}], "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "sources": [{"label": "Tadawul disclosure 2025-09-29"}, {"label": "Toscotec"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Juthor%', '%Juthor%', '%Juthor%',
   $pj${"owner": "Juthor Paper Manufacturing (MEPCO group)", "priority": 2, "products": "Toilet, facial (13.5-15.5 gsm, 100 pct virgin pulp), kitchen towel, napkin, pocket tissue", "grades": ["Facial tissue", "Toilet tissue", "Towel"], "capacity_split": [{"label": "Current", "value_t": 60000}, {"label": "After TM6 (ANDRITZ)", "value_t": 120000}], "pitch": "Facial tissue at 13.5-15.5 gsm virgin pulp is the closest match to the MBG 15 gsm trial", "approach": "Joint evaluation on the existing line first, then extend to TM6. MEPCO group - one approach covers both.", "recent": [{"date": "2026-09-30", "text": "TM6 start moved to 2027 Q1 trial and commercial run (was 2026 Q4) - supply chain delays, Tadawul"}], "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "sources": [{"label": "Tadawul disclosure 2026-09-30"}, {"label": "juthor.com.sa"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Faris%', '%Al Faris%', '%Faris%',
   $pj${"owner": "Al-Faris group", "priority": 3, "products": "Tissue base paper - toilet, napkin, kitchen towel (100 pct virgin pulp)", "grades": ["Tissue"], "pitch": "Pure virgin-pulp tissue - clearest pulp-saving case", "approach": "Mill plus own converting - savings flow to finished goods. Capacity not published.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "sources": [{"label": "fpm.sa"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Obeikan%', '%Obeikan Paper%', '%Obeikan%',
   $pj${"owner": "Obeikan Investment Group - Obeikan Paper Industries", "priority": 4, "products": "Duplex board 250-450 gsm, exported to 20+ countries", "grades": ["Duplex board"], "capacity_split": [{"label": "Duplex board", "value_t": 220000}], "pitch": "Fibre saving with stiffness and ply bond held", "approach": "Ply-by-ply trial - top, middle, back. Current PCC / GCC use per ply not known.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT specs", "Which grades or plies could take a filler", "Who approves a machine trial"], "sources": [{"label": "obeikanindustrial.com.sa"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%MEPCO%', '%Middle East Paper%', '%MEPCO%',
   $pj${"owner": "Middle East Paper Company (MEPCO, PIF portfolio)", "priority": 5, "products": "Testliner, kraftliner, fluting, white top liner, coreboard, plasterboard liner, absorbent kraft", "grades": ["White top liner", "Testliner", "Fluting"], "machines": 3, "capacity_split": [{"label": "Current, three machines", "value_t": 500000}, {"label": "PM5 under construction (Voith), 2027", "value_t": 450000}], "pitch": "Start small on white top liner", "approach": "Strength-led packaging - tissue and printing data do not transfer. Group owner of Juthor.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT specs", "Which grades or plies could take a filler", "Who approves a machine trial"], "sources": [{"label": "PIF portfolio, mep.co"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%WARAQ%', '%Arab Paper%', '%WARAQ%',
   $pj${"owner": "Arab Paper Manufacturing Company (WARAQ)", "priority": 6, "products": "Testliner, semi-kraft liner, fluting, wet-strength fluting, semi-kraft white top liner, coreboard, saturating kraft", "grades": ["White top liner", "Testliner"], "pitch": "White top liner surface ply", "approach": "Founded 1994, Dammam Second Industrial City, recycled fibre. Technical trial needed.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT specs", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Gulf Paper%', '%Gulf Paper%', '%Gulf Paper%',
   $pj${"owner": "Gulf Paper Industries Factory", "products": "Directory lists printing and writing, duplex, kraft and tissue", "approach": "Confirm which grades are actually produced.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 4) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Saudi Paper%', '%SPMC%', '%Saudi Paper%'),
  ('%Juthor%', '%Juthor%', '%Juthor%'),
  ('%Faris%', '%Al Faris%', '%Faris%'),
  ('%Obeikan%', '%Obeikan Paper%', '%Obeikan%'),
  ('%MEPCO%', '%Middle East Paper%', '%MEPCO%'),
  ('%WARAQ%', '%Arab Paper%', '%WARAQ%'),
  ('%Gulf Paper%', '%Gulf Paper%', '%Gulf Paper%')
)
select 'mill' as kind, coalesce(m.party_name, 'MISSING ' || v.name_like) as name,
       case when m.source = 'saudi_update_20261014' then 'added now' when m.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as detail
from v
left join lateral (
  select y.id, y.party_name, y.source from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'SA'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
  order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
  limit 1
) m on true
left join app.paper_mill_profile mp on mp.party_id = m.id
union all
select 'filler', p.party_name,
       case when p.source = 'saudi_update_20261014' then 'added now' else 'already there' end, '-'
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ilike '%Saudi Carbonate%' or p.party_name ilike '%Saudi Marble%' or p.party_name ilike '%Arabian Carbonate%')
order by 1, 4, 2;
