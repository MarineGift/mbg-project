-- ============================================================
-- seed_ipo_module.sql  (v3 final)
-- URM Platform — MarineBio Group Inc. Nasdaq listing program seed (English)
--
-- Requires: migration_ipo_module.sql
-- Re-runnable: ON CONFLICT DO NOTHING per row (missing rows are added; existing
--   rows are NOT updated — use fix_ipo_module_english.sql to retranslate).
--
-- Generated from ipo_data.py — same source as the Gantt HTML.
-- Real patents, licensees and contract rates are entered in the app only.
-- Public repo: never commit real UUIDs.
-- ============================================================

-- ------------------------------------------------------------
-- TX 1. Lookups (global)
-- ------------------------------------------------------------
BEGIN;
INSERT INTO app.ipo_workstreams (code, name, color_hex, sort_order) VALUES
  ('ip','IP / Patents','#7c3aed',1),
  ('commercial','Commercial / Licensing','#059669',2),
  ('finance_audit','Finance / Audit','#2563eb',3),
  ('legal_gov','Legal / Governance','#d97706',4),
  ('capital','Capital Markets','#dc2626',5),
  ('ir','IR / Disclosure','#0891b2',6)
ON CONFLICT (code) DO NOTHING;

INSERT INTO app.ipo_phases (code, name, sort_order, window_label) VALUES
  ('P0','Foundation — ownership and corporate clean-up',0,'2026 H2 – 2027 H1'),
  ('P1','Commercial Proof — commercial production',1,'2026 Q4 – 2028 H1'),
  ('P2','Audit & Controls — audit-ready',2,'2026 Q4 – 2029 Q1'),
  ('P3','Governance — public-company structure',3,'2028 H2 – 2029 Q3'),
  ('P4','Pre-IPO Capital — funding, underwriters, decision',4,'2028 – 2029 H1'),
  ('P5','Filing — S-1 and listing application',5,'2029 H1 – Q3'),
  ('P6','Listing & Aftermarket',6,'2029 Q4 – 2030 H1')
ON CONFLICT (code) DO NOTHING;
COMMIT;


-- ------------------------------------------------------------
-- TX 2. Program and everything under it
-- ------------------------------------------------------------
DO $$
DECLARE
  -- >>> replace before running <<<
  v_org  uuid := '00000000-0000-0000-0000-000000000000';
  -- >>> replace before running <<<
  v_prog uuid;
  v_scn  uuid;
  v_r    jsonb;
  v_i    int := 0;
  v_mid  uuid;
  v_gid  uuid;
  v_did  uuid;
BEGIN
  IF v_org = '00000000-0000-0000-0000-000000000000' THEN
    RAISE EXCEPTION 'Replace v_org with the real organization_id before running.';
  END IF;

  -- ---- program ----
  INSERT INTO app.ipo_programs
    (organization_id, name, target_tier, target_standard, window_start, window_end,
     build_to_quarter, program_start, note)
  VALUES (v_org, 'Nasdaq Listing 2029', 'capital_market', 'equity', '2029Q4', '2030Q2',
     '2029Q4', DATE '2026-09-01',
     'Operational preparation target: 2029 Q4 IPO-ready. IPO window 2029Q4–2030Q2. Decisions: Gate 1 (2028-12) → Gate 2 (2029-03, after FY2028 audit) → Gate 3 (underwriter bake-off). Korea is a PCAOB-accessible jurisdiction — not a Restrictive Market. Delaware corporation — cannot be an FPI; domestic-issuer reporting.')
  ON CONFLICT (organization_id, name) DO NOTHING;
  SELECT id INTO v_prog FROM app.ipo_programs WHERE organization_id = v_org AND name = 'Nasdaq Listing 2029';

  -- ---- milestones ----
  FOR v_r IN SELECT jsonb_array_elements($j$
[{"c": "F-IP-01", "p": "P0", "w": "ip", "t": "Transfer all FCC-related patents to MarineBio Group Inc.", "r": null, "s": "2026-09-01", "d": "2026-10-31", "g": true}, {"c": "F-IP-02", "p": "P0", "w": "ip", "t": "Record assignments at KIPO / USPTO / EPO / JPO", "r": null, "s": "2026-11-01", "d": "2027-02-28", "g": true}, {"c": "F-IP-03", "p": "P0", "w": "ip", "t": "File JP opposition", "r": null, "s": "2026-09-01", "d": "2026-10-27", "g": true}, {"c": "F-IP-04", "p": "P0", "w": "ip", "t": "Build patent register — family_role, expiration, maintenance dues", "r": null, "s": "2026-11-01", "d": "2027-03-31", "g": false}, {"c": "F-IP-05", "p": "P0", "w": "ip", "t": "Compute remaining life of material patents; review PTA/PTE", "r": null, "s": "2027-01-01", "d": "2027-03-31", "g": false}, {"c": "F-LG-01", "p": "P0", "w": "legal_gov", "t": "Written agency agreement with Marinepad (fees, voting, economic interest)", "r": "Reg S-K Item 404", "s": "2026-10-01", "d": "2026-12-31", "g": true}, {"c": "F-LG-02", "p": "P0", "w": "legal_gov", "t": "Clean up Delaware charter, bylaws and shareholder agreement", "r": null, "s": "2027-01-01", "d": "2027-03-31", "g": false}, {"c": "F-LG-03", "p": "P0", "w": "legal_gov", "t": "Cap table clean-up, stock option plan, 409A valuation", "r": null, "s": "2027-01-01", "d": "2027-06-30", "g": true}, {"c": "F-FA-01", "p": "P0", "w": "finance_audit", "t": "Convert books to US GAAP; monthly close in place", "r": null, "s": "2026-11-01", "d": "2027-03-31", "g": true}, {"c": "F-CM-01", "p": "P0", "w": "commercial", "t": "Start commercial production for Moorim 9,000 t order", "r": null, "s": "2026-10-01", "d": "2026-10-31", "g": true}, {"c": "C-CM-01", "p": "P1", "w": "commercial", "t": "Deliver 9,000 t order; Moorim commercial-scale validation and quality approval", "r": null, "s": "2026-11-01", "d": "2027-06-30", "g": true}, {"c": "C-CM-02", "p": "P1", "w": "commercial", "t": "Sign definitive license agreement with global filler manufacturer", "r": null, "s": "2027-01-01", "d": "2027-06-30", "g": true}, {"c": "C-CM-03", "p": "P1", "w": "commercial", "t": "Fix royalty reporting and audit-rights clauses (statements, Net Sales definition, audit right, record retention)", "r": "ASC 606", "s": "2027-01-01", "d": "2027-06-30", "g": true}, {"c": "C-CM-04", "p": "P1", "w": "commercial", "t": "Negotiate minimum volume / minimum royalty, exclusivity scope, termination", "r": null, "s": "2027-01-01", "d": "2027-06-30", "g": false}, {"c": "C-CM-05", "p": "P1", "w": "commercial", "t": "Agree licensee conversion of its own plants to FCC production", "r": null, "s": "2027-07-01", "d": "2027-12-31", "g": false}, {"c": "C-CM-06", "p": "P1", "w": "commercial", "t": "Receive licensee rollout plan → write and approve Management scenario", "r": null, "s": "2027-07-01", "d": "2027-12-31", "g": true}, {"c": "C-CM-07", "p": "P1", "w": "commercial", "t": "Start commercial supply for tissue grades", "r": null, "s": "2028-01-01", "d": "2028-06-30", "g": false}, {"c": "C-FA-01", "p": "P1", "w": "finance_audit", "t": "Document ASC 606 royalty revenue-recognition policy", "r": "ASC 606-10-55-65", "s": "2027-01-01", "d": "2027-03-31", "g": true}, {"c": "C-FA-02", "p": "P1", "w": "finance_audit", "t": "First royalty recognized with auditable settlement evidence", "r": null, "s": "2027-04-01", "d": "2027-09-30", "g": true}, {"c": "C-FA-03", "p": "P1", "w": "finance_audit", "t": "Royalty ledger live — minimum / due / received / recognized kept separate", "r": null, "s": "2027-07-01", "d": "2027-09-30", "g": true}, {"c": "A-FA-01", "p": "P2", "w": "finance_audit", "t": "Interview and engage PCAOB-registered auditor", "r": null, "s": "2026-11-01", "d": "2027-03-31", "g": true}, {"c": "A-FA-02", "p": "P2", "w": "finance_audit", "t": "Receive FY2027 audit report", "r": null, "s": "2028-01-01", "d": "2028-03-31", "g": true}, {"c": "A-FA-03", "p": "P2", "w": "finance_audit", "t": "Receive FY2028 audit report", "r": null, "s": "2029-01-01", "d": "2029-03-31", "g": true}, {"c": "A-FA-04", "p": "P2", "w": "finance_audit", "t": "Quarterly review process in place", "r": null, "s": "2028-04-01", "d": "2028-06-30", "g": false}, {"c": "A-FA-05", "p": "P2", "w": "finance_audit", "t": "Hire CFO with US public-company experience", "r": null, "s": "2027-10-01", "d": "2028-03-31", "g": true}, {"c": "A-FA-06", "p": "P2", "w": "finance_audit", "t": "SOX 302 documentation and ICFR gap remediation", "r": "SOX 302/404(a)", "s": "2028-04-01", "d": "2028-12-31", "g": true}, {"c": "A-FA-07", "p": "P2", "w": "finance_audit", "t": "Korea–US transfer pricing documentation", "r": null, "s": "2028-01-01", "d": "2028-06-30", "g": false}, {"c": "A-FA-08", "p": "P2", "w": "finance_audit", "t": "Complete ASC 810 / VIE assessment of Marinepad", "r": "ASC 810", "s": "2027-10-01", "d": "2028-03-31", "g": false}, {"c": "A-FA-09", "p": "P2", "w": "finance_audit", "t": "Domestic-issuer (non-FPI) reporting set-up — 10-K / 10-Q / 8-K / Proxy", "r": null, "s": "2029-01-01", "d": "2029-06-30", "g": false}, {"c": "A-CM-01", "p": "P2", "w": "commercial", "t": "Secure a second licensee (concentration relief)", "r": null, "s": "2028-01-01", "d": "2028-12-31", "g": false}, {"c": "G-LG-01", "p": "P3", "w": "legal_gov", "t": "Identify and interview independent director candidates", "r": null, "s": "2028-07-01", "d": "2028-12-31", "g": false}, {"c": "G-AC-01", "p": "P3", "w": "legal_gov", "t": "Appoint audit committee member #1 (listing-date requirement)", "r": "5615(b)(1)", "s": "2029-01-01", "d": "2029-03-31", "g": true}, {"c": "G-AC-02", "p": "P3", "w": "legal_gov", "t": "Appoint audit committee member #2 (90-day requirement, met early)", "r": "5615(b)(1)", "s": "2029-03-01", "d": "2029-05-31", "g": true}, {"c": "G-AC-03", "p": "P3", "w": "legal_gov", "t": "Appoint audit committee member #3 (1-year requirement, met early)", "r": "5615(b)(1)", "s": "2029-05-01", "d": "2029-07-31", "g": false}, {"c": "G-BD-01", "p": "P3", "w": "legal_gov", "t": "Majority-independent board before listing (no phase-in)", "r": "5605(b)", "s": "2029-01-01", "d": "2029-06-30", "g": true}, {"c": "G-LG-02", "p": "P3", "w": "legal_gov", "t": "Compensation committee — two or more independent directors", "r": "5605(d)", "s": "2029-01-01", "d": "2029-03-31", "g": false}, {"c": "G-LG-03", "p": "P3", "w": "legal_gov", "t": "Independent-director-led nomination process", "r": "5605(e)", "s": "2029-01-01", "d": "2029-03-31", "g": false}, {"c": "G-LG-04", "p": "P3", "w": "legal_gov", "t": "Adopt code of conduct", "r": "5610", "s": "2028-10-01", "d": "2028-12-31", "g": false}, {"c": "G-LG-05", "p": "P3", "w": "legal_gov", "t": "Related-party review procedure and whistleblower hotline", "r": "5630", "s": "2028-10-01", "d": "2028-12-31", "g": false}, {"c": "G-LG-06", "p": "P3", "w": "legal_gov", "t": "Bylaw clean-up — 33⅓% quorum, no disparate voting rights", "r": "5620(c)/5640", "s": "2029-01-01", "d": "2029-03-31", "g": false}, {"c": "G-LG-07", "p": "P3", "w": "legal_gov", "t": "Bind D&O insurance", "r": null, "s": "2029-04-01", "d": "2029-06-30", "g": false}, {"c": "K-CP-01", "p": "P4", "w": "capital", "t": "Secure cash runway through IPO plus contingency buffer (any instrument)", "r": null, "s": "2028-01-01", "d": "2028-12-31", "g": true}, {"c": "K-CP-02", "p": "P4", "w": "capital", "t": "Underwriter longlist and initial outreach", "r": null, "s": "2028-07-01", "d": "2028-12-31", "g": false}, {"c": "K-CP-03", "p": "P4", "w": "capital", "t": "Underwriter bake-off and selection", "r": null, "s": "2029-01-01", "d": "2029-02-28", "g": true}, {"c": "K-CP-04", "p": "P4", "w": "capital", "t": "Engage securities counsel and transfer agent", "r": null, "s": "2029-01-01", "d": "2029-02-28", "g": false}, {"c": "K-CP-05", "p": "P4", "w": "capital", "t": "Fix offering structure — gross proceeds $20–30M; MVUPHS $15M from offering proceeds only", "r": "5505(a)", "s": "2029-02-01", "d": "2029-03-31", "g": true}, {"c": "K-CP-06", "p": "P4", "w": "capital", "t": "Reverse split / par adjustment for $4+ offering price", "r": "5505(a)", "s": "2029-02-01", "d": "2029-03-31", "g": true}, {"c": "K-CP-07", "p": "P4", "w": "capital", "t": "Plan for 300 round-lot holders (150+ holding $2,500+ unrestricted)", "r": "5505(a)", "s": "2029-04-01", "d": "2029-06-30", "g": true}, {"c": "D-GO-01", "p": "P4", "w": "capital", "t": "Gate 1 — Preliminary Go/No-Go (FY2028 preliminary figures)", "r": null, "s": "2028-12-01", "d": "2028-12-15", "g": true}, {"c": "D-GO-02", "p": "P4", "w": "capital", "t": "Gate 2 — Final Internal Go/No-Go (FY2028 audit reflected)", "r": null, "s": "2029-03-15", "d": "2029-03-31", "g": true}, {"c": "D-GO-03", "p": "P4", "w": "capital", "t": "Gate 3 — Underwriter bake-off validation", "r": null, "s": "2029-01-01", "d": "2029-06-30", "g": true}, {"c": "S-CP-01", "p": "P5", "w": "capital", "t": "Reserve Nasdaq ticker symbol", "r": null, "s": "2029-01-01", "d": "2029-01-31", "g": false}, {"c": "S-CP-02", "p": "P5", "w": "capital", "t": "Draft S-1 (Business, Risk Factors, MD&A, Legal Proceedings)", "r": null, "s": "2029-02-01", "d": "2029-04-30", "g": false}, {"c": "S-CP-03", "p": "P5", "w": "capital", "t": "Confidential draft S-1 submission", "r": "Securities Act 6(e)", "s": "2029-04-15", "d": "2029-04-30", "g": true}, {"c": "S-CP-04", "p": "P5", "w": "capital", "t": "Respond to SEC comments (2–3 rounds)", "r": null, "s": "2029-05-01", "d": "2029-08-31", "g": true}, {"c": "S-CP-05", "p": "P5", "w": "capital", "t": "File Nasdaq listing application, agreement and governance certification; 4–6 week review", "r": "5505", "s": "2029-07-15", "d": "2029-08-31", "g": true}, {"c": "S-CP-06", "p": "P5", "w": "capital", "t": "Public S-1 filing — at least 15 days before roadshow", "r": "JOBS Act", "s": "2029-09-01", "d": "2029-09-15", "g": true}, {"c": "S-CP-07", "p": "P5", "w": "capital", "t": "Secure three registered market makers", "r": "5505(a)", "s": "2029-07-01", "d": "2029-09-30", "g": true}, {"c": "S-IR-01", "p": "P5", "w": "ir", "t": "IR website, disclosure controls and Reg FD policy live", "r": "5250(d)", "s": "2029-06-01", "d": "2029-08-31", "g": false}, {"c": "L-CP-01", "p": "P6", "w": "capital", "t": "Roadshow and book-building", "r": null, "s": "2029-10-01", "d": "2029-10-31", "g": false}, {"c": "L-CP-02", "p": "P6", "w": "capital", "t": "Pricing and S-1 effectiveness", "r": null, "s": "2029-11-01", "d": "2029-11-15", "g": true}, {"c": "L-CP-03", "p": "P6", "w": "capital", "t": "Nasdaq listing and first trade", "r": null, "s": "2029-11-15", "d": "2029-11-30", "g": true}, {"c": "L-CP-04", "p": "P6", "w": "capital", "t": "Switch to continued-listing (5550) monitoring", "r": "5550", "s": "2029-12-01", "d": "2029-12-31", "g": true}, {"c": "L-FA-01", "p": "P6", "w": "finance_audit", "t": "First 10-Q after listing", "r": null, "s": "2030-01-01", "d": "2030-02-28", "g": false}, {"c": "L-FA-02", "p": "P6", "w": "finance_audit", "t": "First 10-K and management ICFR assessment", "r": "SOX 404(a)", "s": "2030-01-01", "d": "2030-03-31", "g": false}, {"c": "L-LG-01", "p": "P6", "w": "legal_gov", "t": "First annual shareholder meeting after listing", "r": "5620(a)", "s": "2030-04-01", "d": "2030-06-30", "g": false}]
$j$::jsonb)
  LOOP
    v_i := v_i + 1;
    INSERT INTO app.ipo_milestones
      (organization_id, program_id, phase_id, workstream_id, code, title, rule_ref,
       start_date, target_date, is_gate, sort_order)
    VALUES (v_org, v_prog,
      (SELECT id FROM app.ipo_phases WHERE code = v_r->>'p'),
      (SELECT id FROM app.ipo_workstreams WHERE code = v_r->>'w'),
      v_r->>'c', v_r->>'t', v_r->>'r',
      (v_r->>'s')::date, (v_r->>'d')::date, (v_r->>'g')::boolean, v_i)
    ON CONFLICT (program_id, code) DO NOTHING;
  END LOOP;
  RAISE NOTICE 'milestones: %', v_i;

  -- ---- dependencies ----
  FOR v_r IN SELECT jsonb_array_elements($j$
[{"a": "F-IP-02", "b": "F-IP-01"}, {"a": "C-CM-02", "b": "F-IP-01"}, {"a": "C-CM-03", "b": "C-CM-02"}, {"a": "C-FA-02", "b": "C-FA-01"}, {"a": "C-FA-03", "b": "C-CM-03"}, {"a": "C-CM-06", "b": "C-CM-05"}, {"a": "A-FA-02", "b": "A-FA-01"}, {"a": "A-FA-02", "b": "C-CM-03"}, {"a": "A-FA-03", "b": "A-FA-02"}, {"a": "A-FA-06", "b": "A-FA-05"}, {"a": "G-AC-02", "b": "G-AC-01"}, {"a": "G-AC-03", "b": "G-AC-02"}, {"a": "K-CP-03", "b": "A-FA-02"}, {"a": "K-CP-05", "b": "K-CP-03"}, {"a": "D-GO-02", "b": "A-FA-03"}, {"a": "D-GO-02", "b": "D-GO-01"}, {"a": "D-GO-03", "b": "K-CP-03"}, {"a": "S-CP-03", "b": "D-GO-02"}, {"a": "S-CP-03", "b": "A-FA-03"}, {"a": "S-CP-03", "b": "G-AC-01"}, {"a": "S-CP-04", "b": "S-CP-03"}, {"a": "S-CP-05", "b": "S-CP-04"}, {"a": "S-CP-06", "b": "S-CP-04"}, {"a": "L-CP-02", "b": "S-CP-06"}, {"a": "L-CP-03", "b": "S-CP-05"}, {"a": "L-CP-03", "b": "S-CP-07"}, {"a": "L-CP-03", "b": "L-CP-02"}]
$j$::jsonb)
  LOOP
    INSERT INTO app.ipo_milestone_deps (milestone_id, depends_on_milestone_id)
    SELECT a.id, b.id FROM app.ipo_milestones a, app.ipo_milestones b
     WHERE a.program_id = v_prog AND b.program_id = v_prog
       AND a.code = v_r->>'a' AND b.code = v_r->>'b'
    ON CONFLICT DO NOTHING;
  END LOOP;

  -- ---- metric definitions ----
  v_i := 0;
  FOR v_r IN SELECT jsonb_array_elements($j$
[{"c": "stockholders_equity", "l": "Stockholders' equity", "u": "usd", "s": "Audit / review report", "v": true}, {"c": "mvuphs", "l": "Market value of unrestricted publicly held shares", "u": "usd", "s": "Offering structure", "v": false}, {"c": "unrestricted_public_shares", "l": "Unrestricted publicly held shares", "u": "shares", "s": "Cap table", "v": false}, {"c": "round_lot_holders", "l": "Unrestricted round-lot holders", "u": "holders", "s": "Transfer agent / underwriter", "v": false}, {"c": "qualified_round_lot_holders", "l": "Holders with $2,500+ unrestricted", "u": "holders", "s": "Transfer agent / underwriter", "v": false}, {"c": "market_makers", "l": "Registered market makers", "u": "count", "s": "Nasdaq", "v": false}, {"c": "bid_price", "l": "Bid price", "u": "usd_per_share", "s": "Offering price / market", "v": false}, {"c": "operating_history_years", "l": "Operating history", "u": "years", "s": "Corporate registration", "v": false}, {"c": "audited_fiscal_years", "l": "Audited fiscal years", "u": "years", "s": "Audit reports", "v": true}, {"c": "audit_committee_indep", "l": "Independent audit committee members", "u": "count", "s": "Board resolution", "v": false}, {"c": "comp_committee_indep", "l": "Independent compensation committee members", "u": "count", "s": "Board resolution", "v": false}, {"c": "board_indep_pct", "l": "Independent directors on board", "u": "pct", "s": "Board composition", "v": false}, {"c": "commercial_volume_tons", "l": "Annual commercial FCC volume", "u": "tons", "s": "Licensee statements", "v": false}, {"c": "licensed_capacity_tons", "l": "Licensed production capacity", "u": "tons", "s": "Licensee", "v": false}, {"c": "active_licensees", "l": "Active licensees", "u": "count", "s": "Contracts", "v": false}, {"c": "commercial_paper_customers", "l": "Paper mills in commercial supply", "u": "count", "s": "Licensee reports", "v": false}, {"c": "largest_licensee_pct", "l": "Largest licensee share of revenue", "u": "pct", "s": "Royalty ledger", "v": false}, {"c": "royalty_run_rate", "l": "Annualized royalty run-rate", "u": "usd", "s": "Royalty ledger", "v": false}, {"c": "gaap_royalty_revenue", "l": "GAAP royalty revenue (closed / audited)", "u": "usd", "s": "Close / audit report", "v": true}, {"c": "royalty_cash_received", "l": "Royalty cash received", "u": "usd", "s": "Bank / royalty ledger", "v": false}, {"c": "contracted_minimum_payment", "l": "Contracted minimum payment (annual)", "u": "usd", "s": "License agreement", "v": false}, {"c": "royalty_verified_pct", "l": "Royalty periods audit-verified", "u": "pct", "s": "v_royalty_metrics", "v": false}, {"c": "cash", "l": "Cash", "u": "usd", "s": "Bank", "v": false}, {"c": "monthly_burn", "l": "Monthly burn", "u": "usd", "s": "Close", "v": false}, {"c": "cash_runway_months", "l": "Cash runway", "u": "months", "s": "cash / monthly_burn", "v": false}, {"c": "material_patent_min_remaining_years", "l": "Material patent minimum remaining life", "u": "years", "s": "v_patent_horizon", "v": false}, {"c": "ipo_gross_proceeds", "l": "IPO gross proceeds (planned)", "u": "usd", "s": "Underwriter", "v": false}]
$j$::jsonb)
  LOOP
    v_i := v_i + 1;
    INSERT INTO app.ipo_metrics (organization_id, program_id, code, label, unit, source_hint, requires_verification, sort_order)
    VALUES (v_org, v_prog, v_r->>'c', v_r->>'l', v_r->>'u', v_r->>'s', (v_r->>'v')::boolean, v_i)
    ON CONFLICT (program_id, code) DO NOTHING;
  END LOOP;
  RAISE NOTICE 'metrics: %', v_i;

  -- ---- listing criteria ----
  v_i := 0;
  FOR v_r IN SELECT jsonb_array_elements($j$
[{"c": "cm_eq_se", "m": "stockholders_equity", "cat": "nasdaq", "r": "5505(b)(1)", "t": "capital_market", "s": "equity", "alt": false, "cmp": "gte", "v": 5000000, "o": false, "n": null}, {"c": "cm_mvuphs", "m": "mvuphs", "cat": "nasdaq", "r": "5505(a)", "t": "capital_market", "s": "equity", "alt": false, "cmp": "gte", "v": 15000000, "o": true, "n": "IPO listings: offering proceeds only"}, {"c": "cm_uphs", "m": "unrestricted_public_shares", "cat": "nasdaq", "r": "5505(a)", "t": "capital_market", "s": "equity", "alt": false, "cmp": "gte", "v": 1000000, "o": false, "n": null}, {"c": "cm_round_lot", "m": "round_lot_holders", "cat": "nasdaq", "r": "5505(a)", "t": "capital_market", "s": "equity", "alt": false, "cmp": "gte", "v": 300, "o": false, "n": null}, {"c": "cm_qualified_round_lot", "m": "qualified_round_lot_holders", "cat": "nasdaq", "r": "5505(a)", "t": "capital_market", "s": "equity", "alt": false, "cmp": "gte", "v": 150, "o": false, "n": "At least half of 300, each $2,500+"}, {"c": "cm_market_makers", "m": "market_makers", "cat": "nasdaq", "r": "5505(a)", "t": "capital_market", "s": "equity", "alt": false, "cmp": "gte", "v": 3, "o": false, "n": null}, {"c": "cm_bid_price", "m": "bid_price", "cat": "nasdaq", "r": "5505(a)", "t": "capital_market", "s": "equity", "alt": false, "cmp": "gte", "v": 4, "o": false, "n": null}, {"c": "cm_op_history", "m": "operating_history_years", "cat": "nasdaq", "r": "5505(b)(1)", "t": "capital_market", "s": "equity", "alt": false, "cmp": "gte", "v": 2, "o": false, "n": "Equity Standard only"}, {"c": "gov_audit_cmte", "m": "audit_committee_indep", "cat": "nasdaq", "r": "5605(c)", "t": "capital_market", "s": null, "alt": false, "cmp": "gte", "v": 3, "o": false, "n": null}, {"c": "gov_comp_cmte", "m": "comp_committee_indep", "cat": "nasdaq", "r": "5605(d)", "t": "capital_market", "s": null, "alt": false, "cmp": "gte", "v": 2, "o": false, "n": null}, {"c": "gov_board_majority", "m": "board_indep_pct", "cat": "nasdaq", "r": "5605(b)", "t": "capital_market", "s": null, "alt": false, "cmp": "gte", "v": 51, "o": false, "n": null}, {"c": "sec_audited_years", "m": "audited_fiscal_years", "cat": "sec", "r": "JOBS Act / Reg S-X", "t": null, "s": null, "alt": false, "cmp": "gte", "v": 2, "o": false, "n": "EGC: two fiscal years. Sets the auditor-engagement deadline"}, {"c": "alt_ni_se", "m": "stockholders_equity", "cat": "nasdaq", "r": "5505(b)(2),(3)", "t": "capital_market", "s": "net_income", "alt": true, "cmp": "gte", "v": 4000000, "o": false, "n": "[Alternate] Net Income / MVLS"}, {"c": "gm_se", "m": "stockholders_equity", "cat": "nasdaq", "r": "5405(b)(1)", "t": "global_market", "s": "income", "alt": true, "cmp": "gte", "v": 15000000, "o": false, "n": "[Uplist]"}, {"c": "gm_uphs", "m": "unrestricted_public_shares", "cat": "nasdaq", "r": "5405(a)", "t": "global_market", "s": "income", "alt": true, "cmp": "gte", "v": 1100000, "o": false, "n": "[Uplist]"}, {"c": "gm_round_lot", "m": "round_lot_holders", "cat": "nasdaq", "r": "5405(a)", "t": "global_market", "s": "income", "alt": true, "cmp": "gte", "v": 400, "o": false, "n": "[Uplist]"}, {"c": "gm_mvuphs", "m": "mvuphs", "cat": "nasdaq", "r": "5405(a)", "t": "global_market", "s": "income", "alt": true, "cmp": "gte", "v": 15000000, "o": true, "n": "[Uplist]"}]
$j$::jsonb)
  LOOP
    v_i := v_i + 1;
    INSERT INTO app.ipo_listing_criteria
      (organization_id, program_id, metric_id, code, category, rule_ref, tier, standard,
       is_alternate, comparator, threshold, from_offering_only, note, sort_order)
    VALUES (v_org, v_prog,
      (SELECT id FROM app.ipo_metrics WHERE program_id = v_prog AND code = v_r->>'m'),
      v_r->>'c', v_r->>'cat', v_r->>'r', v_r->>'t', v_r->>'s',
      (v_r->>'alt')::boolean, v_r->>'cmp', (v_r->>'v')::numeric, (v_r->>'o')::boolean, v_r->>'n', v_i)
    ON CONFLICT (program_id, code) DO NOTHING;
  END LOOP;
  RAISE NOTICE 'listing criteria: %', v_i;

  -- ---- Internal KPIs (structural only; revenue/volume KPIs are added with approved_at once the Management scenario is approved) ----
  v_i := 0;
  FOR v_r IN SELECT jsonb_array_elements($j$
[{"c": "kpi_active_licensees", "m": "active_licensees", "cmp": "gte", "v": 2, "r": "Reduce single-licensee dependence"}, {"c": "kpi_largest_licensee", "m": "largest_licensee_pct", "cmp": "lte", "v": 80, "r": "100% dependence is risk factor #1"}, {"c": "kpi_cash_runway", "m": "cash_runway_months", "cmp": "gte", "v": 24, "r": "Instrument-agnostic"}, {"c": "kpi_patent_life", "m": "material_patent_min_remaining_years", "cmp": "gte", "v": 10, "r": "End of royalty stream = end of valuation"}, {"c": "kpi_board_indep", "m": "board_indep_pct", "cmp": "gte", "v": 51, "r": "Target completion before listing date"}, {"c": "kpi_royalty_verified", "m": "royalty_verified_pct", "cmp": "gte", "v": 100, "r": "One unverified period is an audit issue"}, {"c": "kpi_gross_proceeds", "m": "ipo_gross_proceeds", "cmp": "gte", "v": 20000000, "r": "Do not size to the $15M floor"}]
$j$::jsonb)
  LOOP
    v_i := v_i + 1;
    INSERT INTO app.ipo_internal_kpis (organization_id, program_id, metric_id, code, comparator, threshold, rationale, approved_at, sort_order)
    VALUES (v_org, v_prog,
      (SELECT id FROM app.ipo_metrics WHERE program_id = v_prog AND code = v_r->>'m'),
      v_r->>'c', v_r->>'cmp', (v_r->>'v')::numeric, v_r->>'r', current_date, v_i)
    ON CONFLICT (program_id, code) DO NOTHING;
  END LOOP;
  RAISE NOTICE 'internal KPIs: %', v_i;

  -- ---- gates + linked milestones ----
  v_i := 0;
  FOR v_r IN SELECT jsonb_array_elements($j$
[{"l": 1, "c": "L1-01", "q": "Can the three Equity Standard tests (stockholders' equity $5M, MVUPHS $15M, 2-year operating history) be met at the offering?", "p": "MVUPHS from offering proceeds only; equity measured after the offering", "b": true, "m": ["K-CP-05"]}, {"l": 1, "c": "L1-02", "q": "Can we reach 300 unrestricted round-lot holders, 150+ each holding $2,500+?", "p": "Underwriter allocation plan; exclude locked-up shares", "b": true, "m": ["K-CP-07"]}, {"l": 1, "c": "L1-03", "q": "Does a $4+ offering price structure hold?", "p": "Pre-money basis after any reverse split", "b": true, "m": ["K-CP-06"]}, {"l": 1, "c": "L1-04", "q": "Are three market makers secured?", "p": "Registration confirmed", "b": true, "m": ["S-CP-07"]}, {"l": 2, "c": "L2-01", "q": "Is a PCAOB auditor engaged and are FY2027 and FY2028 audits complete on schedule?", "p": "Two audited fiscal years", "b": true, "m": ["A-FA-01", "A-FA-02", "A-FA-03"]}, {"l": 2, "c": "L2-02", "q": "Has the auditor accepted the royalty revenue-recognition policy?", "p": "ASC 606 basis documented", "b": true, "m": ["C-FA-01", "C-FA-02"]}, {"l": 2, "c": "L2-03", "q": "Are licensee royalty statements verified against independent records?", "p": "v_royalty_reconciliation clean for every period", "b": true, "m": ["C-CM-03", "C-FA-03"]}, {"l": 2, "c": "L2-04", "q": "Is the difference between ledger-recognized and GAAP royalty revenue explained?", "p": "v_royalty_vs_gaap reconciliation_difference documented", "b": false, "m": []}, {"l": 2, "c": "L2-05", "q": "Is a CFO in place, ICFR gaps closed, quarterly reviews running?", "p": "SOX 302 documentation complete", "b": true, "m": ["A-FA-05", "A-FA-06", "A-FA-04"]}, {"l": 2, "c": "L2-06", "q": "Are transfer-pricing files and domestic-issuer reporting ready?", "p": "", "b": false, "m": ["A-FA-07", "A-FA-09"]}, {"l": 3, "c": "L3-01", "q": "Is Moorim commercial production validated with repeat orders?", "p": "Two or more consecutive quarters of orders plus quality approval", "b": true, "m": ["F-CM-01", "C-CM-01"]}, {"l": 3, "c": "L3-02", "q": "Has the global filler manufacturer converted its own plants to FCC?", "p": "Number of converted plants and start dates", "b": true, "m": ["C-CM-05"]}, {"l": 3, "c": "L3-03", "q": "Is royalty recognized as recurring revenue?", "p": "Four or more consecutive quarters", "b": true, "m": ["C-FA-02"]}, {"l": 3, "c": "L3-04", "q": "Is the Management scenario approved on the basis of the licensee's rollout plan?", "p": "ipo_scenarios.approved_at", "b": false, "m": ["C-CM-06"]}, {"l": 3, "c": "L3-05", "q": "Are actuals within the planning-default scenario range?", "p": "v_ipo_scenario_royalty.actual_vs_range ≠ below_low", "b": false, "m": []}, {"l": 3, "c": "L3-06", "q": "Is licensee concentration acceptable?", "p": "Two or more licensees, or a documented mitigation", "b": false, "m": ["A-CM-01"]}, {"l": 4, "c": "L4-01", "q": "Are all material patents owned by MBG Inc. with assignments recorded in every jurisdiction?", "p": "v_patent_horizon.unrecorded_material_count = 0", "b": true, "m": ["F-IP-01", "F-IP-02"]}, {"l": 4, "c": "L4-02", "q": "Does the remaining life of material patents support the royalty stream?", "p": "min_remaining_years; foundational vs improvement disclosed separately", "b": true, "m": ["F-IP-04", "F-IP-05"]}, {"l": 4, "c": "L4-03", "q": "Does the license contain audit rights, reporting, minimum volume and termination protections?", "p": "license_terms reporting/protection all done", "b": true, "m": ["C-CM-03", "C-CM-04"]}, {"l": 4, "c": "L4-04", "q": "Is the Marinepad relationship documented and the VIE assessment complete?", "p": "Signed agreement plus accountants' memo", "b": true, "m": ["F-LG-01", "A-FA-08"]}, {"l": 4, "c": "L4-05", "q": "Are pending patent proceedings (EPO TPO, JP opposition) organized for Legal Proceedings disclosure?", "p": "Status log by date", "b": false, "m": ["F-IP-03"]}, {"l": 5, "c": "L5-01", "q": "Are audit committee member #1 and independent directors confirmed as of the listing date?", "p": "5615(b)(1) listing-date requirement", "b": true, "m": ["G-AC-01", "G-BD-01"]}, {"l": 5, "c": "L5-02", "q": "Will the 3-member audit committee, 2-member compensation committee and nomination process be complete before listing (no phase-in)?", "p": "Internal target", "b": false, "m": ["G-AC-02", "G-AC-03", "G-LG-02", "G-LG-03"]}, {"l": 5, "c": "L5-03", "q": "Are the code of conduct, related-party procedure, bylaws and D&O in place?", "p": "", "b": false, "m": ["G-LG-04", "G-LG-05", "G-LG-06", "G-LG-07"]}, {"l": 6, "c": "L6-01", "q": "Is cash runway through the IPO plus a buffer secured?", "p": "Any instrument — the test is runway, not a round called Series A", "b": true, "m": ["K-CP-01"]}, {"l": 6, "c": "L6-02", "q": "Has an underwriter confirmed firm-commitment intent?", "p": "The effective final judge", "b": true, "m": ["K-CP-03", "D-GO-03"]}, {"l": 6, "c": "L6-03", "q": "Does a $20–30M gross-proceeds structure hold?", "p": "Do not size to the $15M regulatory floor", "b": false, "m": ["K-CP-05"]}, {"l": 6, "c": "L6-04", "q": "Will the holder base sustain aftermarket liquidity and continued-listing tests ($1 bid, $2.5M equity)?", "p": "", "b": false, "m": ["L-CP-04"]}]
$j$::jsonb)
  LOOP
    v_i := v_i + 1;
    INSERT INTO app.ipo_readiness_gates (organization_id, program_id, level, code, question, pass_condition, is_blocking, sort_order)
    VALUES (v_org, v_prog, (v_r->>'l')::int, v_r->>'c', v_r->>'q', NULLIF(v_r->>'p',''), (v_r->>'b')::boolean, v_i)
    ON CONFLICT (program_id, code) DO NOTHING;
    SELECT id INTO v_gid FROM app.ipo_readiness_gates WHERE program_id = v_prog AND code = v_r->>'c';
    INSERT INTO app.ipo_gate_milestones (gate_id, milestone_id)
    SELECT v_gid, m.id FROM app.ipo_milestones m
     WHERE m.program_id = v_prog AND m.code IN (SELECT jsonb_array_elements_text(v_r->'m'))
    ON CONFLICT DO NOTHING;
  END LOOP;
  RAISE NOTICE 'gates: %', v_i;

  -- ---- decision schedule ----
  FOR v_r IN SELECT jsonb_array_elements($j$
[{"s": "gate1", "n": "Gate 1 — Preliminary Go/No-Go", "a": "2028-12-01", "b": "2028-12-15", "p": "Direction call on FY2028 preliminary results, commercialization and run-rate", "i": "v_ipo_dashboard, v_ipo_gate_readiness, v_ipo_scenario_royalty"}, {"s": "gate2", "n": "Gate 2 — Final Internal Go/No-Go", "a": "2029-03-15", "b": "2029-03-31", "p": "Confirm with FY2028 PCAOB audit results", "i": "A-FA-03 audit report, v_ipo_listing_status"}, {"s": "gate3", "n": "Gate 3 — Underwriter Validation", "a": "2029-01-01", "b": "2029-06-30", "p": "Capital-market feasibility via underwriter bake-off", "i": "Firm-commitment letters of intent"}]
$j$::jsonb)
  LOOP
    INSERT INTO app.ipo_decision_schedule (organization_id, program_id, stage, name, window_start, window_end, purpose, inputs)
    VALUES (v_org, v_prog, v_r->>'s', v_r->>'n', (v_r->>'a')::date, (v_r->>'b')::date, v_r->>'p', v_r->>'i')
    ON CONFLICT (program_id, stage) DO NOTHING;
  END LOOP;

  -- ---- assumptions ----
  FOR v_r IN SELECT jsonb_array_elements($j$
[{"c": "fcc_net_sales_per_ton", "v": 200, "u": "usd", "s": "Planning assumption — premium over PCC/GCC"}, {"c": "royalty_pct_low", "v": 5, "u": "pct", "s": "Negotiation range, low end"}, {"c": "royalty_pct_base", "v": 7.5, "u": "pct", "s": "Planning base"}, {"c": "royalty_pct_high", "v": 10, "u": "pct", "s": "Negotiation range, high end"}, {"c": "reference_royalty_per_ton", "v": 15, "u": "usd", "s": "Management reference value. Not a KPI. Sanity-check against derived $/t"}]
$j$::jsonb)
  LOOP
    INSERT INTO app.ipo_assumptions (organization_id, program_id, code, value_numeric, unit, effective_from, source_note)
    VALUES (v_org, v_prog, v_r->>'c', (v_r->>'v')::numeric, v_r->>'u', DATE '2026-09-20', v_r->>'s')
    ON CONFLICT (program_id, code, effective_from) DO NOTHING;
  END LOOP;

  -- ---- scenarios ----
  INSERT INTO app.ipo_scenarios (organization_id, program_id, code, name, is_planning_default, basis, note)
  VALUES (v_org, v_prog, 'conservative', 'Conservative — sequential adoption', true,
    'Paper mills adopt one at a time after re-validation; 2–3 year adoption cycle. Price and rate from ipo_assumptions.',
    'Planning default. Downside surprises cost asymmetrically more; revising upward costs nothing.')
  ON CONFLICT (program_id, code) DO NOTHING;
  SELECT id INTO v_scn FROM app.ipo_scenarios WHERE program_id = v_prog AND code = 'conservative';
  FOR v_r IN SELECT jsonb_array_elements($j$
[{"y": 2026, "cap": 9000, "lo": 9000, "hi": 9000}, {"y": 2027, "cap": null, "lo": 20000, "hi": 30000}, {"y": 2028, "cap": null, "lo": 70000, "hi": 120000}, {"y": 2029, "cap": null, "lo": 180000, "hi": 300000}, {"y": 2030, "cap": null, "lo": 400000, "hi": 600000}]
$j$::jsonb)
  LOOP
    INSERT INTO app.ipo_scenario_points (organization_id, scenario_id, fiscal_year, licensed_capacity_tons, volume_tons_low, volume_tons_high)
    VALUES (v_org, v_scn, (v_r->>'y')::int, (v_r->>'cap')::numeric, (v_r->>'lo')::numeric, (v_r->>'hi')::numeric)
    ON CONFLICT (scenario_id, fiscal_year) DO NOTHING;
  END LOOP;

  INSERT INTO app.ipo_scenarios (organization_id, program_id, code, name, is_planning_default, basis, note)
  VALUES
    (v_org, v_prog, 'management', 'Management — based on commercial results', false,
     'Written after 2026-10 commercialization results and the licensee rollout plan (C-CM-06).',
     'Empty is correct. Not used as any forecast until approved_at is set.'),
    (v_org, v_prog, 'global_rollout', 'Global Rollout — licensee plant conversion', false,
     'Based on the licensee''s official rollout document; step increases per converted plant.',
     'Not filled without a licensee document.')
  ON CONFLICT (program_id, code) DO NOTHING;

  RAISE NOTICE 'program seed complete';
END $$;


-- ------------------------------------------------------------
-- TX 3. License term checklist (template until a licensee is set)
-- ------------------------------------------------------------
DO $$
DECLARE
  v_org uuid := '00000000-0000-0000-0000-000000000000';  -- replace
  v_r jsonb; v_i int := 0;
BEGIN
  IF v_org = '00000000-0000-0000-0000-000000000000' THEN
    RAISE EXCEPTION 'Replace v_org with the real organization_id before running.';
  END IF;
  FOR v_r IN SELECT jsonb_array_elements($j$
[{"c": "economics", "i": "Royalty rate — 5–10% of Net Sales"}, {"c": "economics", "i": "FCC price assumption and $/t derivation"}, {"c": "economics", "i": "Minimum annual royalty / minimum volume"}, {"c": "economics", "i": "Upfront license fee"}, {"c": "economics", "i": "Milestone payments"}, {"c": "scope", "i": "Territory"}, {"c": "scope", "i": "Paper grades — tissue included?"}, {"c": "scope", "i": "Exclusivity and conditions to keep it"}, {"c": "scope", "i": "Sublicensing rights and reporting"}, {"c": "protection", "i": "Minimum commercialization obligation"}, {"c": "protection", "i": "Loss of exclusivity on under-performance"}, {"c": "protection", "i": "Termination"}, {"c": "protection", "i": "Non-compete / no design-around"}, {"c": "reporting", "i": "Quarterly royalty statement obligation and deadline"}, {"c": "reporting", "i": "Reported items — production / sales / Net Sales"}, {"c": "reporting", "i": "Net Sales definition — affiliates, transfer pricing, rebates, freight, taxes"}, {"c": "reporting", "i": "Toll-manufacturing formula where no sales price exists"}, {"c": "reporting", "i": "MBG audit right — at least annually, designated accounting firm"}, {"c": "reporting", "i": "Record retention period"}, {"c": "reporting", "i": "Interest and cost shifting on under-reporting"}, {"c": "ip", "i": "Licensed patent list and jurisdictions"}, {"c": "ip", "i": "Ownership of improvements and new filings"}, {"c": "ip", "i": "Enforcement lead and cost sharing"}, {"c": "ip", "i": "Remaining patent life and post-expiry terms"}]
$j$::jsonb)
  LOOP
    v_i := v_i + 1;
    INSERT INTO app.license_terms (organization_id, licensee_party_id, category, item, sort_order)
    VALUES (v_org, NULL, v_r->>'c', v_r->>'i', v_i)
    ON CONFLICT DO NOTHING;
  END LOOP;
  RAISE NOTICE 'license term checklist: %', v_i;
END $$;


-- ============================================================
-- Verify
-- ============================================================
-- SELECT phase_code, total, open_gates, phase_start, phase_end FROM app.v_ipo_phase_progress ORDER BY sort_order;
--   expect: 7 phases, 66 milestones
-- SELECT level, level_name, gates, linked_total FROM app.v_ipo_gate_readiness ORDER BY level;
--   expect: 6 levels, 28 gates, all incomplete
-- SELECT scenario, fiscal_year, derived_royalty_per_ton, royalty_usd_low, royalty_usd_high
--   FROM app.v_ipo_scenario_royalty ORDER BY fiscal_year;
--   expect: derived $/t = 7.5% x $200 = 15.00 (matches reference)
-- SELECT * FROM app.v_ipo_gantt WHERE program_id = (SELECT id FROM app.ipo_programs LIMIT 1) ORDER BY ord;
