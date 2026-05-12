-- ============================================================
-- 파일: 013_step3_step4_compat_patch.sql
-- 목적:
--   (1) STEP 3 코드(claude-client, processor, consultation-worker)가
--       실제로 INSERT/UPDATE할 수 있도록 누락 컬럼 보강
--   (2) STEP 4 인증 인프라: Supabase Auth access_token_hook 정의
--       (로그인 시 사용자의 organization_id를 JWT app_metadata에 자동 주입)
--   (3) 학습 루프: ai.drafts.final_body_plain 편집 시 edit_distance 자동 계산
--
-- 적용:
--   000_critical_patches.sql 이후, STEP 4 코드 배포 전에 1회 실행.
--   본 파일은 IF NOT EXISTS 가드로 멱등성을 보장 — 재실행해도 안전.
--
-- 의존성:
--   001~011 + 000_critical_patches.sql 모두 적용된 상태.
--
-- 관련 STEP 3 코드 경로:
--   src/lib/ai/cost-tracker.ts          (recordRun → ai.runs)
--   src/lib/ai/claude-client.ts         (run_status 매핑)
--   src/lib/email/processor.ts          (ai.drafts INSERT)
--   src/workers/consultation-worker.ts  (consultations UPDATE)
-- ============================================================

-- ============================================================
-- 섹션 1. ai.drafts — 자동발송 평가 결과 + 분리된 run_id 보존
-- ============================================================
-- STEP 3의 processor.ts insertDraft() 함수가 INSERT 시도하는 6개 컬럼.
-- 모든 컬럼은 안전한 기본값 사용 — 기존 행에 NULL/빈 값 채워짐.

DO $$
BEGIN
    -- 1.1 auto_send_eligible: auto-send-gate.evaluateAutoSend() 결과의 allowed 플래그
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'ai' AND table_name = 'drafts'
           AND column_name = 'auto_send_eligible'
    ) THEN
        ALTER TABLE ai.drafts
            ADD COLUMN auto_send_eligible boolean NOT NULL DEFAULT false;
        COMMENT ON COLUMN ai.drafts.auto_send_eligible IS
            'auto-send-gate가 평가한 자동발송 가능 여부. requires_human_approval과 별개로 게이트 통과 여부만 표시';
    END IF;

    -- 1.2 auto_send_blocked_reasons: GateBlockReason 배열
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'ai' AND table_name = 'drafts'
           AND column_name = 'auto_send_blocked_reasons'
    ) THEN
        ALTER TABLE ai.drafts
            ADD COLUMN auto_send_blocked_reasons text[] NOT NULL DEFAULT '{}';
        COMMENT ON COLUMN ai.drafts.auto_send_blocked_reasons IS
            'auto-send-gate가 차단한 사유 누적 배열 (10단계 평가 모두 누적). 예: {global_disabled,confidence_below_threshold}';
    END IF;

    -- 1.3 auto_send_rule_id: 평가에 사용된 ai.auto_send_rules 행
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'ai' AND table_name = 'drafts'
           AND column_name = 'auto_send_rule_id'
    ) THEN
        ALTER TABLE ai.drafts
            ADD COLUMN auto_send_rule_id uuid
            CONSTRAINT fk_drafts_auto_send_rule_id
                REFERENCES ai.auto_send_rules (id) ON DELETE SET NULL;
        COMMENT ON COLUMN ai.drafts.auto_send_rule_id IS
            '자동발송 평가에 적용된 ai.auto_send_rules 행. 규칙 변경 추적 가능';
    END IF;

    -- 1.4 auto_send_evaluation_log: 디버깅·감사용 평가 로그
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'ai' AND table_name = 'drafts'
           AND column_name = 'auto_send_evaluation_log'
    ) THEN
        ALTER TABLE ai.drafts
            ADD COLUMN auto_send_evaluation_log jsonb NOT NULL DEFAULT '{}'::jsonb;
        COMMENT ON COLUMN ai.drafts.auto_send_evaluation_log IS
            'auto-send-gate 평가 단계별 상세 로그. 예: {confidence_check: {observed: 0.85, required: 0.95}}';
    END IF;

    -- 1.5 classifier_run_id: 분류기(Haiku) 호출의 ai.runs.id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'ai' AND table_name = 'drafts'
           AND column_name = 'classifier_run_id'
    ) THEN
        ALTER TABLE ai.drafts
            ADD COLUMN classifier_run_id uuid
            CONSTRAINT fk_drafts_classifier_run_id
                REFERENCES ai.runs (id) ON DELETE SET NULL;
        COMMENT ON COLUMN ai.drafts.classifier_run_id IS
            '분류기(classifier) 호출의 ai.runs.id. drafter_run_id와 분리 추적';
    END IF;

    -- 1.6 drafter_run_id: 회신가(Opus) 호출의 ai.runs.id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'ai' AND table_name = 'drafts'
           AND column_name = 'drafter_run_id'
    ) THEN
        ALTER TABLE ai.drafts
            ADD COLUMN drafter_run_id uuid
            CONSTRAINT fk_drafts_drafter_run_id
                REFERENCES ai.runs (id) ON DELETE SET NULL;
        COMMENT ON COLUMN ai.drafts.drafter_run_id IS
            '회신가(reply_drafter) 호출의 ai.runs.id. 기존 run_id 컬럼은 backward-compat용';
    END IF;
END$$;

-- run_id 컬럼은 보존 (backward compat). 새 INSERT는 drafter_run_id 사용 권장.
COMMENT ON COLUMN ai.drafts.run_id IS
    'DEPRECATED. 신규 코드는 classifier_run_id / drafter_run_id 사용. 기존 행 호환을 위해 보존';

-- 새 컬럼에 대한 보조 인덱스
CREATE INDEX IF NOT EXISTS idx_drafts_auto_send_rule_id
    ON ai.drafts (auto_send_rule_id) WHERE auto_send_rule_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_drafts_classifier_run_id
    ON ai.drafts (classifier_run_id) WHERE classifier_run_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_drafts_drafter_run_id
    ON ai.drafts (drafter_run_id) WHERE drafter_run_id IS NOT NULL;

-- ============================================================
-- 섹션 2. app.consultations — AI 처리 실패 추적 컬럼
-- ============================================================
-- STEP 3의 consultation-worker.ts가 markFailed 시 UPDATE 시도하는 컬럼.

DO $$
BEGIN
    -- 2.1 ai_processing_error_message: 실패 사유 텍스트
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'app' AND table_name = 'consultations'
           AND column_name = 'ai_processing_error_message'
    ) THEN
        ALTER TABLE app.consultations
            ADD COLUMN ai_processing_error_message text;
        COMMENT ON COLUMN app.consultations.ai_processing_error_message IS
            'AI 처리 실패 시 에러 메시지. ClaudeApiError / ClaudeBudgetExceededError 등';
    END IF;

    -- 2.2 ai_processing_error_class: 에러 클래스명 (재시도 정책 결정용)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'app' AND table_name = 'consultations'
           AND column_name = 'ai_processing_error_class'
    ) THEN
        ALTER TABLE app.consultations
            ADD COLUMN ai_processing_error_class text;
        COMMENT ON COLUMN app.consultations.ai_processing_error_class IS
            '에러 클래스명 (예: ClaudeApiError, ClaudeBudgetExceededError). 자동 재시도 가능 여부 판단';
    END IF;

    -- 2.3 ai_processing_failed_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'app' AND table_name = 'consultations'
           AND column_name = 'ai_processing_failed_at'
    ) THEN
        ALTER TABLE app.consultations
            ADD COLUMN ai_processing_failed_at timestamptz;
        COMMENT ON COLUMN app.consultations.ai_processing_failed_at IS
            'AI 처리 실패 시각. ai_processing_started_at, _completed_at과 짝';
    END IF;

    -- 2.4 ai_processing_retryable
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'app' AND table_name = 'consultations'
           AND column_name = 'ai_processing_retryable'
    ) THEN
        ALTER TABLE app.consultations
            ADD COLUMN ai_processing_retryable boolean;
        COMMENT ON COLUMN app.consultations.ai_processing_retryable IS
            '실패가 일시적인지 영구적인지. 일시적이면 워커가 재시도 가능 (예: 5xx, 429)';
    END IF;
END$$;

-- ============================================================
-- 섹션 3. ai.drafts — edit_distance 자동 계산 트리거
-- ============================================================
-- 사용자가 final_body_plain을 입력하면 body_plain과의 거리를 자동 계산.
-- 학습 루프 (마스터 §6.4): 편집량이 적은 초안 = 우수 사례 → brand_voice 학습 후보.
--
-- 정밀 Levenshtein은 비용이 크므로 pg_trgm.similarity로 근사:
--   edit_distance ≈ (1 - similarity) × length(body_plain)
-- 짧은 텍스트만 정밀 계산하고 긴 본문은 길이 차이로 fallback.

CREATE OR REPLACE FUNCTION ai.compute_draft_edit_distance()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_sim numeric;
BEGIN
    -- final_body_plain이 변경되었거나 새로 채워졌을 때만 계산
    IF (TG_OP = 'INSERT' AND NEW.final_body_plain IS NOT NULL)
       OR (TG_OP = 'UPDATE'
           AND NEW.final_body_plain IS DISTINCT FROM OLD.final_body_plain
           AND NEW.final_body_plain IS NOT NULL) THEN

        IF NEW.body_plain IS NULL OR length(NEW.body_plain) = 0 THEN
            NEW.edit_distance := length(NEW.final_body_plain);
        ELSIF length(NEW.body_plain) <= 8000 AND length(NEW.final_body_plain) <= 8000 THEN
            -- pg_trgm 정밀 계산 (8KB 이하)
            v_sim := similarity(NEW.body_plain, NEW.final_body_plain);
            NEW.edit_distance := round(GREATEST(0.0, 1.0 - v_sim)
                                       * length(NEW.body_plain))::int;
        ELSE
            -- 긴 본문은 길이 차이로 근사
            NEW.edit_distance := abs(length(NEW.final_body_plain)
                                     - length(NEW.body_plain));
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION ai.compute_draft_edit_distance() IS
    'ai.drafts.final_body_plain 입력 시 edit_distance 자동 계산. pg_trgm 기반 근사';

DROP TRIGGER IF EXISTS trg_drafts_compute_edit_distance ON ai.drafts;
CREATE TRIGGER trg_drafts_compute_edit_distance
    BEFORE INSERT OR UPDATE OF final_body_plain ON ai.drafts
    FOR EACH ROW EXECUTE FUNCTION ai.compute_draft_edit_distance();

-- ============================================================
-- 섹션 4. Supabase Auth access_token_hook
-- ============================================================
-- 로그인 시 사용자의 organization_id를 JWT의 app_metadata에 자동 주입.
-- 이로써 app.current_organization_id()가 JWT에서 정상 추출 가능.
--
-- Supabase Dashboard에서 본 함수를 "Custom Access Token Hook"로 등록 필요:
--   Authentication → Hooks → Custom Access Token → public.custom_access_token_hook
--
-- 함수 시그니처 (Supabase 명세):
--   input  event jsonb: { user_id, claims, ... }
--   output: 수정된 event (claims 안의 app_metadata 갱신)

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, app, pg_catalog
AS $$
DECLARE
    v_user_id        uuid;
    v_organization_id uuid;
    v_is_owner       boolean;
    v_preferred_lang text;
    v_claims         jsonb;
    v_app_metadata   jsonb;
BEGIN
    -- user_id 추출 (Supabase가 event에 포함시킴)
    v_user_id := NULLIF(event->>'user_id', '')::uuid;
    IF v_user_id IS NULL THEN
        RETURN event;  -- 변경 없이 패스
    END IF;

    -- 사용자 정보 조회 (활성 + 미삭제만)
    SELECT u.organization_id, u.is_owner, u.preferred_language
      INTO v_organization_id, v_is_owner, v_preferred_lang
      FROM app.users u
     WHERE u.id = v_user_id
       AND u.is_active = true
       AND u.deleted_at IS NULL;

    -- 조직 미할당 사용자는 변경 없이 패스 (가입 직후 등)
    IF v_organization_id IS NULL THEN
        RETURN event;
    END IF;

    -- claims와 app_metadata 추출 (없으면 빈 객체)
    v_claims := COALESCE(event->'claims', '{}'::jsonb);
    v_app_metadata := COALESCE(v_claims->'app_metadata', '{}'::jsonb);

    -- app_metadata 갱신
    v_app_metadata := v_app_metadata
        || jsonb_build_object(
            'organization_id', v_organization_id::text,
            'is_owner',        COALESCE(v_is_owner, false),
            'preferred_language', COALESCE(v_preferred_lang, 'ko')
        );

    -- claims에 다시 주입
    v_claims := jsonb_set(v_claims, '{app_metadata}', v_app_metadata, true);
    event := jsonb_set(event, '{claims}', v_claims, true);

    RETURN event;
EXCEPTION
    WHEN OTHERS THEN
        -- 어떤 예외도 로그인 자체를 막아서는 안 됨 — 원본 event 반환
        -- (RLS는 organization_id 없으면 자동 차단되므로 보안 안전)
        RAISE WARNING 'custom_access_token_hook failed for user %: %', v_user_id, SQLERRM;
        RETURN event;
END;
$$;

COMMENT ON FUNCTION public.custom_access_token_hook(jsonb) IS
    'Supabase Auth hook: 로그인 시 사용자의 organization_id/is_owner/preferred_language를 JWT app_metadata에 주입';

-- Supabase Auth role에게 실행 권한 부여 (Supabase 공식 문서 패턴)
GRANT USAGE ON SCHEMA public TO supabase_auth_admin;
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook(jsonb)
    TO supabase_auth_admin;
GRANT SELECT ON app.users TO supabase_auth_admin;

-- 본 함수의 RLS는 SECURITY DEFINER로 우회되지만,
-- 명시적으로 다른 role의 접근은 차단
REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook(jsonb)
    FROM authenticated, anon, public;

-- ============================================================
-- 섹션 5. ai.runs.metadata 보조 인덱스 (STEP 3 코드가 metadata에
-- trace_label, retry_count, brand_voice_id 등을 저장하므로 검색 효율 확보)
-- ============================================================

-- 5.1 trace_label 검색 (예: processor:classifier:* 패턴 디버깅)
CREATE INDEX IF NOT EXISTS idx_runs_metadata_trace_label
    ON ai.runs USING GIN ((metadata -> 'trace_label'))
    WHERE metadata ? 'trace_label';

-- 5.2 brand_voice 사용 추적 (학습 루프: 어떤 brand_voice 버전이 많이 사용되었나)
CREATE INDEX IF NOT EXISTS idx_runs_metadata_brand_voice
    ON ai.runs USING GIN ((metadata -> 'brand_voice_id'))
    WHERE metadata ? 'brand_voice_id';

-- 5.3 일반 metadata jsonb_path_ops 인덱스 (드물게 쓰이는 키 검색용)
CREATE INDEX IF NOT EXISTS idx_runs_metadata_path_ops
    ON ai.runs USING GIN (metadata jsonb_path_ops);

-- ============================================================
-- 섹션 6. STEP 4 인증 미들웨어 보조 — JWT 검증 헬퍼
-- ============================================================
-- STEP 4 Server Action 및 미인증 경로에서 사용.
--
-- 추가 패치: 001의 current_user_id() / current_organization_id() 도
-- 빈 문자열 JWT 시 PostgreSQL `'' :: jsonb` 에러를 던지지 않도록 안전 처리.
-- (CREATE OR REPLACE이므로 idempotent)

CREATE OR REPLACE FUNCTION app.current_user_id()
RETURNS uuid
LANGUAGE sql STABLE
AS $$
    SELECT NULLIF(
        NULLIF(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub',
        ''
    )::uuid
$$;

COMMENT ON FUNCTION app.current_user_id() IS
    'Supabase JWT sub claim에서 user_id 추출. JWT 부재·빈 문자열 시 NULL 안전 반환';

CREATE OR REPLACE FUNCTION app.current_organization_id()
RETURNS uuid
LANGUAGE sql STABLE
AS $$
    SELECT NULLIF(
        NULLIF(current_setting('request.jwt.claims', true), '')::jsonb
            -> 'app_metadata' ->> 'organization_id',
        ''
    )::uuid
$$;

COMMENT ON FUNCTION app.current_organization_id() IS
    'JWT app_metadata.organization_id 추출. RLS 정책의 핵심. JWT 부재 시 NULL 안전 반환';

CREATE OR REPLACE FUNCTION app.current_is_owner()
RETURNS boolean
LANGUAGE sql STABLE
AS $$
    SELECT COALESCE(
        (NULLIF(current_setting('request.jwt.claims', true), '')::jsonb
            -> 'app_metadata' ->> 'is_owner')::boolean,
        false
    )
$$;

COMMENT ON FUNCTION app.current_is_owner() IS
    'JWT app_metadata.is_owner 추출. STEP 4 Server Action 권한 검사에 사용. JWT 부재 시 false';

CREATE OR REPLACE FUNCTION app.current_preferred_language()
RETURNS text
LANGUAGE sql STABLE
AS $$
    SELECT COALESCE(
        NULLIF(current_setting('request.jwt.claims', true), '')::jsonb
            -> 'app_metadata' ->> 'preferred_language',
        'ko'
    )
$$;

COMMENT ON FUNCTION app.current_preferred_language() IS
    'JWT app_metadata.preferred_language 추출. UI 언어 결정 fallback. JWT 부재 시 ko';

-- ============================================================
-- 섹션 7. ai.drafts pending_review 큐 보조 인덱스 (STEP 4 큐 UI 성능)
-- ============================================================
-- STEP 4 §3.1: 큐 기본 정렬 = confidence ASC, expires_at ASC.
-- 기존 idx_drafts_pending_review은 (organization_id, expires_at)만 다룸.
-- 신뢰도 정렬을 위한 보조 인덱스 추가.

CREATE INDEX IF NOT EXISTS idx_drafts_queue_sort
    ON ai.drafts (organization_id, confidence_score ASC, expires_at ASC)
    WHERE status = 'pending_review';

-- ============================================================
-- 검증 (NOTICE 출력)
-- ============================================================

DO $$
DECLARE
    v_drafts_new_cols       int;
    v_consult_new_cols      int;
    v_edit_dist_trigger     int;
    v_access_token_hook     int;
    v_helper_funcs          int;
    v_new_indexes           int;
BEGIN
    -- ai.drafts 신규 컬럼 6개
    SELECT COUNT(*) INTO v_drafts_new_cols
      FROM information_schema.columns
     WHERE table_schema = 'ai' AND table_name = 'drafts'
       AND column_name IN (
            'auto_send_eligible','auto_send_blocked_reasons',
            'auto_send_rule_id','auto_send_evaluation_log',
            'classifier_run_id','drafter_run_id'
       );

    -- app.consultations 신규 컬럼 4개
    SELECT COUNT(*) INTO v_consult_new_cols
      FROM information_schema.columns
     WHERE table_schema = 'app' AND table_name = 'consultations'
       AND column_name IN (
            'ai_processing_error_message','ai_processing_error_class',
            'ai_processing_failed_at','ai_processing_retryable'
       );

    -- edit_distance 트리거
    SELECT COUNT(*) INTO v_edit_dist_trigger
      FROM information_schema.triggers
     WHERE trigger_name = 'trg_drafts_compute_edit_distance';

    -- access_token_hook 함수
    SELECT COUNT(*) INTO v_access_token_hook
      FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
     WHERE n.nspname = 'public'
       AND p.proname = 'custom_access_token_hook';

    -- 헬퍼 함수 2개
    SELECT COUNT(*) INTO v_helper_funcs
      FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
     WHERE n.nspname = 'app'
       AND p.proname IN ('current_is_owner','current_preferred_language');

    -- 본 마이그레이션이 추가한 인덱스
    SELECT COUNT(*) INTO v_new_indexes
      FROM pg_indexes
     WHERE indexname IN (
            'idx_drafts_auto_send_rule_id',
            'idx_drafts_classifier_run_id',
            'idx_drafts_drafter_run_id',
            'idx_runs_metadata_trace_label',
            'idx_runs_metadata_brand_voice',
            'idx_runs_metadata_path_ops',
            'idx_drafts_queue_sort'
       );

    RAISE NOTICE '[013] ai.drafts 신규 컬럼: % / 6',          v_drafts_new_cols;
    RAISE NOTICE '[013] app.consultations 신규 컬럼: % / 4', v_consult_new_cols;
    RAISE NOTICE '[013] edit_distance 트리거: % / 1',         v_edit_dist_trigger;
    RAISE NOTICE '[013] access_token_hook 함수: % / 1',       v_access_token_hook;
    RAISE NOTICE '[013] JWT 헬퍼 함수: % / 2',                 v_helper_funcs;
    RAISE NOTICE '[013] 신규 인덱스: % / 7',                   v_new_indexes;

    -- 모두 통과해야 STEP 4 시작 가능
    IF v_drafts_new_cols < 6 THEN
        RAISE WARNING '[013] ai.drafts 컬럼이 누락되었습니다. STEP 3 코드의 INSERT가 실패할 수 있습니다.';
    END IF;
    IF v_consult_new_cols < 4 THEN
        RAISE WARNING '[013] app.consultations 컬럼이 누락되었습니다. consultation-worker의 markFailed가 실패할 수 있습니다.';
    END IF;
    IF v_access_token_hook < 1 THEN
        RAISE WARNING '[013] custom_access_token_hook이 누락. Supabase Dashboard에서 등록 필요 (Auth → Hooks)';
    END IF;
END$$;

-- ============================================================
-- 사용 안내 (이 파일 적용 후 운영자가 해야 할 것)
-- ============================================================
--
-- 1. Supabase Dashboard 설정:
--    Authentication → Hooks → Custom Access Token Hook
--    Function: public.custom_access_token_hook
--    Schema:   public
--    → "Enable" 토글 ON
--
-- 2. 기존 로그인 세션은 새 hook이 적용되지 않음.
--    모든 사용자에게 재로그인을 안내하거나
--    auth.users를 통해 강제 로그아웃:
--    SELECT auth.uid(), ... 등 새 세션 발급
--
-- 3. RLS 검증:
--    -- 임의 user_id로 JWT 클레임을 시뮬레이션해 정책 통과 여부 확인
--    SET request.jwt.claims = '{"sub":"<user_uuid>","app_metadata":{"organization_id":"<org_uuid>"}}';
--    SELECT * FROM app.parties LIMIT 1;  -- 본인 조직 데이터만 보이는지 확인
--    RESET request.jwt.claims;
--
-- 4. STEP 3 코드 보정 패치 (단계 2) 적용 후 다음 통합 테스트 통과 확인:
--    - cost-tracker.ts: ai.runs INSERT가 model_used/input_tokens/output_tokens 사용
--    - claude-client.ts: ai.run_status 매핑 (success→completed 등)
--    - processor.ts: inbound_communication_id, agent_id, pending_review 사용
--
-- ============================================================
