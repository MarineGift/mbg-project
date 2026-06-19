# REPORT - Investor Introduction (Deep Tech) 2026-06-15
## 요약
- 대상: `sectors.label_en = 'Deep Tech'` 태깅 투자사 49곳.
- 그중 **26곳은 Advanced Materials 배치에서 이미 intro 작성됨**(intro는 party 단위 → 두 섹터에 자동 노출). 따라서 이 파일은 **신규 23곳**만 처리.
- Priority: 적합도 높은 **5곳을 `high`**로 승격. 나머지는 기본 `medium` 유지.
- 파일: `sql/seed_investor_intro_deep_tech.sql` (UTF-8 **BOM 없이**, 멱등 UPDATE, self-resolving name join, intro_en ASCII-only).

## Priority = high (5곳)
적합 근거: 소재과학/산업 deep tech, 산업 발효·바이오리파이너리, 물리적 산업 제조 재건.

- 8090 Industries
- Data Collective Venture Capital (DCVC)
- Eclipse Ventures
- Ecliptic Capital
- Khosla Ventures LLC

## medium 유지 (18곳) - 근거
Accel, Amplify, Bain Capital Ventures, Boost VC, Founders Fund, Gigafund, Intel Capital, Kleiner Perkins, M12(Microsoft), Mayfield, NFX, Qualcomm Ventures, Samsung NEXT, Section 32, Sutter Hill, Trust Ventures, USV, Valhalla.
- 대부분 SW/엔터프라이즈/AI/핀테크/반도체 제너럴리스트 또는 CVC로, mbg의 해양 바이오소재(하드웨어/소재)와 **직접** 적합도가 낮음. 단 Samsung NEXT는 삼성 그룹 전략 접점, Valhalla/Section 32/Boost는 소재·바이오 일부 관심으로 코멘트 반영.

## 이미 처리됨(중복 태깅 26곳, 재작업 불필요)
ARCH, Anzu, Applied Ventures, Azolla, BASF VC, Breakout, Creative Ventures, Diamond Edge, First Bight, GM Ventures, In-Q-Tel, KdT, Lux, Material Impact, Mitsui, Pangaea, Phoenix VP, Piva, Prime Movers Lab, SOSV, Safar, Saint-Gobain NOVA, Scout, Sumitomo/Presidio, The Engine, Toyota Ventures.

## 검증 출처(예시)
- 각 firm 공식 홈페이지/보도자료(dcvc.com, eclipse.vc, 8090industries.com, khoslaventures.com, ecliptic.capital 등) 및 보도/프로필.
- 사실 위주(포커스/HQ/전략)로만 작성, 추측 배제.

## 다음 배치
- **Life Science** 58행. 상당수가 Adv/Deep과 중복 태깅(First Bight, KdT, Safar 등)이라 신규만 추출해 동일 포맷으로 생성 예정.
