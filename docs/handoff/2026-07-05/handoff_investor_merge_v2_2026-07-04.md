# Handoff — 투자사 병합 v2 (문법 에러 수정) (2026-07-04)

## 두 가지 수정
1. **42601 syntax error 원인**: VALUES 각 행 뒤의 `-- 이름` 인라인 주석을 Supabase 편집기가 문장 분할하다 깨짐 → **인라인 주석 전부 제거**. 매핑 참조는 `investor_merge_map.csv`로 분리.
2. **자식 재지정 자동화**: probe로 테이블을 일일이 확정하지 않아도 되게, `to_regclass` 가드 + `information_schema` 컬럼 조회로 **존재하는 테이블의 party 참조 컬럼만 자동 재지정**하는 do-block으로 교체. 없는 테이블은 에러 없이 skip.

## 파일
- `sql/fix_investor_merge_31pairs_v2.sql` — 실행본 (v1 대체)
- `sql/fix_investor_merge_probe_fk.sql` — FK 목록만 재조회(선택). probe #61은 컬럼만 왔으므로, 이걸 돌려 결과를 주시면 do-block 배열에 누락 테이블이 없는지 교차확인 가능.

## 실행 (둘 중 택1)
**안전 우선 (권장):**
1. `fix_investor_merge_probe_fk.sql` 실행 → FK 테이블 목록 CSV 회신 → 누락 있으면 do-block에 1줄 추가 후 실행
**바로 실행:**
1. `fix_investor_merge_31pairs_v2.sql`을 그대로 실행 (do-block이 흔한 CRM 자식 테이블을 이미 커버, 미존재는 skip). 트랜잭션이라 (6) 검증에서 이상하면 `ROLLBACK;`

## 안전장치 (v1과 동일 유지)
- 트랜잭션 래핑 / (0) 존재·investor·미삭제 검증 abort / soft-delete만 / canonical 정보 보충·태그·sector 합집합 / (6) 검증 0·31

## 기대 결과
- (6): merge_still_active=0, canonical_active=31
- 디렉토리 party 554 → 523

## mover
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
## Finish
```powershell
cd C:\dev\mbg-project
git add sql/ docs/ ; git commit -m "chore(db): investor dedupe merge v2 (31 pairs, comment-free VALUES, auto-reparent)" ; git push origin marinebiogroup
```
