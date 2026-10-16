# Handoff 2026-10-15 (l, m) — 미결 확인 프로브 + 멕시코 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261015k_country_market_ai_links.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/scan_20261015l_pending_and_mx_probe.sql` | 읽기 전용 — k 마이그레이션(컬럼·제약·링크 수), IL/JO/LB 시드 결과, Lebanese Calcium Carbonate 중복, 기존 MX 행 |
| `sql/seed_20261015m_mexico_mills_fillers.sql` | 필러 8, 밀 20(없을 때), 배경 밀 8(있을 때만 갱신), plant 블록, 공급 링크 1, `app.country_markets` MX 행 |

batch / source: `mexico_update_20261015` · 메모 표식 `MX check 2026-10-15`

## 2. 이름 가드 (멕시코는 기존 행이 많음)
- 밀: `country_code = 'MX'` 이고 `party_name ~* name_rx` **또는** (`city ~* city_rx` **그리고** `party_name ~* owner_rx`)
  - 같은 도시 복수 밀 구분: San Juan del Río (Ponderosa / KCM), Orizaba (Scribe / KCM), Monterrey (Essity / Smurfit)
  - Smurfit 은 `(smurfit|westrock|gondi)` — 구 Gondi 행도 같은 그룹으로 매칭
- 필러: `party_type_id = 3` 에서 `party_name ~* guard_rx` (국가 무관) — 새 이름이 자기 가드에 걸리는지 생성기에서 확인함

## 3. 반영
- **필러**: Omya México (공장 4·Cuautitlán Izcalli 실험실, 라이선시) · Specialty Minerals Anáhuac (Pondercel 위성 PCC 기록, 가동 미확인, 라이선시) · Terrazo (Torreón) · Reverté Durango (2026 지분 과반 매각) · ICC · ATSA · ONIC (슬러리·약품, 시험 채널) · LEDSA
  - 제외: Carbonato de Calcio Sol, QR Minerales, HSL (생산 미확인), Calidra (석회), IDQ Cuautitlán PCC (2005 자료) — LEDSA notes 에 기록
- **밀 / 우선순위**: 1 Pondercel · 2 Scribe (Orizaba, 백상지 설비 위치 확인 필요) · 3 Cartones Ponderosa 24만 t · 4 Papel San Francisco 27만 t 목표 · 5 KCM 6개 사이트 · 6 Essity Monterrey 8만·Sahagún 9.5만·Uruapan 4만 t · 7 Convertipap 12.5만 t 목표 · 8 Smurfit Cerro Gordo·Guadalajara (백판지 라인)
  - Smurfit Monterrey·San Pablo·Los Reyes·SLP: 능력만 (2025 연차보고서), 우선순위 없음
  - 배경(있을 때만): Greenpaper, Grupak, Softys, Grupo Corporativo Papelera, Papeles Ultra, Industrial Papelera San Luis, Copamex Industrias, Papelera Chihuahua
- **FCC 시나리오** (Base = 보고서 예시, 가동 100%): Ponderosa 5% 12,000 t · Cerro Gordo 4,400 t · Guadalajara 5,500 t · Essity 3% 합 6,450 t → 28,350 t / 로열티 $425,250
- **공급 링크**: SMI Anáhuac → Pondercel (historical / medium)
- **시장현황**: MX 행 upsert (priority high, headline_ko·summary_ko·FCC 28,350 t)
- 웹사이트는 essity.com, smurfitwestrock.com 만 입력 (나머지 미확인으로 비움)

## 4. 적용
1. Supabase: scan_l 실행 → CSV 업로드 (미결 1·2번 확인)
2. Supabase: seed_m 실행 → 결과 CSV 업로드 (MISSING 행·중복 확인)
3. 이동 · 커밋

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/scan_20261015l_pending_and_mx_probe.sql sql/seed_20261015m_mexico_mills_fillers.sql docs/handoff
git commit -m "data: Mexico fillers + mills + country market row, pending-checks probe"
git push origin marinebiogroup
```

## 5. 남은 미결
- 위 프로브 결과 (k 마이그레이션, IL·JO 결과, Lebanese Calcium Carbonate 중복)
- 제재국 마케팅 제외 패치 결정, Market 탭 sections_ko, CountryPeersPanel 컬럼 정리, fix_20260919c untracked, 필리핀 BOI 밀
- 완료 국가 37 (+MX)
