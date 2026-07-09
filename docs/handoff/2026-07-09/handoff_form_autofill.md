# 🧾 Handoff — Investor 지원서 반자동 입력 (migration 026 + Playwright + UI)

날짜: 2026-07-09 · 세션 산출물 15개 파일

---

## 0. 이번 세션 핵심 결정

1. **CTAN 폼의 실체 확인**: ctan.com/entrepreneurs 는 랜딩 페이지일 뿐이고, 실제 지원은
   **Dealum 포털** — `https://app.dealum.com/#/company/application/new/72264/cmwl94en1rop0rvg8k9x44vzlcw2hgrf`
   Member Login도 Dealum에 있음 → `submission_method='portal'`, `login_required=true`.
   migration 026 섹션 4에서 form_url을 자동 교정함 (열린 질문 2번 해결).
2. **스크립트 위치**: 브리프의 `scripts/` 대신 레포 관례인 **`src/scripts/`** 사용
   (기존 `sim:inbound`, `verify:smtp`와 동일한 `tsx --env-file=.env.local` 패턴).
3. **Playwright 설치 불필요**: `@playwright/test`가 이미 devDependencies에 있음.
   **`npx playwright install chromium`만** 실행하면 됨.
4. **NDA 블록리스트는 코드에 하드코딩 금지**: 레포가 PUBLIC이므로 파트너 실명을
   소스에 넣으면 그 자체가 유출. `.env.local`의 `NDA_BLOCKLIST`로만 관리.

---

## 1. 파일 → 경로 매핑

| 다운로드 파일명 | 저장 위치 |
|---|---|
| `migration_026_submission_method.sql` | `sql\` (라우터 자동) |
| `handoff_form_autofill.md` | `docs\handoff\2026-07-09\` (라우터 자동) |
| `patch_package_json_apply_scripts.ps1` | 실행용 패치 (아래 인라인 블록으로도 제공) |
| `src_scripts_inspect-form.ts` | `src\scripts\inspect-form.ts` |
| `src_scripts_fill-application.ts` | `src\scripts\fill-application.ts` |
| `app_applications_page.tsx` | `src\app\(app)\applications\page.tsx` |
| `app_applications_list-client.tsx` | `src\app\(app)\applications\applications-list-client.tsx` |
| `app_applications_formId_page.tsx` | `src\app\(app)\applications\[formId]\page.tsx` |
| `app_applications_formId_editor-client.tsx` | `src\app\(app)\applications\[formId]\application-editor-client.tsx` |
| `app_applications_library_page.tsx` | `src\app\(app)\applications\library\page.tsx` |
| `app_applications_library_client.tsx` | `src\app\(app)\applications\library\library-client.tsx` |
| `api_applications_route.ts` | `src\app\api\applications\route.ts` |
| `api_applications_formId_route.ts` | `src\app\api\applications\[formId]\route.ts` |
| `api_applications_field_route.ts` | `src\app\api\applications\[formId]\fields\[fieldId]\route.ts` |
| `api_applications_submit_route.ts` | `src\app\api\applications\[formId]\submit\route.ts` |
| `api_answer-library_route.ts` | `src\app\api\answer-library\route.ts` |

## 2. 파일 이동

① SQL / handoff / patch는 유니버설 라우터 한 줄:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\dev\mbg-project\tools\move-downloads.ps1"
```

② 코드 파일(TS/TSX)은 아래 블록을 통째로 붙여넣기 (fallback 겸용, 어느 PC든 동작):

```powershell
$repo = "C:\dev\mbg-project"
$dl   = Join-Path $env:USERPROFILE "Downloads"
$map = @(
  @{ src = "src_scripts_inspect-form*.ts";                dst = "src\scripts";                                    name = "inspect-form.ts" },
  @{ src = "src_scripts_fill-application*.ts";            dst = "src\scripts";                                    name = "fill-application.ts" },
  @{ src = "app_applications_page*.tsx";                  dst = "src\app\(app)\applications";                     name = "page.tsx" },
  @{ src = "app_applications_list-client*.tsx";           dst = "src\app\(app)\applications";                     name = "applications-list-client.tsx" },
  @{ src = "app_applications_formId_page*.tsx";           dst = "src\app\(app)\applications\[formId]";            name = "page.tsx" },
  @{ src = "app_applications_formId_editor-client*.tsx";  dst = "src\app\(app)\applications\[formId]";            name = "application-editor-client.tsx" },
  @{ src = "app_applications_library_page*.tsx";          dst = "src\app\(app)\applications\library";             name = "page.tsx" },
  @{ src = "app_applications_library_client*.tsx";        dst = "src\app\(app)\applications\library";             name = "library-client.tsx" },
  @{ src = "api_applications_route*.ts";                  dst = "src\app\api\applications";                       name = "route.ts" },
  @{ src = "api_applications_formId_route*.ts";           dst = "src\app\api\applications\[formId]";              name = "route.ts" },
  @{ src = "api_applications_field_route*.ts";            dst = "src\app\api\applications\[formId]\fields\[fieldId]"; name = "route.ts" },
  @{ src = "api_applications_submit_route*.ts";           dst = "src\app\api\applications\[formId]\submit";       name = "route.ts" },
  @{ src = "api_answer-library_route*.ts";                dst = "src\app\api\answer-library";                     name = "route.ts" }
)
foreach ($m in $map) {
  $f = Get-ChildItem -Path $dl -Filter $m.src -File -ErrorAction SilentlyContinue |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($null -eq $f) { Write-Host ("MISS  " + $m.src); continue }
  Unblock-File -Path $f.FullName -ErrorAction SilentlyContinue
  $destDir = Join-Path $repo $m.dst
  [System.IO.Directory]::CreateDirectory($destDir) | Out-Null
  $dest = Join-Path $destDir $m.name
  [System.IO.File]::Copy($f.FullName, $dest, $true)
  Remove-Item $f.FullName -Force
  Write-Host ("OK    " + $m.name + "  ->  " + $m.dst)
}
```

③ package.json 패치 (npm 스크립트 추가, 멱등):

```powershell
$path = "C:\dev\mbg-project\package.json"
$text = [System.IO.File]::ReadAllText($path) -replace "`r`n", "`n"
if ($text.Contains('"apply:fill"')) { Write-Host "SKIP: already patched" }
else {
  $anchor = '"verify:smtp": "tsx --env-file=.env.local src/scripts/verify-smtp.ts"'
  if (-not $text.Contains($anchor)) { Write-Host "ANCHOR NOT FOUND - add apply:inspect / apply:fill manually" }
  else {
    $replacement = $anchor + ",`n" +
      '    "apply:inspect": "tsx --env-file=.env.local src/scripts/inspect-form.ts",' + "`n" +
      '    "apply:fill": "tsx --env-file=.env.local src/scripts/fill-application.ts"'
    $text = $text.Replace($anchor, $replacement)
    [System.IO.File]::WriteAllText($path, $text)
    Write-Host "OK: npm scripts added"
  }
}
```

## 3. 환경 준비 (1회)

`.env.local`에 두 줄 추가 (커밋 금지 — .gitignore에 이미 포함되어 있을 것):

```
URM_ORG_ID=b25de8f2-1020-482f-9012-183f63883169
NDA_BLOCKLIST=<파트너 실명들을 콤마로, 여기 문서에도 쓰지 말 것>
```

Chromium 설치 (1회):

```powershell
cd C:\dev\mbg-project
npx playwright install chromium
```

## 4. 실행 순서

1. **Supabase SQL Editor**에서 `sql\migration_026_submission_method.sql` 실행
   (멱등 — 두 번 돌려도 안전. 마지막 SELECT 3개로 검증)
2. **셀렉터 수집**:
   ```powershell
   npm run apply:inspect -- --url "https://app.dealum.com/#/company/application/new/72264/cmwl94en1rop0rvg8k9x44vzlcw2hgrf"
   ```
   브라우저에서 계정 생성/로그인 → 실제 폼 화면까지 이동 → 터미널에서 Enter →
   `form-scan-app.dealum.com-N.json` 생성됨. **이 JSON을 다음 세션에 붙여넣으면
   `seed_ctan_selectors.sql`을 생성해줌** (label/max_length/required도 이때 실측치로 교정).
3. **채우기** (셀렉터 시드 후):
   ```powershell
   npm run apply:fill -- --form <formId>
   ```
   nda_blocked 있으면 즉시 중단 / over_limit는 확인 프롬프트 / 채운 뒤 page.pause()로 정지
   → 사람이 검토·첨부·**직접 Submit** → 터미널에서 is_copied / submitted 처리.

## 5. 마무리 (푸시 = Railway 자동배포)

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/migration_026_submission_method.sql
git add docs/handoff/2026-07-09/handoff_form_autofill.md
git add src/scripts/inspect-form.ts src/scripts/fill-application.ts
git add "src/app/(app)/applications" src/app/api/applications src/app/api/answer-library
git add package.json
git commit -m "feat(applications): submission method, selectors, and Playwright semi-auto fill"
git push origin marinebiogroup
```

> `git push`가 웹 반영의 트리거입니다. 푸시 전 `git status -sb`로 확인.

## 6. 열린 질문 현황

| # | 질문 | 상태 |
|---|---|---|
| 1 | CTAN 실제 글자수 제한 | **inspect-form 스캔으로 실측** (2단계에서 해결) |
| 2 | CTAN 로그인 필요 여부 | ✅ **해결** — Dealum 포털, 계정 필요. migration 026이 form_url/portal/login 교정 |
| 3 | Austin Hardtech / MassChallenge 폼 URL·질문 | 미수집 — URL 확보 후 inspect-form 재사용 |
| 4 | 첨부(덱 PDF, 1페이저) 업로드 필드 | fill 스크립트는 `input_kind='upload'`를 **건너뛰고 목록만 출력** — 사람이 브라우저에서 직접 첨부 |

## 7. 다음 세션 킥오프 문장 예시

> form-scan JSON을 붙여넣을 테니 seed_ctan_selectors.sql을 만들어줘.
> label / max_length / is_required는 스캔 실측치로 기존 8개 질문을 교정하고,
> 스캔에만 있는 신규 필드는 INSERT로 추가해줘.
