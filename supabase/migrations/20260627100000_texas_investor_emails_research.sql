-- ============================================================
-- 20260627100000_texas_investor_emails_research.sql
-- VERIFIED contact emails for Texas investors (deep-research 2026-06-27).
-- Superset of 20260627095000 (re-runs are harmless: NOT EXISTS guards). Safe to re-run.
-- Only emails published on the firm's OWN site / authoritative directory are loaded.
-- EXCLUDED (form-only / defunct / unverified): S3 Ventures, Sante Ventures, Texo Ventures,
--   Covera Ventures, Trailblazer Capital, Cowtown Angels, Wilco Angel Network, Emergent Technologies,
--   Dallas Angel Network, Tyler Texas Angel Network, Alara Capital (closed), Next Step Capital (domain for sale).
-- Address-only whitelist (shared/mismatched domains): blakepetty@tamu.edu, info@dallasvc.com.
-- ============================================================

begin;

-- 1) contacts (party_id resolved by name; contact_type_id=1 default)
insert into app.contacts (organization_id, party_id, contact_type_id, email, full_name, source)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, p.id, 1, v.email, v.full_name, 'texas_investor_email_research_2026Q3'
from (values
  ('Central Texas Angel Network', 'director@ctan.com', 'CTAN funding/director inbox'),
  ('Houston Angel Network', 'samia@houstonangelnetwork.org', 'Samia Ahsan (Managing Director)'),
  ('Aggie Angel Network', 'blakepetty@tamu.edu', 'Blake Petty (Executive Director)'),
  ('Aristos Ventures', 'info@aristosventures.com', 'Aristos Ventures (general inbox)'),
  ('Dallas Venture Partners', 'info@dallasventurepartners.com', 'Dallas Venture Partners (general inbox)'),
  ('Daylight Partners', 'info@daylightpartners.com', 'Daylight Partners (general inbox)'),
  ('Live Oak Venture Partners', 'info@liveoakvp.com', 'Live Oak Venture Partners (general inbox)'),
  ('Mercury Fund', 'info@mercuryfund.com', 'Mercury Fund (general inbox)'),
  ('Naya Ventures', 'info@dallasvc.com', 'Dallas Venture Capital / Naya (general inbox)'),
  ('Silverton Partners', 'businessplans@silvertonpartners.com', 'Silverton Partners (deal submissions)'),
  ('Silverton Partners', 'press@silvertonpartners.com', 'Silverton Partners (press)'),
  ('Texas Women''s Ventures Capital Management', 'info@twvcapital.com', 'TWV Capital (general inbox)'),
  ('North Texas Angel Network', 'info@northtexasangels.org', 'North Texas Angel Network (general inbox)'),
  ('North Texas Angel Network', 'jeff@northtexasangels.org', 'Jeff Murphy (Executive Director)')
) as v(party_name, email, full_name)
join app.parties p on p.party_name = v.party_name and p.deleted_at is null
where not exists (
  select 1 from app.contacts c
  where c.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid and lower(c.email) = v.email and c.deleted_at is null
);

-- 2) whitelist: address entries for all loaded emails + ctan.com domain (idempotent)
--    tamu.edu and dallasvc.com are intentionally address-only (do NOT whitelist those domains).
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.pattern, v.kind, 'Texas investor email (research 2026Q3)', true from (values
  ('director@ctan.com', 'address'),
  ('samia@houstonangelnetwork.org', 'address'),
  ('blakepetty@tamu.edu', 'address'),
  ('info@aristosventures.com', 'address'),
  ('info@dallasventurepartners.com', 'address'),
  ('info@daylightpartners.com', 'address'),
  ('info@liveoakvp.com', 'address'),
  ('info@mercuryfund.com', 'address'),
  ('info@dallasvc.com', 'address'),
  ('businessplans@silvertonpartners.com', 'address'),
  ('press@silvertonpartners.com', 'address'),
  ('info@twvcapital.com', 'address'),
  ('info@northtexasangels.org', 'address'),
  ('jeff@northtexasangels.org', 'address'),
  ('ctan.com', 'domain')
) as v(pattern, kind)
where not exists (
  select 1 from app.email_whitelist w
  where w.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid and lower(w.pattern) = v.pattern and w.kind = v.kind
);

commit;

-- ===================== VERIFY =====================
-- contacts loaded by this research source (expect 14):
select p.party_name, c.email, c.full_name
from app.contacts c join app.parties p on p.id = c.party_id
where c.source = 'texas_investor_email_research_2026Q3' order by p.party_name, c.email;

-- any firm name that did NOT match a party (would mean 0 inserted for it; should be empty):
select distinct v.party_name from (values
  ('Central Texas Angel Network'),
  ('Houston Angel Network'),
  ('Aggie Angel Network'),
  ('Aristos Ventures'),
  ('Dallas Venture Partners'),
  ('Daylight Partners'),
  ('Live Oak Venture Partners'),
  ('Mercury Fund'),
  ('Naya Ventures'),
  ('Silverton Partners'),
  ('Texas Women''s Ventures Capital Management'),
  ('North Texas Angel Network')
) v(party_name)
where not exists (select 1 from app.parties p where p.party_name=v.party_name and p.deleted_at is null);

-- ---------------------------------------------------------------
-- MANUAL-VERIFICATION QUEUE (NOT executed). Uncomment a row only after
-- you confirm the address as a live mailto on the firm's own website.
-- Dallas Angel Network        angels@dallasangelnetwork.com   (Crunchbase only)
-- Covera Ventures             chris@coveraventures.com        (Crunchbase only)
-- Tyler Texas Angel Network   wmohl@suddenlink.net            (directory; personal ISP domain)
-- Emergent Technologies       (no general inbox confirmed)
