-- ============================================================================
-- !!!  Ctrl+A (select ALL) then Run  !!!   (editor runs only highlighted text)
-- ============================================================================
-- seed_20261011_mbg_test_mill.sql
-- Creates ONE test paper mill "MBG Test Mill" (US) with ONE primary contact,
-- so the FCC template can be test-sent through /marketing (Keyword:
-- MBG Test Mill). After the test, set the mill to archived - /marketing skips
-- archived parties.
--
-- >>> BEFORE RUNNING: replace YOUR_TEST_EMAIL@gmail.com (2 places below) with
--     the address that should receive the test mail. Nothing is created while
--     the placeholder is still there.
--
-- Idempotent: running it again does not make a second mill or contact.
-- Last statement is a verification select.
-- ============================================================================

insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, city, status, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       'MBG Test Mill',
       (select t.id from app.party_types t where t.code = 'paper_mill'),
       (select e.id from app.entity_types e where e.code = 'company'),
       'US', 'Houston', 'active', 'internal_test',
       'Internal test recipient for /marketing template checks - keep archived when not testing'
where position('YOUR_TEST_EMAIL' in 'YOUR_TEST_EMAIL@gmail.com') = 0
  and not exists (
    select 1 from app.parties p
    where p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
      and p.party_name = 'MBG Test Mill'
      and p.deleted_at is null
  );

insert into app.contacts
  (organization_id, party_id, contact_type_id, email, full_name, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, p.id, 2,
       lower('YOUR_TEST_EMAIL@gmail.com'), 'Test Recipient', 'Test inbox',
       true, false, 'internal_test', 'Receives /marketing test sends'
from app.parties p
where p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.party_name = 'MBG Test Mill'
  and p.deleted_at is null
  and not exists (
    select 1 from app.contacts c
    where c.party_id = p.id and c.deleted_at is null
      and nullif(btrim(c.email), '') is not null
  );

select p.party_name, p.country_code, p.status, c.email, c.is_primary, p.id as party_id
from app.parties p
left join app.contacts c on c.party_id = p.id and c.deleted_at is null
where p.party_name = 'MBG Test Mill'
  and p.deleted_at is null;
