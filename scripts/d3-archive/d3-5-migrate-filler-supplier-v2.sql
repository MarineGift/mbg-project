-- =============================================================================
-- D3-5 Migration v2: app.party_type 값 'filler' → 'filler_supplier' 재명명
-- v1 에서 발견된 이슈 수정:
--   - v_filler_suppliers 등 VIEW 가 information_schema.columns 에 포함되어
--     UPDATE 대상에 잘못 포함되던 문제
--   - table_type = 'BASE TABLE' 필터 추가
-- 안전 장치 (v1 과 동일):
--   - 단일 트랜잭션 (BEGIN..COMMIT)
--   - 검증 실패 시 RAISE EXCEPTION → 자동 ROLLBACK
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- [1/3] PRE-CHECK: BASE TABLE 만 대상 + 'filler' row count
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    rec           record;
    filler_count  integer;
    total_before  integer := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== PRE-CHECK: app.party_type 사용 BASE TABLE 컬럼 ===';
    FOR rec IN
        SELECT c.table_schema, c.table_name, c.column_name
        FROM information_schema.columns c
        JOIN information_schema.tables  t
          ON t.table_schema = c.table_schema
         AND t.table_name   = c.table_name
        WHERE c.udt_schema = 'app'
          AND c.udt_name   = 'party_type'
          AND t.table_type = 'BASE TABLE'      -- ★ VIEW 제외
        ORDER BY c.table_schema, c.table_name, c.column_name
    LOOP
        EXECUTE format(
            'SELECT COUNT(*) FROM %I.%I WHERE %I::text = ''filler''',
            rec.table_schema, rec.table_name, rec.column_name
        ) INTO filler_count;
        RAISE NOTICE '  %.%.% — % filler rows',
            rec.table_schema, rec.table_name, rec.column_name, filler_count;
        total_before := total_before + filler_count;
    END LOOP;
    RAISE NOTICE '';
    RAISE NOTICE '총 변경 대상 (BASE TABLE only): % rows', total_before;
    RAISE NOTICE '';
END $$;


-- -----------------------------------------------------------------------------
-- [2/3] UPDATE: BASE TABLE 만 대상으로 'filler' → 'filler_supplier'
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    rec            record;
    updated_count  integer;
    total_updated  integer := 0;
BEGIN
    RAISE NOTICE '=== UPDATE 실행 ===';
    FOR rec IN
        SELECT c.table_schema, c.table_name, c.column_name
        FROM information_schema.columns c
        JOIN information_schema.tables  t
          ON t.table_schema = c.table_schema
         AND t.table_name   = c.table_name
        WHERE c.udt_schema = 'app'
          AND c.udt_name   = 'party_type'
          AND t.table_type = 'BASE TABLE'      -- ★ VIEW 제외
        ORDER BY c.table_schema, c.table_name, c.column_name
    LOOP
        EXECUTE format(
            'UPDATE %I.%I SET %I = ''filler_supplier''::app.party_type WHERE %I = ''filler''::app.party_type',
            rec.table_schema, rec.table_name, rec.column_name, rec.column_name
        );
        GET DIAGNOSTICS updated_count = ROW_COUNT;
        IF updated_count > 0 THEN
            RAISE NOTICE '  ✓ %.%.% — % rows updated',
                rec.table_schema, rec.table_name, rec.column_name, updated_count;
        END IF;
        total_updated := total_updated + updated_count;
    END LOOP;
    RAISE NOTICE '';
    RAISE NOTICE '총 UPDATE: % rows', total_updated;
    RAISE NOTICE '';
END $$;


-- -----------------------------------------------------------------------------
-- [3/3] VERIFY: BASE TABLE 의 잔여 'filler' = 0 확인. 아니면 ROLLBACK.
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    rec           record;
    filler_count  integer;
    total_after   integer := 0;
BEGIN
    RAISE NOTICE '=== POST-CHECK (BASE TABLE only) ===';
    FOR rec IN
        SELECT c.table_schema, c.table_name, c.column_name
        FROM information_schema.columns c
        JOIN information_schema.tables  t
          ON t.table_schema = c.table_schema
         AND t.table_name   = c.table_name
        WHERE c.udt_schema = 'app'
          AND c.udt_name   = 'party_type'
          AND t.table_type = 'BASE TABLE'      -- ★ VIEW 제외
        ORDER BY c.table_schema, c.table_name, c.column_name
    LOOP
        EXECUTE format(
            'SELECT COUNT(*) FROM %I.%I WHERE %I::text = ''filler''',
            rec.table_schema, rec.table_name, rec.column_name
        ) INTO filler_count;
        total_after := total_after + filler_count;
    END LOOP;

    IF total_after > 0 THEN
        RAISE EXCEPTION '검증 실패: BASE TABLE 에 % 개의 filler row 가 남아있음. ROLLBACK 됨.', total_after;
    END IF;

    RAISE NOTICE '  ✓ BASE TABLE 잔여 filler row: 0';
    RAISE NOTICE '';
    RAISE NOTICE '=== 마이그레이션 성공 ===';
    RAISE NOTICE '';
    RAISE NOTICE '참고: 다음 VIEW 들은 baseline 테이블 데이터를 자동 반영합니다:';
    RAISE NOTICE '  - app.v_filler_suppliers';
    RAISE NOTICE '  - 기타 app.v_* (필요 시 별도 확인)';
END $$;


COMMIT;


-- =============================================================================
-- 사후 확인 (선택, 별도 실행)
-- =============================================================================
-- 1) 기본 테이블 확인
-- SELECT party_type::text, COUNT(*)
-- FROM app.parties
-- WHERE deleted_at IS NULL
-- GROUP BY party_type
-- ORDER BY party_type;
--
-- 예상 결과:
--   customer         14
--   filler_supplier  229    ← OK
--   investor         119
--   paper_mill       1067
--   partner          8
--
-- 2) VIEW 자동 반영 확인
-- SELECT firm_module::text, COUNT(*)
-- FROM app.v_filler_suppliers
-- GROUP BY firm_module;
-- =============================================================================
