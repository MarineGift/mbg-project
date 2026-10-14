-- ============================================================
-- seed_20261014i_indonesia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Indonesia update (reports "Indonesia PCC/GCC producers" + "Indonesia
-- paper companies", 2026-10). Already in URM and NOT redone: SMI satellite
-- links (Perawang unit 1 + unit 2) to PT Indah Kiat Perawang, and the APP,
-- APRIL, FajarPaper and Suparma mill rows.
--
-- 1) Filler rows if missing + profiles: Omya (Indonesia), PT Dwi Selo Giri
--    Mas, PT Aneka Sumberbumi Jaya, PT Supersonic Chemical Industry.
--    Addresses and phones go in notes (report-sourced, not verified as
--    contacts - email columns left alone).
-- 2) Plant blocks (Mill profile card), Indonesia priority 1-5:
--      1 Indah Kiat Perawang  2 APRIL Kerinci (PaperOne + BoardOne)
--      3 Pindo Deli  4 Tjiwi Kimia  5 Pura Group
--    context rows: Indah Kiat Serang, Tangerang, FajarPaper, Suparma,
--    Adiprima, Lontar Papyrus (APP group, not Mondi).
--    FCC scenario only for APRIL PaperOne (1.15 Mt paper). Indah Kiat
--    figures are company-wide 2019 - no single-mill scenario.
--    Mills matched on ID rows only - NOTHING created. Verify lists MISSING.
--
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 1) FILLER ROWS IF MISSING ----------
insert into app.parties
  (party_type_id, entity_type_id, party_name, country_code, region, city,
   website, status, source, notes, organization_id)
select 3::smallint,
       coalesce((select x.entity_type_id from app.parties x
                 where x.party_type_id = 3 and x.deleted_at is null and x.country_code = 'ID'
                 order by x.created_at limit 1), 1)::smallint,
       v.party_name, 'ID', v.region, v.city, v.website, 'active', 'indonesia_update_20261014',
       v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
from (values
  ('Omya (Indonesia)', 'Omya%Indonesia%', null, null, 'https://www.omya.com', 'Omya Indonesia. 2023 announcement: a new on-site GCC plant for paper and board in Sumatra, part of a seven-plant Asia plan (six China, one Indonesia, about 1.0 Mt/yr total - not an Indonesia figure). Host mill, capacity and current running status not public. Royalty licensee at Omya HQ level.'),
  ('PT Dwi Selo Giri Mas', '%Dwi Selo%', 'East Java', 'Sidoarjo', 'https://www.dwiselogirimas.com', 'Calcium carbonate maker since 1988. Head office and plant at Jl. Raya Tebel No. 50-A, Gedangan, Sidoarjo, East Java 61254, tel +62 31 8913030. Ground and classified GCC with Central Java limestone and calcite. Markets paper, paint, plastics, ceramics, chemicals across Java, Kalimantan and Sulawesi. Capacity not published.'),
  ('PT Aneka Sumberbumi Jaya', '%Aneka Sumber%', 'Lampung', 'Bandar Lampung', 'https://www.asj-indo.com', 'Founded 2004, own limestone quarries (over 50 ha in three areas) and plant at Bandar Lampung, Sumatra. GCC 120,000 t/yr (invested 2013), crushed limestone 350,000 t/yr, 80-1200 mesh. Paper listed among served industries. Office Jl. Ikan Mas No. 46, Bandar Lampung 35224, tel +62 721 488188, enquiry@asj-indo.com.'),
  ('PT Supersonic Chemical Industry', '%Supersonic Chemical%', 'Yogyakarta', 'Gunungkidul', 'https://www.supersonic.co.id', 'Founded 1974 at Sidoarjo, plant moved 1989 to Jl. Raya Mijahan Km. 3, Selang, Wonosari, Gunungkidul, Yogyakarta, tel +62 274 391628. Ground calcium carbonate powder, paper coating among uses. Current capacity not published. sales@supersonic.co.id.')
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
  ('Omya (Indonesia)', 'GCC producer', 'Omya on-site GCC for paper (Sumatra, announced 2023)', 'satellite (on-site)', 'C', 'gcc'),
  ('PT Dwi Selo Giri Mas', 'GCC producer', 'East Java GCC - local partner option', 'merchant', 'C', 'gcc'),
  ('PT Aneka Sumberbumi Jaya', 'GCC producer', 'Sumatra GCC with own quarry - raw material or OEM option', 'merchant', 'C', 'gcc'),
  ('PT Supersonic Chemical Industry', 'GCC producer', 'Central Java GCC powder - paper coating', 'merchant', 'C', 'gcc')
) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
  on p.party_name = d.party_name
where p.party_type_id = 3 and p.deleted_at is null and p.source = 'indonesia_update_20261014'
  and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);

-- ---------- 2) PLANT BLOCKS ----------
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from (values
  ('%Perawang%', '%Indah Kiat Pulp%', '%Indah Kiat%'),
  ('%Kerinci%', '%APRIL%', '%APRIL%'),
  ('%Pindo Deli%', '%Karawang%', '%Pindo%'),
  ('%Tjiwi%', '%Mojokerto%', '%Tjiwi%'),
  ('%Pura%Barutama%', '%Pura Group%', '%Pura%'),
  ('%Indah Kiat%Serang%', '%Serang%', '%Indah Kiat%'),
  ('%Indah Kiat%Tangerang%', '%Tangerang%', '%Indah Kiat%'),
  ('%Fajar%', '%Fajar Surya%', '%Fajar%'),
  ('%Suparma%', '%Suparma%', '%Suparma%'),
  ('%Adiprima%', '%Adiprima%', '%Adiprima%'),
  ('%Lontar%', '%Lontar Papyrus%', '%Lontar%')
) as v(name_like, alt_like, owner_like)
cross join lateral (
  select y.id from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ID'
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ID'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
          order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
          limit 1) as id
  from (values
  ('%Perawang%', '%Indah Kiat Pulp%', '%Indah Kiat%',
   $pj${"owner": "Asia Pulp and Paper (Sinar Mas) - PT Indah Kiat Pulp and Paper", "priority": 1, "products": "Pulp, printing and writing papers", "grades": ["Writing and printing", "Copy paper"], "capacity_split": [{"label": "Indah Kiat all mills - pulp (2019)", "value_t": 3000000}, {"label": "Indah Kiat all mills - printing and writing (2019)", "value_t": 1700000}, {"label": "Indah Kiat all mills - packaging (2019)", "value_t": 2100000}], "filler": [{"supplier": "Specialty Minerals (MTI) via PT Sinar Mas Specialty Minerals (MTI + APP JV)", "type": "Satellite PCC, two plants", "status": "Since 1997. 2017 plan: existing plant 100 to 140 kt plus a new 125 kt plant, 265 kt total", "basis": "MTI release 2017-05-02 - current running rate to confirm"}], "pitch": "Add an FCC step to the existing JV PCC supply - no new supply chain needed", "approach": "Top Indonesia target. Decision sits with the MTI-APP joint venture - confirm who approves new technology and who would pay the royalty.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual annual PCC and GCC use (t), filler versus coating pigment", "Internal pulp cost versus market pulp - sets the FCC saving", "Filler loading per grade and target increase", "Quality gates FCC must pass versus current filler", "Who approves a trial - mill, APP or APRIL group technical, purchasing"], "sources": [{"label": "MTI release 2017-05-02"}, {"label": "Indah Kiat company profile"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Kerinci%', '%APRIL%', '%APRIL%',
   $pj${"owner": "APRIL Group (RGE) - PT Riau Andalan Pulp and Paper", "priority": 2, "products": "PaperOne copy and printing paper, BoardOne / SilverPak FBB, cupstock, art board, pulp", "grades": ["Copy paper", "Printing paper", "Folding boxboard", "Cupstock"], "capacity": {"value": 1150000, "unit": "metric_t", "year": "PaperOne paper capacity (company disclosure)", "source": "APRIL Group"}, "capacity_split": [{"label": "PaperOne paper", "value_t": 1150000}, {"label": "Paperboard line - commissioning since 2024, about USD 2.3bn", "value_t": 1200000}], "filler": [{"supplier": "Not confirmed", "type": "-", "status": "Unknown", "basis": "No public PCC / GCC supplier found - check whether Omya's 2023 Sumatra GCC plant serves APRIL"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on the stated paper capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "PaperOne first - large copy-paper volume with clear quality metrics. Board later, per layer", "approach": "Direct technical evaluation. Vertically integrated pulp - argue on internal pulp opportunity cost, capacity release and carbon, not market pulp price.", "recent": [{"date": "2024", "text": "New 1.2 Mt/yr paperboard line started commissioning"}], "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual annual PCC and GCC use (t), filler versus coating pigment", "Internal pulp cost versus market pulp - sets the FCC saving", "Filler loading per grade and target increase", "Quality gates FCC must pass versus current filler", "Who approves a trial - mill, APP or APRIL group technical, purchasing"], "sources": [{"label": "APRIL Group disclosures, PEFC"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Pindo Deli%', '%Karawang%', '%Pindo%',
   $pj${"owner": "Asia Pulp and Paper (Sinar Mas) - Pindo Deli Pulp and Paper Mills", "priority": 3, "products": "Copy, printing and writing, coated, thermal and specialty papers, tissue", "grades": ["Copy paper", "Thermal", "Coated", "Tissue"], "pitch": "Test general FCC and tissue FCC on separate lines at one mill", "approach": "Approach with Tjiwi Kimia through APP. Thermal and specialty sheets need surface and coating checks.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual annual PCC and GCC use (t), filler versus coating pigment", "Internal pulp cost versus market pulp - sets the FCC saving", "Filler loading per grade and target increase", "Quality gates FCC must pass versus current filler", "Who approves a trial - mill, APP or APRIL group technical, purchasing"], "sources": [{"label": "APP business profile"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Tjiwi%', '%Mojokerto%', '%Tjiwi%',
   $pj${"owner": "Asia Pulp and Paper (Sinar Mas) - PT Pabrik Kertas Tjiwi Kimia Tbk", "priority": 4, "products": "Printing and writing papers and paper products", "grades": ["Writing and printing"], "pitch": "Early commercial candidate - writing and printing focus", "approach": "Also the natural mill for a local GCC partner (DSGM in East Java) if Omya or SMI are not the route.", "to_collect": ["Current PCC / GCC supplier per machine and contract term", "Actual annual PCC and GCC use (t), filler versus coating pigment", "Internal pulp cost versus market pulp - sets the FCC saving", "Filler loading per grade and target increase", "Quality gates FCC must pass versus current filler", "Who approves a trial - mill, APP or APRIL group technical, purchasing"], "sources": [{"label": "APP business profile"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Pura%Barutama%', '%Pura Group%', '%Pura%',
   $pj${"owner": "Pura Group - PT Pura Barutama", "priority": 5, "products": "Specialty, security, food and cigarette papers - integrated site over 100 ha at Kudus", "grades": ["Specialty", "Security paper"], "pitch": "Bulk, stiffness and smoothness gains in functional papers", "approach": "Security and cigarette papers carry certification - start on general specialty grades.", "sources": [{"label": "puragroup.com"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Indah Kiat%Serang%', '%Serang%', '%Indah Kiat%',
   $pj${"owner": "Asia Pulp and Paper (Sinar Mas) - PT Indah Kiat Pulp and Paper", "products": "Industrial board, liner and corrugating medium", "approach": "Packaging-led - do not assume copy-paper filler loading. Multi-ply board trials only.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Indah Kiat%Tangerang%', '%Tangerang%', '%Indah Kiat%',
   $pj${"owner": "Asia Pulp and Paper (Sinar Mas) - PT Indah Kiat Pulp and Paper", "products": "Specialty and printing papers", "approach": "Grade-specific FCC check after Perawang.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Fajar%', '%Fajar Surya%', '%Fajar%',
   $pj${"owner": "PT Fajar Surya Wisesa Tbk (SCG Packaging)", "products": "Kraft liner, corrugating medium, coated duplex board - recycled fibre", "capacity_split": [{"label": "FajarPaper plus PT Dayasa Aria Prima", "value_t": 1500000}], "approach": "Only coated duplex board is worth testing - recycled liner and medium risk strength loss.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Suparma%', '%Suparma%', '%Suparma%',
   $pj${"owner": "PT Suparma Tbk", "products": "Industrial and consumer papers, tissue", "capacity_split": [{"label": "2025 paper output (utilization 76.1 pct)", "value_t": 232783}, {"label": "Implied capacity", "value_t": 306000}], "approach": "Mid-size line-level trial, tissue and consumer grades.", "recent": [{"date": "2025", "text": "Annual report: about 113 pulp and paper mills in Indonesia, total capacity about 21.3 Mt/yr"}], "sources": [{"label": "PT Suparma 2025 annual report"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Adiprima%', '%Adiprima%', '%Adiprima%',
   $pj${"owner": "PT Adiprima Suraprinta", "products": "Newsprint, recycled printing paper, white base paper - 100 pct recycled fibre", "machines": 3, "capacity_split": [{"label": "Three machines 150 + 220 + 110 t/day, about 168,000 t/yr at 350 days (calculated)", "value_t": 168000}], "approach": "Recycled printing and white base paper only - fibre quality, ash and retention vary.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Lontar%', '%Lontar Papyrus%', '%Lontar%',
   $pj${"owner": "PT Lontar Papyrus Pulp and Paper (APP / Sinar Mas group - not Mondi)", "products": "Pulp and tissue", "approach": "Tissue track only, after the APP printing-paper mills.", "checked_at": "2026-10-14"}$pj$::jsonb)
  ) as v(name_like, alt_like, owner_like, plant)
) m
where mp.party_id = m.id;

-- ---------- 3) VERIFY ----------
with v(name_like, alt_like, owner_like) as (values
  ('%Perawang%', '%Indah Kiat Pulp%', '%Indah Kiat%'),
  ('%Kerinci%', '%APRIL%', '%APRIL%'),
  ('%Pindo Deli%', '%Karawang%', '%Pindo%'),
  ('%Tjiwi%', '%Mojokerto%', '%Tjiwi%'),
  ('%Pura%Barutama%', '%Pura Group%', '%Pura%'),
  ('%Indah Kiat%Serang%', '%Serang%', '%Indah Kiat%'),
  ('%Indah Kiat%Tangerang%', '%Tangerang%', '%Indah Kiat%'),
  ('%Fajar%', '%Fajar Surya%', '%Fajar%'),
  ('%Suparma%', '%Suparma%', '%Suparma%'),
  ('%Adiprima%', '%Adiprima%', '%Adiprima%'),
  ('%Lontar%', '%Lontar Papyrus%', '%Lontar%')
)
select 'mill' as kind, coalesce(m.party_name, 'MISSING ' || v.name_like) as name,
       coalesce(mp.extra_data #>> '{plant,owner}', '-') as status,
       coalesce(mp.extra_data #>> '{plant,priority}', '-') as detail
from v
left join lateral (
  select y.id, y.party_name from app.parties y
  where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'ID'
     and (y.party_name ilike v.name_like or y.party_name ilike v.alt_like or y.city ilike btrim(v.name_like, '%'))
  order by (y.party_name ilike v.name_like) desc, (y.party_name ilike v.owner_like) desc, y.created_at
  limit 1
) m on true
left join app.paper_mill_profile mp on mp.party_id = m.id
union all
select 'filler', p.party_name,
       case when p.source = 'indonesia_update_20261014' then 'added now' else 'already there' end, '-'
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null
  and (p.party_name ilike 'Omya%Indonesia%' or p.party_name ilike '%Dwi Selo%'
       or p.party_name ilike '%Aneka Sumber%' or p.party_name ilike '%Supersonic Chemical%')
order by 1, 4, 2;
