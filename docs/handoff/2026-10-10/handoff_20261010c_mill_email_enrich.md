# Handoff 2026-10-10 (c) — Paper Mill 이메일 보강

## 목적
/marketing 대량발송은 `contacts.email` 이 있는 제지사만 대상. 이메일 없는 밀을 홈페이지·LinkedIn 으로 조사해 `app.contacts` 에 채운다.

## 워크리스트 현황 (scan_20261010_mill_email_worklist 결과)
- 이메일 없는 paper_mill 770행 (do_not_contact 제외)
- 웹사이트 있음: 426행 = 도메인 93개 / 웹사이트 없음: 344행
- 750행은 이미 form 마커 보유 (폼만 있고 이메일 없음)
- 대형 그룹: Kimberly-Clark 34, Smurfit Westrock 29, International Paper 23, Nippon Paper 21, Mondi 19, Sappi 19, Nine Dragons 17, Stora Enso 16, Oji 12, GP 11, Domtar 10

## 방식 변경 — 크롤러
Claude 웹검색은 회사당 2~4회 호출 + 데이터브로커 페이지가 대부분이라 93개 도메인에 비효율.
→ `tools/mill_email_crawl.ps1` 을 로컬에서 실행: 각 사이트 홈 + 같은 사이트의 contact/imprint/about 페이지를 열어 **페이지에 실제 표시된 이메일만** 수집 (Cloudflare 난독화 해제 포함), 발견 URL 과 함께 CSV 출력. DB 는 건드리지 않음.
→ 결과 CSV 를 Claude 가 검토(도메인 일치·역할 판단) → `enrich_..._bNN.sql` 생성.
→ 웹사이트 없는 344행은 Claude 가 별도 배치로 사이트부터 조사.

## Batch 01 (수동 조사분)
- Kartonsan: kartonsan@ (general), satinalma@ (purchasing) — kartonsan.com.tr/en/contact
- Borregaard AS: borregaard@borregaard.com — 회사 연차보고서
- Modern Karton: 이메일이 Cloudflare 난독화 → 크롤러로 처리

## 조사 규칙
- 페이지에 표시된 주소만. 검색 스니펫·데이터브로커(ContactOut, Wiza, Prospeo 등)·추측 패턴(first.last@) 금지
- 다른 회사 도메인 주소(on_domain=False)는 개별 검토 — 대행사·웹제작사 주소 걸러냄
- 그룹 공통 인박스는 같은 도메인 행에만. LinkedIn 은 이름·직책 확인용, 이메일 추출 X
- 제네릭 주소는 `full_name` 비움, `title_text` = General / Purchasing / Sales inbox
- 폼만 있는 회사는 이메일 행 만들지 않음

## 순서
1. Mover (아래) — sql 2개, handoff, 크롤러(.ps1.txt → tools\mill_email_crawl.ps1), 워크리스트 CSV → data\
2. 크롤러 실행 (5~15분):
   `powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\mill_email_crawl.ps1 -CsvPath C:\dev\mbg-project\data\mill_worklist_20261010.csv`
3. `Downloads\mill_email_candidates_*.csv` 를 채팅에 업로드
4. Supabase: `enrich_20261010_mill_emails_b01.sql` Ctrl+A → Run → 마지막 select 3행 확인
5. Push (data\ 는 커밋하지 않음)

## 발송 시 주의
- 같은 인박스가 여러 사이트 행에 붙으면 한 배치 안에서는 dedup, 다른 배치에서는 재발송 가능 → 미리보기 확인
- DE·AT·KR 은 /marketing 기본 제외

## Mover (inline)
```powershell
$Repo = 'C:\dev\mbg-project'
$Dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = @(
  @{ n='scan_20261010_mill_email_worklist';  e='.sql';     d='sql';                     t='scan_20261010_mill_email_worklist.sql' },
  @{ n='enrich_20261010_mill_emails_b01';    e='.sql';     d='sql';                     t='enrich_20261010_mill_emails_b01.sql' },
  @{ n='handoff_20261010c_mill_email_enrich'; e='.md';     d='docs\handoff\2026-10-10'; t='handoff_20261010c_mill_email_enrich.md' },
  @{ n='mill_email_crawl';                   e='.ps1.txt'; d='tools';                   t='mill_email_crawl.ps1' },
  @{ n='Supabase_Snippet_Untitled_query';    e='.csv';     d='data';                    t='mill_worklist_20261010.csv' }
)
foreach ($m in $map) {
  $hits = Get-ChildItem -LiteralPath $Dl -File | Where-Object { $_.Name -like ($m.n + '*' + $m.e) } | Sort-Object LastWriteTime -Descending
  if (-not $hits) { Write-Output ('MISS  ' + $m.n + $m.e); continue }
  $src = $hits[0]
  Unblock-File -LiteralPath $src.FullName -ErrorAction SilentlyContinue
  $destDir = Join-Path $Repo $m.d
  [System.IO.Directory]::CreateDirectory($destDir) | Out-Null
  $dest = Join-Path $destDir $m.t
  [System.IO.File]::Copy($src.FullName, $dest, $true)
  $hits | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
  Write-Output ('MOVED ' + $src.Name + ' -> ' + $dest)
}
```

## Push
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/scan_20261010_mill_email_worklist.sql sql/enrich_20261010_mill_emails_b01.sql tools/mill_email_crawl.ps1 docs/handoff
git commit -m "mill email enrichment: worklist scan, site crawler, batch 01"
git push origin marinebiogroup
```
