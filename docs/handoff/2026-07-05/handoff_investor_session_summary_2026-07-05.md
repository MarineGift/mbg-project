# Handoff — Investor 트랙 전체 세션 요약 & 다음 세션 시작점 (2026-07-05)

## 이 세션에서 완료된 것 (전부 DB 반영 + 커밋 완료)

### 1. 투자사 중복 병합 — 31쌍
- 디렉토리 party 554 → 523
- canonical = 간결한 통용명(Accel, Sequoia Capital, a16z, DCVC, Dallas Venture Capital 등)
- 제외: 5AM Ventures vs II(별개 펀드), ICONIQ Growth vs Capital(별도 비히클)
- 최종 실행본: `sql/fix_investor_merge_31pairs_v9.sql` (검증 0/31 통과)
- 매핑: `investor_merge_map.csv`
- **핵심 교훈(메모리 #14 기록)**: Supabase SQL Editor는 do-block/temp-table/BEGIN을 별도 실행으로 쪼갬 → `_merge` temp table이 사라져 42P01. 해결책 = do-block/temp/BEGIN 없이 31쌍 매핑을 **인라인 CTE로 문장마다 반복**하는 순수 정적 SQL. 자식 테이블은 probe #66(실제 unique/pk)로 확인해 1-per-party / composite / plain 3분류.

### 2. Sector focus 정규화 (Interest Tags와 동일 방식)
- Sector focus를 자유텍스트 `<Input>` → 정규화 체크박스 피커 `<TagMultiSelect>` + Add-new
- 4개 파트 전부 배포됨:
  - `sql/fix_sync_sector_focus_rpc_v2.sql` — `sync_party_sector_focus(party_id, codes[])` RPC. **v2 이유**: app.sectors.id가 auto-default 아님 → id를 max+row_number로 명시 부여 (v1은 23502 null 에러)
  - `src/lib/queries/sector-focus.ts` — `fetchSectorOptions()`
  - `patch_sector_focus_normalized.ps1` — party-form.tsx(Input→TagMultiSelect), new/edit page(옵션 로드+전달), actions/parties.ts(create+update 시 sync RPC 호출)
- 커밋: 3ddc637, faee253 등 / 모두 push 완료

### 3. Sector 카탈로그 보강
- `sql/fix_sectors_catalogue_backfill.sql` — app.sectors 15→27개 (life_science=16 등 실사용 코드 정식 등록)
- 실행 확인: id 1~27, life_science 포함

### 4. Investor 시드 2건
- **wave7** (`sql/seed_investor_korea_us_backers_wave7.sql`): 한국 투자이력 미국 투자사 4곳 — Ribbit Capital, General Atlantic, TPG, The Carlyle Group
- **wave8** (`sql/seed_investor_ca_ny_wave8.sql`): CA/NY 딥테크 7 + 생명과학 5 = 12곳
  - 딥테크: Point72 Ventures(H), True Ventures(H), 645 Ventures, Great Oaks, Contour, Primary, Base10 → deep_tech, industrial
  - 생명과학: LifeSci Venture Partners, LifeX Ventures, Novo Holdings(H), Sands Capital, SR One → life_science
  - 검증 통과: 12곳 전부 sector_focus + interest_tags 정규화 코드 일치
  - 멱등(이름/도메인 dedup) — 방금 병합한 canonical들과 재충돌 없음

## ★ 이번에 발견한 Supabase 파서 함정 (메모리 #14, 재발 방지 필수)
1. **문자열 내 `;`** → 문장 종결로 오인. intro/notes에 세미콜론 금지, `—`나 `,` 사용
2. **문자열 내 `into`** → `INSERT INTO <table>`로 오인 (ERROR 42P01 relation "<다음단어>" does not exist). intro에 standalone `into` 금지, `toward` 등으로 우회. from/join/where/select 등 다른 bare 키워드도 위험 가능
3. **do-block/temp-table/BEGIN** → 별도 실행으로 쪼갬. 인라인 CTE 반복 방식 사용
→ 앞으로 모든 seed intro는 이 단어들을 피해서 작성

## 다음 세션에서 이어갈 열린 과제

### (A) Sector 전체 정규화 — 가장 큰 미완 과제
현 상태: sectors 카탈로그는 27개로 정비됐으나, **기존 investor들의 sector는 여전히 legacy `investor_profile.sector_focus` text[]에 정규화 안 된 변종으로 존재** (probe 결과: healthcare 95, deep_tech 84, life_science 80, ... + 대소문자/언어/표기 변종 200+개: AI/ai, deeptech/deep tech/딥테크, materials/첨단 소재 등).
- 필요 작업 (interest_tags 정비와 동일 패턴):
  1. `app.sector_aliases` 테이블 생성 (alias → canonical code), interest_tag_aliases 미러
  2. 변종 200+개를 27개 canonical로 매핑하는 alias 시드 (AI→ai, deeptech→deep_tech, 첨단소재→advanced_materials, healthcare→healthcare 등)
  3. 기존 investor 전체를 `sync_party_sector_focus`로 backfill → investor_sector_focus 링크 생성
  4. sync RPC를 alias-aware로 업그레이드 (현재는 slug만, alias 해석 추가)
- sort_order 중복도 정리 (life_science=95, sustainability·food_ag=120 등 겹침)

### (B) 기타 대기 항목
- Paper Mills / Filler Suppliers 중복 조사 (investor와 동일 probe→병합 프레임, v9 방식 재사용)
- Batch 9 contact enrichment T2 (~59 firms, 우선 wave2/3 high 13) — Pangaea 후속 아웃리치용
- Pangaea Ventures (Andrew Haughian) 7/8 미팅 — deal First Meeting stage

## 참고 (반복된 실무 이슈)
- 브라우저가 Downloads에 **구버전 파일**을 남겨 mover가 옛 파일을 이동 → 반복 실패. 해결: 실행 전 `Get-Content <file> | Select-String <핵심단어>`로 최신본 확인, 또는 in-place PS 패치로 리포 파일 직접 수정 후 `Get-Content -Raw | Set-Clipboard`로 편집기에 붙여넣기
- Supabase **저장된 스니펫 재실행** 주의 — 새 SQL은 반드시 New query 새 탭에서

## 리포 상태
- branch marinebiogroup, 최신 커밋 faee253 (push 완료)
- 이 세션 SQL/패치 전부 sql\, tools\patches\, docs\handoff6-07-05\에 기록됨
