# HANDOFF - 새 세션 시작용 (Slack 연동 완료 후속)

날짜: 2026-07-01 (밤)
작성 이유: Slack <-> URM 양방향 연동 세션 종료 -> 새 세션으로 컨텍스트 이관.

--------------------------------------------------------------------
## A. 완료된 것 (이번 세션)
--------------------------------------------------------------------
**Slack <-> URM 양방향 연동 완료 + 실전 검증 끝.**
- 인바운드: /urm help·note·contact 모두 동작. app.slack_integrations 행:
  org b25de8f2-..., slack_team_id=T0BEQGKC7N0 (self-heal로 자동 backfill),
  team_name=marinebiogrouphq, webhook/enabled 정상. 노트/컨택 DB 저장 확인.
- 아웃바운드: 새 인바운드 메일 -> #all-marinebiogroup 에
  "New inbound email / From / Subject / https://urm.../inbox/<id>" 알림. 실메일 2건 검증.
- 커밋: 3180f63(Slack 기반 5파일) -> bb52052(빈 커밋) -> **189d6da**
  (feat(slack): notify channel on new inbound email; fix missing partyTypes i18n keys)
  = types/email.ts(fromName·subject 추가), mailcarrier.ts(이벤트에 채움),
  mailcarrier-worker.ts(notifySlack 호출, event.organizationId 사용),
  i18n en/ko/ja partyTypes 5키 추가(buyer/government_grant/consultant/
  crowdfunding_platform/self; ko·ja는 \uXXXX 이스케이프), HANDOFF-slack-outbound-i18n.md.
- **배포 인프라 장애 해결(중요 기록)**: Railway mbg-project(web) Variables에
  빈 이름 변수가 있어 모든 빌드가 `secret ID missing for ""` 로 5연속 실패,
  옛 빌드(eaec5a1f)가 Active로 고착돼 있었음. 변수 정리 후 push->auto-deploy 정상화.
  web 서비스 = www + urm 두 도메인 모두 서비스(port 8080). worker = lucky-patience.
- lucky-patience 에 NEXT_PUBLIC_APP_URL=https://urm.marinebiogroup.com 설정됨
  (알림 링크가 이 값 사용).

--------------------------------------------------------------------
## B. 다음 작업 후보 (우선순위 제안 순)
--------------------------------------------------------------------
1. **[버그] fetchCommunicationDetailV2 42501**: inbox 상세의 어떤 경로가 anon 권한으로
   app.parties 조회 -> "permission denied for table parties" 로그 반복.
   *GRANT TO anon 금지* (org RLS/SaaS 표준 위반). 서버 코드가 인증(JWT) 또는
   admin 클라이언트를 쓰도록 수정. 페이지 렌더 자체는 됨(비치명).
2. **Capital Factory 액션(비코딩)**: (1) capitalfactory.com/investors 폼에 덱 제출
   - Drive PDF 링크(Ver3_3_Share), 제목 "Advanced Materials - 2 orders + top filler
   maker - US - Seed" (pitch/deck/intro/opportunity 단어 금지). (2) Caroline Vannuis
   에게 인트로 요청 메일 -> 그다음 Nick Spiller(All Access Fund). (3) 7/14 Cup of
   Capital(Antler 공동, 화 1:30PM) 등록. CF 캠페인 id d0000000-...-00fd, 체크리스트 8.
3. **DB 타입 재생성**: slack_integrations/slack_notes 가 생성 타입에 없어
   slack route/notify 가 admin 클라이언트를 `as any` 로 씀 -> 재생성 후 제거.
4. **Deal/Meeting 생성 알림(선택)**: 원하면 해당 server action 에 notifySlack 한 줄씩.
5. **WhatsApp 연동(백로그, 지금 우선순위 아님)**: Meta WhatsApp Business Platform
   (Cloud API). 구조는 Slack 과 동일 패턴(웹훅 인바운드 -> communications 저장 +
   Slack 알림 / API 아웃바운드). 제약: Meta 비즈니스 인증 + 전용 전화번호 +
   24h 룰(이후엔 승인 템플릿만, 발신 과금). 가치: 해외 제지사/공급망 컨택
   (동남아·중동·남미·유럽)엔 큼, IR/투자자엔 낮음(이메일 표준), 한국은 카카오라 해당없음.
   해외 밀 아웃리치 본격화 시점에 최소 버전(인바운드 저장+알림)부터.

--------------------------------------------------------------------
## C. IR / Pangaea (배경, 변동 없음)
--------------------------------------------------------------------
- **7/8 Andrew Haughian (Partner, Pangaea Ventures) 인트로 콜.** Deck Ver3.3 발송 완료,
  one-pager follow-up 예정(초안 있음). Andrew 회신 오면 이제 Slack 알림으로 즉시 인지됨.
- 시드 $1M / 5% / $20M pre. FCC 제지 필러 로열티 라이선스. Traction 9,000t 확정 +
  ~10,000t 진행. 익명화: KOREAN MILL A/B, SMI="world's top filler maker".
- CEO 발신 yunyoung.heo@marinebiogroup.com. US HQ 1108 Nueces St Unit 301 Austin TX.

--------------------------------------------------------------------
## D. 반드시 지켜야 하는 작업 규칙 (모든 mbg-project 작업 공통)
--------------------------------------------------------------------
- repo: PUBLIC MarineGift/mbg-project, branch marinebiogroup. 로컬 C:\dev\mbg-project
  (Samsung SS_LAPTOP-HEO / Lenovo). 파일은 raw.githubusercontent.com 으로 직접 읽기
  (괄호 경로 URL 인코딩: (app) -> %28app%29).
- Next.js 14 (src/, App Router). Supabase clients: @/lib/supabase/server (JWT),
  @/lib/supabase/admin (service_role, schema 'app'). env 는 @/lib/env (zod).
  next.config: typescript.ignoreBuildErrors=true (임시).
- SQL 은 항상 Supabase SQL Editor 에서 실행 (PowerShell 아님). Railway 는 마이그레이션
  자동 실행 안 함. push origin marinebiogroup = web+worker 자동배포 = 웹 게시.
- SaaS/멀티테넌트 표준: 엔티티 테이블 organization_id default app.current_organization_id()
  + created_by uuid default auth.uid() + org 격리 RLS. join/history/lookup/log/1:1detail
  제외. GRANT TO anon 절대 금지.
- 핵심 ID: org b25de8f2-1020-482f-9012-183f63883169, owner/created_by
  551fc4a0-b365-47eb-bf2f-0c3f594001c0, supabase project ogenmrgxwhpbfepeldqx.
- **파일 전달 표준**: 다운로드는 %USERPROFILE%\Downloads. mover 는 항상 **복붙
  PowerShell 블록**(다운로드 .ps1 아님): Downloads 를 base이름*.ext 글롭 -> 최신 1개
  -> Unblock-File -> [System.IO.Directory]::CreateDirectory -> [System.IO.File]::Copy
  + Remove-Item -> repo 정식 경로/이름. 콘솔 ASCII only.
- **기존 파일 수정 표준**: in-place PowerShell 패치 복붙 블록 - ReadAllText ->
  CRLF->LF -> guard 로 멱등 체크 -> .Replace(anchor 유일성 사전 검증) -> WriteAllText.
  한글/일본어 JSON 값은 \uXXXX 이스케이프로 ASCII 유지. anchor 는 대상 블록 전용으로
  (동일 패턴이 파일 내 다른 곳에 있을 수 있음 - 이번 세션에서 guard 오탐 사례 있었음).
- Korean .md 리포트는 UTF-8 BOM. 콘솔/식별자/코드/SQL 은 영어 ASCII.
- 마무리 finish block: git status -sb -> git add <경로들> -> commit -> pull --rebase
  -> push origin marinebiogroup. mover+finish 를 handoff .md 에 매번 박는다.

--------------------------------------------------------------------
## E. 이 handoff 파일 mover (Downloads -> repo 루트)
--------------------------------------------------------------------
```powershell
$ErrorActionPreference = 'Stop'
$src = Get-ChildItem (Join-Path $env:USERPROFILE 'Downloads') -Filter 'HANDOFF-NEXT-SESSION-post-slack*.md' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $src) { Write-Host 'ERROR: file not found in Downloads'; return }
Unblock-File -LiteralPath $src.FullName
$dst = 'C:\dev\mbg-project\HANDOFF-NEXT-SESSION-post-slack.md'
[System.IO.File]::Copy($src.FullName, $dst, $true)
Remove-Item -LiteralPath $src.FullName
Write-Host ('MOVED: ' + $dst)
```

repo 에 기록해두려면(선택):
```powershell
cd C:\dev\mbg-project
git status -sb
git add HANDOFF-NEXT-SESSION-post-slack.md
git commit -m "docs: handoff - post slack integration, next-session backlog"
git pull --rebase origin marinebiogroup
git push origin marinebiogroup
```
