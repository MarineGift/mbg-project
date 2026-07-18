-- ============================================================
-- scan_paper_mill_sweep_worklist_2026-07-17.sql
--
-- "한국 제외 전부" = 757 마커 - 6 KR. Before accepting that number, the same
-- question that broke yesterday: IS 757 A COUNT OF COMPANIES.
--
-- IT IS NOT, AND THE PROOF IS ALREADY IN sql/.
--   paper-mill-contacts-batch2-KC-IP-form.sql wrote 56 rows:
--     Kimberly-Clark    33 rows - Argentina, Australia, Colombia, Costa Rica,
--                       CZ, Dominican, Ecuador, France, UK, Guatemala, Honduras,
--                       Mexico, Nigeria, Panama, Peru, Saudi, El Salvador,
--                       Thailand, Venezuela, South Africa + 13 US mills
--     International Paper 23 rows - Spain, UK, Italy, Morocco, Mexico, Poland
--                       + 13 US mills + the company itself
--   A corporate contact form is ONE form. kimberly-clark.com does not serve 33
--   forms. 56 rows are TWO companies, and building 56 form rows would be 56
--   copies of two tasks - which is fix_azolla_duplicate_form_2026-07-10, at
--   twenty-eight times the scale.
--
-- Yesterday: "242는 회사 수가 아닙니다." Today the same sentence with a bigger
-- number. 757 is rows. Block 0 says how many companies.
--
-- AND THE SECOND GATE, which no one has checked: A SWEEP NEEDS A WEBSITE.
-- Every one of the 26 filler verdicts yesterday came off a company page. A mill
-- row with a null website cannot be swept at all - not slowly, not ever - and
-- the KR filler roster already had this exact hole ("KR 무사이트 5곳" in batch 3).
-- Block 1 sizes it BEFORE anyone plans a sweep against a number that includes
-- rows with nowhere to go.
--
-- WHAT "충전제 제조사처럼" ACTUALLY PRODUCED, since it is the stated benchmark:
--   26 companies opened, 26 verdicts, and ONE application_forms row - Artemyn -
--   WITH ZERO FIELDS, because its page is a HubSpot embed. The filler sweep did
--   not mass-produce forms. It produced judgments, and the one form it made is
--   still not fillable.
--   Hankuk already passed that: one form, ten real fields, verified in the DB an
--   hour ago. The mill side is ahead of the benchmark, not behind it.
--
-- THE REAL CONSTRAINT, stated plainly. Field capture needs the page opened, and
-- max_length needs a browser because a server fetch does not return the
-- attribute. That is what happened with Artemyn yesterday and with Hansol and
-- Hankuk today - three for three. Twenty-six companies took a full day. "All
-- countries" is not one file. It is a batched sweep, and this scan is what makes
-- the batches.
--
-- READ-ONLY. Writes nothing. Run each block SEPARATELY.
-- Block 3 is the one to send back - it is what I write the fix files from.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 0) 757 ROWS - HOW MANY COMPANIES ----------
select count(*) as marker_rows,
       count(distinct split_part(p.party_name, ' - ', 1)) as brands,
       count(distinct p.domain_normalized) filter (where p.domain_normalized is not null) as domains,
       count(*) filter (where p.party_name ~ ' - ') as plant_rows,
       count(*) filter (where p.country_code = 'KR') as kr_rows,
       count(*) filter (where p.country_code is null) as country_unknown
from app.parties p
where p.party_type_id = 2
  and p.deleted_at is null
  and exists (select 1 from app.contacts c
              where c.party_id = p.id and c.source = 'form' and c.deleted_at is null);
-- The gap between marker_rows and brands is the whole argument. If 757 rows
-- collapse to something like 60 brands, then "한국 제외 전부" is a few dozen
-- companies and it is a real week of work rather than an impossible one.


-- ---------- 1) CAN THEY EVEN BE SWEPT ----------
select case when nullif(btrim(p.website), '') is null then 'NO WEBSITE - unsweepable'
            else 'has website' end as sweepable,
       count(*) as rows,
       count(distinct split_part(p.party_name, ' - ', 1)) as brands
from app.parties p
where p.party_type_id = 2
  and p.deleted_at is null
  and coalesce(p.country_code, '') <> 'KR'
  and exists (select 1 from app.contacts c
              where c.party_id = p.id and c.source = 'form' and c.deleted_at is null)
group by 1
order by 1;
-- A mill with a form marker and no website is a row asserting a form exists on a
-- site nobody recorded. That marker cannot be verified and cannot be swept. It is
-- also evidence the marker was never worth much - somebody wrote "Form 입력"
-- without keeping the address, 757 times.


-- ---------- 2) THE BRANDS, LARGEST FIRST - one form each, not one per row ----------
select split_part(p.party_name, ' - ', 1) as brand,
       count(*) as rows,
       count(distinct p.country_code) as countries,
       string_agg(distinct p.country_code, ',' order by p.country_code) as where_,
       count(*) filter (where p.party_name !~ ' - ') as company_level_rows,
       max(p.website) as a_website,
       count(*) filter (where exists (select 1 from app.contacts c
                        where c.party_id = p.id and c.deleted_at is null
                          and nullif(btrim(c.email), '') is not null)) as rows_with_email,
       count(*) filter (where exists (select 1 from app.paper_mill_paper_types mp
                        join app.paper_types pt on pt.id = mp.paper_type_id
                        where mp.mill_party_id = p.id and pt.filler_relevance = 'high')) as rows_high_grade
from app.parties p
where p.party_type_id = 2
  and p.deleted_at is null
  and coalesce(p.country_code, '') <> 'KR'
  and exists (select 1 from app.contacts c
              where c.party_id = p.id and c.source = 'form' and c.deleted_at is null)
group by 1
having count(*) > 1
order by count(*) desc, 1;
-- EXPECT Kimberly-Clark near 33 and International Paper near 23. Every brand here
-- is ONE form and N rows. company_level_rows is where the form row must go -
-- if a brand shows 13 rows and 0 company-level rows, its form has nowhere legal
-- to live and that is a roster problem, exactly like Hansol this morning.
-- rows_high_grade is the reason to sweep it or skip it. A brand with 33 rows and
-- 0 high-grade rows is 33 rows of tissue.


-- ---------- 3) THE SWEEP LIST - what I write fix files from ----------
select p.country_code, p.party_name, p.id, p.website, p.domain_normalized,
       (select string_agg(distinct pt.filler_relevance, ' / ')
        from app.paper_mill_paper_types mp
        join app.paper_types pt on pt.id = mp.paper_type_id
        where mp.mill_party_id = p.id) as filler_relevance,
       (select string_agg(pt.label_en, ' | ' order by mp.is_primary desc, pt.label_en)
        from app.paper_mill_paper_types mp
        join app.paper_types pt on pt.id = mp.paper_type_id
        where mp.mill_party_id = p.id) as grades
from app.parties p
where p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false
  and coalesce(p.country_code, '') <> 'KR'
  and p.party_name !~ ' - '                        -- companies sign, plants do not
  and p.contact_form_url is null
  and nullif(btrim(p.website), '') is not null     -- unsweepable otherwise
  and exists (select 1 from app.contacts c
              where c.party_id = p.id and c.source = 'form' and c.deleted_at is null)
  and not exists (select 1 from app.contacts c    -- an email beats a form, always
                  where c.party_id = p.id and c.deleted_at is null
                    and nullif(btrim(c.email), '') is not null)
order by p.country_code, p.party_name;
-- EVERY FILTER IS EARNED, NOT TASTE:
--   do_not_contact false  - migration_028, and Kleannara is a mill
--   not KR                - asked for
--   no ' - '              - a plant cannot sign and its form is the group's
--   contact_form_url null - already done ones stay done
--   website not null      - block 1. No page, no sweep
--   form marker exists    - somebody already established the door is a form
--   no email              - THE ONE THAT CUTS MOST. Burgo has
--                           info@burgogroup.com, a live monitored inbox, and
--                           fix_burgo_domain_verified proved it. A form has no
--                           reply-to and no thread. If a mill has an address,
--                           building it a form is downgrade work.
-- SEND THIS BLOCK BACK. Every mill file in sql/ targets by exact party_name and
-- carries no uuid - fix_burgo_domain_verified and fix_saica_wrong_contact both
-- say so in their headers. I need the NAMES, not the ids, and then the sweep runs
-- in country batches ordered by whatever this returns.


-- ---------- 4) WHERE TO START ----------
select p.country_code,
       count(*) as sweepable_companies,
       count(*) filter (where exists (select 1 from app.paper_mill_paper_types mp
                        join app.paper_types pt on pt.id = mp.paper_type_id
                        where mp.mill_party_id = p.id and pt.filler_relevance = 'high')) as high_grade,
       count(*) filter (where not exists (select 1 from app.paper_mill_paper_types mp
                        where mp.mill_party_id = p.id)) as no_grade_link
from app.parties p
where p.party_type_id = 2
  and p.deleted_at is null
  and p.do_not_contact is false
  and coalesce(p.country_code, '') <> 'KR'
  and p.party_name !~ ' - '
  and p.contact_form_url is null
  and nullif(btrim(p.website), '') is not null
  and exists (select 1 from app.contacts c
              where c.party_id = p.id and c.source = 'form' and c.deleted_at is null)
  and not exists (select 1 from app.contacts c
                  where c.party_id = p.id and c.deleted_at is null
                    and nullif(btrim(c.email), '') is not null)
group by 1
order by 3 desc, 2 desc;
-- Sweep the country with the best high_grade ratio first, not the alphabet.
-- That is the one thing yesterday actually established - India came back 4 STRONG
-- out of 7 real companies while Mexico came back 0 of 3, and nothing in the
-- database predicted either. Country ratio was the only signal that held.
