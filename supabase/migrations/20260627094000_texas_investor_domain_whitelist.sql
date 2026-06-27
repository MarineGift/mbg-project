-- ============================================================
-- 20260627094000_texas_investor_domain_whitelist.sql
-- Add the 24 Texas investor domains to app.email_whitelist (kind='domain').
-- Idempotent: NOT EXISTS guard on (organization_id, lower(pattern), kind). Safe to re-run.
-- Relies on id/created_at column defaults; run in Supabase SQL Editor (service role).
-- ============================================================

begin;

insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select v.organization_id, v.pattern, v.kind, v.notes, v.is_active from (values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'alaracap.com', 'domain', 'Texas investor: Alara Capital (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'aristosventures.com', 'domain', 'Texas investor: Aristos Ventures (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'coveraventures.com', 'domain', 'Texas investor: Covera Ventures (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'dallasventurepartners.com', 'domain', 'Texas investor: Dallas Venture Partners (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'daylightpartners.com', 'domain', 'Texas investor: Daylight Partners (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'liveoakvp.com', 'domain', 'Texas investor: Live Oak Venture Partners (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'mercuryfund.com', 'domain', 'Texas investor: Mercury Fund (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'nayaventures.com', 'domain', 'Texas investor: Naya Ventures (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'nextstepcapitalpartners.com', 'domain', 'Texas investor: Next Step Capital Partners (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 's3vc.com', 'domain', 'Texas investor: S3 Ventures (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'santeventures.com', 'domain', 'Texas investor: Santé Ventures (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'silvertonpartners.com', 'domain', 'Texas investor: Silverton Partners (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'trailblazercapital.com', 'domain', 'Texas investor: Trailblazer Capital (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'texoventures.com', 'domain', 'Texas investor: Texo Ventures (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'twvcapital.com', 'domain', 'Texas investor: Texas Women''s Ventures Capital Management (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'emergenttechnologies.com', 'domain', 'Texas investor: Emergent Technologies (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'aggieangelnetwork.com', 'domain', 'Texas investor: Aggie Angel Network (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'centraltexasangelnetwork.com', 'domain', 'Texas investor: Central Texas Angel Network (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'cowtownangels.org', 'domain', 'Texas investor: Cowtown Angels (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'dallasangelnetwork.com', 'domain', 'Texas investor: Dallas Angel Network (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'houstonangelnetwork.org', 'domain', 'Texas investor: Houston Angel Network (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'northtexasangels.org', 'domain', 'Texas investor: North Texas Angel Network (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'tylertexasangelnetwork.com', 'domain', 'Texas investor: Tyler Texas Angel Network (texas_startup_resources_2017)', true),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'wilcoangelnetwork.org', 'domain', 'Texas investor: Wilco Angel Network (texas_startup_resources_2017)', true)
) as v(organization_id, pattern, kind, notes, is_active)
where not exists (
  select 1 from app.email_whitelist w
  where w.organization_id = v.organization_id
    and lower(w.pattern) = v.pattern
    and w.kind = v.kind
);

commit;

-- ===================== VERIFY =====================
-- these 24 domains present as active 'domain' entries (expect 24):
select count(*) from app.email_whitelist
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid and kind='domain' and is_active = true and pattern in (
  'alaracap.com',
  'aristosventures.com',
  'coveraventures.com',
  'dallasventurepartners.com',
  'daylightpartners.com',
  'liveoakvp.com',
  'mercuryfund.com',
  'nayaventures.com',
  'nextstepcapitalpartners.com',
  's3vc.com',
  'santeventures.com',
  'silvertonpartners.com',
  'trailblazercapital.com',
  'texoventures.com',
  'twvcapital.com',
  'emergenttechnologies.com',
  'aggieangelnetwork.com',
  'centraltexasangelnetwork.com',
  'cowtownangels.org',
  'dallasangelnetwork.com',
  'houstonangelnetwork.org',
  'northtexasangels.org',
  'tylertexasangelnetwork.com',
  'wilcoangelnetwork.org'
);

-- list them:
select pattern, kind, is_active, notes from app.email_whitelist
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid and pattern in (
  'alaracap.com',
  'aristosventures.com',
  'coveraventures.com',
  'dallasventurepartners.com',
  'daylightpartners.com',
  'liveoakvp.com',
  'mercuryfund.com',
  'nayaventures.com',
  'nextstepcapitalpartners.com',
  's3vc.com',
  'santeventures.com',
  'silvertonpartners.com',
  'trailblazercapital.com',
  'texoventures.com',
  'twvcapital.com',
  'emergenttechnologies.com',
  'aggieangelnetwork.com',
  'centraltexasangelnetwork.com',
  'cowtownangels.org',
  'dallasangelnetwork.com',
  'houstonangelnetwork.org',
  'northtexasangels.org',
  'tylertexasangelnetwork.com',
  'wilcoangelnetwork.org'
) order by pattern;

-- ALT (if direct insert is blocked or id/created_at lack defaults): use the app RPC, e.g.
--   select app.add_email_whitelist('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'alaracap.com', 'domain', 'Texas investor: Alara Capital');
-- or just use Settings -> Email Whitelist -> 'Unregistered domains' bulk-add (these now surface automatically).
