# HANDOFF — Inbox: Greentown Labs 투자자 메일 Investors 분류 (2026-09-21)

## 문제
- Josh Grehan ("Greentown connected us") → 배지 없음: 발신자가 URM party에 없음.
- Mitchell Hauser ("… Exploring a potential fit with Strategic Ventures") → `partyTypes.mentor`: 같은 사람이 Greentown 멘토 party(118명)로 등록돼 있어 contact 이메일 매칭이 mentor party를 선택. 게다가 i18n에 `mentor` 키가 없어 원시 키가 노출.
- 원인: Greentown 웜인트로 발송은 Greentown 메일 시스템으로 나갔기 때문에 URM에 outbound가 없고, 스레드 매칭이 불가.

## 변경 (AI 없음, 규칙 기반)
- `src/lib/email/investor-intro.ts` (신규): 판정 규칙
  1. 발신자 = `will@greentownlabs.org` (/.com) → 항상 Investors (대량발송 헤더여도)
  2. 제목이 웜인트로 템플릿 `Exploring a potential fit with <Firm>` → Investors, Firm 추출
  3. 제목 또는 **새 본문**(인용 제외 — 우리 서명에 Greentown 주소가 있으므로)에 Greentown + 소개/투자 단어, 발신자가 Greentown 직원 아님 → Investors
  - 2·3은 뉴스레터(List-Unsubscribe 등) 제외.
  - 가드: 이미 paper_mill/filler_supplier/partner 등 사업 party에 연결된 메일은 건드리지 않음 (미연결·mentor·investor만).
- `mailcarrier.ts` 인입 시 판정 → `external_data.inferred_party_type='investor'` + `investor_intro{reason,firm_hint,relinked}` 저장. Firm 이름과 정확히 일치하는 investor party가 **1개**면 party_id 재연결(contact_id는 다른 party 소속이면 null).
- `queries/inbox.ts` + `types/inbox.ts`: 배지 = 스레드 내 inferred 값 우선, 없으면 연결 party 타입.
- i18n en/ko/ja `partyTypes.mentor` 추가 (Mentors/멘토/メンター).
- 테스트 `src/__tests__/email/investor-intro.test.ts` (5개 통과). 기존 email 테스트 실패 6건은 변경 전과 동일(기존 이슈).

## 기존 메일 백필
`sql/backfill_20260921_greentown_investor_intro.sql` — Supabase SQL Editor에서 **Ctrl+A 후 Run**. 태깅 → Firm 재연결 → 결과표(마지막 SELECT). 멱등, org UUID 불필요.

## Greentown 인트로 발신자 추가 방법
`investor-intro.ts`의 `GREENTOWN_INTRO_SENDERS` 배열에 소문자 주소 추가.

## 남은 일 / 확인
- 백필 결과표에서 `relinked=false`인 행 = Firm party가 없거나 이름 불일치. 필요하면 해당 investor party 생성 후 백필 재실행(멱등이라 relink 단계만 다시 적용됨).
- Josh Grehan(Helios?)은 제목에 Firm이 없어 배지만 Investors, party 미연결 → 필요 시 수동으로 party/contact 생성.
- mail folder "Investors" 그룹은 party_id 기준이므로 미연결 메일은 폴더에 안 뜸 (배지만 표시).

## Inline mover (PowerShell)
```powershell
$Repo = 'C:\dev\mbg-project'
$Dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = [ordered]@{
  'investor-intro.ts'      = 'src\lib\email\investor-intro.ts'
  'investor-intro.test.ts' = 'src\__tests__\email\investor-intro.test.ts'
  'mailcarrier.ts'         = 'src\lib\email\mailcarrier.ts'
  'queries_inbox.ts'       = 'src\lib\queries\inbox.ts'
  'types_inbox.ts'         = 'src\types\inbox.ts'
  'messages_en.json'       = 'src\i18n\messages\en.json'
  'messages_ko.json'       = 'src\i18n\messages\ko.json'
  'messages_ja.json'       = 'src\i18n\messages\ja.json'
}
foreach ($name in $map.Keys) {
  $base = [System.IO.Path]::GetFileNameWithoutExtension($name)
  $ext  = [System.IO.Path]::GetExtension($name)
  $hits = @(Get-ChildItem -LiteralPath $Dl -File | Where-Object { $_.Name -like ($base + '*' + $ext) -and ($_.Name -eq $name -or $_.Name -match ('^' + [regex]::Escape($base) + ' \(\d+\)' + [regex]::Escape($ext) + '$')) } | Sort-Object LastWriteTime -Descending)
  if ($hits.Count -eq 0) { Write-Output ('MISS  ' + $name); continue }
  $dest = Join-Path $Repo $map[$name]
  [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($dest)) | Out-Null
  Unblock-File -LiteralPath $hits[0].FullName -ErrorAction SilentlyContinue
  [System.IO.File]::Copy($hits[0].FullName, $dest, $true)
  $hits | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
  Write-Output ('MOVED ' + $hits[0].Name + ' -> ' + $map[$name])
}
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
