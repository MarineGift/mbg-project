# handoff_20260916b_incident_recovery — Supabase Disk IO 장애 대응 및 메일 수신 복구 (2026-09-16)

> 저장소가 Public이므로 이 문서에는 비밀번호, 키, 외부인 연락처를 적지 않는다.

## 1. 요약

- Supabase에서 Disk IO 예산 소진 경고를 받았고, 이후 DB가 두 차례 응답 불능 상태가 됐다(오후 재시작으로 복구).
- 원인은 서로 겹친 여러 문제였다: 무거운 사이드바 집계, 행마다 실행되는 RLS 권한 함수, 메일 본문을 통째로 복사하는 변경 이력, DB 장애를 증폭시키는 메일 워커.
- 모두 수정했고, 변경 이력 테이블은 1,008MB에서 135MB로 줄였다.
- DB 장애 중 누락됐던 BASF VC 회신 메일(개인 메일함 uid 1524)은 복구해 URM Investors 폴더에 저장됐다.
- 최종 커밋: `c8f654c` (branch `marinebiogroup`)

## 2. 원인과 조치

| # | 원인 | 조치 | 커밋 |
|---|---|---|---|
| 1 | `app.mail_folder_counts()`가 폴더마다 communications 전체 스캔, 사이드바가 30초마다 호출 | 함수 재작성(1회 스캔), 부분 커버링 인덱스, 폴링 120초 + 숨김 탭 제외 | `3b99383` |
| 2 | RBAC 정책이 `app.perm_scope()`(SECURITY DEFINER)를 행마다 실행 → role_permissions 647만 회 스캔 | app/ai 정책 305개를 `(select fn())` InitPlan 형태로 재작성 | `c599b28` |
| 3 | `audit.log_change()`가 메일 본문 포함 행 전체 복사 → change_log 985MB | change_log BEFORE INSERT 트리거: 2KB 넘는 개별 값은 `[omitted N bytes]` | `c599b28` |
| 4 | 워커: DB 오류 시 last_uid를 0으로 간주(메일함 전체 재처리), DB 조회 실패 시 env 비밀번호로 폴백 → IMAP 인증 실패 → 재시작 루프 | 재시도 후 회차 건너뛰기, 폴백 제거(백오프 재시도), 전체 실패 시 5분 대기 후 종료 | `c834765` |
| 5 | NUL 문자 메일(22P05)이 naver 메일함을 장기간 막음, 일부 서버의 IDLE이 즉시 종료되어 1초마다 fetch | 저장 전 NUL 제거, 데이터 오류 3회 시 건너뛰기, IDLE 회차 최소 30초 간격 | `a01c534`, `065a32a` |
| 6 | 받은편지함 목록이 메일 1,000건의 본문 전체를 읽어 57014(시간 초과) | `app.body_preview` computed field(앞 500자)로 교체 | `8595e57` |
| 7 | `src/middleware.ts`가 루트 `middleware.ts`를 가려서 세션 갱신이 안 됨 → 서버 조회가 anon(42501) | `src/middleware.ts`에서 CRM 호스트는 `updateSession()` 호출 | `3036e85` |
| 8 | 13.6MB 메일(uid 1496) 다운로드가 끝나지 않아 개인 메일함이 수 시간 정지 | 크기 사전 확인, 10MB 초과 메일은 내려받지 않고 건너뜀(`MAILCARRIER_MAX_MESSAGE_BYTES`) | `b32be5e` |

## 3. DB에 적용된 변경 (Supabase)

| 파일 | 내용 | 상태 |
|---|---|---|
| `sql/migration_20260916a_mail_folder_counts_fn.sql` | 폴더 집계 함수 재작성 | 적용 |
| `sql/migration_20260916b_mail_folder_indexes.sql` | 인덱스 2개 | 적용 |
| `sql/migration_20260916c_rls_initplan.sql` | RLS 정책 InitPlan화 (ai 24, app 281) | 적용 |
| `sql/migration_20260916d_audit_slim.sql` | change_log 슬림 트리거 | 적용 |
| `sql/migration_20260916e_inbox_body_preview.sql` | `app.body_preview()` | 적용 |
| `sql/repair_20260916f_authenticated_timeout.sql` | authenticated `statement_timeout` 30s | **임시 적용 — 되돌려야 함** |
| `sql/repair_20260917_change_log_slim.sql` (v4) + `...b_change_log_vacuum.sql` | 기존 이력 슬림화 + VACUUM FULL | 완료 (1,008MB → 135MB) |
| `sql/repair_20260917c_analyze_stale.sql` | 투자자 테이블 통계 갱신 | 완료 |
| `sql/repair_20260917d_drop_slim_progress.sql` | 진행 기록 테이블 삭제 | 완료 |
| `sql/repair_20260917e_expire_backlog_drafts.sql` | 오래된 메일에 생성된 AI 초안 266건 expired 처리 | 완료 |
| `sql/repair_20260917f~i_*.sql` | 개인 메일함 처리 위치 조정 | 완료 (보충 처리 진행 중이었음) |

## 4. 도구

- `tools/run-sql.mjs` — Supabase 대시보드 없이 SQL 실행. 직접 연결이 IPv6라 실패하면 세션 풀러를 자동 탐색. 접속 후 `statement_timeout=30min`, NOTICE 출력.
  - `node --env-file=.env.local tools/run-sql.mjs sql\<file>.sql`
  - 풀러 세션 모드가 꽉 차면(`ECHECKOUTTIMEOUT`) 그 창에서만 `$env:SUPABASE_DB_URL`의 포트를 6543으로 바꿔 실행.
- `tools/imap-find.mjs` — 읽기 전용. 메일 서버에서 보낸 사람으로 검색해 uid 확인, 또는 목록과 크기 확인.
  - `node --env-file=.env.local tools/imap-find.mjs <mailbox> <from text> [days]`
  - `node --env-file=.env.local tools/imap-find.mjs <mailbox> --list <from uid>`
- 진단 SQL: `diag_ping`, `diag_sessions`, `diag_20260916_disk_io`, `diag_20260916b_rls_audit`, `diag_basf_mail`, `diag_ai_cost_by_hour`, `diag_ai_drafts_today_by_mail_age`, `diag_change_log_remaining`
- 정리 SQL: `repair_kill_stuck_runsql.sql` (남은 run-sql 세션만 종료)

## 5. 남은 일

1. **authenticated 제한 시간 되돌리기 (9/19경, 받은편지함이 안정적이면)**
   ```sql
   alter role authenticated set statement_timeout = '8s';
   notify pgrst, 'reload config';
   ```
2. **Disk IO 그래프** 1~2일 관찰. 안정되면 compute 업그레이드 불필요.
3. **개인 메일함 보충 처리 확인**: 1497~1526 처리 후 처리 위치가 1526 이상인지 `diag_basf_mail.sql`로 확인. uid 1496(13.6MB, 본인 발신)은 의도적으로 저장하지 않음.
4. **AI 일일 예산($50)**: 9/16은 장애 복구 중 밀린 메일 처리로 초과. 초과 이후 들어온 메일은 AI 분류/초안이 없고 자동 재처리되지 않음. 예산 정책 검토.
5. **정리 후보**: 루트 `middleware.ts`는 무시되는 파일(삭제 검토). `src/__tests__/email/mailcarrier.test.ts`의 4개 테스트는 이번 작업 이전부터 실패 중.
6. change_log에는 "중간 크기 값이 여러 개인" 행 약 1,600건이 남아 있으나 슬림화 대상이 아님(정상).

## 6. 교훈 / 주의

- 대량 UPDATE 조건은 **실제로 바뀌는 행만** 고를 것. v2 슬림화는 행 전체 크기로 대상을 골라, 바뀌지 않는 행을 매번 다시 기록해 DB를 다시 멈추게 했다(v3에서 수정).
- 메일 처리 위치를 되감기 전에 `tools/imap-find.mjs`로 **실제 uid를 먼저 확인**할 것. 추측으로 되감으면 불필요한 재처리가 생긴다.
- 워커 처리 도중 위치를 바꾸면 워커가 덮어쓴다. 고정 스크립트(2분 hold) + 재시작, 또는 워커가 대기 중일 때 변경.
- Supabase: `postgres`도 슈퍼유저가 아님(`pg_stat_reset` 불가). 풀러는 접속 파라미터의 `statement_timeout`을 무시하므로 접속 후 `SET`으로 지정.
- DO 블록 안의 `COMMIT`은 파일에 **그 DO 문 하나만** 있을 때 동작(run-sql은 파일 전체를 한 번에 보냄). `VACUUM`도 단독 파일로.
- Railway에 "Apply N changes"가 떠 있으면 **Details부터 확인**. 이번에는 두 서비스의 Repo/Branch 연결 삭제였고 Discard로 취소.
- PowerShell here-string의 닫는 `'@`는 **반드시 줄 맨 앞**. 들여쓴 채 붙여넣으면 `>>` 상태로 멈춤(Ctrl+C로 탈출).
- Public 저장소: `docs/handoff` 폴더 통째로 add 금지. 파일을 하나씩 지정.

## 7. SaaS 표준 (유지)

RLS org-scoping, 엔티티 테이블 `created_by uuid default auth.uid()` + `created_at/updated_at`, `app.users.id = auth.uid()`. join/link, history, lookup, log, 1:1 상세 테이블에는 `created_by`를 넣지 않는다. 이번 작업은 함수, 정책 표현식, 트리거, 인덱스 변경이며 테이블 스키마 변경은 없다.

## 8. 파일 이동 및 커밋

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add docs/handoff/2026-09-16/handoff_20260916b_incident_recovery.md
git commit -m "docs: 2026-09-16 incident recovery handoff"
git push origin marinebiogroup
```
push 시 Railway 자동 배포(문서만 변경이므로 앱 동작 영향 없음). 저장소가 Public이므로 push하면 이 문서도 공개된다.
