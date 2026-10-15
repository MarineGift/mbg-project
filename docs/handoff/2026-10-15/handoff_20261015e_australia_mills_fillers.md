\xef\xbb\xbf# Handoff 2026-10-15 (e) — 호주 제지공장·필러 업데이트

> 앞 문서: `handoff_20261015d_laos_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261015e_australia_mills_fillers.sql` | 필러 2사, 밀 6곳(없을 때), 소개·메모, plant 블록 8 |

batch / source: `australia_update_20261015` · 메모 표식 `AU check 2026-10-15`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: Omya Australia (Bathurst GCC + 과거 Moss Vale·Bajool·Geelong — Geelong 습식 GCC 이력 중요), Imerys Burnie (과거 7만 t GCC, Burnie 제지공장 2010-06 폐쇄 — 이력 보존). 호주 제지용 PCC 공장 없음. Sibelco·MTI 호주(비제지) 제외
- Mill profile 우선순위: 1 Boyer (2025-04 Norske Skog → Boyer Capital, 26만 t 인쇄계, 2026 복사용지 진출 — **시나리오**) · 2 ABC Tissue (Wetherill Park PM1, Carole Park 2대) · 3 Arbex Millicent (Suzano 51 / K-C 49, 2026-07 출범, 구조개편 검토) · 4 Solaris Paper (Box Hill·Greystanes, APP 파트너) · 5 Visy Tumut (크라프트라이너 68만 t) · 6 Opal Botany (재생 42만 t)
- 참고(있을 때만): Opal Maryvale (2023 백색지 중단), Encore Tissue

## 3. 판단
- 호주 백색지 PCC 수요는 Maryvale 전환 후 축소 — Boyer 복사용지·티슈가 직접 기회, Visy·Opal 포장용지는 후순위
- Arbex(MY Kluang·이스라엘 K-C 와 연결), Solaris(APP) 는 글로벌 확장 통로

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015e_australia_mills_fillers.sql docs/handoff
git commit -m "data: Australia fillers (Omya) + mills (Boyer, ABC Tissue, Arbex, Solaris, Visy, Opal) + intros + plant profiles"
git push origin marinebiogroup
```
