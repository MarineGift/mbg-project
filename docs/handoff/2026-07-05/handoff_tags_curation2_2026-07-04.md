# Handoff — 태그 큐레이션 2차 (최종) (2026-07-04)

## 파일
`sql/fix_interest_tags_curation2.sql` — 마지막 정리 패스 (멱등):
1. 승격 3종: `generalist`(제너럴리스트 ← tech 17건 등), `diversity_focus`(다양성 포커스 ← women_led/female_founders), `non_dilutive`(비희석 자금 ← royalty_based/**sbir_sttr** — SBIR 트랙과 연계 가치)
2. 별칭 ~36개: oceans→ocean_blue_economy, sustainable_chemistry/ingredients→specialty_chemicals, semiconductors/iot/wireless→hardware, health_tech/healthcare_it→healthcare, defense_tech/national_security→defense_space, cvc_platform→cvc 등
3. 병합 재실행
4. **usage 0 고아 태그 삭제** — gcc/pcc/limestone/filler_supplier 등은 공급사 레거시 어휘가 태그 행만 만들고 링크가 없던 것 (필요 시 자동 재생성됨)
5. 최종 리포트 — 남는 1건짜리 지역/메타 태그(texas, midwest, leadership 등)는 그대로 둬도 무방

## 실행
1. 다운로드 → `powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1`
2. Supabase Run → (5) 리포트 확인

## Finish block

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/fix_interest_tags_curation2.sql docs/
git commit -m "feat(db): interest tag curation pass 2 - final folds, drop usage-0 orphans"
git push origin marinebiogroup
```
