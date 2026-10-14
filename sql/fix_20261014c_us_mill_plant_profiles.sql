-- ============================================================
-- fix_20261014c_us_mill_plant_profiles.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Plant detail for the 6 US target mills (customer-development report
-- 2026-10-14): Sylvamo Eastover + Ticonderoga, Sappi Cloquet, Domtar
-- Hawesville + Johnsonburg, plus Domtar Nekoosa as the Omya reference case.
-- Written to app.paper_mill_profile.extra_data.plant, read by the new
-- Mill profile card on the party Overview tab:
--   owner, products, grades, machines, capacity (unit as reported),
--   current filler supplier + basis, FCC scenario assumptions
--   (75/10/10, 85/25/20, 90/50/25 at USD 15/t - the card computes t/yr and
--   royalty), outreach priority, pitch, approach, recent events,
--   first-meeting questions, sources.
-- Supplier status for Domtar mills stays as found (Omya PCC USA at the
-- mill address) - the report called it history only.
-- 1) creates a missing paper_mill_profile row  2) merges extra_data.plant
--    and fills empty main_products / headquarters.
-- Idempotent (re-run overwrites the plant block with the same content).
-- Last statement is a verification select.
-- ============================================================

-- ---------- 1) PROFILE ROW IF MISSING ----------
with v(name_like, owner_like) as (values
  ('%Eastover%', '%Sylvamo%'),
  ('%Ticonderoga%', '%Sylvamo%'),
  ('%Cloquet%', '%Sappi%'),
  ('%Hawesville%', '%Domtar%'),
  ('%Johnsonburg%', '%Domtar%'),
  ('%Nekoosa%', '%Domtar%')
),
m as (
  select distinct on (v.name_like) v.name_like, y.id
  from v
  join app.parties y
    on y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'US'
   and (y.party_name ilike v.name_like or y.city ilike btrim(v.name_like, '%'))
  order by v.name_like, (y.party_name ilike v.owner_like) desc, y.created_at
)
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from m
where not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);

-- ---------- 2) PLANT BLOCK ----------
with v(name_like, owner_like, products, hq, plant) as (values
  ('%Eastover%', '%Sylvamo%', 'Uncoated freesheet, cut-size copy paper', 'Memphis, TN',
   $pj${"owner": "Sylvamo (International Paper until the 2021 spin-off)", "products": "Uncoated freesheet - cut-size copy and printing papers", "grades": ["Uncoated freesheet", "Copy paper"], "capacity": {"value": 700000, "unit": "short_tons", "year": "2021 filing, Eastover plus Ticonderoga still 975,000 in the 2025 annual report", "source": "Sylvamo SEC filings"}, "filler": [{"supplier": "Specialty Minerals (MTI)", "type": "On-site satellite PCC", "status": "Satellite listed in MTI FY2024 10-K", "basis": "Earlier MTI 10-K tables name the mill as host - current contract terms not public"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate capacity, not orders. Grades on FCC = share of output switched to FCC, FCC in sheet = FCC mass share of that paper. FCC in sheet is not the same as pulp replaced."}, "priority": 1, "pitch": "Cut pulp in copy paper while holding strength and opacity, lower furnish cost", "approach": "Lead account. Run the technical case with Sylvamo HQ together with Ticonderoga. FCC supply goes through SMI as producer and licensee - agree NDA scope and background IP with SMI before sharing data.", "recent": [{"date": "2026", "text": "Sylvamo productivity investment at Eastover, reported at about USD 145M (unrelated to FCC, but a live capex conversation)"}], "to_collect": ["Current PCC or GCC supplier, contract term and renewal date", "Actual annual PCC and GCC purchases (t)", "Output and utilization per paper machine", "Filler loading and furnish by grade", "Quality gates FCC must pass versus current PCC", "Who signs off a mill trial (technical and purchasing)"], "sources": [{"label": "MTI 10-K FY2024 Item 2", "url": "https://www.sec.gov/Archives/edgar/data/891014/000089101425000018/form10k.htm"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Ticonderoga%', '%Sylvamo%', 'Premium uncoated freesheet', 'Memphis, TN',
   $pj${"owner": "Sylvamo (International Paper until the 2021 spin-off)", "products": "Premium uncoated freesheet - copy and opaque printing papers", "grades": ["Premium copy", "Opaque offset"], "capacity": {"value": 275000, "unit": "short_tons", "year": "2021 filing", "source": "Sylvamo SEC filings"}, "filler": [{"supplier": "Specialty Minerals (MTI)", "type": "On-site satellite PCC", "status": "Satellite listed in MTI FY2024 10-K", "basis": "One of the first SMI satellites (planned in the 1980s next to the IP mill)"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate capacity, not orders. Grades on FCC = share of output switched to FCC, FCC in sheet = FCC mass share of that paper. FCC in sheet is not the same as pulp replaced."}, "priority": 2, "pitch": "Optimize filler package in premium grades - brightness, opacity and surface must hold", "approach": "Same owner as Eastover - pair both mills in one Sylvamo HQ technical review.", "to_collect": ["Current PCC or GCC supplier, contract term and renewal date", "Actual annual PCC and GCC purchases (t)", "Output and utilization per paper machine", "Filler loading and furnish by grade", "Quality gates FCC must pass versus current PCC", "Who signs off a mill trial (technical and purchasing)"], "sources": [{"label": "MTI 10-K FY2024 Item 2", "url": "https://www.sec.gov/Archives/edgar/data/891014/000089101425000018/form10k.htm"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Cloquet%', '%Sappi%', 'Coated graphic papers, packaging and specialty', 'Johannesburg, South Africa',
   $pj${"owner": "Sappi North America", "products": "Coated graphic papers plus packaging and specialty papers", "grades": ["Coated printing", "Label base", "Packaging and specialty"], "capacity": {"value": 340000, "unit": "metric_t", "year": "2025 annual report", "source": "Sappi operations overview"}, "capacity_split": [{"label": "Graphic papers", "value_t": 270000}, {"label": "Packaging and specialty", "value_t": 70000}], "filler": [{"supplier": "Specialty Minerals (MTI)", "type": "On-site satellite PCC", "status": "Satellite listed in MTI FY2024 10-K", "basis": "Earlier MTI 10-K tables name Sappi (Potlatch before) as host"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate capacity, not orders. Grades on FCC = share of output switched to FCC, FCC in sheet = FCC mass share of that paper. FCC in sheet is not the same as pulp replaced."}, "priority": 3, "pitch": "FCC in coated printing and label base sheets - assess base-sheet filler separately to coating pigment", "approach": "Second account after Sylvamo. Coating carbonate and internal filler are different questions - scope the trial to the base sheet.", "to_collect": ["Current PCC or GCC supplier, contract term and renewal date", "Actual annual PCC and GCC purchases (t)", "Output and utilization per paper machine", "Filler loading and furnish by grade", "Quality gates FCC must pass versus current PCC", "Who signs off a mill trial (technical and purchasing)", "Base-sheet filler versus coating pigment volumes"], "sources": [{"label": "MTI 10-K FY2024 Item 2", "url": "https://www.sec.gov/Archives/edgar/data/891014/000089101425000018/form10k.htm"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Hawesville%', '%Domtar%', 'Fine and specialty uncoated papers, hardwood market pulp', 'Fort Mill, SC',
   $pj${"owner": "Domtar (Paper Excellence group)", "products": "Fine and specialty uncoated papers plus hardwood market pulp", "grades": ["Specialty uncoated", "Fine paper"], "machines": 2, "capacity": {"value": 596000, "unit": "short_tons", "year": "Domtar 10-K FY2020-21 and mill page", "source": "Domtar"}, "filler": [{"supplier": "Omya PCC USA", "type": "On-site PCC", "status": "Listed at the mill street address, Omya hiring there 2023", "basis": "Business listings - current contract not public"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate capacity, not orders. Grades on FCC = share of output switched to FCC, FCC in sheet = FCC mass share of that paper. FCC in sheet is not the same as pulp replaced."}, "priority": 4, "pitch": "Pulp savings in specialty grades while keeping optical properties", "approach": "Domtar account, paired with Johnsonburg. FCC supply goes through Omya as licensee - Omya HQ global royalty talks come first.", "to_collect": ["Current PCC or GCC supplier, contract term and renewal date", "Actual annual PCC and GCC purchases (t)", "Output and utilization per paper machine", "Filler loading and furnish by grade", "Quality gates FCC must pass versus current PCC", "Who signs off a mill trial (technical and purchasing)"], "sources": [{"label": "Domtar Hawesville mill page", "url": "https://www.domtar.com/fr/our-location/moulin-de-hawesville"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Johnsonburg%', '%Domtar%', 'Uncoated freesheet', 'Fort Mill, SC',
   $pj${"owner": "Domtar (Paper Excellence group)", "products": "Uncoated freesheet", "grades": ["Uncoated freesheet"], "machines": 2, "capacity": {"value": 344000, "unit": "short_tons", "year": "Domtar mill page", "source": "Domtar"}, "filler": [{"supplier": "Omya PCC USA", "type": "On-site PCC", "status": "Omya PCC USA plant at 499 Glen Ave since 2007", "basis": "Business listings - current contract not public"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate capacity, not orders. Grades on FCC = share of output switched to FCC, FCC in sheet = FCC mass share of that paper. FCC in sheet is not the same as pulp replaced."}, "priority": 5, "pitch": "Prove FCC pulp replacement in uncoated freesheet - closest grade fit to the Korean program", "approach": "Domtar account, paired with Hawesville, via Omya.", "to_collect": ["Current PCC or GCC supplier, contract term and renewal date", "Actual annual PCC and GCC purchases (t)", "Output and utilization per paper machine", "Filler loading and furnish by grade", "Quality gates FCC must pass versus current PCC", "Who signs off a mill trial (technical and purchasing)"], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Nekoosa%', '%Domtar%', 'Specialty and uncoated papers', 'Fort Mill, SC',
   $pj${"owner": "Domtar (Paper Excellence group)", "filler": [{"supplier": "Omya (USA)", "type": "On-site PCC, Omya designed, owns and operates", "status": "Started 2024-09, about 27,500 dry t/yr", "basis": "Domtar announcement"}, {"supplier": "Omya (USA)", "type": "Near-site supply to Domtar Rothschild", "status": "Active", "basis": "Domtar announcement"}], "pitch": "Reference case - a mill and Omya building new on-site PCC in 2024 shows the three-party model (MBG technology, Omya production, mill use) already works in the US", "approach": "Use as the US proof point in Omya and Domtar talks. Mill capacity not filled - add once confirmed.", "recent": [{"date": "2024-09", "text": "Omya on-site PCC plant at Nekoosa started, also supplying Rothschild", "url": "https://www.domtar.com/nekoosa-mill-pcc-plant/"}], "sources": [{"label": "Domtar - Nekoosa mill PCC plant", "url": "https://www.domtar.com/nekoosa-mill-pcc-plant/"}], "checked_at": "2026-10-14"}$pj$::jsonb)
),
m as (
  select distinct on (v.name_like) v.name_like, v.products, v.hq, v.plant, y.id
  from v
  join app.parties y
    on y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'US'
   and (y.party_name ilike v.name_like or y.city ilike btrim(v.name_like, '%'))
  order by v.name_like, (y.party_name ilike v.owner_like) desc, y.created_at
)
update app.paper_mill_profile mp
set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', m.plant),
    main_products = coalesce(nullif(btrim(mp.main_products), ''), m.products),
    headquarters  = coalesce(nullif(btrim(mp.headquarters), ''), m.hq),
    updated_at = now()
from m
where mp.party_id = m.id;

-- ---------- 3) VERIFY ----------
select p.party_name,
       mp.extra_data #>> '{plant,priority}' as priority,
       mp.extra_data #>> '{plant,capacity,value}' as capacity,
       mp.extra_data #>> '{plant,capacity,unit}' as unit,
       mp.extra_data #>> '{plant,filler,0,supplier}' as filler_supplier,
       mp.extra_data #>> '{plant,checked_at}' as checked
from app.paper_mill_profile mp
join app.parties p on p.id = mp.party_id
where p.deleted_at is null and mp.extra_data #>> '{plant,checked_at}' = '2026-10-14'
order by (mp.extra_data #>> '{plant,priority}') nulls last, p.party_name;
