-- ============================================================
-- scan_paper_mill_reachability_2026-07-17.sql
--
-- BLOCK 9 CAME BACK AND TWO NUMBERS DIED. Both were mine to check and I did not.
--
-- 1. I SAID THE FORM COHORT WAS 63. IT IS 757.
--    I counted the three batch files committed to sql/ - batch2 KC+IP 56,
--    batch3 KR 6, batch17 Renova 1 - and treated that as the cohort. Block 9
--    counted 757 mills carrying a source='form' marker. Batches 1 and 4 through
--    16 were APPLIED and never committed, or were applied through the app. The
--    repo is not the database. I have known that since plant_supply_links -
--    migration 024 sits in sql/ and was never applied - and I made the mirror
--    error today, reading sql/ as if it were the schema.
--    757 mills say a form exists. 20 say where it is. THAT is the gap.
--
-- 2. migration_028 SAID THE MILL ROSTER IS REACHABLE. IT IS NOT.
--    Its header: "of 888 paper mill parties, 868 already have a contact - 97.7
--    percent. The mill roster is the one part of this database that is actually
--    reachable." Block 9 says 114 mills have a contact with an EMAIL, and 20
--    have a form URL. Ceiling 134 of 888 - FIFTEEN PERCENT.
--    868 minus 757 marker rows leaves roughly the 114. The 97.7 percent counted
--    'Form 입력' placeholders - rows with a null email, no URL and no routing
--    information of any kind - as contacts. I wrote that sentence into 028's
--    header and built today's plan on top of it.
--
--    THIS IS YESTERDAY'S ERROR WEARING THE OTHER SHOE. `4 of 242` filler
--    coverage had a wrong DENOMINATOR - 242 was rows, not companies. `868 of
--    888` mill coverage has a wrong NUMERATOR - 868 is rows, not contacts. Both
--    times the number was believed because it was already written down.
--    Block 0 proves it or kills it.
--
-- 3. THE INVERSION IS REAL AND IT IS BIGGER THAN 56.
--    Vocabulary confirmed: high / medium / low / none, and combinations.
--      touches high    187 mills   29 email   7 url   159 markers
--      only low/none   329 mills   15 email   5 url   306 markers
--      no grade link   238 mills   47 email   8 url   185 markers
--    306 form routes recorded on grades with low or no filler relevance, against
--    159 on grades that touch high. I estimated 56 wrong ones. It is at least
--    306, and the rule broken - do not record a contact route on a non-target -
--    was broken at roughly six times the scale I claimed.
--
-- 4. AND THE BEST-CONNECTED BAND IS THE ONE WE CANNOT JUDGE.
--    238 mills have NO grade link - 27 percent of the roster - and they hold 47
--    emails, more than any other band. The most reachable mills in this database
--    are the ones the grade axis cannot classify at all.
--
-- 5. THE QUESTION THIS RAISES ABOUT THE WHOLE PROJECT.
--    29 mills touch a high-filler grade AND already have an email. A form is the
--    slow door. If those 29 are real, the highest-value action today is not
--    building forms - it is writing to 29 addresses that already exist. Block 1
--    names them. I was asked to build forms and the data may be saying the form
--    is the wrong instrument for the best targets.
--
-- READ-ONLY. Writes nothing. Run each block SEPARATELY.
-- The vocabulary is now KNOWN, so filtering on 'high' below is checked, not
-- guessed. That is the only reason it is allowed here and was not in v1.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 0) THE REACHABILITY AUDIT - is 97.7 percent a placeholder count ----------
select coalesce(c.source, '(null)') as source,
       count(*) as contact_rows,
       count(*) filter (where nullif(btrim(c.email), '') is not null) as rows_with_email,
       count(distinct c.party_id) as mills_touched,
       count(distinct c.party_id) filter (where nullif(btrim(c.email), '') is not null) as mills_with_email
from app.contacts c
join app.parties p on p.id = c.party_id
where p.party_type_id = 2
  and p.deleted_at is null
  and c.deleted_at is null
group by 1
order by 2 desc;
-- EXPECT source='form' to be roughly 757 rows with ZERO emails.
-- If it is, migration_028's header is wrong and so is every plan built on it,
-- including this morning's. The mill roster is not reachable - it is annotated.
-- Fix 028's comment. A wrong number in a migration header outlives the migration.


-- ---------- 1) THE 29 - high grade, email already in hand, no form needed ----------
select p.country_code, p.party_name, p.website,
       (select string_agg(distinct pt.filler_relevance, ' / ')
        from app.paper_mill_paper_types mp
        join app.paper_types pt on pt.id = mp.paper_type_id
        where mp.mill_party_id = p.id) as filler_relevance,
       (select string_agg(pt.label_en, ' | ' order by mp.is_primary desc, pt.label_en)
        from app.paper_mill_paper_types mp
        join app.paper_types pt on pt.id = mp.paper_type_id
        where mp.mill_party_id = p.id and pt.filler_relevance = 'high') as high_grades,
       (select string_agg(c.email, ' | ' order by c.is_primary desc, c.email)
        from app.contacts c
        where c.party_id = p.id and c.deleted_at is null
          and nullif(btrim(c.email), '') is not null) as emails,
       p.contact_form_url,
       p.do_not_contact
from app.parties p
where p.party_type_id = 2
  and p.deleted_at is null
  and exists (select 1 from app.paper_mill_paper_types mp
              join app.paper_types pt on pt.id = mp.paper_type_id
              where mp.mill_party_id = p.id and pt.filler_relevance = 'high')
  and exists (select 1 from app.contacts c
              where c.party_id = p.id and c.deleted_at is null
                and nullif(btrim(c.email), '') is not null)
order by p.country_code, p.party_name;
-- THE LIST THAT MAY END THE FORM PROJECT FOR THE TOP OF THE ROSTER.
-- Roughly 29 rows. Read the emails before believing them - yesterday a batch of
-- 14 people was nearly invented out of local-parts, and enrich_mlc_us_filler
-- still owes a source check. A generic inbox on a mill that makes high-filler
-- grades still beats a contact form on the same mill, because a form has no
-- reply-to and no thread.
-- do_not_contact is printed so Kleannara cannot slip into this list unnoticed.


-- ---------- 2) THE 20 WITH A URL - only 5 of them are mine ----------
select p.country_code, p.party_name, p.contact_form_url,
       p.preferred_contact_method, p.updated_at,
       (select count(*) from app.application_forms af
        where af.party_id = p.id and af.form_type = 'contact_inquiry') as form_rows,
       (select string_agg(distinct pt.filler_relevance, ' / ')
        from app.paper_mill_paper_types mp
        join app.paper_types pt on pt.id = mp.paper_type_id
        where mp.mill_party_id = p.id) as filler_relevance
from app.parties p
where p.party_type_id = 2
  and p.deleted_at is null
  and p.contact_form_url is not null
order by p.updated_at desc;
-- Today wrote FIVE - Hansol x4 and Hankuk x1. Block 9 counted twenty. FIFTEEN
-- mill URLs existed before this session and I asserted in v1 of the cohort scan
-- that every row in the cohort would be null. Wrong again, and cheaply checkable.
-- WHERE THEY CAME FROM MATTERS: migration_027 block 6 backfills contact_form_url
-- onto parties out of any application_forms row with a web_form or portal
-- submission_method. If these fifteen arrived that way they are trustworthy. If
-- they arrived some other way, they are unsourced URLs on a mill roster and need
-- the same treatment as the local-part contacts.
-- This block also doubles as the write check for Hansol and Hankuk - five rows
-- with today's updated_at, or the guards matched nothing.


-- ---------- 3) THE REAL SWEEP LIST - high grade, marker, no way to reach it ----------
select p.country_code,
       count(*) as mills,
       string_agg(p.party_name, ' | ' order by p.party_name) as who
from app.parties p
where p.party_type_id = 2
  and p.deleted_at is null
  and p.contact_form_url is null
  and exists (select 1 from app.paper_mill_paper_types mp
              join app.paper_types pt on pt.id = mp.paper_type_id
              where mp.mill_party_id = p.id and pt.filler_relevance = 'high')
  and exists (select 1 from app.contacts c
              where c.party_id = p.id and c.deleted_at is null and c.source = 'form')
  and not exists (select 1 from app.contacts c
                  where c.party_id = p.id and c.deleted_at is null
                    and nullif(btrim(c.email), '') is not null)
group by 1
order by 2 desc, 1;
-- Roughly 130 mills. High-filler grades, somebody already established that the
-- only door is a form, and nobody wrote down the door. THIS is the sweep - not
-- the 63 I described this morning, and not the KC and IP rows I spent the
-- handoff arguing about.
-- Grouped by country because that is how the filler sweep found its edge -
-- India was 4 of 7. Sweep the country with the best ratio first, not the
-- alphabet.


-- ---------- 4) THE 238 WITH NO GRADE LINK - the roster's blind spot ----------
select p.country_code,
       count(*) as mills,
       count(*) filter (where exists (select 1 from app.contacts c
                        where c.party_id = p.id and c.deleted_at is null
                          and nullif(btrim(c.email), '') is not null)) as with_email,
       string_agg(p.party_name, ' | ' order by p.party_name)
         filter (where exists (select 1 from app.contacts c
                 where c.party_id = p.id and c.deleted_at is null
                   and nullif(btrim(c.email), '') is not null)) as reachable_ones
from app.parties p
where p.party_type_id = 2
  and p.deleted_at is null
  and not exists (select 1 from app.paper_mill_paper_types mp where mp.mill_party_id = p.id)
group by 1
order by 3 desc, 2 desc;
-- 238 mills, 47 emails - the highest email count of any band, on the one band
-- with no grade information at all. Everything above sorts the roster by a field
-- that is missing for 27 percent of it.
-- Linking a mill to a paper_type is cheap compared to a homepage sweep, and 47
-- of these are already reachable. If even a third make high-filler grades, that
-- is a bigger prize than anything in block 3 and it needs no new contacts.


-- ---------- 5) DID HANKUK ACTUALLY WRITE ----------
select p.id, p.party_name, p.party_type_id, p.do_not_contact,
       p.preferred_contact_method, p.contact_form_url,
       af.form_type, af.submission_method, af.status,
       (select count(*) from app.application_form_fields ff where ff.form_id = af.id) as fields
from app.parties p
left join app.application_forms af
  on af.party_id = p.id and af.form_type = 'contact_inquiry'
where p.id = '028f9b56-3780-4bb2-91f4-ca3514025484'::uuid;
-- EXPECT one row, web_form, contact_inquiry, not_started, FIELDS = 10.
-- 'Success. No rows returned' told us nothing - Supabase says that for any DML
-- without RETURNING whether it matched one row or zero.
-- Block 9 returning 888 mills against party_type_id = 2, matching 028's own
-- count exactly, is good evidence that the 2 is right and the guards passed. It
-- is not proof that this row exists.
