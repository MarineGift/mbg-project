-- =====================================================================
-- 20260715220000_scan_country_code_coverage.sql
--
-- Unblocks 미결 4 (timezone). READ-ONLY. Nothing is written.
--
-- WHY THIS EXISTS
--   The handoff records: "app.parties에 country 없음(42703) → 백필 선행".
--   That 42703 was a COLUMN-NAME error, not a missing column.
--   app.parties has had `country_code` (ISO-2) all along, alongside
--   `city` and `region`. Confirmed three ways in the repo:
--     * src/types/database.ts  -> parties.Row.country_code: string | null
--     * sql/20260627120000_global_am_investors_batch3.sql and ~10 other
--       seeds insert into app.parties (..., country_code, region, city, ...)
--     * src/components/parties/party-form.tsx line 92/339 (countryCode),
--       party-header.tsx line 96 renders it, country-peers-panel.tsx
--       filters .eq('country_code', ...)
--   So no backfill MIGRATION is needed. What is unknown is COVERAGE:
--   how many of the 40 Tuesday recipients actually have a country_code.
--   That is what this file measures. Run it, then decide.
--
-- Supabase SQL Editor safe: self-contained statements, CTEs repeated per
-- statement, no semicolons inside strings, no bare `into` inside strings.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Q1. Does the column exist, and what is org-wide coverage?
--     If this returns rows, the 42703 was a typo -- full stop.
-- ---------------------------------------------------------------------
SELECT
  count(*)                                            AS parties_total,
  count(p.country_code)                               AS with_country_code,
  count(*) - count(p.country_code)                    AS missing,
  round(100.0 * count(p.country_code) / nullif(count(*), 0), 1) AS pct_covered
FROM app.parties p
WHERE p.deleted_at IS NULL;


-- ---------------------------------------------------------------------
-- Q2. Coverage that actually matters: the live Climate sequence.
--     Sequence 63737c08 = "Climate Investor Cold Outreach -- FCC",
--     the only active sequence after the 07-15 archive pass.
-- ---------------------------------------------------------------------
SELECT
  count(*)                                            AS active_enrollments,
  count(p.country_code)                               AS with_country_code,
  count(*) - count(p.country_code)                    AS missing,
  round(100.0 * count(p.country_code) / nullif(count(*), 0), 1) AS pct_covered
FROM app.email_sequence_enrollments e
JOIN app.parties p ON p.id = e.party_id
WHERE e.sequence_id::text LIKE '63737c08%'
  AND e.status::text = 'active'
  AND p.deleted_at IS NULL;


-- ---------------------------------------------------------------------
-- Q3. The real question behind 미결 4:
--     at 09:00 PT on 7/21, what LOCAL time does each recipient get hit?
--     16:00 UTC is the send instant. Rough zone by country_code.
--     NULL country_code rows surface as 'UNKNOWN' -- those are the ones
--     a backfill would need to touch, and the count tells you whether
--     it is worth doing before Tuesday or not.
-- ---------------------------------------------------------------------
SELECT
  coalesce(p.country_code, 'UNKNOWN')                 AS country_code,
  count(*)                                            AS recipients,
  CASE coalesce(p.country_code, 'UNKNOWN')
    WHEN 'US' THEN 'America/Los_Angeles'
    WHEN 'CA' THEN 'America/Toronto'
    WHEN 'GB' THEN 'Europe/London'
    WHEN 'DE' THEN 'Europe/Berlin'
    WHEN 'FR' THEN 'Europe/Paris'
    WHEN 'NL' THEN 'Europe/Amsterdam'
    WHEN 'CH' THEN 'Europe/Zurich'
    WHEN 'SE' THEN 'Europe/Stockholm'
    WHEN 'DK' THEN 'Europe/Copenhagen'
    WHEN 'NO' THEN 'Europe/Oslo'
    WHEN 'FI' THEN 'Europe/Helsinki'
    WHEN 'ES' THEN 'Europe/Madrid'
    WHEN 'IT' THEN 'Europe/Rome'
    WHEN 'IE' THEN 'Europe/Dublin'
    WHEN 'BE' THEN 'Europe/Brussels'
    WHEN 'AT' THEN 'Europe/Vienna'
    WHEN 'IL' THEN 'Asia/Jerusalem'
    WHEN 'JP' THEN 'Asia/Tokyo'
    WHEN 'KR' THEN 'Asia/Seoul'
    WHEN 'CN' THEN 'Asia/Shanghai'
    WHEN 'SG' THEN 'Asia/Singapore'
    WHEN 'IN' THEN 'Asia/Kolkata'
    WHEN 'AU' THEN 'Australia/Sydney'
    WHEN 'NZ' THEN 'Pacific/Auckland'
    WHEN 'BR' THEN 'America/Sao_Paulo'
    ELSE NULL
  END                                                 AS assumed_tz,
  to_char(
    timestamptz '2026-07-21 16:00:00+00' AT TIME ZONE
    coalesce(
      CASE coalesce(p.country_code, 'UNKNOWN')
        WHEN 'US' THEN 'America/Los_Angeles'
        WHEN 'CA' THEN 'America/Toronto'
        WHEN 'GB' THEN 'Europe/London'
        WHEN 'DE' THEN 'Europe/Berlin'
        WHEN 'FR' THEN 'Europe/Paris'
        WHEN 'NL' THEN 'Europe/Amsterdam'
        WHEN 'CH' THEN 'Europe/Zurich'
        WHEN 'SE' THEN 'Europe/Stockholm'
        WHEN 'DK' THEN 'Europe/Copenhagen'
        WHEN 'NO' THEN 'Europe/Oslo'
        WHEN 'FI' THEN 'Europe/Helsinki'
        WHEN 'ES' THEN 'Europe/Madrid'
        WHEN 'IT' THEN 'Europe/Rome'
        WHEN 'IE' THEN 'Europe/Dublin'
        WHEN 'BE' THEN 'Europe/Brussels'
        WHEN 'AT' THEN 'Europe/Vienna'
        WHEN 'IL' THEN 'Asia/Jerusalem'
        WHEN 'JP' THEN 'Asia/Tokyo'
        WHEN 'KR' THEN 'Asia/Seoul'
        WHEN 'CN' THEN 'Asia/Shanghai'
        WHEN 'SG' THEN 'Asia/Singapore'
        WHEN 'IN' THEN 'Asia/Kolkata'
        WHEN 'AU' THEN 'Australia/Sydney'
        WHEN 'NZ' THEN 'Pacific/Auckland'
        WHEN 'BR' THEN 'America/Sao_Paulo'
        ELSE NULL
      END,
      'UTC'
    ),
    'Dy HH24:MI'
  )                                                   AS local_arrival,
  CASE
    WHEN p.country_code IS NULL THEN 'unknown - cannot judge'
    WHEN p.country_code IN ('US','CA','BR') THEN 'business hours'
    WHEN p.country_code IN ('GB','IE','DE','FR','NL','CH','SE','DK','NO','FI','ES','IT','BE','AT','IL')
      THEN 'EVENING - after hours'
    WHEN p.country_code IN ('JP','KR','CN','SG','AU','NZ','IN')
      THEN 'MIDDLE OF THE NIGHT'
    ELSE 'check by hand'
  END                                                 AS verdict
FROM app.email_sequence_enrollments e
JOIN app.parties p ON p.id = e.party_id
WHERE e.sequence_id::text LIKE '63737c08%'
  AND e.status::text = 'active'
  AND p.deleted_at IS NULL
GROUP BY p.country_code
ORDER BY recipients DESC, country_code;


-- ---------------------------------------------------------------------
-- Q4. Name the rows a backfill would have to fix. If this is short,
--     fix them by hand in the UI (party-form already has the field)
--     and skip the migration entirely.
-- ---------------------------------------------------------------------
SELECT
  p.id,
  p.party_name,
  p.city,
  p.region,
  p.website,
  split_part(p.domain_normalized, '.', -1)            AS tld_hint
FROM app.email_sequence_enrollments e
JOIN app.parties p ON p.id = e.party_id
WHERE e.sequence_id::text LIKE '63737c08%'
  AND e.status::text = 'active'
  AND p.country_code IS NULL
  AND p.deleted_at IS NULL
ORDER BY p.party_name;


-- ---------------------------------------------------------------------
-- Q5. If Q4 is long, this is the cheap 80% backfill: ccTLD -> country.
--     PREVIEW ONLY -- this is a SELECT, it writes nothing.
--     Deliberately skips .com/.net/.org/.io/.vc/.ai and other
--     non-geographic TLDs, which carry no country signal.
-- ---------------------------------------------------------------------
SELECT
  p.id,
  p.party_name,
  p.website,
  split_part(p.domain_normalized, '.', -1)            AS tld,
  upper(split_part(p.domain_normalized, '.', -1))     AS would_set_country_code
FROM app.parties p
WHERE p.country_code IS NULL
  AND p.deleted_at IS NULL
  AND p.domain_normalized IS NOT NULL
  AND split_part(p.domain_normalized, '.', -1) IN (
    'kr','jp','cn','uk','de','fr','nl','ch','se','dk','no','fi','es','it',
    'ie','be','at','il','sg','in','au','nz','br','ca','tw','hk'
  )
ORDER BY tld, p.party_name;
-- NOTE on .uk: the ccTLD is 'uk' but the ISO-2 country code is 'GB'.
-- Do not blind-cast upper(tld). Map uk -> GB by hand before any UPDATE.
