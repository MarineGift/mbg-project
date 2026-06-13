# URM 핸드오프 — 2026-06-13 (오후) → 다음 세션

다음 세션 첫 메시지로 맨 아래 "다음 세션 시작 메시지" 블록을 붙여넣으세요.
※ 이 문서 자체는 한글이지만, 새 세션의 메인 작업은 "소스코드 내 한글을 전부 영문(ASCII)으로 치환"입니다.

---

## 다음 세션 메인 작업: 소스코드 한글 → 영문(ASCII) 전면 치환  ★최우선

### 왜
PS 5.x가 UTF-8(no-BOM)을 CP949로 오독해 한글이 깨짐. 깨진 주석/로그/문자열이 빌드·콘솔·인코딩 사고를 반복 유발(.gitignore에 UTF-16/null 박혀 binary로 인식된 사례, 워커 로그 모지바케, processor.ts 폴백 답장 ko/ja 텍스트 등). 코드 내 한글을 ASCII 영문으로 정리하면 근본 차단.

### 범위
- **대상**: 소스코드 안의 주석 / 콘솔 로그 문자열 / 식별 불필요한 한글 리터럴 (.ts, .tsx 등).
- **주의 — 영문화하면 안 되는 것**: 사용자에게 실제 발송/표시되는 한국어 콘텐츠.
  - 예: src/lib/email/processor.ts buildFallbackReply의 bodyByLang.ko / .ja (실제 답장 본문 — 한국어/일본어 유지. 단 파일은 UTF-8 정상 저장이어야 하며, 깨진 모지바케면 정상 한글로 복원).
  - i18n 메시지, 이메일 서명(html_content) 등 사용자 노출 텍스트.
- 즉 "개발자용 한글(주석/로그)"은 영문화, "사용자용 한국어 콘텐츠"는 정상 UTF-8로 보존/복원.

### 시작 절차 (첫 명령)
1) 비ASCII/null 바이트가 든 소스파일 스캔 → 작업 목록 생성:
   PowerShell:
   Get-ChildItem -Recurse src -Include *.ts,*.tsx | ForEach-Object {
     $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
     $nonAscii = ($bytes | Where-Object { $_ -gt 127 }).Count
     $nulls    = ($bytes | Where-Object { $_ -eq 0 }).Count
     if ($nonAscii -gt 0 -or $nulls -gt 0) {
       "{0,5} nonAscii {1,4} null  {2}" -f $nonAscii, $nulls, $_.FullName.Replace("$PWD\","")
     }
   } | Sort-Object
2) null>0 파일은 손상(UTF-16 등) → 우선 복원. nonAscii만 있으면 한글 텍스트.
3) 파일별 한글 주석/로그 줄을 영문 치환안으로, UTF-8 보존 패치(.NET ReadAllText/WriteAllText no-BOM)로 적용. 사용자용 한국어는 건드리지 않음.
4) 배치마다 npx tsc --noEmit 0 확인 후 커밋. 파일 많으면 디렉터리/도메인 단위로 나눠 여러 커밋.

### 방식 메모
- 패치 앵커는 단일 줄 우선. 멀티라인은 빈 줄/들여쓰기 1바이트 차이로 실패하니 실제 바이트(ReadAllLines + len) 확인 후 작성.
- 롤백 명령을 안내 코드블록에 넣지 말 것(통째 붙여넣어 원복 사고 있었음).
- git add 후 항상 git status -sb로 staged 확인 후 commit.

---

## 큰 작업 백로그 (한글 영문화 다음, 또는 병행)
※ "이전에 하려다 못한 큰 작업들" — 세션 시작 시 사용자에게 정확한 우선순위 재확인. 아래는 메모리/핸드오프 기준 후보.

- **Google Drive 첨부 마무리**: GCP Console에서 Drive API enable → 재배포 → OAuth 재동의로 drive.file scope 부여 → /attachments-test에서 업로드/다운로드 테스트. (Phases 1,3 첨부)
- **투자자 enrichment**: Deep Tech / Advanced Materials / Life Science. 모델 parties → investor_profile → investor_sector_focus → sectors, insert 관례 확정. no-guessing(공개 LinkedIn URL만, 개인 이메일/모바일 금지).
- **크라우드펀딩 파이프라인(Kickstarter형)**: 테스트 백커/리워드 티어 시드.

---

## 남은 기능 항목 (핸드오프 누적)
1. **#2 AI 답장 실검증** — 코드 배포됨(d5c58be). force=true 재처리(npx tsx 일회성)로 기존 inbound 한 건 돌려 ai.drafts INSERT 확인 + 워커 로그 'ai.drafts INSERT failed'/'loadBrandVoice' FK 에러 소멸 확인. .env.local 키 필요(CALENDAR_TOKEN_ENCRYPTION_KEY, SUPABASE_SERVICE_ROLE_KEY, ANTHROPIC_API_KEY).
   검증 SQL: select id, agent_id, inbound_communication_id, classification_category, requires_human_approval, status, created_at from ai.drafts order by created_at desc limit 5;
2. **#4 워커 uncaughtException production화** — mailcarrier-worker.ts 상단 핸들러가 진단 모드(로그만, exit 안 함). 계정별 에러를 carrier 내부에서 격리하거나 복구/재연결로. 코드 변경 신중히.
3. **#6 BB1 수동 코멘트 → BB2 → BB3/BB4** — app.task_activity 코멘트 테이블(kind='comment') + 입력창, audit 이벤트와 머지. 이후 완료조건 체크리스트 / "마지막 활동 후 N일" / 목록 진행률·활동 배지. 설계서 docs/DESIGN_task_progress_tracking_2026-06-12.md.
4. **(후속) 배지 실시간 갱신** — sidebar.tsx 카운트가 마운트 시 1회만 fetch. 삭제/발송 직후 router.refresh()/재요청으로 자동 반영.
5. **package-lock.json** 계속 modified — 의도 변경이면 커밋, 아니면 git checkout -- package-lock.json.
6. **(선택) 1039631 커밋 메시지 교정** — 메시지는 perf(mailcarrier)인데 내용은 inbox occurred_at revert. amend+force push는 두 머신 동기화 위험 → 그냥 두기 권장.

---

## 직전 세션(2026-06-13 오후)에서 배포 완료 (참고)
모두 branch marinebiogroup push 완료(web/worker 자동 배포). C:\dev\mbg-project.
- c13fd4c Task 타임라인 status 핫픽스 (legacy pending/open/completed 매핑)
- e33f712 .gitignore 복구(UTF-16/null 제거, ASCII화) + env.download ignore
- d5c58be ai.drafts INSERT(inbound_communication_id + agent_id 역조회) + loadBrandVoice(party_type text 필터, FK 임베드 제거)
- 1039631 Inbox 정렬/표시 occurred_at(발신날짜)순 확정 [메시지 오기입]
- 3a0e09e 메일수신 AI를 fetch 루프에서 분리(bounded 백그라운드, drainAi) → 백필 가속
- 51fe53d 배지에서 soft-deleted 제외(inbound/outbound 카운트 x2파일)
- f6f856b 수동 발송 서명 복구(composeSchema useSignature, 기본 true)
확인: 워커 7계정 정상/노이즈 없음, marine-gift 정상, email_signatures 기본 서명 정상 존재.

---

## 다음 세션 시작 메시지 (이 블록만 복사)

지난 세션 이어서 URM 작업. mbg-project, branch marinebiogroup, C:\dev\mbg-project. 두 머신 작업이라 시작 시 git pull --no-rebase.

이번 세션 메인 작업: 소스코드 안의 한글 주석/로그/문자열을 전부 영문(ASCII)으로 치환하자. PS 5.x UTF-8 오독으로 한글이 깨져 빌드/인코딩 사고가 반복돼서 근본 정리한다. 단 사용자에게 실제 발송/표시되는 한국어 콘텐츠(예: processor.ts buildFallbackReply의 ko/ja 답장 본문, 이메일 서명, i18n)는 영문화하지 말고 정상 UTF-8로 보존/복원. 개발자용(주석/콘솔 로그)만 영문화.

진행: 먼저 src 전체에서 비ASCII/null 바이트가 든 .ts/.tsx 파일을 스캔해 작업 목록을 만들고(아래 명령), null이 든 파일은 손상이니 복원 우선, 나머지는 파일별 한글 줄을 영문 치환. 배치마다 npx tsc --noEmit 0 확인 후 커밋(도메인 단위로 나눠 여러 커밋). UTF-8 no-BOM 보존 패치 방식.

스캔 명령:
Get-ChildItem -Recurse src -Include *.ts,*.tsx | ForEach-Object { $b=[System.IO.File]::ReadAllBytes($_.FullName); $n=($b|?{$_-gt127}).Count; $z=($b|?{$_-eq0}).Count; if($n-gt0-or$z-gt0){"{0,5} nonAscii {1,4} null  {2}" -f $n,$z,$_.FullName.Replace("$PWD\","")} } | Sort-Object

그리고 "이전에 하려다 못한 큰 작업들"이 있었는데, 그게 (a) Google Drive 첨부 마무리 (b) 투자자 enrichment(Deep Tech/Advanced Materials/Life Science) (c) 크라우드펀딩 파이프라인 시드 — 이 셋 중 무엇인지(또는 다른 것인지) 내가 먼저 알려줄 테니, 한글 영문화 다음 순서로 잡자.

남은 기능 항목도 대기: #2 AI 답장 실검증(force 재처리), #4 워커 uncaughtException production화, #6 BB1→BB4, 배지 실시간 갱신, package-lock.json 정리.

먼저 git log --oneline -8로 f6f856b까지 올라갔는지 확인하고, 위 스캔 명령부터 돌려서 한글 든 파일 목록을 만들고 시작하자.
