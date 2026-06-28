-- ============================================================
-- 20260627130000_global_am_investor_emails.sql
-- Verified contact emails for today's net-new global AM investors -> app.contacts + app.email_whitelist.
-- 7 firms with a PUBLIC/verified email (captured from each firm's OWN site, 2026-06-27).
-- 6 firms are FORM-ONLY (M Ventures, Holcim MAQER, Henkel Ventures, GC Ventures, Mitsui 321FORCE, Taiwania)
--   -> no email fabricated, intentionally omitted (submit via their pitch/inquiry form).
-- NOTE: 'Demeter' rebranded to 'Demea Sustainable Investment' (domain demea-si.com); party row not renamed here.
-- Idempotent (NOT EXISTS guards). Run as one txn in Supabase SQL Editor (clear the tab first, then paste).
-- ============================================================

begin;

-- 1) contacts (join to today's parties by name + source)
insert into app.contacts (organization_id, party_id, contact_type_id, email, full_name, source)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, p.id, v.contact_type_id, v.email, v.full_name, 'global_am_investors_2026Q3_email'
from app.parties p join (values
  ('European Circular Bioeconomy Fund (ECBF)', 'michael.brandkamp@ecbf.vc', 'Michael Brandkamp (Managing Partner)', 5::smallint),
  ('Amcor Ventures', 'frank.lehmann@amcor.com', 'Frank Lehmann (VP Corporate Venturing)', 5::smallint),
  ('Chrysalix Venture Capital', 'info@chrysalix.com', 'Chrysalix (general)', 1::smallint),
  ('Infinity Recycling', 'enquiries@infinity-recycling.com', 'Infinity Recycling (general)', 1::smallint),
  ('Capricorn Partners', 'capricorn@capricorn.be', 'Capricorn Partners (general)', 1::smallint),
  ('Demeter', 'contact@demea-si.com', 'Demea Sustainable Investment (ex Demeter) general', 1::smallint),
  ('Asahi Kasei Ventures', 'cvc@om.asahi-kasei.co.jp', 'Asahi Kasei Corporate VC', 1::smallint)
) as v(party_name, email, full_name, contact_type_id) on v.party_name=p.party_name
where p.source='global_am_investors_2026Q3' and p.party_type_id=1 and p.deleted_at is null
  and not exists (select 1 from app.contacts c where c.party_id=p.id and lower(c.email)=lower(v.email));

-- 2) email_whitelist (domains for independents, specific addresses where the corp domain is too broad)
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.pattern, v.kind, v.notes, true
from (values
  ('ecbf.vc', 'domain', 'ECBF (global AM investor)'),
  ('chrysalix.com', 'domain', 'Chrysalix Venture Capital (global AM investor)'),
  ('infinity-recycling.com', 'domain', 'Infinity Recycling (global AM investor)'),
  ('capricorn.be', 'domain', 'Capricorn Partners (global AM investor)'),
  ('demea-si.com', 'domain', 'Demea ex Demeter (global AM investor)'),
  ('frank.lehmann@amcor.com', 'address', 'Amcor Ventures VP Corp Venturing (amcor.com domain too broad to whitelist)'),
  ('cvc@om.asahi-kasei.co.jp', 'address', 'Asahi Kasei Corporate VC mailbox')
) as v(pattern, kind, notes)
where not exists (select 1 from app.email_whitelist w where w.organization_id='b25de8f2-1020-482f-9012-183f63883169'::uuid and lower(w.pattern)=lower(v.pattern));

commit;

-- ===================== VERIFY =====================
-- contacts added this batch (expect 7):
select p.party_name, c.email, c.contact_type_id
from app.contacts c join app.parties p on p.id=c.party_id
where c.source='global_am_investors_2026Q3_email' order by p.party_name;
-- whitelist entries for these patterns (expect 7):
select pattern, kind, is_active from app.email_whitelist
where pattern in ('ecbf.vc','chrysalix.com','infinity-recycling.com','capricorn.be','demea-si.com','frank.lehmann@amcor.com','cvc@om.asahi-kasei.co.jp')
order by kind, pattern;
