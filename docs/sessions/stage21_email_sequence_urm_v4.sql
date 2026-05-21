-- ============================================================================
-- Migration: Stage 21 v4 — email_sequence URM 완성 (β + δ 전면)
-- Date:      2026-05-21 (Session 5 / 첫 작업, Stage 20 후)
--
-- v3 → v4: partial index 2개 DROP/recreate 추가 (§2.6 + §4.5 신설)
--   원인: email_sequence_enrollments 의 2 partial index 가 WHERE 절에서
--         text literal 비교 사용:
--           idx_seq_enrollments_due:        WHERE status = 'active'::text
--           idx_unique_active_enrollment:   WHERE status = 'active'::text AND ...
--         ALTER COLUMN TYPE 시 WHERE 표현식을 enum 컬럼에 재적용하려다 fail.
--   수정: §2.6 신설 — 2 index DROP (ALTER 전)
--         §4.5 신설 — 2 index 재생성 (enum literal 사용)
--   격리 진단: Test A (sequences), Test C (sends) ✅ Success.
--             Test B (enrollments) 만 fail — 이 테이블 partial index 가 원인.
--
-- v2 → v3: CHECK constraint 3개 DROP 추가 (§2.5 신설)
--   원인: pg_depend normal dependency CHECK constraint 3개 (text array 비교).
--   수정: ALTER 전 CHECK 3개 DROP. enum 이 자체 제약 보장.
--   부수: enrollment_status enum 에 'paused' value 추가 (별도 transaction).
--
-- v1 → v2: archive_sequence + cancel_enrollment 추가 처리
--   원인: LANGUAGE sql 함수 — ALTER COLUMN TYPE 시 eager 재컴파일.
--   수정: §2.4 에 DROP, §8.14/§8.15 에 explicit cast 재정의.
--
-- 사전 조건 (v4 실행 전 필수):
--   1. enum 3개 commit 됨 (이미 commit 완료)
--   2. 'paused' value 추가 commit 됨 (별도 ALTER TYPE ADD VALUE 사전 실행 — 완료됨)
--   3. CHECK constraint 3개 drop 됨 (별도 실행됨 — 단, v4 idempotent 처리)
--
-- 목적:
--   Session 4 handoff §4 의 17b + 17c + 17d 마무리.
--   email_sequence 모듈을 URM 100% 일치로 정렬.
--
-- 작업 (β + δ — URM 완전체):
--   §0. Pre-check NOTICE
--   §1. Enum 3개 존재 확인 (이미 생성됨)
--   §2. 의존성 해제 (8 RLS + 2 triggers + 2 trigger funcs + 13 functions)
--   §3. Column rename (org_id → organization_id, 2 테이블)
--   §4. Status text → enum cast (3 컬럼, DEFAULT 처리 포함)
--   §5. Trigger functions 재생성
--   §6. Triggers 재생성
--   §7. RLS policies 재생성 (8개)
--   §8. 13 public functions 재정의 (β+δ)
--   §9. 검증 (12 항목 + rows 보존)
--   §10. NOTIFY pgrst
--
-- 영향:
--   - 데이터 손실 0 (rows 보존)
--   - Frontend breaking change:
--     * RPC 인자명: p_org_id → p_organization_id (전체)
--     * RPC 반환: status text → app.xxx_status enum
--     * jsonb 키: 'org_id' → 'organization_id' (get_sequence_with_steps)
--   - Stage 22 에서 TS types 재생성 + app code patch 로 흡수 예정
--
-- 메타: 활성 데이터 (sequences 2, enrollments 6, sends 5)
-- ============================================================================

BEGIN;

-- ═══════════════════════════════════════════════════════════════════════
-- §0. Pre-check
-- ═══════════════════════════════════════════════════════════════════════

DO $precheck$
DECLARE
  v_es_rows int; v_ese_rows int; v_esn_rows int; v_est_rows int;
  v_enum_count int;
  v_paused_exists boolean;
  v_check_count int;
  v_partial_idx_count int;
  v_policy_count int;
  v_func_count int;
BEGIN
  SELECT COUNT(*) INTO v_es_rows  FROM app.email_sequences;
  SELECT COUNT(*) INTO v_ese_rows FROM app.email_sequence_enrollments;
  SELECT COUNT(*) INTO v_esn_rows FROM app.email_sequence_sends;
  SELECT COUNT(*) INTO v_est_rows FROM app.email_sequence_steps;

  SELECT COUNT(*) INTO v_enum_count
    FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
    WHERE n.nspname='app'
      AND t.typname IN ('email_sequence_status','enrollment_status','send_status');

  -- v3: 'paused' value 사전 commit 확인 (gotcha #4 — ADD VALUE 같은 transaction 안 사용 불가)
  SELECT EXISTS(
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname='app' AND t.typname='enrollment_status' AND e.enumlabel='paused'
  ) INTO v_paused_exists;

  -- v3: CHECK constraint 잔존 확인 (이미 단독 drop 됨 — 0 expected, idempotent)
  SELECT COUNT(*) INTO v_check_count
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    WHERE c.contype = 'c'
      AND t.relname IN ('email_sequences','email_sequence_enrollments','email_sequence_sends')
      AND c.conname LIKE '%status_check';

  -- v4: partial index 2개 존재 확인 (drop 대상)
  SELECT COUNT(*) INTO v_partial_idx_count
    FROM pg_indexes
    WHERE schemaname='app'
      AND tablename='email_sequence_enrollments'
      AND indexname IN ('idx_seq_enrollments_due','idx_unique_active_enrollment');

  SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE schemaname='app' AND tablename LIKE 'email_sequence%';

  SELECT COUNT(*) INTO v_func_count
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public'
      AND p.proname IN (
        'advance_enrollment','bulk_enroll_filtered','count_email_history',
        'create_campaign_from_template','create_sequence','enroll_in_sequence',
        'get_due_enrollments','get_email_history','get_party_enrollments',
        'get_sequence_with_steps','list_sequences'
      );

  RAISE NOTICE '[21] ══════════════════════════════════════════════════════';
  RAISE NOTICE '[21] Stage 21 v4 — email_sequence URM 완성 (β + δ)';
  RAISE NOTICE '[21] ══════════════════════════════════════════════════════';
  RAISE NOTICE '[21]   email_sequences rows              : %', v_es_rows;
  RAISE NOTICE '[21]   email_sequence_enrollments rows   : %', v_ese_rows;
  RAISE NOTICE '[21]   email_sequence_sends rows         : %', v_esn_rows;
  RAISE NOTICE '[21]   email_sequence_steps rows         : %', v_est_rows;
  RAISE NOTICE '[21]   enum 3개 존재 (3 expected)        : %', v_enum_count;
  RAISE NOTICE '[21]   enrollment_status.paused          : %', v_paused_exists;
  RAISE NOTICE '[21]   CHECK constraints (0 expected)    : %', v_check_count;
  RAISE NOTICE '[21]   partial indexes (2 expected)      : %', v_partial_idx_count;
  RAISE NOTICE '[21]   policies 현재 (16 expected)       : %', v_policy_count;
  RAISE NOTICE '[21]   redefine 대상 함수 (11 expected)  : %', v_func_count;
  RAISE NOTICE '[21] ══════════════════════════════════════════════════════';

  IF v_enum_count != 3 THEN
    RAISE EXCEPTION '[21] enum 3개 누락 — Session 5 사전 단독 실행분 확인 필요';
  END IF;

  IF NOT v_paused_exists THEN
    RAISE EXCEPTION '[21] enrollment_status.paused 누락 — 사전 별도 transaction 으로 ADD VALUE 실행 필수: ALTER TYPE app.enrollment_status ADD VALUE IF NOT EXISTS ''paused'';';
  END IF;
END $precheck$;

-- ═══════════════════════════════════════════════════════════════════════
-- §1. Enum 3개 존재 확인 (이미 생성됨, idempotent skip)
-- ═══════════════════════════════════════════════════════════════════════
-- app.email_sequence_status (draft/active/paused/archived)
-- app.enrollment_status (active/completed/cancelled/failed)
-- app.send_status (pending/sent/skipped/bounced/failed)

DO $enum_check$
BEGIN
  RAISE NOTICE '[21] §1 Enum 3개 확인 — 이미 생성됨, skip';
END $enum_check$;

-- ═══════════════════════════════════════════════════════════════════════
-- §2. 의존성 해제 (drop in dependency order)
-- ═══════════════════════════════════════════════════════════════════════

-- §2.1 RLS policies DROP (8개 — org_id 참조하는 것만)
--      email_sequence_sends/steps 의 8 policies 는 이미 organization_id 사용 — 유지

DROP POLICY IF EXISTS pol_es_select  ON app.email_sequences;
DROP POLICY IF EXISTS pol_es_insert  ON app.email_sequences;
DROP POLICY IF EXISTS pol_es_update  ON app.email_sequences;
DROP POLICY IF EXISTS pol_es_delete  ON app.email_sequences;

DROP POLICY IF EXISTS pol_ese_select ON app.email_sequence_enrollments;
DROP POLICY IF EXISTS pol_ese_insert ON app.email_sequence_enrollments;
DROP POLICY IF EXISTS pol_ese_update ON app.email_sequence_enrollments;
DROP POLICY IF EXISTS pol_ese_delete ON app.email_sequence_enrollments;

-- §2.2 Triggers DROP (org_id 컬럼 참조하는 trigger fn 사용 중)
DROP TRIGGER IF EXISTS trg_ess_set_organization_id ON app.email_sequence_steps;
DROP TRIGGER IF EXISTS trg_esn_set_organization_id ON app.email_sequence_sends;

-- §2.3 Trigger functions DROP
DROP FUNCTION IF EXISTS app.fn_ess_set_organization_id();
DROP FUNCTION IF EXISTS app.fn_esn_set_organization_id();

-- §2.4 13 public functions DROP (정확한 arg type 매칭)
--      RETURNS 변경 + arg type 변경이 있으므로 CREATE OR REPLACE 불가 → DROP 필수

DROP FUNCTION IF EXISTS public.advance_enrollment(uuid, uuid, integer, uuid, boolean, text);
DROP FUNCTION IF EXISTS public.bulk_enroll_filtered(uuid, uuid, text, text[], text, text, uuid, boolean);
DROP FUNCTION IF EXISTS public.bulk_enroll_filtered(uuid, uuid, text, text[], text, text, uuid, boolean, text, text);
DROP FUNCTION IF EXISTS public.count_email_history(uuid);
DROP FUNCTION IF EXISTS public.create_campaign_from_template(uuid, uuid, text, text, text[], text, text, uuid);
DROP FUNCTION IF EXISTS public.create_campaign_from_template(uuid, uuid, text, text, text[], text, text, uuid, text, text);
DROP FUNCTION IF EXISTS public.create_sequence(uuid, text, text, jsonb);
DROP FUNCTION IF EXISTS public.enroll_in_sequence(uuid, uuid, uuid, uuid, uuid);
DROP FUNCTION IF EXISTS public.get_due_enrollments();
DROP FUNCTION IF EXISTS public.get_email_history(uuid, integer, integer);
DROP FUNCTION IF EXISTS public.get_party_enrollments(uuid);
DROP FUNCTION IF EXISTS public.get_sequence_with_steps(uuid);
DROP FUNCTION IF EXISTS public.list_sequences(uuid);

-- 추가 DROP (v2): SQL language 함수 — ALTER COLUMN TYPE 시 eager 재컴파일 회피
DROP FUNCTION IF EXISTS public.archive_sequence(uuid);
DROP FUNCTION IF EXISTS public.cancel_enrollment(uuid);

DO $drop_notice$ BEGIN
  RAISE NOTICE '[21] §2 의존성 해제 완료 — 8 policies + 2 triggers + 2 trigger funcs + 15 functions';
END $drop_notice$;

-- ═══════════════════════════════════════════════════════════════════════
-- §2.5 CHECK constraint DROP (v3 추가 — pg_depend normal dependency 차단)
-- ═══════════════════════════════════════════════════════════════════════
-- 원인: status 컬럼에 normal dep CHECK constraint 3개. CHECK 본문이 text array
--       (status = ANY(ARRAY[...]::text[])) 이라 ALTER COLUMN TYPE 시 fail.
-- 대안: 재생성 안 함. enum 자체가 값 제한을 더 강력하게 보장.

ALTER TABLE app.email_sequences
  DROP CONSTRAINT IF EXISTS email_sequences_status_check;

ALTER TABLE app.email_sequence_enrollments
  DROP CONSTRAINT IF EXISTS email_sequence_enrollments_status_check;

ALTER TABLE app.email_sequence_sends
  DROP CONSTRAINT IF EXISTS email_sequence_sends_status_check;

DO $check_drop_notice$ BEGIN
  RAISE NOTICE '[21] §2.5 CHECK constraint 3개 DROP 완료 (enum 으로 대체)';
END $check_drop_notice$;

-- ═══════════════════════════════════════════════════════════════════════
-- §2.6 partial index DROP (v4 추가 — pg_depend auto dependency 차단)
-- ═══════════════════════════════════════════════════════════════════════
-- 원인: email_sequence_enrollments 의 2 partial index 가 WHERE 절에서
--       text literal `'active'::text` 비교 사용. ALTER COLUMN TYPE 시
--       WHERE 표현식이 enum 컬럼과 맞지 않아 fail.
-- 대안: ALTER 전 DROP, ALTER 후 enum literal 로 재생성 (§4.5).

DROP INDEX IF EXISTS app.idx_seq_enrollments_due;
DROP INDEX IF EXISTS app.idx_unique_active_enrollment;

DO $partial_idx_drop_notice$ BEGIN
  RAISE NOTICE '[21] §2.6 partial index 2개 DROP 완료';
END $partial_idx_drop_notice$;

-- ═══════════════════════════════════════════════════════════════════════
-- §3. Column rename (org_id → organization_id)
-- ═══════════════════════════════════════════════════════════════════════

ALTER TABLE app.email_sequences
  RENAME COLUMN org_id TO organization_id;

ALTER TABLE app.email_sequence_enrollments
  RENAME COLUMN org_id TO organization_id;

DO $rename_notice$ BEGIN
  RAISE NOTICE '[21] §3 Column rename 완료 — 2 테이블 org_id → organization_id';
END $rename_notice$;

-- ═══════════════════════════════════════════════════════════════════════
-- §4. Status text → enum cast (gotcha #18: DEFAULT 일시 제거 후 복원)
-- ═══════════════════════════════════════════════════════════════════════

-- §4.1 email_sequences.status → app.email_sequence_status
ALTER TABLE app.email_sequences
  ALTER COLUMN status DROP DEFAULT;
ALTER TABLE app.email_sequences
  ALTER COLUMN status TYPE app.email_sequence_status
  USING status::app.email_sequence_status;
ALTER TABLE app.email_sequences
  ALTER COLUMN status SET DEFAULT 'active'::app.email_sequence_status;

-- §4.2 email_sequence_enrollments.status → app.enrollment_status
ALTER TABLE app.email_sequence_enrollments
  ALTER COLUMN status DROP DEFAULT;
ALTER TABLE app.email_sequence_enrollments
  ALTER COLUMN status TYPE app.enrollment_status
  USING status::app.enrollment_status;
ALTER TABLE app.email_sequence_enrollments
  ALTER COLUMN status SET DEFAULT 'active'::app.enrollment_status;

-- §4.3 email_sequence_sends.status → app.send_status
ALTER TABLE app.email_sequence_sends
  ALTER COLUMN status DROP DEFAULT;
ALTER TABLE app.email_sequence_sends
  ALTER COLUMN status TYPE app.send_status
  USING status::app.send_status;
ALTER TABLE app.email_sequence_sends
  ALTER COLUMN status SET DEFAULT 'sent'::app.send_status;

DO $cast_notice$ BEGIN
  RAISE NOTICE '[21] §4 Status cast 완료 — 3 컬럼 text → enum';
END $cast_notice$;

-- ═══════════════════════════════════════════════════════════════════════
-- §4.5 partial index 재생성 (v4 추가 — enum literal 사용)
-- ═══════════════════════════════════════════════════════════════════════
-- §2.6 에서 DROP 한 2 index 를 enum literal 로 재생성.

CREATE INDEX idx_seq_enrollments_due
  ON app.email_sequence_enrollments USING btree (status, next_send_at)
  WHERE (status = 'active'::app.enrollment_status);

CREATE UNIQUE INDEX idx_unique_active_enrollment
  ON app.email_sequence_enrollments USING btree (sequence_id, party_id)
  WHERE ((status = 'active'::app.enrollment_status) AND (party_id IS NOT NULL));

DO $partial_idx_create_notice$ BEGIN
  RAISE NOTICE '[21] §4.5 partial index 2개 재생성 완료 (enum literal)';
END $partial_idx_create_notice$;

-- ═══════════════════════════════════════════════════════════════════════
-- §5. Trigger functions 재생성 (organization_id 컬럼명 반영)
-- ═══════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION app.fn_ess_set_organization_id()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.organization_id IS NULL THEN
    SELECT organization_id INTO NEW.organization_id
    FROM app.email_sequences
    WHERE id = NEW.sequence_id;

    IF NEW.organization_id IS NULL THEN
      RAISE EXCEPTION 'email_sequence_steps.organization_id 자동 fill 실패 — sequence_id % 부정합', NEW.sequence_id
        USING ERRCODE = 'P0001';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION app.fn_esn_set_organization_id()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.organization_id IS NULL THEN
    SELECT organization_id INTO NEW.organization_id
    FROM app.email_sequence_enrollments
    WHERE id = NEW.enrollment_id;

    IF NEW.organization_id IS NULL THEN
      RAISE EXCEPTION 'email_sequence_sends.organization_id 자동 fill 실패 — enrollment_id % 부정합', NEW.enrollment_id
        USING ERRCODE = 'P0001';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;

-- ═══════════════════════════════════════════════════════════════════════
-- §6. Triggers 재생성
-- ═══════════════════════════════════════════════════════════════════════

CREATE TRIGGER trg_ess_set_organization_id
  BEFORE INSERT ON app.email_sequence_steps
  FOR EACH ROW EXECUTE FUNCTION app.fn_ess_set_organization_id();

CREATE TRIGGER trg_esn_set_organization_id
  BEFORE INSERT ON app.email_sequence_sends
  FOR EACH ROW EXECUTE FUNCTION app.fn_esn_set_organization_id();

-- ═══════════════════════════════════════════════════════════════════════
-- §7. RLS policies 재생성 (8개 — organization_id 사용)
-- ═══════════════════════════════════════════════════════════════════════

-- email_sequences (4 policies)
CREATE POLICY pol_es_select ON app.email_sequences FOR SELECT
  USING (organization_id = app.current_organization_id());

CREATE POLICY pol_es_insert ON app.email_sequences FOR INSERT
  WITH CHECK (organization_id = app.current_organization_id());

CREATE POLICY pol_es_update ON app.email_sequences FOR UPDATE
  USING (organization_id = app.current_organization_id())
  WITH CHECK (organization_id = app.current_organization_id());

CREATE POLICY pol_es_delete ON app.email_sequences FOR DELETE
  USING (organization_id = app.current_organization_id());

-- email_sequence_enrollments (4 policies)
CREATE POLICY pol_ese_select ON app.email_sequence_enrollments FOR SELECT
  USING (organization_id = app.current_organization_id());

CREATE POLICY pol_ese_insert ON app.email_sequence_enrollments FOR INSERT
  WITH CHECK (organization_id = app.current_organization_id());

CREATE POLICY pol_ese_update ON app.email_sequence_enrollments FOR UPDATE
  USING (organization_id = app.current_organization_id())
  WITH CHECK (organization_id = app.current_organization_id());

CREATE POLICY pol_ese_delete ON app.email_sequence_enrollments FOR DELETE
  USING (organization_id = app.current_organization_id());

DO $policy_notice$ BEGIN
  RAISE NOTICE '[21] §5-7 Trigger funcs + triggers + 8 RLS policies 재생성 완료';
END $policy_notice$;

-- ═══════════════════════════════════════════════════════════════════════
-- §8. 13 public functions 재정의 (β + δ)
-- ═══════════════════════════════════════════════════════════════════════

-- §8.1 advance_enrollment — p_status text → app.send_status (δ)
CREATE OR REPLACE FUNCTION public.advance_enrollment(
  p_enrollment_id   uuid,
  p_step_id         uuid,
  p_step_order      integer,
  p_communication_id uuid,
  p_is_last_step    boolean,
  p_status          app.send_status DEFAULT 'sent'::app.send_status
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_sequence_id      UUID;
  v_enrolled_at      TIMESTAMPTZ;
  v_next_day_offset  INT;
BEGIN
  -- 발송 로그 기록
  INSERT INTO app.email_sequence_sends
    (enrollment_id, step_id, step_order, communication_id, status)
  VALUES
    (p_enrollment_id, p_step_id, p_step_order, p_communication_id, p_status);

  IF p_is_last_step THEN
    UPDATE app.email_sequence_enrollments
    SET status       = 'completed'::app.enrollment_status,
        completed_at = now(),
        updated_at   = now()
    WHERE id = p_enrollment_id;
  ELSE
    SELECT sequence_id, enrolled_at
    INTO v_sequence_id, v_enrolled_at
    FROM app.email_sequence_enrollments
    WHERE id = p_enrollment_id;

    SELECT day_offset INTO v_next_day_offset
    FROM app.email_sequence_steps
    WHERE sequence_id = v_sequence_id
      AND step_order  = p_step_order + 1;

    UPDATE app.email_sequence_enrollments
    SET next_step_order = p_step_order + 1,
        next_send_at    = v_enrolled_at + (v_next_day_offset || ' days')::INTERVAL,
        updated_at      = now()
    WHERE id = p_enrollment_id;
  END IF;
END;
$function$;

-- §8.2 bulk_enroll_filtered (overload 1 — 기본 8 args)
CREATE OR REPLACE FUNCTION public.bulk_enroll_filtered(
  p_organization_id uuid,
  p_sequence_id     uuid,
  p_module          text DEFAULT NULL::text,
  p_tiers           text[] DEFAULT NULL::text[],
  p_status          text DEFAULT 'active'::text,    -- parties.status filter, NOT enum
  p_country_code    text DEFAULT NULL::text,
  p_enrolled_by     uuid DEFAULT NULL::uuid,
  p_dry_run         boolean DEFAULT false
)
RETURNS TABLE(
  total_matching            integer,
  enrolled_count            integer,
  skipped_already_enrolled  integer,
  skipped_no_email          integer,
  sample_names              text[]
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_first_day_offset  INT;
  v_total_matching    INT := 0;
  v_enrolled          INT := 0;
  v_skipped_dup       INT := 0;
  v_skipped_no_email  INT := 0;
  v_sample_names      TEXT[] := ARRAY[]::TEXT[];
  v_party_id          UUID;
  v_contact_id        UUID;
  v_existing          UUID;
  v_party_name        TEXT;
BEGIN
  SELECT day_offset INTO v_first_day_offset
  FROM app.email_sequence_steps
  WHERE sequence_id = p_sequence_id
  ORDER BY step_order
  LIMIT 1;

  IF v_first_day_offset IS NULL THEN
    RAISE EXCEPTION 'Sequence has no steps';
  END IF;

  FOR v_party_id, v_party_name IN
    SELECT p.id, p.name
    FROM app.parties p
    WHERE p.organization_id = p_organization_id
      AND p.deleted_at IS NULL
      AND (p_module       IS NULL OR p.module::TEXT       = p_module)
      AND (p_tiers        IS NULL OR p.tier::TEXT         = ANY(p_tiers))
      AND (p_status       IS NULL OR p.status::TEXT       = p_status)
      AND (p_country_code IS NULL OR p.country_code       = p_country_code)
    ORDER BY p.name
  LOOP
    v_total_matching := v_total_matching + 1;

    IF array_length(v_sample_names, 1) IS NULL OR array_length(v_sample_names, 1) < 5 THEN
      v_sample_names := v_sample_names || v_party_name;
    END IF;

    SELECT id INTO v_existing
    FROM app.email_sequence_enrollments
    WHERE sequence_id = p_sequence_id
      AND party_id    = v_party_id
      AND status      = 'active'::app.enrollment_status
    LIMIT 1;

    IF v_existing IS NOT NULL THEN
      v_skipped_dup := v_skipped_dup + 1;
      v_existing := NULL;
      CONTINUE;
    END IF;

    SELECT id INTO v_contact_id
    FROM app.contacts
    WHERE party_id        = v_party_id
      AND deleted_at      IS NULL
      AND is_active       = true
      AND do_not_contact  = false
      AND email           IS NOT NULL
      AND email           != ''
    ORDER BY is_primary DESC, created_at ASC
    LIMIT 1;

    IF v_contact_id IS NULL THEN
      v_skipped_no_email := v_skipped_no_email + 1;
      CONTINUE;
    END IF;

    IF NOT p_dry_run THEN
      INSERT INTO app.email_sequence_enrollments (
        organization_id, sequence_id, party_id, contact_id, enrolled_by,
        status, next_step_order, next_send_at
      ) VALUES (
        p_organization_id, p_sequence_id, v_party_id, v_contact_id, p_enrolled_by,
        'active'::app.enrollment_status, 0,
        now() + (v_first_day_offset || ' days')::INTERVAL
      );
    END IF;

    v_enrolled   := v_enrolled + 1;
    v_contact_id := NULL;
  END LOOP;

  RETURN QUERY SELECT
    v_total_matching,
    v_enrolled,
    v_skipped_dup,
    v_skipped_no_email,
    v_sample_names;
END;
$function$;

-- §8.3 bulk_enroll_filtered (overload 2 — 10 args with industry_tag/name_contains)
CREATE OR REPLACE FUNCTION public.bulk_enroll_filtered(
  p_organization_id uuid,
  p_sequence_id     uuid,
  p_module          text DEFAULT NULL::text,
  p_tiers           text[] DEFAULT NULL::text[],
  p_status          text DEFAULT 'active'::text,    -- parties.status filter
  p_country_code    text DEFAULT NULL::text,
  p_enrolled_by     uuid DEFAULT NULL::uuid,
  p_dry_run         boolean DEFAULT false,
  p_industry_tag    text DEFAULT NULL::text,
  p_name_contains   text DEFAULT NULL::text
)
RETURNS TABLE(
  total_matching            integer,
  enrolled_count            integer,
  skipped_already_enrolled  integer,
  skipped_no_email          integer,
  sample_names              text[]
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_first_day_offset  INT;
  v_total_matching    INT := 0;
  v_enrolled          INT := 0;
  v_skipped_dup       INT := 0;
  v_skipped_no_email  INT := 0;
  v_sample_names      TEXT[] := ARRAY[]::TEXT[];
  v_party_id          UUID;
  v_contact_id        UUID;
  v_existing          UUID;
  v_party_name        TEXT;
BEGIN
  SELECT day_offset INTO v_first_day_offset
  FROM app.email_sequence_steps
  WHERE sequence_id = p_sequence_id
  ORDER BY step_order LIMIT 1;

  IF v_first_day_offset IS NULL THEN
    RAISE EXCEPTION 'Sequence has no steps';
  END IF;

  FOR v_party_id, v_party_name IN
    SELECT p.id, p.name
    FROM app.parties p
    WHERE p.organization_id = p_organization_id
      AND p.deleted_at IS NULL
      AND (p_module        IS NULL OR p.module::TEXT = p_module)
      AND (p_tiers         IS NULL OR p.tier::TEXT = ANY(p_tiers))
      AND (p_status        IS NULL OR p.status::TEXT = p_status)
      AND (p_country_code  IS NULL OR p.country_code = p_country_code)
      AND (p_industry_tag  IS NULL OR EXISTS (
             SELECT 1 FROM unnest(p.industry_tags) tag
             WHERE tag ILIKE '%' || p_industry_tag || '%'
           ))
      AND (p_name_contains IS NULL OR p.name ILIKE '%' || p_name_contains || '%')
    ORDER BY p.name
  LOOP
    v_total_matching := v_total_matching + 1;

    IF array_length(v_sample_names, 1) IS NULL OR array_length(v_sample_names, 1) < 5 THEN
      v_sample_names := v_sample_names || v_party_name;
    END IF;

    SELECT id INTO v_existing
    FROM app.email_sequence_enrollments
    WHERE sequence_id = p_sequence_id
      AND party_id    = v_party_id
      AND status      = 'active'::app.enrollment_status
    LIMIT 1;

    IF v_existing IS NOT NULL THEN
      v_skipped_dup := v_skipped_dup + 1;
      v_existing := NULL;
      CONTINUE;
    END IF;

    SELECT id INTO v_contact_id
    FROM app.contacts
    WHERE party_id        = v_party_id
      AND deleted_at      IS NULL
      AND is_active       = true
      AND do_not_contact  = false
      AND email           IS NOT NULL
      AND email           != ''
    ORDER BY is_primary DESC, created_at ASC
    LIMIT 1;

    IF v_contact_id IS NULL THEN
      v_skipped_no_email := v_skipped_no_email + 1;
      CONTINUE;
    END IF;

    IF NOT p_dry_run THEN
      INSERT INTO app.email_sequence_enrollments (
        organization_id, sequence_id, party_id, contact_id, enrolled_by,
        status, next_step_order, next_send_at
      ) VALUES (
        p_organization_id, p_sequence_id, v_party_id, v_contact_id, p_enrolled_by,
        'active'::app.enrollment_status, 0,
        now() + (v_first_day_offset || ' days')::INTERVAL
      );
    END IF;

    v_enrolled   := v_enrolled + 1;
    v_contact_id := NULL;
  END LOOP;

  RETURN QUERY SELECT
    v_total_matching,
    v_enrolled,
    v_skipped_dup,
    v_skipped_no_email,
    v_sample_names;
END;
$function$;

-- §8.4 count_email_history
CREATE OR REPLACE FUNCTION public.count_email_history(p_organization_id uuid)
RETURNS bigint
LANGUAGE sql
SECURITY DEFINER
AS $function$
  SELECT COUNT(*)
  FROM app.email_sequence_sends ss
  JOIN app.email_sequence_enrollments e ON e.id = ss.enrollment_id
  WHERE e.organization_id = p_organization_id;
$function$;

-- §8.5 create_campaign_from_template (overload 1 — 8 args)
CREATE OR REPLACE FUNCTION public.create_campaign_from_template(
  p_organization_id uuid,
  p_template_id     uuid,
  p_campaign_name   text,
  p_module          text DEFAULT NULL::text,
  p_tiers           text[] DEFAULT NULL::text[],
  p_status          text DEFAULT 'active'::text,    -- parties.status filter
  p_country_code    text DEFAULT NULL::text,
  p_enrolled_by     uuid DEFAULT NULL::uuid
)
RETURNS TABLE(
  sequence_id              uuid,
  total_matching           integer,
  enrolled_count           integer,
  skipped_already_enrolled integer,
  skipped_no_email         integer,
  sample_names             text[]
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_template_name     TEXT;
  v_template_subject  TEXT;
  v_template_body     TEXT;
  v_sequence_id       UUID;
  v_bulk              RECORD;
BEGIN
  SELECT name, subject, body_plain
  INTO v_template_name, v_template_subject, v_template_body
  FROM app.email_templates
  WHERE id = p_template_id AND organization_id = p_organization_id AND is_active = true;

  IF v_template_subject IS NULL THEN
    RAISE EXCEPTION 'Template not found or inactive';
  END IF;

  INSERT INTO app.email_sequences (organization_id, name, description, status)
  VALUES (p_organization_id, p_campaign_name,
          'Campaign from template: ' || v_template_name,
          'active'::app.email_sequence_status)
  RETURNING id INTO v_sequence_id;

  INSERT INTO app.email_sequence_steps (sequence_id, step_order, day_offset, subject, body_text)
  VALUES (v_sequence_id, 0, 0, v_template_subject, v_template_body);

  SELECT * INTO v_bulk
  FROM public.bulk_enroll_filtered(
    p_organization_id, v_sequence_id,
    p_module, p_tiers, p_status, p_country_code,
    p_enrolled_by, false
  )
  LIMIT 1;

  RETURN QUERY SELECT
    v_sequence_id,
    v_bulk.total_matching, v_bulk.enrolled_count,
    v_bulk.skipped_already_enrolled, v_bulk.skipped_no_email,
    v_bulk.sample_names;
END;
$function$;

-- §8.6 create_campaign_from_template (overload 2 — 10 args)
CREATE OR REPLACE FUNCTION public.create_campaign_from_template(
  p_organization_id uuid,
  p_template_id     uuid,
  p_campaign_name   text,
  p_module          text DEFAULT NULL::text,
  p_tiers           text[] DEFAULT NULL::text[],
  p_status          text DEFAULT 'active'::text,    -- parties.status filter
  p_country_code    text DEFAULT NULL::text,
  p_enrolled_by     uuid DEFAULT NULL::uuid,
  p_industry_tag    text DEFAULT NULL::text,
  p_name_contains   text DEFAULT NULL::text
)
RETURNS TABLE(
  sequence_id              uuid,
  total_matching           integer,
  enrolled_count           integer,
  skipped_already_enrolled integer,
  skipped_no_email         integer,
  sample_names             text[]
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_template_name     TEXT;
  v_template_subject  TEXT;
  v_template_body     TEXT;
  v_sequence_id       UUID;
  v_bulk              RECORD;
BEGIN
  SELECT name, subject, body_plain
  INTO v_template_name, v_template_subject, v_template_body
  FROM app.email_templates
  WHERE id = p_template_id AND organization_id = p_organization_id AND is_active = true;

  IF v_template_subject IS NULL THEN
    RAISE EXCEPTION 'Template not found or inactive';
  END IF;

  INSERT INTO app.email_sequences (organization_id, name, description, status)
  VALUES (p_organization_id, p_campaign_name,
          'Campaign from template: ' || v_template_name,
          'active'::app.email_sequence_status)
  RETURNING id INTO v_sequence_id;

  INSERT INTO app.email_sequence_steps (sequence_id, step_order, day_offset, subject, body_text)
  VALUES (v_sequence_id, 0, 0, v_template_subject, v_template_body);

  SELECT * INTO v_bulk
  FROM public.bulk_enroll_filtered(
    p_organization_id, v_sequence_id,
    p_module, p_tiers, p_status, p_country_code,
    p_enrolled_by, false,
    p_industry_tag, p_name_contains
  )
  LIMIT 1;

  RETURN QUERY SELECT
    v_sequence_id,
    v_bulk.total_matching, v_bulk.enrolled_count,
    v_bulk.skipped_already_enrolled, v_bulk.skipped_no_email,
    v_bulk.sample_names;
END;
$function$;

-- §8.7 create_sequence
CREATE OR REPLACE FUNCTION public.create_sequence(
  p_organization_id uuid,
  p_name            text,
  p_description     text,
  p_steps           jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_seq_id UUID;
BEGIN
  INSERT INTO app.email_sequences (organization_id, name, description, status)
  VALUES (p_organization_id, p_name, NULLIF(p_description, ''),
          'active'::app.email_sequence_status)
  RETURNING id INTO v_seq_id;

  IF jsonb_array_length(p_steps) > 0 THEN
    INSERT INTO app.email_sequence_steps
      (sequence_id, step_order, day_offset, subject, body_text)
    SELECT
      v_seq_id,
      (step->>'step_order')::INT,
      (step->>'day_offset')::INT,
      step->>'subject',
      step->>'body_text'
    FROM jsonb_array_elements(p_steps) step;
  END IF;

  RETURN v_seq_id;
END;
$function$;

-- §8.8 enroll_in_sequence
CREATE OR REPLACE FUNCTION public.enroll_in_sequence(
  p_organization_id uuid,
  p_sequence_id     uuid,
  p_party_id        uuid,
  p_contact_id      uuid,
  p_enrolled_by     uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_enrollment_id    UUID;
  v_first_day_offset INT;
BEGIN
  SELECT day_offset INTO v_first_day_offset
  FROM app.email_sequence_steps
  WHERE sequence_id = p_sequence_id
  ORDER BY step_order
  LIMIT 1;

  IF v_first_day_offset IS NULL THEN
    RAISE EXCEPTION 'Sequence has no steps';
  END IF;

  INSERT INTO app.email_sequence_enrollments (
    organization_id, sequence_id, party_id, contact_id, enrolled_by,
    status, next_step_order, next_send_at
  ) VALUES (
    p_organization_id, p_sequence_id, p_party_id, p_contact_id, p_enrolled_by,
    'active'::app.enrollment_status, 0,
    now() + (v_first_day_offset || ' days')::INTERVAL
  )
  RETURNING id INTO v_enrollment_id;

  RETURN v_enrollment_id;
END;
$function$;

-- §8.9 get_due_enrollments — RETURNS 컬럼명 org_id → organization_id (δ)
CREATE OR REPLACE FUNCTION public.get_due_enrollments()
RETURNS TABLE(
  enrollment_id     uuid,
  organization_id   uuid,
  sequence_id       uuid,
  party_id          uuid,
  contact_id        uuid,
  enrolled_by       uuid,
  enrolled_at       timestamp with time zone,
  next_step_order   integer,
  step_id           uuid,
  step_day_offset   integer,
  step_subject      text,
  step_body_text    text,
  is_last_step      boolean
)
LANGUAGE sql
SECURITY DEFINER
AS $function$
  SELECT
    e.id                                                         AS enrollment_id,
    e.organization_id,
    e.sequence_id,
    e.party_id,
    e.contact_id,
    e.enrolled_by,
    e.enrolled_at,
    e.next_step_order,
    st.id                                                        AS step_id,
    st.day_offset                                                AS step_day_offset,
    st.subject                                                   AS step_subject,
    st.body_text                                                 AS step_body_text,
    (st.step_order = (
      SELECT MAX(s2.step_order)
      FROM app.email_sequence_steps s2
      WHERE s2.sequence_id = e.sequence_id
    ))                                                           AS is_last_step
  FROM app.email_sequence_enrollments e
  JOIN app.email_sequence_steps st
    ON st.sequence_id   = e.sequence_id
   AND st.step_order    = e.next_step_order
  WHERE e.status        = 'active'::app.enrollment_status
    AND e.next_send_at <= now()
  ORDER BY e.next_send_at;
$function$;

-- §8.10 get_email_history — send_status text → app.send_status (δ)
CREATE OR REPLACE FUNCTION public.get_email_history(
  p_organization_id uuid,
  p_limit           integer DEFAULT 100,
  p_offset          integer DEFAULT 0
)
RETURNS TABLE(
  send_id             uuid,
  sent_at             timestamp with time zone,
  sequence_id         uuid,
  sequence_name       text,
  step_order          integer,
  enrollment_id       uuid,
  party_id            uuid,
  party_name          text,
  contact_email       text,
  contact_full_name   text,
  send_status         app.send_status,
  open_count          integer,
  first_opened_at     timestamp with time zone,
  click_count         integer,
  communication_id    uuid
)
LANGUAGE sql
SECURITY DEFINER
AS $function$
  SELECT
    ss.id,
    ss.sent_at,
    e.sequence_id,
    s.name,
    ss.step_order,
    ss.enrollment_id,
    e.party_id,
    p.name,
    c.email,
    c.full_name,
    ss.status,
    COALESCE(et.open_count, 0)::INT,
    et.first_opened_at,
    COALESCE(et.click_count, 0)::INT,
    ss.communication_id
  FROM app.email_sequence_sends ss
  JOIN app.email_sequence_enrollments e
    ON e.id = ss.enrollment_id
  JOIN app.email_sequences s
    ON s.id = e.sequence_id
  LEFT JOIN app.parties p
    ON p.id = e.party_id
  LEFT JOIN app.contacts c
    ON c.id = e.contact_id
  LEFT JOIN app.email_tracking et
    ON et.communication_id = ss.communication_id
  WHERE e.organization_id = p_organization_id
  ORDER BY ss.sent_at DESC NULLS LAST
  LIMIT p_limit
  OFFSET p_offset;
$function$;

-- §8.11 get_party_enrollments — status text → app.enrollment_status (δ)
CREATE OR REPLACE FUNCTION public.get_party_enrollments(p_party_id uuid)
RETURNS TABLE(
  id                uuid,
  sequence_id       uuid,
  sequence_name     text,
  status            app.enrollment_status,
  next_step_order   integer,
  total_steps       bigint,
  next_send_at      timestamp with time zone,
  enrolled_at       timestamp with time zone,
  sends_count       bigint
)
LANGUAGE sql
SECURITY DEFINER
AS $function$
  SELECT
    e.id,
    e.sequence_id,
    s.name                    AS sequence_name,
    e.status,
    e.next_step_order,
    COUNT(DISTINCT st.id)     AS total_steps,
    e.next_send_at,
    e.enrolled_at,
    COUNT(DISTINCT ss.id) FILTER (WHERE ss.status = 'sent'::app.send_status) AS sends_count
  FROM app.email_sequence_enrollments e
  JOIN app.email_sequences s
    ON s.id = e.sequence_id
  LEFT JOIN app.email_sequence_steps st
    ON st.sequence_id = e.sequence_id
  LEFT JOIN app.email_sequence_sends ss
    ON ss.enrollment_id = e.id
  WHERE e.party_id = p_party_id
  GROUP BY e.id, s.name
  ORDER BY e.enrolled_at DESC;
$function$;

-- §8.12 get_sequence_with_steps — jsonb 키 org_id → organization_id (β)
CREATE OR REPLACE FUNCTION public.get_sequence_with_steps(p_sequence_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'id',              s.id,
    'organization_id', s.organization_id,
    'name',            s.name,
    'description',     s.description,
    'status',          s.status,
    'created_at',      s.created_at,
    'steps', COALESCE(
      (SELECT jsonb_agg(
        jsonb_build_object(
          'id',         st.id,
          'step_order', st.step_order,
          'day_offset', st.day_offset,
          'subject',    st.subject,
          'body_text',  st.body_text
        ) ORDER BY st.step_order
      ) FROM app.email_sequence_steps st
        WHERE st.sequence_id = s.id),
      '[]'::JSONB
    )
  )
  INTO v_result
  FROM app.email_sequences s
  WHERE s.id = p_sequence_id;

  RETURN v_result;
END;
$function$;

-- §8.13 list_sequences — status text → app.email_sequence_status (δ)
CREATE OR REPLACE FUNCTION public.list_sequences(p_organization_id uuid)
RETURNS TABLE(
  id                  uuid,
  name                text,
  description         text,
  status              app.email_sequence_status,
  step_count          bigint,
  active_enrollments  bigint,
  total_sends         bigint,
  created_at          timestamp with time zone
)
LANGUAGE sql
SECURITY DEFINER
AS $function$
  SELECT
    s.id,
    s.name,
    s.description,
    s.status,
    COUNT(DISTINCT st.id)                                                    AS step_count,
    COUNT(DISTINCT e.id) FILTER (WHERE e.status = 'active'::app.enrollment_status) AS active_enrollments,
    COUNT(DISTINCT ss.id) FILTER (WHERE ss.status = 'sent'::app.send_status)       AS total_sends,
    s.created_at
  FROM app.email_sequences s
  LEFT JOIN app.email_sequence_steps st
    ON st.sequence_id = s.id
  LEFT JOIN app.email_sequence_enrollments e
    ON e.sequence_id = s.id
  LEFT JOIN app.email_sequence_sends ss
    ON ss.enrollment_id = e.id
  WHERE s.organization_id = p_organization_id
    AND s.status != 'archived'::app.email_sequence_status
  GROUP BY s.id
  ORDER BY s.created_at DESC;
$function$;

DO $func_notice$ BEGIN
  RAISE NOTICE '[21] §8 13 functions 재정의 완료 (β + δ)';
END $func_notice$;

-- §8.14 archive_sequence (v2 추가) — SQL function, enum literal explicit cast
CREATE OR REPLACE FUNCTION public.archive_sequence(p_sequence_id uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
AS $function$
  UPDATE app.email_sequences
  SET status     = 'archived'::app.email_sequence_status,
      updated_at = now()
  WHERE id = p_sequence_id;
$function$;

-- §8.15 cancel_enrollment (v2 추가) — SQL function, enum literal explicit cast
CREATE OR REPLACE FUNCTION public.cancel_enrollment(p_enrollment_id uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
AS $function$
  UPDATE app.email_sequence_enrollments
  SET status       = 'cancelled'::app.enrollment_status,
      cancelled_at = now(),
      updated_at   = now()
  WHERE id = p_enrollment_id;
$function$;

DO $func_v2_notice$ BEGIN
  RAISE NOTICE '[21] §8 v2 추가 — archive_sequence + cancel_enrollment 재정의';
END $func_v2_notice$;

-- ═══════════════════════════════════════════════════════════════════════
-- §9. 검증
-- ═══════════════════════════════════════════════════════════════════════

DO $verify$
DECLARE
  v_es_org_id_exists boolean; v_es_organization_id_exists boolean;
  v_ese_org_id_exists boolean; v_ese_organization_id_exists boolean;
  v_es_status_type text; v_ese_status_type text; v_esn_status_type text;
  v_es_rows int; v_ese_rows int; v_esn_rows int; v_est_rows int;
  v_func_count int; v_overload_count int;
  v_policy_count int;
  v_trigger_count int;
  v_trigger_func_count int;
  v_check_remaining int;
  v_paused_in_enum boolean;
  v_partial_idx_count int;  -- v4: 재생성된 partial index 확인
BEGIN
  -- §3 컬럼 rename 확인
  SELECT EXISTS(SELECT 1 FROM information_schema.columns
                WHERE table_schema='app' AND table_name='email_sequences'
                  AND column_name='org_id') INTO v_es_org_id_exists;
  SELECT EXISTS(SELECT 1 FROM information_schema.columns
                WHERE table_schema='app' AND table_name='email_sequences'
                  AND column_name='organization_id') INTO v_es_organization_id_exists;
  SELECT EXISTS(SELECT 1 FROM information_schema.columns
                WHERE table_schema='app' AND table_name='email_sequence_enrollments'
                  AND column_name='org_id') INTO v_ese_org_id_exists;
  SELECT EXISTS(SELECT 1 FROM information_schema.columns
                WHERE table_schema='app' AND table_name='email_sequence_enrollments'
                  AND column_name='organization_id') INTO v_ese_organization_id_exists;

  -- §4 enum cast 확인
  SELECT udt_name INTO v_es_status_type FROM information_schema.columns
    WHERE table_schema='app' AND table_name='email_sequences' AND column_name='status';
  SELECT udt_name INTO v_ese_status_type FROM information_schema.columns
    WHERE table_schema='app' AND table_name='email_sequence_enrollments' AND column_name='status';
  SELECT udt_name INTO v_esn_status_type FROM information_schema.columns
    WHERE table_schema='app' AND table_name='email_sequence_sends' AND column_name='status';

  -- Rows 보존
  SELECT COUNT(*) INTO v_es_rows  FROM app.email_sequences;
  SELECT COUNT(*) INTO v_ese_rows FROM app.email_sequence_enrollments;
  SELECT COUNT(*) INTO v_esn_rows FROM app.email_sequence_sends;
  SELECT COUNT(*) INTO v_est_rows FROM app.email_sequence_steps;

  -- §8 15 함수 재정의 확인 (13 unique names, 15 overloads — v2: archive + cancel 포함)
  SELECT COUNT(DISTINCT p.proname) INTO v_func_count
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public'
      AND p.proname IN (
        'advance_enrollment','bulk_enroll_filtered','count_email_history',
        'create_campaign_from_template','create_sequence','enroll_in_sequence',
        'get_due_enrollments','get_email_history','get_party_enrollments',
        'get_sequence_with_steps','list_sequences',
        'archive_sequence','cancel_enrollment'
      );
  SELECT COUNT(*) INTO v_overload_count
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public'
      AND p.proname IN (
        'advance_enrollment','bulk_enroll_filtered','count_email_history',
        'create_campaign_from_template','create_sequence','enroll_in_sequence',
        'get_due_enrollments','get_email_history','get_party_enrollments',
        'get_sequence_with_steps','list_sequences',
        'archive_sequence','cancel_enrollment'
      );

  -- §7 8 policies 재생성 확인
  SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE schemaname='app'
      AND tablename IN ('email_sequences','email_sequence_enrollments');

  -- §6 2 triggers 재생성 확인
  SELECT COUNT(*) INTO v_trigger_count
    FROM pg_trigger tg
    JOIN pg_class cls ON cls.oid = tg.tgrelid
    JOIN pg_namespace ns ON ns.oid = cls.relnamespace
    WHERE ns.nspname='app'
      AND tg.tgname IN ('trg_ess_set_organization_id','trg_esn_set_organization_id')
      AND NOT tg.tgisinternal;

  -- §5 2 trigger functions 재생성 확인
  SELECT COUNT(*) INTO v_trigger_func_count
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='app'
      AND p.proname IN ('fn_ess_set_organization_id','fn_esn_set_organization_id');

  -- v3: CHECK constraint 3개 모두 drop 됐는지 확인 (잔존 0 expected)
  SELECT COUNT(*) INTO v_check_remaining
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    WHERE c.contype = 'c'
      AND t.relname IN ('email_sequences','email_sequence_enrollments','email_sequence_sends')
      AND c.conname LIKE '%status_check';

  -- v3: 'paused' value 가 enrollment_status enum 에 commit 됐는지 확인
  SELECT EXISTS(
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname='app' AND t.typname='enrollment_status' AND e.enumlabel='paused'
  ) INTO v_paused_in_enum;

  -- v4: 재생성된 partial index 2개 확인
  SELECT COUNT(*) INTO v_partial_idx_count
    FROM pg_indexes
    WHERE schemaname='app'
      AND tablename='email_sequence_enrollments'
      AND indexname IN ('idx_seq_enrollments_due','idx_unique_active_enrollment');

  RAISE NOTICE '[21] ══════════════════════════════════════════════════════';
  RAISE NOTICE '[21] Stage 21 검증 결과';
  RAISE NOTICE '[21] ══════════════════════════════════════════════════════';
  RAISE NOTICE '[21]   §3 Column rename:';
  RAISE NOTICE '[21]     email_sequences.org_id 제거          : %', NOT v_es_org_id_exists;
  RAISE NOTICE '[21]     email_sequences.organization_id 존재 : %', v_es_organization_id_exists;
  RAISE NOTICE '[21]     email_sequence_enrollments.org_id 제거 : %', NOT v_ese_org_id_exists;
  RAISE NOTICE '[21]     email_sequence_enrollments.org_id 존재 : %', v_ese_organization_id_exists;
  RAISE NOTICE '[21]   §4 Status enum cast:';
  RAISE NOTICE '[21]     email_sequences.status type          : % (email_sequence_status expected)', v_es_status_type;
  RAISE NOTICE '[21]     email_sequence_enrollments.status    : % (enrollment_status expected)', v_ese_status_type;
  RAISE NOTICE '[21]     email_sequence_sends.status          : % (send_status expected)', v_esn_status_type;
  RAISE NOTICE '[21]   §5-6 Triggers:';
  RAISE NOTICE '[21]     2 trigger functions 재생성          : %', v_trigger_func_count;
  RAISE NOTICE '[21]     2 triggers 재생성                   : %', v_trigger_count;
  RAISE NOTICE '[21]   §7 RLS policies (8 expected)          : %', v_policy_count;
  RAISE NOTICE '[21]   §8 Functions:';
  RAISE NOTICE '[21]     unique names (13 expected)           : %', v_func_count;
  RAISE NOTICE '[21]     overloads total (15 expected)        : %', v_overload_count;
  RAISE NOTICE '[21]   v3 추가 검증:';
  RAISE NOTICE '[21]     CHECK constraints 잔존 (0 expected)  : %', v_check_remaining;
  RAISE NOTICE '[21]     paused in enrollment_status enum     : %', v_paused_in_enum;
  RAISE NOTICE '[21]   v4 추가 검증:';
  RAISE NOTICE '[21]     partial indexes 재생성 (2 expected)  : %', v_partial_idx_count;
  RAISE NOTICE '[21]   ─────────────────────────────────────────────────';
  RAISE NOTICE '[21]   Rows 보존:';
  RAISE NOTICE '[21]     email_sequences            : % (≥2 expected)',  v_es_rows;
  RAISE NOTICE '[21]     email_sequence_enrollments : % (≥6 expected)',  v_ese_rows;
  RAISE NOTICE '[21]     email_sequence_sends       : % (≥5 expected)',  v_esn_rows;
  RAISE NOTICE '[21]     email_sequence_steps       : %', v_est_rows;
  RAISE NOTICE '[21] ══════════════════════════════════════════════════════';

  -- Hard assertions
  IF v_es_org_id_exists THEN RAISE EXCEPTION '[21] email_sequences.org_id 잔재'; END IF;
  IF NOT v_es_organization_id_exists THEN RAISE EXCEPTION '[21] email_sequences.organization_id 누락'; END IF;
  IF v_ese_org_id_exists THEN RAISE EXCEPTION '[21] email_sequence_enrollments.org_id 잔재'; END IF;
  IF NOT v_ese_organization_id_exists THEN RAISE EXCEPTION '[21] email_sequence_enrollments.organization_id 누락'; END IF;

  IF v_es_status_type != 'email_sequence_status' THEN
    RAISE EXCEPTION '[21] email_sequences.status enum cast 실패: %', v_es_status_type;
  END IF;
  IF v_ese_status_type != 'enrollment_status' THEN
    RAISE EXCEPTION '[21] email_sequence_enrollments.status enum cast 실패: %', v_ese_status_type;
  END IF;
  IF v_esn_status_type != 'send_status' THEN
    RAISE EXCEPTION '[21] email_sequence_sends.status enum cast 실패: %', v_esn_status_type;
  END IF;

  IF v_trigger_func_count != 2 THEN RAISE EXCEPTION '[21] trigger functions 누락: %', v_trigger_func_count; END IF;
  IF v_trigger_count != 2 THEN RAISE EXCEPTION '[21] triggers 누락: %', v_trigger_count; END IF;
  IF v_policy_count != 8 THEN RAISE EXCEPTION '[21] RLS policies 부정합 (8 expected): %', v_policy_count; END IF;
  IF v_func_count != 13 THEN RAISE EXCEPTION '[21] unique functions 부정합 (13 expected): %', v_func_count; END IF;
  IF v_overload_count != 15 THEN RAISE EXCEPTION '[21] overload count 부정합 (15 expected): %', v_overload_count; END IF;

  -- v3 assertions
  IF v_check_remaining != 0 THEN
    RAISE EXCEPTION '[21] CHECK constraint 잔존: % (DROP 누락)', v_check_remaining;
  END IF;
  IF NOT v_paused_in_enum THEN
    RAISE EXCEPTION '[21] enrollment_status.paused 누락';
  END IF;

  -- v4 assertions
  IF v_partial_idx_count != 2 THEN
    RAISE EXCEPTION '[21] partial index 재생성 누락: % (2 expected)', v_partial_idx_count;
  END IF;

  -- Rows 보존 (활성 데이터 — 증가 허용, 감소 차단)
  IF v_es_rows  < 2 THEN RAISE EXCEPTION '[21] email_sequences rows 손실: %', v_es_rows; END IF;
  IF v_ese_rows < 6 THEN RAISE EXCEPTION '[21] email_sequence_enrollments rows 손실: %', v_ese_rows; END IF;
  IF v_esn_rows < 5 THEN RAISE EXCEPTION '[21] email_sequence_sends rows 손실: %', v_esn_rows; END IF;

  RAISE NOTICE '[21] ✅ Stage 21 v4 완료 — email_sequence URM 100%% 일치';
  RAISE NOTICE '[21]   - org_id → organization_id (2 테이블)';
  RAISE NOTICE '[21]   - status text → enum (3 컬럼, CHECK constraint 대체)';
  RAISE NOTICE '[21]   - partial index 2개 재생성 (enum literal)';
  RAISE NOTICE '[21]   - 15 functions (13 β+δ + 2 SQL func explicit cast)';
  RAISE NOTICE '[21]   - 8 RLS policies + 2 triggers 재생성';
  RAISE NOTICE '[21]   - enrollment_status enum 에 paused value 포함 (총 5 values)';
  RAISE NOTICE '[21] ─────────────────────────────────────────────────';
  RAISE NOTICE '[21] 다음 작업 (Stage 22): TS types 재생성 + app code patch';
END $verify$;

-- ═══════════════════════════════════════════════════════════════════════
-- §10. PostgREST 캐시 reload
-- ═══════════════════════════════════════════════════════════════════════

NOTIFY pgrst, 'reload schema';

COMMIT;

-- ============================================================================
-- App code 측 영향 (Stage 22 에서 흡수):
--   1. TS types 재생성 (필수):
--      npx supabase gen types typescript --project-id ogenmrgxwhpbfepeldqx > src/types/database.types.ts
--   2. RPC 호출 인자명 정정:
--      bulk_enroll_filtered({ p_org_id: ... })           → { p_organization_id: ... }
--      count_email_history({ p_org_id: ... })             → { p_organization_id: ... }
--      create_campaign_from_template({ p_org_id: ... })   → { p_organization_id: ... }
--      create_sequence({ p_org_id: ... })                 → { p_organization_id: ... }
--      enroll_in_sequence({ p_org_id: ... })              → { p_organization_id: ... }
--      get_email_history({ p_org_id: ... })               → { p_organization_id: ... }
--      list_sequences({ p_org_id: ... })                  → { p_organization_id: ... }
--   3. JSON 키 정정 (get_sequence_with_steps 결과):
--      response.org_id → response.organization_id
--   4. status type 강화 (string → enum union type):
--      get_party_enrollments 의 status: 'active' | 'completed' | 'cancelled' | 'failed'
--      list_sequences 의 status: 'draft' | 'active' | 'paused' | 'archived'
--      get_email_history 의 send_status: 'pending' | 'sent' | 'skipped' | 'bounced' | 'failed'
--      get_due_enrollments 의 org_id → organization_id (RETURNS 컬럼명)
-- ============================================================================
