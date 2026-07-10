\ufeff# Handoff: Series A 전환 + 폼 블리츠 준비 완료 (2026-07-10)

## 0. 시스템 컨텍스트
- 플랫폼: URM (Next.js 14 / Supabase), repo MarineGift/mbg-project, branch marinebiogroup, 배포 urm.marinebiogroup.com
- org_id: b25de8f2-1020-482f-9012-183f63883169
- **오늘의 핵심 결정: 라운드를 $100K SAFE에서 $5M Series A @ $30M pre ($35M post)로 전환. Series A 단일 트랙, 엔젤은 폴백.**

## 1. 오늘 완료 (2026-07-10)
### 라운드/덱/아웃리치
- 덱 V3.0 확정: `Marinebio_IR_Ver3_0_SeriesA_5M.pptx` (30슬라이드). 슬라이드 18 = $5M Series A ask ($2.0M 생산 스케일업 / $1.5M US 검증 / $1.5M IP+운영), 슬라이드 19 = $30M pre 논리 (Y3 로열티 $22.4M의 1.3x, 로열티 5-15x 거래). 경쟁사 실명(Omya/Imerys/SMI) 유지 - 공개정보. 파트너 언급은 전부 익명.
- 원칙: **덱/서면 = 파트너 실명 금지 ("world's top filler maker"), 구두 = 실명 가능.** 경쟁사 맥락 실명은 OK.
- 덱 URL: https://drive.google.com/file/d/1alGPNW-LafjgszrRkj0ATkQ86bFy7GNN/view?usp=drive_link (공유설정 "링크 소지자 뷰어" 확인 필요)
- First Bight: Collin이 덱 요청 (폼 제출 -> 인바운드 전환 성공 사례). 답장 최종본 작성됨 (FCC=펄프대체 프레임, 파트너 익명). CF 커뮤니티 매니저 웜인트로 병행 예정.
- Pangaea 재접근 메일 최종본 작성됨 (거절 사유였던 체급 미스매치가 Series A 전환으로 소멸 - "당신 조언대로 재구성했다" 프레임).
- Lowercarbon 폼 작성 (Tell us more 텍스트 제공됨). ⚠️ "carbon removal?" 체크박스는 해제 권고 (FCC는 저감이지 removal 아님).
- **미확인: Collin/Andrew 메일 발송 여부, Lowercarbon SHIP IT 여부** -> 다음 세션에서 확인, 발송됐으면 CRM 스테이지 이동.

### answer_library (완성됨)
- 라운드 키 9개 Series A 갱신: capital_seeking, deal_terms, use_of_funds, valuation_rationale, already_raised, discount_rate, company_one_liner(196자), ask_use_of_funds, cost_structure. drafting 폼 final_text 동기화 완료. 라벨(title) 3개 정리.
- 신규 시딩: deck_url, burn_rate($5K/mo, asset-light 프레임), runway_months(10개월 = $50K/$5K, 로열티 상쇄 언급).
- ⚠️ **body_ko는 여전히 SAFE 시절** - 한국계 투자자 폼 전에 갱신 필요.
- created_by NOT NULL 주의: SQL 에디터 INSERT 시 기존 행에서 created_by 복사하는 패턴 사용.

### 플랫폼 수정 (전부 배포됨)
- **RLS 대형 버그 수정**: 7개 테이블 정책이 최상위 JWT 클레임(auth.jwt() ->> 'organization_id')을 읽어 INSERT 전부 거부되던 것을 app.current_organization_id()로 교체. 대상: application_forms, application_form_fields, application_field_answers, answer_library, email_signatures, investor_interest_tags, deal_close_reasons(정책명 close_reasons_org_isolation). **교훈: 새 테이블 정책은 반드시 app.current_organization_id() 패턴.**
- API 라우트 3개 requireAuth() 전환 (getUser().app_metadata는 hook 주입 org가 안 보임): from-template, fields/[fieldId], answer-library.
- 폼 에디터 개편: form_type 분기 - **Angel Form**(application/accelerator/grant/pitch_event) = 9섹션 탭 (Company/Problem/Solution/Market/Business Model/Competition/Traction/Team/The Ask), **Company Form**(contact_inquiry) = 3탭 (Company/Product/Commercial). 탭별 카운트 + 빨간 이슈 배지. Copy next가 해당 탭 자동 전환. 반응형 + max-w-[1700px] + xl 2열 그리드 + 답변 textarea 자동확장(최대 28줄).
- page.tsx가 application_forms.form_type을 조회해 에디터에 전달.
- 알려진 부채: `npx tsc --noEmit`은 기존 에러 15개로 실패 (내 패치와 무관, next build는 통과). 언젠가 정리.

### DB 데이터
- 제지사 공급업체 포털 15/15 판정 (portal 9 / web_form 6). HQ 파티 신규: Kimberly-Clark Corporation, Nippon Paper Industries Co., Ltd. 기록: supabase/enrich/enrich_mill_supplier_portals_2026-07-10.sql

## 2. 폼 블리츠 큐 (다음 세션 메인 과제)
현재 drafting 3건: Lowercarbon(제출 직전), 3M Ventures, 1955 Capital(한국 브리지 - body_ko 갱신하면 유리).
다음 등록 순서 (전부 web_form, Series A 체급):
1. Azolla Ventures - azollaventures.com/contact-us/ (기가톤 CO2e 논제)
2. Clean Energy Ventures - cleanenergyventures.com/investment-application/ (100% 심사 보장)
3. Breakout Ventures - breakout.vc/contact (바이오소재 포트폴리오 직접 겹침)
4. Toyota Ventures - toyota.ventures/submit-pitch.html (Frontier+Climate 양 트랙)
5. Anzu Partners - anzupartners.com/company-questionnaire/
6. Good Growth Capital - goodgrowthvc.com/contact (Advanced Materials 명시)
7. Emerald Technology Ventures - emerald.vc/entrepreneurs (기업 LP 50+ 고객 연결)
8. Capital Factory Ventures - info.capitalfactory.com/ventures-application (입주멤버 내부채널 병행)
- 보류(엔젤 폴백): CTAN(Dealum, 마감 7/26 - 계정만 유지), Baylor, SWAN
- 주의: Applied Ventures = 제출물 전부 non-confidential. 3M Ventures도 CVC라 약관 확인 필요.
- 시민권/지분 요건 확인 대기: NSF SBIR, Chain Reaction, Innovation Crossroads

## 3. 재무 기본값 (확정)
- 라운드: $5M Series A @ $30M pre / $35M post
- 번레이트: $5,000/월 | 보유현금: $50,000 | 런웨이: 10개월
- 트랙션: 9,000톤 오더 실행 중 @ $350/ton 로열티 자동 발생, ~10,000톤 추가 진행, Y3 로열티 $22.4M (validated track)
- 캡테이블: Heo 51% / Seo 34%, 보통주만, 전환증권 없음

## 4. 새 세션 킥오프 메시지 (그대로 붙여넣기)
```
URM 폼 블리츠 계속. repo MarineGift/mbg-project(marinebiogroup), org_id b25de8f2-1020-482f-9012-183f63883169.
어제: Series A 전환($5M @ $30M pre) 완료, answer_library 갱신 완료(burn $5K/runway 10mo/deck_url 포함), RLS 7테이블 수정, 에디터 Angel 9탭 개편. drafting 3건(Lowercarbon/3M/1955 Capital).
오늘 과제:
1. 발송 확인 처리: First Bight(Collin) 답장 + Pangaea(Andrew) 재접근 메일 + Lowercarbon SHIP IT -> 제출된 것 Mark as submitted + CRM 스테이지 이동 SQL
2. 폼 블리츠: Azolla -> Clean Energy Ventures -> Breakout -> Toyota -> Anzu -> Good Growth -> Emerald -> CF Ventures 순서로 폼 생성/제출
3. body_ko 라운드 키를 Series A로 갱신 (1955 Capital용)
핸드오프: docs/handoffs/handoff_series_a_form_blitz.md 참조.
```

## 5. 파일 이동 (레포 반영)
라우터:
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
인라인 폴백:
```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "handoff_series_a_form_blitz*.md" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($src) {
  Unblock-File -LiteralPath $src.FullName
  [System.IO.Directory]::CreateDirectory("C:\dev\mbg-project\docs\handoffs") | Out-Null
  [System.IO.File]::Copy($src.FullName, "C:\dev\mbg-project\docs\handoffs\handoff_series_a_form_blitz.md", $true)
  Remove-Item -LiteralPath $src.FullName
  Write-Host "MOVED handoff_series_a_form_blitz.md"
} else { Write-Host "MISS handoff file not found" }
```
마무리 (푸시가 웹 반영):
```
cd C:\dev\mbg-project
git status -sb
git add docs/
git commit -m "docs: handoff - Series A conversion complete, form blitz ready"
git push origin marinebiogroup
```
