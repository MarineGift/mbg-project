# Handoff: 라운드 v2 + GCC 스토리 + 시장검증 + 덱수정 (2026-07-10 종료)

## 0. 시스템 컨텍스트
- 플랫폼: URM (Next.js 14 / Supabase), repo MarineGift/mbg-project, branch marinebiogroup, 배포 urm.marinebiogroup.com
- org_id: b25de8f2-1020-482f-9012-183f63883169
- **핵심 결정(오늘): 라운드 = $3M @ $27M pre / $30M post (희석 10%), $30M cap SAFE 방향, 리드 불필요.**

## 1. 라운드 v2 (확정)
- **$3M raise @ $27M pre / $30M post (희석 10%).** 리드 없음 - $3M 규모엔 불필요, 다수 소액 투자자로 채우고 지분 방어. Pangaea는 리드 아닌 참여자로 접근.
- **구조: $30M cap SAFE** (빠른 자금 목표). ⚠️ **주의: answer_library의 discount_rate/deal_terms는 현재 Priced Round 언어("SAFE 해당없음")임. SAFE로 굳히면 SAFE 언어로 되돌려야 함** (미완 - 다음 세션 결정+수정 필요).
- **Use of funds ($3M)**: FCC 적용연구·상용화 $1M (GCC 공정 검증 + 티슈 테스트 중심) / 특허·IP $1M / 운영비 $1M.
- **재무 기본값**: 번 $5K/월, 현금 $50K, 런웨이 10개월. 캡테이블 Heo 51% / Seo 34%, 보통주만.

## 2. GCC 확장 스토리 (밸류 방어의 두 번째 다리)
- FCC는 현재 **PCC 공정**에 적용 가능. **GCC 공정** 생산 기술 개발 완료 + **특허 정규 출원(provisional 아님)**.
- 이번 $3M = GCC 공정 검증 + 티슈 테스트 → 난연벽지·티슈·패키징까지 확장 = **접근 시장 약 5배** (GCC가 PCC보다 볼륨 5~10배, 데이터 지지).
- Valuation 논거: **$27M pre = 검증 로열티 트랙 $22.4M(Y3)의 1.2x + IP 뒷받침 5배 확장 옵션** (두 축).

## 3. 오늘 완료
### answer_library (전부 DB 반영, 일부 레포 미커밋)
- 라운드 v2로 5키 갱신: capital_seeking, deal_terms, use_of_funds, ask_use_of_funds, valuation_rationale (전 variant, en+ko). SQL: `sql/backfill_round_27pre_3raise_2026-07-10.sql`
- GCC 스토리 반영: valuation_rationale/use_of_funds/ask_use_of_funds에 GCC leg 추가 + **`gcc_expansion` 신규 키**. SQL: `backfill_gcc_expansion_story_2026-07-10.sql` ⚠️ **레포 미커밋(다운로드 필요)**
- **`category_positioning` 신규 키** (green-chemistry, FCC 주체+펄프·SAP 대체). SQL: `sql/fix_anzu_greenchem_positioning_2026-07-10.sql`
- **`market_context` + market_size_musd 갱신** (검증 로열티 풀 $10.5-16.8B/yr). SQL: `backfill_market_size_verified_2026-07-10.sql` ⚠️ **레포 미커밋**
- ⚠️ 위생 부채: competitors/uvp/team_management가 variant=short인데 실제 long 길이 (027 마이그레이션 기본값 불일치). 언젠가 variant 재분류.

### 폼 블리츠 진행 상황
| # | 투자사 | 상태 | 비고 |
|---|---|---|---|
| P1 | Azolla | ✅ **submitted** | typeform. 구 $5M 구조로 제출됨 (v2 정정 대상) |
| P2 | CEV/CEVG | drafting (42필드/33프리필) | cevg.com Drupal폼. 미완: Date Founded, Phone(필수), 서술2문항, Climate CO2e. 숫자필드 v2 반영됨 |
| P3 | Breakout | not_started | 6필드 범용 컨택폼. Message용 outreach_blurb 키 필요(미생성) |
| P5 | Anzu | drafting (22필드) | Greenchem 재분류+특허 Granted+포지셔닝 완료. 숫자 v2 반영. **덱 pdf 업로드 필수, CVC 약관 확인 후 제출 가능** |
- Lowercarbon ✅ submitted (구 $5M). 미착수: P4 Toyota, P6 Good Growth, P7 Emerald, P8 CF.

### 덱 시장 데이터 검증 + 수정 (ver5 = ATI 피칭덱, 60슬라이드)
**주의: ver5는 ATI 파트너십 피칭용. $5M Series A IR 덱은 별도 Ver3.0.**
파일: `marinebio_group_Eng_ver5_verified.pptx` (58MB, Drive 업로드 권장). 수정 5슬라이드:
- **43**: GCC $69.1B(2034오기)→$51.1B(2030), PCC $20.8B→$5.4B, 톤수 51-63M→10-25M, **TAM $200B 도넛→$10.5-16.8B/yr 로열티 풀 + 도넛 이미지 교체(응용처별 톤수)**. 도넛 글자 흐림도 고해상도로 수정.
- **80**: Economic Impact $200B → $20.8B/yr (실제 미국 제지 수입 2024)
- **27**: TAM $200B → $10.5-16.8B/yr Royalty Pool
- **38**: Global Market $200B → ~$52B CaCO3 Market
- **40**: "Value" → "End-market" 라벨 명확화, Premium Tissue → Tissue (all grades)
- **핵심 원칙**: $200B는 완제품 시장을 필러 회사 가치로 오용 → 전부 제거, mbg 단위경제(톤당 $350 로열티) 기반 로열티 풀로 통일.
- 검증 리포트: `docs/handoff/2026-07-10/handoff_market_verification_gcc_pcc.md`

### 데이터 정합성 (오늘 확정 컨벤션)
- **폼 status 변경 SQL = form_id/form_url로 조준** (party+status만이면 중복 오폭). 폼 중복 대량 정리 완료.
- **딜 스테이지 이동 = UPDATE만** (deal_stage_history는 라이브 트리거가 기록).
- **프리필 조인 = variant-agnostic pick** (medium→long→short, body_en required).

## 4. 남은 To-do (우선순위)
1. **SAFE vs Priced 최종 확정** → SAFE면 discount_rate/deal_terms를 SAFE 언어로 되돌리는 SQL (현재 Priced 상태).
2. **레포 미커밋 SQL 커밋**: backfill_gcc_expansion_story, backfill_market_size_verified (DB엔 반영됨, 레포엔 없음 - 다운로드+라우터+커밋).
3. **Azolla/Lowercarbon 제출본 라운드 정정**: 구 $5M로 제출됨. 실사 시 구두/이메일 v2 정정.
4. **Pangaea 재접근 메일 발송** (2버전 작성됨: GCC 피벗 + $30M cap SAFE, 리드 없음). 발송 후 딜 스테이지 이동.
5. **P5 Anzu 제출**: 덱 pdf + CVC 약관.
6. **P3 Breakout**: outreach_blurb 키 + 6필드 시딩.
7. **P2 CEV 마무리**: Date Founded/Phone/서술2문항(development_stage·risks_regulation)/Climate CO2e.
8. **IR Ver3.0 덱에 라운드 v2 반영** (ver5 아님 - 그건 ATI용). 파일명 $5M→$3M 갱신.
9. **덱 ver5 slide38/40 텍스트 겹침 정리** (원본부터 있던 레이아웃 문제, 재설계 필요).
10. variant 재분류 (라이브러리 위생).

## 5. 새 세션 킥오프 메시지 (그대로 붙여넣기)
```
URM 폼 블리츠 계속. repo MarineGift/mbg-project(marinebiogroup), org_id b25de8f2-1020-482f-9012-183f63883169.
어제 확정: 라운드 v2 = $3M @ $27M pre / $30M post (희석10%), $30M cap SAFE 방향, 리드 없음. use of funds = FCC적용연구(GCC검증+티슈테스트)$1M/특허$1M/운영$1M, valuation 1.2x + GCC 5배확장(특허 정규출원). answer_library 5키+gcc_expansion+category_positioning+market_context 갱신. 폼: Azolla(P1)+Lowercarbon submitted, CEV(P2)/Anzu(P5) drafting. 덱 ver5(ATI피칭) 시장수치 검증+수정 완료($200B 오용 전부 제거→로열티풀 $10.5-16.8B/yr).
오늘 과제:
1. SAFE 확정시 discount_rate/deal_terms를 SAFE 언어로 되돌리기
2. 미커밋 SQL 커밋 (backfill_gcc_expansion, backfill_market_size_verified)
3. Pangaea 메일 발송 + 딜 스테이지 이동
4. P5 Anzu 제출 (덱pdf, CVC약관)
5. P3 Breakout: outreach_blurb + 6필드
6. P2 CEV 마무리 (Date Founded/Phone/서술2/CO2e)
컨벤션: 폼status=form_id조준, 딜스테이지=UPDATE만(트리거), 프리필=variant-agnostic.
핸드오프: docs/handoff/2026-07-10/handoff_round_v2_gcc_market_deck.md 참조.
```

## 6. 파일 이동 (레포 반영)
라우터:
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
인라인 폴백:
```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "handoff_round_v2_gcc_market_deck*.md" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($src) {
  Unblock-File -LiteralPath $src.FullName
  [System.IO.Directory]::CreateDirectory("C:\dev\mbg-project\docs\handoff\2026-07-10") | Out-Null
  [System.IO.File]::Copy($src.FullName, "C:\dev\mbg-project\docs\handoff\2026-07-10\handoff_round_v2_gcc_market_deck.md", $true)
  Remove-Item -LiteralPath $src.FullName
  Write-Host "MOVED handoff_round_v2_gcc_market_deck.md"
} else { Write-Host "MISS handoff file not found" }
```
마무리 (푸시가 웹 반영):
```
cd C:\dev\mbg-project
git status -sb
git add sql/ docs/
git commit -m "docs: handoff - round v2, GCC story, market verification, deck fixes"
git push origin marinebiogroup
```
⚠️ **git status에서 미커밋 SQL 2개(backfill_gcc_expansion, backfill_market_size_verified)도 함께 있는지 확인 후 add.**
```
