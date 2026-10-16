# Handoff 2026-10-15 (s) — 캐나다 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261015r_timorleste_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261015s_canada_mills_fillers.sql` | 필러 3, 밀 14(없을 때) + 배경 13(있을 때만), plant 블록, 공급 링크 2, `app.country_markets` CA 행 |

batch / source: `canada_update_20261015` · 메모 표식 `CA check 2026-10-15`

## 2. 반영
- **필러**: Omya Canada Perth (Tatlock Quarry, 94명) · Omya Canada Saint-Armand (농업용 돌로마이트 — 제지 등급 미확인) · Specialty Minerals (Canada) (2025 10-K 캐나다 공장 4곳)
  - 폐쇄 PCC: Cornwall (2006), Dryden (2008, 3만 t), Omya(구 Huber) Prince Albert (4.2만 t, 2006) — 메모에만
  - 석회 업체(Graymont, Carmeuse, 퀘벡 채석장) 추가 안 함
- **밀 / 우선순위**: 1 Domtar Windsor (64.2만 short t — 단위 short_t 로 저장, 탭에서 미터톤 환산) · 2 Irving Paper SC 20.5만 t · 3 Kruger Wayagamack 26만 t · 4 Kruger Products Crabtree 9.2만 t · 5 Cascades Tissue Kingsey Falls · 6 Kruger Products Gatineau·Lennoxville·Sherbrooke LDC·New Westminster, Cascades Candiac·Lachute, Irving Tissue · 7 Kruger Products Sherbrooke TAD · Sustana Saint-Jérôme (우선순위 없음, 가동 확인)
  - 배경(있을 때만): Domtar Alma·Dolbeau·Kénogami·Clermont(22.1만 t)·Gatineau·Port Alberni, Kruger Trois-Rivières(52만 t)·Corner Brook(25만 t), White Birch Stadacona·Masson·Soucy, Atlantic Packaging Whitby·New Forest
- **FCC Base** (보고서 시나리오 85% × 5%): Windsor 24,753 t · Irving 8,713 t · Wayagamack 11,050 t · Kruger Products 6라인 17,425 t (티슈 5% 는 미검증) → 61,940 t
- **공급 링크**: SMI → Windsor, SMI → Sustana Saint-Jérôme (둘 다 historical / medium, 2004 SEC 기록)
- **시장현황**: CA 행 high, FCC 44,516 ~ 61,940 t
- 가드 겹침 수정: Kruger Trois-Rivières 배경 가드가 Wayagamack 를 잡지 않도록 `(?!.*wayagamack)` — 생성기에 전체 가드 교차검사 추가

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015s_canada_mills_fillers.sql docs/handoff
git commit -m "data: Canada fillers + mills + country market row"
git push origin marinebiogroup
```

## 4. 완료 국가 39 (+CA). 결과 대기: TH(o), CA(s)
