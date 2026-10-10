-- ============================================================
-- enrich_20261010_mill_emails_b16.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Batch 16 - TW / IL / BR / AR / KE, crawler run w11 (2026-10-10).
-- Part 1 websites (8 rows) - each site was reached by the crawler.
-- Part 2 e-mails (6 rows) printed on the company sites:
--   Shaniv info@ | Santher fale.conosco@ (contact inbox) |
--   Papel Prensa comercializacion@ (sales, primary) + ppsa@ (general) |
--   Chandaria info@ | Kim-Fay customercare@
-- Not used: Papel Prensa purchasing / HR / credit-desk inboxes, and a
-- template placeholder address on the Santher page.
-- Cheng Loong, Chung Hwa Pulp, Mili: site reached, no address (form only).
-- Crawl failed (bot block or wrong domain): Longchen, YFY, Hadera, Ibema,
-- Familia, UPPC, UCIC - not filled.
-- Idempotent. Last statement is a verification select.
-- ============================================================
update app.parties p
set website = v.website,
    domain_normalized = coalesce(nullif(btrim(p.domain_normalized), ''), v.domain),
    updated_at = now()
from (values
  ('705b866d-bd5a-4432-93d1-4931a0b16cf7'::uuid, 'https://www.clc.com.tw',      'clc.com.tw'),
  ('d1624c06-608e-4177-9370-cb922e80c3fb'::uuid, 'https://www.chp.com.tw',      'chp.com.tw'),
  ('b5574536-aaeb-4ba1-9f39-28c7ff009c07'::uuid, 'https://shaniv.com',          'shaniv.com'),
  ('c8f84cce-1654-4f4d-a955-294f0ecfc58d'::uuid, 'https://www.santher.com.br',  'santher.com.br'),
  ('51ccf210-289f-46c3-829b-e0a6b0cc9b2f'::uuid, 'https://www.mili.com.br',     'mili.com.br'),
  ('eea07746-7316-40c8-8ea9-26d79b6294c2'::uuid, 'https://papelprensa.com',     'papelprensa.com'),
  ('98ab4582-52eb-45af-aaa8-e212ff558c4b'::uuid, 'https://chandaria.com',       'chandaria.com'),
  ('e0687d63-e113-443f-892b-ba9c899481a7'::uuid, 'https://www.kimfay.com',      'kimfay.com')
) as v(party_id, website, domain)
where p.id = v.party_id
  and p.deleted_at is null
  and nullif(btrim(p.website), '') is null;

insert into app.contacts
  (organization_id, party_id, contact_type_id, email, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.party_id, 2, v.email, v.title_text,
       v.is_primary, false, 'homepage', v.notes
from (values
  ('b5574536-aaeb-4ba1-9f39-28c7ff009c07'::uuid, 'info@shaniv.com', 'General inbox', true,
   'Shown on https://shaniv.com/en/contact-us/ (crawler 2026-10-10)'),
  ('c8f84cce-1654-4f4d-a955-294f0ecfc58d'::uuid, 'fale.conosco@santher.com.br', 'Contact inbox', true,
   'Shown on https://www.santher.com.br/ (crawler 2026-10-10)'),
  ('eea07746-7316-40c8-8ea9-26d79b6294c2'::uuid, 'comercializacion@papelprensa.com', 'Sales inbox', true,
   'Shown on https://papelprensa.com/consultas.php (crawler 2026-10-10)'),
  ('eea07746-7316-40c8-8ea9-26d79b6294c2'::uuid, 'ppsa@papelprensa.com', 'General inbox', false,
   'Shown on https://papelprensa.com/consultas.php (crawler 2026-10-10)'),
  ('98ab4582-52eb-45af-aaa8-e212ff558c4b'::uuid, 'info@chandaria.com', 'General inbox', true,
   'Shown on https://chandaria.com/ (crawler 2026-10-10)'),
  ('e0687d63-e113-443f-892b-ba9c899481a7'::uuid, 'customercare@kimfay.com', 'Customer care inbox', true,
   'Shown on https://www.kimfay.com/ (crawler 2026-10-10)')
) as v(party_id, email, title_text, is_primary, notes)
where exists (select 1 from app.parties p where p.id = v.party_id and p.deleted_at is null)
  and not exists (
    select 1 from app.contacts c
    where c.party_id = v.party_id
      and lower(c.email) = lower(v.email)
      and c.deleted_at is null
  );

select p.party_name, p.website,
       (select string_agg(c.email, ', ') from app.contacts c
         where c.party_id = p.id and c.deleted_at is null and nullif(btrim(c.email), '') is not null) as emails
from app.parties p
where p.id in ('705b866d-bd5a-4432-93d1-4931a0b16cf7'::uuid, 'd1624c06-608e-4177-9370-cb922e80c3fb'::uuid,
               'b5574536-aaeb-4ba1-9f39-28c7ff009c07'::uuid, 'c8f84cce-1654-4f4d-a955-294f0ecfc58d'::uuid,
               '51ccf210-289f-46c3-829b-e0a6b0cc9b2f'::uuid, 'eea07746-7316-40c8-8ea9-26d79b6294c2'::uuid,
               '98ab4582-52eb-45af-aaa8-e212ff558c4b'::uuid, 'e0687d63-e113-443f-892b-ba9c899481a7'::uuid)
order by p.party_name;
