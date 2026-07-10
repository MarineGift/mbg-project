-- ============================================================
-- fix_drafting_final_text_resync_2026-07-10.sql
-- The Series A backfills rewrote answer_library, but final_text
-- on application_field_answers is a frozen copy per field, so
-- DRAFTING forms (3M Ventures, 1955 Capital) can still carry
-- SAFE era text. Submitted forms are preserved on purpose.
--
--   DETECT A - drafting fields whose final_text still shows a
--              stale marker (must fix)
--   FIX B    - resync ONLY those stale fields off the bound
--              library answer, language matched (Hangul in the
--              old text -> body_ko, otherwise body_en)
--   REPORT C - drafting fields whose final_text differs off the
--              library body without stale markers - these may be
--              intentional per-form tailoring, review only
--   BONUS D  - Azolla form_url corrected to the real entry
--              point, the Typeform behind the contact page
--
-- Supabase SQL Editor safe: no do-blocks, no temp tables,
-- no semicolons inside string literals
-- ============================================================

-- ------------------------------------------------------------
-- DETECT A: stale markers on drafting forms (run before FIX B
-- to see the damage, expect rows for 3M or 1955 Capital)
-- ------------------------------------------------------------
select pt.party_name, f.status, ff.label, al.answer_key, al.variant,
       left(fa.final_text, 60) as text_head
from app.application_field_answers fa
join app.application_form_fields ff on ff.id = fa.field_id
join app.application_forms f        on f.id  = ff.form_id
join app.parties pt                 on pt.id = f.party_id
left join app.answer_library al     on al.id = fa.answer_id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and f.status = 'drafting'
  and (
       fa.final_text like '%1000만%' or fa.final_text like '%1,000만%'
    or fa.final_text like '%10만 달러%' or fa.final_text like '%확정하지 않%'
    or fa.final_text like '%유리한 쪽%'
    or fa.final_text like '%100,000%' or fa.final_text like '%$100K%'
    or fa.final_text like '%100K SAFE%' or fa.final_text like '%10M cap%'
    or fa.final_text like '%10,000,000%'
    or fa.final_text like '%20%% discount%' or fa.final_text like '%MFN%'
  )
order by pt.party_name, ff.seq;


-- ------------------------------------------------------------
-- FIX B: resync stale fields off the bound library answer.
-- Only touches drafting forms, only rows with a stale marker,
-- only rows actually bound to a library answer. Language of the
-- replacement follows the language of the old text.
-- ------------------------------------------------------------
update app.application_field_answers fa
set final_text = case
                   when fa.final_text ~ '[가-힣]' then al.body_ko
                   else al.body_en
                 end,
    is_copied  = false,
    updated_at = now()
from app.application_form_fields ff,
     app.application_forms f,
     app.answer_library al
where ff.id = fa.field_id
  and f.id  = ff.form_id
  and al.id = fa.answer_id
  and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and f.status = 'drafting'
  and (
       fa.final_text like '%1000만%' or fa.final_text like '%1,000만%'
    or fa.final_text like '%10만 달러%' or fa.final_text like '%확정하지 않%'
    or fa.final_text like '%유리한 쪽%'
    or fa.final_text like '%100,000%' or fa.final_text like '%$100K%'
    or fa.final_text like '%100K SAFE%' or fa.final_text like '%10M cap%'
    or fa.final_text like '%10,000,000%'
    or fa.final_text like '%20%% discount%' or fa.final_text like '%MFN%'
  )
  and case
        when fa.final_text ~ '[가-힣]' then al.body_ko
        else al.body_en
      end is not null;


-- ------------------------------------------------------------
-- REPORT C: drafting fields whose final_text no longer matches
-- the bound library body in either language - review only, these
-- can be legitimate per-form tailoring. Do NOT bulk overwrite.
-- ------------------------------------------------------------
select pt.party_name, ff.label, al.answer_key, al.variant,
       fa.char_count,
       left(fa.final_text, 50) as text_head,
       left(coalesce(al.body_en, al.body_ko), 50) as library_head
from app.application_field_answers fa
join app.application_form_fields ff on ff.id = fa.field_id
join app.application_forms f        on f.id  = ff.form_id
join app.parties pt                 on pt.id = f.party_id
join app.answer_library al          on al.id = fa.answer_id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and f.status = 'drafting'
  and fa.final_text is not null
  and fa.final_text is distinct from al.body_en
  and fa.final_text is distinct from al.body_ko
order by pt.party_name, ff.seq;


-- ------------------------------------------------------------
-- BONUS D: Azolla entry point is a Typeform, not the contact
-- page - correct the registered form_url (checked 2026-07-10)
-- ------------------------------------------------------------
update app.application_forms f
set form_url   = 'https://azollaventures.typeform.com/to/zgHBtjoX',
    notes      = 'P1 form blitz - gigaton CO2e decarbonization thesis fit. Entry is the Company Interest Form typeform linked off contact-us',
    updated_at = now()
from app.parties pt
where pt.id = f.party_id
  and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%azolla%'
  and f.form_url = 'https://azollaventures.com/contact-us/';


-- ------------------------------------------------------------
-- VERIFY: rerun of the stale sweep after FIX B (expect 0 rows)
-- plus the corrected Azolla row
-- ------------------------------------------------------------
select pt.party_name, f.status, count(*) as stale_fields
from app.application_field_answers fa
join app.application_form_fields ff on ff.id = fa.field_id
join app.application_forms f        on f.id  = ff.form_id
join app.parties pt                 on pt.id = f.party_id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and f.status = 'drafting'
  and (
       fa.final_text like '%1000만%' or fa.final_text like '%1,000만%'
    or fa.final_text like '%10만 달러%' or fa.final_text like '%확정하지 않%'
    or fa.final_text like '%유리한 쪽%'
    or fa.final_text like '%100,000%' or fa.final_text like '%$100K%'
    or fa.final_text like '%100K SAFE%' or fa.final_text like '%10M cap%'
    or fa.final_text like '%10,000,000%'
    or fa.final_text like '%20%% discount%' or fa.final_text like '%MFN%'
  )
group by pt.party_name, f.status;

select pt.party_name, f.form_url, f.notes
from app.application_forms f
join app.parties pt on pt.id = f.party_id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%azolla%';
