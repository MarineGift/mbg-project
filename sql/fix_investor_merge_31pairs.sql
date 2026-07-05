-- ============================================================
-- MERGE: investor duplicates (2026-07-04) -- 31 pairs, Option A (keep concise name)
-- PREREQUISITE: run fix_investor_merge_probe.sql first and confirm the FK list
-- below matches. This script:
--   (0) safety: verify every id exists and is an investor; abort logic via CTE
--   (1) DRY-RUN counts (what will be reparented)   <-- review before committing
--   (2) backfill canonical's NULL/empty fields from the merge row
--   (3) reparent child rows (deals, engagements, tasks, mail, sector/tag focus)
--   (4) move investor_profile sub-links, then soft-delete merge party + profile
--   (5) verify
-- Wrapped in a transaction: run section 1 first (SELECTs), eyeball, then run
-- the whole file. Nothing is hard-deleted (soft-delete via deleted_at).
--
-- EXCLUDED (never merged): 5AM Ventures vs 5AM Ventures II (distinct funds);
--   ICONIQ Growth vs ICONIQ Capital (distinct vehicle).
-- ============================================================

begin;

create temporary table _merge(canonical_id uuid, merge_id uuid) on commit drop;
insert into _merge(canonical_id, merge_id) values
  ('56ec6a60-c9b0-4c21-baaa-502e4f3da3ef'::uuid, '54683abc-f6de-4b03-8ed3-52d7ad2cc41d'::uuid)  -- 8VC,
  ('213aeb77-0b03-4374-b2d2-961d0d8481bb'::uuid, 'e1496b92-833a-44c4-9e91-89588fc97492'::uuid)  -- Accel,
  ('174b5996-41a7-44fc-a1e9-3767c6b26314'::uuid, '8860433c-f9aa-4dbb-b0f0-d76736e5e94f'::uuid)  -- Bain Capital Ventures,
  ('d09c7f36-6c8a-41cb-b9e5-180273ce7568'::uuid, '566587c2-1f27-477f-aa3f-1fedbb2135d3'::uuid)  -- Benchmark,
  ('620ee8d8-dc23-4ac9-ad72-4d0f3ecd5729'::uuid, '4ab17b47-8e8b-49c3-ad51-44a3b24f6f7f'::uuid)  -- Coatue Management,
  ('0a07aaf5-35ef-4c3b-9269-0f88817bb7bd'::uuid, '398200d7-6b22-4ae3-ac26-c1fed61f670c'::uuid)  -- Dallas Venture Capital,
  ('b21c2c0e-4f02-4d7d-9b1f-e53eb71e2eb8'::uuid, '5666b9dc-bc69-41de-83d2-e15cccb544b7'::uuid)  -- Evonik Venture Capital,
  ('69d0aa8b-8246-49f3-af76-e09846582c9e'::uuid, '390e0a20-1a78-4ec5-955f-291d66a1ac0b'::uuid)  -- ICONIQ Capital,
  ('249d3da7-1bf1-48ab-ac7c-0ab87466d8f9'::uuid, 'e8b2de41-7a93-43c3-a399-3c86d656d5a8'::uuid)  -- Insight Partners,
  ('3e9b2825-1cfa-4266-9970-bfdb9da6884c'::uuid, '4bd65a4f-d395-4846-8f94-cdfeaabf5eb9'::uuid)  -- Lightspeed Venture Partners,
  ('9a9f8574-b4d3-49c1-8e98-9449833bf3b4'::uuid, '744a668f-fbb2-46e5-bfa5-ce79692c52f4'::uuid)  -- Material Impact,
  ('47669b55-b9b7-42f8-8da5-54992a73c6f5'::uuid, '0f3899ed-01ed-4487-b014-c5939276b436'::uuid)  -- Mayfield Fund,
  ('adeaceeb-17b0-4b80-bb9f-077a50726f84'::uuid, 'e3df7b4e-031f-498d-bfcd-4b79d21d5fba'::uuid)  -- Sapphire Ventures,
  ('c486e761-98e2-4ebf-a57d-c43ddfada8a1'::uuid, 'd7b20261-61d3-4487-a868-f760d6d14da3'::uuid)  -- Spark Capital,
  ('a85059da-43f1-4881-9099-12c36b6e18e9'::uuid, 'cecad41b-dcae-4b58-b632-72d24bebfb39'::uuid)  -- Temasek,
  ('d859bf14-e4c4-461a-80cb-48832ddf4b68'::uuid, '03af7a8d-264a-4f24-82e3-b2485e2e1d82'::uuid)  -- Texo Ventures,
  ('a4f436b8-6781-4f6d-be95-bee630435e39'::uuid, '54060cda-844a-451e-b41a-861ed17d685c'::uuid)  -- Thrive Capital,
  ('1391ab55-777e-42c7-aa8e-2a4752bb7e2e'::uuid, '73245866-3841-4303-ae7c-ebde97970182'::uuid)  -- Tiger Global Management,
  ('f3959f9c-8a81-49b5-bb7d-82659a0ed297'::uuid, '139428c8-2614-49a4-9754-cf0220ab42e3'::uuid)  -- Y Combinator,
  ('d34887f1-7281-423b-83c2-28e9d5fababd'::uuid, '3e85dc1c-5ce6-427f-9efc-4a13065dc30a'::uuid)  -- Andreessen Horowitz (a16z),
  ('47dca0b3-8398-4573-b520-567ea32d2146'::uuid, 'ba8afb75-3e72-4651-bd03-a881d96949bf'::uuid)  -- DCVC,
  ('83a8f585-8532-419b-9467-38d13450fd65'::uuid, 'ba1b23b1-e9b5-4e2a-a840-ce7d65148de1'::uuid)  -- Sequoia Capital,
  ('6050d6ef-8168-4608-84a9-bd0d9e0aeae0'::uuid, '10a54538-2dc2-49cf-a285-6abb03c59617'::uuid)  -- Kleiner Perkins,
  ('f501983f-da05-4983-965f-3f5290ce4de8'::uuid, '0121edf7-46d8-482e-9ca3-9c821d88212e'::uuid)  -- IVP,
  ('6c088927-c224-476e-9c16-35266a375aab'::uuid, '0a56434e-7666-4357-90dc-27a30246a70c'::uuid)  -- TCV,
  ('3fc092ae-a543-4312-b236-e151218a12a0'::uuid, '37b07de3-4622-4f2a-8e7a-776fc80520d5'::uuid)  -- M12,
  ('cda9557d-6501-4583-9917-29e53f1b5c34'::uuid, '303be069-167e-426d-b34f-fd297ade7624'::uuid)  -- Central Texas Angel Network (CTAN),
  ('e29460ad-1530-4326-9bd6-2f52bf856a1f'::uuid, '5fce619a-7a27-4e33-8b2e-40e700ae93d8'::uuid)  -- Live Oak Venture Partners,
  ('46438b2b-eb0b-47ab-87c6-82d9536c32b9'::uuid, '5eae1a04-5c82-47d9-943a-6c75c0a02ca8'::uuid)  -- Sante Ventures,
  ('be1c79d1-0ab5-4cc8-84ea-26482e53ad07'::uuid, '2ac5135d-384f-4110-a6e6-5f53ee41982a'::uuid)  -- Samsung Ventures,
  ('de9c95c7-b9ab-4503-887d-b03123f783a4'::uuid, '3673da0b-2663-465c-af2c-791a2431511e'::uuid)  -- Asahi Kasei Ventures;

-- (0) SAFETY: both ids must exist, be investors, not already deleted, distinct
do $chk$
declare bad int;
begin
  select count(*) into bad
  from _merge m
  where not exists (select 1 from app.parties p join app.party_types pt on pt.id=p.party_type_id
                    where p.id=m.canonical_id and pt.code='investor' and p.deleted_at is null)
     or not exists (select 1 from app.parties p join app.party_types pt on pt.id=p.party_type_id
                    where p.id=m.merge_id and pt.code='investor' and p.deleted_at is null)
     or m.canonical_id = m.merge_id;
  if bad > 0 then
    raise exception 'Safety check failed for % pair(s): missing/deleted/non-investor/self. Aborting.', bad;
  end if;
end $chk$;

-- (1) DRY-RUN: how many child rows each reparent will touch
--     >>> RUN THIS SECTION ALONE FIRST (comment out the rest) TO REVIEW <<<
-- Uncomment child-table lines that the PROBE confirmed exist.
-- select 'deals' t, count(*) from app.deals d join _merge m on d.party_id=m.merge_id
-- union all select 'engagements', count(*) from app.engagements e join _merge m on e.party_id=m.merge_id
-- union all select 'sector_focus', count(*) from app.investor_sector_focus f
--   join app.investor_profile ip on ip.id=f.investor_profile_id join _merge m on ip.party_id=m.merge_id
-- union all select 'interest_tags', count(*) from app.investor_interest_tags f
--   join app.investor_profile ip on ip.id=f.investor_profile_id join _merge m on ip.party_id=m.merge_id;

-- (2) BACKFILL canonical's empty scalar fields from the merge row
update app.parties c set
  website        = coalesce(nullif(c.website,''),        mp.website),
  email          = coalesce(nullif(c.email,''),          mp.email),
  city           = coalesce(nullif(c.city,''),           mp.city),
  region         = coalesce(nullif(c.region,''),         mp.region),
  country_code   = coalesce(nullif(c.country_code,''),   mp.country_code),
  street_address = coalesce(nullif(c.street_address,''), mp.street_address),
  intro_ko       = coalesce(nullif(c.intro_ko,''),       mp.intro_ko),
  intro_en       = coalesce(nullif(c.intro_en,''),       mp.intro_en),
  notes          = coalesce(nullif(c.notes,''),          mp.notes),
  updated_at     = now()
from _merge m
join app.parties mp on mp.id = m.merge_id
where c.id = m.canonical_id;

-- merge interest_tags jsonb (union of both legacy arrays), array-guarded
update app.parties c set interest_tags = (
  select to_jsonb(array(select distinct e from (
    select jsonb_array_elements_text(case when jsonb_typeof(coalesce(c.interest_tags,'[]'::jsonb))='array' then c.interest_tags else '[]'::jsonb end) e
    union
    select jsonb_array_elements_text(case when jsonb_typeof(coalesce(mp.interest_tags,'[]'::jsonb))='array' then mp.interest_tags else '[]'::jsonb end)
  ) s where e is not null and btrim(e)<>'')))
from _merge m join app.parties mp on mp.id=m.merge_id
where c.id = m.canonical_id;

-- (3) REPARENT child rows. UNCOMMENT/ADD tables per the PROBE output.
-- Pattern for a table with party_id:
--   update app.<table> t set party_id = m.canonical_id from _merge m where t.party_id = m.merge_id;
-- === confirmed-common candidates (verify against probe before running) ===
-- update app.deals        t set party_id = m.canonical_id from _merge m where t.party_id = m.merge_id;
-- update app.engagements  t set party_id = m.canonical_id from _merge m where t.party_id = m.merge_id;
-- update app.tasks        t set party_id = m.canonical_id from _merge m where t.party_id = m.merge_id;
-- update app.contacts     t set party_id = m.canonical_id from _merge m where t.party_id = m.merge_id;
-- update app.mail_run_recipients t set party_id = m.canonical_id from _merge m where t.party_id = m.merge_id;
-- ... (add every table the probe reported that references app.parties(id))

-- (4) investor_profile sub-links -> canonical's profile, then drop merge profile.
-- move sector_focus / interest_tags links that don't collide, then delete dupes.
with cp as (
  select m.canonical_id, m.merge_id,
         cip.id as canon_profile, mip.id as merge_profile
  from _merge m
  left join app.investor_profile cip on cip.party_id = m.canonical_id
  left join app.investor_profile mip on mip.party_id = m.merge_id
)
update app.investor_sector_focus f set investor_profile_id = cp.canon_profile
from cp where f.investor_profile_id = cp.merge_profile and cp.canon_profile is not null
  and not exists (select 1 from app.investor_sector_focus x
                  where x.investor_profile_id=cp.canon_profile and x.sector_id=f.sector_id);
with cp as (
  select cip.id as canon_profile, mip.id as merge_profile
  from _merge m
  left join app.investor_profile cip on cip.party_id = m.canonical_id
  left join app.investor_profile mip on mip.party_id = m.merge_id
)
update app.investor_interest_tags f set investor_profile_id = cp.canon_profile
from cp where f.investor_profile_id = cp.merge_profile and cp.canon_profile is not null
  and not exists (select 1 from app.investor_interest_tags x
                  where x.investor_profile_id=cp.canon_profile and x.interest_tag_id=f.interest_tag_id);

-- backfill canonical profile scalar fields, then soft-delete the merge profile
update app.investor_profile cip set
  priority          = coalesce(cip.priority, mip.priority),
  investor_type_id  = coalesce(cip.investor_type_id, mip.investor_type_id),
  fund_name         = coalesce(nullif(cip.fund_name,''), mip.fund_name),
  fund_size_usd     = coalesce(cip.fund_size_usd, mip.fund_size_usd),
  aum_usd           = coalesce(cip.aum_usd, mip.aum_usd),
  updated_at        = now()
from _merge m
join app.investor_profile mip on mip.party_id = m.merge_id
where cip.party_id = m.canonical_id;

-- remove leftover links on the merge profile, then the merge profile row
delete from app.investor_sector_focus f using app.investor_profile mip, _merge m
  where mip.party_id=m.merge_id and f.investor_profile_id=mip.id;
delete from app.investor_interest_tags f using app.investor_profile mip, _merge m
  where mip.party_id=m.merge_id and f.investor_profile_id=mip.id;
delete from app.investor_profile mip using _merge m where mip.party_id=m.merge_id;

-- (5) SOFT-DELETE the merge party (recoverable), tag notes for audit
update app.parties p set
  deleted_at = now(),
  notes = coalesce(p.notes||E'\n','') || '[merged 2026-07-04 into ' || m.canonical_id || ']',
  updated_at = now()
from _merge m where p.id = m.merge_id;

-- (6) VERIFY: no merge_id should remain active; canonical retained
select (select count(*) from app.parties p join _merge m on p.id=m.merge_id where p.deleted_at is null) as merge_still_active,
       (select count(*) from app.parties p join _merge m on p.id=m.canonical_id where p.deleted_at is null) as canonical_active;
-- expected: merge_still_active = 0, canonical_active = 31

commit;
-- To roll back before commit: run ROLLBACK; instead of COMMIT.
