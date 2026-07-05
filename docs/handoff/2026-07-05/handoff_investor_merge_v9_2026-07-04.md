# Handoff — 투자사 병합 v9 (스키마 검증 완료, 최종) (2026-07-04)

## probe #66으로 실제 스키마 확정 → 추측 제거
이전 에러(portfolio_company_id 등)는 제가 컬럼명을 추측해서였습니다. probe #66이 24개 자식 테이블의 실제 unique/PK를 보여줘, 정확히 재분류:

| 분류 | 테이블 | 근거 |
|---|---|---|
| **1-per-party** | account_scores, filler_supplier_profile, paper_mill_profile, lead_scores, party_profiles | UNIQUE/PK가 party_id 단독(또는 org+party) |
| **composite** | paper_mill_paper_types(+paper_type_id), contacts(+linkedin_url) | party FK + 다른 컬럼 유니크 |
| **plain** | 나머지 18개 (investor_portfolio_companies, deal_*, engagement_participants, meeting_attendees, meetings, engagements, deals, party_supply_links 양쪽 등) | **PK(id)만** 또는 party 무관 유니크 → 충돌 없음, 단순 재지정 |

핵심: 대부분 테이블이 PK(id)만이라 재지정에 충돌이 없었고, 실제 dedup 필요한 건 7개뿐이었습니다.

## v9 특성 (v8 구조 유지)
- do-block/temp table/BEGIN 없음 (Supabase 편집기 호환)
- 31쌍 = 인라인 CTE, 문장별 반복, 각 self-contained + 멱등
- soft-delete만, canonical 정보 보충 + 태그/sector 합집합
- **컬럼명 전부 실제 스키마 기반** (portfolio_company_id 등 추측 제거)

## 실행
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
→ Supabase에서 `fix_investor_merge_31pairs_v9.sql` **select-all + Run** → 마지막 SELECT `merge_still_active=0, canonical_active=31`

## 기대
- 0 / 31, 디렉토리 554 → 523
- contacts Nino Marakovic는 Sapphire Ventures 사본만 잔존

## Finish
```powershell
cd C:\dev\mbg-project
git add sql/ docs/ ; git commit -m "chore(db): investor dedupe merge v9 (schema-verified classification, 31 pairs)" ; git push origin marinebiogroup
```

## 다음
검증 통과 시 Paper Mills / Filler Suppliers 중복 (동일 probe→병합).
