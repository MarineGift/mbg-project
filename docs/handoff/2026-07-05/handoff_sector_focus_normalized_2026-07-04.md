# Handoff — Sector focus 정규화 (Interest Tags와 동일 방식) (2026-07-04)

## 요구사항
- Sector focus를 Interest Tags처럼 **정규화 카탈로그(app.sectors) 기반 체크박스 멀티셀렉트**로
- **정규화 안 된 데이터 금지** — 자유 텍스트 대신 카탈로그에서 선택
- **없으면 Add** — 새 sector 입력 시 카탈로그에 자동 등록 (interest_tags와 동일)

## 구조 (interest_tags 미러)
```
app.sectors (code,label_en,sort_order)  ← 카탈로그
  ↓ M:N
app.investor_sector_focus (investor_profile_id, sector_id)  ← 정규화 링크
  + investor_profile.sector_focus text[]  ← 레거시(디렉토리/카드가 읽음, RPC가 동기화)
```

## 4개 파트

### ① RPC — `sql/fix_sync_sector_focus_rpc.sql`
`app.sync_party_sector_focus(party_id, codes[])`: 저장 시 REPLACE 동기화. 슬러그화 → 없는 sector는 app.sectors에 자동생성(sort 900) → investor_sector_focus를 저장셋과 정확히 일치 → 레거시 text[]도 동기화. sync_party_interest_tags와 동일 패턴.

### ② 쿼리 헬퍼 — `src/lib/queries/sector-focus.ts` (신규 파일)
`fetchSectorOptions()`: app.sectors를 sort_order 순 TagOption[]로. interest-tags.ts 미러.

### ③ 폼/페이지 패치 — `patch_sector_focus_normalized.ps1`
- party-form.tsx: Sector focus `<Input>` → `<TagMultiSelect>` (Interest Tags와 동일 컴포넌트), `sectorSuggestions` prop 추가
- new/edit page: `fetchSectorOptions()` 로드 + `sectorSuggestions` 전달
- actions/parties.ts: create+update 저장 후 `sync_party_sector_focus` RPC 호출

## 실행 순서 (파일 생성 먼저)
1. **쿼리 헬퍼 파일 생성** (아래 인라인 또는 다운로드+mover)
2. RPC SQL 다운로드 → mover → **Supabase에서 실행**
3. patch_sector_focus_normalized.ps1 다운로드 → mover → 실행
4. npm run build → commit/push
5. (선택) 기존 자유텍스트 sector를 정규화: RPC 파일 하단 주석의 backfill 1줄 실행

## 쿼리 헬퍼 인라인 생성
```powershell
$p = 'C:\dev\mbg-project\src\lib\queries\sector-focus.ts'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$body = @'
/**
 * lib/queries/sector-focus.ts
 *
 * Canonical sector options (app.sectors) for the Party form Sector focus
 * TagMultiSelect. Global lookup, catalogue sort_order. Mirrors
 * lib/queries/interest-tags.ts so the Sector focus picker behaves exactly like
 * the Interest Tags picker (checkbox multi-select + Add-new).
 */

import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { TagOption } from '@/components/parties/tag-multi-select';

export async function fetchSectorOptions(): Promise<TagOption[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('sectors' as never)
    .select('code, label_en, sort_order')
    .order('sort_order' as never, { ascending: true });

  if (error || !data) return [];

  return (data as Array<{ code: string; label_en: string | null }>)
    .filter((r) => !!r.code)
    .map((r) => ({ code: r.code, label: r.label_en ?? r.code }));
}

'@
[System.IO.File]::WriteAllText($p, $body, $utf8)
Write-Output ('WROTE ' + $p)
```

## mover (RPC + patch)
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
(fix_*.sql → sql\, patch_*.ps1 → tools\patches\)

## 패치 실행
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_sector_focus_normalized.ps1
```
11개 앵커 전부 유일성·중괄호/괄호 밸런스 검증 완료(로컬 시뮬레이션).

## Finish
```powershell
cd C:\dev\mbg-project
npm run build
git status -sb
git add src/ sql/ tools/ docs/
git commit -m "feat(party-form): normalized Sector focus picker (app.sectors catalogue, checkbox + add-new; sync RPC on save)"
git push origin marinebiogroup
```

## 검증
- 배포 후 investor edit → Sector focus가 Interest Tags처럼 체크박스 드롭다운 + Add
- 저장 → investor_sector_focus 링크 갱신 + 레거시 text[] 동기화 확인
- 자유 텍스트로 정규화 안 된 값 입력 불가 (Add하면 카탈로그 정식 등록됨)

## 다음 (B)
California/New York VC 시드 — sector 정규화가 적용됐으니 시드하는 VC의 sector_focus도 정규화 코드로 들어감.
