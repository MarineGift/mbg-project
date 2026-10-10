-- ============================================================
-- fix_20261010_archive_defunct_mills.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- 1) Archive paper mill rows for companies or mills that no longer exist, so
--    they stop showing as e-mail research targets and are never mailed:
--      PICOP Resources (closed 2010)
--      Stora Enso Veitsiluoto Kemi (closed 2021)
--      Consolidated Papers (absorbed by Stora Enso / NewPage, name retired)
--      NewPage (merged into Verso 2015, Verso acquired by Billerud 2022)
--    status = archived, do_not_contact = true with a reason. Nothing deleted.
-- 2) Ledesma: fill the empty website with the official site (checked
--    2026-10-10). Its contact page is a form, no published e-mail.
-- Idempotent. Last statement is a verification select.
-- ============================================================
update app.parties p
set status = 'archived',
    do_not_contact = true,
    do_not_contact_reason = coalesce(p.do_not_contact_reason, 'Defunct - company or mill no longer operating'),
    do_not_contact_set_at = coalesce(p.do_not_contact_set_at, now()),
    updated_at = now()
where p.deleted_at is null
  and p.id in ('a160c9bd-473c-40c5-9fc4-74f85e7db167'::uuid,
               '1dd27154-7f00-4f85-aa94-dddc30a785df'::uuid,
               '471e45e3-b982-4704-a436-49867c91aa93'::uuid,
               'd753532b-cf22-4670-a83b-6311fe8d18f7'::uuid)
  and (p.status is distinct from 'archived' or p.do_not_contact is distinct from true);

update app.parties p
set website = 'https://www.ledesma.com.ar',
    updated_at = now()
where p.deleted_at is null
  and p.id = '7b8b830e-2959-4298-a758-c8a859d0933c'::uuid
  and nullif(btrim(p.website), '') is null;

select p.party_name, p.status, p.do_not_contact, p.do_not_contact_reason, p.website
from app.parties p
where p.id in ('a160c9bd-473c-40c5-9fc4-74f85e7db167'::uuid,
               '1dd27154-7f00-4f85-aa94-dddc30a785df'::uuid,
               '471e45e3-b982-4704-a436-49867c91aa93'::uuid,
               'd753532b-cf22-4670-a83b-6311fe8d18f7'::uuid,
               '7b8b830e-2959-4298-a758-c8a859d0933c'::uuid)
order by p.party_name;
