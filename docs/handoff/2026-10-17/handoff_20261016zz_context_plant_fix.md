# Handoff 2026-10-16 (zz) — 생성기 수정: 배경(context) 행 plant 블록 덮어쓰기 방지 + 점검 스캔

> 앞 문서: `handoff_20261016zy_germany_mills_fillers.md`

## 1. 발견한 문제
독일 시드 SQL 을 다시 보니, 3) PLANT BLOCKS 의 update 가 **배경(context, 생성 안 하고 메모만 다는) 행**에도
`extra_data || jsonb_build_object('plant', 새 블록)` 을 적용 → 기존 plant 블록 전체가 `{owner, products, approach, checked_at}` 로 **교체**됨.
예전 시드나 import 에서 priority·capacity·fcc·grades 가 들어 있던 행이면 그 키들이 사라짐.
- 주 대상(create=True) 행은 교체가 의도된 동작 (예: BG Belovo 우선순위 제거) → 그대로 둠
- 영향 범위: 2026-10-14 ~ 10-16 국가 시드 중 실행된 것들의 배경 행. paper_mill_profile 에 이력(audit) 없음

## 2. 수정 (gen.py)
- plant values 에 `ctx` 플래그 추가 (배경 행 = true)
- 배경 행: `새 블록 || 기존 블록` → **기존 키가 우선**, 없는 키만 추가
- 주 대상 행: 지금처럼 교체
- `seed_20261016zy_germany_mills_fillers.sql` 을 수정된 생성기로 **다시 만듦** (같은 파일명 — 아직 실행 전이면 이걸로 교체, 이미 실행했으면 다시 실행해도 안전)

## 3. 점검 스캔 (읽기 전용)
| 파일 | 내용 |
|---|---|
| `sql/scan_20261016zz_context_plant_overwrite.sql` | plant 블록이 owner/products/approach/checked_at 4개 키뿐인 밀 행 중, 이번 국가 시드가 만든 행이 아닌 것 목록 (국가·이름·source·생성일·키 목록) |

- 결과에 priority·capacity 가 있었어야 할 행이 보이면 → 그 행을 처음 만든 시드를 다시 실행하면 원래 블록 복구 (시드는 idempotent, 메모는 표식으로 한 번만)
- 원래 plant 블록이 없던 행도 함께 나옴 → source·생성일로 구분

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zy_germany_mills_fillers.sql sql/scan_20261016zz_context_plant_overwrite.sql docs/handoff
git commit -m "seed gen: context rows merge plant block instead of replacing; scan for overwritten blocks"
git push origin marinebiogroup
```

## 5. 다음 파일 접미사
zza, zzb ...
