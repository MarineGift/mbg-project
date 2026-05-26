-- ============================================================
-- 031_calendar_token_functions.sql
-- calendar_connections 토큰 암호화/복호화 RPC
-- 의존: 030_calendar_integration.sql (pgcrypto, calendar_connections)
-- ============================================================

-- 암호화: 앱에서 평문 토큰 → bytea (pgp_sym_encrypt)
CREATE OR REPLACE FUNCTION app.encrypt_calendar_token(
    plain_text  text,
    enc_key     text
)
RETURNS bytea
LANGUAGE sql
SECURITY DEFINER
SET search_path = app, public
AS $$
    SELECT pgp_sym_encrypt(plain_text, enc_key);
$$;

-- 복호화: bytea → 평문 (service_role 전용)
CREATE OR REPLACE FUNCTION app.decrypt_calendar_token(
    encrypted   bytea,
    enc_key     text
)
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = app, public
AS $$
    SELECT pgp_sym_decrypt(encrypted, enc_key);
$$;

-- 연결 저장 헬퍼 (암호화 + INSERT 원자적 처리)
CREATE OR REPLACE FUNCTION app.upsert_calendar_connection(
    p_organization_id   uuid,
    p_user_id           uuid,
    p_provider          app.calendar_provider,
    p_account_email     text,
    p_account_name      text,
    p_access_token      text,
    p_refresh_token     text,
    p_expires_at        timestamptz,
    p_scopes            text[],
    p_enc_key           text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = app, public
AS $$
DECLARE
    v_id uuid;
BEGIN
    INSERT INTO app.calendar_connections (
        organization_id, user_id, provider,
        account_email, account_name,
        access_token, refresh_token,
        expires_at, scopes,
        is_active, is_primary
    )
    VALUES (
        p_organization_id, p_user_id, p_provider,
        p_account_email, p_account_name,
        pgp_sym_encrypt(p_access_token,  p_enc_key),
        pgp_sym_encrypt(p_refresh_token, p_enc_key),
        p_expires_at, p_scopes,
        true,
        NOT EXISTS (
            SELECT 1 FROM app.calendar_connections
            WHERE user_id = p_user_id
              AND provider = p_provider
              AND is_primary = true
        )
    )
    ON CONFLICT (user_id, provider, account_email)
    DO UPDATE SET
        access_token   = pgp_sym_encrypt(p_access_token,  p_enc_key),
        refresh_token  = CASE
                            WHEN p_refresh_token IS NOT NULL
                            THEN pgp_sym_encrypt(p_refresh_token, p_enc_key)
                            ELSE calendar_connections.refresh_token
                         END,
        expires_at     = p_expires_at,
        scopes         = p_scopes,
        is_active      = true,
        updated_at     = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;

-- 토큰 갱신 헬퍼
CREATE OR REPLACE FUNCTION app.update_calendar_tokens(
    p_connection_id uuid,
    p_access_token  text,
    p_expires_at    timestamptz,
    p_enc_key       text
)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = app, public
AS $$
    UPDATE app.calendar_connections
    SET
        access_token = pgp_sym_encrypt(p_access_token, p_enc_key),
        expires_at   = p_expires_at,
        updated_at   = NOW()
    WHERE id = p_connection_id;
$$;

-- syncToken / deltaLink 업데이트
CREATE OR REPLACE FUNCTION app.update_calendar_sync_state(
    p_connection_id     uuid,
    p_sync_token        text DEFAULT NULL,
    p_delta_link        text DEFAULT NULL,
    p_sync_status       app.calendar_sync_status DEFAULT 'success',
    p_last_error        text DEFAULT NULL
)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = app, public
AS $$
    UPDATE app.calendar_connections
    SET
        sync_token        = COALESCE(p_sync_token,  sync_token),
        delta_link        = COALESCE(p_delta_link,  delta_link),
        last_sync_at      = NOW(),
        last_sync_status  = p_sync_status,
        last_error        = p_last_error,
        sync_failures     = CASE
                                WHEN p_sync_status = 'failed'
                                THEN sync_failures + 1
                                ELSE 0
                            END,
        updated_at        = NOW()
    WHERE id = p_connection_id;
$$;

-- RPC 실행 권한 (authenticated role)
GRANT EXECUTE ON FUNCTION app.upsert_calendar_connection   TO authenticated;
GRANT EXECUTE ON FUNCTION app.update_calendar_sync_state   TO authenticated;
-- decrypt / update_tokens 는 service_role 전용
REVOKE EXECUTE ON FUNCTION app.decrypt_calendar_token      FROM authenticated;
REVOKE EXECUTE ON FUNCTION app.encrypt_calendar_token      FROM authenticated;
REVOKE EXECUTE ON FUNCTION app.update_calendar_tokens      FROM authenticated;
