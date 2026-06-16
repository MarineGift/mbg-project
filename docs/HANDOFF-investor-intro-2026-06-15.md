# HANDOFF — Investor Introduction & Priority (2026-06-15)

> 다음 세션은 이 문서만 읽고 바로 이어갈 수 있도록 작성. 코드/SQL은 English, 본문은 한국어.
> 저장 위치 제안: `docs/HANDOFF-investor-intro-2026-06-15.md`

---

## 0) 다음 세션 작업 (핵심)

**목표: Investors 에 회사 소개(Introduction, intro_ko/intro_en)를 채운다.**
1. **Advanced Materials 섹터부터 시작** — 우리(mbg)와 관련 있는 투자사 우선.
2. 각 투자사에 **한국어/영어 소개**를 작성해 `app.parties.intro_ko / intro_en` 에 넣는다.
   - 소개는 "그 투자사가 mbg(해양 바이오소재 = 키틴/FCC 필러, Advanced Materials 원천기술, 종이/포장/화장품)와 왜 맞는지"를 중심으로.
3. **관련성이 높다고 판단되면 Priority 를 'high' 로** 수정 (기본은 이미 전부 'medium').

### 작업 순서 제안
1. Advanced Materials 투자사 목록 추출(아래 쿼리).
2. 각 투자사 웹 리서치 → intro_ko/intro_en 작성(검증된 사실만, 추측 금지).
3. intro UPDATE SQL(self-resolving) 실행 → 화면 Introduction 카드에 노출 확인.
4. 고관련 투자사는 priority='high' UPDATE.

---

## 1) 재사용 SQL 템플릿 (Supabase SQL Editor 전용, UTF-8 **BOM 없이** 저장)

### (a) Advanced Materials 투자사 찾기
```sql
-- 먼저 섹터 코드 확인 (label_en 'Advanced Materials' 의 code 파악)
select id, code, label_en from app.sectors order by sort_order;

-- 해당 섹터 포커스를 가진 투자사 + 현재 priority
select p.id, p.party_name, ip.priority,
       (p.intro_ko is not null or p.intro_en is not null) as has_intro
from app.parties p
join app.investor_profile ip          on ip.party_id = p.id
join app.investor_sector_focus isf    on isf.investor_profile_id = ip.id
join app.sectors s                     on s.id = isf.sector_id
where s.label_en = 'Advanced Materials'   -- 또는 위에서 확인한 code 사용
  and p.party_type_id = 1                 -- investor
  and p.deleted_at is null
order by p.party_name;
```

### (b) Introduction 채우기 (이름 self-resolving join — 컬럼명 하드코딩 금지)
```sql
update app.parties p
set intro_ko = d.ko, intro_en = d.en
from (values
  ('2048 Ventures', '한국어 소개 ...', 'English intro (ASCII only) ...'),
  ('Firm B',        '...',            '...')
) as d(nm, ko, en)
where coalesce(
  to_jsonb(p)->>'name', to_jsonb(p)->>'party_name', to_jsonb(p)->>'legal_name',
  to_jsonb(p)->>'display_name', to_jsonb(p)->>'company_name', to_jsonb(p)->>'entity_name'
) = d.nm;
```
- EN 텍스트는 ASCII만(작은따옴표는 SQL escape '' 로, 가능하면 회피). "into <소문자명사>" 같은 표현 회피(파서 오해 방지).
- 멱등: 같은 파일 재실행해도 안전(UPDATE).

### (c) 고관련 투자사 Priority = High  (**UPDATE 사용, upsert 금지**)
```sql
update app.investor_profile ip
set priority = 'high', updated_at = now()
from app.parties p
where p.id = ip.party_id
  and coalesce(to_jsonb(p)->>'party_name', to_jsonb(p)->>'name') in
      ('Firm A', 'Firm B');   -- 고관련으로 판단한 투자사들
```
- 이유: investor_profile 에 INSERT 하면 `investor_type_id`(과거 NOT NULL) 문제가 있었음. 지금은 nullable 로 풀었지만, **기존 행 수정은 UPDATE 가 정석**. (모든 355개 investor_profile 행은 이미 존재 + priority='medium'.)

### 검증
```sql
select priority, count(*) from app.investor_profile group by priority order by 2 desc;
select p.party_name, p.intro_ko is not null as ko, p.intro_en is not null as en
from app.parties p where p.party_type_id = 1 and (p.intro_ko is not null or p.intro_en is not null);
```

---

## 2) 핵심 스키마/규칙 (다음 세션이 알아야 할 것)

- **Repo**: MarineGift/mbg-project, branch `marinebiogroup` (PUBLIC), local `C:\dev\mbg-project`. Deploy: push → `urm.marinebiogroup.com` 자동배포. org_id `b25de8f2-1020-482f-9012-183f63883169`.
- **app.parties**: 표시명 컬럼은 `party_name`. 이번 작업 대상 컬럼 **`intro_ko` / `intro_en` (text)** 존재함.
- **party_types id**: investor=1, paper_mill=2, filler_supplier=3, buyer=4, customer=5, partner=6, government_grant=7, consultant=8, crowdfunding_platform=9, self=10.
- **app.investor_profile**: party_id 1:1(unique). **`priority` text** (CHECK: null|high|medium|low, DEFAULT 'medium'). 전 행 backfill 'medium' 완료(355행). `investor_type_id` 는 이번 세션에 **nullable 로 완화**(생성된 database.ts 타입에는 안 보이지만 실제 DB엔 존재).
- **섹터 포커스 체인**: parties → investor_profile(id) → investor_sector_focus(investor_profile_id, sector_id) → sectors(code, label_en). 'Advanced Materials' 는 sectors.label_en.
- **Korean SQL**: 반드시 Supabase SQL Editor(UTF-8)에서 실행. PowerShell/psql(CP949) 금지. SQL 파일은 **UTF-8 BOM 없이** 저장(BOM이 첫 구문 깨뜨림). .md 리포트는 UTF-8 **BOM 포함**.

### 파일 전달 규칙 (매번)
- 다운로드 파일명은 충돌 없게(같은 basename 금지) → 별칭으로.
- **ASCII-only PowerShell mover**: `$env:USERPROFILE\Downloads` → repo 경로. 대괄호/괄호 경로( `(app)`, `[partyType]`, `[id]` )는 .NET IO 사용( `[System.IO.File]::Move`, `[System.IO.Directory]::CreateDirectory`, `Test-Path/Remove-Item/Unblock-File -LiteralPath` ). New-Item/Move-Item 의 와일드카드 회피.
- Finish block: `git pull` → `npx tsc --noEmit`(0 errors) → `git status -sb` → `git add <files>` → `git commit` → `git push origin marinebiogroup`. push=자동배포 안내.
- 결과물은 `present_files` 로 전달.

---

## 3) UI 동작 (이미 구현됨 — 데이터만 넣으면 보임)

- **Introduction 카드**: party Overview 상단(통계 아래, Basic Information 위)에 **항상 노출**. intro_ko→intro_en 순, 큰 글자(text-base). 비면 "-"+안내. 파일: `src/components/parties/party-intro-card.tsx`. 쿼리/타입: `src/lib/queries/party-detail.ts`, `src/types/party-detail.ts` (introKo/introEn 매핑됨).
- **Investor Profile 카드**: 반응형 그리드(모바일 2단/데스크톱 3단). 첫 줄 = Priority · Sector Focus · Geographic Focus. Priority 는 인라인 토글(High/Medium/Low) → `updateInvestorPriority` 서버액션(**UPDATE 우선, 없으면 INSERT**). 파일: `src/components/parties/investor-profile-card.tsx`, `src/components/parties/investor-priority-editor.tsx`, 액션 `src/lib/actions/parties.ts`.
- **투자사 리스트**(`/investor/parties`): Priority 컬럼 + 정렬(High먼저/Low먼저) + 필터(All/High/Medium/Low). 파일: `src/app/(app)/[partyType]/parties/page.tsx`, `src/components/parties/parties-filter-bar.tsx`. → intro/priority 채우면 즉시 반영.

---

## 4) 이번 세션에 한 일 (요약)

- **partner 분류 + 소개 카드**: 가속기/프로그램 6곳(Plug and Play, Greentown Labs, MassChallenge, Cleantech Open, TEX-E, Circular Austin Showcase)을 partner(6)로 생성, Capital Factory→partner 재분류. Introduction 카드 신설(`f6142c1`).
- **Investor Priority 필드**: investor_profile.priority 추가 + 인라인 편집 + 리스트 컬럼/정렬/필터. 라벨 High/Medium/Low 로 단순화(Tier A/B/C 표기 제거; 규모용 Tier 는 별도 account-score 시스템).
- **버그 수정들**:
  - AI Draft 404 → `src/lib/actions/email-compose.ts` 의 모델 `claude-sonnet-4-20250514` → `process.env.ANTHROPIC_MODEL_SONNET ?? 'claude-sonnet-4-6'`.
  - "MarineBio Group(self) Party not found" → 4개 라우트 가드 `PHASE_1_MODULES` 에 `'self'` 추가.
  - Priority 저장 시 `investor_type_id NOT NULL` 위반 → 액션을 upsert→UPDATE(없으면 INSERT)로, SQL로 investor_type_id nullable + priority 기본 'medium' + 전 행 backfill.
- **레이아웃**: 대시보드에 Mailing 카드(Inbox 아래, `/mailing` 링크). Basic Information / Investor Profile 둘 다 반응형 그리드(가로 스크롤 제거). Introduction 항상 노출.
- 마지막 변경(미배포 가능성): Geographic Focus 재노출(`move_investor_card_geo.ps1`) — 아직 commit 안 했으면 아래 커밋 필요.

### 미정리(확인 요망)
- `docs/HANDOFF-bulk-mailing-2026-06-15.md` 가 여러 커밋에서 untracked 로 남아 있음 → 추적할 문서면 `git add` 후 커밋, 아니면 .gitignore.
- Geographic Focus 재노출 커밋:
```powershell
git add src/components/parties/investor-profile-card.tsx
git commit -m "feat(investor): show Geographic Focus beside Sector Focus on Investor Profile card"
git push origin marinebiogroup
```

---

## 5) 다음 세션 시작 프롬프트(붙여넣기용)

> "mbg-project 이어서 진행. 이 Handoff(docs/HANDOFF-investor-intro-2026-06-15.md) 기준으로,
> Advanced Materials 섹터 투자사부터 Introduction(intro_ko/intro_en)을 채우고, 관련성 높은 곳은 Priority='high'로 올려줘.
> 먼저 Advanced Materials 투자사 목록 추출 쿼리부터."
