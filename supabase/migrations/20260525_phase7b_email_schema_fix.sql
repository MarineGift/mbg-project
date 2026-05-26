-- =============================================================================
-- Phase 7-b: email schema fix
-- File: supabase/migrations/20260525_phase7b_email_schema_fix.sql
-- Branch: feature/stage23-urm-cleanup
-- =============================================================================
-- Scope (after Step 1/1-b/1-c diagnosis):
--   1. CREATE 3 missing tables: org_members, party_contacts, email_signatures
--   2. ALTER email_sequence_sends: add bounce_reason, delivered_at, updated_at
--   3. RLS policies + indexes for new tables
--   4. updated_at triggers for email_signatures and email_sequence_sends
--
-- NOT touched:
--   - app.communications     (50 cols already present; only code-side fix)
--   - app.email_whitelist    (only code-side fix: value -> pattern)
--   - app.email_templates    (no drift)
--   - app.email_tracking     (no drift)
--   - app.email_tracking_events (no drift)
--   - email_sequences / enrollments / steps (RPC-only, no .from() in code)
--   - email-attachments      (storage bucket, not a table)
--
-- JWT claim note:
--   The 013 migration installs a custom_access_token_hook that injects
--   organization_id into the access token. This file uses
--     auth.jwt() -> 'app_metadata' ->> 'organization_id'
--   as the canonical claim path. If the hook injects at the top level instead,
--   change to auth.jwt() ->> 'organization_id' in all four policies below.
-- =============================================================================

BEGIN;

-- =============================================================================
-- 1.1  app.org_members  (user <-> organization membership)
-- =============================================================================

CREATE TABLE app.org_members (
    user_id         UUID         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    organization_id UUID         NOT NULL REFERENCES app.organizations(id) ON DELETE CASCADE,
    role            TEXT         NOT NULL DEFAULT 'member',
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, organization_id)
);

CREATE INDEX ix_org_members_org ON app.org_members(organization_id);

ALTER TABLE app.org_members ENABLE ROW LEVEL SECURITY;

-- A user can read their own membership row, plus any membership row of an org
-- they currently belong to (from the JWT claim).
CREATE POLICY org_members_select ON app.org_members
    FOR SELECT
    USING (
        user_id = auth.uid()
        OR organization_id = (auth.jwt() -> 'app_metadata' ->> 'organization_id')::uuid
    );

-- Insert/update/delete intentionally not exposed via RLS.
-- Membership changes should go through an admin RPC (to be added separately).

-- =============================================================================
-- 1.2  app.party_contacts  (party <-> contact join with is_primary)
-- =============================================================================

CREATE TABLE app.party_contacts (
    party_id   UUID         NOT NULL REFERENCES app.parties(id)   ON DELETE CASCADE,
    contact_id UUID         NOT NULL REFERENCES app.contacts(id)  ON DELETE CASCADE,
    is_primary BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (party_id, contact_id)
);

-- At most one primary contact per party
CREATE UNIQUE INDEX uq_party_contacts_one_primary
    ON app.party_contacts(party_id)
    WHERE is_primary = TRUE;

CREATE INDEX ix_party_contacts_contact ON app.party_contacts(contact_id);

ALTER TABLE app.party_contacts ENABLE ROW LEVEL SECURITY;

-- Isolation via the parent party's organization_id
CREATE POLICY party_contacts_org_isolation ON app.party_contacts
    FOR ALL
    USING (
        party_id IN (
            SELECT id FROM app.parties
            WHERE organization_id = (auth.jwt() -> 'app_metadata' ->> 'organization_id')::uuid
        )
    )
    WITH CHECK (
        party_id IN (
            SELECT id FROM app.parties
            WHERE organization_id = (auth.jwt() -> 'app_metadata' ->> 'organization_id')::uuid
        )
    );

-- =============================================================================
-- 1.3  app.email_signatures  (org-scoped HTML signatures, one default per org)
-- =============================================================================

CREATE TABLE app.email_signatures (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID         NOT NULL REFERENCES app.organizations(id) ON DELETE CASCADE,
    name            TEXT         NOT NULL,
    html_content    TEXT         NOT NULL,
    is_default      BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX ix_email_signatures_org ON app.email_signatures(organization_id);

-- One default per org
CREATE UNIQUE INDEX uq_email_signatures_one_default
    ON app.email_signatures(organization_id)
    WHERE is_default = TRUE;

ALTER TABLE app.email_signatures ENABLE ROW LEVEL SECURITY;

CREATE POLICY email_signatures_org_isolation ON app.email_signatures
    FOR ALL
    USING (organization_id = (auth.jwt() -> 'app_metadata' ->> 'organization_id')::uuid)
    WITH CHECK (organization_id = (auth.jwt() -> 'app_metadata' ->> 'organization_id')::uuid);

-- Auto-maintain updated_at
CREATE OR REPLACE FUNCTION app.tg_email_signatures_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_email_signatures_set_updated_at
    BEFORE UPDATE ON app.email_signatures
    FOR EACH ROW
    EXECUTE FUNCTION app.tg_email_signatures_set_updated_at();

-- =============================================================================
-- 2.  ALTER app.email_sequence_sends
--     Add bounce_reason, delivered_at, updated_at (used by sequence-processor)
-- =============================================================================

ALTER TABLE app.email_sequence_sends
    ADD COLUMN IF NOT EXISTS bounce_reason TEXT,
    ADD COLUMN IF NOT EXISTS delivered_at  TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS updated_at    TIMESTAMPTZ NOT NULL DEFAULT now();

-- Auto-maintain updated_at
CREATE OR REPLACE FUNCTION app.tg_email_sequence_sends_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_email_sequence_sends_set_updated_at
    ON app.email_sequence_sends;

CREATE TRIGGER trg_email_sequence_sends_set_updated_at
    BEFORE UPDATE ON app.email_sequence_sends
    FOR EACH ROW
    EXECUTE FUNCTION app.tg_email_sequence_sends_set_updated_at();

COMMIT;

-- =============================================================================
-- Post-apply verification queries (run manually after the migration):
-- =============================================================================
-- SELECT table_name FROM information_schema.tables
--  WHERE table_schema = 'app'
--    AND table_name IN ('org_members','party_contacts','email_signatures')
--  ORDER BY table_name;
--
-- SELECT column_name FROM information_schema.columns
--  WHERE table_schema='app' AND table_name='email_sequence_sends'
--    AND column_name IN ('bounce_reason','delivered_at','updated_at')
--  ORDER BY column_name;
--
-- SELECT polname, polrelid::regclass FROM pg_policy
--  WHERE polrelid::regclass::text LIKE 'app.%'
--    AND polname LIKE '%org_isolation%' OR polname LIKE 'org_members%';
-- =============================================================================
