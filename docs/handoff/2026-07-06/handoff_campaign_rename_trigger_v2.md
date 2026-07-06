# Handoff -- 캠페인 rename 트리거 v2 (토큰 치환) + deal_name 일괄 정리 완료 (2026-07-06)

## 완료된 것
1. **deal_name 일괄 수정 완료** -- `fix_deal_name_seed_to_bridge.sql` 실행됨. "Seed Round" -> "Bridge Round" 치환, 괄호 접미사((Deep Tech) 등) 보존. verify 결과 잔재 0, 샘플 전부 "... - Bridge Round (...)"로 확인.
2. **중복 Pangaea 캠페인 삭제 완료** -- archived·0-deal 캠페인 제거. Bridge 캠페인 3개(Advanced Materials 120 / Deep Tech 60 / Life Science 70)만 정상 잔존.

## 이번 산출물: migration_campaign_rename_trigger.sql (트리거 v2)
기존 hand-made 트리거의 결함을 고친 **정식 마이그레이션**. repo에 남겨 DB 재구성 시 재현 가능.

### 왜 v2인가
- 원래 트리거: `replace(deal_name, ' - ' || old.name, ...)` -- 캠페인명 전체를 literal 매칭.
- 문제: deal_name은 캠페인명을 **verbatim으로 안 담음**. 캠페인 "Bridge Round - Advanced Materials"가 deal에는 "3M Ventures - Bridge Round (Advanced Materials)" (하이픈->괄호)로 저장됨. 전체 매칭이 절대 안 걸림.

### v2 동작 (토큰 치환, 괄호 형식 보존)
- old.name vs new.name의 **공통 접미사를 뺀 "달라진 토큰"만** 추출.
  예: 'Seed Round - Advanced Materials' -> 'Bridge Round - Advanced Materials'면 공통 꼬리 ' Round - Advanced Materials' 제거 -> old_token='Seed', new_token='Bridge'.
- deal_name에서 **' - ' 경계 뒤의 토큰만** 치환. 회사명에 우연히 같은 단어가 있어도(예: "Seedcamp") 안전 -- 회사명은 첫 ' - ' 앞이라 안 건드림.
  결과: "3M Ventures - Seed Round (Advanced Materials)" -> "3M Ventures - Bridge Round (Advanced Materials)". 괄호 접미사 보존.
- 접미사만 바뀌는 희귀 케이스(예: "Deep Tech"->"Deep Technology")는 괄호/하이픈 형식 차이로 매칭 실패 -> **안전하게 미변경**(잘못 바꾸느니 안 바꿈).

### 검증
로직을 파이썬으로 시뮬레이션 -- 실데이터 패턴 4종(정상 2 + Seedcamp 경계 + 전체 rename) 전부 기대값 일치.

## 적용
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
Supabase에서 `migration_campaign_rename_trigger.sql` 실행 -> 마지막 VERIFY가 트리거 1행(tgenabled='O') 나오면 성공. (기존 트리거는 drop-then-create로 자동 교체됨.)

## 테스트 (선택)
캠페인 하나의 name을 살짝 바꿔보고 그 캠페인 deal_name이 따라오는지 확인:
```sql
-- 예: 'Bridge Round - Deep Tech' -> 'Bridge Round - Deep Tech ' 뒤 스페이스 넣었다 뺐다 대신
-- 실제로는 라운드명 변경 시나리오로 테스트. 원복 가능.
```
실전에서는 캠페인 이름을 UI에서 바꾸면 해당 파이프라인 deal_name이 자동 반영됨.

## 커밋 (finish block)
```powershell
cd C:\dev\mbg-project
git pull --rebase origin marinebiogroup
git status -sb
git add sql/migration_campaign_rename_trigger.sql sql/fix_deal_name_seed_to_bridge.sql sql/cleanup_pangaea_dup_campaign.sql sql/probe_campaign_pipeline_link.sql "docs/handoff/$(Get-Date -Format 'yyyy-MM-dd')/handoff_campaign_rename_trigger_v2.md"
git commit -m "feat(campaigns): rename trigger v2 (token-replace, suffix-safe) + deal_name seed->bridge cleanup + dup campaign removal"
git push origin marinebiogroup
```

## 인라인 mover (fallback)
```powershell
$dl = "$env:USERPROFILE\Downloads"
$map = @(
  @{f='migration_campaign_rename_trigger*.sql'; d='C:\dev\mbg-project\sql\migration_campaign_rename_trigger.sql'},
  @{f='handoff_campaign_rename_trigger_v2*.md'; d=('C:\dev\mbg-project\docs\handoff\' + (Get-Date -Format 'yyyy-MM-dd') + '\handoff_campaign_rename_trigger_v2.md')}
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

## 향후 참고
- 근본 개선안(옵션): deal_name을 저장 컬럼이 아니라 뷰/조인으로 파생시키면 이런 동기화가 불필요해짐. 다만 현재 아키텍처 변경 비용이 크므로 트리거가 실용적.
- 트리거는 `after update of name` -- name 외 컬럼 UPDATE엔 안 걸림(성능 안전).
