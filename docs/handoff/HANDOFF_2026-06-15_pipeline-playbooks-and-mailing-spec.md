＝＝＝ HANDOFF — 2026-06-15 ＝＝＝
# Pipeline Playbooks 완료 + Mailing System 스펙

## 1. 이번 세션 요약 (모두 실 DB 반영 완료)

5개 파이프라인 전부에 스테이지별 **Checklist + Task 플레이북**을 구축/정상화했고, 백필·정리·회귀버그 수정까지 마쳤다.

### 1.1 FCC 영업 플레이북 (commit cb6b51d, push 완료)
- **paper_mill** (수요/PULL, 99딜): 8스테이지(lead→qualified→sample_sent→trial_eval→quotation→negotiation→won→lost) 구조 유지. 체크리스트 20 / 태스크 14 시드, 99딜 백필, 옛 항목 정리(검증: lead 294/98, qualified 2/1).
  - `20260615_paper_mill_fcc_playbook_seed.sql`, `20260615_paper_mill_playbook_cleanup.sql`
- **filler_suppliers** (라이선스/PUSH, 85딜): Pilot 버그 수정(is_lost/is_terminal=true→false), Lost 스테이지 추가(sort 9, paper_mill lost 행을 rowtype 복제). 체크리스트 23 / 태스크 16, 85딜 백필(prospect 243/81), 정리 포함.
  - `20260615_filler_suppliers_fcc_playbook_seed.sql`

### 1.2 회귀버그 수정 (이번 세션 — 커밋 예정)
- 증상: 딜 상세에서 Checklist가 안 보이고 Task만 보임.
- 원인: `20260614_playbook_tasks_require_checklist.sql`가 `apply_stage_playbook` 재작성 시 deal_checklists INSERT에서 **stage_id를 누락**(태스크엔 있음). `checklist-tab.tsx`는 stage_id로 그룹핑 → 백필 체크리스트가 stage_id=NULL → "Other"(기본 접힘)로 빠져 안 보였음.
- 수정: `20260615_playbook_checklist_stage_id_fix.sql` — 함수에 stage_id 복원 + 기존 pb_cl 항목 stage_id 백필(템플릿 기준). 검증 still_null=0.
- ⚠️ **주의: 20260614를 다시 적용하면 버그 재발. 이 수정이 항상 최신이어야 한다.**

### 1.3 나머지 파이프라인 플레이북 (이번 세션 — 커밋 예정)
- **investors** (1딜): 템플릿(31 체크리스트 / 21 태스크, 20260612 시드)은 있었으나 백필 안 됨 → 백필 실행. `20260615_investors_playbook_backfill.sql`
- **crowdfunding** (1딜): 리워드 캠페인 운영 플레이북 신규. 체크리스트 27 / 태스크 21, 7스테이지, 백필. `20260615_crowdfunding_playbook_seed.sql`
- **government_grant** (0딜): 그랜트 신청 플레이북 신규. 체크리스트 21 / 태스크 15, 7스테이지. `20260615_government_grant_playbook_seed.sql`

## 2. 현재 파이프라인 플레이북 커버리지
| Pipeline | 스테이지 | 체크리스트 | 태스크 | 백필 |
|---|---|---|---|---|
| paper_mill | 8 | 20 | 14 | 99딜 |
| filler_suppliers | 9 (Lost 추가) | 23 | 16 | 85딜 |
| investors | 7 | 31 | 21 | 예 |
| crowdfunding | 7 | 27 | 21 | 예 |
| government_grant | 7 | 21 | 15 | (0딜) |

## 3. 핵심 기술 사실 (Playbook 시스템)
- 템플릿: `app.stage_checklist_templates`(org_id, stage_id, title, sort_order, is_active), `app.stage_task_templates`(+ checklist_template_id, description, default_priority=low/medium/high, due_in_days).
- 함수 `app.apply_stage_playbook(p_deal_id, p_stage_id)`: 딜 스테이지 진입 시 템플릿→deal_checklists/tasks 생성. 멱등(extra_data.pb_cl / pb_task 태깅). 태스크는 checklist_template_id NOT NULL인 것만 생성. **수정 후 체크리스트·태스크 모두 stage_id 기록.**
- UI `checklist-tab.tsx`: deal_checklists를 stage_id로 그룹핑(현재 스테이지 펼침, stage_id=NULL은 "Other" 접힘). → 백필 항목엔 stage_id 필수.
- 검증된 시드 패턴(한 트랜잭션): 기존 템플릿 delete(태스크 먼저, FK) → VALUES-join으로 (pipeline code + stage code)로 stage_id 조회 후 INSERT → apply_stage_playbook 백필 루프 → 고아(pb_cl/pb_task 중 템플릿 없는 행) soft-delete. org_id 명시 `b25de8f2-1020-482f-9012-183f63883169` (SQL editor에선 current_organization_id()=NULL).
- 실행은 Supabase SQL Editor. Railway 배포는 supabase 마이그레이션을 자동 실행하지 않음 → `supabase/migrations/`는 기록/버전관리용.

## 4. 다음 세션 목표: Mailing System (대량 메일링)

### 4.1 목표
Template을 이용해 Pipeline의 Deal에 등록된 Party(app.deal_parties) 또는 Parties 디렉토리의 Party들에게 **대량 메일 발송**. **이미 받은 Party는 제외**하고 미수신 Party에게만 발송.

### 4.2 요구사항 (사용자)
1. 파이프라인 Deal party들에게 **스테이지에 맞는** 템플릿 메일 발송.
   - 예: Investors 파이프라인 cold_outreach(Prospecting) 단계 Deal party들에게 Cold mail 템플릿 발송.
2. **중복 제외**: 해당 템플릿을 이미 받은 party는 빼고 미수신자에게만.
3. Parties 디렉토리 기준 대량 발송도 지원(파이프라인 외).

### 4.3 관련 기존 스키마/컴포넌트 (조사 완료 — 앵커)
- `app.email_templates`: id, name, subject, body_plain, body_html, category, **party_type**, is_active, organization_id. 액션 `src/lib/actions/email-templates.ts`, 설정 UI `src/app/(app)/settings/email-templates/page.tsx`, 컴포넌트 `src/components/settings/email-templates/`.
  - ⚠️ 템플릿에 stage 매핑 컬럼 없음(category/party_type만). "스테이지에 맞는 템플릿"을 위해 stage 매핑 추가 검토 필요(설계 결정).
- `app.deal_parties`(deal_id, party_id, role): 파이프라인/스테이지별 수신 대상 추출. deals.current_stage_id + stages.pipeline_id로 필터.
- `app.communications`: party_id, contact_id, direction(direction_type), status, sent_at, subject, to_addresses[], from_address, **template_id**, template_variables, ai_generated, deal_id, engagement_id.
  - → **중복 제외 = outbound communications에서 party_id(또는 to_address) + template_id 기준으로 이미 보낸 party를 SELECT해 후보에서 제외.**
- 발송부 `src/lib/email/send-outbound.ts`: `{ partyId, templateId?, to, dealId?, ... }` → communications(status='sending') insert → 트래킹 → 트리거 trg_comm_log_engagement가 engagement 자동 로그. → 대량 발송기는 이 단일 함수를 후보 루프에서 재사용.
- 머지 토큰: {{party.name}}, {{party.country}}, {{party.website}}, {{party_name}}, {{company_name}}, {{fund_name}}, {{contact.given_name}} 등 (renderMerge(partyId, ...)).

### 4.4 제안 접근 (다음 세션에서 확정/구현)
1. 대상 선택: (a) 파이프라인+스테이지 → 해당 deal_parties, 또는 (b) Parties 필터.
2. 템플릿 선택 + (필요시) 스테이지↔템플릿 매핑.
3. 후보에서 이미-발송(communications.template_id + party_id) 제외, 미리보기(보낼 N / 제외 M).
4. party당 수신 contact 이메일 해석 규칙.
5. send-outbound 배치 호출(rate limit / MailCarrier 워커 고려).
6. 발송 결과 로그/요약.

### 4.5 열린 질문
- 스테이지↔템플릿 매핑 위치(email_templates에 stage_id 컬럼? 별도 매핑표?).
- party당 수신 contact 선정(primary? 전체? party 자체 이메일?).
- "이미 받음" 기준(같은 template_id 영구 제외 vs 캠페인/기간 단위).
- from 발신함(personal/role/shared) 라우팅 선택 방식.

## 5. 컨벤션 (항상)
- 레포 파일: ASCII PowerShell 패처(앵커 1개 가드, 불일치 시 미기록 중단, 멱등, LF+UTF-8 no-BOM, ASCII 콘솔) + 무버(Downloads→repo, Unblock-File, Move-Item -Force) + finish 블록(`git push origin marinebiogroup` = 웹 배포). 핸드오프 .md만 UTF-8 BOM(한글 허용).
- 커밋 전 `npx tsc --noEmit` 0 에러. `git status -sb`로 스테이징 확인.
- DB는 Supabase SQL Editor 실행; migrations/는 기록.
- 레포 PUBLIC: codeload 타르볼 또는 raw.githubusercontent.com로 직접 읽기. route-group 괄호 URL 인코딩.
- 머신: Samsung(SS_LAPTOP-HEO)/Lenovo, 둘 다 C:\dev\mbg-project, Downloads=$env:USERPROFILE\Downloads.

＝＝＝ END HANDOFF ＝＝＝
