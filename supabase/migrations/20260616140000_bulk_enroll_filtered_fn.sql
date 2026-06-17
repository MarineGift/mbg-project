-- ============================================================
-- 20260616140000_bulk_enroll_filtered_fn.sql
-- Create public.bulk_enroll_filtered(...) used by the Bulk Enroll
-- dialog. The app already calls rpc('bulk_enroll_filtered', ...) but
-- the function did not exist in the DB (verified 2026-06-16), so the
-- bulk-enroll feature was non-functional. This creates it, and adds a
-- NEW p_priority filter (investor_profile.priority: high|medium|low).
--
-- Design: resolve matching (party, contact) candidates, dedup against
-- existing active/completed enrollments, skip parties with no email,
-- and for a real run delegate the actual insert to the proven
-- public.enroll_in_sequence(...) - one call per eligible party.
--
-- Filters implemented: p_module (party_types.code), p_status
-- (parties.status), p_country_code, p_name_contains, p_priority.
-- p_tiers / p_industry_tag are accepted for call-signature
-- compatibility but NOT applied in this version (the dialog's tier
-- values tier_1..cold do not map to app.account_scores.tier A/B/C;
-- wire later once the tier source is reconciled).
--
-- Schema note: created in PUBLIC schema because the app's rpc()
-- helper resolves functions in the PostgREST-exposed schema (public),
-- same as enroll_in_sequence. App tables live in app.* (qualified).
--
-- Safety: SECURITY INVOKER (default) so RLS scopes reads to the
-- caller's org; every query also filters organization_id explicitly.
-- Preview first (p_dry_run = true) - the dialog always previews.
-- ============================================================

create or replace function public.bulk_enroll_filtered(
  p_organization_id uuid,
  p_sequence_id     uuid,
  p_module          text    default null,
  p_tiers           text[]  default null,   -- accepted; not applied (see note)
  p_status          text    default null,
  p_country_code    text    default null,
  p_industry_tag    text    default null,   -- accepted; not applied (see note)
  p_name_contains   text    default null,
  p_priority        text[]  default null,   -- NEW: investor priority high|medium|low (multi)
  p_enrolled_by     uuid    default null,
  p_dry_run         boolean default true
)
returns table (
  total_matching           integer,
  enrolled_count           integer,
  skipped_already_enrolled integer,
  skipped_no_email         integer,
  sample_names             text[]
)
language plpgsql
as $fn$
declare
  v_total    integer := 0;
  v_enrolled integer := 0;
  v_skip_enr integer := 0;
  v_skip_eml integer := 0;
  v_samples  text[]  := '{}';
  r          record;
  v_contact  uuid;
  v_already  boolean;
begin
  for r in
    select p.id, p.party_name
    from app.parties p
    join app.party_types pt on pt.id = p.party_type_id
    left join app.investor_profile ip on ip.party_id = p.id
    where p.organization_id = p_organization_id
      and p.deleted_at is null
      and (p_module        is null or pt.code = p_module)
      and (p_status        is null or p.status = p_status)
      and (p_country_code  is null or upper(p.country_code) = upper(p_country_code))
      and (p_name_contains is null or p.party_name ilike '%' || p_name_contains || '%')
      and (p_priority      is null or ip.priority = any(p_priority))
    order by p.party_name
  loop
    v_total := v_total + 1;

    -- Already enrolled in this sequence? (re-enroll allowed if cancelled/failed)
    select exists (
      select 1
      from app.email_sequence_enrollments e
      where e.sequence_id = p_sequence_id
        and e.party_id    = r.id
        and e.status in ('active', 'completed')
    ) into v_already;

    if v_already then
      v_skip_enr := v_skip_enr + 1;
      continue;
    end if;

    -- Pick one contact with an email (primary first, then oldest)
    select c.id
    into v_contact
    from app.contacts c
    where c.party_id        = r.id
      and c.organization_id = p_organization_id
      and c.deleted_at is null
      and c.email is not null
    order by c.is_primary desc nulls last, c.created_at asc
    limit 1;

    if v_contact is null then
      v_skip_eml := v_skip_eml + 1;
      continue;
    end if;

    -- Eligible
    v_enrolled := v_enrolled + 1;
    if coalesce(array_length(v_samples, 1), 0) < 10 then
      v_samples := v_samples || r.party_name;
    end if;

    if not p_dry_run then
      perform public.enroll_in_sequence(
        p_organization_id := p_organization_id,
        p_sequence_id     := p_sequence_id,
        p_party_id        := r.id,
        p_contact_id      := v_contact,
        p_enrolled_by     := p_enrolled_by
      );
    end if;
  end loop;

  return query select v_total, v_enrolled, v_skip_enr, v_skip_eml, v_samples;
end;
$fn$;

grant execute on function public.bulk_enroll_filtered(
  uuid, uuid, text, text[], text, text, text, text, text[], uuid, boolean
) to authenticated, service_role;

-- Smoke test (dry run, no writes):
-- select * from public.bulk_enroll_filtered(
--   'b25de8f2-1020-482f-9012-183f63883169'::uuid,
--   '<a real sequence_id>'::uuid,
--   p_module   => 'investor',
--   p_priority => array['high'],
--   p_dry_run  => true
-- );
