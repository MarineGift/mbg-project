-- ============================================================
-- scan_filler_paper_grade_reverify_2026-07-16.sql
--
-- WHY: three separate rows turned out to carry positioning lifted from the
-- company's OLD marketing page while the company's CURRENT disclosure said
-- something different.
--   MLC      - stored "No.2 US PCC player". Live web forms - PCC no longer sold.
--   Zantat   - stored "top MY GCC supplier FOR PAPER". Listed-entity end
--              markets - plastics, paints, gloves, rubber. Paper absent.
--   Shiraishi- stored "Japanese PCC pioneer" on the SALES entity, and the site's
--              four headline fields do not include paper at all.
-- Same failure mode each time. The FCC target ranking rests on these claims.
--
-- HONEST LIMITATION: this scan CANNOT identify "marketing-sourced" claims,
-- because provenance was never recorded. There is no source URL and no checked
-- date on any paper-grade claim. So this ranks by RE-VERIFICATION PRIORITY
-- instead - claim strength x ranking impact x not-yet-rechecked - which is the
-- best proxy available from the data as it stands. See section 6 for the
-- structural fix.
--
-- READ-ONLY. Nothing is written. Run each block separately in the SQL Editor.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) SUMMARY - how big is the problem ----------
select
  case
    when coalesce(f.notes,'') ~ '\[(jp-homepage|my-verify|mlc-homepage|kr-verify|pre-pccexit-values) 2026-07' then '0_RECHECKED 2026-07'
    when coalesce(f.notes,'') ~* 'paper.grade:\s*yes' and coalesce(f.evidence_level,'') in ('A','B') then '1_HIGH RISK x HIGH IMPACT'
    when coalesce(f.notes,'') ~* 'paper.grade:\s*yes' then '2_HIGH RISK x MED IMPACT'
    when coalesce(f.notes,'') ~* 'paper.grade:\s*(plausible|candidate|needs)' then '3_ALREADY SOFT'
    when f.id is null or coalesce(f.notes,'') = '' then '4_NEVER ASSESSED'
    else '5_OTHER'
  end as tier,
  count(*) as rows
from app.parties p
left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.party_type_id = 3 and p.deleted_at is null
group by 1
order by 1;


-- ---------- 2) TIER 1 WORKLIST - recheck these first ----------
-- Strong paper claim + evidence A/B = these rows are what the FCC ranking rests
-- on. If any is stale the ranking is wrong. MLC and Zantat both sat here.
select
  p.id, p.party_name, p.country_code, p.city, p.website,
  f.evidence_level, f.supply_model, f.market_role, f.mineral_class,
  (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as contacts,
  substring(f.notes from 'Paper.grade:[^.]{0,90}') as paper_claim,
  f.industry_source
from app.parties p
join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.party_type_id = 3 and p.deleted_at is null
  and coalesce(f.notes,'') ~* 'paper.grade:\s*yes'
  and coalesce(f.evidence_level,'') in ('A','B')
  and coalesce(f.notes,'') !~ '\[(jp-homepage|my-verify|mlc-homepage|kr-verify) 2026-07'
order by
  case when coalesce(f.supply_model,'') ~* 'satellite|onsite|on-site' then 0 else 1 end,
  f.evidence_level,
  p.party_name;


-- ---------- 3) TIER 2 - strong paper claim but weaker evidence ----------
select
  p.id, p.party_name, p.country_code, p.website,
  f.evidence_level, f.supply_model, f.market_role,
  substring(f.notes from 'Paper.grade:[^.]{0,90}') as paper_claim
from app.parties p
join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.party_type_id = 3 and p.deleted_at is null
  and coalesce(f.notes,'') ~* 'paper.grade:\s*yes'
  and coalesce(f.evidence_level,'') not in ('A','B')
  and coalesce(f.notes,'') !~ '\[(jp-homepage|my-verify|mlc-homepage|kr-verify) 2026-07'
order by p.country_code, p.party_name;


-- ---------- 4) NEVER ASSESSED - the hole that hid the JP top names ----------
-- Okutama, Shiraishi x2, Maruo and Bihoku all sat here for a month - website
-- backfilled, then skipped by every enrichment batch. Check who else is here.
select
  p.id, p.party_name, p.country_code, p.city, p.website,
  f.evidence_level, f.supply_model, f.mineral_class,
  (p.intro_ko is not null) as has_ko,
  case when f.id is null then 'NO PROFILE ROW' else 'profile exists, notes empty' end as state
from app.parties p
left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.party_type_id = 3 and p.deleted_at is null
  and (f.id is null or coalesce(f.notes,'') = '')
order by p.country_code nulls last, p.party_name;


-- ---------- 5) INFORMAL JUDGEMENT TEXT - star ratings, not evidence ----------
-- batch14 rescued evaluation text that had been stuffed in the website column
-- and tagged it [ex-website-note 2026-06-20]. Those are opinions with star
-- marks, not sourced claims. MLC's "No.2 US PCC player" was one of them.
select
  p.id, p.party_name, p.country_code, f.evidence_level, f.supply_model,
  substring(f.notes from '\[ex-website-note 2026-06-20\][^\n]{0,110}') as informal_note
from app.parties p
join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.party_type_id = 3 and p.deleted_at is null
  and coalesce(f.notes,'') like '%[ex-website-note 2026-06-20]%'
order by p.country_code, p.party_name;


-- ---------- 6) DUPE DETECTOR BY DOMAIN, not by name ----------
-- The Omya Korea dupe happened because the guard matched exact party_name.
-- 'Omya Korea Inc.' never collided with 'Omya (Korea)'. Grouping by host plus
-- country catches that class of thing. Review before any future insert.
select
  coalesce(p.country_code,'??') as cc,
  lower(regexp_replace(regexp_replace(coalesce(p.website,''), '^https?://', ''), '/.*$', '')) as host,
  count(*) as rows,
  string_agg(p.party_name, ' | ' order by p.party_name) as names
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and coalesce(p.website,'') <> ''
group by 1, 2
having count(*) > 1
order by count(*) desc, 1, 2;


-- ---------- 7) STRUCTURAL FIX (proposal - not applied here) ----------
-- The real defect is that no paper-grade claim records where it came from or
-- when it was checked. extra_data is already a jsonb column on
-- app.filler_supplier_profile and default '{}', so provenance can live there
-- with no migration:
--
--   {"paper_grade": {
--      "claim": "yes",
--      "source_url": "https://www.mlc.com/contact-us/",
--      "source_type": "transactional",     -- marketing | disclosure | transactional | third_party
--      "checked_at": "2026-07-16"
--   }}
--
-- source_type is the field that would have caught all three misses - a claim
-- resting only on source_type = marketing is exactly the risk class. Once it is
-- populated this whole scan collapses to one honest query:
--
--   select party_name from app.parties p
--   join app.filler_supplier_profile f on f.party_id = p.id
--   where f.extra_data #>> '{paper_grade,source_type}' = 'marketing'
--      or f.extra_data #>> '{paper_grade,checked_at}' < '2026-01-01';
--
-- Backfilling every row is not realistic. Suggested scope - populate it for the
-- Tier 1 list from block 2 as each row is rechecked, so the coverage grows with
-- the work rather than as a separate project.
