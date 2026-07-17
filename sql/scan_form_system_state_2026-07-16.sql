-- ============================================================
-- scan_form_system_state_2026-07-16.sql
--
-- The form machinery already exists and is already generalised. Migration 027
-- says so in its own header - it took the investor-only application system and
-- opened it to "any party that communicates via a web form (mills included)".
-- I nearly wrote a migration_028 to add things that shipped weeks ago. That
-- would have been the fourth time today I assumed "I do not know it" means "it
-- does not exist".
--
-- WHAT IS ALREADY BUILT
--   parties.contact_form_url + preferred_contact_method   - badge reads these two
--   application_forms.form_type = 'contact_inquiry'       - reuses 025/026 whole
--   answer_library.variant (short/medium/long) + target_length
--                                                          - one key, many lengths,
--                                                            picked against max_length
--   application_form_fields.canonical_key                  - maps each form question
--                                                            onto a standard catalog
--                                                            so HUNDREDS of forms
--                                                            share ONE answer library
--   v_application_field_status                             - the working view
--
-- So filler suppliers need DATA, not schema. And the "hundreds of forms" that
-- 027 was designed for is exactly the 176 filler companies that have a website
-- form and no email address.
--
-- WHY THIS MATTERS TODAY: 4 of 176 filler companies have a contact. Nearly all
-- of them have an inquiry form. The form IS the contact channel - it needs no
-- address, it is invited contact rather than cold email, and it is immune to the
-- DKIM/DMARC/PTR problems. app.v_email_do_not_send already reads
-- application_forms, so a submitted form suppresses cold outreach on that party
-- automatically. The wiring is done.
--
-- This scan reads the current state so the seed can be written against facts.
--
-- READ-ONLY. Run each block SEPARATELY.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) WHAT FORMS EXIST, BY TYPE AND PARTY TYPE ----------
select f.form_type, p.party_type_id, f.submission_method, f.status,
       count(*) as forms,
       count(distinct f.party_id) as parties
from app.application_forms f
join app.parties p on p.id = f.party_id
group by 1,2,3,4
order by 1,2,3,4;


-- ---------- 2) THE ANSWER LIBRARY AS IT STANDS ----------
-- Keys, variants, disclosure levels, tags, and body lengths. The seed for filler
-- answers must not collide with these keys, and should reuse any that are
-- genuinely audience-neutral.
select a.answer_key, a.variant, a.target_length, a.disclosure_level, a.tags,
       a.title,
       length(a.body_en) as en_chars,
       length(a.body_ko) as ko_chars
from app.answer_library a
order by a.answer_key, a.variant nulls first;


-- ---------- 3) THE CANONICAL QUESTION CATALOG IN USE ----------
-- canonical_key is the whole point of 027 - it lets one answer serve every form
-- that asks the same thing. This shows which standard questions already exist
-- and how many form fields map onto each.
select ff.canonical_key,
       count(*) as fields_using_it,
       count(distinct ff.form_id) as forms,
       min(ff.max_length) as min_max_length,
       max(ff.max_length) as max_max_length,
       string_agg(distinct ff.field_type, ', ') as field_types
from app.application_form_fields ff
group by 1
order by count(*) desc nulls last;


-- ---------- 4) HOW MANY PARTIES ARE MARKED AS FORM-BASED ----------
select p.party_type_id,
       count(*) as parties,
       count(*) filter (where p.contact_form_url is not null) as have_form_url,
       count(*) filter (where p.preferred_contact_method is not null) as have_pref_method,
       count(*) filter (where exists (select 1 from app.contacts c
                                      where c.party_id = p.id and c.deleted_at is null)) as have_a_contact
from app.parties p
where p.deleted_at is null
group by 1
order by 1;


-- ---------- 5) THE FILLER GAP - the list this whole exercise is for ----------
-- Every filler company with no contact. Each one needs contact_form_url filled
-- and a contact_inquiry form built. ADVERSE PARTIES ARE EXCLUDED - see block 6.
select p.id, p.party_name, p.country_code, p.website, p.contact_form_url,
       p.preferred_contact_method, f.evidence_level, f.market_role
from app.parties p
join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.party_type_id = 3 and p.deleted_at is null
  and p.party_name !~ ' - '
  and p.party_name !~* '\(Global'
  and not exists (select 1 from app.contacts c where c.party_id = p.id and c.deleted_at is null)
  and coalesce(f.extra_data #>> '{adverse_party,status}','') <> 'DO NOT CONTACT'
  and coalesce(f.extra_data #>> '{fcc_fit,verdict}','') not in ('no','adverse - not a target')
  and coalesce(f.market_role,'') || ' ' || coalesce(f.supply_model,'')
        !~* 'no direct presence|theoretical|no .{0,12}commercial entity|holding company'
order by f.evidence_level nulls last, p.party_name;


-- ---------- 6) THE GATE THIS SYSTEM DOES NOT HAVE YET ----------
-- A web form is contact, and contact to an adversary is disclosure. Taekyung
-- Industrial co-filed EP4579034 with Kleannara on flexible calcium carbonate.
-- Submitting a technical description of FCC into their inquiry form would be a
-- voluntary written disclosure to a litigation opponent, on their own record,
-- timestamped. That is worse than a cold email - a form submission is
-- deliberate, attributable and archived by the recipient.
--
-- The investor library already learned the softer half of this lesson.
-- 20260714170000_scan_nda_sensitive_answers.sql hunts for text that leaks into
-- a public form: the affiliate name holding the KR patents, the 500,000 USD
-- deferred consideration, counterparty approval status, a named counterparty
-- tied to a 9,000-ton contract.
--
-- BUT THE FILLER AUDIENCE IS NOT THE INVESTOR AUDIENCE. An investor reading the
-- pitch is a potential funder. A FILLER SUPPLIER READING IT IS A POTENTIAL
-- LICENSEE AND A POTENTIAL INFRINGER - Taekyung is literally both. So the filler
-- answer set must be stricter than the investor one, not merely as strict:
--   * disclosure_level public ONLY - nda_only answers must never bind to a
--     contact_inquiry field
--   * no process parameters, no formulations, no mill names under contract
--   * no royalty figures, no round terms
--   * capability and outcome only - what it does for the mill, not how
--   * an explicit NDA ask as the close, so the real conversation happens under
--     an agreement rather than in a web form
--
-- This block finds any adverse or excluded party that already carries a form URL
-- or a form row - i.e. anything already primed to send.
select p.party_name, p.party_type_id, p.contact_form_url,
       f.extra_data #>> '{adverse_party,status}' as adverse,
       (select count(*) from app.application_forms af where af.party_id = p.id) as form_rows
from app.parties p
left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.deleted_at is null
  and (coalesce(f.extra_data #>> '{adverse_party,status}','') = 'DO NOT CONTACT'
       or p.party_name ~* 'kleannara|깨끗한나라|대한펄프|taekyung|태경')
order by p.party_name;
-- Anything here with a contact_form_url or a form row is a live disclosure risk.
