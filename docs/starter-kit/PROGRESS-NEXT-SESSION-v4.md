# 다음 세션 시작 — 핸드오프 v4

> **이전 세션(v3 → v4) 종료 시점**: Phase 3 (Classifier + Reply Drafter prompt camelCase 수정) 완료. End-to-end 파이프라인이 실제 분류 결과 + 회신 본문 생성까지 정상 작동. AI Drafts UI 화면 디자인 이슈도 해결. 다음 세션은 **RAG 복구 + Git 정리 + 운영 준비**.

---

## 첫 메시지 (그대로 복사해서 새 채팅에 붙여넣기)

```
Phase 3 (Classifier + Reply Drafter prompt camelCase 수정) 완료. 
End-to-end 검증 통과 — 메일 5건이 information_request / 0.92로 정상 처리됨.
AI Drafts 화면 sticky 헤더 겹침 이슈도 수정. 다음은 search_knowledge RPC 
함수 생성(RAG 복구) + Git 정리 + 운영 준비. 핸드오프 v4 문서 첨부합니다.
```

문서 첨부 (이 PROGRESS-NEXT-SESSION-v4.md).

---

## 프로젝트 컨텍스트

- **Repo**: https://github.com/MarineGift/mbg-project
- **Branch**: marinebiogroup
- **Local**: C:\dev\mbg-project
- **Org ID**: b25de8f2-1020-482f-9012-183f63883169
- **User ID**: 551fc4a0-b365-47eb-bf2f-0c3f594001c0
- **Stack**: Next.js 14.2.13, Supabase, Anthropic SDK, TABS Mailer, MailCarrier
- **언어**: 한국어 응답
- **메일서버**: mail.marinebiogroup.com (자체 호스팅, IMAP 143 STARTTLS, SMTP 587 평문)
- **3개 계정**: personal (yunyoung.heo@), role (ceo@), shared (contact@)

---

## ✅ 이번 세션에서 완성된 사항

### Phase 3-a — OpenAI quota 복구

- OpenAI 결제 정보 추가 + credit 충전 → embedding API 200 OK 확인
- `text-embedding-3-large` 호출 시 quota 정상
- 단, 일부 OpenAI 키 이슈는 `.env.local`이 PowerShell 셸에 자동 로드 안 되는 점을 확인하면서 우회 (실제 운영에선 Node.js 워커가 dotenv로 읽으므로 무관)

### Phase 3-b — mailcarrier_state 복구

`mailcarrier_state` 테이블에 row가 없는 inbox는 `last_uid=0`으로 시작 → 자체 호스팅 IMAP이 `range=1:*` 요청에 hang. 다음 작업으로 정상화:

```sql
-- role inbox state row 생성 + uid 점프
INSERT INTO app.mailcarrier_state 
  (organization_id, kind, username, last_processed_uid, updated_at)
VALUES (
  'b25de8f2-1020-482f-9012-183f63883169',
  'role',
  'ceo@marinebiogroup.com',
  3955,
  NOW()
)
ON CONFLICT (organization_id, kind, username)
DO UPDATE SET last_processed_uid = EXCLUDED.last_processed_uid;

-- 최종적으로 12200으로 점프 (실제 inbox uid는 ~12500대)
UPDATE app.mailcarrier_state
SET last_processed_uid = 12200, updated_at = NOW()
WHERE kind = 'role';
```

### Phase 3-c — Spam 우회 (webmail 측 작업)

`marinegift4u@gmail.com`에서 보낸 테스트 메일들이 모두 webmail Spam 폴더로 분류되어 INBOX에 안 도달. 해결:

- mail.marinebiogroup.com → Options → SPAM → Safe senders → `marinegift4u@gmail.com` 추가
- 이후 발송한 메일은 Inbox 직행 확인

### Phase 3-d — Classifier Prompt camelCase 수정 (핵심)

`app.ai_agents` 테이블의 `classifier` agent system_prompt가 snake_case로 작성되어 `validateClassificationOutput` schema 검증이 100% 실패하던 문제.

**진단 경로**:
1. `processor.ts:289` — `classifier output invalid: ... → forcing 'other'` 로그 위치
2. `src/types/classification.ts:135` — `validateClassificationOutput` 함수
3. Schema 기대 필드 (camelCase): `category`, `urgency`, `sentiment`, `requiresHuman`, `confidence`, `rationale`, `riskFlags`, `detectedLanguage`, `topics?`, `entities?`
4. DB의 prompt는 snake_case로 작성: `language_detected`, `key_signals` (sentiment/requiresHuman/riskFlags 자체 누락)
5. 결과: 모든 draft가 `category='other'`, `confidence=0.300` (fallback) 으로 강제

**수정 SQL** (Supabase):

```sql
UPDATE ai.agents
SET system_prompt = $sp$You are an email classifier for a multi-module B2B CRM platform.

Classify the inbound message into EXACTLY ONE of these 10 standard categories:
- information_request
- meeting_scheduling
- simple_acknowledgment
- price_negotiation
- contract_terms
- rejection
- complaint
- introduction
- follow_up
- other

Output STRICT JSON ONLY using EXACTLY these field names (camelCase):

{
  "category": "<one of the 10 above>",
  "urgency": "<low|medium|high|urgent>",
  "sentiment": "<positive|neutral|negative|mixed>",
  "requiresHuman": <true|false>,
  "confidence": <number 0.0 to 1.0>,
  "rationale": "<one short sentence>",
  "riskFlags": [<zero or more from the allowed list below; use [] if none>],
  "detectedLanguage": "<ko|en|ja|zh|other>",
  "topics": ["<optional keywords>"]
}

ALLOWED riskFlags values (use ONLY these strings, never invent new ones):
- quality_certification
- pricing_dispute
- delivery_issue
- quality_complaint
- capacity_commitment
- audit_finding_topic
- pii_in_request
- regulatory_topic
- litigation_topic

CRITICAL field naming rules:
- ALL field names MUST be camelCase. Wrong: requires_human, language_detected, risk_flags. Right: requiresHuman, detectedLanguage, riskFlags.
- requiresHuman MUST be a boolean literal (true or false), never a string.
- riskFlags MUST be an array, use [] when empty (never null, never omitted).
- detectedLanguage MUST be one of exactly: ko, en, ja, zh, other. Use "zh" not "zh-CN" or "zh-TW".
- sentiment is REQUIRED — classify the emotional tone even for neutral business messages.

Other rules:
- NEVER invent new categories. Use exactly the 10 listed.
- Set requiresHuman=true when: confidence<0.7, message touches legal/contractual/complaint topics, or any riskFlags are detected.
- Detect language from the message body, not the subject line alone.

Example output for a typical inquiry:
{
  "category": "information_request",
  "urgency": "medium",
  "sentiment": "neutral",
  "requiresHuman": false,
  "confidence": 0.85,
  "rationale": "Customer requesting product datasheet and pricing.",
  "riskFlags": [],
  "detectedLanguage": "en",
  "topics": ["datasheet", "pricing"]
}$sp$
WHERE id = 'cf788e07-252a-4322-9f64-796b1640f172';
```

- Length: 773 → 2210 chars
- agent prompt는 매 호출마다 DB SELECT (`claude-client.ts`의 `loadAgent`)이므로 **워커 재시작 불필요** — 즉시 반영

### Phase 3-e — Reply Drafter Prompt camelCase 수정 (7개 agent)

같은 패턴으로 7개의 `reply_drafter` agent prompt도 snake_case로 잘못 작성됨:
- `body_plain` → `bodyPlain`
- `body_html` → `bodyHtml`
- `risk_flags` → `riskFlags`
- `requires_human_approval` → `requiresHumanApproval`

추가로 `Standard Reply Drafter`만 `language: <ko|en|ja|zh-CN>` 잘못 — schema는 `'ko'|'en'|'ja'`만 허용 (zh-CN 없음).

**수정 SQL — 7개 일괄**:

```sql
-- ① snake_case → camelCase 일괄 치환 (7개 agent 모두)
UPDATE ai.agents
SET system_prompt = REPLACE(REPLACE(REPLACE(REPLACE(
        system_prompt,
        '"body_plain"', '"bodyPlain"'),
        '"body_html"', '"bodyHtml"'),
        '"risk_flags"', '"riskFlags"'),
        '"requires_human_approval"', '"requiresHumanApproval"'),
    updated_at = NOW()
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND role = 'reply_drafter';

-- ② Standard Reply Drafter의 zh-CN 제거
UPDATE ai.agents
SET system_prompt = REPLACE(system_prompt, '<ko|en|ja|zh-CN>', '<ko|en|ja>'),
    updated_at = NOW()
WHERE id = '61f031ef-4c27-44fd-b35e-6f741676f0c3';
```

### Phase 3-f — End-to-end 검증 통과

`marinegift4u@gmail.com` 발신 메일 5건 처리 결과:

| Subject | Category | Confidence | has_body |
|---|---|---|---|
| Final test - chitosan inquiry verification | **information_request** | **0.92** | ✅ |
| Chitosan grade evaluation request | **information_request** | **0.92** | ✅ |
| dsfsdfsdfsd... (의미없는 텍스트) | other | 0.05 | ✅ |
| Datasheet inquiry for chitosan grade samples | **information_request** | **0.92** | ✅ |
| Sample request for chitosan grade testing | **information_request** | **0.92** | ✅ |

- `category` ≠ `other` (3개 카테고리 다양)
- `confidence` ≠ `0.300` (실제 값 0.92)
- `body_plain` 채워짐 (drafter 정상)
- 의미없는 텍스트는 적절히 `other / 0.05` (시스템이 정확하다는 증거)

### Phase 3-g — AI Drafts UI 헤더 겹침 수정

`src/components/drafts/draft-queue-table.tsx`의 `<thead>`가 `sticky top-[57px]`로 설정되어 부모 컨테이너 overflow와 충돌 → 헤더와 첫 데이터 row가 항상 겹쳐서 표시되던 문제.

**수정** (한 줄):

```tsx
// 변경 전
<thead className="border-b bg-muted/40 sticky top-[57px] z-10">

// 변경 후 (sticky 제거 + 시각적 분리 강화)
<thead className="border-b-2 bg-muted/60">
```

sticky 유지하려는 시도는 부모 컨테이너 overflow 구조 문제로 실패. 운영용 안정성 위해 sticky 포기하고 일반 테이블로 변경.

---

## 🚧 남은 미해결 항목 (다음 세션 우선순위)

### 1. **`search_knowledge` RPC 함수 생성** ⚠️ 우선순위

```
[prompt-renderer.loadKnowledgeChunks] {
  code: 'PGRST202',
  message: 'Could not find the function public.search_knowledge(p_collection, p_limit, p_min_similarity, p_organization_id, p_query_embedding)'
}
```

RAG의 knowledge_chunks 검색이 미작동. graceful skip이라 워커는 안 죽지만:
- drafter에 knowledge_chunks 컨텍스트 안 들어감 → 본문 길이 짧음 (89 chars로 관찰)
- brand_voice도 비어있을 가능성

**작업 내용**:
- Supabase에 `vector` extension 활성화 확인
- `ai.knowledge_chunks` 테이블 스키마 확인
- `public.search_knowledge` RPC 함수 정의 (parameters: `p_collection, p_limit, p_min_similarity, p_organization_id, p_query_embedding`)
- 코사인 유사도 기반 top_k 검색 로직
- 인덱스 (`ivfflat` 또는 `hnsw`) 생성

### 2. **env.ts conditional schema** (15분)

`.env.local`에 `MAILCARRIER_USERNAME`/`MAILCARRIER_PASSWORD`가 여전히 required로 되어 있어 fallback용 2줄 (`contact@` 값) 필요. `MAILCARRIER_POLL_KINDS` 있으면 옵셔널로 만들기:

```typescript
// env.ts에서 (대략적)
MAILCARRIER_USERNAME: z.string().optional(),
MAILCARRIER_PASSWORD: z.string().optional(),
// .refine() 로 POLL_KINDS 비어있으면 둘 다 required 검증
```

### 3. **Personal inbox 복귀 전략**

현재 `.env.local`의 `MAILCARRIER_POLL_KINDS=role,shared` (personal 제외). personal inbox는 약 250개의 미처리 메일이 쌓여있어서 워커가 lock을 독점하던 문제 때문에 비활성. 복귀 전략:

**옵션 A — uid 점프 후 활성화** (권장):
```sql
-- personal inbox state row 강제 생성, 가장 큰 uid보다 큰 값으로
INSERT INTO app.mailcarrier_state
  (organization_id, kind, username, last_processed_uid, updated_at)
VALUES (
  'b25de8f2-1020-482f-9012-183f63883169',
  'personal',
  'yunyoung.heo@marinebiogroup.com',
  9999,  -- 현재 personal inbox uid보다 큰 값
  NOW()
)
ON CONFLICT (organization_id, kind, username)
DO UPDATE SET last_processed_uid = EXCLUDED.last_processed_uid;
```

그 후 `.env.local`에서 `MAILCARRIER_POLL_KINDS=personal,role,shared`로 복귀, 워커 재시작.

**옵션 B — inbox별 독립 lock** (코드 작업):
- 현재 모든 inbox가 IMAP connection을 공유해서 한 inbox가 처리 중이면 다른 inbox가 대기
- 각 inbox에 별도 ImapFlow 인스턴스 분리하면 병렬 처리 가능
- Phase 4 작업으로 추천 (구조 변경 큼)

### 4. **Git 정리** ⚠️ 다음 세션 시작 직후 권장

`git status`에 의도치 않은 변경 + untracked 파일 잔뜩 쌓임:

**의도된 변경 (커밋 대상)**:
- `src/lib/email/mailcarrier.ts` (Phase 2-b/2-c 패치)
- `src/lib/ai/claude-client.ts`
- `src/lib/email/whitelist.ts` (untracked)
- `src/workers/mailcarrier-worker.ts` (untracked)
- `src/lib/env.ts`
- `src/scripts/` (untracked)
- `src/types/email.ts`
- `src/components/drafts/draft-queue-table.tsx` (이번 세션 UI 수정)
- `package-lock.json`, `package.json`

**검토 필요한 변경 (이번 디버깅 부작용 가능)**:
- `src/components/drafts/approve-draft-dialog.tsx`
- `src/components/drafts/bulk-reject-dialog.tsx`
- `src/components/drafts/reject-draft-dialog.tsx`
- `src/components/inbox/*`
- `src/components/engagements/*`
- `src/components/parties/*`
- i18n messages
- `src/lib/queries/*`
- `src/lib/actions/*`
- `src/lib/auth.ts`
- `src/lib/email/tabs-mailer.ts`
- `src/app/(app)/[module]/engagements/new/page.tsx`
- `src/app/(app)/[module]/parties/[id]/page.tsx`
- `src/app/(app)/engagements/[id]/edit/page.tsx`

각 파일에 `git diff <file>` 돌려서 의도된 변경인지 확인 후 커밋 또는 `git checkout`.

**.gitignore 보강** (untracked 임시 파일):
```
worker-*.log
worker.log
*_dump.txt
env.local.*.backup
```

### 5. **Bulk Actions Bar와 테이블 헤더 충돌 가능성**

`draft-queue-bulk-actions.tsx`가 `sticky top-14 z-20`로 설정. 행 체크박스 선택 시 벌크 액션 바가 나타나는데, 만약 테이블 헤더에 다시 sticky 적용할 경우 같은 자리 충돌. 현재는 헤더 sticky 제거 상태라 문제 없음. 추후 sticky 다시 도입 시 주의.

### 6. **운영 준비 작업** (별도 큰 작업)

- `sql/010_rls_policies.sql` 적용 (현재 service_role 우회 중)
- SMTP STARTTLS 활성화 (현재 평문 587)
- 첨부 발송 기능 구현
- `uncaughtException` 핸들러에서 `process.exit(1)` 으로 변경 (운영 단계 진입 시)
- Reply Drafter 본문 길이 문제 — RAG 복구 후 자동 개선 기대, 안 되면 prompt 추가 보강

### 7. **메일서버 측 점검 (선택, 낮은 우선순위)**

Phase 2-c에서 UID 추적으로 우회한 IMAP `\Seen` 응답 불안정 문제. 코드 측에서 이미 해결돼서 필수 아님. 메일서버 직접 수정하려면 SW 종류(Dovecot? Cyrus?), IMAP timeouts/locking 설정, 다중 client 접속 lock 정책 확인.

---

## ✅ 현재 상태 — 시스템 동작 확인

### 마지막 정상 동작 로그 (Phase 3-d/3-e 검증 후)

```
[mailcarrier-worker:role:94e80cd9] new inbound — from=ceo@marinebiogroup.com
[prompt-renderer.loadKnowledgeChunks] PGRST202 (RAG skip)
[mailcarrier-worker:role:94e80cd9] processed → 
  draft.id=4c36bdd5-c9d8-4986-90b2-91f12887d4b4
  category=simple_acknowledgment confidence=0.92 auto_send=false
```

- ✅ Classifier 정상: `category=simple_acknowledgment`, `confidence=0.92` (fallback 아님)
- ✅ Reply Drafter 정상: draft 생성, body_plain 채워짐
- ⚠️ RAG skip: knowledge_chunks 검색 안 됨 (graceful), 다음 세션 작업

### DB 검증 쿼리 (운영 모니터링용)

```sql
-- 1. UID 추적 상태 확인
SELECT kind, username, last_processed_uid, updated_at
FROM app.mailcarrier_state
ORDER BY kind;

-- 기대:
--   role    | ceo@marinebiogroup.com     | 12200+ (워커 진행 따라 증가)
--   shared  | contact@marinebiogroup.com | 14 (변동 없음)
--   personal| 없음 (POLL_KINDS에서 제외 상태)

-- 2. 최근 inbound 메일 + draft 결과 확인
SELECT 
  d.classification_category,
  d.confidence_score,
  d.requires_human_approval,
  d.status,
  c.subject,
  c.from_address,
  d.created_at
FROM ai.drafts d
JOIN app.communications c ON c.id = d.inbound_communication_id
WHERE c.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND d.created_at > NOW() - INTERVAL '1 hour'
ORDER BY d.created_at DESC
LIMIT 20;

-- 3. agent prompt 검증 (snake_case 잔존 확인)
SELECT 
  name, 
  LENGTH(system_prompt) AS len,
  (LENGTH(system_prompt) - LENGTH(REPLACE(system_prompt, '"body_plain"', ''))) / LENGTH('"body_plain"') AS body_plain_count,
  (LENGTH(system_prompt) - LENGTH(REPLACE(system_prompt, '"risk_flags"', ''))) / LENGTH('"risk_flags"') AS risk_flags_count
FROM ai.agents
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
ORDER BY role, name;

-- 기대: 모든 행에서 body_plain_count=0, risk_flags_count=0
```

---

## 환경변수 현재 상태

```dotenv
# IMAP
MAILCARRIER_HOST=mail.marinebiogroup.com
MAILCARRIER_PORT=143
MAILCARRIER_USERNAME=contact@marinebiogroup.com   # fallback (env.ts required, 다음 세션에 옵셔널화)
MAILCARRIER_PASSWORD=<rotated>                    # fallback
MAILCARRIER_USE_IDLE=false
MAILCARRIER_INBOX_FOLDER=INBOX
MAILCARRIER_POLL_INTERVAL_SECONDS=30
MAILCARRIER_TLS_REJECT_UNAUTHORIZED=false
MAILCARRIER_POLL_KINDS=role,shared                # ⚠️ personal 비활성 (다음 세션에서 복귀)

# Multi-account credentials
MAIL_PERSONAL_USERNAME=yunyoung.heo@marinebiogroup.com
MAIL_PERSONAL_PASSWORD=<rotated>
MAIL_PERSONAL_DISPLAY_NAME=YunYoung Heo
MAIL_ROLE_USERNAME=ceo@marinebiogroup.com
MAIL_ROLE_PASSWORD=<rotated>
MAIL_ROLE_DISPLAY_NAME=CEO
MAIL_SHARED_USERNAME=contact@marinebiogroup.com
MAIL_SHARED_PASSWORD=<rotated>
MAIL_SHARED_DISPLAY_NAME=Marinebio Group

# AI
ANTHROPIC_API_KEY=<rotated>
ANTHROPIC_MODEL_OPUS=claude-opus-4-7
ANTHROPIC_MODEL_HAIKU=claude-haiku-4-5-20251001
ANTHROPIC_MODEL_SONNET=claude-sonnet-4-6
OPENAI_API_KEY=<rotated>                          # ✅ quota 결제 완료
OPENAI_EMBEDDING_MODEL=text-embedding-3-large

# Supabase
SUPABASE_SERVICE_ROLE_KEY=<rotated>
SUPABASE_DB_URL=postgresql://postgres:<rotated>@db.ogenmrgxwhpbfepeldqx.supabase.co:5432/postgres
SUPABASE_STORAGE_BUCKET_ATTACHMENTS=communications-attachments
```

---

## 화이트리스트 (이번 세션 확정)

테이블: `app.email_whitelist` (SQL은 `015_email_whitelist.sql` 참조)

```sql
SELECT pattern, kind, notes 
FROM app.email_whitelist
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND is_active = true;
```

현재 등록:
- `marinebiogroup.com` (domain) — 자기 도메인
- `marinegift4u@gmail.com` (address) — 테스트용 외부 주소

신규 외부 발신자 추가 시:
```sql
INSERT INTO app.email_whitelist (organization_id, pattern, kind, notes)
VALUES (
  'b25de8f2-1020-482f-9012-183f63883169', 
  'newpartner@example.com', 
  'address', 
  '새 파트너'
);
```

---

## 이번 세션의 교훈

1. **Schema와 prompt의 case mismatch는 매우 흔한 버그** — Anthropic Claude는 prompt에 명시한 그대로 응답함. snake_case로 지시하면 snake_case 응답. validation은 camelCase 기대 → 100% 실패. 양쪽 일치시키는 게 가장 빠른 해결.

2. **Validation 실패 시 fallback이 너무 관대하면 진단이 어려움** — `category='other'/confidence=0.3` 으로 fallback되니까 워커가 안 죽고 정상 작동하는 것처럼 보임. 다행히 `processor.ts:289`에 `console.warn`이 있어서 worker.log 확인으로 진단 가능했음. 향후 fallback에 더 진하게 표시하면 좋겠다 (예: `confidence=0.0001` 같이).

3. **자체 호스팅 IMAP은 큰 fetch range에 hang** — `range=1:*`처럼 처음부터 전체 fetch 요청은 메일이 많을 때 응답 지연. `mailcarrier_state.last_processed_uid`로 range를 좁혀야 함. 새 inbox 시작 시엔 미리 큰 uid로 점프해두는 게 안전.

4. **agent prompt가 DB SELECT 매 호출마다 됨** — `loadAgent`가 캐싱 안 함. 즉 prompt UPDATE는 즉시 반영, 워커 재시작 불필요. 운영 시 prompt 튜닝 빠른 사이클 가능.

5. **Spam 폴더 분류는 webmail 측 작업** — 코드 측 화이트리스트와 별개로 메일서버 자체의 spam 필터가 동작. Safe sender 등록 필요. 자동화하려면 webmail API 또는 메일서버 설정 직접 변경.

6. **Sticky CSS는 부모 컨테이너 overflow에 민감** — `sticky`가 viewport 기준이 아니라 가장 가까운 overflow 부모 기준으로 트리거됨. 안 보이는 상위 컨테이너에 overflow가 있으면 sticky가 의도와 다르게 동작. 운영 안정성을 위해 sticky 포기하는 게 답일 때가 많음.

7. **PowerShell regex 치환은 JSX에 위험** — 복잡 구조 자동 수정 시 빌드 깨짐. Git이 있으니 `git checkout`으로 즉시 복원 가능. VS Code에서 직접 수정하는 게 안전.

---

## 다음 세션 추천 시작 순서

1. **Git 정리 — 30분** (다른 작업 시작 전 필수)
   - `git diff` 각 변경 파일 검토
   - 의도된 변경: commit
   - 의도치 않은 변경: `git checkout`
   - `.gitignore` 보강
   - 의미 있는 커밋 메시지로 chunk별 commit

2. **personal inbox 복귀 — 15분**
   - 위 옵션 A의 UPSERT SQL 실행 (uid=9999)
   - `.env.local`에서 `MAILCARRIER_POLL_KINDS=personal,role,shared` 복귀
   - 워커 재시작
   - 30초 후 워커 로그에서 `[mailcarrier:personal] fetch: range=10000:*` 확인

3. **`search_knowledge` RPC 함수 생성 — 1~2시간**
   - vector extension 확인
   - knowledge_chunks 테이블 스키마 확인
   - RPC 함수 정의 + 인덱스
   - 워커 로그에서 `loadKnowledgeChunks` PGRST202 사라지는지 확인
   - 다음 chitosan 메일 처리 시 body_len 증가 확인 (89 → 200+)

4. **env.ts conditional schema — 15분**
   - `MAILCARRIER_USERNAME/PASSWORD` 옵셔널화
   - `.refine()` 로 POLL_KINDS 없으면 둘 다 required 검증
   - `.env.local`에서 fallback 2줄 제거 가능

5. **운영 준비 — 별도 큰 작업** (위 미해결 항목 #6 참조)

---

## 디버깅 명령 참고 (PowerShell)

```powershell
# 워커 종료 + 백업 + 재시작 (3개 한 줄)
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep -Seconds 3; $log = "worker-$(Get-Date -Format 'HHmmss').log"; npm run worker:mailcarrier 2>&1 | Tee-Object -FilePath $log

# 워커 로그에서 specific 패턴 검색
Get-Content -Path .\worker.log -Encoding UTF8 | Select-String -Pattern "classifier|drafter|invalid|embedding" | Select-Object -Last 30

# 마지막 N 줄
Get-Content -Path .\worker.log -Tail 80 -Encoding UTF8

# 실시간 follow (Linux tail -f 같이)
Get-Content -Path .\worker.log -Wait -Tail 50

# 코드에서 패턴 검색
Get-ChildItem -Path src -Recurse -Filter *.ts | Select-String -Pattern "<패턴>" | Select-Object Filename, LineNumber, Line -First 10

# 파일 일부 보기
Get-Content -Path .\src\<path> -Encoding UTF8 | Select-Object -Skip <N> -First <M>
```

---

## 참고 — Phase 2-c (이전 세션 v3) 정리

Phase 2-c에서 해결된 자체 호스팅 IMAP `\Seen` 미응답 문제는 UID 추적으로 코드 측에서 우회 완료. 이번 세션에서도 그 메커니즘으로 정상 작동. 단, **state row가 없는 inbox**는 여전히 `last_uid=0`으로 시작하여 큰 fetch hang 위험 있음. 새 inbox 추가 시 항상 적절한 uid로 state row 사전 생성 필요.

이번 세션의 mailcarrier_state 작업이 그 보강:

```sql
-- 새 inbox 추가 시 템플릿
INSERT INTO app.mailcarrier_state 
  (organization_id, kind, username, last_processed_uid, updated_at)
VALUES (
  '<org_id>',
  '<kind>',           -- personal | role | shared
  '<email>',
  <inbox 최신 uid 추정값>,
  NOW()
)
ON CONFLICT (organization_id, kind, username)
DO UPDATE SET last_processed_uid = EXCLUDED.last_processed_uid;
```
