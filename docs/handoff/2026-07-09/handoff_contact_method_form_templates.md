# Handoff — Party 연락방식 UI + 폼 템플릿 지원서 생성 + Copy-next (2026-07-09)

전제: migration_026 / 027 은 이미 DB에 적용 완료 (parties.preferred_contact_method / contact_form_url,
application_forms.submission_method 계열, application_form_fields.canonical_key / selector,
answer_library.variant / target_length, form_type 'contact_inquiry').

## 이번 배포에 포함된 것

| # | 파일 | 목적지 | 역할 |
|---|---|---|---|
| 1 | seed_form_only_investors.sql | sql\ | 폼 전용 투자자 7곳 시드 (SWAN, HAN, Baylor AN, Third Derivative, NSF SBIR, Techstars, SOSV) + contact_method/form_url + investor_profile |
| 2 | patch_contact_method_ui.ps1 | (실행용) | 기존 7개 파일 제자리 패치 — 타입, 쿼리, 상세 배지·필드, 목록 배지, 폼 편집, 상세 페이지 패널 |
| 3 | contact-method-badge.tsx | src\components\common\ | 연락방식 배지 (web_form/portal이면 링크) |
| 4 | party-application-panel.tsx | src\components\parties\ | Party 상세의 지원서 패널 + "New from template" |
| 5 | canonical-templates.ts | src\lib\applications\ | form_type별 canonical_key 템플릿 + pickVariant |
| 6 | route_from_template.ts | src\app\api\applications\from-template\route.ts | 템플릿에서 폼+필드 생성, answer_library 자동 바인딩 |
| 7 | route_applications_list.ts | src\app\api\applications\route.ts (교체) | ?party_id= 필터 추가 |
| 8 | application-editor-client.tsx | src\app\(app)\applications\[formId]\ (교체) | Copy-next 스티키 툴바 + variant 표시 (기존 기능 전부 보존) |
| 9 | page_application_editor.tsx | src\app\(app)\applications\[formId]\page.tsx (교체) | canonical_key/variant 매핑 로드 |

타입체크 검증 완료: 패치 적용 트리에서 `tsc --noEmit` 신규 오류 0건
(기존 sectorFocus / scripts 오류는 이번 변경과 무관한 pre-existing).

## 실행 순서

### 0) 시작 전 확인 SQL (Supabase SQL Editor)

```sql
SELECT answer_key, variant, length(body_en) AS len, target_length
FROM app.answer_library ORDER BY 1, 2;
```

- variant가 medium 하나뿐인 키가 대부분일 것 → 템플릿 생성은 그대로 동작 (있는 것 중 최적 선택).
- short/long variant 시딩과 중복 키 통합은 이 결과를 보고 후속 세션에서.

### 1) 파일 9개 다운로드 → 라우터 실행

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

라우터는 seed_*.sql → sql\, handoff_*.md → docs\handoff\, patch_*.ps1 을 처리합니다.
코드 파일(.tsx/.ts)은 프리픽스가 없으므로 아래 인라인 mover로 이동합니다.

### 2) 코드 파일 mover (붙여넣기용, ASCII 출력)

```powershell
$repo = "C:\dev\mbg-project"
$dl = Join-Path $env:USERPROFILE "Downloads"
$map = @(
  @{ Src = "contact-method-badge*.tsx";      Dst = "src\components\common\contact-method-badge.tsx" },
  @{ Src = "party-application-panel*.tsx";   Dst = "src\components\parties\party-application-panel.tsx" },
  @{ Src = "canonical-templates*.ts";        Dst = "src\lib\applications\canonical-templates.ts" },
  @{ Src = "route_from_template*.ts";        Dst = "src\app\api\applications\from-template\route.ts" },
  @{ Src = "route_applications_list*.ts";    Dst = "src\app\api\applications\route.ts" },
  @{ Src = "application-editor-client*.tsx"; Dst = "src\app\(app)\applications\[formId]\application-editor-client.tsx" },
  @{ Src = "page_application_editor*.tsx";   Dst = "src\app\(app)\applications\[formId]\page.tsx" }
)
foreach ($m in $map) {
  $f = Get-ChildItem -LiteralPath $dl -Filter $m.Src -File -ErrorAction SilentlyContinue |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $f) { Write-Host ("MISS  " + $m.Src); continue }
  Unblock-File -LiteralPath $f.FullName -ErrorAction SilentlyContinue
  $dest = Join-Path $repo $m.Dst
  [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($dest)) | Out-Null
  [System.IO.File]::Copy($f.FullName, $dest, $true)
  Remove-Item -LiteralPath $f.FullName -Force
  Write-Host ("OK    " + $m.Dst)
}
```

### 3) 기존 파일 패치 실행

```powershell
$dl = Join-Path $env:USERPROFILE "Downloads"
$f = Get-ChildItem -LiteralPath $dl -Filter "patch_contact_method_ui*.ps1" -File |
     Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($f) { Unblock-File -LiteralPath $f.FullName; powershell -ExecutionPolicy Bypass -File $f.FullName }
else { Write-Host "MISS  patch_contact_method_ui.ps1" }
```

출력이 전부 `OK` 또는 `SKIP`(재실행 시)이어야 합니다. `FAIL`이면 해당 파일 앵커가 바뀐 것이니 중단하고 알려주세요.
(레포 HEAD 기준 21개 앵커 전부 검증 완료 상태입니다.)

### 4) 시드 SQL 실행 (Supabase SQL Editor)

`sql\seed_form_only_investors.sql` 전체를 붙여넣고 실행. idempotent — 재실행 안전.
마지막 SELECT가 7행(SWAN / HAN / Baylor / Third Derivative / NSF SBIR / Techstars / SOSV)을 반환해야 합니다.

### 5) 마무리 (푸시 = Railway 자동배포)

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/ docs/ src/
git commit -m "feat: contact method UI + form template generation + copy-next mode"
git push origin marinebiogroup
```

푸시해야 urm.marinebiogroup.com에 반영됩니다.

## 배포 후 확인

1. Investors 목록 → SWAN Impact Network 등에 연락방식 배지(portal/web_form) 표시
2. Party 상세 → 배지 + Contact method/Form URL 필드 + Applications 패널
3. Applications 패널 → "New from template" → form_type: application 선택 → 15필드 생성, answer_library 바인딩 확인
4. 에디터 → Copy-next 툴바: 진행바, 다음 타깃 하이라이트, 클릭 시 복사+is_copied 저장+다음 카드 스크롤

## 주의사항

- **DB CHECK 제약**: preferred_contact_method가 web_form/portal이면 contact_form_url이 반드시 필요합니다.
  폼에서 URL 없이 저장하면 DB가 거부합니다 (에러 메시지로 안내됨).
- **Houston Angel Network**: 선호 라운드 $250K–1.5M — 현재 $100K SAFE는 하한 미달.
  라운드 확대 또는 리드 확보 후 지원 권장. 시드에는 status 참고용으로 포함.
- **NSF SBIR**: Project Pitch 2026-06-02 재개 (NSF 26-510). Phase I 최대 $305K 비희석.
  단, 미국 시민/영주권자 지분 50%+ 요건 — 현 캡테이블(Heo 51% / Seo 34%) 적격성 확인 필수.
- **Baylor Angel Network**: 체크 $25K–250K — 현재 $100K 라운드에 가장 잘 맞는 체급.
- **Third Derivative**: 2026 코호트 하드테크·저탄소소재 집중, TRL4+ 요건, 선택형 $100K 노트.
- 파트너 실명(Omya/SMI/무림/TPIL)은 웹폼·공개자료에 쓰지 않는 원칙 유지 — 템플릿 답변도 NDA 차단 로직이 그대로 작동합니다.

## 후속 작업 후보

1. answer_library short/long variant 시딩 (0번 확인 SQL 결과 기반)
2. 중복/유사 answer_key 통합
3. 지원서 필드 selector 채우기 (실제 폼 자동 매핑용)
4. 텀시트(전용실시권) 체결·등록 완료 시 901/804/714 답변 갱신 SQL
