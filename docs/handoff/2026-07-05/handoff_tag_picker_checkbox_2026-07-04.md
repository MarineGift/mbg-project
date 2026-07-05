# Handoff — 태그 피커 v2: 체크박스 다중선택 + 영문 라벨 (2026-07-04)

## 변경
1. **체크박스 방식**: 선택된 태그가 목록에서 사라지지 않고 체크 표시로 남음 → 클릭할 때마다 추가/해제 토글, 드롭다운 열린 채 여러 개 연속 선택
2. **한글 라벨 제거**: 우측 라벨을 label_en(영문)만 표시
3. 목록 12개 + 스크롤(max-h-64) — 카탈로그 전체 탐색 가능
4. Add 버튼·칩 ×삭제·Backspace는 기존 유지

## 실행
1. 아래 인라인 패치 실행 (기존 두 파일 6개 앵커, 멱등)
2. `npm run build`
3. finish block → 배포 후 하드 리프레시(Ctrl+F5)

## 인라인 패치

```powershell
# patch_tag_picker_checkbox.ps1
# Tag picker v2: checkbox multi-select (selected tags stay in the list,
# click toggles) + English-only labels (drop Korean). Idempotent.
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$warn = $false

$path = 'C:\dev\mbg-project\src\components\parties\tag-multi-select.tsx'
$c = [System.IO.File]::ReadAllText($path); $c = $c.Replace("`r`n", "`n")

$old_C2 = @'
import { useMemo, useRef, useState } from 'react';
import { X, Plus } from 'lucide-react';
'@
$new_C2 = @'
import { useMemo, useRef, useState } from 'react';
import { X, Plus, Check } from 'lucide-react';
'@
if ($c.Contains($new_C2)) { Write-Output ('SKIP C2') }
elseif ($c.Contains($old_C2)) { $c = $c.Replace($old_C2, $new_C2); Write-Output ('OK   C2') }
else { Write-Output ('WARN C2: anchor not found'); $warn = $true }

$old_C1 = @'
  const q = query.trim().toLowerCase();
  const matches = useMemo(() => {
    const pool = suggestions.filter((s) => !selectedSet.has(s.code.toLowerCase()));
    if (!q) return pool.slice(0, 8);
    return pool
      .filter(
        (s) =>
          s.code.toLowerCase().includes(q) || s.label.toLowerCase().includes(q),
      )
      .slice(0, 8);
  }, [suggestions, selectedSet, q]);
'@
$new_C1 = @'
  const q = query.trim().toLowerCase();
  // checkbox mode: selected tags STAY in the list (checked) so multiple
  // selections toggle in place.
  const matches = useMemo(() => {
    if (!q) return suggestions.slice(0, 12);
    return suggestions
      .filter(
        (s) =>
          s.code.toLowerCase().includes(q) || s.label.toLowerCase().includes(q),
      )
      .slice(0, 12);
  }, [suggestions, q]);
'@
if ($c.Contains($new_C1)) { Write-Output ('SKIP C1') }
elseif ($c.Contains($old_C1)) { $c = $c.Replace($old_C1, $new_C1); Write-Output ('OK   C1') }
else { Write-Output ('WARN C1: anchor not found'); $warn = $true }

$old_C3 = @'
  const remove = (code: string) => {
    onChange(selected.filter((s) => s !== code).join(', '));
  };
'@
$new_C3 = @'
  const remove = (code: string) => {
    onChange(selected.filter((s) => s !== code).join(', '));
  };
  const toggle = (code: string) => {
    const found = selected.find((s) => s.toLowerCase() === code.toLowerCase());
    if (found) remove(found);
    else add(code);
  };
'@
if ($c.Contains($new_C3)) { Write-Output ('SKIP C3') }
elseif ($c.Contains($old_C3)) { $c = $c.Replace($old_C3, $new_C3); Write-Output ('OK   C3') }
else { Write-Output ('WARN C3: anchor not found'); $warn = $true }

$old_C4 = @'
          {matches.map((s) => (
            <button
              key={s.code}
              type="button"
              className="flex w-full items-center justify-between rounded px-2 py-1.5 text-left text-sm hover:bg-muted"
              onMouseDown={(e) => e.preventDefault()}
              onClick={() => add(s.code)}
            >
              <span>{s.code}</span>
              {s.label !== s.code && (
                <span className="ml-2 truncate text-xs text-muted-foreground">
                  {s.label}
                </span>
              )}
            </button>
          ))}
'@
$new_C4 = @'
          {matches.map((s) => {
            const checked = selectedSet.has(s.code.toLowerCase());
            return (
              <button
                key={s.code}
                type="button"
                className="flex w-full items-center gap-2 rounded px-2 py-1.5 text-left text-sm hover:bg-muted"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => toggle(s.code)}
              >
                <span
                  className={`flex h-4 w-4 shrink-0 items-center justify-center rounded border ${checked ? 'border-primary bg-primary text-primary-foreground' : 'border-input'}`}
                >
                  {checked && <Check className="h-3 w-3" />}
                </span>
                <span className="flex-1 truncate">{s.code}</span>
                {s.label !== s.code && (
                  <span className="ml-2 truncate text-xs text-muted-foreground">
                    {s.label}
                  </span>
                )}
              </button>
            );
          })}
'@
if ($c.Contains($new_C4)) { Write-Output ('SKIP C4') }
elseif ($c.Contains($old_C4)) { $c = $c.Replace($old_C4, $new_C4); Write-Output ('OK   C4') }
else { Write-Output ('WARN C4: anchor not found'); $warn = $true }

$old_C5 = @'
        <div className="absolute z-30 mt-1 w-full rounded-md border bg-popover p-1 shadow-md">
'@
$new_C5 = @'
        <div className="absolute z-30 mt-1 max-h-64 w-full overflow-y-auto rounded-md border bg-popover p-1 shadow-md">
'@
if ($c.Contains($new_C5)) { Write-Output ('SKIP C5') }
elseif ($c.Contains($old_C5)) { $c = $c.Replace($old_C5, $new_C5); Write-Output ('OK   C5') }
else { Write-Output ('WARN C5: anchor not found'); $warn = $true }

[System.IO.File]::WriteAllText($path, $c, $utf8); Write-Output ('WROTE ' + $path)

$path = 'C:\dev\mbg-project\src\lib\queries\interest-tags.ts'
$h = [System.IO.File]::ReadAllText($path); $h = $h.Replace("`r`n", "`n")

$old_H1 = @'
      label:
        r.label_ko && r.label_ko !== r.code
          ? r.label_ko
          : (r.label_en ?? r.code),
'@
$new_H1 = @'
      // English-only label (user request: no Korean in the picker)
      label: r.label_en ?? r.code,
'@
if ($h.Contains($new_H1)) { Write-Output ('SKIP H1') }
elseif ($h.Contains($old_H1)) { $h = $h.Replace($old_H1, $new_H1); Write-Output ('OK   H1') }
else { Write-Output ('WARN H1: anchor not found'); $warn = $true }

[System.IO.File]::WriteAllText($path, $h, $utf8); Write-Output ('WROTE ' + $path)

if ($warn) { Write-Output 'Anchor missing - review WARN lines.' }
Write-Output 'Next: npm run build, then commit + push.'
```

## Finish block

```powershell
cd C:\dev\mbg-project
npm run build
git status -sb
git add src/components/parties/tag-multi-select.tsx src/lib/queries/interest-tags.ts tools/ docs/
git commit -m "feat(tag-picker): checkbox multi-select toggle, english-only labels, scrollable list"
git push origin marinebiogroup
```
