# Marinebio IR Deck — Handoff (2026-07-13)

## 현재 최신 파일 (이 세션 종료 시점)
- **`Marinebio_IR_ColdDeck_v5.pptx`** (15장) — 콜드 아웃리치 최신. Pretendard 통일 + 탄소 슬라이드 + SEM 커버 반영
- **`Marinebio_IR_ColdDeck_v5.pdf`** — 발송용 (폰트 임베드, 메타데이터 정리 완료)
- **`Marinebio_IR_Ver3_21.pptx`** (40장) — 풀덱 최신. Ver3_20에서 **폰트 통일 + docProps 메타데이터 수정만** 반영 (콘텐츠 변경 없음)
- 덱은 **Drive/로컬 보관** 대상 (mbg-project repo 아님) → mover/git 불필요
- 다음 세션 시작 시 사용자가 최신 pptx를 업로드하면 그것이 기준. (사용자가 PowerPoint에서 직접 수정하는 경우가 많음 — 항상 diff로 변경점 먼저 파악할 것)

## 회사/라운드 요약 (변동 없음)
- Marinebio Group Inc. — FCC(Flexible Calcium Carbonate) 종이 충전제, 펄프 대체
- 라이선스 → 로열티 모델. Round: **$3M @ $27M pre / $30M post**, $30M cap SAFE
- 확정 핵심 숫자(전 슬라이드 정합): 로열티 5-10% / 대표 $15/ton, Y1/Y2/Y3 = $4.4M/$12.3M/$33.6M (0.29/0.82/2.24M t), 밸류 $27M = 0.8× Y3 royalty, SOM ~1.6M t, 필러 25-30M t (GCC ~5× PCC), 로열티풀 $93-112M/yr
- 소통: 한국어(논의) + 영어(덱/코드)

## ColdDeck v5 (15장) 구성
Cover → Traction → **Carbon & Water Impact** → Problem → Breakthrough → Competition → Market Size → Two Tracks → Business Model → Royalty Math → Sales Weapon → Domino → What $3M Delivers → Why $27M → Team

- 탄소 슬라이드는 기후 펀드 대응용으로 사용자가 3번 위치에 삽입 (Traction 직후 = 확정 9,000t 물량 기준 임팩트 환산 구조. 위치 검토 완료, 유지 권장)
- 커버(사용자 수정 + Claude 보완): FCC SEM 현미경 이미지(우측), F·C·C 이니셜 레드 강조, 크레딧 라인 "A **patent moat no one can design around** — validated by **the world's top filler giants under NDA**." (2줄, 대시가 2행 머리)
- **커버 미결 제안**: SEM 이미지 좌하단 장비 타임스탬프(2019년 날짜) 크롭 권장 — 스케일바(100 µm)는 유지

## 이번 세션(2026-07-13)에 완료한 작업
1. **ColdDeck v2** (12장): Ver3_20에서 재추출 (sldIdLst 트림 → clean.py → 페이지번호 캐시 갱신 → viewProps 깨진 참조 수정)
2. **v3 검토** (14장, 사용자가 Royalty Math + Sales Weapon 추가): 발송 전 QA 통과. NDA 익명화 전수검사(본문+노트) — 실명+NDA 동일 슬라이드 동반 0건
3. **PDF 메타데이터 문제 발견/해결**: pptx docProps에 `Multi-page HTML Content` / `Visual Extract to PPTX Converter` 잔존 → PowerPoint PDF 내보내기마다 복사됨 (Chrome 탭 제목에 노출!). **근본 수정: v4부터 docProps/core.xml을 직접 수정** → 이후 내보내기 자동 클린. Ver3_21에도 적용됨 (`Marinebio Group - FCC Series A` / `Marinebio Group Inc.`)
4. **v4**: 커버 크레딧 라인 추가
5. **v5 + Ver3_21: Pretendard 전체 폰트 통일**
   - 교체 대상: Montserrat, Inter, Roboto, Calibri(+Light), Arial, Times New Roman, Noto Sans 계열, 맑은 고딕, Segoe UI, Ebrima, Estrangelo Edessa 등 → 전부 `Pretendard`
   - **의도적 유지**: Wingdings, Segoe UI Symbol (체크마크·아이콘 글리프 깨짐 방지). "Pretendard ExtraBold"도 그대로 둠
   - theme1.xml majorFont/minorFont latin+ea+cs → Pretendard (테마 script 폰트 리스트는 미변경)
   - 교체 수: 콜드덱 889곳, 풀덱 2,811곳. 전 슬라이드 렌더 QA 통과 (오버플로 없음)

## PDF 생성 워크플로 (중요)
- **사용자 PC(PowerPoint) 내보내기 = 1순위** (폰트 완벽). docProps 수정됐으므로 메타데이터도 자동 클린
- **샌드박스(LibreOffice) 변환 시**: 폰트 미설치면 글자 깨짐 → 반드시 폰트 먼저 설치:
  - Pretendard: `curl -sL -o p.zip https://github.com/orioncactus/pretendard/releases/download/v1.3.9/Pretendard-1.3.9.zip` → `public/static/*.ttf`를 `~/.fonts/`로 → `fc-cache -f`
  - Montserrat/Roboto/NotoSans: `github.com/google/fonts/raw/main/ofl/<name>/...ttf` (Pretendard 통일 후엔 Pretendard만으로 충분)
- PDF 메타데이터 수동 수정 필요 시: `pikepdf` (`pip install pikepdf --break-system-packages`), docinfo는 **open_metadata 컨텍스트 종료 후에** 설정해야 XMP에 안 덮임
- PPTX 외부 공유 시: PowerPoint "파일에 글꼴 포함" 옵션 권장 (Pretendard = OFL, 임베드 합법)

## NDA 익명화 상태
- 실명(Omya/SMI/MTI/Imerys) + "NDA" **같은 슬라이드 동반 = 0건** (본문·발표노트 전수검사 완료)
- 실명 허용 맥락: Competition(경쟁 비교), Market Size 출처, Sales Weapon 예시, Domino 출처 라인 — 모두 NDA 문구 없는 슬라이드
- **잔여 리스크(사용자 인지/수용)**: Domino 슬라이드 출처의 "MTI ~50% of satellite PCC" ↔ Why $27M의 "Two giants under NDA — 40-50% of satellite PCC" 교차 추론으로 파트너 특정 가능. 공개 데이터 출처라 컨벤션상 통과. 더 보수적으로 가려면 출처에서 실명 제거 옵션 있음

## 덱 편집 컨벤션 (누적)
- pptx 작업 전 `/mnt/skills/public/pptx/SKILL.md` 필독
- 워크플로: zipfile extractall → slideN.xml 편집(unique str.replace) → 디렉토리 안에서 `rm -f ../out.pptx && zip -Xrq ../out.pptx .` → `validate.py OUT --original ORIG` → soffice pdf + pdftoppm 렌더 QA
- 슬라이드 삭제 순서: presentation.xml `<p:sldIdLst>` 트림 → `clean.py` → slidenum 캐시 갱신(`type="slidenum"` 필드의 `<a:t>` 값) → **viewProps.xml의 outline-view `<p:sldLst>` + viewProps.xml.rels의 삭제 슬라이드 참조 제거** (validate가 잡아줌)
- 새 도형/텍스트 추가 시 defusedxml.minidom.parseString으로 well-formed 검증. xml.etree 라운드트립 금지
- 6자리 hex만 유효. 커버 등 Pretendard 런 추가 시 rPr에 latin+ea+cs 3종 typeface 모두 지정
- 팔레트: navy 1F3864/203864, blue 2E5496/4472C4, teal 5B9BD5, green 548235/385723, red C0392B, orange ED7D31, bg DCE6F5/EAF1FB/EAF2E2/FFF4E6/FDECEC
- 발표노트 = 영어 스크립트 [한국어 훅/전환 + 영어 본문]
- 사용자가 PowerPoint로 수정한 파일은 markitdown 텍스트 diff + XML diff로 변경점 파악 후 작업 (이번 세션에서 사용자 수정: SEM 이미지, FCC 레드 이니셜, 탄소 슬라이드 삽입)

## 미해결 / 다음 세션 후보 작업
1. **SEM 커버 이미지 타임스탬프 크롭** (권장, 5분 작업)
2. **Ver3_21 (40장) 사용자 육안 검수 대기** — 폰트 통일 후 이상 슬라이드 있으면 번호 받아서 수정
3. **풀덱에도 커버 크레딧 라인/SEM 반영 여부** — 현재 콜드덱(v5)에만 있음. 풀덱 커버는 구버전 상태
4. Q&A 방어 문서 (2026-07-12 핸드오프의 미해결 4항목: 수익성 방어, 3년 타임라인, 라운드 구조, 로열티율 하향 여지) — 아직 미착수
5. 클라이밋 펀드용 콜드 이메일 초안 + URM 타겟 리스트 매칭 (탄소 슬라이드 추가의 후속 작업으로 자연스러움)

## 버전 히스토리 (전체)
Ver3_11 → … → **Ver3_20**(2026-07-12, 발송준비) → **Ver3_21**(폰트 통일+메타데이터, 콘텐츠 동일)
ColdDeck_v1(12장, 3_15 기준) → **v2**(12장, 3_20 기준 재추출) → **v3**(14장, +Royalty Math/Sales Weapon, 사용자) → **v4**(+커버 크레딧 라인, 메타데이터 근본수정) → **v5**(15장, +탄소 슬라이드/SEM 커버(사용자) + Pretendard 통일, 최신)
