-- ============================================================
-- scan_fcc_campaign_triage_2026-07-16.sql
--
-- THE NUMBER, from block 5 of scan_entity_enrollment:
--
--     live FCC Licensing deals with a contact:      3
--     live FCC Licensing deals with NOBODY TO CALL: 148
--
-- The 148 break down as 40 Omya country entities, 43 Specialty Minerals country
-- entities and 65 Specialty Minerals plants. Among them:
--     Specialty Minerals (Korea)      - the DB records "No direct presence"
--     Specialty Minerals (Malaysia)   - the DB records "Theoretical only, no
--                                       Malaysia commercial entity"
--     Specialty Minerals (Global - PCC) - not a company, an abstraction
--
-- There are open FCC licensing deals against entities THIS DATABASE ITSELF
-- records as not existing.
--
-- And the 3 reachable ones are Omya (HQ), Omya (Korea) and Specialty Minerals
-- (HQ) - whose five contacts were ALL nameless this morning. Edgar Habich,
-- Jaehoon Cho, Sharad Mathur, Raina Wickkiser and Ken Mueller were given names
-- today. Before today the reachable pipeline was arguably zero.
--
-- Mississippi Lime, the only filler with real contact depth at 13 people, has NO
-- deal at all. The enrolment caught the Omya and SMI families and nothing else.
--
-- THE FRAMING THAT MATTERS: 148 of these are not deals. They are a TARGET LIST
-- wearing a pipeline's clothes. A deal with no contact, no activity since
-- creation, and no value_amount is a row that makes a dashboard number go up.
--
-- This scan does NOT delete anything. 148 deals is a business decision about
-- your own pipeline and it is not mine to make. It sorts them into buckets so
-- the decision is cheap.
--
-- READ-ONLY. Run each block SEPARATELY.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) THE BUCKETS ----------
select case
    when exists (select 1 from app.contacts c where c.party_id = p.id and c.deleted_at is null)
      then 'A_KEEP - reachable, a real deal'
    when coalesce(f.market_role,'') || ' ' || coalesce(f.supply_model,'') ~* 'no direct presence|theoretical|no .{0,12}commercial entity'
      then 'B_RETIRE - the DB says this entity does not exist'
    when p.party_name ~ ' - '
      then 'C_RETIRE - a plant or site row, never a licensing counterparty'
    when p.party_name ~* '\(Global'
      then 'D_RETIRE - an abstraction, not a legal entity'
    else 'E_DECIDE - a real country entity, but nobody to call yet'
  end as bucket,
  count(*) as live_deals
from app.deals d
join app.parties p on p.id = d.party_id
left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where d.deleted_at is null and p.deleted_at is null and p.party_type_id = 3
group by 1
order by 1;


-- ---------- 2) BUCKET B - deals against entities the DB says are not real ----------
select p.party_name, p.country_code, f.evidence_level, f.market_role, f.supply_model,
       d.deal_name, d.created_at::date
from app.deals d
join app.parties p on p.id = d.party_id
join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where d.deleted_at is null and p.deleted_at is null and p.party_type_id = 3
  and coalesce(f.market_role,'') || ' ' || coalesce(f.supply_model,'') ~* 'no direct presence|theoretical|no .{0,12}commercial entity'
order by p.party_name;


-- ---------- 3) BUCKET E - the honest backlog ----------
-- Country entities that plausibly exist and have no contact. These are NOT
-- phantoms - they are the real unworked list, and the reason the pipeline looks
-- full. The question is whether a target with nobody to call should be a DEAL or
-- just a target. Omya (USA) sits here at evidence A.
select p.party_name, p.country_code, f.evidence_level, f.supply_model, f.market_role,
       d.created_at::date, d.source as deal_source
from app.deals d
join app.parties p on p.id = d.party_id
left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where d.deleted_at is null and p.deleted_at is null and p.party_type_id = 3
  and not exists (select 1 from app.contacts c where c.party_id = p.id and c.deleted_at is null)
  and p.party_name !~ ' - '
  and p.party_name !~* '\(Global'
  and coalesce(f.market_role,'') || ' ' || coalesce(f.supply_model,'') !~* 'no direct presence|theoretical|no .{0,12}commercial entity'
order by f.evidence_level nulls last, p.party_name;


-- ---------- 4) WHO IS MISSING FROM THE CAMPAIGN ENTIRELY ----------
-- The enrolment caught Omya and Specialty Minerals and stopped. Every other
-- licensing target has no deal at all - including the ones researched today.
select p.party_name, p.country_code, f.evidence_level, f.market_role,
       (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as contacts
from app.parties p
left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.party_type_id = 3 and p.deleted_at is null
  and not exists (select 1 from app.deals d where d.party_id = p.id and d.deleted_at is null)
  and p.party_name !~ ' - '
  and p.party_name !~* '^(Omya|Specialty Minerals)'
order by f.evidence_level nulls last, p.party_name;
-- Expect Taekyung BK (satellite, evidence B), Taekyung Industrial, GMC, Zantat,
-- Okutama (90 percent-plus of Japanese paper PCC), Maruo, Imerys USA, Huber,
-- Imerys Korea, and Mississippi Lime with its 13 contacts.
-- The campaign has 151 deals and does not contain a single one of them.


-- ---------- 5) WHERE THE REAL FIX GOES - NOT v_email_do_not_send ----------
-- I proposed patching app.v_email_do_not_send to exclude generic inboxes. Having
-- now read the view in the repo, that was wrong and I withdraw it.
--
-- The view is a COLD-OUTREACH SUPPRESSION LIST, and its own header says so. Its
-- inputs are app.email_send_outcomes - bounce_hard, unsubscribe_request,
-- reply_positive, reply_neutral, rejected_*, next_action suppress or a
-- resend_later cooldown - plus app.application_forms at submitted or decided.
-- Every input is an EVENT. It answers "who has already responded, so stop cold
-- mailing them". It is keyed on email_lower and party_id, carries is_follow_up
-- and blocks_direct, and deliberately has no organization_id.
--
-- A generic inbox has no event. A duplicate party sharing an inbox has no event.
-- An entity with no contact has no event. None of them belong in a
-- suppression list, and bolting them on would break what the view means.
--
-- The 151 deals show where the defect actually is: ENROLMENT, not sending.
-- entity_enrollment stamped a deal onto every Omya and Specialty Minerals row it
-- could see - country shells, 65 plants, and three entities the DB says do not
-- exist. Nothing at send time can undo that, because the bad rows never reach
-- send time - they have no contact. They only inflate a number.
--
-- Send me the entity_enrollment source and I will read it rather than guess.
-- Likely candidates in the repo - grep for entity_enrollment under src/lib.
-- The guard it needs is a pre-enrolment one, roughly:
--   * skip party_name matching ' - '            (plants and sites)
--   * skip market_role saying the entity is theoretical or absent
--   * skip parties with zero live contacts, or enrol them to a TARGET list
--     rather than a deal pipeline
--   * dedupe by website host and country before creating anything
-- That last one is what would have stopped my Omya Korea duplicate, the two
-- Taekyung duplicates, and Specialty Minerals Inc. all at once.
