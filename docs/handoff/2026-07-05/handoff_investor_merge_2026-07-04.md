# Handoff — 투자사 중복 병합 (31쌍, Option A) (2026-07-04)

## 결정 확정
- **canonical = 간결한 통용명** (Accel, Sequoia Capital, Dallas Venture Capital, DCVC, a16z 등)
- **31쌍 병합** / **제외 2건**: 5AM Ventures vs II(별개 펀드), ICONIQ Growth vs Capital(별도 비히클 — Growth 미병합. Iconiq Capital↔ICONIQ Capital 대소문자만 병합)
- Dallas 웹 확정: "Dallas Venture Partners"는 DVC의 **옛 이름**(현 미국 법인 Dallas Venture Capital LLC, Irving TX) → 병합
- 전체 매핑: `investor_merge_map.csv` (keep_name / canonical_id / merge_id / rationale)

## ⚠️ 2단계 실행 (FK 정확성 때문에 필수)
자식 테이블을 추측으로 재지정하면 관계가 누락됩니다. 반드시:

### 1) PROBE 먼저 — `sql/fix_investor_merge_probe.sql` (READ ONLY)
`app.parties`/`investor_profile`를 참조하는 **모든 FK 테이블·컬럼**을 출력.
→ 결과 CSV를 회신해 주세요.

### 2) MERGE — `sql/fix_investor_merge_31pairs.sql`
probe 결과에 맞춰 (3) REPARENT 섹션의 `update app.<table> ...` 줄을 확정한 뒤 실행.
- **트랜잭션(begin/commit)으로 감쌈** — 이상하면 `ROLLBACK;`
- (0) 안전검사: 31쌍 모두 존재·investor·미삭제·상호구별 아니면 즉시 abort
- (1) DRY-RUN 카운트(주석 해제해 먼저 확인)
- (2) canonical 빈 필드 보충 + interest_tags jsonb 합집합
- (3) 자식 재지정 ← **probe 결과로 채움**
- (4) investor_profile 하위링크 이관(중복 회피) → merge profile 삭제
- (5) merge party **soft-delete**(deleted_at + audit note) — hard-delete 없음
- (6) 검증: merge_still_active=0, canonical_active=31

## 실행 순서
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
# 1) Supabase에서 probe 실행 → FK 목록 CSV 회신
# 2) (회신 후) 최종 merge SQL 받아서 실행
git add sql/ docs/ ; git commit -m "chore(db): investor dedupe - probe + 31-pair merge map" ; git push origin marinebiogroup
```

## 안전장치 요약
- soft-delete만 사용(복구 가능), 트랜잭션 래핑, 사전 존재검증, dry-run, canonical 정보 손실 방지(빈 필드만 보충 + 태그 합집합)
- 병합 후 디렉토리 party 수가 31 감소해야 함 (554 → 523 예상)

## 다음
probe 결과 주시면 REPARENT 섹션을 확정한 **최종 실행본**을 즉시 생성합니다. 그 후 Paper Mills / Filler Suppliers 중복도 동일 방식으로 진행 가능.
