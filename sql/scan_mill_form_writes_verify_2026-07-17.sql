-- ============================================================
-- scan_mill_form_writes_verify_2026-07-17.sql
--
-- 'Success. No rows returned' has now been the answer to three separate write
-- files today, and it means nothing. Supabase prints it for any DML without
-- RETURNING whether the statement matched one row or zero. Every fix file today
-- shipped its verify AS A COMMENT, which is the same as not shipping one.
--
-- MY DEFECT, and the fix is a convention, not a file:
--   FROM NOW ON THE LAST STATEMENT OF EVERY FIX FILE IS AN UNCOMMENTED SELECT.
-- Supabase runs the whole file and displays the LAST result set. Put the verify
-- there and 'Success. No rows returned' can never appear again - the file
-- answers its own question on the way out. Zero cost, and it would have caught
-- anything wrong three files ago.
--
-- Until those files are reissued, this is the catch-up. Everything written today
-- in one screen.
--
-- READ-ONLY. One block. Run it whole.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

select v.expect,
       p.party_name,
       p.country_code,
       p.party_type_id,
       p.do_not_contact,
       p.preferred_contact_method,
       p.contact_form_url,
       af.form_type,
       af.status,
       (select count(*) from app.application_form_fields ff where ff.form_id = af.id) as fields,
       p.updated_at
from (values
  ('A. Hankuk  - url + form + 10 fields', '028f9b56-3780-4bb2-91f4-ca3514025484'::uuid),
  ('B. Andhra  - url + form + 8 fields',  '6ad04789-209f-4df1-b185-24a50c60717d'::uuid),
  ('C. Hansol Cheonan   - url, NO form',  'b2d7898e-1571-44c8-8db5-ce5f74f55334'::uuid),
  ('C. Hansol Daejeon   - url, NO form',  'a02f872c-2f9e-4863-b271-4ab9741d6be2'::uuid),
  ('C. Hansol Janghang  - url, NO form',  '890ae7ee-12ae-4889-be24-c1f2155dbad0'::uuid),
  ('C. Hansol Shintanjin- url, NO form',  '5110d2b4-d248-4a0f-a6cc-9e0580dff060'::uuid),
  ('D. Papertech CONTROL- must stay NULL','c318be29-8a39-4b42-a2dd-71f6085518cc'::uuid)
) as v(expect, party_id)
join app.parties p on p.id = v.party_id and p.deleted_at is null
left join app.application_forms af
  on af.party_id = p.id and af.form_type = 'contact_inquiry'
order by v.expect, p.party_name;

-- HOW TO READ IT - seven rows, and each letter is a different question.
--
-- A  Hankuk   web_form · hankukpaper.com/ko/cs/addViewCsqna.do · contact_inquiry
--             · not_started · fields 10        ALREADY CONFIRMED at 19:12.
--
-- B  Andhra   web_form · andhrapaper.com/become-our-supplier/ · contact_inquiry
--             · not_started · fields 8         THIS IS THE ONE IN QUESTION.
--             If contact_form_url is null, the update matched nothing and the
--             cause is one of exactly three things, all checkable:
--               party_type_id is not 2   - but 888 mills answered to 2 twice
--               do_not_contact is true   - it should be false
--               the uuid is wrong        - it came out of block 3's own CSV
--             If the url landed but form_type is null, statement 2 failed while
--             1 succeeded, which means the NOT EXISTS guard found a form already
--             there - say so and I will look.
--             If fields comes back under 8, statement 3 partially applied.
--
-- C  Hansol   FOUR rows, each with the url and NO form row. The missing form is
--             deliberate - all four are mill rows and the form belongs to
--             한솔제지(주). If af.form_type is populated here, something else made
--             a form and I need to know.
--             If contact_form_url is null on all four, note the extra guard in
--             that file: `and p.contact_form_url is null`. It is idempotent, so
--             a second run is a no-op, not a failure.
--
-- D  Papertech MUST be null on both columns. It has its own domain and was never
--             swept. If it has the 한솔제지 url, I contaminated it and it needs
--             clearing - that is the error class caught eight times yesterday.
--
-- IF A ROW IS MISSING ENTIRELY, that uuid is not a live party and the CSV it came
-- from is stale. Send the output as-is.
