# URM 개발 HANDBOOK - PowerShell 파일 전달 표준 (필수 / 모든 작업 공통)

> 이 문서는 **강제 규칙**이다. mbg-project의 모든 작업(파일 생성/수정/이동)은 **반드시 아래와 동일한 형태의 PowerShell**로 파일을 repo에 적용한다.
> 다운로드 파일을 손으로 복사/이동하지 않는다. 항상 mover/patch `.ps1`을 함께 만들어 제공한다.

---

## 0. 절대 규칙 (요약)

1. **모든 산출물에는 PowerShell이 따라온다.** 새 파일이면 **mover.ps1**, 기존 파일 수정이면 **patch.ps1**.
2. 실행은 항상: `powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\<script>.ps1"`
3. **콘솔 출력은 ASCII 전용.** PS 5.x는 UTF-8 no-BOM을 CP949로 오인 -> 한글 깨짐. `.ps1`/`.sql` 본문은 ASCII만.
4. **한글은 UTF-8 BOM `.md`에만.** (mover가 이동만 하므로 .md 내용은 보존됨)
5. 다운로드 zone-block 해제: **`Unblock-File`** 또는 `-ExecutionPolicy Bypass -File`.
6. 괄호/대괄호 경로(`(app)`, `[partyType]`, `[id]`)는 **`-LiteralPath`** 또는 `[System.IO.File]::Copy` 사용.
7. 기존 파일 수정은 **in-place 패치**(ReadAllText -> Replace -> WriteAllText, CRLF->LF, UTF-8 no-BOM). 멱등 가드 필수.
8. 끝은 항상 **finish block** (`git add` -> `git status -sb` -> `commit` -> `git push origin marinebiogroup`). push가 웹 배포임을 명시.
9. 데이터/RPC는 SQL Editor 실행이 별도 필요(push는 파일 이력만).
10. handoff `.md`에 **mover 파일명 / download->repo 경로 매핑 / 실행 명령**을 매번 문서화.

상수: repo = `C:\dev\mbg-project`, branch = `marinebiogroup`, 다운로드 = `$env:USERPROFILE\Downloads` (양 머신 공통).

---

## 1. 템플릿 A - 신규 파일 mover (Downloads -> repo)  [가장 자주 씀]

```powershell
# move_<name>.ps1  (ASCII console; the .md/.sql content itself is preserved)
$ErrorActionPreference = 'Stop'
$repo   = 'C:\dev\mbg-project'
$src    = Join-Path $env:USERPROFILE 'Downloads\<FILENAME>'
$dstDir = Join-Path $repo '<REPO\SUBDIR>'
$dst    = Join-Path $dstDir '<FILENAME>'

if (-not (Test-Path -LiteralPath $src)) { throw ('not found in Downloads: ' + $src) }
Unblock-File -LiteralPath $src
[System.IO.Directory]::CreateDirectory($dstDir) | Out-Null
Move-Item -LiteralPath $src -Destination $dst -Force
Write-Host ('[ok] moved -> ' + $dst)

Write-Host ''
Write-Host 'Next:'
Write-Host '  cd C:\dev\mbg-project'
Write-Host '  git add <REPO/SUBDIR/FILENAME>'
Write-Host '  git status -sb'
Write-Host '  git commit -m "<message>"'
Write-Host '  git push origin marinebiogroup'
```

### 1-1. 여러 파일 mover (테이블 구동)
```powershell
$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = @(
  @{ file = 'fileA.sql'; dir = 'supabase\migrations' },
  @{ file = 'fileB.tsx'; dir = 'src\components\settings' }
)
foreach ($m in $map) {
  $src = Join-Path $dl $m.file
  $dstDir = Join-Path $repo $m.dir
  $dst = Join-Path $dstDir $m.file
  if (-not (Test-Path -LiteralPath $src)) { throw ('not found: ' + $src) }
  Unblock-File -LiteralPath $src
  [System.IO.Directory]::CreateDirectory($dstDir) | Out-Null
  Move-Item -LiteralPath $src -Destination $dst -Force
  Write-Host ('[ok] ' + $dst)
}
```

### 1-2. 괄호/대괄호 route 경로(예: `src\app\(app)\[partyType]\[id]`)
`-LiteralPath`가 핵심. 그래도 문제면 .NET 사용:
```powershell
[System.IO.Directory]::CreateDirectory($dstDir) | Out-Null
[System.IO.File]::Copy($src, $dst, $true)   # overwrite
Remove-Item -LiteralPath $src -Force
```

---

## 2. 템플릿 B - 신규 ASCII 파일을 repo에 직접 생성 (here-string)
주로 `.sql`/`.ps1` 같은 ASCII 파일. 한글이 필요하면 이 방식 금지(BOM 필요) -> 템플릿 A로 mover 사용.
```powershell
$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'
$p = Join-Path $repo '<REPO\SUBDIR\file.sql>'
$body = @'
-- ASCII content only
select 1;
'@
[System.IO.Directory]::CreateDirectory((Split-Path $p)) | Out-Null
Set-Content -Path $p -Value $body -Encoding ascii
Write-Host ('[ok] wrote ' + $p)
```

---

## 3. 템플릿 C - 기존 파일 in-place 패치 (멱등)
`-File`로 돌릴 때 PS 5.x에서 가끔 조용히 무동작 -> **inline 붙여넣기 블록도 함께 제공**할 것.
```powershell
$ErrorActionPreference = 'Stop'
$enc  = New-Object System.Text.UTF8Encoding($false)   # UTF-8 no-BOM (비ASCII 보존)
$path = Join-Path 'C:\dev\mbg-project' '<REPO\SUBDIR\file.ts>'

$t = [System.IO.File]::ReadAllText($path)
$t = $t -replace "`r`n", "`n"                          # CRLF -> LF 먼저

$old = @'
<EXACT OLD BLOCK - 파일과 1:1 일치, LF 기준>
'@.TrimEnd("`n")
$new = @'
<NEW BLOCK>
'@.TrimEnd("`n")

if ($t.Contains('<GUARD_STRING>')) {                   # 이미 패치됨?
  Write-Host '[skip] already patched'
} elseif (-not $t.Contains($old)) {
  throw 'anchor not found'
} else {
  $t = $t.Replace($old, $new)
  $t = $t -replace "`r`n", "`n"
  [System.IO.File]::WriteAllText($path, $t, $enc)
  Write-Host ('[ok] patched ' + $path)
}
```
여러 블록을 바꿀 땐 `Patch-File` 헬퍼(블록 배열 + guard) 패턴을 쓴다. 각 블록은 적용 전 `Contains` 존재 검사(없으면 throw).

---

## 4. 템플릿 D - finish block (항상 마지막)
```powershell
cd C:\dev\mbg-project
git add <changed paths>
git status -sb
git commit -m "<type(scope): message>"
git push origin marinebiogroup   # push가 웹(mbg-project) 자동배포. 워커는 lucky-patience.
```

---

## 5. 산출 시 체크리스트 (Claude/작업자용)
- [ ] 신규 파일 -> 템플릿 A(mover) 동봉. 기존 수정 -> 템플릿 C(patch) 동봉 (+ inline 블록).
- [ ] `.ps1`/`.sql` 본문 **ASCII only** 확인 (`grep -nP '[^\x00-\x7F]'` = 0).
- [ ] 한글 `.md`는 **UTF-8 BOM** 확인 (`EF BB BF`).
- [ ] 괄호/대괄호 경로면 `-LiteralPath`/.NET 사용.
- [ ] in-place 패치는 멱등 가드 + anchor 존재검사.
- [ ] handoff `.md`에 mover 파일명/경로매핑/실행명령 문서화.
- [ ] finish block(`git push origin marinebiogroup`) 포함.
- [ ] 데이터/RPC면 "SQL Editor에 붙여넣어 Run" 별도 안내.

---

## 6. 실행 한 줄 (참고)
```
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\<script>.ps1"
```

> 이 표준은 모든 세션/핸드오프의 상위 규칙이다. 신규 세션은 작업 시작 전 본 문서를 따른다.
