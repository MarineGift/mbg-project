# Git Commit 안내 — A3 cleanup + A2 dedup 인프라

## 권장 파일 배치

`mbg-project` repo 기준 (Next.js 14 + Supabase 표준 구조):

```
mbg-project/
├── docs/
│   ├── starter-kit/                           ← 권장 신규 폴더
│   │   ├── README_STARTER_KIT.md              ← v5 (갱신)
│   │   ├── NEXT_SESSION_KICKOFF.md            ← v6 (갱신)
│   │   ├── URM_MASTER_ARCHITECTURE.md         ← v4 (갱신)
│   │   ├── DB_SCHEMA_REFERENCE.md             ← v2.4 (갱신)
│   │   └── SCHEMA_GOTCHAS.md                  ← v3.3 (갱신)
│   └── handoffs/                              ← 권장 신규 폴더
│       └── SESSION_HANDOFF_2026-05-19.md      ← 신규
│
└── supabase/
    └── migrations/
        └── 20260519XXXXXX_a2_dedup.sql        ← migration_A2_dedup_2026Q2.sql 의 내용
                                                  (Supabase CLI timestamp 형식으로 rename 권고)
```

**Migration 파일 이름:** Supabase CLI 가 timestamp 기반 정렬을 사용하므로 `YYYYMMDDHHMMSS` prefix 권고. 예시:
- `20260519010000_a2_dedup_activity_status.sql`

(Supabase 사용 안 하면 그냥 `db/migrations/2026Q2_05_a2_dedup.sql` 같은 식)

---

## 복사 명령 (참고)

이 sandbox 의 outputs 폴더에서 본인 repo 로:

```bash
# repo 가 ~/projects/mbg-project 에 있다고 가정
cd ~/projects/mbg-project

mkdir -p docs/starter-kit docs/handoffs supabase/migrations

# 6개 starter kit 파일 + 1 handoff
cp /path/to/downloads/README_STARTER_KIT.md         docs/starter-kit/
cp /path/to/downloads/NEXT_SESSION_KICKOFF.md       docs/starter-kit/
cp /path/to/downloads/URM_MASTER_ARCHITECTURE.md    docs/starter-kit/
cp /path/to/downloads/DB_SCHEMA_REFERENCE.md        docs/starter-kit/
cp /path/to/downloads/SCHEMA_GOTCHAS.md             docs/starter-kit/
cp /path/to/downloads/SESSION_HANDOFF_2026-05-19.md docs/handoffs/

# Migration 파일 — Supabase timestamp prefix 권고
TS=$(date -u +"%Y%m%d%H%M%S")
cp /path/to/downloads/migration_A2_dedup_2026Q2.sql \
   supabase/migrations/${TS}_a2_dedup_activity_status.sql
```

---

## Commit 전략 (옵션 2가지)

### 옵션 A — Single Commit (단순)

```bash
git add docs/starter-kit/ docs/handoffs/ supabase/migrations/

git commit -m "feat(db): A2 dedup 인프라 + A3 filler cleanup

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
- SCHEMA_GOTCHAS v3.2 → v3.3 (added §13)

Decisions:
- PROJECT_CONTEXT §2 narrow interpretation: only Korean-HQ firms blocked,
  foreign HQ's KR subsidiaries preserved (Omya/Specialty/Imerys Korea)
- Dedup view threshold 0.5 hard floor, caller adds filter for higher confidence
- Auto-merge prohibited - results are review candidates only

Next: Cat 1 cleanup (Imerys/Schaefer Kalk/Carmeuse HQ creation + linking, 45-60min)
"
```

### 옵션 B — Two Commits (논리 분리)

```bash
# Commit 1: A3 cleanup + migration
git add supabase/migrations/${TS}_a2_dedup_activity_status.sql
git commit -m "feat(db): Phase 4 [A2] dedup infrastructure

- app.activity_status enum + parties phone/activity columns
- Trigram indexes (GIN partial WHERE deleted IS NULL)
- normalize_phone() + find_similar_parties() + find_similar_persons()
- v_party_dedup_candidates (recursive root) + v_person_dedup_candidates
- Acceptance: EGM/Q-min/Mikron-S auto-detection passed
- Same-root exclusion: Specialty Minerals 363 → 0
"

# Commit 2: Starter kit docs
git add docs/
git commit -m "docs: starter kit v5 + SESSION_HANDOFF 2026-05-19

- README v4 → v5 (Phase 4 marked done, dedup quick reference)
- KICKOFF v5 → v6 (next session = Cat 1 cleanup)
- URM_MASTER v3 → v4 (7th building block: Dedup infra)
- DB_SCHEMA_REFERENCE v2.3 → v2.4 (A2 functions/views added)
- SCHEMA_GOTCHAS v3.2 → v3.3 (§13 added)
- SESSION_HANDOFF 2026-05-19: A3 + A2 summary
"
```

---

## Branch 전략 (옵션)

대규모 schema 변경이라 별도 branch 권고:

```bash
git checkout -b feature/phase-4-a2-dedup-infra
# ... commits ...
git push -u origin feature/phase-4-a2-dedup-infra
# PR 생성 시 SESSION_HANDOFF_2026-05-19.md 내용을 description 으로 활용
```

또는 main 에 직접 push (1인 개발 환경):
```bash
git checkout main
# ... commits ...
git push
```

---

## Production DB 와의 일관성

이번 세션의 변경은 **production DB 에 이미 직접 적용됨** (Supabase SQL Editor 통해). git commit 은 **historical record + reproducibility** 목적.

새 환경 (staging / 개발자 local) 에서 재현하려면:
1. base schema dump → 새 환경
2. 이번 migration `20260519XXXXXX_a2_dedup_activity_status.sql` 적용
3. KICKOFF §2 검증 SQL 실행

migration 은 idempotent (CREATE OR REPLACE / IF NOT EXISTS) 라 production 에 재실행해도 안전 — 단, 데이터 변경 (A3 cleanup 25 행 soft-delete + KR variant 3 복구 + profile orphan 25 hard-delete) 은 idempotent 아님. 재현하려면 별도 data migration script 필요.

→ **권고:** 다음 세션 시작 전 production DB 의 dump 를 `db/snapshots/2026-05-19-post-a2.sql.gz` 같은 곳에 보관. Schema + data 모두 포함.

```bash
# 예시 (Supabase CLI 사용 시)
supabase db dump --data-only > db/snapshots/2026-05-19-post-a2-data.sql
supabase db dump --schema-only > db/snapshots/2026-05-19-post-a2-schema.sql
gzip db/snapshots/2026-05-19-post-a2-*.sql
git add db/snapshots/
git commit -m "chore(db): snapshot after A3 cleanup + A2 dedup"
```

---

## 다음 세션 시작 시

```bash
cd ~/projects/mbg-project
git pull
cat docs/starter-kit/README_STARTER_KIT.md      # v5
cat docs/starter-kit/NEXT_SESSION_KICKOFF.md     # v6 (직전 상태)
cat docs/handoffs/SESSION_HANDOFF_2026-05-19.md  # 이 세션 자체 요약
```

새 Claude 세션 시작 시 위 5 starter kit + 1 handoff 첨부.
