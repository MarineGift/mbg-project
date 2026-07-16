-- ============================================================
-- scan_bare_contacts_2026-07-16.sql
--
-- WHAT THE 2026-07-16 15:20 AND 15:21 RUNS SHOWED:
--   * Specialty Minerals (HQ) had 3 bare contacts at 15:20 and ZERO at 15:21.
--     enrich_smi_contacts landed. Sharad Mathur now has a name.
--   * The list was cut at Limit 100 and every single row had exactly 1 bare
--     contact. 98 of the 100 were paper mills. The other 2 were fillers -
--     Omya (HQ) and OMYA (KOREA).
--
-- Omya (Korea) is the number 1 KR FCC licensing target - confirmed by KFTC
-- decision 2019-109 and by GMC's own "foreign firms hold about 80 percent"
-- statement. Its ONLY contact is a nameless email address. It has been sitting
-- in the CRM unusable, exactly like Sharad Mathur was.
--
-- The real total is unknown because the editor capped the result at 100.
--
-- WHY IT MATTERS BEYOND TIDINESS: this project runs email sequences. A contact
-- with no full_name cannot be personalised, so a bare row is not merely untidy,
-- it is unusable by the sequence pipeline. It is in the database and absent from
-- the business at the same time.
--
-- READ-ONLY. Nothing is written. Run each block SEPARATELY - the editor aborts
-- the whole file on the first error and only shows the last statement's result.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) THE TRUE TOTAL - no row cap ----------
select p.party_type_id,
       count(*) as bare_contacts,
       count(distinct p.id) as parties_affected
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null and p.deleted_at is null
  and c.full_name is null and c.email is not null
group by 1
order by 1;


-- ---------- 2) WHERE DID THEY COME FROM ----------
select coalesce(c.source, '(null)') as contact_source,
       count(*) as bare_contacts,
       min(c.created_at)::date as first_seen,
       max(c.created_at)::date as last_seen
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null and p.deleted_at is null
  and c.full_name is null and c.email is not null
group by 1
order by count(*) desc;


-- ---------- 3) CAN THE NAME BE DERIVED FROM THE ADDRESS ----------
-- sharad.mathur@mineralstech.com -> Sharad Mathur, mechanically, no research.
-- info@ cannot and must not be given a person's name.
select case
         when split_part(c.email,'@',1) ~ '^[a-z]{2,}\.[a-z]{2,}$'  then '1_first.last - derivable'
         when split_part(c.email,'@',1) ~ '^[a-z]{2,}_[a-z]{2,}$'   then '2_first_last - derivable'
         when split_part(c.email,'@',1) ~ '^(info|sales|contact|enquiry|enquiries|inquiry|inquiries|office|mail|admin|general|support|hello|kontakt|kundservice|marketing|press|media|communications)$'
                                                                     then '3_generic inbox - never name a person'
         else '4_other - manual review'
       end as pattern,
       count(*) as rows
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null and p.deleted_at is null
  and c.full_name is null and c.email is not null
group by 1
order by 1;


-- ---------- 4) THE TWO FILLER ROWS - highest priority ----------
-- Omya (Korea) is the KR number 1 target. Show me the actual address.
select p.id as party_id, p.party_name, p.country_code,
       c.id as contact_id, c.email, c.contact_type_id, c.source,
       c.is_primary, c.is_decision_maker, c.created_at::date
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null and p.deleted_at is null
  and c.full_name is null and c.email is not null
  and p.party_type_id = 3
order by p.party_name;


-- ---------- 5) DERIVATION PREVIEW - what a bulk fix WOULD write ----------
-- Nothing is written. This is the eyeball check before I write any UPDATE.
-- If this column looks right, send it back and I will turn it into a fix file.
select p.party_name,
       c.email,
       initcap(replace(split_part(c.email,'@',1), '.', ' '))            as would_set_full_name,
       initcap(split_part(split_part(c.email,'@',1), '.', 1))           as would_set_given_name,
       initcap(split_part(split_part(c.email,'@',1), '.', 2))           as would_set_family_name
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null and p.deleted_at is null
  and c.full_name is null and c.email is not null
  and split_part(c.email,'@',1) ~ '^[a-z]{2,}\.[a-z]{2,}$'
order by p.party_name
limit 60;
-- KNOWN IMPERFECTIONS of initcap - mcdonald becomes Mcdonald not McDonald,
-- oconnor becomes Oconnor. Compound surnames like van.der.berg do not match the
-- regex at all and fall to block 3 category 4. Accepting Mcdonald is better than
-- leaving the row unusable, but tell me if you would rather not.


-- ---------- 6) THE GENERIC ONES - a different fix ----------
-- These should get a label, not a person's name. Something like
-- 'General inbox' in full_name, or contact_type_id set to a general type,
-- so the sequence pipeline can skip them instead of mailing "Dear null".
select p.party_name, p.party_type_id, c.email, c.contact_type_id
from app.contacts c
join app.parties p on p.id = c.party_id
where c.deleted_at is null and p.deleted_at is null
  and c.full_name is null and c.email is not null
  and split_part(c.email,'@',1) ~ '^(info|sales|contact|enquiry|enquiries|inquiry|inquiries|office|mail|admin|general|support|hello|kontakt|kundservice|marketing|press|media|communications)$'
order by p.party_type_id, p.party_name
limit 60;
