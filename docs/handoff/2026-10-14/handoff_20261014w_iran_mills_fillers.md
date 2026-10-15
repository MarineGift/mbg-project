\xef\xbb\xbf# Handoff 2026-10-14 (w) — 이란 제지공장·필러 (기록 전용, 제재로 보류)

> 앞 문서: `handoff_20261014v_afghanistan_mills_fillers.md` (실행·푸시 완료)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014w_iran_mills_fillers.sql` | 필러 7사, 밀 12곳(없을 때), 소개·메모, plant 블록 12 — 전부 ON HOLD |

batch / source: `iran_update_20261014` · 메모 표식 `IR check 2026-10-14`

## 2. 제재 처리
- **미국 대이란 제재(OFAC)** — MBG 는 미국 법인. 모든 plant 블록 approach = `ON HOLD ... no contact, NDA, samples, licence or royalty until a sanctions lawyer clears it`
- outreach priority 미설정 (기술 순위는 approach 문장에만), 연락처 이메일 저장 안 함, FCC 시나리오·링크 없음
- **후속 권고**: 마케팅 세그먼트(`src/lib/queries/marketing-segment.ts`)가 현재 archived·`MBG Pulp Only` 만 제외 → 이란(IR) 등 제재국 행이 "전체 제지공장" 캠페인에 포함될 수 있음. 제재국 국가코드 하드 제외 패치 필요

## 3. 반영
- 필러: Chemie Ma-Dani Hamadan (PCC·GCC), Pars Hasti Asia (PCC·나노 PCC), Arman Powder Lorestan (제지용 GCC), Arosha, MAD KOOHZAD, Farayand, Arya Powder Pars — 제외: Poudresazan, Iran Kaolin & Barite
- 밀: Mazandaran (1), Pars Paper (2), Dibaye Shushtar (3), Zarrin Barg (4), Pars Hayat (5), Latif (6), Harir Khuzestan (7), Golpoune (8), Aryan Cellulose (9), Zagros Fars (10, 미가동), Chooka (11), Kaveh (12) — 제외: Pars Tamin 스톤페이퍼

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014w_iran_mills_fillers.sql docs/handoff
git commit -m "data: Iran fillers + mills (record only, on hold - US sanctions)"
git push origin marinebiogroup
```
