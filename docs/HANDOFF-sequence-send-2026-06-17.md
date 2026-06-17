# HANDOFF — Sequence Sending Pipeline / mbg-project / marinebiogroup

작성: 2026-06-17 (KST 야간 세션)
브랜치: `marinebiogroup` / 로컬: `C:\dev\mbg-project`
Supabase: `ogenmrgxwhpbfepeldqx` / org: `b25de8f2-1020-482f-9012-183f63883169`
Railway: web+worker 서비스 = `lucky-patience` (urm.marinebiogroup.com)
HEAD: `b5b377f`

---

## TL;DR — 이번 세션 결과

**Email Sequence(케이던스) 발송 파이프라인을 처음부터 끝까지 뚫었다.** 테스트 1건(MBG Mailing Test → ceo@marine-gift.com)이 **서명 자동첨부 + 본문 정상**으로 실제 수신 확인됨(`{"processed":1,"sent":1}`).

발송이 안 되던 원인이 **5개 관문**으로 줄줄이 있었고 하나씩 다 해결:
1. Edit 다이얼로그가 저장된 본문을 안 불러옴 → `key`로 remount (`5dbcff3`)
2. 시퀀스 발송에 서명 미첨부 → processor가 org 기본 서명 append (`b46e010`)
3. `get_due_enrollments`가 `st.body_text`(없는 컬럼) 참조 → `body_plain`+alias `step_body` (`f98f889`)
4. Run Now 401 → CRON_SECRET **불일치**(서버는 64자 hex, 내가 보낸 건 15자였음). 실제 값 = `a3f8e1c97b24d605fae8923c1d47b60e9f5128a7c3e0b94d6172fa8be35c0d49`
5. `get_due_enrollments`가 contact_email/이름/party_name 미반환 → processor가 skip → contacts/parties join 추가 (`a7a2032`, **SQL 직접 실행으로 적용**)
6. communications INSERT가 **RLS 위반**(cron은 세션 없음) → processor를 **service-role admin 클라이언트**로 전환 (`1678f09`)

**그린(완료·검증):** 시퀀스 CRUD UI, Edit 본문 로딩, 시퀀스 서명 자동첨부, get_due_enrollments(body+contact), CRON_SECRET 인증, RLS 우회, **실제 발송+수신**
**다음 세션 1순위:** 중복 "15 min..." 시퀀스 정리 (status 타입 확인 후 archive) → 실제 발송(Bulk Enroll Investors+High 29곳)
**보류/선택:** 서명 이메일 통일, 발신 계정 결정

---

## 가장 중요한 교훈 (반드시 기억)

1. **SQL은 push가 아니라 Supabase SQL Editor 실행으로만 적용.** 이번에도 `a7a2032`(get_due_enrollments contact_fields)를 push만 하고 SQL 실행을 안 해서 한참 "contact_email does not exist"가 났다. 마이그레이션 파일은 기록용, **실효는 SQL Editor 실행.**

2. **CRON_SECRET 디버깅 = 추측 금지, 서버가 보는 값을 직접 확인.** 임시 debug 엔드포인트로 `env_secret_length`(64) vs `header_length`(15) 비교해서 즉시 판명. 서버에 든 실제 값은 64자 hex였다(내가 처음 제안한 그 값). 변수 바꾸지 말고 **그 값을 헤더로 보내면 됨**.

3. **cron/worker 엔드포인트는 로그인 세션이 없다 → RLS에 막힌다.** `createSupabaseServerClient()`(세션 기반) 대신 **`createSupabaseAdminClient()`**(service_role, RLS 우회) 사용. admin.ts 주석에 "STEP 3 workers / webhook용" 명시돼 있음. `SUPABASE_SERVICE_ROLE_KEY`는 Railway에 이미 있음.

4. **`body_text` 컬럼은 존재하지 않는다.** 실제 컬럼은 `app.email_sequence_steps.body_plain`. 이 잔재가 create/update/get_with_steps/get_due 4개 함수에 흩어져 있었고 전부 잡았다. `email_sequence_steps`에는 `body_html`/`template_id` 컬럼도 **없음**(processor엔 NULL로 전달).

5. **처리 실패는 응답에 errors 배열로 노출하게 해뒀다.** `processSequence`가 enrollment별 에러를 `errors:[{enrollment_id,error}]`로 반환(`4fcbe2b`). 발송 디버깅 시 매우 유용 — 그대로 유지 권장.

6. **배포 지연 주의.** push 후 Railway 빌드가 Active 될 때까지 옛 코드가 응답. 매번 Deployments에서 최신 커밋 Active 확인 후 호출. (이번에 RLS fix도 빌드 전엔 같은 에러가 나서 "안 고쳐졌나" 착각함.)

---

## 발송 파이프라인 전체 흐름 (검증된 동작)

1. **Bulk Enroll** (UI 또는 `public.bulk_enroll_filtered(org, seq_id, p_module=>'investor', p_name_contains=>..., p_dry_run=>...)`)
   → 이메일 있는 파티의 primary contact를 `app.email_sequence_enrollments`에 등록 (status=active, next_step_order=0, next_send_at=now)
2. **트리거**: `POST /api/sequences/process` (헤더 `x-cron-secret: <64자값>`) → `triggerSequenceProcessor`/cron → `processSequence()`
3. `public.get_due_enrollments()` → active & next_send_at<=now 인 건의 step + contact + party 반환
4. processor가 merge field 치환 → 본문 HTML화 → **org 기본 서명 append**(`<hr>`+html_content WHERE is_default) → 트래킹픽셀 → communications INSERT(service-role) → nodemailer 발송 → `advance_enrollment`
5. Day 0/3/7 진행

발송 수동 트리거(테스트):
```powershell
$secret = "a3f8e1c97b24d605fae8923c1d47b60e9f5128a7c3e0b94d6172fa8be35c0d49"
$r = Invoke-WebRequest -Method POST -Uri "https://urm.marinebiogroup.com/api/sequences/process" -Headers @{ "x-cron-secret" = $secret } -UseBasicParsing
$r.Content   # {"processed":N,"sent":N,"failed":N,"skipped":N,"errors":[...]}
```

발송 확인 SQL:
```sql
select created_at, to_addresses, status, bounce_reason
from app.communications
where (external_data->>'source') = 'sequence'
order by created_at desc limit 10;
```

---

## 현재 시퀀스 상태 (3개 — 정리 필요)

| id | name | 상태 | 처리 |
|----|------|------|------|
| `151d5454-8efc-4ecb-90a6-ff4f0d18520d` | 15 min on a filler tech... | active, 본문 최신, **테스트 발송 검증됨** | **살릴 것 (발송용)** |
| `025f2c6f-4fa5-4126-bf1c-b2ea9ba96704` | 15 min on a filler tech... | active, 중복 | **정리(archive)** |
| `87050eeb-8cc2-4b68-b2d5-c1a5cd9903af` | Investor Cold Outreach — High Priority | active, 옛 본문/`[One personal line]` 자리표시자 남음 | **정리(archive)** |

UI Archive 버튼이 회색(비활성)이라 클릭 안 됨 → **SQL로 처리해야 함**.
미해결: `app.email_sequences.status`의 타입/허용값 미확인. 다음 세션 첫 작업:
```sql
-- (1) status 컬럼 타입
select column_name, data_type, udt_name
from information_schema.columns
where table_schema='app' and table_name='email_sequences' and column_name='status';
-- (2) 현재 쓰이는 값
select distinct status from app.email_sequences;
-- (3) udt_name이 enum이면 그 값 (타입명 대입)
-- select enum_range(null::app.<udt_name>);
```
→ 'archived'/'paused' 등 허용값 확인 후, 025f2c6f / 87050eeb 두 개 UPDATE.
(text 타입이면 자유 문자열 가능. 완전 DELETE는 enrollment/이력 FK 깨질 수 있어 **archive 권장**.)

---

## 이번 세션 테스트 정리 상태

- MBG Mailing Test enrollment(`12bb425d-0296-416f-95c6-2766ab13bec6`) → **cancelled 처리 완료** (Day 3/7 안 나감)
- MBG Mailing Test 파티: id `8fd7b4ae-73b7-4d33-8fb5-f7876109eef7`, Investors, priority=(none), primary contact `ceo@marine-gift.com`(+5개 본인 주소), contact_id `87e5d64e-d440-485d-a1c2-845341a8bf45`
- 재테스트 시: `bulk_enroll_filtered(... p_name_contains=>'MBG Mailing Test' ...)` (priority 필터는 비울 것 — none이라 High로는 안 잡힘)

---

## 커밋 히스토리 (이번 세션, origin/marinebiogroup, 최신순)

```
b5b377f chore: remove temporary debug-auth diagnostic endpoint
1678f09 fix(sequences): processor uses service-role client (RLS was blocking inserts)
4fcbe2b debug(sequences): surface per-enrollment processor errors in response
aff8092 chore: extend debug-auth with SMTP env presence check        [엔드포인트는 b5b377f에서 제거됨]
a7a2032 fix(sequences): get_due_enrollments returns contact_email/name/party_name  [SQL은 직접 실행함]
4f873fd chore: temporary debug-auth endpoint                          [제거됨]
f98f889 fix(sequences): get_due_enrollments reads body_plain, alias step_body  [구버전, a7a2032가 대체]
b46e010 feat(sequences): attach org default signature on sequence sends
5dbcff3 fix(sequences): remount edit dialog via key so it loads saved steps
9d79ae2 fix(sequences): get_sequence_with_steps reads body_plain (Edit dialog)
e71ad87 feat(mailing): tabs for Mailing + Email Sequences (CRUD) on /mailing
```

DB에 직접 실행한 SQL(리포 마이그레이션과 별개로 라이브 적용됨):
- `get_sequence_with_steps` body_plain 수정 (9d79ae2 대응)
- `get_due_enrollments` 최종본 (DROP+CREATE, body_plain + alias step_body + contacts/parties join + body_html/template_id를 NULL). **이게 라이브 함수의 최종 정의.**

---

## 다음 세션 TODO (우선순위)

1. **[1순위] 중복 시퀀스 정리** — 위 status 타입 확인 → `025f2c6f`, `87050eeb` 2개 archive. `151d5454`만 발송용으로 남김.
2. **[선택] 발신 계정 결정** — 현재 발신자 `contact@marinebiogroup.com`(=`TABS_MAILER_USERNAME`). 투자자에게 `ceo@`/`yunyoung.heo@`로 보내려면 변수 변경.
3. **[선택] 서명 이메일 통일** — 서명 HTML에 `yunyoung.heo@` / `ceo@marinebiogroup.com` 혼재. Settings→Email Signature에서 **기존 서명 편집**(새로 만들지 말 것). 기본 서명 id `7b500196-e55d-4fc2-95b9-62d1e0f37d8f`.
4. **[발송] 실제 케이던스 시작** — `151d5454` 본문 최종 확인 → Bulk Enroll(Investors + Priority High) → Preview(이메일 있는 **29곳**, 없는 28곳 자동 skip) → Enroll → cron 자동 발송(또는 process 수동 호출). Day 0/3/7 + 서명 자동첨부.
5. **[선택] Bulk Enroll UI에 "Name contains" 입력칸 추가** — 함수/액션/typed-rpc엔 `p_name_contains` 있으나 다이얼로그 입력칸만 없음. (Tier 필터도 고아 상태: tier_1..cold vs account_scores A/B/C 미연결)

---

## 환경/접속 참고

- CRON_SECRET (Railway lucky-patience): `a3f8e1c97b24d605fae8923c1d47b60e9f5128a7c3e0b94d6172fa8be35c0d49` (64자)
- NEXT_PUBLIC_APP_URL: `https://urm.marinebiogroup.com`
- SMTP: `TABS_MAILER_HOST/PORT/USERNAME/PASSWORD` 전부 존재. USERNAME=`contact@marinebiogroup.com`(26자), USE_MOCK=null(실발송).
- 발송 도메인 whitelist: 이번 테스트(marine-gift.com)는 통과했음(processor가 whitelist 안 거치는 것으로 보임). 실제 투자자 도메인은 발송 시 확인.
