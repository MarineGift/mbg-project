# Handoff: IR 덱 Ver3.1 재구축 + 로열티 단위 정정 (2026-07-11 종료)

## 0. 시스템 컨텍스트
- 플랫폼: URM (Next.js 14 / Supabase), repo MarineGift/mbg-project, branch marinebiogroup, 배포 urm.marinebiogroup.com
- org_id: b25de8f2-1020-482f-9012-183f63883169
- 라운드 v2 (전 세션 확정): $3M @ $27M pre / $30M post (희석 10%), $30M cap SAFE 방향, 리드 불필요.
- 이번 세션 산출물: IR 덱 `Marinebio_IR_Ver3_1_SeriesA_3M.pptx` (37슬라이드) + SQL 2개.

## 1. 이번 세션 핵심 결정

### 1-1. 로열티 단위 오류 정정 (⚠️ 가장 중요)
- **덱이 정답**: 로열티 = FCC 가격 $250-350/톤의 3-5% = 약 **$10/톤**. (검산: Y3 $22.4M / 2.24M t = 정확히 $10/t.)
- **오류 원인**: 전 세션 answer_library 백필(그리고 오늘의 refined story 초안)이 "톤당 $350 로열티"로 기재. ver5 덱의 "Royalty Pool $10.5-16.8B/yr"도 30-48M t x $350로 계산된 값. $350는 가격(제지사 절감액)이지 로열티가 아님.
- **올바른 단위 사슬**: 가격 $250-350/t -> 로열티 3-5% (~$10/t) -> FCC 가치 풀 $10.5-16.8B/yr (30-48M t x 가격) -> 로열티 풀 $0.3-0.8B/yr (가치 풀의 3-5%).
- **정정 SQL**: `fix_royalty_unit_economics` (아래 3-2). ⚠️ 파일명 날짜가 07-10 또는 07-11일 수 있음(재생성분) - 내용 동일. Downloads/레포에서 실제 파일명 확인. Supabase 미실행 가능성 있으니 실행 여부 확인 필요.

### 1-2. GCC 배수 표현 확정
- "6배" 단정 금지 (소스에 따라 1.3x~9x로 요동). **"약 5-10배 + 소스 페어 명시"** 로 통일: GCC $51.1B vs PCC $5.4B by 2030 (Grand View Research).
- 또는 로열티 풀 중심으로 배수 논쟁 우회 (전 세션 원칙 유지).

### 1-3. 로열티 마진 표현
- "순수익(net profit) 80%" -> **"로열티 매출총이익률(gross margin) 80%+"** 로 표기 (회사 전체 net margin과 혼동 방지).

### 1-4. 특허 표현
- 정규 출원 2023-07-12 + 7개국 개별국(national phase) 진입. 덱/폼에서 "filed"와 "granted" 명확히 구분. Anzu 폼에 "Granted" 기재분은 실제 등록건과 출원건 혼재 여부 재확인 필요 (실사 리스크).

### 1-5. Why Texas 슬라이드 배포 정책 (질문 답변)
- **텍사스 외 투자자에게도 빼지 말고 그냥 발송.** 위치는 Appendix 맨 끝(현재 37번) 유지.
- 근거: 부록 맨 끝의 Why Texas는 "US 리쇼어링 + 자본 효율" 근거로 읽혀 어느 미국 투자자에게나 플러스. 부록은 안 맞으면 안 넘기면 그만이라 존재가 마이너스가 되지 않음. 슬라이드 톤도 특정 투자자 배제 신호 없음(오히려 "US 투자자 중심" 명시).
- **파일 두 벌 관리 금지** (버전 지옥). 한 벌 발송 + 텍사스 로컬(CTAN/Capital Factory)엔 커버레터에서 Why Texas 언급해 끌어올림. 특수 케이스(예: 유럽 전용 펀드) 발생 시 그때 1장 삭제본 즉석 생성.

## 2. IR 덱 Ver3.1 구조 (37슬라이드 = 본편 18 / Backup 12 / Appendix 6+1)

### 본편 (1-18)
1 표지 · 2 Traction · 3 Ulsan 시너지 · 4 Paper Problem · 5-6 Solution(구조/원리) · 7 Competition · 8 Market Size · 9 Tissue(커머셜 핵심) · 10 Two Tracks · 11 Carbon & Water · 12 Business Model · **13 Why now: years->months(신규)** · **14 The Ask $3M** · **15 What $3M delivers(신규)** · **16 Why $27M** · 17 Team · 18 Vision

### Backup (19 디바이더 + 20-31)
19 **Backup 디바이더**(목차: IP&특허모트 / 기술&라이선시경제성 / 보류피치슬라이드) · 20 Patent Portfolio · 21 Category · 22 3층 특허 · 23 Forensic Detection · 24 Prior Art · **25 Data: FCC vs GCC(신규)** · 26-27 SMI/Omya 프로필 · 28 Plastic Problem · 29 Sponge Mechanism · 30 Go-To-Market · **31 Licensee economics(신규)**

### Appendix (32 Life Science + 33 디바이더 + 34-37)
32 Life Science(前 라벨오류 "APPENDIX"->수정) · 33 **Appendix 디바이더**(목차: Market GCC vs PCC / FCC응용 / Why Texas) · **34 Market: GCC vs PCC(신규,정정본)** · 35 Paper Applications · 36 Packaging/Bio · **37 Why Texas(신규)**

### 이번 세션 신규/수정 슬라이드 (전부 IR 덱 스타일로 재구축, ver5 이식 아님)
- **14 The Ask**: $5M->$3M, $27M pre/$30M post, use of funds 3분할(FCC R&D:GCC검증+티슈 / 특허·IP:7개국 / 운영), Excluded박스 "GCC route 5-10x, $51.1B vs $5.4B(GVR)". 발표노트 전면 재작성.
- **15 What $3M delivers (신규)**: 에어비앤비 7/14p 오마주 3원 플로우 $3M -> 2.24M t -> $22.4M/yr. 중간 원에 "validated track" 딱지(가정 아닌 계약 기반 강조). 하단 마일스톤 스트립 + 로열티 단위 각주.
- **16 Why $27M**: 1.3x->1.2x, "$30M discount"->"$27M".
- **13 Why now (신규)**: 왜 13년 걸렸나(파일럿 인프라 부재 + $2-3M/day 리스크 + 과학은 계속 전진) -> US 대학 파일럿(WMU/Maine/USC)으로 13년->13개월, 12x faster. "신규 응용처 몇 달 만에 검증·라이선싱" 메시지.
- **25 Data (신규)**: ver5 25/26 실측 재구축. Bulk+20%/Tensile+20%/Stiffness유지/Smoothness유지, 최대필러로딩 15-30% vs 60%=2x. DOI 10.3390/ma16082978.
- **31 Licensee economics (신규)**: ver5 33 CAPEX Hack. 표준그라인더/유지비90%↓/처리량5x/제로설비, 전용MFC $5-10M vs FCC $1-2M = CAPEX 80%절감.
- **34 Market GCC vs PCC (신규, 정정본)**: ver5 43의 "Royalty Pool $10.5-16.8B" 오류 제거 -> "FCC 가치풀 $10.5-16.8B(라이선시 매출)"과 "로열티풀 $0.3-0.8B(~$10/t)" 2막대 분리. "Y3 $22.4M은 로열티풀의 ~3-7%, 무리한 점유율 가정 없음" 보너스 논거.
- **37 Why Texas (신규)**: Gulf Coast원료/텍사스코튼하이브리드/제지인프라/Port of Houston·Whole Foods. 우측 "Already on the ground"=Capital Factory 오스틴 입주+US투자자중심, US제지수입 $20.8B 리쇼어링. K-C·Whole Foods 로고 대신 텍스트 언급(파트너십 오해 방지).
- **디바이더 목차 정합**: 19 Backup/33 Appendix 디바이더 목차를 실제 슬라이드 순서와 일치하게 재작성. 30 라벨오류(APPENDIX->Life Science) 수정.

### 의도적으로 넣지 않은 것
- 라이프사이언스 상세(ver5 88-99): 이번 라운드는 FCC. Vision(18)이 그 역할.
- 제지사 커밋 슬라이드(ver5 76-78): 파트너명 노출 NDA 리스크, 대면 구두가 안전.
- ver5 102 "Nature's Wisdom": 마케팅 톤이 로열티 산수 IR 덱과 충돌. 텍사스 코튼 스토리는 Why Texas에 흡수.

## 3. 이번 세션 SQL (레포 반영 필요)

### 3-1. backfill_gcc_story_refined_2026-07-10.sql (전 세션 커밋됨, DB 반영 확인됨)
- gcc_expansion/valuation_rationale 덮어쓰기 + royalty_economics/gtm_platform 신규.
- ⚠️ 단, royalty_economics/valuation_rationale의 "톤당 $350 로열티" 표현이 오류 -> 3-2가 정정.

### 3-2. fix_royalty_unit_economics_2026-07-11.sql (⚠️ Supabase 실행 + 커밋 필요)
- valuation_rationale: "톤당 350달러 가격에 3-5% 로열티" 로 정정.
- royalty_economics: 가격->로열티->가치풀->로열티풀 단위 사슬 명시.
- "로열티 풀" 표현 전수 리라벨("FCC 가치 풀") + CEV/Anzu 재동기화.
- VERIFY 1 = 0행이어야 정상(톤당 $350 로열티 잔존 없음).
- Supabase Editor 세이프 검증 완료(문자열 내 세미콜론·SQL키워드 0).

## 4. 남은 To-do (우선순위)
1. **fix_royalty_unit_economics SQL Supabase 실행** + VERIFY 1 = 0행 확인.
2. **git push 완료 확인**: 전 세션 curl 56으로 push 실패 이력. `git status -sb`에 [ahead N] 남았는지 확인 후 재push. fix SQL도 함께 커밋.
3. **ver5 (ATI 피칭덱) 동일 오류 정정**: slide 43 "royalty at $350/ton", "1% = $105-168M/yr royalty"(실제 ~$10/t, ~$3-8M/yr). ATI 미팅 전 필수. IR 덱 34번을 기준 삼아 수정.
4. **SAFE vs Priced 최종 확정** (전 세션 이월): SAFE면 discount_rate/deal_terms를 SAFE 언어로 되돌리는 SQL.
5. **Azolla/Lowercarbon 제출본 정정**: 구 $5M 구조로 제출됨. 실사 시 v2 + 로열티 단위 함께 구두/이메일 정정.
6. **폼 블리츠 재개**: P5 Anzu(이 덱 PDF로 제출 가능, CVC약관 확인) · P3 Breakout(outreach_blurb 키+6필드) · P2 CEV 마무리(Date Founded/Phone/서술2/CO2e).
7. **Pangaea 재접근 메일 발송** (2버전 작성됨) + 딜 스테이지 이동.
8. variant 재분류 (라이브러리 위생): valuation_rationale가 variant=short만 존재. competitors/uvp/team_management도 short인데 실제 long.

## 4-1. 라운드 전략 결정: Series A 단독 (2026-07-11 확정)
- **결정: Series A $3M 단독 진행. Seed 투자사 대상 브릿지($100-200K) 병행 안 함.**
- 근거:
  1. **Seed 경제학 불성립**: $27M pre에서 $150K = 지분 약 0.5%. Seed 투자자는 초기 리스크 대가로 5-15% 기대 -> 0.5%는 펀드 모델 자체가 성립 안 됨. "위험은 Seed급, 밸류는 Series A급"이라 리스크-리워드 역전. 설득이 아닌 산수의 문제.
  2. **시그널 리스크**: $3M Series A 자료와 $100-200K 브릿지 자료 동시 발송 시 "$3M 못 채워 연명" 신호. "리드 불필요, 다수 소액으로 채운다"는 $3M 전략과 브릿지가 겹쳐 혼란.
  3. **밸류 정합성**: 낮은 캡 브릿지 -> Series A 투자자가 "왜 나만 비싸게" 반발. 같은 캡 -> Seed가 "브릿지인데 왜 같은 가격" 반발.
- **타겟팅 함의**: Seed 투자사는 처음부터 고객군 아님. $27M pre(검증 로열티 트랙 1.2x + GCC 확장)를 인정하는 Series A/성장 단계 투자자만 접촉.
- **미래 재검토 조건**: 런웨이 방어로 소액이 급해질 경우에만, 기존 Seed사에 낮은 캡/디스카운트 SAFE로 소액($200K 이하)만, Series A와 시간 분리해 접근. 단 SAFE 확정이 선결(To-do #4). 현시점은 급전 불필요로 판단 -> 보류.

## 5. 컨벤션 (유지)
- 폼 status 변경 = form_id/form_url로 조준(party+status만이면 중복 오폭).
- 딜 스테이지 이동 = UPDATE만(deal_stage_history는 라이브 트리거 기록).
- 프리필 조인 = variant-agnostic pick (medium->long->short, body_en required).
- 덱 편집: python zipfile + markitdown + LibreOffice headless + pdftoppm. 편집 후 validate.py --original 필수. 텍스트런 단위 str.replace(유니크 검증). 막대차트는 실제 수치 비율로.

## 6. 새 세션 킥오프 메시지 (그대로 붙여넣기)
```
URM IR 덱 + 폼 블리츠 계속. repo MarineGift/mbg-project(marinebiogroup), org_id b25de8f2-1020-482f-9012-183f63883169.
확정: 라운드 v2 = $3M @ $27M pre/$30M post, $30M cap SAFE 방향, 리드 없음. IR 덱 = Marinebio_IR_Ver3_1_SeriesA_3M.pptx (37슬라이드, 본편18/Backup12/Appendix6+1).
로열티 단위 정정 완료(덱): 로열티 = 가격 $250-350/t의 3-5% = ~$10/t. FCC 가치풀 $10.5-16.8B/yr vs 로열티풀 $0.3-0.8B/yr 구분. "$350 로열티"는 오류(그건 가격).
GCC 배수 = "약 5-10배 + 소스페어(GCC $51.1B vs PCC $5.4B by 2030 GVR)". 특허 = 정규출원 2023-07-12 + 7개국. 마진 = 로열티 gross margin 80%+.
라운드 전략 = Series A $3M 단독 확정(2026-07-11). Seed 브릿지 병행 안 함(Seed는 $27M에 지분 0.5%라 경제학 불성립).
오늘 과제:
1. fix_royalty_unit_economics SQL Supabase 실행(VERIFY 1 = 0행) + 커밋
2. git push 완료 확인(전 세션 curl56 실패 이력)
3. ver5(ATI덱) slide43 로열티 단위 정정 (IR덱 34번 기준)
4. P5 Anzu 제출(이 덱 PDF) / P3 Breakout / P2 CEV 마무리
5. SAFE 확정시 discount_rate/deal_terms SAFE 언어로
컨벤션: 폼status=form_id조준, 딜스테이지=UPDATE만, 프리필=variant-agnostic, 덱편집=validate.py --original 필수.
핸드오프: docs/handoff/2026-07-11/handoff_ir_deck_ver31_2026-07-11.md 참조.
```

## 7. 파일 이동 (레포 반영)
라우터:
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
인라인 폴백 (핸드오프 md):
```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "handoff_ir_deck_ver31_2026-07-11*.md" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($src) {
  Unblock-File -LiteralPath $src.FullName
  [System.IO.Directory]::CreateDirectory("C:\dev\mbg-project\docs\handoff\2026-07-11") | Out-Null
  [System.IO.File]::Copy($src.FullName, "C:\dev\mbg-project\docs\handoff\2026-07-11\handoff_ir_deck_ver31_2026-07-11.md", $true)
  Remove-Item -LiteralPath $src.FullName
  Write-Host "MOVED handoff_ir_deck_ver31_2026-07-11.md"
} else { Write-Host "MISS handoff file not found" }
```
인라인 폴백 (fix SQL - 아직 이동 안 했으면):
```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "fix_royalty_unit_economics_2026-07-11*.sql" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($src) {
  Unblock-File -LiteralPath $src.FullName
  [System.IO.Directory]::CreateDirectory("C:\dev\mbg-project\sql") | Out-Null
  [System.IO.File]::Copy($src.FullName, "C:\dev\mbg-project\sql\fix_royalty_unit_economics_2026-07-11.sql", $true)
  Remove-Item -LiteralPath $src.FullName
  Write-Host "MOVED fix_royalty_unit_economics_2026-07-11.sql"
} else { Write-Host "MISS fix SQL not found" }
```
마무리 (푸시가 웹 반영):
```
cd C:\dev\mbg-project
git status -sb
git add sql/ docs/
git commit -m "docs: handoff IR deck ver3.1 + royalty unit fix (2026-07-11)"
git push origin marinebiogroup
```
⚠️ **git status에서 전 세션 미푸시 커밋(724db92 등)이 [ahead N]으로 남아있는지 확인 후 push.** 덱 pptx는 레포가 아닌 Drive/로컬 보관 대상.
