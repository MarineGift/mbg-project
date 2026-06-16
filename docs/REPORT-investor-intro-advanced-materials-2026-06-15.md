# REPORT - Investor Introduction (Advanced Materials) 2026-06-15
## 요약
- 대상: `sectors.label_en = 'Advanced Materials'` 태깅 투자사 51곳.
- 처리: 50곳에 `intro_ko` / `intro_en` 작성 (홈페이지+웹서치 검증). `Chevron Technology Ventures`는 기존 intro 보유로 제외.
- Priority: 적합도 높은 **23곳을 `high`**로 승격. 나머지는 기본 `medium` 유지.
- 파일: `sql/seed_investor_intro_advanced_materials.sql` (UTF-8 **BOM 없이** 저장됨, 멱등 UPDATE, self-resolving name join).

## 실행 방법
1. Supabase SQL Editor(UTF-8)에서 `seed_investor_intro_advanced_materials.sql` 전체 실행.
2. 하단 검증 쿼리로 priority 분포와 intro 채움 현황 확인.
3. 화면: party Overview의 Introduction 카드 + `/investor/parties` Priority 컬럼/필터에서 확인.

## Priority = high (23곳)
적합 근거: 소재과학 전문 VC, 바이오제조/합성생물, 펄프·제지·포장 전략투자(CVC), 순환경제/포장, 화장품 응용, 해양/블루이코노미.

- 3M Ventures
- Anzu Partners
- At One Ventures
- BASF Venture Capital
- Breakout Ventures
- Circulate Capital
- Closed Loop Partners
- Diamond Edge Ventures
- Emerald Technology Ventures
- First Bight Ventures
- KdT Ventures
- Material Impact Partners
- P&G Ventures
- Pangaea Ventures
- Phoenix Venture Partners
- Prime Movers Lab
- Regeneration.VC
- S2G Ventures
- SOSV
- Saint-Gobain NOVA
- Suzano Ventures
- The Engine Ventures
- Unilever Ventures

### 특히 강한 적합(bullseye)
- **Suzano Ventures** - 세계 최대 펄프 생산사 CVC. 유칼립투스 바이오소재·지속가능 포장 투자. mbg 종이/포장 필러와 직결.
- **Pangaea Ventures / Material Impact / Anzu / Phoenix VP** - advanced materials 전문 VC.
- **BASF VC / Diamond Edge(Mitsubishi Chemical) / Saint-Gobain NOVA** - 소재·화학 대기업 CVC, 가치사슬 시너지.
- **First Bight / SOSV(IndieBio) / KdT** - 바이오제조·합성생물 기반 소재.

## 검증 출처(예시)
- 각 투자사 공식 홈페이지 및 보도자료(예: pangaeaventures.com, materialimpact.com, anzupartners.com, suzanoventures.com, diamondedgeventures.com, firstbight.com, phoenix-vp.com, s2gventures.com).
- 사실 위주(포커스 영역/HQ/전략)로만 작성, 추측 배제. 미검증 수치는 제외.

## 다음 배치 (남은 작업)
- **Deep Tech** 49행, **Life Science** 58행 (중복 태깅 포함, 고유 128곳 중 Advanced Materials 처리 후 잔여).
- 다수 firm은 Advanced Materials와 중복 태깅이라 intro는 party 단위로 1회만 작성하면 두 섹터에 동시 반영됨(intro는 party 컬럼).
- 동일 포맷(self-resolving UPDATE + priority UPDATE + 검증)으로 이어서 생성 예정.
