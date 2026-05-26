# URM Platform — 새 채팅 인수인계 문서

## 프로젝트 기본 정보

| 항목 | 값 |
|------|-----|
| **프로젝트 경로** | `C:\dev\mbg-project` |
| **Stack** | Next.js 14 + Supabase + TypeScript |
| **Org ID** | `b25de8f2-1020-482f-9012-183f63883169` |
| **Supabase Schema** | `app` |
| **실행** | `cd C:\dev\mbg-project` → `npm run dev` |
| **환경** | PowerShell (Windows), UTF-8 BOM 파일 |

---

## 현재 즉시 해결해야 할 오류

### 오류 메시지
```
Error: Unsupported Server Component type: undefined
```

### 원인
`parties/page.tsx` 또는 `parties/[id]/page.tsx`에서 import한 컴포넌트 중 하나가 `undefined`로 렌더링됨.

### 진단 스크립트 (즉시 실행)
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; & "$env:USERPROFILE\Downloads\Diag-Components.ps1" -ProjectRoot "C:\dev\mbg-project" | Tee-Object "$env:USERPROFILE\Downloads\diag.txt"
```
→ `diag.txt` 내용을 새 채팅에 붙여넣으면 원인 즉시 파악 가능.

**Diag-Components.ps1** 내용 (다운로드 안 됐을 경우 수동 작성):
```powershell
param([string]$ProjectRoot = "C:\dev\mbg-project")
$enc = New-Object System.Text.UTF8Encoding $false
$src = Join-Path $ProjectRoot "src"

Write-Host "=== parties/page.tsx imports ===" -ForegroundColor Cyan
$pp = [System.IO.File]::ReadAllText("$ProjectRoot\src\app\(app)\[module]\parties\page.tsx", $enc)
($pp -split "`n") | Where-Object { $_ -like "import*" -or $_ -like "*dynamic*" } | ForEach-Object { Write-Host "  $_" }

Write-Host "`n=== parties/[id]/page.tsx imports ===" -ForegroundColor Cyan
$dp = [System.IO.File]::ReadAllText("$ProjectRoot\src\app\(app)\[module]\parties\[id]\page.tsx", $enc)
($dp -split "`n") | Where-Object { $_ -like "import*" } | ForEach-Object { Write-Host "  $_" }

Write-Host "`n=== Check component exports ===" -ForegroundColor Cyan
$comps = @(
  "src\components\parties\country-filter-bar.tsx",
  "src\components\parties\party-supply-links-panel.tsx",
  "src\components\parties\country-peers-panel.tsx",
  "src\components\parties\country-peers-panel-client.tsx"
)
foreach ($c in $comps) {
  $fp = Join-Path $ProjectRoot $c
  if (Test-Path $fp) {
    $txt = [System.IO.File]::ReadAllText($fp, $enc)
    $exports = ($txt -split "`n") | Where-Object { $_ -like "export function*" -or $_ -like "export default*" -or $_ -like "export const*" }
    Write-Host "  $c" -ForegroundColor Yellow
    $exports | ForEach-Object { Write-Host "    $_" }
  } else {
    Write-Host "  $c - FILE MISSING" -ForegroundColor Red
  }
}
```

---

## 이번 세션에서 완료된 작업

### 1. Specialty Minerals (MTI) DB 완성
- **95개 항목**: HQ(1) + Country Entity(45) + Plant(49)
- **SQL 실행 완료**: `SMI-Complete-Update.sql`, `SMI-Cleanup-Final.sql`
- 17개국 56-plant footprint 완전 입력
- **한국(KR) = plant 없음** → HFCC 영업 최우선 타겟

### 2. party_supply_links 테이블
- **117개 공급 연결** 입력 완료
- Omya (Korea→Hansol/Moorim/Hankuk 등 5개)
- Specialty Minerals India(8개), China(8개) 전부 active
- `[미등록] Filler Supplier` placeholder 생성 완료

### 3. 데이터 정규화
- **트리거 생성**: `trg_check_supply_link` — 미등록 party 연결 차단
- **원칙**: 미등록 공급사 → placeholder 임시 연결 → 등록 후 업데이트

### 4. UI 추가 (이번 세션)
- **CountryFilterBar**: 국가 드롭다운 필터 (`parties/page.tsx`)
- **PartySupplyLinksPanel**: Filler↔Paper Mill 연결 패널 (detail page)
- **[미등록 연결]** 버튼: 모달에서 미등록 공급사 임시 연결

---

## 수정된 주요 파일 목록

| 파일 | 내용 |
|------|------|
| `src/app/(app)/[module]/parties/page.tsx` | CountryFilterBar 추가, 전체 JSX 재작성 |
| `src/app/(app)/[module]/parties/[id]/page.tsx` | PartySupplyLinksPanel 추가 |
| `src/components/parties/country-filter-bar.tsx` | **신규** — 국가 드롭다운 필터 |
| `src/components/parties/party-supply-links-panel.tsx` | **신규** — 공급 연결 패널 (대폭 수정) |
| `src/components/parties/country-peers-panel.tsx` | Phase 23 완료 |
| `src/components/layout/topbar-search-input.tsx` | 검색 기능 |

---

## 컴포넌트 Export 정보 (정상 상태)

### country-filter-bar.tsx
```tsx
'use client';
export function CountryFilterBar({ countries, current }: Props) { ... }
```
- `parties/page.tsx`에서 `dynamic` import (`ssr: false`)로 사용

### party-supply-links-panel.tsx
```tsx
'use client';
export function PartySupplyLinksPanel({ partyId, partyModule, orgId }: Props) { ... }
```
- `parties/[id]/page.tsx`에서 사용

### country-peers-panel.tsx (서버 컴포넌트)
```tsx
export async function CountryPeersPanel({ ... }) { ... }
```

---

## API 엔드포인트 (구현 완료)

| 경로 | 메서드 | 기능 |
|------|--------|------|
| `/api/supply-links` | GET | partyId+role로 연결 목록 |
| `/api/supply-links` | POST | 새 연결 추가 |
| `/api/supply-links/[id]` | DELETE | 연결 삭제 |
| `/api/parties/search` | GET | q+module로 party 검색 |

---

## DB 테이블 구조

### app.party_supply_links
```sql
filler_party_id uuid → app.parties (module='filler')
mill_party_id   uuid → app.parties (module='paper_mill')
supply_type     text  -- 'active'|'potential'|'pilot'|'historical'
product_grade   text  -- 'PCC'|'GCC'|'PCC+GCC'|...
volume_tpy      integer
notes           text
UNIQUE(filler_party_id, mill_party_id)
```

---

## 사이드바 미완료 작업

- **Paper Companies → Paper Mills** 이름 변경 아직 미완료
  - `MODULE_LABELS` 수정 필요: `paper_mill: 'Paper Mills'`
  - 관련 파일: `src/app/(app)/[module]/parties/page.tsx`

---

## 새 채팅 시작 방법

1. 이 문서를 새 채팅에 붙여넣기
2. `diag.txt` 첨부 또는 내용 붙여넣기
3. 다음 메시지로 시작:

```
아래 handoff 문서와 diag.txt 결과를 참고하여 
"Unsupported Server Component type: undefined" 오류를 수정해 주세요.
[HANDOFF.md 내용 붙여넣기]
[diag.txt 내용 붙여넣기]
```
