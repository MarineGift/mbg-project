# REPORT - Investor Introduction (Life Science) 2026-06-15
## 요약
- 대상: `sectors.label_en = 'Life Science'` 태깅 투자사 58곳.
- 제외: 이전 배치에서 이미 intro 작성된 4곳(Emergent Technologies, First Bight, KdT, Safar) + 기존 intro 보유 S3 Ventures = 5곳. → 이 파일은 **신규 53곳** 처리.
- Priority: **2곳만 `high`** (Genoa Ventures, 8VC). 나머지 51곳은 `medium` 유지.
- 파일: `sql/seed_investor_intro_life_science.sql` (UTF-8 **BOM 없이**, 멱등 UPDATE, self-resolving join, intro_en ASCII-only).

## 적합도 판단 (중요)
이 섹터의 투자사 대부분은 **신약·치료제·메드테크·헬스케어 크로스오버** 펀드입니다. mbg는 해양 바이오소재(종이/포장/화장품용 기능성 필러)로 **소재·소비자 바이오** 사업이므로, 치료제 중심 펀드와는 직접 적합도가 일반적으로 낮습니다. 따라서 각 intro에 적합도를 **정직하게** 표기했습니다(과장 금지).

### Priority = high (2곳) — 드문 강한 적합
- **Genoa Ventures** — 생물×기술 융합. 합성생물·산업바이오·**consumer bio**·agri/food bio 등 **치료제 외** 영역 집중. mbg 비치료제 바이오소재와 정합.
- **8VC** — 멀티스테이지(약 $7B). 상업용 합성생물 소재(예: Bolt Threads)·산업 영역 투자 이력. mbg 바이오 소재·산업 생산과 부합.

### 일부 인접성(코멘트 반영, medium 유지)
- Alexandria(agrifood/지속가능), Sofinnova Partners US(산업바이오 전략 이력), Northpond(플랫폼/도구/엔지니어링 바이오), Foothill/New Science/Dimension(deep tech·과학 기반), Civilization(합성생물) — 결은 닿으나 핵심 포커스가 치료제/헬스케어라 medium.

### 나머지(치료제·헬스케어 중심, 직접 적합도 낮음)
5AM, Avalon, Avoro, Baker Bros, Bain Capital LS, Bios, Boxer, Casdin, Catalio, Column Group, Cormorant, Cure, Decheng, Deep Track, EcoR1, Frazier, Green Park & Golf, Hatteras, Health Wildcatters, Lightstone, Logos, Longitude, MPM BioImpact, Mubadala, New Leaf, Omega, Perceptive, RTW, Redmile, SV Health, Samsara, Sanderling, Sante, Sofinnova Investments, SpringRock, TEXO, TMCi, Venture Investors, Vesalius, Vida, Vivo, Westlake Village, aMoon, venBio.

## 검증 출처(예시)
- 각 firm 홈페이지/프로필(genoavc.com, 8vc.com, civilizationventures.com 등). 사실 위주(포커스/HQ)로만 작성, 추측 배제.

## 전체 진행 현황 (3개 섹터)
- Advanced Materials 50곳(high 23) + Deep Tech 신규 23곳(high 5) + Life Science 신규 53곳(high 2) = **고유 firm 126곳 intro 완료**(이미 보유 2곳 제외).
- 세 SQL 파일은 모두 멱등 UPDATE → 함께/반복 실행 안전. 실행 후 검증 쿼리로 priority 분포 확인 권장.
