# HANDOFF - 새 세션 시작용 (Investors 파이프라인 정리)

날짜: 2026-07-02 (2차 세션)
직전 세션: AI 답장 언어/서명 수정 + KdT 반송 진단/교정 + 데이터룸 재연결.
다음 세션 목표: **Investors 파이프라인 추가 정리** (아래 C 참고).

--------------------------------------------------------------------
## A. 이번 세션 완료분
--------------------------------------------------------------------
1. **AI 답장 언어 수정 (commit 4aef8ce, 배포됨)**
   - 원인: generateAIReply 시스템 프롬프트의 "Respond in Korean, or in the original
     message language if not Korean" 이 한국어 우선으로 해석됨.
   - 수정: (a) 기본 Auto = 원문 이메일 언어 감지 후 동일 언어로 작성,
     (b) AI Draft 탭에 Language 드롭다운(Auto / English / Korean) 추가.
   - 파일: src/lib/actions/email-compose.ts (AIReplyPayload.language),
     src/components/email/compose-email-dialog.tsx (aiLanguage state + select).
2. **AI 답장 sign-off 제거 (프롬프트 강화 + 코드 안전망)**
   - 프롬프트: 맺음말/이름/직함/회사 금지, 마지막 본문 문단에서 종료.
   - 안전망: signOffPattern 정규식으로 초안 끝 sign-off 블록(최대 4줄) 제거.
     한국어 "감사합니다" 류 정상 본문 마무리는 건드리지 않음.
   - 파일: src/lib/actions/email-compose.ts (generateAIReply 끝부분).
3. **KdT 발송 실패 진단 + 교정 (에디터 SQL, 마이그레이션 미보관)**
   - 반송: andrew@kdtvc.com -> 550 5.1.1 NoSuchUser (Gmail). IP 평판 문제 아님.
   - 사실관계: KdT 도메인 kdtvc.com 은 first@ 형식. 창업자 법적 이름 Andrew Cain
     McClary 이나 통칭 **Cain** (팀 페이지: Cain McClary, Managing Partner & Founder).
   - 교정: contacts 58eae018-de4b-4189-8790-18633748e06c ("General Inquiries") ->
     email cain@kdtvc.com, given/family/full = Cain / McClary / Cain McClary.
   - 화이트리스트: kdtvc.com domain 이 이미 active -> 추가 등록 불필요.
   - 블록리스트(유지): contact@kdtvc.com (6/30), andrew@kdtvc.com (7/2) 둘 다
     hard_bounce. **같은 도메인 3번째 추측 발송임** - cain@ 반송 시 이메일 추측 중단,
     LinkedIn 경로로 전환.
4. **데이터룸 재연결 (에디터 SQL DO 블록, 마이그레이션 미보관)**
   - 원인: 섹터 3분할 때 campaign_folders/campaign_materials 가 archived
     Pangaea 캠페인에만 연결.
   - 수정: jsonb_populate_record 전컬럼 복사(멱등, name/item_key 가드)로
     Pangaea -> AM/LS/DT 3개 캠페인. 검증: 각 7 folders / 19 materials.
   - 3캠페인이 같은 Drive 폴더 공유 중. 섹터별 자료 분리 시 drive_folder_id 만 교체.
5. 정상 발송 확인: David DePasquale(SMI) tissue 답장 22:40 sent,
   STATION Austin 답장 22:37 sent (AI 언어 수정 후 영어 생성 확인됨).

--------------------------------------------------------------------
## B. 미해결 / 대기
--------------------------------------------------------------------
- [발송] **KdT 재발송**: cain@kdtvc.com 으로 재발송. 호칭 "Cain" 으로 수정.
  발송 후 30분 내 반송 확인 (아래 bounce 쿼리). 도달 시 자동화(backlog->cold_outreach)
  상태가 사실과 일치하게 됨.
- [파일보관] 20260702010000_campaign_restructure_sector_split.sql repo 미반영 (이전 세션분).
- [파일보관] 에디터 직접 실행 SQL 아카이브 대상 누적: Omya/SMI FCC 딜, Paper Mill
  restage, Lost 삭제 (이전) + KdT 연락처 교정, 데이터룸 재연결 DO 블록 (이번).
  -> 새 세션에서 하나의 정리 마이그레이션으로 아카이브 권장.
- [버그] fetchCommunicationDetailV2: anon 42501 (app.parties). GRANT TO anon 금지,
  인증(JWT)/admin 클라이언트로 수정 필요.
- [정리] DB 타입 재생성 -> slack route/notify 의 `as any` 제거.
- [평판] 발신 IP 49.254.118.167 (mail.marinebio.kr) Trend Micro ERS 차단 -> delisting
  신청 (KdT 건은 무관했으나 여전히 미해결).
- [답장대기] Sharad Mathur(SMI): tissue 데이터 답장은 David DePasquale 에게 발송 완료
  상태. 후속 회신 모니터링.
- [7/8] Pangaea 콜 9:30-10:00 PDT. 도서관 509호 11AM-1PM CDT. 콜 전(7/6-7)
  one-pager 첨부 확인 메일 초안 있음.

bounce 확인 쿼리:
```sql
select occurred_at, from_address, subject, left(coalesce(body_plain,''),400)
from app.communications
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and direction = 'inbound' and occurred_at > now() - interval '2 hours'
  and (from_address ilike '%postmaster%' or subject ilike '%전송 실패%'
       or subject ilike '%undeliver%' or subject ilike '%failure%')
order by occurred_at desc;
```

--------------------------------------------------------------------
## C. 새 세션 주제: Investors 파이프라인 추가 정리 (사용자 지정)
--------------------------------------------------------------------
논의/작업 후보 (사용자가 방향 정함):
- 스테이지 미세조정 (warm_intro 위치/자동화, followup_meeting 통합 여부,
  term_sheet/contract 뒤 won 처리 - 현재 investors 에 won/lost 없음)
- Backlog 184곳(AM 88 / DT 53 / LS 43) 아웃리치 플랜: 섹터별 시퀀스 매핑, 발송 스케줄
- reply_received 6곳 후속 처리 (거절 vs 대기 구분 -> 스테이지 or 태그)
- 캠페인별 체크리스트/플레이북(stage_checklist_templates) 정비
- Reports: 섹터/캠페인별 퍼널 전환율

--------------------------------------------------------------------
## D. 작업 규칙 (모든 mbg-project 작업 공통 - 항상 준수)
--------------------------------------------------------------------
- repo: PUBLIC MarineGift/mbg-project, branch marinebiogroup. 로컬 C:\dev\mbg-project.
  파일은 raw.githubusercontent.com 직접 읽기 ((app) -> %28app%29 인코딩).
- Next.js 14 (src/, App Router). Supabase: @/lib/supabase/server(JWT) /
  admin(service_role, schema 'app'). env=@/lib/env(zod). ignoreBuildErrors=true(임시).
- SQL 은 항상 Supabase SQL Editor 수동 실행 (Railway 는 마이그레이션 자동실행 안함).
  push origin marinebiogroup = web(mbg-project)+worker(lucky-patience) 자동배포 = 웹 게시.
- SaaS 표준: organization_id + created_by(auth.uid()) + org RLS (엔티티 테이블).
  join/history/lookup/log/1:1detail 제외. GRANT TO anon 절대 금지.
  SQL Editor 실행 시 auth.uid() 가 null 이므로 created_by 는 명시 지정
  ('551fc4a0-b365-47eb-bf2f-0c3f594001c0').
- 핵심 ID: org b25de8f2-1020-482f-9012-183f63883169, supabase ogenmrgxwhpbfepeldqx.
- 스키마 함정: parties 에 party_type 없음(party_type_id smallint), country_code,
  investor_profile 단수형, campaigns.campaign_type/status text,
  deals.campaign_id NOT NULL, meetings.engagement_id -> deals.id.
  contacts: full_name 은 저장 컬럼(생성 컬럼 아님), email/given_name/family_name.
  campaign_folders(campaign_id,name,drive_folder_id,sort_order),
  campaign_materials(campaign_id,section,item_key,label,detail,status,sort_order).
- 발송 파이프라인 에러 구분: blocked(화이트리스트/블록리스트/PII, 행 미생성) vs
  failed(SMTP, status='failed'+error_message). 반송은 inbound 로 수신되고
  hard bounce 는 email_blocklist 에 자동 등록(reason='hard_bounce').
- 파일 전달 표준: 다운로드는 %USERPROFILE%\Downloads. mover 는 복붙 PowerShell 블록
  (글롭 -> 최신1개 -> Unblock-File -> CreateDirectory -> File.Copy -> Remove-Item, ASCII).
- in-place 패치 표준: ReadAllText -> CRLF->LF -> guard 멱등체크 -> Assert-Once 앵커
  유일성 검증 -> .Replace -> WriteAllText. 여러 패치는 반드시 올인원 블록
  (전부 성공시에만 저장+commit+push).
- Korean .md 는 UTF-8 BOM. 콘솔/코드/SQL 은 영어 ASCII.
- finish block: git status -sb -> add -> commit -> pull --rebase -> push.
  존재 불확실한 파일은 Test-Path 가드로 add.

--------------------------------------------------------------------
## E. 이 handoff 파일 mover + finish
--------------------------------------------------------------------
handoff mover:
```powershell
$ErrorActionPreference = 'Stop'
$src = Get-ChildItem (Join-Path $env:USERPROFILE 'Downloads') -Filter 'HANDOFF-NEXT-SESSION-investors*.md' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $src) { Write-Host 'ERROR: file not found in Downloads'; return }
Unblock-File -LiteralPath $src.FullName
$dst = 'C:\dev\mbg-project\HANDOFF-NEXT-SESSION-investors.md'
[System.IO.File]::Copy($src.FullName, $dst, $true)
Remove-Item -LiteralPath $src.FullName
Write-Host ('MOVED: ' + $dst)
```

finish block:
```powershell
cd C:\dev\mbg-project
git status -sb
git add HANDOFF-NEXT-SESSION-investors.md
if (Test-Path 'HANDOFF-NEXT-SESSION-pipeline-v2.md') { git rm -q HANDOFF-NEXT-SESSION-pipeline-v2.md }
if (Test-Path 'supabase\migrations\20260702010000_campaign_restructure_sector_split.sql') { git add supabase/migrations/20260702010000_campaign_restructure_sector_split.sql }
git commit -m "docs: handoff - investors pipeline session; ai-reply language/sign-off fixes, kdt correction, dataroom reconnect"
git pull --rebase origin marinebiogroup
git push origin marinebiogroup
```
