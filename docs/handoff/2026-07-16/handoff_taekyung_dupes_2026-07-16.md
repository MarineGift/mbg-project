# Handoff — Taekyung 중복 2건 정리 + 이름 기반 중복 스캔 (2026-07-16, 6차)

## 0. 스캔이 바로 제 사고를 잡았습니다

블록 6 결과에서:

```
KR, www.taekyungbk.co.kr, 2
  Taekyung BK Co. (태경비케이, ex-Baekkwang Materials)  ← 원래 있던 행
  Taekyung BK Co., Ltd.                                ← 제가 넣은 행
```

**또 중복입니다.** 그리고 확인해보니 하나가 아니라 **둘**입니다.

## 1. 제가 세 번 틀렸습니다 — 같은 방식으로

`seed_filler_suppliers_kr_2026-07-16.sql`을 만들 때 저는 **`,'KR'` 리터럴 패턴만 grep**했습니다. `.co.kr` 도메인은 안 봤습니다. 그런데 `20260620060000_app_parties_website_backfill_batch1.sql` 21~22행에 이렇게 있었습니다:

```sql
('3d121300-0eab-49b9-baf3-89f592baca78', 'http://www.taekyungbk.co.kr'),  -- Taekyung BK (ex-Baekkwang Materials)
('313a4d86-0055-49a1-aca0-6a760ee0b7e2', 'http://www.taekyungind.co.kr')  -- Taekyung Industrial
```

**리포 안에 있었습니다.** 제가 안 본 겁니다.

| 제가 넣은 행 | 실제 상태 |
|---|---|
| Omya Korea Inc. | ❌ 중복 — `Omya (Korea)` 이미 존재 (1차에 인정) |
| **Taekyung BK Co., Ltd.** | ❌ **중복** — `3d121300` 이미 존재 |
| **Taekyung Industry Co., Ltd.** | ❌ **중복 의심** — `313a4d86` 이미 존재 |
| GMC Co., Ltd. (Korea) | ⭕ 아마 진짜 신규 (website NULL이라 확인 불가) |

즉 **"KR filler = 0건"은 세 겹으로 틀렸고**, 2차 핸드오프에서 제가 "나머지 3개는 진짜 신규"라고 한 것도 틀렸습니다. 실제로 새로 추가된 값은 **GMC 하나**뿐일 수 있습니다.

### 그리고 이것도 — 제 "발견"이 아니었습니다

`20260620210000_paper_mill_website_intro_batch15.sql:57`, 한솔제지 장항공장 intro:

> 인쇄·특수지를 생산하며 **현장 PCC(태경비케이) 공급 관계**가 있는 핵심 생산거점

**한 달 전부터 제지사 쪽에 기록돼 있었습니다.** 제가 "태경비케이가 satellite 모델을 이미 돌리고 있다 — 한국 FCC 1순위"라고 발견한 것처럼 보고했는데, DB가 이미 알고 있던 사실입니다.

## 2. 왜 도메인 스캔이 하나만 잡았나

- **Taekyung BK** — 양쪽 다 `www.taekyungbk.co.kr` → **그룹핑됨, 잡힘 ✅**
- **Taekyung Industrial** — 저장된 값 `taekyungind.co.kr`, 제 값 `taekyung.co.kr` → **호스트가 다름, 안 잡힘 ❌**
- **GMC** — website가 NULL → **스캔 대상에서 아예 제외 ❌**

**호스트 그룹핑은 필요조건이지 충분조건이 아닙니다.** 제가 지난 핸드오프에서 "이걸 규칙으로 하자"고 했는데, 그것만으로는 부족합니다.

---

## 3. `fix_taekyung_dupes_2026-07-16.sql` → `sql\`

두 중복을 병합합니다. 각각:

1. 제 행의 연구 결과(intro, 국가/지역/도시)를 **keeper로 이관** (coalesce — keeper 값 절대 안 덮음)
2. keeper에 profile이 없으면 **생성**, 있으면 **notes append만**
3. 제 행 + profile **삭제** (contacts/deals/communications/deal_parties/party_supply_links 없을 때만)

**Taekyung Industrial 병합은 self-guarding입니다.** `313a4d86`이 filler(type 3)가 아닌 것으로 밝혀지면 관련 문 전부 no-op입니다. 그래도 파일 맨 위의 **pre-flight 쿼리를 먼저** 돌려주세요:

```sql
select id, party_name, party_type_id, country_code, city, website, source,
       (intro_ko is not null) as has_ko
from app.parties
where party_type_id = 3 and deleted_at is null and party_name ilike '%taekyung%'
order by party_name;
```

**실행 전 4행 → 실행 후 2행.** `313a4d86`이 type 3이 아니면 블록 3 돌리기 전에 알려주세요.

### 블록 4 — 유일하게 건설적인 부분

batch15는 한솔 장항 ↔ 태경비케이 온사이트 PCC 관계를 **intro 안의 산문으로만** 갖고 있었습니다. **행이 아니었습니다.** 이제 양쪽 uuid를 다 알기 때문에 실제 엣지로 만들 수 있습니다:

```
mill   890ae7ee-12ae-4889-be24-c1f2155dbad0  한솔제지 장항공장
filler 3d121300-0eab-49b9-baf3-89f592baca78  태경비케이
```

`app.party_supply_links`에 넣습니다. 파일 **맨 마지막 문**으로 뒀습니다 — 그 테이블에 제가 모르는 NOT NULL 컬럼이 있으면 에러가 나겠지만, 그 위 문들은 이미 커밋된 뒤라 안전합니다.

## 4. `scan_filler_name_dupes_2026-07-16.sql` → `sql\`

도메인 스캔이 못 잡는 나머지를 덮습니다. **READ-ONLY.**

| 블록 | 내용 |
|---|---|
| 1 | **정규화 이름 충돌** — 괄호·법인격 접미사·기호 제거 후 그룹핑. `Taekyung BK Co. (태경비케이...)` → `taekyungbk`, `Taekyung BK Co., Ltd.` → `taekyungbk` **일치**. 도메인 스캔이 놓친 걸 잡는 그물 |
| 2 | **거친 prefix 클러스터** — 정규화 이름 앞 8글자 + 국가. `taekyungindustrial` vs `taekyungindustry`는 1번으로 안 잡히지만 prefix `taekyung`을 공유. 오탐 나옵니다 — 자동 판정이 아니라 **사람이 볼 짧은 리스트**가 목적 |
| 3 | **website NULL 행** — 도메인 스캔에 안 보이는 사각지대. GMC가 여기 |
| 4 | KR seed에서 살아남은 행 — 두 fix 실행 후 **GMC 1행**만 남아야 정상 |
| 5 | **FULL KR PICTURE** — 첫날 돌렸어야 할 감사 |

---

## 5. 이동 · 실행 · 마무리

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$moves = @(
  @{ Pattern = 'fix_taekyung_dupes_2026-07-16*.sql';       Dest = (Join-Path $repo 'sql'); Name = 'fix_taekyung_dupes_2026-07-16.sql' },
  @{ Pattern = 'scan_filler_name_dupes_2026-07-16*.sql';   Dest = (Join-Path $repo 'sql'); Name = 'scan_filler_name_dupes_2026-07-16.sql' },
  @{ Pattern = 'handoff_taekyung_dupes_2026-07-16*.md';    Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_taekyung_dupes_2026-07-16.md' }
)

foreach ($m in $moves) {
  $src = Get-ChildItem -Path $dl -Filter $m.Pattern -File -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $src) { Write-Host ("SKIP  no match: " + $m.Pattern); continue }
  Unblock-File -Path $src.FullName
  [System.IO.Directory]::CreateDirectory($m.Dest) | Out-Null
  $target = [System.IO.Path]::Combine($m.Dest, $m.Name)
  [System.IO.File]::Copy($src.FullName, $target, $true)
  Remove-Item -LiteralPath $src.FullName -Force
  Write-Host ("OK    " + $src.Name + "  ->  " + $target)
}
Write-Host "DONE"
```

**실행 순서**

1. `fix_taekyung_dupes` **pre-flight 쿼리** → 4행 확인
2. `fix_taekyung_dupes` 블록 1~3 실행 → verify로 2행 확인
3. 블록 4 (party_supply_links) 실행 — 에러 나면 그 테이블 스키마를 알려주세요
4. `scan_filler_name_dupes` 블록 1·2·3 실행 → **결과 CSV 보내주세요.** 다른 나라에도 같은 사고가 있는지 봐야 합니다
5. 블록 4 → GMC 1행만 남는지 확인

**마무리**

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/fix_taekyung_dupes_2026-07-16.sql sql/scan_filler_name_dupes_2026-07-16.sql docs/handoff/2026-07-16/handoff_taekyung_dupes_2026-07-16.md
git commit -m "fix: merge 2 Taekyung dupes from the KR seed (both pre-existed in batch1) + link Hansol Janghang <-> Taekyung BK supply edge; scan: name-based dupe nets"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 6. 규칙 하나 — 이제 확실합니다

제 오류 3건이 전부 같은 원인입니다:

> **리포를 좁은 grep으로 감사하고, "리포에 없다"를 "DB에 없다"로 취급했다.**

1차에서 이걸 인정하고 "다시는 안 그러겠다"고 했는데, KR seed는 이미 나간 뒤였고 저는 **같은 방식으로 두 번 더 틀렸습니다.** `.co.kr`를 안 본 건 변명이 안 됩니다 — 애초에 grep으로 감사하겠다는 접근 자체가 틀렸습니다.

**앞으로의 규칙, 예외 없이:**

> **filler_supplier에 INSERT하는 파일은, 해당 국가/도메인의 실제 DB 조회 결과를 받기 전에는 만들지 않습니다.**

리포 기반 추론으로는 INSERT 파일을 안 만들겠습니다. UPDATE(uuid 타깃)는 안전하니 그건 계속합니다 — JP·MY 파일이 그래서 사고가 없었습니다.

## 7. 살아남은 것들

명확히 하기 위해 — 이번 세션에서 **실제로 유효한 성과**:

| 결과 | 상태 |
|---|---|
| MLC PCC 철수 + 도메인 이전 + 담당자 13명 | ✅ 유효 |
| Zantat 상장(Bursa ACE 0301) + 능력 32만 MT + Calrock 자매회사 | ✅ 유효 |
| 奥多摩 제지용 PCC 9할 초과 + 니가타PCC satellite 신호 | ✅ 유효 |
| 白石 역할 뒤바뀜 + 제지 적합성 과대평가 | ✅ 유효 |
| 備北 GCC 전업 (PCC 없음) | ✅ 유효 |
| Omya Korea 5개 공장 검증 | ✅ 유효 |
| GMC 추가 | ⚠️ 아마 유효 (website NULL — 스캔 3번으로 확인 필요) |
| 태경비케이 satellite "발견" | ❌ 이미 batch15에 있었음 |
| KR filler 신규 3사 | ❌ 실제로는 1사 |

## 8. 아직 안 받은 것

- **블록 2 (Tier 1 워크리스트)** — 이번에 주신 CSV는 블록 6이었습니다. paper-grade 재검증 스윕의 본체는 아직 시작 못 했습니다
- **일본 `has_ko` 5행 확인** — MLC와 같은 null 가드 버그 여부
