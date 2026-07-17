-- ============================================================
-- fix_answer_library_filler_gate_2026-07-17.sql
--
-- WHY: 72 of 79 answers are disclosure_level = 'public'. The schema says
--   disclosure_level text NOT NULL DEFAULT 'public'
-- so 'public' is not a judgement, it is the ABSENCE of one. Seven people decided
-- something was nda_only. The other 72 inherited a default. If a filler
-- contact_inquiry form binds on disclosure_level = 'public', all 72 are eligible.
--
-- THREE OF THEM VIOLATE THIS PROJECT'S OWN STATED RULE.
-- sql/20260714170000_scan_nda_sensitive_answers.sql defines the markers:
--     'Marinepad' / '500,000 USD' / 'executive approval' / '9,000-ton' + payee
--     "any one is a red flag for a public form"
--
--   ip_portfolio      [public] contains 'Marinepad' AND '500,000 USD'
--   business_model    [short, public] contains '9,000-ton' AND 'executive approval'
--   royalty_economics [public] states the royalty rate and the per-ton figure
--
-- ip_portfolio is the worst. Read as a whole it is a map of every weakness in the
-- IP position: only ONE asset actually owned, the assignment consideration
-- unpaid, the 500,000 USD obligation unfunded, five granted patents sitting with
-- a separate affiliate and enforceable in Korea only, no licence ever executed -
-- and it names the third-party submissions filed against a competitor patent
-- family. That last item is the Taekyung/Kleannara action. Handing this to a
-- filler supplier during a live dispute over flexible calcium carbonate would be
-- severe, and disclosure_level = 'public' is the only thing standing between it
-- and a web form.
--
-- WHAT THIS FILE DOES NOT DO: it does not change disclosure_level. That column
-- governs investor diligence, where IP ownership disclosure is normal and
-- expected. The problem is not that the answer exists - it is that ONE LABEL IS
-- SERVING TWO AUDIENCES. An investor is a funder. A filler supplier is a
-- potential licensee AND a potential infringer, and Taekyung is literally both.
--
-- THE FIX IS A SECOND AXIS, carried in tags, needing no migration:
--     contact_inquiry binding rule:
--         disclosure_level = 'public'  AND  tags @> ARRAY['filler_safe']
--     No tag, no bind. DENY BY DEFAULT.
--
-- Deny-by-default is not paranoia here. EVERY failure found in this session was
-- silent: the null guard that skipped an update, the three-column insert that
-- passed, the regex that would have invented fourteen people, entity_enrollment
-- stamping deals onto rows the database itself calls non-existent, a Spanish
-- mill carrying an Italian competitor's live inbox. A form that silently binds
-- ip_portfolio is the same shape - except the damage lands in a competitor's
-- archive and no soft delete reaches it.
--
-- filler_safe today = 0. That is the correct starting point. Every answer earns
-- the tag deliberately or never gets it.
--
-- IDEMPOTENT. Tags only. NOTHING IS DELETED. answer_library has no notes column,
-- so the signal lives in tags where the binding query can actually read it.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 0) PRE-FLIGHT (run separately) ----------
-- select answer_key, variant, disclosure_level, tags
-- from app.answer_library
-- where answer_key in ('ip_portfolio','business_model','royalty_economics')
-- order by answer_key, variant;


-- ---------- 1) HARD BLOCK the three that break the project's own rule ----------
-- 'never_filler_form' is belt-and-braces. Deny-by-default already excludes them,
-- but a human reading the library should see the verdict without re-deriving it.
update app.answer_library a
set tags = (select array_agg(distinct t) from unnest(a.tags || ARRAY['never_filler_form']) t),
    updated_at = now()
where a.answer_key in ('ip_portfolio','business_model','royalty_economics')
  and not (a.tags @> ARRAY['never_filler_form']);


-- ---------- 2) FLAG FOR REVIEW - read before deciding ----------
-- I have only seen the opening 120 characters of these. They carry risk markers
-- but I will not rule on text I have not read. Same rule that stopped the bulk
-- name derivation from inventing fourteen people yesterday.
update app.answer_library a
set tags = (select array_agg(distinct t) from unnest(a.tags || ARRAY['filler_review_needed']) t),
    updated_at = now()
where a.disclosure_level = 'public'
  and coalesce(a.body_en,'') ~* 'royalt|per ton|USD per|patent|application US|Omya|Imerys|Specialty Minerals|Minerals Technologies|Moorim|Marinepad|FiberLean|FulFill|granted|9,000|500,000|executive approval|NET certificate'
  and not (a.tags @> ARRAY['never_filler_form'])
  and not (a.tags @> ARRAY['filler_review_needed']);


-- ---------- 3) THE WORKSHEET ----------
-- Everything public, worst first. Work down the list and tag filler_safe by hand.
-- select a.answer_key, a.variant, a.target_length, a.tags, a.title,
--        length(a.body_en) as en_len, a.body_en
-- from app.answer_library a
-- where a.disclosure_level = 'public'
--   and not (a.tags @> ARRAY['never_filler_form'])
-- order by (a.tags @> ARRAY['filler_review_needed']) desc, a.answer_key, a.variant;
--
-- To clear one:
--   update app.answer_library
--   set tags = (select array_agg(distinct t) from unnest(tags || ARRAY['filler_safe']) t),
--       updated_at = now()
--   where answer_key = 'company_one_liner' and variant = 'medium';
--
-- Likely to clear: company_legal_name, brand_name, company_one_liner,
-- category_positioning. All are audience-neutral facts about who you are.
-- company_one_liner [medium] reads "Marinebio Group makes FCC, a calcium
-- carbonate filler grown in-situ on pulp fibers, letting paper mills replace
-- costly pulp with low-cost filler without losing sheet strength. Patented, in
-- market." - 196 chars, capability and outcome, no how, no numbers, no names.
-- That is exactly the register a filler inquiry form should use.


-- ---------- 4) VERIFY ----------
-- select count(*) filter (where tags @> ARRAY['never_filler_form'])     as hard_blocked,
--        count(*) filter (where tags @> ARRAY['filler_review_needed'])  as needs_review,
--        count(*) filter (where tags @> ARRAY['filler_safe'])           as cleared,
--        count(*) filter (where disclosure_level = 'public')            as public_total
-- from app.answer_library;
-- cleared stays 0 until you clear them one at a time. That is the point.


-- ---------- 5) SEPARATE QUESTION, NOT DECIDED HERE ----------
-- Should ip_portfolio be nda_only rather than public? The project's own scan file
-- says '500,000 USD' and 'Marinepad' are red flags for a public form, and this
-- answer contains both. By that rule it is already mislabelled.
--
-- Against changing it: investor diligence legitimately requires IP ownership
-- disclosure, and if an investor form is currently bound to this answer, flipping
-- it to nda_only may silently empty a field that is mid-drafting. Four investor
-- forms are in 'drafting' and two are 'submitted'.
--
-- Check what would break before deciding:
--   select f.party_id, p.party_name, af.status, ff.label, fa.final_text is not null as has_text
--   from app.application_field_answers fa
--   join app.application_form_fields ff on ff.id = fa.field_id
--   join app.application_forms af on af.id = ff.form_id
--   join app.parties p on p.id = af.party_id
--   join app.answer_library al on al.id = fa.answer_id
--   left join app.application_forms f on f.id = af.id
--   where al.answer_key in ('ip_portfolio','business_model','royalty_economics');
--
-- If nothing is bound, nda_only costs nothing and closes a real hole. If
-- something is bound, decide with the form in front of you rather than in the
-- dark. I am not making this call for you - it is your disclosure posture, and
-- the two submitted forms are already out.
