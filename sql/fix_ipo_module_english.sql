-- ============================================================
-- fix_ipo_module_english.sql
-- Retranslate existing IPO module rows to English, matched by code.
-- Idempotent. Does not touch verdicts, statuses, snapshots or dates.
-- Generated from ipo_data.py.
-- ============================================================
BEGIN;

UPDATE app.ipo_phases SET name='Foundation — ownership and corporate clean-up', window_label='2026 H2 – 2027 H1' WHERE code='P0';
UPDATE app.ipo_phases SET name='Commercial Proof — commercial production', window_label='2026 Q4 – 2028 H1' WHERE code='P1';
UPDATE app.ipo_phases SET name='Audit & Controls — audit-ready', window_label='2026 Q4 – 2029 Q1' WHERE code='P2';
UPDATE app.ipo_phases SET name='Governance — public-company structure', window_label='2028 H2 – 2029 Q3' WHERE code='P3';
UPDATE app.ipo_phases SET name='Pre-IPO Capital — funding, underwriters, decision', window_label='2028 – 2029 H1' WHERE code='P4';
UPDATE app.ipo_phases SET name='Filing — S-1 and listing application', window_label='2029 H1 – Q3' WHERE code='P5';
UPDATE app.ipo_phases SET name='Listing & Aftermarket', window_label='2029 Q4 – 2030 H1' WHERE code='P6';
UPDATE app.ipo_workstreams SET name='IP / Patents' WHERE code='ip';
UPDATE app.ipo_workstreams SET name='Commercial / Licensing' WHERE code='commercial';
UPDATE app.ipo_workstreams SET name='Finance / Audit' WHERE code='finance_audit';
UPDATE app.ipo_workstreams SET name='Legal / Governance' WHERE code='legal_gov';
UPDATE app.ipo_workstreams SET name='Capital Markets' WHERE code='capital';
UPDATE app.ipo_workstreams SET name='IR / Disclosure' WHERE code='ir';

UPDATE app.ipo_programs SET note='Operational preparation target: 2029 Q4 IPO-ready. IPO window 2029Q4–2030Q2. Decisions: Gate 1 (2028-12) → Gate 2 (2029-03, after FY2028 audit) → Gate 3 (underwriter bake-off). Korea is a PCAOB-accessible jurisdiction — not a Restrictive Market. Delaware corporation — cannot be an FPI; domestic-issuer reporting.' WHERE name='Nasdaq Listing 2029';

-- milestones
UPDATE app.ipo_milestones SET title='Transfer all FCC-related patents to MarineBio Group Inc.', rule_ref=NULL WHERE code='F-IP-01';
UPDATE app.ipo_milestones SET title='Record assignments at KIPO / USPTO / EPO / JPO', rule_ref=NULL WHERE code='F-IP-02';
UPDATE app.ipo_milestones SET title='File JP opposition', rule_ref=NULL WHERE code='F-IP-03';
UPDATE app.ipo_milestones SET title='Build patent register — family_role, expiration, maintenance dues', rule_ref=NULL WHERE code='F-IP-04';
UPDATE app.ipo_milestones SET title='Compute remaining life of material patents; review PTA/PTE', rule_ref=NULL WHERE code='F-IP-05';
UPDATE app.ipo_milestones SET title='Written agency agreement with Marinepad (fees, voting, economic interest)', rule_ref='Reg S-K Item 404' WHERE code='F-LG-01';
UPDATE app.ipo_milestones SET title='Clean up Delaware charter, bylaws and shareholder agreement', rule_ref=NULL WHERE code='F-LG-02';
UPDATE app.ipo_milestones SET title='Cap table clean-up, stock option plan, 409A valuation', rule_ref=NULL WHERE code='F-LG-03';
UPDATE app.ipo_milestones SET title='Convert books to US GAAP; monthly close in place', rule_ref=NULL WHERE code='F-FA-01';
UPDATE app.ipo_milestones SET title='Start commercial production for Moorim 9,000 t order', rule_ref=NULL WHERE code='F-CM-01';
UPDATE app.ipo_milestones SET title='Deliver 9,000 t order; Moorim commercial-scale validation and quality approval', rule_ref=NULL WHERE code='C-CM-01';
UPDATE app.ipo_milestones SET title='Sign definitive license agreement with global filler manufacturer', rule_ref=NULL WHERE code='C-CM-02';
UPDATE app.ipo_milestones SET title='Fix royalty reporting and audit-rights clauses (statements, Net Sales definition, audit right, record retention)', rule_ref='ASC 606' WHERE code='C-CM-03';
UPDATE app.ipo_milestones SET title='Negotiate minimum volume / minimum royalty, exclusivity scope, termination', rule_ref=NULL WHERE code='C-CM-04';
UPDATE app.ipo_milestones SET title='Agree licensee conversion of its own plants to FCC production', rule_ref=NULL WHERE code='C-CM-05';
UPDATE app.ipo_milestones SET title='Receive licensee rollout plan → write and approve Management scenario', rule_ref=NULL WHERE code='C-CM-06';
UPDATE app.ipo_milestones SET title='Start commercial supply for tissue grades', rule_ref=NULL WHERE code='C-CM-07';
UPDATE app.ipo_milestones SET title='Document ASC 606 royalty revenue-recognition policy', rule_ref='ASC 606-10-55-65' WHERE code='C-FA-01';
UPDATE app.ipo_milestones SET title='First royalty recognized with auditable settlement evidence', rule_ref=NULL WHERE code='C-FA-02';
UPDATE app.ipo_milestones SET title='Royalty ledger live — minimum / due / received / recognized kept separate', rule_ref=NULL WHERE code='C-FA-03';
UPDATE app.ipo_milestones SET title='Interview and engage PCAOB-registered auditor', rule_ref=NULL WHERE code='A-FA-01';
UPDATE app.ipo_milestones SET title='Receive FY2027 audit report', rule_ref=NULL WHERE code='A-FA-02';
UPDATE app.ipo_milestones SET title='Receive FY2028 audit report', rule_ref=NULL WHERE code='A-FA-03';
UPDATE app.ipo_milestones SET title='Quarterly review process in place', rule_ref=NULL WHERE code='A-FA-04';
UPDATE app.ipo_milestones SET title='Hire CFO with US public-company experience', rule_ref=NULL WHERE code='A-FA-05';
UPDATE app.ipo_milestones SET title='SOX 302 documentation and ICFR gap remediation', rule_ref='SOX 302/404(a)' WHERE code='A-FA-06';
UPDATE app.ipo_milestones SET title='Korea–US transfer pricing documentation', rule_ref=NULL WHERE code='A-FA-07';
UPDATE app.ipo_milestones SET title='Complete ASC 810 / VIE assessment of Marinepad', rule_ref='ASC 810' WHERE code='A-FA-08';
UPDATE app.ipo_milestones SET title='Domestic-issuer (non-FPI) reporting set-up — 10-K / 10-Q / 8-K / Proxy', rule_ref=NULL WHERE code='A-FA-09';
UPDATE app.ipo_milestones SET title='Secure a second licensee (concentration relief)', rule_ref=NULL WHERE code='A-CM-01';
UPDATE app.ipo_milestones SET title='Identify and interview independent director candidates', rule_ref=NULL WHERE code='G-LG-01';
UPDATE app.ipo_milestones SET title='Appoint audit committee member #1 (listing-date requirement)', rule_ref='5615(b)(1)' WHERE code='G-AC-01';
UPDATE app.ipo_milestones SET title='Appoint audit committee member #2 (90-day requirement, met early)', rule_ref='5615(b)(1)' WHERE code='G-AC-02';
UPDATE app.ipo_milestones SET title='Appoint audit committee member #3 (1-year requirement, met early)', rule_ref='5615(b)(1)' WHERE code='G-AC-03';
UPDATE app.ipo_milestones SET title='Majority-independent board before listing (no phase-in)', rule_ref='5605(b)' WHERE code='G-BD-01';
UPDATE app.ipo_milestones SET title='Compensation committee — two or more independent directors', rule_ref='5605(d)' WHERE code='G-LG-02';
UPDATE app.ipo_milestones SET title='Independent-director-led nomination process', rule_ref='5605(e)' WHERE code='G-LG-03';
UPDATE app.ipo_milestones SET title='Adopt code of conduct', rule_ref='5610' WHERE code='G-LG-04';
UPDATE app.ipo_milestones SET title='Related-party review procedure and whistleblower hotline', rule_ref='5630' WHERE code='G-LG-05';
UPDATE app.ipo_milestones SET title='Bylaw clean-up — 33⅓% quorum, no disparate voting rights', rule_ref='5620(c)/5640' WHERE code='G-LG-06';
UPDATE app.ipo_milestones SET title='Bind D&O insurance', rule_ref=NULL WHERE code='G-LG-07';
UPDATE app.ipo_milestones SET title='Secure cash runway through IPO plus contingency buffer (any instrument)', rule_ref=NULL WHERE code='K-CP-01';
UPDATE app.ipo_milestones SET title='Underwriter longlist and initial outreach', rule_ref=NULL WHERE code='K-CP-02';
UPDATE app.ipo_milestones SET title='Underwriter bake-off and selection', rule_ref=NULL WHERE code='K-CP-03';
UPDATE app.ipo_milestones SET title='Engage securities counsel and transfer agent', rule_ref=NULL WHERE code='K-CP-04';
UPDATE app.ipo_milestones SET title='Fix offering structure — gross proceeds $20–30M; MVUPHS $15M from offering proceeds only', rule_ref='5505(a)' WHERE code='K-CP-05';
UPDATE app.ipo_milestones SET title='Reverse split / par adjustment for $4+ offering price', rule_ref='5505(a)' WHERE code='K-CP-06';
UPDATE app.ipo_milestones SET title='Plan for 300 round-lot holders (150+ holding $2,500+ unrestricted)', rule_ref='5505(a)' WHERE code='K-CP-07';
UPDATE app.ipo_milestones SET title='Gate 1 — Preliminary Go/No-Go (FY2028 preliminary figures)', rule_ref=NULL WHERE code='D-GO-01';
UPDATE app.ipo_milestones SET title='Gate 2 — Final Internal Go/No-Go (FY2028 audit reflected)', rule_ref=NULL WHERE code='D-GO-02';
UPDATE app.ipo_milestones SET title='Gate 3 — Underwriter bake-off validation', rule_ref=NULL WHERE code='D-GO-03';
UPDATE app.ipo_milestones SET title='Reserve Nasdaq ticker symbol', rule_ref=NULL WHERE code='S-CP-01';
UPDATE app.ipo_milestones SET title='Draft S-1 (Business, Risk Factors, MD&A, Legal Proceedings)', rule_ref=NULL WHERE code='S-CP-02';
UPDATE app.ipo_milestones SET title='Confidential draft S-1 submission', rule_ref='Securities Act 6(e)' WHERE code='S-CP-03';
UPDATE app.ipo_milestones SET title='Respond to SEC comments (2–3 rounds)', rule_ref=NULL WHERE code='S-CP-04';
UPDATE app.ipo_milestones SET title='File Nasdaq listing application, agreement and governance certification; 4–6 week review', rule_ref='5505' WHERE code='S-CP-05';
UPDATE app.ipo_milestones SET title='Public S-1 filing — at least 15 days before roadshow', rule_ref='JOBS Act' WHERE code='S-CP-06';
UPDATE app.ipo_milestones SET title='Secure three registered market makers', rule_ref='5505(a)' WHERE code='S-CP-07';
UPDATE app.ipo_milestones SET title='IR website, disclosure controls and Reg FD policy live', rule_ref='5250(d)' WHERE code='S-IR-01';
UPDATE app.ipo_milestones SET title='Roadshow and book-building', rule_ref=NULL WHERE code='L-CP-01';
UPDATE app.ipo_milestones SET title='Pricing and S-1 effectiveness', rule_ref=NULL WHERE code='L-CP-02';
UPDATE app.ipo_milestones SET title='Nasdaq listing and first trade', rule_ref=NULL WHERE code='L-CP-03';
UPDATE app.ipo_milestones SET title='Switch to continued-listing (5550) monitoring', rule_ref='5550' WHERE code='L-CP-04';
UPDATE app.ipo_milestones SET title='First 10-Q after listing', rule_ref=NULL WHERE code='L-FA-01';
UPDATE app.ipo_milestones SET title='First 10-K and management ICFR assessment', rule_ref='SOX 404(a)' WHERE code='L-FA-02';
UPDATE app.ipo_milestones SET title='First annual shareholder meeting after listing', rule_ref='5620(a)' WHERE code='L-LG-01';

-- gates
UPDATE app.ipo_readiness_gates SET question='Can the three Equity Standard tests (stockholders'' equity $5M, MVUPHS $15M, 2-year operating history) be met at the offering?', pass_condition='MVUPHS from offering proceeds only; equity measured after the offering' WHERE code='L1-01';
UPDATE app.ipo_readiness_gates SET question='Can we reach 300 unrestricted round-lot holders, 150+ each holding $2,500+?', pass_condition='Underwriter allocation plan; exclude locked-up shares' WHERE code='L1-02';
UPDATE app.ipo_readiness_gates SET question='Does a $4+ offering price structure hold?', pass_condition='Pre-money basis after any reverse split' WHERE code='L1-03';
UPDATE app.ipo_readiness_gates SET question='Are three market makers secured?', pass_condition='Registration confirmed' WHERE code='L1-04';
UPDATE app.ipo_readiness_gates SET question='Is a PCAOB auditor engaged and are FY2027 and FY2028 audits complete on schedule?', pass_condition='Two audited fiscal years' WHERE code='L2-01';
UPDATE app.ipo_readiness_gates SET question='Has the auditor accepted the royalty revenue-recognition policy?', pass_condition='ASC 606 basis documented' WHERE code='L2-02';
UPDATE app.ipo_readiness_gates SET question='Are licensee royalty statements verified against independent records?', pass_condition='v_royalty_reconciliation clean for every period' WHERE code='L2-03';
UPDATE app.ipo_readiness_gates SET question='Is the difference between ledger-recognized and GAAP royalty revenue explained?', pass_condition='v_royalty_vs_gaap reconciliation_difference documented' WHERE code='L2-04';
UPDATE app.ipo_readiness_gates SET question='Is a CFO in place, ICFR gaps closed, quarterly reviews running?', pass_condition='SOX 302 documentation complete' WHERE code='L2-05';
UPDATE app.ipo_readiness_gates SET question='Are transfer-pricing files and domestic-issuer reporting ready?', pass_condition=NULL WHERE code='L2-06';
UPDATE app.ipo_readiness_gates SET question='Is Moorim commercial production validated with repeat orders?', pass_condition='Two or more consecutive quarters of orders plus quality approval' WHERE code='L3-01';
UPDATE app.ipo_readiness_gates SET question='Has the global filler manufacturer converted its own plants to FCC?', pass_condition='Number of converted plants and start dates' WHERE code='L3-02';
UPDATE app.ipo_readiness_gates SET question='Is royalty recognized as recurring revenue?', pass_condition='Four or more consecutive quarters' WHERE code='L3-03';
UPDATE app.ipo_readiness_gates SET question='Is the Management scenario approved on the basis of the licensee''s rollout plan?', pass_condition='ipo_scenarios.approved_at' WHERE code='L3-04';
UPDATE app.ipo_readiness_gates SET question='Are actuals within the planning-default scenario range?', pass_condition='v_ipo_scenario_royalty.actual_vs_range ≠ below_low' WHERE code='L3-05';
UPDATE app.ipo_readiness_gates SET question='Is licensee concentration acceptable?', pass_condition='Two or more licensees, or a documented mitigation' WHERE code='L3-06';
UPDATE app.ipo_readiness_gates SET question='Are all material patents owned by MBG Inc. with assignments recorded in every jurisdiction?', pass_condition='v_patent_horizon.unrecorded_material_count = 0' WHERE code='L4-01';
UPDATE app.ipo_readiness_gates SET question='Does the remaining life of material patents support the royalty stream?', pass_condition='min_remaining_years; foundational vs improvement disclosed separately' WHERE code='L4-02';
UPDATE app.ipo_readiness_gates SET question='Does the license contain audit rights, reporting, minimum volume and termination protections?', pass_condition='license_terms reporting/protection all done' WHERE code='L4-03';
UPDATE app.ipo_readiness_gates SET question='Is the Marinepad relationship documented and the VIE assessment complete?', pass_condition='Signed agreement plus accountants'' memo' WHERE code='L4-04';
UPDATE app.ipo_readiness_gates SET question='Are pending patent proceedings (EPO TPO, JP opposition) organized for Legal Proceedings disclosure?', pass_condition='Status log by date' WHERE code='L4-05';
UPDATE app.ipo_readiness_gates SET question='Are audit committee member #1 and independent directors confirmed as of the listing date?', pass_condition='5615(b)(1) listing-date requirement' WHERE code='L5-01';
UPDATE app.ipo_readiness_gates SET question='Will the 3-member audit committee, 2-member compensation committee and nomination process be complete before listing (no phase-in)?', pass_condition='Internal target' WHERE code='L5-02';
UPDATE app.ipo_readiness_gates SET question='Are the code of conduct, related-party procedure, bylaws and D&O in place?', pass_condition=NULL WHERE code='L5-03';
UPDATE app.ipo_readiness_gates SET question='Is cash runway through the IPO plus a buffer secured?', pass_condition='Any instrument — the test is runway, not a round called Series A' WHERE code='L6-01';
UPDATE app.ipo_readiness_gates SET question='Has an underwriter confirmed firm-commitment intent?', pass_condition='The effective final judge' WHERE code='L6-02';
UPDATE app.ipo_readiness_gates SET question='Does a $20–30M gross-proceeds structure hold?', pass_condition='Do not size to the $15M regulatory floor' WHERE code='L6-03';
UPDATE app.ipo_readiness_gates SET question='Will the holder base sustain aftermarket liquidity and continued-listing tests ($1 bid, $2.5M equity)?', pass_condition=NULL WHERE code='L6-04';

-- metrics
UPDATE app.ipo_metrics SET label='Stockholders'' equity', source_hint='Audit / review report' WHERE code='stockholders_equity';
UPDATE app.ipo_metrics SET label='Market value of unrestricted publicly held shares', source_hint='Offering structure' WHERE code='mvuphs';
UPDATE app.ipo_metrics SET label='Unrestricted publicly held shares', source_hint='Cap table' WHERE code='unrestricted_public_shares';
UPDATE app.ipo_metrics SET label='Unrestricted round-lot holders', source_hint='Transfer agent / underwriter' WHERE code='round_lot_holders';
UPDATE app.ipo_metrics SET label='Holders with $2,500+ unrestricted', source_hint='Transfer agent / underwriter' WHERE code='qualified_round_lot_holders';
UPDATE app.ipo_metrics SET label='Registered market makers', source_hint='Nasdaq' WHERE code='market_makers';
UPDATE app.ipo_metrics SET label='Bid price', source_hint='Offering price / market' WHERE code='bid_price';
UPDATE app.ipo_metrics SET label='Operating history', source_hint='Corporate registration' WHERE code='operating_history_years';
UPDATE app.ipo_metrics SET label='Audited fiscal years', source_hint='Audit reports' WHERE code='audited_fiscal_years';
UPDATE app.ipo_metrics SET label='Independent audit committee members', source_hint='Board resolution' WHERE code='audit_committee_indep';
UPDATE app.ipo_metrics SET label='Independent compensation committee members', source_hint='Board resolution' WHERE code='comp_committee_indep';
UPDATE app.ipo_metrics SET label='Independent directors on board', source_hint='Board composition' WHERE code='board_indep_pct';
UPDATE app.ipo_metrics SET label='Annual commercial FCC volume', source_hint='Licensee statements' WHERE code='commercial_volume_tons';
UPDATE app.ipo_metrics SET label='Licensed production capacity', source_hint='Licensee' WHERE code='licensed_capacity_tons';
UPDATE app.ipo_metrics SET label='Active licensees', source_hint='Contracts' WHERE code='active_licensees';
UPDATE app.ipo_metrics SET label='Paper mills in commercial supply', source_hint='Licensee reports' WHERE code='commercial_paper_customers';
UPDATE app.ipo_metrics SET label='Largest licensee share of revenue', source_hint='Royalty ledger' WHERE code='largest_licensee_pct';
UPDATE app.ipo_metrics SET label='Annualized royalty run-rate', source_hint='Royalty ledger' WHERE code='royalty_run_rate';
UPDATE app.ipo_metrics SET label='GAAP royalty revenue (closed / audited)', source_hint='Close / audit report' WHERE code='gaap_royalty_revenue';
UPDATE app.ipo_metrics SET label='Royalty cash received', source_hint='Bank / royalty ledger' WHERE code='royalty_cash_received';
UPDATE app.ipo_metrics SET label='Contracted minimum payment (annual)', source_hint='License agreement' WHERE code='contracted_minimum_payment';
UPDATE app.ipo_metrics SET label='Royalty periods audit-verified', source_hint='v_royalty_metrics' WHERE code='royalty_verified_pct';
UPDATE app.ipo_metrics SET label='Cash', source_hint='Bank' WHERE code='cash';
UPDATE app.ipo_metrics SET label='Monthly burn', source_hint='Close' WHERE code='monthly_burn';
UPDATE app.ipo_metrics SET label='Cash runway', source_hint='cash / monthly_burn' WHERE code='cash_runway_months';
UPDATE app.ipo_metrics SET label='Material patent minimum remaining life', source_hint='v_patent_horizon' WHERE code='material_patent_min_remaining_years';
UPDATE app.ipo_metrics SET label='IPO gross proceeds (planned)', source_hint='Underwriter' WHERE code='ipo_gross_proceeds';

-- listing criteria notes
UPDATE app.ipo_listing_criteria SET note=NULL WHERE code='cm_eq_se';
UPDATE app.ipo_listing_criteria SET note='IPO listings: offering proceeds only' WHERE code='cm_mvuphs';
UPDATE app.ipo_listing_criteria SET note=NULL WHERE code='cm_uphs';
UPDATE app.ipo_listing_criteria SET note=NULL WHERE code='cm_round_lot';
UPDATE app.ipo_listing_criteria SET note='At least half of 300, each $2,500+' WHERE code='cm_qualified_round_lot';
UPDATE app.ipo_listing_criteria SET note=NULL WHERE code='cm_market_makers';
UPDATE app.ipo_listing_criteria SET note=NULL WHERE code='cm_bid_price';
UPDATE app.ipo_listing_criteria SET note='Equity Standard only' WHERE code='cm_op_history';
UPDATE app.ipo_listing_criteria SET note=NULL WHERE code='gov_audit_cmte';
UPDATE app.ipo_listing_criteria SET note=NULL WHERE code='gov_comp_cmte';
UPDATE app.ipo_listing_criteria SET note=NULL WHERE code='gov_board_majority';
UPDATE app.ipo_listing_criteria SET note='EGC: two fiscal years. Sets the auditor-engagement deadline' WHERE code='sec_audited_years';
UPDATE app.ipo_listing_criteria SET note='[Alternate] Net Income / MVLS' WHERE code='alt_ni_se';
UPDATE app.ipo_listing_criteria SET note='[Uplist]' WHERE code='gm_se';
UPDATE app.ipo_listing_criteria SET note='[Uplist]' WHERE code='gm_uphs';
UPDATE app.ipo_listing_criteria SET note='[Uplist]' WHERE code='gm_round_lot';
UPDATE app.ipo_listing_criteria SET note='[Uplist]' WHERE code='gm_mvuphs';

-- internal KPI rationale
UPDATE app.ipo_internal_kpis SET rationale='Reduce single-licensee dependence' WHERE code='kpi_active_licensees';
UPDATE app.ipo_internal_kpis SET rationale='100% dependence is risk factor #1' WHERE code='kpi_largest_licensee';
UPDATE app.ipo_internal_kpis SET rationale='Instrument-agnostic' WHERE code='kpi_cash_runway';
UPDATE app.ipo_internal_kpis SET rationale='End of royalty stream = end of valuation' WHERE code='kpi_patent_life';
UPDATE app.ipo_internal_kpis SET rationale='Target completion before listing date' WHERE code='kpi_board_indep';
UPDATE app.ipo_internal_kpis SET rationale='One unverified period is an audit issue' WHERE code='kpi_royalty_verified';
UPDATE app.ipo_internal_kpis SET rationale='Do not size to the $15M floor' WHERE code='kpi_gross_proceeds';

-- assumptions
UPDATE app.ipo_assumptions SET source_note='Planning assumption — premium over PCC/GCC' WHERE code='fcc_net_sales_per_ton';
UPDATE app.ipo_assumptions SET source_note='Negotiation range, low end' WHERE code='royalty_pct_low';
UPDATE app.ipo_assumptions SET source_note='Planning base' WHERE code='royalty_pct_base';
UPDATE app.ipo_assumptions SET source_note='Negotiation range, high end' WHERE code='royalty_pct_high';
UPDATE app.ipo_assumptions SET source_note='Management reference value. Not a KPI. Sanity-check against derived $/t' WHERE code='reference_royalty_per_ton';

-- scenarios
UPDATE app.ipo_scenarios SET name='Conservative — sequential adoption', basis='Paper mills adopt one at a time after re-validation; 2–3 year adoption cycle. Price and rate from ipo_assumptions.', note='Planning default. Downside surprises cost asymmetrically more; revising upward costs nothing.' WHERE code='conservative';
UPDATE app.ipo_scenarios SET name='Management — based on commercial results', basis='Written after 2026-10 commercialization results and the licensee rollout plan (C-CM-06).', note='Empty is correct. Not used as any forecast until approved_at is set.' WHERE code='management';
UPDATE app.ipo_scenarios SET name='Global Rollout — licensee plant conversion', basis='Based on the licensee''s official rollout document; step increases per converted plant.', note='Not filled without a licensee document.' WHERE code='global_rollout';

-- decision schedule
UPDATE app.ipo_decision_schedule SET name='Gate 1 — Preliminary Go/No-Go', purpose='Direction call on FY2028 preliminary results, commercialization and run-rate', inputs='v_ipo_dashboard, v_ipo_gate_readiness, v_ipo_scenario_royalty' WHERE stage='gate1';
UPDATE app.ipo_decision_schedule SET name='Gate 2 — Final Internal Go/No-Go', purpose='Confirm with FY2028 PCAOB audit results', inputs='A-FA-03 audit report, v_ipo_listing_status' WHERE stage='gate2';
UPDATE app.ipo_decision_schedule SET name='Gate 3 — Underwriter Validation', purpose='Capital-market feasibility via underwriter bake-off', inputs='Firm-commitment letters of intent' WHERE stage='gate3';

-- license term checklist: template rows (licensee_party_id IS NULL) by sort_order
UPDATE app.license_terms SET category='economics', item='Royalty rate — 5–10% of Net Sales' WHERE licensee_party_id IS NULL AND sort_order=1;
UPDATE app.license_terms SET category='economics', item='FCC price assumption and $/t derivation' WHERE licensee_party_id IS NULL AND sort_order=2;
UPDATE app.license_terms SET category='economics', item='Minimum annual royalty / minimum volume' WHERE licensee_party_id IS NULL AND sort_order=3;
UPDATE app.license_terms SET category='economics', item='Upfront license fee' WHERE licensee_party_id IS NULL AND sort_order=4;
UPDATE app.license_terms SET category='economics', item='Milestone payments' WHERE licensee_party_id IS NULL AND sort_order=5;
UPDATE app.license_terms SET category='scope', item='Territory' WHERE licensee_party_id IS NULL AND sort_order=6;
UPDATE app.license_terms SET category='scope', item='Paper grades — tissue included?' WHERE licensee_party_id IS NULL AND sort_order=7;
UPDATE app.license_terms SET category='scope', item='Exclusivity and conditions to keep it' WHERE licensee_party_id IS NULL AND sort_order=8;
UPDATE app.license_terms SET category='scope', item='Sublicensing rights and reporting' WHERE licensee_party_id IS NULL AND sort_order=9;
UPDATE app.license_terms SET category='protection', item='Minimum commercialization obligation' WHERE licensee_party_id IS NULL AND sort_order=10;
UPDATE app.license_terms SET category='protection', item='Loss of exclusivity on under-performance' WHERE licensee_party_id IS NULL AND sort_order=11;
UPDATE app.license_terms SET category='protection', item='Termination' WHERE licensee_party_id IS NULL AND sort_order=12;
UPDATE app.license_terms SET category='protection', item='Non-compete / no design-around' WHERE licensee_party_id IS NULL AND sort_order=13;
UPDATE app.license_terms SET category='reporting', item='Quarterly royalty statement obligation and deadline' WHERE licensee_party_id IS NULL AND sort_order=14;
UPDATE app.license_terms SET category='reporting', item='Reported items — production / sales / Net Sales' WHERE licensee_party_id IS NULL AND sort_order=15;
UPDATE app.license_terms SET category='reporting', item='Net Sales definition — affiliates, transfer pricing, rebates, freight, taxes' WHERE licensee_party_id IS NULL AND sort_order=16;
UPDATE app.license_terms SET category='reporting', item='Toll-manufacturing formula where no sales price exists' WHERE licensee_party_id IS NULL AND sort_order=17;
UPDATE app.license_terms SET category='reporting', item='MBG audit right — at least annually, designated accounting firm' WHERE licensee_party_id IS NULL AND sort_order=18;
UPDATE app.license_terms SET category='reporting', item='Record retention period' WHERE licensee_party_id IS NULL AND sort_order=19;
UPDATE app.license_terms SET category='reporting', item='Interest and cost shifting on under-reporting' WHERE licensee_party_id IS NULL AND sort_order=20;
UPDATE app.license_terms SET category='ip', item='Licensed patent list and jurisdictions' WHERE licensee_party_id IS NULL AND sort_order=21;
UPDATE app.license_terms SET category='ip', item='Ownership of improvements and new filings' WHERE licensee_party_id IS NULL AND sort_order=22;
UPDATE app.license_terms SET category='ip', item='Enforcement lead and cost sharing' WHERE licensee_party_id IS NULL AND sort_order=23;
UPDATE app.license_terms SET category='ip', item='Remaining patent life and post-expiry terms' WHERE licensee_party_id IS NULL AND sort_order=24;

-- de-duplicate template rows (UNIQUE ignores NULL licensee_party_id)
DELETE FROM app.license_terms a USING app.license_terms b
 WHERE a.licensee_party_id IS NULL AND b.licensee_party_id IS NULL
   AND a.organization_id = b.organization_id AND a.category = b.category AND a.item = b.item
   AND a.id > b.id;

-- advisor pipeline description
UPDATE app.pipelines SET description = 'Underwriters, PCAOB auditor, securities counsel, transfer agent, market makers, IR firm. Engaged is not the end — the work starts after engagement.'
 WHERE code = 'nasdaq_advisors';

COMMIT;

-- Verify
-- SELECT code, title FROM app.ipo_milestones WHERE title ~ '[가-힣]';   -- expect 0 rows
-- SELECT code, question FROM app.ipo_readiness_gates WHERE question ~ '[가-힣]';
