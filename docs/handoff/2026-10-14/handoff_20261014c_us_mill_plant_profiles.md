\xef\xbb\xbf# Handoff 2026-10-14 (c) — 미국 타깃 제지공장 상세 프로필 + Mill profile 카드

> 앞 문서: `handoff_20261014b_omya_us_plants.md`

## 1. 파일
| 파일 | 위치 | 내용 |
|---|---|---|
| `fix_20261014c_us_mill_plant_profiles.sql` | `sql\` | 6개 밀의 `paper_mill_profile.extra_data.plant` 입력 |
| `plant-profile-card.tsx` | `src\components\parties\` | 신규 서버 컴포넌트 — Overview 탭 "Mill profile / Plant profile" 카드 |
| `page.tsx` (패치) | `src\app\(app)\[partyType]\parties\[id]\` | Info 카드 아래에 카드 삽입 (paper_mill · filler_supplier) |

## 2. 대상 밀 (outreach priority)
| # | 밀 | 생산능력 | 현재 필러 |
|---|---|---|---|
| 1 | Sylvamo Eastover SC | 700,000 short t | SMI 위성 PCC |
| 2 | Sylvamo Ticonderoga NY | 275,000 short t | SMI 위성 PCC |
| 3 | Sappi Cloquet MN | 340,000 metric t (그래픽 270k + 포장·특수 70k) | SMI 위성 PCC |
| 4 | Domtar Hawesville KY | 596,000 short t, PM 2대 | Omya PCC USA (밀 주소) |
| 5 | Domtar Johnsonburg PA | 344,000 short t, PM 2대 | Omya PCC USA |
| - | Domtar Nekoosa WI | 미입력 | Omya on-site PCC 2024-09 (~27,500 dry t) — 3자 모델 레퍼런스 |

## 3. 카드 동작
- 프로필 기본 필드 + `extra_data.plant` 중 채워진 항목만 표시
- FCC 시나리오: 카드가 계산 = 생산능력(short t → metric 환산) × 가동률 × FCC 적용 비율 × 시트 내 FCC 비율, 로열티 $15/t
  - 보수 75/10/10 · 기준 85/25/20 · 확대 90/50/25 (기준 합계 약 88,300 t · $1.32M — 보고서와 일치)
- 공급사·근거, 접근 전략, 최근 이벤트, 첫 미팅 질문, 출처
- 다른 밀은 `extra_data.plant` 를 채우면 같은 카드로 표시됨 (스키마 변경 없음)

## 4. 보고서와 다르게 둔 것
- Domtar Hawesville·Johnsonburg 의 Omya: 보고서는 "과거 이력"이라 했지만 Omya PCC USA 가 밀 주소에 현재 등록 → active / medium 유지
- 시나리오 수치는 DB 에 저장하지 않고 가정만 저장 (생산능력이 바뀌면 자동 재계산)

## 5. 적용 순서 (PowerShell, 한 블록)
```powershell
$repo = 'C:\dev\mbg-project'; $dl = Join-Path $env:USERPROFILE 'Downloads'
$utf8 = New-Object System.Text.UTF8Encoding($false)
# 1) component file -> src\components\parties
$f = Get-ChildItem -Path $dl -Filter 'plant-profile-card*.tsx' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if ($f) {
  Unblock-File -Path $f[0].FullName -ErrorAction SilentlyContinue
  $dest = Join-Path $repo 'src\components\parties\plant-profile-card.tsx'
  [System.IO.File]::Copy($f[0].FullName, $dest, $true)
  $f | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
  Write-Output ('MOVED plant-profile-card.tsx -> ' + $dest)
} else { Write-Output 'MISSING plant-profile-card.tsx in Downloads' }
# 2) patch party detail page (idempotent)
$p = Join-Path $repo 'src\app\(app)\[partyType]\parties\[id]\page.tsx'
$s = [System.IO.File]::ReadAllText($p, $utf8).Replace("`r`n", "`n")
if ($s.Contains('PlantProfileCard')) { Write-Output 'SKIP page.tsx already patched' }
else {
  $a = "import { MentorProfileCard } from '@/components/parties/mentor-profile-card';"
  $b = '<PartyInfoCard party={full.party} contacts={full.contacts} />'
  if (-not $s.Contains($a) -or -not $s.Contains($b)) { Write-Output 'ERROR anchors not found - page.tsx not changed' }
  else {
    $s = $s.Replace($a, $a + "`nimport { PlantProfileCard } from '@/components/parties/plant-profile-card';")
    $ins = "`n                {(full.party.partyType === 'paper_mill' ||`n                  full.party.partyType === 'filler_supplier') && (`n                  <PlantProfileCard`n                    partyId={full.party.id}`n                    partyType={full.party.partyType as 'paper_mill' | 'filler_supplier'}`n                  />`n                )}"
    $s = $s.Replace($b, $b + $ins)
    [System.IO.File]::WriteAllText($p, $s, $utf8)
    Write-Output 'PATCHED page.tsx'
  }
}
# 3) sql + handoff
powershell -ExecutionPolicy Bypass -File (Join-Path $repo 'tools\move-downloads.ps1')
```
그 다음 Supabase 에서 `sql\fix_20261014c_us_mill_plant_profiles.sql` 실행 (Ctrl+A → Run). 검증: 6행, priority 1~5 + Nekoosa.

## 6. 커밋
```powershell
cd C:\dev\mbg-project
git status -sb
git add src/components/parties/plant-profile-card.tsx "src/app/(app)/[partyType]/parties/[id]/page.tsx" sql/fix_20261014c_us_mill_plant_profiles.sql docs/handoff
git commit -m "mill profile card + US target mill plant profiles (Sylvamo, Sappi, Domtar)"
git push origin marinebiogroup
```
