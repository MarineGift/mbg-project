# Git Commit 안내 — A3 cleanup + A2 dedup 인프라 (PowerShell)

> **환경:** Windows PowerShell (5.1 또는 7.x)
> Bash 사용 시: 이 가이드의 PowerShell 명령을 표준 bash 로 변환하면 됨.

---

## 권장 파일 배치

`mbg-project` repo 기준 (Next.js 14 + Supabase 표준 구조):

```
mbg-project\
├── docs\
│   ├── starter-kit\                           ← 권장 신규 폴더
│   │   ├── README_STARTER_KIT.md              ← v5 (갱신)
│   │   ├── NEXT_SESSION_KICKOFF.md            ← v6 (갱신)
│   │   ├── URM_MASTER_ARCHITECTURE.md         ← v4 (갱신)
│   │   ├── DB_SCHEMA_REFERENCE.md             ← v2.4 (갱신)
│   │   └── SCHEMA_GOTCHAS.md                  ← v3.3 (갱신)
│   └── handoffs\                              ← 권장 신규 폴더
│       └── SESSION_HANDOFF_2026-05-19.md      ← 신규
│
└── supabase\
    └── migrations\
        └── YYYYMMDDHHMMSS_a2_dedup.sql        ← migration_A2_dedup_2026Q2.sql
                                                  (Supabase CLI timestamp prefix 권고)
```

**Migration 파일 이름:** Supabase CLI 가 timestamp 기반 정렬을 사용하므로 `YYYYMMDDHHMMSS` prefix 권고.

(Supabase 사용 안 하면 그냥 `db\migrations\2026Q2_05_a2_dedup.sql` 같은 식)

---

## PowerShell 복사 명령

이 sandbox 의 outputs 폴더에서 본인 repo 로:

```powershell
# repo 가 C:\Users\<you>\projects\mbg-project 에 있다고 가정
# (또는 $env:USERPROFILE\projects\mbg-project)
$Repo     = "$env:USERPROFILE\projects\mbg-project"
$Download = "$env:USERPROFILE\Downloads"   # claude 에서 받은 파일들 위치

Set-Location $Repo

# 1. 폴더 생성 (-Force 가 깊은 경로도 한 번에 만듦)
New-Item -ItemType Directory -Force -Path "docs\starter-kit"      | Out-Null
New-Item -ItemType Directory -Force -Path "docs\handoffs"         | Out-Null
New-Item -ItemType Directory -Force -Path "supabase\migrations"   | Out-Null

# 2. Starter kit 5 파일 + 1 handoff 복사
Copy-Item "$Download\README_STARTER_KIT.md"         "docs\starter-kit\"
Copy-Item "$Download\NEXT_SESSION_KICKOFF.md"       "docs\starter-kit\"
Copy-Item "$Download\URM_MASTER_ARCHITECTURE.md"    "docs\starter-kit\"
Copy-Item "$Download\DB_SCHEMA_REFERENCE.md"        "docs\starter-kit\"
Copy-Item "$Download\SCHEMA_GOTCHAS.md"             "docs\starter-kit\"
Copy-Item "$Download\SESSION_HANDOFF_2026-05-19.md" "docs\handoffs\"

# 3. Migration 파일 — Supabase timestamp prefix 권고
$Ts = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
Copy-Item "$Download\migration_A2_dedup_2026Q2.sql" `
          "supabase\migrations\${Ts}_a2_dedup_activity_status.sql"

# 4. 결과 확인
Get-ChildItem -Recurse -Path "docs", "supabase\migrations"
```

---

## Commit 전략 (옵션 2가지)

### 옵션 A — Single Commit (단순)

PowerShell 에서 multi-line commit message 는 **here-string** (`@"..."@`) 사용:

```powershell
git add docs\starter-kit\ docs\handoffs\ supabase\migrations\

git commit -m @"
feat(db): A2 dedup 인프라 + A3 filler cleanup

A3 cleanup (filler module):
- Cat 2 descriptor bucket 19 행 soft-delete (Local/regional, Domestic lime 등)
- Cat 3 한국 본사 firm 6 행 soft-delete (Hanil/Sungshin/Tongyang)
- 외국 본사 KR variant 3 행 복구 (Imerys/Omya/Specialty Minerals Korea)
- filler_supplier_profile orphan 25 행 hard-delete (260 → 235)

A2 dedup infrastructure (Phase 4):
- app.activity_status enum (5 values)
- parties.activity_status + phone_e164 + phone_normalized columns
- GIN trgm + B-tree partial indexes
- app.normalize_phone() (IMMUTABLE)
- app.find_similar_parties() + app.find_similar_persons()
- app.v_party_dedup_candidates view (recursive root, 3-stage exclusion)
- app.v_person_dedup_candidates wrapper view

Acceptance tests passed:
- Cat 4 near-dup auto-detection (EGM 1.00, Q-min 0.88, Mikron-S 0.79)
- Same-root-ancestor exclusion (Specialty Minerals 363 → 0)

Findings:
- investor/individual 3 dedup pair (Brian Smith × 2, Lior Susan × 2, Heather-Mack)
- Imerys 38-row mass-duplicate (703 pair) - next cleanup target

Starter kit updates:
- README v4 → v5
- KICKOFF v5 → v6
- URM_MASTER v3 → v4 (added 7th building block: Dedup infra)
- DB_SCHEMA_REFERENCE v2.3 → v2.4
- SCHEMA_GOTCHAS v3.2 → v3.3 (added 13)

Decisions:
- PROJECT_CONTEXT 2 narrow interpretation: only Korean-HQ firms blocked,
  foreign HQ's KR subsidiaries preserved (Omya/Specialty/Imerys Korea)
- Dedup view threshold 0.5 hard floor, caller adds filter for higher confidence
- Auto-merge prohibited - results are review candidates only

Next: Cat 1 cleanup (Imerys/Schaefer Kalk/Carmeuse HQ creation + linking, 45-60min)
"@
```

> **Note: PowerShell here-string 함정** — `@"` 다음과 `"@` 직전에 줄바꿈이 정확히 와야 함. `"@` 뒤에 공백/탭 있으면 syntax error. 복사할 때 trailing whitespace 주의.
>
> 또한 commit message 안의 `§` 같은 특수문자가 PowerShell 에서 자주 문제됨 → 위 메시지에서 `§2` → `2`, `§13` → `13` 으로 변경. 한글 / 화살표 (→) 는 UTF-8 이라 OK.

### 옵션 B — Two Commits (논리 분리)

```powershell
# Commit 1: Migration (DB schema 변경)
git add supabase\migrations\${Ts}_a2_dedup_activity_status.sql
git commit -m @"
feat(db): Phase 4 [A2] dedup infrastructure

- app.activity_status enum + parties phone/activity columns
- Trigram indexes (GIN partial WHERE deleted IS NULL)
- normalize_phone() + find_similar_parties() + find_similar_persons()
- v_party_dedup_candidates (recursive root) + v_person_dedup_candidates
- Acceptance: EGM/Q-min/Mikron-S auto-detection passed
- Same-root exclusion: Specialty Minerals 363 to 0
"@

# Commit 2: Starter kit docs
git add docs\
git commit -m @"
docs: starter kit v5 + SESSION_HANDOFF 2026-05-19

- README v4 → v5 (Phase 4 marked done, dedup quick reference)
- KICKOFF v5 → v6 (next session = Cat 1 cleanup)
- URM_MASTER v3 → v4 (7th building block: Dedup infra)
- DB_SCHEMA_REFERENCE v2.3 → v2.4 (A2 functions/views added)
- SCHEMA_GOTCHAS v3.2 → v3.3 (13 added)
- SESSION_HANDOFF 2026-05-19: A3 + A2 summary
"@
```

### 옵션 C — Commit message 를 파일로 사용 (가장 안전)

특수문자 / multiline 문제 회피. handoff 파일 자체를 commit message 로:

```powershell
git add docs\ supabase\migrations\
git commit -F docs\handoffs\SESSION_HANDOFF_2026-05-19.md
```

→ 이 경우 commit message 가 ~200 라인 길이가 됨. log 가 두꺼워지지만 가장 안전하고 정보 풍부함. 1인 repo 에 권장.

---

## Branch 전략 (옵션)

대규모 schema 변경이라 별도 branch 권고:

```powershell
git checkout -b feature/phase-4-a2-dedup-infra
# ... commits (위 옵션 A/B/C 중 하나) ...
git push -u origin feature/phase-4-a2-dedup-infra
# PR 생성 시 SESSION_HANDOFF_2026-05-19.md 내용을 description 으로 활용
```

또는 main 에 직접 push (1인 개발 환경):

```powershell
git checkout main
# ... commits ...
git push
```

---

## Production DB Snapshot (재현성)

이번 세션의 변경은 **production DB 에 이미 직접 적용됨** (Supabase SQL Editor 통해). git commit 은 **historical record + reproducibility** 목적.

새 환경 (staging / 개발자 local) 에서 재현하려면:
1. base schema dump → 새 환경
2. 이번 migration `YYYYMMDDHHMMSS_a2_dedup_activity_status.sql` 적용
3. KICKOFF 2 검증 SQL 실행

migration 은 idempotent (CREATE OR REPLACE / IF NOT EXISTS) 라 production 에 재실행해도 안전 — 단, 데이터 변경 (A3 cleanup 25 행 soft-delete + KR variant 3 복구 + profile orphan 25 hard-delete) 은 idempotent 아님. 재현하려면 별도 data migration script 필요.

### Snapshot 권고

다음 세션 시작 전 production DB 의 dump 를 보관:

```powershell
# Supabase CLI 사용 시 (npm/scoop 으로 설치된 경우)
New-Item -ItemType Directory -Force -Path "db\snapshots" | Out-Null

supabase db dump --data-only   > db\snapshots\2026-05-19-post-a2-data.sql
supabase db dump --schema-only > db\snapshots\2026-05-19-post-a2-schema.sql

# PowerShell native 압축 (Compress-Archive — .zip 출력)
Compress-Archive -Path "db\snapshots\2026-05-19-post-a2-*.sql" `
                 -DestinationPath "db\snapshots\2026-05-19-post-a2.zip" `
                 -Force

# 압축 후 원본 sql 삭제 (옵션)
Remove-Item "db\snapshots\2026-05-19-post-a2-data.sql", `
            "db\snapshots\2026-05-19-post-a2-schema.sql"

git add db\snapshots\
git commit -m "chore(db): snapshot after A3 cleanup + A2 dedup"
```

> **Note: gzip vs zip** — Linux/macOS 표준은 `.sql.gz` 인데 PowerShell native 압축은 `.zip`. 만약 cross-platform `.sql.gz` 가 필요하면 7zip 설치 후:
> ```powershell
> # 7zip 설치: scoop install 7zip   또는   choco install 7zip
> 7z a -tgzip "db\snapshots\2026-05-19-post-a2-data.sql.gz" "db\snapshots\2026-05-19-post-a2-data.sql"
> ```

---

## 다음 세션 시작 시

```powershell
Set-Location "$env:USERPROFILE\projects\mbg-project"
git pull

# 5 starter kit 읽기 (concat 으로 한 번에 보거나 개별)
Get-Content docs\starter-kit\README_STARTER_KIT.md       # v5
Get-Content docs\starter-kit\NEXT_SESSION_KICKOFF.md     # v6 (직전 상태)
Get-Content docs\handoffs\SESSION_HANDOFF_2026-05-19.md  # 이 세션 자체 요약
```

새 Claude 세션 시작 시 위 5 starter kit + 1 handoff 첨부.

### 한 번에 여러 파일 보기 (옵션)

```powershell
# Starter kit 5 파일 + handoff 1 = 6 파일을 less 같이 페이지 단위로
Get-Content docs\starter-kit\*.md, docs\handoffs\SESSION_HANDOFF_2026-05-19.md | more

# VS Code 로 모두 열기
code docs\starter-kit\ docs\handoffs\SESSION_HANDOFF_2026-05-19.md
```

---

## PowerShell 함정 회피 메모

1. **`@"` here-string** — opening / closing delimiter 단독 라인에 있어야. trailing whitespace 금지.
2. **Backslash 경로** — `"docs\starter-kit"` 안전. forward slash `/` 도 대부분 작동하지만 mixed 보다는 일관성.
3. **변수 expansion 안 되는 single-quote string** — `'$Repo'` 는 literal. `"$Repo"` 가 expansion.
4. **`Out-Null` 로 noise 제거** — `New-Item` 의 출력이 console 에 뜨는 것 방지.
5. **Execution policy** — git / npm 등 일반 도구는 영향 없지만, `.ps1` script 실행 시 `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` 한 번 필요할 수 있음.
6. **UTF-8 인코딩** — 한글 commit message 깨지면 `git config --global i18n.commitEncoding utf-8` + `git config --global i18n.logOutputEncoding utf-8` + PowerShell 자체 인코딩 `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`.
