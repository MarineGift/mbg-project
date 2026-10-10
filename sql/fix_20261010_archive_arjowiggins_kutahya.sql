-- ============================================================
-- fix_20261010_archive_arjowiggins.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Two rows archived (checked 2026-10-10):
-- A) Hamburger Kutahya (TR) - a planned mill that was never built.
--    Announced 2017 for 2020; EUWID (April 2024) reports Hamburger
--    Containerboard built the machine in Spremberg instead and expects no
--    further step at Kutahya before 2025. Archived without do_not_contact -
--    the operating Hamburger mills (Corlu, Denizli) stay as they are.
-- B) Arjowiggins (FR, Boulogne-Billancourt) - archived as defunct.
-- Checked 2026-10-10 (Wikipedia, Printweek, Fedrigoni releases):
--   * French group (Sequana) liquidated 2019; Arches mill already sold to
--     Munksjo in 2011 (now Ahlstrom).
--   * UK businesses (Stoneywood, Chartham) went into administration in
--     September 2022 - no buyer, mills offered for redevelopment.
--   * Guarro Casas (Spain) bought by Fedrigoni October 2022.
--   * Quzhou translucent-paper mill (China) bought by Fedrigoni December 2023.
-- So no operating Arjowiggins company remains: no new UK row is created.
-- The SMI "France - Arches" historical link stays on this row as history.
-- The last statement is READ-ONLY: lists any other URM rows for the former
-- Arjowiggins mills, so they can be re-pointed to Fedrigoni if present.
-- Idempotent.
-- ============================================================
update app.parties p
set status = 'archived',
    do_not_contact = true,
    do_not_contact_reason = coalesce(p.do_not_contact_reason, 'Defunct - Arjowiggins group dissolved (FR 2019, UK administration 2022); remaining mills sold to Fedrigoni'),
    do_not_contact_set_at = coalesce(p.do_not_contact_set_at, now()),
    updated_at = now()
where p.deleted_at is null
  and p.id = 'ddf55a91-53c8-4263-8b92-c3dc58335c81'::uuid
  and (p.status is distinct from 'archived' or p.do_not_contact is distinct from true);

update app.parties p
set status = 'archived',
    notes = coalesce(nullif(btrim(p.notes), '') || ' | ', '')
            || 'Planned mill, not built - EUWID April 2024: no step at Kutahya before 2025 (checked 2026-10-10)',
    updated_at = now()
where p.deleted_at is null
  and p.id = '1d4b565c-369a-476e-bd1a-cb31e3376c63'::uuid
  and p.status is distinct from 'archived';

select p.party_name, t.code as party_type, p.country_code, p.city, p.status,
       p.do_not_contact, p.website, p.id
from app.parties p
join app.party_types t on t.id = p.party_type_id
where p.deleted_at is null
  and (p.party_name ~* '(arjo|guarro|quzhou|stoneywood|chartham|arches|hamburger)'
       or p.id = 'ddf55a91-53c8-4263-8b92-c3dc58335c81'::uuid)
order by p.party_name;
