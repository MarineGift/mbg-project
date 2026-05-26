-- ============================================================
-- 030_calendar_integration.sql
-- 목적: Google Calendar + Microsoft Outlook 통합 캘린더 + 미팅 관리
-- 의존성: 001~010, 020~024
-- 관련 문서: docs/handoff/02_calendar_integration_design.md
-- ============================================================

-- ------------------------------------------------------------
-- 0. pgcrypto 확장 (이미 001에서 활성화됨 — 확인용)
-- ------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ------------------------------------------------------------
-- 1. ENUMs
-- ------------------------------------------------------------

DO $$ BEGIN
    CREATE TYPE app.calendar_provider AS ENUM ('google', 'microsoft', 'internal');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE app.calendar_sync_status AS ENUM (
        'pending', 'syncing', 'success', 'partial', 'failed'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE app.event_status AS ENUM ('confirmed', 'tentative', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE app.meeting_status AS ENUM (
        'scheduled', 'completed', 'cancelled', 'no_show', 'rescheduled'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE app.attendee_role AS ENUM (
        'organizer', 'required', 'optional', 'resource'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE app.attendee_response AS ENUM (
        'no_response', 'accepted', 'declined', 'tentative'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ------------------------------------------------------------
-- 2. calendar_connections — 사용자별 OAuth 연결
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS app.calendar_connections (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid        NOT NULL
                                REFERENCES app.organizations(id) ON DELETE CASCADE,
    user_id         uuid        NOT NULL
                                REFERENCES app.users(id) ON DELETE CASCADE,

    provider        app.calendar_provider NOT NULL,
    account_email   text        NOT NULL,
    account_name    text,

    -- 토큰은 pgp_sym_encrypt로 암호화 저장 (bytea)
    access_token    bytea       NOT NULL,
    refresh_token   bytea,
    token_type      text        DEFAULT 'Bearer',
    expires_at      timestamptz,
    scopes          text[]      NOT NULL DEFAULT '{}',

    -- 동기화 상태
    sync_token      text,           -- Google syncToken
    delta_link      text,           -- MS Graph deltaLink
    last_sync_at    timestamptz,
    last_sync_status app.calendar_sync_status DEFAULT 'pending',
    last_error      text,
    sync_failures   int         NOT NULL DEFAULT 0,

    is_active       boolean     NOT NULL DEFAULT true,
    is_primary      boolean     NOT NULL DEFAULT false,
    -- 한 user의 한 provider에 여러 계정 가능, primary는 하나

    created_at      timestamptz NOT NULL DEFAULT NOW(),
    updated_at      timestamptz NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_calendar_connections_user_provider_email
        UNIQUE (user_id, provider, account_email)
);

CREATE INDEX IF NOT EXISTS idx_calendar_connections_user
    ON app.calendar_connections (user_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_calendar_connections_org
    ON app.calendar_connections (organization_id);
CREATE INDEX IF NOT EXISTS idx_calendar_connections_sync_due
    ON app.calendar_connections (last_sync_at NULLS FIRST)
    WHERE is_active = true;

COMMENT ON TABLE app.calendar_connections IS
    '사용자별 외부 캘린더 OAuth 연결. 토큰은 pgcrypto로 암호화 저장';
COMMENT ON COLUMN app.calendar_connections.access_token IS
    'pgp_sym_encrypt(token, encryption_key) 형태. 복호화는 RPC 통해 service_role만';

DROP TRIGGER IF EXISTS trg_calendar_connections_updated_at ON app.calendar_connections;
CREATE TRIGGER trg_calendar_connections_updated_at
    BEFORE UPDATE ON app.calendar_connections
    FOR EACH ROW EXECUTE FUNCTION app.set_updated_at();

-- ------------------------------------------------------------
-- 3. calendar_events — 외부/내부 이벤트 통합 캐시
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS app.calendar_events (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid        NOT NULL
                                REFERENCES app.organizations(id) ON DELETE CASCADE,
    user_id         uuid        NOT NULL
                                REFERENCES app.users(id) ON DELETE CASCADE,
    connection_id   uuid        REFERENCES app.calendar_connections(id) ON DELETE CASCADE,
    -- connection_id NULL = internal-only 이벤트 (외부 sync 안 됨)

    source          app.calendar_provider NOT NULL,
    external_id     text,           -- Google eventId / MS event.id
    external_etag   text,           -- 충돌 감지

    title           text        NOT NULL DEFAULT '(No title)',
    description     text,
    location        text,           -- 물리적 주소 또는 빈 값
    meeting_url     text,           -- Google Meet / Teams / Zoom

    start_at        timestamptz NOT NULL,
    end_at          timestamptz NOT NULL,
    timezone        text        NOT NULL DEFAULT 'Asia/Seoul',
    is_all_day      boolean     NOT NULL DEFAULT false,

    -- 반복 이벤트
    recurrence_rule text,           -- RRULE string
    recurring_event_id text,        -- 부모 반복 시리즈 ID (외부 시스템)
    is_recurrence_instance boolean NOT NULL DEFAULT false,

    -- 참석자 (jsonb로 빠른 표시, 정규화는 meeting_attendees)
    attendees       jsonb       NOT NULL DEFAULT '[]',
    -- 예: [{"email":"a@b.com","name":"Anna","response":"accepted","role":"required"}]

    organizer_email text,
    organizer_name  text,

    status          app.event_status NOT NULL DEFAULT 'confirmed',
    visibility      text        DEFAULT 'default',
    -- 'default' | 'public' | 'private' | 'confidential'

    -- mbg 통합 매핑
    party_id        uuid        REFERENCES app.parties(id) ON DELETE SET NULL,
    engagement_id   uuid        REFERENCES app.engagements(id) ON DELETE SET NULL,
    meeting_id      uuid,       -- FK 추가는 meetings 테이블 생성 후
    auto_matched    boolean     NOT NULL DEFAULT false,
    match_confidence numeric(3,2),

    -- 외부 시스템 변경 시각
    external_created_at  timestamptz,
    external_modified_at timestamptz,

    created_at      timestamptz NOT NULL DEFAULT NOW(),
    updated_at      timestamptz NOT NULL DEFAULT NOW(),

    -- 같은 connection 내에서 external_id 유일
    CONSTRAINT uq_calendar_events_connection_external
        UNIQUE (connection_id, external_id),
    CONSTRAINT chk_calendar_events_time
        CHECK (end_at >= start_at)
);

CREATE INDEX IF NOT EXISTS idx_calendar_events_user_time
    ON app.calendar_events (user_id, start_at);
CREATE INDEX IF NOT EXISTS idx_calendar_events_org_time
    ON app.calendar_events (organization_id, start_at);
CREATE INDEX IF NOT EXISTS idx_calendar_events_party
    ON app.calendar_events (party_id) WHERE party_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_calendar_events_engagement
    ON app.calendar_events (engagement_id) WHERE engagement_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_calendar_events_unmatched
    ON app.calendar_events (user_id, start_at DESC)
    WHERE party_id IS NULL AND engagement_id IS NULL;

COMMENT ON TABLE app.calendar_events IS
    'Google/MS Calendar에서 sync해온 이벤트 + 내부 생성 이벤트의 통합 캐시';
COMMENT ON COLUMN app.calendar_events.auto_matched IS
    'party/engagement 자동 매칭으로 link됐는지 (수동 매핑과 구분)';

DROP TRIGGER IF EXISTS trg_calendar_events_updated_at ON app.calendar_events;
CREATE TRIGGER trg_calendar_events_updated_at
    BEFORE UPDATE ON app.calendar_events
    FOR EACH ROW EXECUTE FUNCTION app.set_updated_at();

-- ------------------------------------------------------------
-- 4. meetings — mbg-project 내부 미팅 (party-centric)
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS app.meetings (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid        NOT NULL
                                REFERENCES app.organizations(id) ON DELETE CASCADE,

    -- 누가 만들었는가 (캘린더 owner)
    user_id         uuid        NOT NULL
                                REFERENCES app.users(id) ON DELETE RESTRICT,

    -- 어떤 party와 (필수)
    party_id        uuid        NOT NULL
                                REFERENCES app.parties(id) ON DELETE CASCADE,
    engagement_id   uuid        REFERENCES app.engagements(id) ON DELETE SET NULL,

    title           text        NOT NULL,
    agenda          text,
    notes           text,
    ai_summary      text,           -- AI가 미팅 후 자동 요약 (Phase C)
    action_items    jsonb       NOT NULL DEFAULT '[]',
    -- 예: [{"text":"Send NDA","assignee_user_id":"...","due_at":"..."}]

    meeting_type    app.meeting_type DEFAULT 'discovery',
    meeting_mode    app.meeting_mode DEFAULT 'video_call',

    scheduled_at    timestamptz NOT NULL,
    duration_minutes int        NOT NULL DEFAULT 30,
    actual_started_at timestamptz,
    actual_ended_at timestamptz,

    location        text,
    meeting_url     text,

    status          app.meeting_status NOT NULL DEFAULT 'scheduled',

    -- 캘린더 이벤트 연결
    calendar_event_id uuid      REFERENCES app.calendar_events(id) ON DELETE SET NULL,

    -- 후속 task들 (생성 시 ID 보관)
    follow_up_task_ids uuid[]   NOT NULL DEFAULT '{}',

    created_at      timestamptz NOT NULL DEFAULT NOW(),
    updated_at      timestamptz NOT NULL DEFAULT NOW(),
    created_by      uuid        REFERENCES app.users(id) ON DELETE SET NULL,
    updated_by      uuid        REFERENCES app.users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_meetings_party_time
    ON app.meetings (party_id, scheduled_at DESC);
CREATE INDEX IF NOT EXISTS idx_meetings_engagement
    ON app.meetings (engagement_id) WHERE engagement_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_meetings_user_upcoming
    ON app.meetings (user_id, scheduled_at)
    WHERE status = 'scheduled';
CREATE INDEX IF NOT EXISTS idx_meetings_org_time
    ON app.meetings (organization_id, scheduled_at);

COMMENT ON TABLE app.meetings IS
    'party와 연결된 비즈니스 미팅. calendar_events의 부분집합 + 비즈니스 메타';

DROP TRIGGER IF EXISTS trg_meetings_updated_at ON app.meetings;
CREATE TRIGGER trg_meetings_updated_at
    BEFORE UPDATE ON app.meetings
    FOR EACH ROW EXECUTE FUNCTION app.set_updated_at();

-- meeting_id FK를 calendar_events에 뒤늦게 추가
ALTER TABLE app.calendar_events
    ADD CONSTRAINT fk_calendar_events_meeting
    FOREIGN KEY (meeting_id) REFERENCES app.meetings(id) ON DELETE SET NULL;

-- ------------------------------------------------------------
-- 5. meeting_attendees — 미팅 참석자 (contact 또는 외부 이메일)
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS app.meeting_attendees (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid        NOT NULL
                                REFERENCES app.organizations(id) ON DELETE CASCADE,
    meeting_id      uuid        NOT NULL
                                REFERENCES app.meetings(id) ON DELETE CASCADE,
    contact_id      uuid        REFERENCES app.contacts(id) ON DELETE SET NULL,
    -- contact_id NULL이면 외부 참석자

    email           text        NOT NULL,
    name            text,
    role            app.attendee_role NOT NULL DEFAULT 'required',
    response        app.attendee_response NOT NULL DEFAULT 'no_response',
    is_internal     boolean     NOT NULL DEFAULT false,
    -- true면 우리 조직 사람 (보통 user_id 보유)

    user_id         uuid        REFERENCES app.users(id) ON DELETE SET NULL,
    notes           text,

    created_at      timestamptz NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_meeting_attendees_meeting_email
        UNIQUE (meeting_id, email)
);

CREATE INDEX IF NOT EXISTS idx_meeting_attendees_meeting
    ON app.meeting_attendees (meeting_id);
CREATE INDEX IF NOT EXISTS idx_meeting_attendees_contact
    ON app.meeting_attendees (contact_id) WHERE contact_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_meeting_attendees_email
    ON app.meeting_attendees (lower(email));

-- ------------------------------------------------------------
-- 6. RLS — 010 패턴 + connection은 본인만
-- ------------------------------------------------------------

ALTER TABLE app.calendar_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.calendar_events       ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.meetings              ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.meeting_attendees     ENABLE ROW LEVEL SECURITY;

-- calendar_connections: 본인 것만 모든 작업
DROP POLICY IF EXISTS pol_calendar_connections_all ON app.calendar_connections;
CREATE POLICY pol_calendar_connections_all ON app.calendar_connections
    FOR ALL
    USING (
        organization_id = app.current_organization_id()
        AND user_id = app.current_user_id()
    )
    WITH CHECK (
        organization_id = app.current_organization_id()
        AND user_id = app.current_user_id()
    );

-- calendar_events: 본인 + 같은 조직 SELECT (협업 미팅 보기 위해)
DROP POLICY IF EXISTS pol_calendar_events_select ON app.calendar_events;
CREATE POLICY pol_calendar_events_select ON app.calendar_events
    FOR SELECT USING (organization_id = app.current_organization_id());

DROP POLICY IF EXISTS pol_calendar_events_modify ON app.calendar_events;
CREATE POLICY pol_calendar_events_modify ON app.calendar_events
    FOR ALL
    USING (
        organization_id = app.current_organization_id()
        AND user_id = app.current_user_id()
    )
    WITH CHECK (
        organization_id = app.current_organization_id()
        AND user_id = app.current_user_id()
    );

-- meetings: 같은 조직 SELECT, 본인 또는 조직 owner만 UPDATE
DROP POLICY IF EXISTS pol_meetings_select ON app.meetings;
CREATE POLICY pol_meetings_select ON app.meetings
    FOR SELECT USING (organization_id = app.current_organization_id());

DROP POLICY IF EXISTS pol_meetings_insert ON app.meetings;
CREATE POLICY pol_meetings_insert ON app.meetings
    FOR INSERT WITH CHECK (organization_id = app.current_organization_id());

DROP POLICY IF EXISTS pol_meetings_update ON app.meetings;
CREATE POLICY pol_meetings_update ON app.meetings
    FOR UPDATE
    USING (
        organization_id = app.current_organization_id()
        AND (user_id = app.current_user_id()
             OR created_by = app.current_user_id()
             OR app.is_organization_owner(organization_id))
    )
    WITH CHECK (organization_id = app.current_organization_id());

DROP POLICY IF EXISTS pol_meetings_delete ON app.meetings;
CREATE POLICY pol_meetings_delete ON app.meetings
    FOR DELETE USING (
        organization_id = app.current_organization_id()
        AND (user_id = app.current_user_id()
             OR app.is_organization_owner(organization_id))
    );

-- meeting_attendees: 같은 조직 SELECT, meeting 작성자만 INSERT/UPDATE/DELETE
DROP POLICY IF EXISTS pol_meeting_attendees_select ON app.meeting_attendees;
CREATE POLICY pol_meeting_attendees_select ON app.meeting_attendees
    FOR SELECT USING (organization_id = app.current_organization_id());

DROP POLICY IF EXISTS pol_meeting_attendees_modify ON app.meeting_attendees;
CREATE POLICY pol_meeting_attendees_modify ON app.meeting_attendees
    FOR ALL
    USING (
        organization_id = app.current_organization_id()
        AND EXISTS (
            SELECT 1 FROM app.meetings m
            WHERE m.id = meeting_attendees.meeting_id
              AND (m.user_id = app.current_user_id()
                   OR m.created_by = app.current_user_id())
        )
    )
    WITH CHECK (organization_id = app.current_organization_id());

-- ------------------------------------------------------------
-- 7. 감사 트리거
-- ------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_audit_calendar_connections ON app.calendar_connections;
CREATE TRIGGER trg_audit_calendar_connections
    AFTER INSERT OR UPDATE OR DELETE ON app.calendar_connections
    FOR EACH ROW EXECUTE FUNCTION audit.log_change();

DROP TRIGGER IF EXISTS trg_audit_meetings ON app.meetings;
CREATE TRIGGER trg_audit_meetings
    AFTER INSERT OR UPDATE OR DELETE ON app.meetings
    FOR EACH ROW EXECUTE FUNCTION audit.log_change();

DROP TRIGGER IF EXISTS trg_audit_meeting_attendees ON app.meeting_attendees;
CREATE TRIGGER trg_audit_meeting_attendees
    AFTER INSERT OR UPDATE OR DELETE ON app.meeting_attendees
    FOR EACH ROW EXECUTE FUNCTION audit.log_change();

-- calendar_events는 동기화로 INSERT/UPDATE 빈번 → 감사 제외

-- ------------------------------------------------------------
-- 8. 토큰 암호화 helper (service_role만 호출)
-- ------------------------------------------------------------

-- 환경 변수 `app.calendar_encryption_key`를 Supabase에 설정해야 함
-- ALTER DATABASE postgres SET app.calendar_encryption_key = 'your-32-byte-key';

CREATE OR REPLACE FUNCTION app.encrypt_calendar_token(p_plain text)
RETURNS bytea
LANGUAGE sql IMMUTABLE
AS $$
    SELECT pgp_sym_encrypt(p_plain, current_setting('app.calendar_encryption_key'));
$$;

CREATE OR REPLACE FUNCTION app.decrypt_calendar_token(p_encrypted bytea)
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
    SELECT pgp_sym_decrypt(p_encrypted, current_setting('app.calendar_encryption_key'));
$$;

REVOKE EXECUTE ON FUNCTION app.decrypt_calendar_token(bytea) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION app.decrypt_calendar_token(bytea) TO service_role;

COMMENT ON FUNCTION app.encrypt_calendar_token(text) IS
    '캘린더 OAuth 토큰 암호화. INSERT/UPDATE 시 호출';
COMMENT ON FUNCTION app.decrypt_calendar_token(bytea) IS
    '캘린더 OAuth 토큰 복호화. service_role만 호출 가능';

-- ------------------------------------------------------------
-- 9. Helper RPC: 사용자의 다가오는 미팅 조회
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_upcoming_meetings(
    p_user_id    uuid DEFAULT NULL,
    p_days_ahead int  DEFAULT 30
)
RETURNS TABLE (
    meeting_id      uuid,
    party_id        uuid,
    party_name      text,
    title           text,
    scheduled_at    timestamptz,
    duration_minutes int,
    meeting_mode    app.meeting_mode,
    status          app.meeting_status
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, app
AS $$
    SELECT
        m.id,
        m.party_id,
        p.name,
        m.title,
        m.scheduled_at,
        m.duration_minutes,
        m.meeting_mode,
        m.status
    FROM app.meetings m
    JOIN app.parties p ON p.id = m.party_id
    WHERE m.organization_id = app.current_organization_id()
      AND m.user_id = COALESCE(p_user_id, app.current_user_id())
      AND m.scheduled_at >= NOW()
      AND m.scheduled_at <= NOW() + (p_days_ahead || ' days')::interval
      AND m.status = 'scheduled'
    ORDER BY m.scheduled_at ASC;
$$;

-- ------------------------------------------------------------
-- 10. 검증
-- ------------------------------------------------------------

DO $$
DECLARE
    v_tables       int;
    v_policies     int;
    v_triggers     int;
BEGIN
    SELECT COUNT(*) INTO v_tables
      FROM pg_tables
     WHERE schemaname = 'app'
       AND tablename IN ('calendar_connections', 'calendar_events', 'meetings', 'meeting_attendees');

    SELECT COUNT(*) INTO v_policies
      FROM pg_policies
     WHERE schemaname = 'app'
       AND tablename IN ('calendar_connections', 'calendar_events', 'meetings', 'meeting_attendees');

    SELECT COUNT(*) INTO v_triggers
      FROM information_schema.triggers
     WHERE event_object_schema = 'app'
       AND event_object_table IN ('calendar_connections', 'calendar_events', 'meetings', 'meeting_attendees');

    RAISE NOTICE '[030] Tables created: % / 4', v_tables;
    RAISE NOTICE '[030] RLS policies: % (expect 10+)', v_policies;
    RAISE NOTICE '[030] Triggers: %', v_triggers;

    IF v_tables < 4 THEN
        RAISE WARNING '[030] Missing tables!';
    END IF;
END$$;
