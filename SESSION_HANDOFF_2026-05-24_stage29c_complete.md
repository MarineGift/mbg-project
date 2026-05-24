# SESSION_HANDOFF — Stage 29-c COMPLETE

**Date**: 2026-05-24
**Branch**: feature/stage23-urm-cleanup
**Latest commits**:
  9b1ba70  stage29c: phase1 - org_id->organization_id, body_text->body_plain (communications)
  3506d2a  stage29c: regen database.ts with urm schema

---

## §1. Stage 29-c 결과

### Phase 1 적용 완료 (commit 9b1ba70)
- org_id -> organization_id: 21 사이트 / 6 파일
- body_text -> body_plain: 2 사이트 (communications 한정)
- database.ts regen with urm schema (3506d2a)

### tsc baseline (검증)
- Before Phase 1: 181 errors
- After Phase 1: 181 errors
- Phase 1 delta: 0 ✅ (regression 없음)

### Phase 2 연기 (Stage 29-d 와 일괄)
| ID | 작업 | 연기 사유 |
|---|---|---|
| A1 | SbClient generic 'app' -> 'urm' | 30+ default .from() 가 app 테이블 직접 호출. 변경시 break |
| A2 | 163곳 .schema('app') 검토 | A1 안 했으므로 그대로 작동 |
| A4 | party.ts party_type='company' (2곳) | app.parties.party_type enum 살아있음 |
| A8 | parent_party_id / party_level 제거 (19곳) | app.parties 에 컬럼 잔존 (information_schema 검증) |

---

## §2. 새 발견 사실 (Stage 29-c carry-forward)

1. **handoff §5 delta DROP 검증**: 9 deprecated profile + portfolio_companies 실제 부재 확인. 1잔존: app.investor_partner_profile (108 row, epsilon 잔재)

2. **app.parties carry 컬럼**: parent_party_id / party_level / tier 모두 app.parties 에 존재. Stage 29-d 까지 carry

3. **app.parties drift**: handoff §7 expected 1738 active vs 실제 1441 active (delta -297). cutover 영향 없음

4. **urm.parties / investor_profile drift**: handoff §7 +6 / +5 / -4. URM 원칙 위반 아님 (모든 orphan 검증 0). 자연 시점 차이

5. **p_org_id (RPC 매개변수) 8 사이트 보존**: DB RPC 시그니처. 컬럼 rename 대상 아님

6. **body_text (sequence_steps) 12 사이트 보존**: communications.body_text 와 다른 별도 컬럼

7. **app.parties 의 23 row 가 urm.parties 에 없음**: Stage 29-b 후 신규 추가 또는 migration 누락. Stage 29-d 시 일괄 처리

8. **urm.parties 의 3 row 가 app.parties 에 없음**: handoff §5 epsilon 의 의도된 3 HQ 보존 (Carmeuse / Schaefer Kalk / Sibelco) - 확인 완료

---

## §3. Stage 29-d 진입 조건

- [x] Phase 1 commit 완료
- [x] caller audit 완료 (stage29c_audit_report.md)
- [x] database.ts regen 완료 (urm schema 포함, 850132 bytes)
- [x] tsc regression 없음 확인 (delta 0)
- [ ] Production traffic 1-2주 cooldown
- [ ] (선택) tsc 181 errors 정리 - regen exposure 로 인한 기존 잠재 버그, 정상 동작에 영향 없을 가능성 큼

---

## §4. Stage 29-d 시 정리 대상

### A. app.* 테이블 DROP (urm 으로 완전 이전)
- app.parties (cascade: investor_partner_profile, person_firm_history, investor_portfolio_companies, party_supply_links, plant_supply_links, investor_profile, paper_mill_profile, filler_supplier_profile)
- app.pipelines / pipeline_stages / tasks (이미 TRUNCATE)
- app.engagements / engagement_stage_history (0 row)

### B. caller code cutover (DROP 동시)
- A1: 3 파일 (server.ts, client.ts, admin.ts) - <Database, 'app'> -> 'urm'
- A2: 163곳 .schema('app') 정리
- A4: party.ts 2곳 (PARTY_TYPE constant + JOIN 패턴)
- A8: 4 파일 (party.ts / page.tsx / country-peers-panel.tsx / tier-cascade.ts) - parent_party_id, party_level 제거
- 30+ default .from() 사이트: .schema('app') 명시 추가 OR urm 으로 전환

### C. tsc 181 errors 정리
- Phase 1 와 무관한 regen exposure
- 'country' -> 'country_code' 등 잔존 V1 references
- never type 에러 (database.ts strict typing 으로 노출)

---

## §5. 산출물 인벤토리

| 파일 | 용도 |
|---|---|
| stage29c/STAGE_29C_PLAYBOOK.md | 마스터 실행 문서 |
| stage29c/01_caller_audit/audit_v3.ps1 | grep audit (working version) |
| stage29c/05_urm_verification_sql/* | URM 검증 SQL (실행 완료) |
| stage29c_audit_report.md | 770 매치 detail (Phase 1 이전) |
| apply_phase1.cjs (gitignored) | Phase 1 codemod script |
| inspect.js (gitignored) | 컨텍스트 분석 script |
| src/types/database.v1-backup.ts (gitignored) | regen 전 백업 |

---

## §6. 다음 세션 진입 메시지

"Stage 29-c COMPLETE. Phase 1 (column rename) 적용. tsc delta 0. Phase 2 (SbClient cutover + A4/A8) 는 Stage 29-d (app.* DROP) 와 일괄 처리. 1-2주 cooldown 진행 중. handoff SESSION_HANDOFF_2026-05-24_stage29c_complete.md 참조."
