# Handoff — Paper Mill 3쌍 병합 실행본 (v2, parser-safe) (2026-07-05)

## 이번에 확정된 두 가지
1. **FK probe 결과 (CSV 15): app.parties(id) 참조 child 26개.** `party_supply_links`가 **실제로 존재**하고 컬럼은 `mill_party_id` / `filler_party_id`. → 처음 추측한 이름이 맞았음. 반대로 024의 `plant_supply_links`는 **DB에 없는 유령 테이블**이었음(미적용). 두 테이블 개념이 섞여 혼란이 있었던 것.
2. **v1 실패 원인**: Supabase 에디터가 `;`에서 문을 쪼개 `create temporary table … / do $$ … $$` 이후 문이 temp table을 못 찾음(42P01 `_mill_merge does not exist`). → **temp table·do-block·BEGIN 전부 제거**하고 v9처럼 문마다 3쌍 VALUES를 인라인 반복하는 자기완결형으로 재작성 = `fix_mill_merge_3pairs_v2.sql`.

## reparent 범위 (FK 26개 분류)
- **generic party_id 이동 (16)**: account_scores, calendar_events, communications, consultations, deal_backers, deal_participation, deal_parties, deals, email_sequence_enrollments, email_tracking, engagements, lead_scores, meetings, response_strategies + contacts_history.firm_party_id + contacts(중복 회피 가드)
- **mill 전용 컬럼**: `party_supply_links.mill_party_id`(pair 중복 회피 후 잔여 delete), `paper_mill_paper_types.mill_party_id`(plain move)
- **1:1 detail (move-or-drop)**: paper_mill_profile, party_profiles
- **스킵(mill 아님)**: investor_profile, investor_portfolio_companies, filler_supplier_profile, engagement_participants·meeting_attendees(person), party_supply_links.filler_party_id(공급사 쪽)

## 병합 대상 (3쌍만 — 앞선 분석대로)
| keep | ← merge |
|---|---|
| Essity `a31ef82c` | Essity AB `3a6e8e3e` |
| Holmen Iggesund `d98f9ba1` | Holmen Iggesund Mill `b2e47e37` |
| Mondi Neusiedler(Hausmening) `c1fb01a0` | Mondi Neusiedler GmbH(오기 Munich) `29d74802` |

Holmen AB/Paper(HQ vs 사업부)·Star(UAE vs India 별개회사)는 **병합 제외** 유지.

## 실행 순서
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
Supabase에서 `fix_mill_merge_3pairs_v2.sql` **전체 select-all → Run**:
1. (0) 프리플라이트가 `all_ok` 를 반환 — **3이 아니면 즉시 중단**(id·타입·미삭제 문제).
2. 나머지 문이 순서대로: canonical 보충 → child 재지정 → 1:1 detail 이동 → merge 행 soft-delete.
3. 마지막 (8) verify가 **merge_still_active=0, keep_active=3**이면 성공. 디렉토리 paper_mill 3 감소.

⚠ **트랜잭션 미적용 주의**: 에디터가 BEGIN을 쪼개므로 이 파일은 v9처럼 문별 실행됨. 각 문이 독립적으로 안전하고 soft-delete가 마지막이라, 중간 실패 시에도 데이터 손상은 없고 재실행하면 이어짐(재지정은 이미 옮긴 건 `where = merge`가 0건이라 무해). 만약 **(5) paper_mill_paper_types에서 unique 위반**이 나면 그 한 문만 지우고 계속 — 어차피 merge 행은 soft-delete됨. (이 3개 EU mill은 해당 테이블이 비어 있을 가능성 높아 no-op 예상.)

## 병합 후 (선택)
- Holmen 3-tier(AB→Paper→Iggesund/Hallsta/Braviken) FK 연결 점검
- Star 2건 이름 충돌 회피: party_name에 국가 접미사 (예: "Star Paper Mill (India)")

## 커밋 (finish block)
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/fix_mill_merge_3pairs_v2.sql "docs/handoff/$(Get-Date -Format 'yyyy-MM-dd')/handoff_mill_merge_v2.md"
git commit -m "feat(db): paper-mill dedupe - 3-pair merge v2 (parser-safe, FK-confirmed reparent)"
git push origin marinebiogroup
```

## 인라인 mover (fallback)
```powershell
$dl = "$env:USERPROFILE\Downloads"
$map = @(
  @{f='fix_mill_merge_3pairs_v2*.sql'; d='C:\dev\mbg-project\sql\fix_mill_merge_3pairs_v2.sql'},
  @{f='handoff_mill_merge_v2*.md';     d=('C:\dev\mbg-project\docs\handoff\' + (Get-Date -Format 'yyyy-MM-dd') + '\handoff_mill_merge_v2.md')}
)
foreach ($m in $map) {
  $src = Get-ChildItem -Path $dl -Filter $m.f -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($src) {
    Unblock-File $src.FullName -ErrorAction SilentlyContinue
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($m.d)) | Out-Null
    [System.IO.File]::Copy($src.FullName, $m.d, $true); Remove-Item $src.FullName -Force
    Write-Host ("MOVED: " + $src.Name)
  } else { Write-Host ("SKIP (not found): " + $m.f) }
}
```

## 대기 중 (별개 트랙)
- `enrich_batch9c_kr_cany_emails.sql` (9c-1 이메일) 미실행이면 실행
- **Pangaea pre-meeting 이메일: 월 7/6 오전 발송** (수 7/8 9:30 PDT)
- 9c-2: US 14곳


---

## v2 실행 중 발견된 23505 수정 (2026-07-05, 추가)
**증상**: `account_scores`에서 `duplicate key … account_scores_organization_id_party_id_key` — Mondi keep/merge 양쪽에 스코어 행이 있어 재지정이 unique(organization_id, party_id)를 위반.

**원인**: 스코어/프로필류는 **party당 1행**이라 plain move가 아니라 move-or-drop이어야 함. v2에서 `account_scores`·`lead_scores`를 plain move로 둔 게 실수.

**수정 (동일 파일 갱신됨)**:
- `account_scores`: keep에 (org,party) 행이 없을 때만 이동, 있으면 merge 행 delete
- `lead_scores`: 동일 패턴 (party_id 기준 가드 — org 컬럼 유무와 무관하게 안전)
- `paper_mill_profile`·`party_profiles`는 이미 move-or-drop이었음

**재실행 안전**: 이 파일은 트랜잭션이 없어 실패 지점(첫 reparint=account_scores) 앞의 pre-flight·canonical enrich만 이미 실행됨. 각 문이 `where party_id = merge_id`라 이미 옮긴 건 0건 스킵 → **수정본을 처음부터 다시 select-all → Run** 하면 됩니다. (0) all_ok=3, (8) (0,3) 확인.

> 교훈: FK child 중 scores/profile/1:1-detail은 전부 move-or-drop, events/comms/deals/links는 plain move. 메모리 #15의 child 목록에 이 구분을 참고.
