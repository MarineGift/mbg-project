-- ============================================================
-- seed_20261014k_malaysia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Malaysia update (reports "Malaysia PCC/GCC producers" + "Malaysia paper
-- companies", 2026-10). Already in URM: Zantat, Calrock, Muda Kajang and
-- Tasek, Sabah Forest Industries and the SMI Sipitang satellite link.
--
-- 1) SMI -> Sabah Forest Industries Sipitang: active -> HISTORICAL.
--    Checked: mill halted by 2019 (state chief minister), company in
--    receivership, land taken back 2025. active_until 2019-01-01.
-- 2) Filler rows if missing + profiles: MRC Industries, Schaefer Kalk
--    (Malaysia) - PCC plant confirmed, Omya (Malaysia), Imerys Minerals
--    Malaysia, RCI Lime, Jayatrade. Lon Dah skipped (plastics masterbatch).
--    Zantat: notes line appended (320 kt Ipoh GCC, PCC powder imported).
-- 3) Mill rows if missing: NTPM, Kimberly-Clark Kluang, GS Paperboard
--    Banting, Lee and Man Malaysia, Nine Dragons Malaysia, Fudak.
-- 4) Plant blocks, Malaysia priority 1-6:
--      1 NTPM (tissue)  2 Kimberly-Clark Kluang  3 GS Paperboard (PM2 white
--      top liner)  4 Muda Kajang  5 Lee and Man  6 Nine Dragons
--    context: Muda Tasek, Fudak, Pascorp (ceased 2025-08), SFI (halted).
--    FCC scenario only for GS PM2 white top (55 kt). No supply links added -
--    no mill-filler pair is confirmed in public sources.
--
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 1) SIPITANG LINK -> HISTORICAL ----------
update app.party_supply_links l
set link_type = 'historical',
    active_until = coalesce(l.active_until, '2019-01-01'::date),
    notes = coalesce(nullif(btrim(l.notes), '') || ' | ', '')
            || 'Marked historical 2026-10-14: SFI Sipitang mill halted by 2019, company in receivership, land taken back 2025.',
    extra_data = coalesce(l.extra_data, '{}'::jsonb) || jsonb_build_object('historical_batch', 'malaysia_update_20261014'),
    updated_at = now()
where l.deleted_at is null and l.link_type <> 'historical'
  and l.mill_party_id in (select p.id from app.parties p
                          where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'MY'
                            and (p.party_name ilike '%Sabah Forest%' or p.party_name ilike '%Sipitang%'));

-- ---------- 2) FILLER ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 3::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 3 and x.deleted_at is null and x.country_code = 'MY'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'MY', v.region, v.city, v.website, 'active', 'malaysia_update_20261014', v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('MRC Industries', '%MRC Industries%', 'Perak', 'Kampung Kepayang', 'https://www.mrcindustries.com.my', 'GCC, PCC and kaolin maker. Plant Lot 225083, Tungzen Industrial Park, Mukim Sungai Raia, Kampung Kepayang, Perak. German-technology wet grinding lines added 2013, 2016 and 2020. Own PCC synthesis, capacity and paper customers not confirmed.'),
  ('Schaefer Kalk (Malaysia)', '%Schaefer Kalk%Malaysia%', 'Kedah', 'Kuala Ketil', 'https://www.schaeferkalk.de', 'Schaefer Kalk (Germany) Malaysian plant, Lot 45 and 46 Kawasan Industrie, Kuala Ketil, Kedah - limestone quarry, two GGR lime kilns, one RCE vertical kiln, hydrated lime plant and one PCC plant. Paper-grade PCC, slurry supply, capacity and paper customers not confirmed.'),
  ('Omya (Malaysia)', 'Omya%Malaysia%', 'Selangor', 'Shah Alam', 'https://www.omya.com', 'Omya Malaysia Sdn Bhd, Lot 6, Jalan Teluk Pulai 27/88, Section 27, Shah Alam, Selangor - calcium carbonate and specialty chemicals. A dedicated paper-grade plant in Malaysia is not confirmed, and Malaysia was not in the 2023 Asia plant list. Royalty licensee at Omya HQ level.'),
  ('Imerys Minerals Malaysia', '%Imerys%Malaysia%', 'Kuala Lumpur', 'Kuala Lumpur', 'https://www.imerys.com', 'Imerys Minerals Malaysia Sdn Bhd, Kuala Lumpur - IMERCARB calcium carbonate listed by the Malaysian plastics association. Local plant, capacity and paper business owner (Imerys or Artemyn) not confirmed.'),
  ('RCI Lime', '%RCI Lime%', 'Perak', 'Gopeng', 'https://www.rci.com.my', 'Rock Chemical Industries (Malaysia), Lot 45157 and 45158, Gunung Panjang, Gopeng, Perak - GCC with adjustable grinding, lime. Published uses are construction, mining and soil stabilisation - paper-grade GCC to be confirmed.'),
  ('Jayatrade Manufacturing', '%Jayatrade%', 'Negeri Sembilan', 'Seremban', null, 'GCC maker in Seremban. A staging web page lists about 8,000 t/month and paper among uses - recheck current output.')
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
  ('MRC Industries', 'GCC producer', 'Perak wet-ground GCC - local FCC pilot candidate', 'merchant', 'C', 'gcc'),
  ('Schaefer Kalk (Malaysia)', 'PCC producer', 'Malaysia PCC plant (synthesis confirmed)', 'merchant', 'B', 'pcc'),
  ('Omya (Malaysia)', 'GCC producer', 'Omya Malaysia - regional sales and supply', 'merchant', 'C', 'gcc'),
  ('Imerys Minerals Malaysia', 'GCC producer', 'Calcium carbonate supplier - plant unconfirmed', 'merchant', 'C', 'gcc'),
  ('RCI Lime', 'GCC producer', 'Perak GCC and lime - paper role unconfirmed', 'merchant', 'C', 'gcc'),
  ('Jayatrade Manufacturing', 'GCC producer', 'Seremban GCC', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'malaysia_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

update app.parties p
set notes = coalesce(nullif(btrim(p.notes), '') || ' | ', '') || 'Malaysia check 2026-10-14: Ipoh GCC 320,000 t/yr (paper, plastics, paint), Kuala Lumpur dispersion plant 60,000 t/yr (mainly latex gloves). PCC powder for its PCC dispersions is imported (China) per the sustainability report - Zantat does not synthesise PCC. Top local FCC production partner candidate (GCC slurry, wet milling, bulk tankers).',
    updated_at = now()
where p.party_type_id = 3 and p.deleted_at is null and p.country_code = 'MY'
  and p.party_name ilike 'Zantat%'
  and coalesce(p.notes, '') not ilike '%320,000 t/yr%';

-- ---------- 3) MILL ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 2::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 2 and x.deleted_at is null and x.country_code = 'MY'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'MY', v.region, v.city, v.website, 'active', 'malaysia_update_20261014', v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('%Nibong Tebal%', '%NTPM%', 'Nibong Tebal Paper Mill (NTPM) - Nibong Tebal (Penang)', 'Penang', 'Nibong Tebal', 'https://www.ntpm.com.my', 'NTPM tissue and MG paper mill, founded 1975, paper since 1979.'),
  ('%Kimberly%', '%Kimberly%Kluang%', 'Kimberly-Clark Malaysia - Kluang Mill (Kluang)', 'Johor', 'Kluang', 'https://www.kimberly-clark.com', 'Kimberly-Clark tissue mill, Kluang Industrial Area, Johor - Kleenex facial tissue and Scott towels.'),
  ('%GS Paperboard%', '%GSPP%', 'GS Paperboard & Packaging - Banting Mill (Banting)', 'Selangor', 'Banting', 'https://www.gspp.com.my', 'Oji group recycled packaging mill at Lot 7090, Mukim Tanjung 12, Banting, Selangor - three paper machines.'),
  ('%Lee & Man%', '%Lee and Man%', 'Lee & Man Paper - Malaysia Mill (Selangor)', 'Selangor', null, 'https://www.leemanpaper.com', 'Lee and Man Paper Manufacturing Malaysian recycled packaging paper mill, Selangor.'),
  ('%Nine Dragons%', '%ND Paper%', 'Nine Dragons Paper - Malaysia Base (Selangor)', 'Selangor', null, 'https://www.ndpaper.com', 'Nine Dragons Malaysian base - Selangor paper mill (two machines started 2023) and Bentong recycled pulp mill (acquired 2019).'),
  ('%Fudak%', '%Fudak%', 'Fudak - Johor (Johor)', 'Johor', null, null, 'Johor tissue and disposable hygiene products company, founded 1988 - own paper machine not confirmed.')
) as v(name_like, alt_like, party_name, region, city, website, notes)
where not exists (
  select 1 from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MY'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
);

-- ---------- 4) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (values
  ('%Nibong Tebal%', '%NTPM%', '%Nibong%'),
  ('%Kimberly%', '%Kimberly%Kluang%', '%Kimberly%'),
  ('%GS Paperboard%', '%GSPP%', '%GS Paper%'),
  ('%Muda%Kajang%', '%Kajang%', '%Muda%'),
  ('%Muda%Tasek%', '%Tasek%', '%Muda%'),
  ('%Lee & Man%', '%Lee and Man%', '%Lee%Man%'),
  ('%Nine Dragons%', '%ND Paper%', '%Nine Dragons%'),
  ('%Fudak%', '%Fudak%', '%Fudak%'),
  ('%Pascorp%', '%Pascorp%', '%Pascorp%'),
  ('%Sabah Forest%', '%Sipitang%', '%Sabah Forest%')
) as v(name_like, alt_like, owner_like)
cross join lateral (
  select y.id from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MY'
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MY'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Nibong Tebal%', '%NTPM%', '%Nibong%',
   $pj${"owner": "Nibong Tebal Paper Mill Holdings (NTPM)", "priority": 1, "products": "Toilet and facial tissue, kitchen and hand towel, napkins, core wrap, MG paper", "grades": ["Toilet tissue", "Facial tissue", "Towel", "MG paper"], "machines": 21, "pitch": "Compare directly with the MBG 15 gsm tissue trial (5 pct FCC) - pulp saving with strength, stretch, softness, brightness, retention and dust measured together", "approach": "First Malaysian technical meeting. Machine widths 1,690 / 2,820 / 2,850 mm, capacity not published. Separate virgin and recycled-fibre tissue - recycled adds brightness and contaminant questions. Filler partner later (Zantat, MRC or Omya).", "to_collect": ["Current filler (PCC / GCC) per machine, if any, and supplier", "Furnish - virgin versus recycled fibre per grade", "Strength, softness, dust and absorbency limits for a trial", "Who approves a machine trial"], "sources": [{"label": "ntpm.com.my"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Kimberly%', '%Kimberly%Kluang%', '%Kimberly%',
   $pj${"owner": "Kimberly-Clark", "priority": 2, "products": "Kleenex facial tissue, Scott paper towels", "grades": ["Facial tissue", "Towel"], "pitch": "A tissue win here can roll out to other Kimberly-Clark mills", "approach": "Go through global technical / R and D. Expect a longer cycle - raw-material change approval and consumer safety review.", "to_collect": ["Current filler (PCC / GCC) per machine, if any, and supplier", "Furnish - virgin versus recycled fibre per grade", "Strength, softness, dust and absorbency limits for a trial", "Who approves a machine trial"], "sources": [{"label": "Kimberly-Clark sustainability reporting, contractor project list"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%GS Paperboard%', '%GSPP%', '%GS Paper%',
   $pj${"owner": "Oji Holdings - GS Paperboard and Packaging", "priority": 3, "products": "Corrugating medium, testliner, kraft top and white top liner, lightweight recycled packaging", "grades": ["White top liner", "Testliner", "Corrugating medium"], "machines": 3, "capacity": {"value": 55000, "unit": "metric_t", "year": "PM2 white top liner - company site", "source": "gspp.com.my"}, "capacity_split": [{"label": "PM1 medium, testliner, kraft top", "value_t": 240000}, {"label": "PM2 white top liner", "value_t": 55000}, {"label": "PM3 lightweight recycled (about RM1.2bn)", "value_t": 450000}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Scenario on PM2 white top liner only, not orders. FCC goes in the white top ply - other plies are a separate question."}, "pitch": "FCC in the white top ply - optics with pulp saving", "approach": "PM2 trial first. Check top-ply furnish, ash, ply bond and printability. Oji link connects to the Japan program.", "to_collect": ["Current filler use per machine (t/yr) and supplier", "Ash and strength specs per grade - compression, burst, ply bond", "Drainage and drying energy baseline", "Who approves a machine trial"], "sources": [{"label": "gspp.com.my"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Muda%Kajang%', '%Kajang%', '%Muda%',
   $pj${"owner": "Muda Holdings Berhad", "priority": 4, "products": "Testliner, corrugating medium, chip board, core board, wrapping paper", "grades": ["Testliner", "Chip board", "Core board"], "capacity_split": [{"label": "Kajang plus Tasek mills, older company figure", "value_t": 400000}], "pitch": "Cost-down on a specific grade - Muda is looking for savings", "approach": "Local decision-making - pilot one grade. 2025: revenue RM1.43bn, EBITDA RM58.1m, pre-tax loss RM62.1m.", "to_collect": ["Current filler use per machine (t/yr) and supplier", "Ash and strength specs per grade - compression, burst, ply bond", "Drainage and drying energy baseline", "Who approves a machine trial"], "sources": [{"label": "Muda 2025 annual report"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Muda%Tasek%', '%Tasek%', '%Muda%',
   $pj${"owner": "Muda Holdings Berhad", "products": "Packaging grades and paperboard", "approach": "Second Muda mill - follow the Kajang pilot.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Lee & Man%', '%Lee and Man%', '%Lee%Man%',
   $pj${"owner": "Lee and Man Paper Manufacturing", "priority": 5, "products": "Recycled-fibre industrial packaging paper", "capacity_split": [{"label": "Malaysia mill, 2025 annual report", "value_t": 1400000}], "pitch": "Lightweight packaging with strength held", "approach": "Do not count the 1.4 Mt as FCC volume - filler can hurt compression, burst and bonding in recycled board. Joint development of a lightweight grade.", "to_collect": ["Current filler use per machine (t/yr) and supplier", "Ash and strength specs per grade - compression, burst, ply bond", "Drainage and drying energy baseline", "Who approves a machine trial"], "sources": [{"label": "Lee and Man 2025 annual report"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Nine Dragons%', '%ND Paper%', '%Nine Dragons%',
   $pj${"owner": "Nine Dragons Paper (Holdings)", "priority": 6, "products": "Kraftliner, corrugating medium, recycled pulp", "machines": 2, "capacity_split": [{"label": "Selangor paper (PMs started 2023 Q2 and Q3)", "value_t": 900000}, {"label": "Bentong recycled pulp", "value_t": 480000}], "pitch": "Recycled pulp quality and high-strength lightweight board", "approach": "Long-term development. Filler use not known - test before sizing.", "to_collect": ["Current filler use per machine (t/yr) and supplier", "Ash and strength specs per grade - compression, burst, ply bond", "Drainage and drying energy baseline", "Who approves a machine trial"], "sources": [{"label": "Nine Dragons Malaysia base page"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Fudak%', '%Fudak%', '%Fudak%',
   $pj${"owner": "Fudak Sdn Bhd", "products": "Tissue and disposable hygiene products", "approach": "Confirm first whether Fudak makes its own tissue base paper - a converter buying jumbo rolls cannot use FCC.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Pascorp%', '%Pascorp%', '%Pascorp%',
   $pj${"owner": "Pascorp Paper Industries", "products": "Recycled packaging base paper (Bentong)", "approach": "Excluded - operations ceased 2025-08-15. Recheck only if restarted or sold.", "recent": [{"date": "2025-08-15", "text": "Company announced operations ceased"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Sabah Forest%', '%Sipitang%', '%Sabah Forest%',
   $pj${"owner": "Sabah Forest Industries (in receivership)", "products": "Formerly pulp (about 243,000 t/yr) and printing paper (about 144,000 t/yr)", "filler": [{"supplier": "Specialty Minerals (MTI)", "type": "Satellite PCC", "status": "Historical - mill halted", "basis": "Satellite built early 2000s, link now marked historical"}], "approach": "Excluded - mill halted, company bankrupt, state took back the land. A state consortium talks of a restart - recheck only then.", "recent": [{"date": "2019", "text": "Mill reported ground to a halt, machinery largely scrap (state chief minister)"}, {"date": "2025", "text": "Company in receivership, ex-workers moved off the estate"}], "sources": [{"label": "The Malaysian Insight 2019, The Edge 2021, The Vibes 2025"}], "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 5) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Nibong Tebal%', '%NTPM%', '%Nibong%'),
  ('%Kimberly%', '%Kimberly%Kluang%', '%Kimberly%'),
  ('%GS Paperboard%', '%GSPP%', '%GS Paper%'),
  ('%Muda%Kajang%', '%Kajang%', '%Muda%'),
  ('%Muda%Tasek%', '%Tasek%', '%Muda%'),
  ('%Lee & Man%', '%Lee and Man%', '%Lee%Man%'),
  ('%Nine Dragons%', '%ND Paper%', '%Nine Dragons%'),
  ('%Fudak%', '%Fudak%', '%Fudak%'),
  ('%Pascorp%', '%Pascorp%', '%Pascorp%'),
  ('%Sabah Forest%', '%Sipitang%', '%Sabah Forest%')
)
select 'mill' as kind, coalesce(m.party_name, 'MISSING ' || v.name_like) as name,
       case when m.source = 'malaysia_update_20261014' then 'added now' when m.id is null then '-' else 'already there' end as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as detail
from v
left join lateral (
  select y.id, y.party_name, y.source from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'MY'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
  order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
  limit 1
) m on true
left join app.paper_mill_profile mp on mp.party_id = m.id
union all
select 'filler', p.party_name,
       case when p.source = 'malaysia_update_20261014' then 'added now' else 'already there' end,
       case when p.party_name ilike 'Zantat%' and p.notes ilike '%320,000 t/yr%' then 'note added' else '-' end
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null
  and (p.party_name ilike '%MRC Industries%' or p.party_name ilike '%Schaefer Kalk%Malaysia%'
       or p.party_name ilike 'Omya%Malaysia%' or p.party_name ilike '%Imerys%Malaysia%'
       or p.party_name ilike '%RCI Lime%' or p.party_name ilike '%Jayatrade%'
       or (p.party_name ilike 'Zantat%' and p.country_code = 'MY'))
union all
select 'link', f.party_name || ' -> ' || m.party_name, l.link_type, coalesce(to_char(l.active_until, 'YYYY-MM-DD'), '-')
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and m.country_code = 'MY'
  and (m.party_name ilike '%Sabah Forest%' or m.party_name ilike '%Sipitang%')
order by 1, 4, 2;
