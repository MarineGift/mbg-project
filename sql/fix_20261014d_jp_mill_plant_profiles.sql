-- ============================================================
-- fix_20261014d_jp_mill_plant_profiles.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Japan mill plant profiles (report "Japan paper industry for FCC", 2026-10).
-- Writes app.paper_mill_profile.extra_data.plant for 16 JP mills, shown on
-- the Mill profile card. Outreach priority 1-7:
--   1 Hokuetsu Niigata  2 Nippon Paper Ishinomaki  3 Oji Kasugai
--   4 Oji Yonago  5 Daio Mishima  6 Mitsubishi Hachinohe  7 Nippon Paper Shiraoi
-- plus context-only rows (no priority): Oji Tomioka, Tomakomai, Nippon Paper
-- Iwakuni, Otake, Iwanuma, Yatsushiro, Hokuetsu Kishu, Daio Kani,
-- Chuetsu Takaoka.
--
-- Checked against company releases: Shiraoi PM8 (64 kt) shut 2025-09,
-- Yatsushiro N2 (232 kt newsprint) shut 2025-06, Oji Tomakomai PM9 (83 kt)
-- shut 2025-03, Mitsubishi Takasago machine shut 2025-12. Report-only items
-- (Tomakomai N-4 2026-03, Otake PM1 2026-06) are marked "confirm".
-- FCC scenarios only for Ishinomaki (whole mill is graphic paper). Mishima
-- capacity is shown but no scenario - whole-mill tonnage overstates demand.
--
-- Mills are matched on JP rows by name or city - NOTHING is created.
-- The verify select lists every target as matched or MISSING.
-- Idempotent. Last statement is the verification select.
-- ============================================================

-- ---------- 1) PROFILE ROW IF MISSING ----------
with v(name_like, owner_like) as (values
  ('%Niigata%', '%Hokuetsu%'),
  ('%Ishinomaki%', '%Nippon Paper%'),
  ('%Kasugai%', '%Oji%'),
  ('%Yonago%', '%Oji%'),
  ('%Mishima%', '%Daio%'),
  ('%Hachinohe%', '%Mitsubishi%'),
  ('%Shiraoi%', '%Nippon Paper%'),
  ('%Tomioka%', '%Oji%'),
  ('%Tomakomai%', '%Oji%'),
  ('%Iwakuni%', '%Nippon Paper%'),
  ('%Otake%', '%Nippon Paper%'),
  ('%Iwanuma%', '%Nippon Paper%'),
  ('%Yatsushiro%', '%Nippon Paper%'),
  ('%Kishu%', '%Hokuetsu%'),
  ('%Kani%', '%Daio%'),
  ('%Takaoka%', '%Chuetsu%')
),
m as (
  select distinct on (v.name_like) v.name_like, y.id
  from v
  join app.parties y
    on y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'JP'
   and (y.party_name ilike v.name_like or y.city ilike btrim(v.name_like, '%'))
  order by v.name_like, (y.party_name ilike v.owner_like) desc, y.created_at
)
insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
select m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
from m
where not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);

-- ---------- 2) PLANT BLOCK ----------
with v(name_like, owner_like, plant) as (values
  ('%Niigata%', '%Hokuetsu%',
   $pj${"owner": "Hokuetsu Corporation", "priority": 1, "products": "Coated and uncoated printing papers, white board", "grades": ["Coated printing", "Uncoated printing", "White board"], "machines": 8, "pitch": "Lower cost per tonne on large fine-paper machines - pulp saving with strength and opacity held", "approach": "Top Japan target. Find the current PCC / GCC supplier first and approach mill and supplier together (the Korean model).", "recent": [{"date": "FY2024", "text": "Paper exports 290,000 t, up 20% (2025 integrated report)"}, {"date": "note", "text": "Mill page lists 8 machines, a product page also shows PM9 - confirm the machine list"}], "to_collect": ["Current PCC / GCC supplier per machine, and whether PCC is made on site", "Annual PCC and GCC use (t) and price basis", "Machines expected to keep running for the next 5-10 years", "Filler loading and furnish by grade", "Quality gates FCC must pass versus current filler", "Who approves a mill trial (technical and purchasing)"], "sources": [{"label": "Hokuetsu mill page and 2025 integrated report"}, {"label": "Japan Paper Association - 2025 output 21.1M t, down 2.3%"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Ishinomaki%', '%Nippon Paper%',
   $pj${"owner": "Nippon Paper Industries", "priority": 2, "products": "Printing and communication papers - publishing, flyer and copy papers", "grades": ["Publishing paper", "Coated printing", "Copy paper"], "capacity": {"value": 850000, "unit": "metric_t", "year": "Post-2011 rebuild figure (about 860,000 t in 2014 press)", "source": "Nippon Paper releases - confirm current"}, "filler": [{"supplier": "In-house", "type": "On-site filler production", "status": "Described in older Nippon Paper material", "basis": "Current filler process to be confirmed"}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Conservative", "utilization": 0.75, "fcc_share": 0.1, "fcc_loading": 0.1}, {"label": "Base", "utilization": 0.85, "fcc_share": 0.25, "fcc_loading": 0.2}, {"label": "Expanded", "utilization": 0.9, "fcc_share": 0.5, "fcc_loading": 0.25}], "note": "Planning scenarios on nameplate capacity, not orders. FCC in sheet is not the same as pulp replaced."}, "pitch": "Add FCC to the existing in-house filler process - no new plant needed", "approach": "Ask how filler is made today (own PCC, purchased slurry or both). If in-house, the licence is with Nippon Paper directly.", "recent": [{"date": "2014", "text": "About 10% of Japan printing and communication paper made at Ishinomaki, PM8 makes book papers"}], "to_collect": ["Current PCC / GCC supplier per machine, and whether PCC is made on site", "Annual PCC and GCC use (t) and price basis", "Machines expected to keep running for the next 5-10 years", "Filler loading and furnish by grade", "Quality gates FCC must pass versus current filler", "Who approves a mill trial (technical and purchasing)"], "sources": [{"label": "Nippon Paper Group releases, Toyo Keizai 2014"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Kasugai%', '%Oji%',
   $pj${"owner": "Oji Holdings (Oji Paper)", "priority": 3, "products": "Printing and communication papers", "grades": ["Copy paper", "Printing papers"], "pitch": "Start on the high-filler copy and printing grades", "approach": "Pick the machine with the highest filler loading for the first trial.", "to_collect": ["Current PCC / GCC supplier per machine, and whether PCC is made on site", "Annual PCC and GCC use (t) and price basis", "Machines expected to keep running for the next 5-10 years", "Filler loading and furnish by grade", "Quality gates FCC must pass versus current filler", "Who approves a mill trial (technical and purchasing)"], "sources": [{"label": "Oji Holdings integrated report"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Yonago%', '%Oji%',
   $pj${"owner": "Oji Holdings (Oji Paper)", "priority": 4, "products": "High-grade coated papers", "grades": ["Coated printing"], "pitch": "Pulp saving in coated base paper while holding strength and opacity", "approach": "Scope the trial to the base sheet - coating pigment is a separate question.", "to_collect": ["Current PCC / GCC supplier per machine, and whether PCC is made on site", "Annual PCC and GCC use (t) and price basis", "Machines expected to keep running for the next 5-10 years", "Filler loading and furnish by grade", "Quality gates FCC must pass versus current filler", "Who approves a mill trial (technical and purchasing)"], "sources": [{"label": "Oji Holdings integrated report"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Mishima%', '%Daio%',
   $pj${"owner": "Daio Paper", "priority": 5, "products": "Printing papers, board, tissue and household paper - integrated mill", "grades": ["Printing papers", "Board", "Tissue"], "machines": 16, "capacity": {"value": 2100000, "unit": "metric_t", "year": "Company mill page - 6,990 t/day paper and board, pulp 6,880 t/day", "source": "Daio Paper"}, "pitch": "Copy, printing and some specialty grades only - board and tissue use different furnish", "approach": "Whole-mill capacity overstates FCC demand. Ask for printing-grade output per machine (N10 alone about 24,000 t/month) before any volume estimate.", "to_collect": ["Current PCC / GCC supplier per machine, and whether PCC is made on site", "Annual PCC and GCC use (t) and price basis", "Machines expected to keep running for the next 5-10 years", "Filler loading and furnish by grade", "Quality gates FCC must pass versus current filler", "Who approves a mill trial (technical and purchasing)"], "sources": [{"label": "Daio Paper Mishima mill page"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Hachinohe%', '%Mitsubishi%',
   $pj${"owner": "Mitsubishi Paper Mills", "priority": 6, "products": "Fine and coated printing papers", "grades": ["Coated printing", "Fine paper"], "pitch": "Strength, opacity and smoothness together with pulp saving", "approach": "Base-paper trials per grade - thermal and specialty sheets need their own validation.", "recent": [{"date": "2025-12", "text": "Mitsubishi Paper shut a Takasago machine for information base and specialty papers, and a Takasago coater 2025-09 - output consolidated on newer lines"}], "to_collect": ["Current PCC / GCC supplier per machine, and whether PCC is made on site", "Annual PCC and GCC use (t) and price basis", "Machines expected to keep running for the next 5-10 years", "Filler loading and furnish by grade", "Quality gates FCC must pass versus current filler", "Who approves a mill trial (technical and purchasing)"], "sources": [{"label": "Mitsubishi Paper integrated report, Newswitch 2024"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Shiraoi%', '%Nippon Paper%',
   $pj${"owner": "Nippon Paper Industries", "priority": 7, "products": "Remaining lines moved to non-graphic grades after PM8 closed", "filler": [{"supplier": "Specialty Minerals FMT", "type": "On-site PCC inside the mill", "status": "Per FMT factory page - current running status to confirm", "basis": "fmt.co.jp quality and factory page"}], "pitch": "Convert the existing on-site PCC unit to FCC for the remaining machines", "approach": "Check first whether the on-site PCC unit still runs after PM8 stopped and how much carbonate the remaining machines use. Supply goes through SMI as licensee.", "recent": [{"date": "2025-09", "text": "PM8 (fine paper, about 64,000 t/yr) shut, remaining facilities shifted to non-graphic products"}], "to_collect": ["Current PCC / GCC supplier per machine, and whether PCC is made on site", "Annual PCC and GCC use (t) and price basis", "Machines expected to keep running for the next 5-10 years", "Filler loading and furnish by grade", "Quality gates FCC must pass versus current filler", "Who approves a mill trial (technical and purchasing)"], "sources": [{"label": "Nippon Paper release 2024-08 - production system reorganization"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Tomioka%', '%Oji%',
   $pj${"owner": "Oji Holdings (Oji Paper)", "products": "Coated printing papers", "grades": ["Coated printing"], "approach": "Second-wave Oji mill after Kasugai and Yonago.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Tomakomai%', '%Oji%',
   $pj${"owner": "Oji Holdings (Oji Paper)", "products": "Newsprint and coated papers", "approach": "Low FCC priority - newsprint and shrinking graphic capacity.", "recent": [{"date": "2025-03", "text": "PM9 (coated and lightweight coated, about 83,000 t/yr) shut"}, {"date": "2026-03", "text": "Newsprint machine N-4 (about 159,000 t/yr) planned to stop at end of March 2026 (per report, confirm)"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Iwakuni%', '%Nippon Paper%',
   $pj${"owner": "Nippon Paper Industries", "products": "High-grade printing and coated papers", "grades": ["Coated printing"], "approach": "Second-wave Nippon Paper mill after Ishinomaki.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Otake%', '%Nippon Paper%',
   $pj${"owner": "Nippon Paper Industries", "products": "Specialty papers and packaging base paper", "recent": [{"date": "2026-06", "text": "PM1 (about 20,000 t/yr) planned to stop (per report, confirm)"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Iwanuma%', '%Nippon Paper%',
   $pj${"owner": "Nippon Paper Industries", "approach": "Check grade mix before any FCC work.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Yatsushiro%', '%Nippon Paper%',
   $pj${"owner": "Nippon Paper Industries", "products": "Newsprint and fine paper, household paper planned", "approach": "Not a near-term FCC target - graphic capacity cut, household paper start planned 2027.", "recent": [{"date": "2025-06", "text": "Newsprint machine N2 (about 232,000 t/yr) and the coal boiler shut"}, {"date": "2027", "text": "Household paper (tissue) production planned, mainly for export"}], "sources": [{"label": "Nippon Paper release 2024-08 - production system reorganization"}], "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Kishu%', '%Hokuetsu%',
   $pj${"owner": "Hokuetsu Corporation", "products": "Copy, colour and information papers", "grades": ["Copy paper", "Colour paper"], "approach": "Second Hokuetsu candidate after Niigata.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Kani%', '%Daio%',
   $pj${"owner": "Daio Paper", "products": "Printing papers and household paper", "approach": "Check printing-grade share before any FCC work.", "checked_at": "2026-10-14"}$pj$::jsonb),
  ('%Takaoka%', '%Chuetsu%',
   $pj${"owner": "Chuetsu Pulp & Paper", "products": "Printing, specialty papers and pulp", "approach": "Mid priority - confirm grade mix and filler supplier.", "checked_at": "2026-10-14"}$pj$::jsonb)
),
m as (
  select distinct on (v.name_like) v.name_like, v.plant, y.id
  from v
  join app.parties y
    on y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'JP'
   and (y.party_name ilike v.name_like or y.city ilike btrim(v.name_like, '%'))
  order by v.name_like, (y.party_name ilike v.owner_like) desc, y.created_at
)
update app.paper_mill_profile mp
set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', m.plant),
    main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
    updated_at = now()
from m
where mp.party_id = m.id;

-- ---------- 3) VERIFY (every target, matched or MISSING) ----------
with v(town, name_like, owner_like) as (values
  ('Niigata', '%Niigata%', '%Hokuetsu%'),
  ('Ishinomaki', '%Ishinomaki%', '%Nippon Paper%'),
  ('Kasugai', '%Kasugai%', '%Oji%'),
  ('Yonago', '%Yonago%', '%Oji%'),
  ('Mishima', '%Mishima%', '%Daio%'),
  ('Hachinohe', '%Hachinohe%', '%Mitsubishi%'),
  ('Shiraoi', '%Shiraoi%', '%Nippon Paper%'),
  ('Tomioka', '%Tomioka%', '%Oji%'),
  ('Tomakomai', '%Tomakomai%', '%Oji%'),
  ('Iwakuni', '%Iwakuni%', '%Nippon Paper%'),
  ('Otake', '%Otake%', '%Nippon Paper%'),
  ('Iwanuma', '%Iwanuma%', '%Nippon Paper%'),
  ('Yatsushiro', '%Yatsushiro%', '%Nippon Paper%'),
  ('Kishu', '%Kishu%', '%Hokuetsu%'),
  ('Kani', '%Kani%', '%Daio%'),
  ('Takaoka', '%Takaoka%', '%Chuetsu%')
),
m as (
  select distinct on (v.name_like) v.name_like, y.id, y.party_name
  from v
  join app.parties y
    on y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'JP'
   and (y.party_name ilike v.name_like or y.city ilike btrim(v.name_like, '%'))
  order by v.name_like, (y.party_name ilike v.owner_like) desc, y.created_at
)
select v.town,
       coalesce(m.party_name, 'MISSING') as mill,
       mp.extra_data #>> '{plant,priority}' as priority,
       mp.extra_data #>> '{plant,owner}' as owner,
       case when mp.extra_data #>> '{plant,checked_at}' = '2026-10-14' then 'written' else '-' end as plant_block
from v
left join m on m.name_like = v.name_like
left join app.paper_mill_profile mp on mp.party_id = m.id
order by (mp.extra_data #>> '{plant,priority}') nulls last, v.town;
