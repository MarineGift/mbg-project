-- =====================================================================
-- 20260714190000_verify_do_not_send.sql   (READ-ONLY)
-- One-shot proof that the extended v_email_do_not_send is working:
--   Q1  composition counts (forms vs outcomes vs follow-up)
--   Q2  the actual form-submitted parties now blocked (Lowercarbon etc.)
--   Q3  the 5 recorded 7/14 outcome addresses still blocked
--   Q4  spot-check: is a given address blocked, and why
-- =====================================================================

-- Q1. composition of the block list
SELECT
  COUNT(*) FILTER (WHERE outcomes LIKE 'form_%')      AS from_forms,
  COUNT(*) FILTER (WHERE outcomes NOT LIKE '%form_%') AS from_outcomes_only,
  COUNT(*) FILTER (WHERE is_follow_up)                AS follow_up_flagged,
  COUNT(*)                                            AS total_blocked
FROM app.v_email_do_not_send;

-- Q2. parties blocked because a web form was submitted/decided.
-- Lowercarbon Capital (submitted $5M) should appear here.
SELECT DISTINCT p.party_name, dns.email_lower, dns.outcomes, dns.last_event_at
FROM app.v_email_do_not_send dns
JOIN app.parties p ON p.id = dns.party_id
WHERE dns.outcomes LIKE 'form_%'
ORDER BY p.party_name;

-- Q3. the 7/14 outcome-based blocks (bounce / reject / etc.) still present
SELECT dns.email_lower, dns.outcomes, dns.is_follow_up, dns.last_event_at
FROM app.v_email_do_not_send dns
WHERE dns.outcomes NOT LIKE '%form_%'
ORDER BY dns.last_event_at DESC;

-- Q4. spot check one address (edit the value). 0 rows = safe to send.
SELECT email_lower, party_id, outcomes, is_follow_up
FROM app.v_email_do_not_send
WHERE email_lower = lower('startups@planet-a.com');
