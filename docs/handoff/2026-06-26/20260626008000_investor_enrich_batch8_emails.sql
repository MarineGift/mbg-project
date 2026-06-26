-- 20260626008000_investor_enrich_batch8_emails.sql
-- =============================================================================
-- Batch 8: 4 more general inquiry emails confirmed.
-- =============================================================================

-- 1) Breakout Ventures  [EMAIL]
-- Source: Crunchbase Contact Email + firm thesis explicitly includes "materials"
-- ("intersections of technology, biology, materials, and energy"). FCC fit.
UPDATE app.parties SET
  email = COALESCE(NULLIF(email,''), 'contact@breakout.vc')
WHERE id = 'f49a8284-70c1-47c2-9473-5a0e765c5b1b';

-- 2) G2 Venture Partners  [EMAIL]
-- Source: Crunchbase Contact Email field. Climate-tech, originated from KP
-- Green Growth Fund. Portfolio includes Lumafield (industrial CT scanning),
-- Fictiv (digital manufacturing) -- industrial sustainability fit.
UPDATE app.parties SET
  email = COALESCE(NULLIF(email,''), 'info@g2vp.com')
WHERE id = 'df44c86a-84fa-422f-929b-9f88ab159181';

-- 3) Creative Ventures  [EMAIL + STREET]
-- Source: creativeventures.vc/contact + Crunchbase. Thesis: "industrial,
-- agri-food, healthcare, automation, automotive, construction, logistics,
-- manufacturing, climate, energy" -- broad industrial/materials fit.
-- Address: 44 Tehama St, San Francisco, CA 94105 (LinkedIn HQ + PitchBook).
UPDATE app.parties SET
  email          = COALESCE(NULLIF(email,''),          'invest@creativeventures.vc'),
  street_address = COALESCE(NULLIF(street_address,''), '44 Tehama Street')
WHERE id = 'f31631a0-aa56-46fc-8533-ff3f83c4a602';

-- 4) Spring Lane Capital  [EMAIL]
-- Source: springlanecapital.com/contact. Climate/sustainability "missing
-- middle" investor (project finance + growth equity hybrid).
-- Energy/water/food/waste focus -- weaker FCC fit but worth having.
UPDATE app.parties SET
  email = COALESCE(NULLIF(email,''), 'info@springlanecapital.com')
WHERE id = '8427e74a-e19e-48c3-b04c-707f0de7d2a5';

-- ----------------------------------------------------------------------------
-- Verification:
--   SELECT party_name, city, region, street_address, email
--     FROM app.parties
--    WHERE id IN (
--      'f49a8284-70c1-47c2-9473-5a0e765c5b1b',  -- Breakout
--      'df44c86a-84fa-422f-929b-9f88ab159181',  -- G2 VP
--      'f31631a0-aa56-46fc-8533-ff3f83c4a602',  -- Creative Ventures
--      '8427e74a-e19e-48c3-b04c-707f0de7d2a5'   -- Spring Lane
--    );
-- ----------------------------------------------------------------------------
--
-- Other firms checked this turn with NO public general email:
--   - ARCH Venture Partners (form only)
--   - Regeneration.VC (Airtable form; portfolio incl. Nature Coatings = materials)
--   - Ironspring Ventures (no public general email)
--   - Galvanize Climate Solutions (form only)
--   - KdT Ventures (life sci focus, individual emails only)
--   - Costanoa Ventures (AI/cyber focus, not FCC fit)
-- ----------------------------------------------------------------------------
