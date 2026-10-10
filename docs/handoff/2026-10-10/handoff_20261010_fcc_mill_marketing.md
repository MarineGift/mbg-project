\xef\xbb\xbf# Handoff 2026-10-10 — Marketing: 글로벌 제지사 FCC 대량발송 (/marketing)

## 목적
글로벌 필러 대기업과 공급계약 체결 → 전 세계 제지사에 "충전제 공급사에 FCC 로 펄프를 대체하고 싶다고만 말하면 된다 → 공급사가 MBG 에 연락" 메시지를 대량 발송.
MBG 는 기술 라이선서: 제지사에 제품을 팔지 않음. 제지사 → 기존 PCC/GCC 공급사 → MBG(라이선스/로열티).

## 변경
1. NEW `src/lib/queries/marketing-segment.ts` — 디렉토리 세그먼트 해석 (party_type + 포함/제외 국가 + 키워드(이름/제품군) + 공급사 이름(`party_supply_links`) + 팔로업(이전 템플릿 N일 전 수신자만)). 이미 발송 / 큐 대기(`mail_run_recipients` pending·sending) / do-not-send / 이메일 없음 제외 후 **다음 배치(최대 150)** 반환. 1000행 페이지네이션.
2. NEW `src/lib/actions/marketing-segment.ts` — `buildMarketingSegment()` server action
3. NEW `src/app/(app)/marketing/page.tsx`, `marketing-client.tsx` — 세그먼트 → 템플릿 → "Build batch" → 미리보기 → Queue. 국가·제품군 칩(이메일보유/전체 건수), 팔로업 모드, 화-목 09:00 예약 버튼, 최근 run 진행률
4. 사이드바 `Marketing` 메뉴 (inline patch, `src/components/layout/sidebar.tsx`)
5. SQL `seed_20261010_fcc_mill_outreach_templates.sql` — 영문 템플릿 3종 (party_type=paper_mill, category=marketing)
- 발송은 기존 `enqueueBulkMail` (source=parties) 재사용 → 블록리스트·바운스·회신자 제외·rate limit·worker 그대로. **DB 마이그레이션 없음**
- tsc 오류 12건 = 기존 그대로

## 순서
1) Supabase: seed SQL 실행 (Ctrl+A → Run) → 3행
2) 파일 이동 + 사이드바 패치 + push
3) /marketing → Party type = Paper Mill → Template "FCC Mill 1" → Build batch → 미리보기 확인 → Queue
4) 1차 발송 7일 후: Follow-up ON, Earlier template = FCC Mill 1, 7일 → Template "FCC Mill 2". 14일 후 "FCC Mill 3"

## 발송 전 확인 (중요)
- 계약 상대방 이름은 메일에 쓰지 않음 ("a leading global filler manufacturer"). NDA 상 "supply agreement" 표현 가능 여부 확인
- "60% ash FCC 지 = 30% ash GCC 지 강도 이상" 은 충남대 발표 논문 결과 — 인용 가능 여부 확인, 아니면 그 문장 삭제
- 푸터 주소 "Houston, TX" → 실제 우편주소(Greentown Labs Houston 주소)로 교체 권장 (CAN-SPAM)
- 수신거부 회신("unsubscribe")은 자동 분류되지 않음 → Settings > Email blocklist 에 수동 등록
- 처음 2~3일은 배치 50, 15/min. 바운스율 3% 넘으면 중단하고 주소 정리

## 글로벌 제지사 컨택 방법
**타깃 우선순위**
1. 계약 공급사가 이미 공급 중인 밀 (Supplied by = 공급사 이름) — 공급사가 곧바로 응대 가능, 전환 가장 빠름
2. 충전제 비율이 높은 지종: 인쇄용지(UWF/CWF), 신문·SC, 판지 중층. 티슈는 SMI 관심 분야
3. 위성 PCC 플랜트가 있는 대형 밀 (공급사와 협의 구조가 이미 있음)
4. 다른 PCC/GCC 공급사의 밀 → 그 공급사가 MBG 에 문의 = 신규 라이선시 확보 경로

**연락 대상 직책 (밀당 2명: 기술 1 + 구매 1)**
Technical Director / Mill Manager / Production Manager / Chief Papermaker / Head of Procurement (Fiber & Chemicals) / R&D Manager. 지속가능성·원가절감 담당 임원도 유효

**연락처 확보 채널**
- URM 디렉토리: /marketing 국가 칩의 "이메일보유/전체" 로 공백 확인 → 공백 큰 국가부터 보강
- 회사 웹사이트 Contact/IR 페이지, 각 밀 사이트 대표 메일
- LinkedIn (Sales Navigator 필터: Paper & Forest Products, 위 직책) + 이메일 확인 도구(Apollo, Hunter 등)로 보강 → contacts 에 입력
- 업계 데이터: Fastmarkets RISI 밀 데이터베이스, PPI(Pulp & Paper International) 디렉토리
- 협회: CEPI(유럽), AF&PA(미국), Ibá(브라질), IPMA(인도), 중국조지협회, 일본제지연합회, 한국제지연합회
- 전시·학회: TAPPI PaperCon, Paper One Show, Miac(Lucca), Paperex(인도), Tissue World, ABTCP, PaperWeek Canada — 사전 미팅 요청 메일에 같은 메시지 사용

**국가별 규제 (콜드 메일)**
- 미국 CAN-SPAM: 실제 주소 + 수신거부 방법 필수 (템플릿에 포함)
- EU/UK: B2B 정당한 이익 근거 + 즉시 수신거부. 독일·오스트리아는 사전 동의 요구 → 기본 제외
- 한국: 정보통신망법상 광고성 메일 사전 동의 + 제목 "(광고)" → 기본 제외, 국내 밀은 직접 연락
- 캐나다 CASL: 공개된 업무 이메일 + 업무 관련 내용이면 묵시적 동의 가능
- 일본: 업무용으로 공개된 주소는 예외 인정. 그 외는 신중

**응답 처리**
회신은 Inbox 로 들어옴. 공급사(필러 제조사)가 연락해 오면 Filler Suppliers 파이프라인 딜 생성 → 기술이전/로열티 협의. 제지사 관심 회신은 공급사 이름을 물어 연결

## Mover (inline)
```powershell
$Repo = 'C:\dev\mbg-project'
$Dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = @(
  @{ n='marketing-segment-query';  e='.ts';  d='src\lib\queries';        t='marketing-segment.ts' },
  @{ n='marketing-segment-action'; e='.ts';  d='src\lib\actions';        t='marketing-segment.ts' },
  @{ n='marketing-page';           e='.tsx'; d='src\app\(app)\marketing'; t='page.tsx' },
  @{ n='marketing-client';         e='.tsx'; d='src\app\(app)\marketing'; t='marketing-client.tsx' }
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
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

## Sidebar patch (inline)
```powershell
$f = 'C:\dev\mbg-project\src\components\layout\sidebar.tsx'
$s = [System.IO.File]::ReadAllText($f).Replace("`r`n", "`n")
if ($s.Contains("href: '/marketing'")) { Write-Output 'SKIP  sidebar already patched' } else {
  $a = "  { href: '/mailing', labelKey: 'mailing', icon: Mail, label: 'Mailing' },`n"
  $b = "  { href: '/marketing', labelKey: 'mailing', icon: Target, label: 'Marketing' },`n"
  if (-not $s.Contains($a) -or -not $s.Contains("  Megaphone,`n")) { Write-Output 'ERROR anchor not found' } else {
    $s = $s.Replace($a, $a + $b).Replace("  Megaphone,`n", "  Megaphone,`n  Target,`n")
    [System.IO.File]::WriteAllText($f, $s, (New-Object System.Text.UTF8Encoding($false)))
    Write-Output 'PATCHED sidebar.tsx'
  }
}
```

## Push
```powershell
cd C:\dev\mbg-project
git status -sb
git add src/lib/queries/marketing-segment.ts src/lib/actions/marketing-segment.ts "src/app/(app)/marketing/page.tsx" "src/app/(app)/marketing/marketing-client.tsx" src/components/layout/sidebar.tsx sql/seed_20261010_fcc_mill_outreach_templates.sql docs/handoff
git commit -m "marketing: directory-segment bulk outreach + FCC mill templates"
git push origin marinebiogroup
```
