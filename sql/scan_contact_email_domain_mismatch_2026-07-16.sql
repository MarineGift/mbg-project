-- ============================================================
-- scan_contact_email_domain_mismatch_2026-07-16.sql
--
-- TWO PROBLEMS, both surfaced by block 6 of scan_bare_contacts.
--
-- PROBLEM 1 - CONTAMINATION. Saica Paper El Burgo de Ebro Zaragoza carried
-- info@burgogroup.com, an Italian competitor's inbox, because a string match saw
-- "Burgo" in a Spanish place name. If one row is contaminated this way, others
-- probably are. This scan compares each contact's email domain against its
-- party's own website domain - they should agree, and where they do not there is
-- either a legitimate reason (group inbox, parent company) or a bug.
--
-- PROBLEM 2 - DUPLICATE INBOXES. The same generic address is attached to many
-- sibling parties. info@sodra.com sits on 4 Sodra mills, info@nordic-paper.com
-- on 5, info@burgogroup.com on 4 real Burgo mills plus the contaminated Saica
-- row. If a sequence enrols all of them, ONE inbox receives 4 or 5 near-identical
-- cold emails in the same window. That is a textbook spam pattern - and this
-- project already has DKIM absent, DMARC at p=none and a PTR mismatch, so the
-- margin for looking like a bulk mailer is zero.
--
-- READ-ONLY. Run each block SEPARATELY.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) EMAIL DOMAIN vs PARTY WEBSITE DOMAIN ----------
-- Where they disagree, look. Group inboxes on subsidiary parties are normal and
-- will show up here too - the point is a review list, not a verdict.
select p.party_name, p.party_type_id, p.country_code,
       split_part(c.email, '@', 2) as email_domain,
       lower(regexp_replace(regexp_replace(regexp_replace(coalesce(p.website,''), '^https?://', ''), '^www\.', ''), '/.*$', '')) as site_domain,
       c.email, c.source
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null and p.deleted_at is null
  and c.email is not null and coalesce(p.website,'') <> ''
  and position(
        split_part(lower(regexp_replace(regexp_replace(regexp_replace(p.website, '^https?://', ''), '^www\.', ''), '/.*$', '')), '.', 1)
        in lower(split_part(c.email, '@', 2))
      ) = 0
order by p.party_type_id, p.party_name
limit 80;


-- ---------- 2) ONE INBOX, MANY PARTIES - the send-volume risk ----------
select c.email,
       count(distinct p.id) as parties_sharing_it,
       string_agg(distinct p.party_name, ' | ' order by p.party_name) as parties
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null and p.deleted_at is null and c.email is not null
group by 1
having count(distinct p.id) > 1
order by count(distinct p.id) desc, 1;


-- ---------- 3) THE SAME THING, but only where it would actually send ----------
-- Enrolled in a live sequence AND sharing an inbox with another enrolled party.
-- This is the block that matters operationally. If it returns rows, a real
-- sequence is about to hit one inbox several times.
select c.email,
       count(distinct e.party_id) as enrolled_parties_sharing_inbox,
       string_agg(distinct p.party_name, ' | ' order by p.party_name) as parties
from app.email_sequence_enrollments e
join app.parties p  on p.id = e.party_id and p.deleted_at is null
join app.contacts c on c.party_id = p.id and c.deleted_at is null and c.email is not null
group by 1
having count(distinct e.party_id) > 1
order by count(distinct e.party_id) desc;
-- If app.email_sequence_enrollments has no party_id column this errors - tell me
-- the shape and I will redo it. It is the last block, so blocks 1-2 still ran.


-- ---------- 4) GENERIC ADDRESSES ON HIGH-VALUE ROWS ----------
-- A generic inbox on a filler_supplier is worth knowing about - those are the
-- licensing targets. Omya (HQ) and Omya (Korea) both showed up nameless.
select p.party_name, p.country_code, f.evidence_level, f.market_role,
       c.email, c.full_name, c.title_text
from app.contacts c
join app.parties p on p.id = c.party_id
left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where c.deleted_at is null and p.deleted_at is null
  and p.party_type_id = 3 and c.email is not null
order by f.evidence_level nulls last, p.party_name;


-- ---------- 5) WHAT ELSE DID THE STRING MATCHER TOUCH ----------
-- The Saica bug came from a substring of a PLACE name matching a COMPANY name.
-- Any party whose name contains a token that is also another party's brand is a
-- candidate. This is deliberately crude - eyeball it.
select p.party_name, p.country_code, p.website, c.email
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null and p.deleted_at is null and c.email is not null
  and (p.party_name ~* 'burgo|palm|jass|crown|century|progroup|waraq'
       or split_part(c.email,'@',2) ~* 'burgo|palm|jass|crown|century|progroup|waraq')
order by split_part(c.email,'@',2), p.party_name;
