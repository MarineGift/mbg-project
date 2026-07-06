# Handoff -- 캠페인 이름 -> pipeline(deal) 자동 반영 트리거 + Pangaea 중복 삭제 (2026-07-06)

## 근본 원인 (소스 확인 완료)
"Investors 파이프라인의 Seed Round"는 **별도 컬럼이 아니라 deal 행의 스냅샷**입니다. `src/lib/actions/campaigns.ts`의 seedCampaignDeals가 deal 생성 시:
```
deal_name = `${party_name} - ${campaignName}`
```
로 **생성 시점의 캠페인 이름을 deal_name에 박아 넣습니다**. 그래서 캠페인 이름을 Seed Round -> Bridge Round로 바꿔도 이미 만들어진 deal_name은 안 따라옵니다. 이게 "pipeline이 안 바뀐다"의 정체입니다.

-> 해결: **DB 트리거** -- 캠페인 name이 UPDATE되면 그 캠페인에 속한 deal들의 deal_name에서 옛 이름 부분을 새 이름으로 치환.

## ⚠ 왜 2단계인가 (probe 먼저)
generated DB 타입(`src/types/database.ts`)의 deals Row에 **campaign_id가 없습니다**. 코드는 campaign_id로 insert하는데 타입엔 없음 -> 타입이 오래됐거나 실제 컬럼명이 다를 수 있음. 여기서 컬럼명을 추측하면 지난 plant_supply_links처럼 42703이 납니다. 그래서 **probe로 실제 스키마 확정 후** 트리거를 확정합니다.

## STEP 1 -- probe 실행 (READ ONLY)
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
Supabase에서 `probe_campaign_pipeline_link.sql` 실행 -> 6개 결과셋 전부 회신:
- (1) campaigns 컬럼 (name 컬럼·pk 확정)
- (2) deals 컬럼 중 campaign/name 관련 (campaign_id 실제 존재·이름 확정)
- (3) deals -> campaigns FK (정확한 링크 컬럼)
- (4) Bridge/Seed/Pangaea/Advanced Materials 캠페인 현황
- (5) deal_name에 "Seed Round"가 박힌 deal 목록 (고칠 대상)
- (6) **Pangaea 중복 캠페인 2건 상세** (어느 것을 지울지 판단용)

## STEP 2 -- probe 결과 받으면 (다음 응답에서 확정본 생성)
### A. 트리거 (campaign name -> deal_name 자동 반영)
probe (1)(2)(3)으로 컬럼 확정 후, 대략 이런 형태 (컬럼명은 probe로 교체):
```sql
create or replace function app.sync_deal_name_on_campaign_rename()
returns trigger language plpgsql as $$
begin
  if new.name is distinct from old.name then
    update app.deals d
       set deal_name = replace(d.deal_name, ' - ' || old.name, ' - ' || new.name),
           updated_at = now()
     where d.campaign_id = new.id
       and d.deleted_at is null
       and d.deal_name like '% - ' || old.name;
  end if;
  return new;
end $$;

create trigger trg_sync_deal_name_on_campaign_rename
  after update of name on app.campaigns
  for each row execute function app.sync_deal_name_on_campaign_rename();
```
+ **소급 1회 실행**: 이미 바뀐 Bridge Round 캠페인의 기존 deal들을 지금 한 번 치환 (현재 'Seed Round'로 남아있는 Pangaea deal -> 'Bridge Round').

### B. Pangaea 중복 캠페인 삭제
probe (6)으로 두 캠페인의 id·deal수·소속 회사를 본 뒤:
- 'Bridge Round Advanced Materials'에 포함된 Pangaea vs 별개 Pangaea 캠페인 중 **어느 것이 정본인지 확인** -> 중복본의 deal을 정본으로 재지정(또는 중복 deal soft-delete) 후 캠페인 soft-delete.
- ⚠ 캠페인을 지우기 전에 그 캠페인에 매달린 deal 처리 방침 결정 필요 (재지정 vs 삭제). deal에는 engagement/meeting 등이 붙어 있을 수 있으므로 (Pangaea는 7/8 미팅 deal 존재!) **삭제가 아니라 재지정**이 안전.

## 판단 필요 지점 (STEP 2에서 사용자 확인)
1. 트리거 매칭을 ' - <name>' 접미사로 할지 (deal_name 규칙이 정확히 이 형태인지 probe (5)로 확인)
2. Pangaea 정본 캠페인 어느 쪽인지 (probe (6) 결과 보고)
3. 중복 캠페인의 Pangaea deal(7/8 미팅 붙은 것)을 정본으로 옮길지

## 다음 세션(또는 이어서) 시작 프롬프트
> "probe_campaign_pipeline_link.sql 결과 붙여넣는다. 이걸로 (A) 캠페인 rename->deal_name 자동반영 트리거 + 소급 1회 실행, (B) Pangaea 중복 캠페인 정리(미팅 붙은 deal은 재지정)를 확정 SQL로 만들어줘. idempotent, Supabase 에디터 파서 안전(do-block/temp/세미콜론 주의), verify 포함."

## 오늘 세션 완료분 (참고)
Paper Mill 병합·9c 이메일·Pangaea 발송·이메일 패치 2건·To-do handoff 전부 커밋·push 완료. 원격 HEAD 92958f5.
