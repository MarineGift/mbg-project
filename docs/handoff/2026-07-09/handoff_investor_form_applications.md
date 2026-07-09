\xEF\xBB\xBF# Handoff: 투자사 폼 등록 실행 + 제지사 공급업체 포털 조사 (2026-07-10)

## 0. 시스템 컨텍스트
- 플랫폼: URM (Next.js 14 / Supabase), repo MarineGift/mbg-project, branch marinebiogroup, 배포 urm.marinebiogroup.com
- org_id: b25de8f2-1020-482f-9012-183f63883169
- 연락채널 3-상태 규약: preferred_contact_method가 null=미조사, 'email'=조사완료 폼없음, 'web_form'/'portal'=폼있음(contact_form_url 필수)
- 현재 DB 상태 (2026-07-09 마감): web_form 31 + portal 6 + email 8 = 45곳 판정 완료. Capital Factory 중복 merge 완료 (KEEP a01fd96a-d89d-4234-a9a2-e9af45b847a6)
- UI 워크플로우: Party 상세 -> Applications 패널 -> New from template -> form_type 선택(application 15필드 / accelerator 11 / grant 9 / contact_inquiry 5) -> answer_library 자동 바인딩(pickVariant가 글자수 제한에 맞는 variant 선택) -> 에디터에서 Copy next로 순차 클립보드 복사 -> 외부 폼에 붙여넣기
- Supabase SQL 규칙: 문자열에 세미콜론/작은따옴표/독립 SQL 키워드 금지, name-matched idempotent UPDATE 패턴

## 1. 내일 등록 우선순위 (폼/포털 37곳 중 상위)
| # | 파티 | URL | 비고 |
|---|---|---|---|
| 1 | CTAN | Dealum (진행 중) | 마감 7/26 (D-16). 지원비 없음, 클로징 시 admin fee만 |
| 2 | Baylor Angel Network | Dealum | $25-250K 체급 최적 |
| 3 | First Bight Ventures | firstbight.com | 휴스턴 바이오매뉴팩처링, BioWell 13,000L 파일럿. Capital Factory 공식 협력 -> CF 커뮤니티 매니저에게 웜인트로 병행 요청 |
| 4 | SWAN Impact Network | Dealum | 오스틴 임팩트 엔젤 |
| 5 | Lowercarbon Capital | lowercarbon.com/building/ | 웜인트로 불필요 명시, industrial materials 논제 |
| 6 | Azolla Ventures | azollaventures.com/contact-us/ | 기가톤 CO2e 논제 = CaCO3 스토리 정합 최고 |
| 7 | Clean Energy Ventures | cleanenergyventures.com/investment-application/ | 100% 심사 보장, CEVG 엔젤 포함 |
| 8 | Breakout Ventures | breakout.vc/contact | 폼 실제로 다 읽는다고 명시. Modern Meadow/Ecovative 포트폴리오 = 바이오소재 직접 겹침 |
| 9 | Toyota Ventures | toyota.ventures/submit-pitch.html | Frontier(materials) + Climate(탄소) 양 트랙 |
| 10 | Anzu Partners | anzupartners.com/company-questionnaire/ | 산업기술/소재 4대축 |
| 11 | Good Growth Capital | goodgrowthvc.com/contact | Advanced Materials 명시 투자영역 |
| 12 | Emerald Technology Ventures | emerald.vc/entrepreneurs | Materials and Packaging 공식 섹터, 기업 LP 50+를 첫 고객 연결 |
| 13 | Capital Factory | info.capitalfactory.com/ventures-application | 입주 멤버 - 내부 채널 병행 |
- 주의(Applied Ventures): 제출물 전부 non-confidential 조항 -> 특허 공개분 수준만, 노하우 제외
- 보류: Cradle to Commerce(모집 마감 + DOE 외국인심사 6개월+), PepsiCo Greenhouse(APAC/알럼나이), mHUB(현 코호트 부적합), In-Q-Tel(요건 미달), HAN(라운드 하한 미달)
- 시민권/영주권 지분 요건 확인 필요: NSF SBIR, Chain Reaction Innovations, Innovation Crossroads (캡테이블 Heo 51% / Seo 34% 기준 적격성)

## 2. 등록 전 필수 입력값 (사용자 제공 대기)
1. 덱 URL (deck_url)
2. 월 번레이트 (burn_rate)
3. 런웨이 개월수 (runway_months)
-> 받으면 seed_answer_library_form_extras.sql 생성 (+cap_table_summary, ghg_reduction_estimate). placeholder 시딩 금지.

## 3. 등록 중 발견사항 처리 루프
- 템플릿에 없는 질문 발견 -> canonical_key 추가 시딩
- 글자수 초과 필드 -> 트리밍. 기존 초과 8건: ip_portfolio(3302>3000), risks_mitigations(2338>2300), valuation_rationale(1591>1500), use_of_funds(1017>1000), uvp(819>800), founder_experience(656>650), team_family_relationships(84>80) + 1건
- answer_library 중복 variant 4쌍(problem/solution/business_model/traction)은 pickVariant가 처리 - 정상

## 4. 잔여 조사 큐 (등록 틈틈이)
- 미조사 투자자 ~10곳: Cantos, Piva Capital, Playground Global, Obvious Ventures, Circulate Capital 등
- Q~Z 구간 export 미확보: Supabase에서 재export 시 반드시 "No limit" 선택 (이전 export가 100행 컷). Solvay, SK, Umicore 등 대기

## 5. [새 세션 과제] 제지사 공급업체 등록 포털 조사 (10곳)
목표: 글로벌 제지사 중 supplier/vendor registration 포털을 운영하는 곳 10곳을 찾아 투자자와 동일한 방식으로 DB에 마킹.
- 마킹 규약(동일): preferred_contact_method='portal'(Ariba/Coupa/Jaggaer 등 조달 시스템) 또는 'web_form'(자체 폼), contact_form_url=등록 URL. 조사했는데 없으면 'email'.
- 우선 후보(파티명은 DB 기준 확인 필수 - ilike 진단 먼저): International Paper, WestRock(Smurfit Westrock), Georgia-Pacific, Kimberly-Clark, P&G(티슈 공장 6곳 등록됨 - 본사 파티에 마킹), Sappi, UPM, Stora Enso, Mondi, Oji, Nippon Paper, Suzano, Domtar, Sofidel, Essity
- 산출물: enrich_mill_supplier_portals_batch1.sql (name-matched idempotent, org_id 동일)
- 전략 노트: 공급업체 포털 등록은 투자 피치가 아니라 벤더 온보딩 경로. MBG 포지션 = 충전제/섬유 소재 공급업체(9,000톤 Omya 오더 트랙션 인용). NDA 요구 시 90_NDA_PRIVATE 폴더 규약 사용.

## 6. 새 세션 킥오프 메시지 (그대로 붙여넣기)
```
URM 플랫폼 작업 계속. repo MarineGift/mbg-project(marinebiogroup), org_id b25de8f2-1020-482f-9012-183f63883169.
어제 투자자 연락채널 전수조사 45곳 완료(web_form 31/portal 6/email 8), Capital Factory 중복 merge 완료.
오늘 과제: 글로벌 제지사 중 공급업체(supplier/vendor) 등록 포털이 있는 곳 10곳을 조사해서 투자자와 동일한 3-상태 규약으로 마킹해줘.
- 마킹: preferred_contact_method='portal' 또는 'web_form' + contact_form_url, 없으면 'email'
- 먼저 파티명 진단: International Paper, WestRock, Georgia-Pacific, K-C, Sappi, UPM, Stora Enso, Mondi, Suzano, Domtar 등을 ilike로 확인하는 쿼리부터 줘
- 산출물: enrich_mill_supplier_portals_batch1.sql (name-matched idempotent, Supabase 에디터 규칙 준수)
- 포지셔닝: MBG는 충전제/섬유 소재 공급업체로 벤더 등록 (9,000톤 오더 트랙션)
핸드오프 문서: docs/handoffs/handoff_investor_form_applications.md 참조.
```

## 7. 파일 이동 (레포 반영)
라우터 사용 (권장):
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
인라인 폴백 (라우터 실패 시 붙여넣기):
```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "handoff_investor_form_applications*.md" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($src) {
  Unblock-File -LiteralPath $src.FullName
  [System.IO.Directory]::CreateDirectory("C:\dev\mbg-project\docs\handoffs") | Out-Null
  [System.IO.File]::Copy($src.FullName, "C:\dev\mbg-project\docs\handoffs\handoff_investor_form_applications.md", $true)
  Remove-Item -LiteralPath $src.FullName
  Write-Host "MOVED handoff_investor_form_applications.md"
} else { Write-Host "MISS handoff file not found" }
```
마무리 (푸시가 웹 반영):
```
cd C:\dev\mbg-project
git status -sb
git add docs/handoffs/handoff_investor_form_applications.md
git commit -m "docs: handoff for investor form applications + mill supplier portal sweep"
git push origin marinebiogroup
```
