# D5 사전결정 framework — 5 항목

**전제**: `D5-0-audit-report.md` (stage29c 산출물) + `D5-0 urm-diagnostic` 결과를 본 다음에 최종 결정. 이 문서는 옵션 매트릭스 + 추천안.

---

## Decision 1 — urm 스키마 design 확정됐는가?

**판단 입력**: `stage29c/02_type_regeneration/urm_schema_typescript_stub.ts` + `D5-0-urm-diagnostic` 의 result set [5] (urm 컬럼 전체)

| 옵션 | 설명 | 위험 | 비용 |
|---|---|---|---|
| **A. stub 그대로 채택** | stage29c 산출물을 그대로 사용 | 만든 시점 ≠ 지금. D3/D4 변경 (party_type 5값 enum, ai.* column rename 등) 반영 안 됐을 수 있음 | 낮음 |
| **B. stub 검토 + 미세 조정** | D3/D4 변경사항 패치만 적용 | 누락 발견 가능성 | 중간 |
| **C. 처음부터 재설계** | app.* 현재 상태 기준 신규 DDL | 가장 안전하지만 stage29c 작업 낭비 | 높음 |

**추천**: **B**. 이유 — stage29c 가 D3 이전에 작성되었을 가능성이 높음 (`module` → `party_type` rename 반영 여부 확인 필요). audit 결과 받은 후 diff 떠서 결정.

**확인 trigger 질문**: stage29c stub 의 컬럼명에 `module` 이 있는가? `party_type` 인가?

---

## Decision 2 — app.* vs urm.* 분담 전략

**핵심 질문**: urm 이 app 을 *완전 대체* 할 것인가, 영구 *공존* 할 것인가?

| 옵션 | 설명 | 장점 | 단점 |
|---|---|---|---|
| **A. urm 완전 대체** | D5 마지막에 app.* DROP | 깔끔, 단일 source of truth | 마이그레이션 끝나야 코드 안정. 롤백 시 app 복구 필요 |
| **B. 영구 공존** | app = legacy/read-only, urm = active write | 안전, 즉시 cutover 가능 | 두 스키마 영구 유지 비용. 혼란 가능 |
| **C. 점진 cutover** | 모듈별로 app → urm 이전 후 모듈별로 app 제거 | 위험 분산 | 작업 기간 길어짐, 중간 상태 복잡 |

**추천**: **A** (완전 대체). 이유 — handoff doc 의 "urm.* 스키마로 완전 이전" 표현, 그리고 industry.* 처럼 별도 비즈니스 도메인이 아니라 *동일 데이터의 재구조화* 이기 때문. B 는 dual-write 부담이 너무 큼.

단, **app.* DROP 은 D5 마지막 phase (D5-7)** — 그 전까지 app.* 는 deprecation 상태로 read-only 유지 가능.

---

## Decision 3 — 데이터 이전 전략

**판단 입력**: 데이터 크기. handoff 의 party 분포 기준 1437 rows. contacts/deals 까지 합쳐도 추정 1만 rows 이하. **충분히 작음**.

| 옵션 | 설명 | 다운타임 | 복잡도 |
|---|---|---|---|
| **A. 한 번에 dump+load (단일 트랜잭션)** | `INSERT INTO urm.x SELECT * FROM app.x` 모든 테이블 한 번에 | 단일 트랜잭션 시간 (수초 ~ 1분) | 낮음 |
| **B. 점진적 이중쓰기** | app + urm 양쪽 쓰기, urm 검증 후 read 도 urm 으로 전환 | 무중단 | 매우 높음 (sync trigger, 충돌 해결, race condition) |
| **C. 모듈별 단계 cutover** | parties 먼저 cutover → contacts → deals ... | 모듈별 부분 다운타임 | 중간. FK cross-schema 처리 까다로움 |

**추천**: **A**. 이유 — 데이터 크기가 작고, 사용자 환경이 single-user dev 단계로 보이며 (production 부하 정보 없음), 사용자 선호 ("통째로 BEGIN..COMMIT 한 번에 실행") 와 일치.

⚠ **사전 확인**: production traffic 이 24/7 인지? 그렇다면 C 도 고려.

---

## Decision 4 — 마이그레이션 timing

Decision 3 의 종속 결정.

| 옵션 | 설명 |
|---|---|
| **A. 한 세션에 트랜잭션 통째로** | D5-3 마이그레이션 SQL = 단일 BEGIN..COMMIT, PRE/POST-CHECK + RAISE EXCEPTION |
| **B. 모듈별 분할 (parties → contacts → deals → engagements ...)** | 각 모듈이 단일 트랜잭션, 모듈 간은 분리. FK는 모든 마이그레이션 완료 후 한 번에 |

**추천**: **A** + Decision 3-A 와 동일 선상. 단, **D5-5 (코드 cutover)** 는 *모듈별로 분할* — 이건 코드 risk 분산 차원.

→ **DB 마이그레이션은 한 방, 코드 cutover 는 모듈별** 이 표준 패턴.

---

## Decision 5 — 롤백 전략

| 옵션 | 설명 | 적용 가능 |
|---|---|---|
| **A. 단일 트랜잭션 자동 ROLLBACK** | SQL 안에서 POST-CHECK 실패 시 RAISE EXCEPTION → ROLLBACK | D5-3 SQL 마이그레이션 |
| **B. DB 스냅샷 (Supabase backup)** | 마이그레이션 전 backup, 실패 시 PITR 복구 | catastrophic failure 대비 |
| **C. 이중쓰기 windows** | urm 활성 후에도 app 유지, 문제 시 코드만 app 으로 복귀 | D5-5 ~ D5-6 코드 cutover 기간 |
| **D. read-only fallback** | urm 활성 후 app 은 read-only, 문제 시 app 으로 임시 복귀 | D5-5 ~ D5-6 |

**추천 조합**: **A + B + D**
- A: D5-3 SQL 자체의 안전망 (사용자 표준 패턴)
- B: D5-3 시작 직전 manual snapshot (Supabase 대시보드)
- D: D5-5 코드 cutover 기간 (D5-7 app DROP 까지) 동안 app.* 는 read-only 로 유지

C 는 dual-write 부담이 커서 제외.

---

## 결정 매트릭스 — 추천안 요약

| Decision | 추천 | 의존 |
|---|---|---|
| 1. urm 스키마 design | **B** (stub 검토+조정) | audit 결과 |
| 2. app vs urm 분담 | **A** (urm 완전 대체) | — |
| 3. 데이터 이전 | **A** (한 번에 dump+load) | production traffic 여부 |
| 4. 마이그레이션 timing | **A** (DB 한 방) + **B** (코드 cutover 는 모듈별) | Decision 3 |
| 5. 롤백 전략 | **A + B + D** (트랜잭션 안전망 + 스냅샷 + read-only fallback) | Decision 3, 4 |

---

## audit 결과 받은 후 확정할 항목

1. **stage29c 진행 상태** — 어디까지 만들어졌고 어디서 멈췄는지
2. **stub 파일의 컬럼명** — `module` vs `party_type` 반영 여부
3. **현재 urm.* 실제 상태** — 비어있는지, 일부만 만들어졌는지, 데이터가 들어있는지
4. **app.* 와 urm.* parallel coverage** — 어떤 테이블이 누락됐는지
5. **production traffic 정보** — Decision 3 의 옵션 A vs C 결정

→ 이 5개 답이 모이면 **D5-1 (urm 스키마 final DDL 확정)** 직행.

---

## D5-0 워크플로우 (사용자 액션)

```
1. D5-0-audit.ps1   → 로컬에서 실행 → D5-0-audit-report.md 생성
2. D5-0-urm-diagnostic.sql → Supabase SQL Editor 에서 실행 → 결과 캡처
3. 두 결과 공유 → 이 framework 의 5 항목 답 확정 → D5-1 진입
```

각 단계에서 막히면 즉시 piping. sequential problem-solving.
