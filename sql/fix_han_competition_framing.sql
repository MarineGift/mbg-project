-- ============================================================
-- fix_han_competition_framing.sql
-- Correct the HAN pitch scenario after a market structure correction
-- (2026-07-25, follows seed_houston_angel_network.sql)
--
-- WHAT WAS WRONG
--   The original seed framed Kleannara as a competitor and the patent
--   proceedings as competitive risk. That is backwards.
--
-- ACTUAL STRUCTURE
--   Competitors  = filler producers, chiefly Omya and SMI
--   Kleannara    = buyer side paper mill, and the counterparty in the
--                  active patent proceedings
--   Real model   = the incumbents OEM the mbg technology under license,
--                  because their own development did not match it
--
-- CONSEQUENCES BAKED IN BELOW
--   1) Market validation leads with incumbent OEM adoption, not mill orders
--   2) Competition slide reframed - incumbents are channel, not threat
--   3) Valuation defence rests on royalty over incumbent volume
--   4) The sharp investor question becomes licensee dependency and
--      design-around risk, answered by the patent position
--   5) NEW blocking item - can the licensee names be stated without an NDA
--
-- Idempotent. Supabase SQL Editor safe. Save as UTF-8 WITHOUT BOM.
-- ============================================================


-- ------------------------------------------------------------
-- 1) Correct existing checklist items
-- ------------------------------------------------------------
update app.campaign_materials
set detail = 'HAN requires a completed working prototype and market validation. The strongest evidence is not the mill orders - it is that the largest global filler producers, Omya and SMI, already manufacture the product under an OEM license. Incumbent adoption IS the validation. Lead with it.',
    updated_at = now()
where campaign_id = 'd0000000-0000-4000-8000-0000000000fb'
  and item_key = 'elig_traction';

update app.campaign_materials
set detail = 'Decision 2026-07-25 - lead with the FCC filler story and target the Energy committee. Buyer economics are industrial and Houston angel members read cost and process carbon reduction in their own language. Confirm routing with the Managing Director before paying the fee.',
    status = 'in_progress',
    updated_at = now()
where campaign_id = 'd0000000-0000-4000-8000-0000000000fb'
  and item_key = 'elig_committee';

update app.campaign_materials
set detail = 'HAN and its members sign no confidentiality agreement during screening. Note the correct structure - the patent proceedings run against a buyer side paper mill (Kleannara), NOT against a filler competitor. State that accurately if it comes up. Keep the unpublished claim strategy and the opinion letter analysis out of every written submission and every spoken answer.',
    updated_at = now()
where campaign_id = 'd0000000-0000-4000-8000-0000000000fb'
  and item_key = 'elig_ip_boundary';

update app.campaign_materials
set detail = 'The 27M pre-money is high for a typical angel audience. The strongest support is a royalty model riding on incumbent production volume rather than on in-house capacity - Omya and SMI output is the addressable base, reached without matching capital intensity. Have comparable transactions and the patent position ready, and decide whether an SPV allocation on different terms is acceptable.',
    updated_at = now()
where campaign_id = 'd0000000-0000-4000-8000-0000000000fb'
  and item_key = 'pitch_valuation';

update app.campaign_materials
set detail = 'Only 5 minutes of questions. Prepare tight answers on unit economics, mill adoption cycle length, licensee dependency and design-around risk, and use of funds. Do not let any answer imply that the patent proceedings are a competitor dispute - the counterparty sits on the buyer side.',
    updated_at = now()
where campaign_id = 'd0000000-0000-4000-8000-0000000000fb'
  and item_key = 'pitch_qa';


-- ------------------------------------------------------------
-- 2) New checklist items for the corrected scenario
-- ------------------------------------------------------------
insert into app.campaign_materials
  (campaign_id, section, item_key, label, detail, status, sort_order)
values
 ('d0000000-0000-4000-8000-0000000000fb','Eligibility','elig_naming_rights',
  'Confirm the right to name the OEM licensees',
  'BLOCKING. Verify whether the Omya and SMI license agreements restrict naming the counterparty publicly. HAN signs no NDA, so anything stated in the application or the pitch is unprotected and cannot be walked back. If naming is restricted, use a formulation such as two of the largest global calcium carbonate producers and hold the names for the diligence stage. Settle this BEFORE any application text is written.',
  'not_started',50),
 ('d0000000-0000-4000-8000-0000000000fb','Pitch Materials','pitch_competition',
  'Rebuild the competition slide - incumbents as channel',
  'Omya and SMI are not the threat, they are the distribution channel. They license and OEM the product because their own development did not match it. That single fact is the market validation, and it outweighs the mill orders. Place it early rather than burying it on a competition slide near the end.',
  'not_started',205),
 ('d0000000-0000-4000-8000-0000000000fb','Pitch Materials','pitch_lockin',
  'Answer the licensee dependency question first',
  'The one sharp question an experienced angel will ask is why a licensee does not simply engineer around the technology and drop the royalty. That is the real risk, not competitive displacement. The patent position and the performance gap are the answer, and the answer belongs in the deck before the question is asked.',
  'not_started',215)
on conflict (campaign_id, item_key) do nothing;


-- ------------------------------------------------------------
-- 3) Correct the pitch task description
-- ------------------------------------------------------------
update app.tasks t
set description = '셋째 수요일 피치. 8분 발표 + 5분 질의응답. 압축 답변 준비 - 유닛 이코노믹스, 제지사 도입 사이클 길이, 라이선시 의존도와 설계우회 리스크, 자금 사용 계획. 특허 절차의 상대는 충전제 경쟁사가 아니라 구매자측 제지사(Kleannara)다. 답변이 반대로 들리지 않게 할 것.',
    updated_at = now()
from app.deals d
where d.id = t.deal_id
  and d.deal_name = 'Houston Angel Network - Sep 2026 pitch cycle'
  and d.deleted_at is null
  and t.title = 'HAN pitch meeting - 8 minutes plus 5 minutes Q and A'
  and t.deleted_at is null;

update app.tasks t
set description = '엔젤 오디언스 기준 27M 프리머니는 높은 편이다. 방어 논리의 핵심은 자체 생산능력이 아니라 인커번트 생산량 위에 얹히는 로열티 구조다 - Omya·SMI 물량이 자본집약 없이 접근 가능한 기반이 된다. 비교 거래 사례와 특허 포지션을 함께 정리하고, SPV 배정에 별도 조건을 허용할지 사전에 결정.',
    updated_at = now()
from app.deals d
where d.id = t.deal_id
  and d.deal_name = 'Houston Angel Network - Sep 2026 pitch cycle'
  and d.deleted_at is null
  and t.title = 'Prepare the 27M pre-money valuation defence'
  and t.deleted_at is null;


-- ------------------------------------------------------------
-- 4) New tasks
-- ------------------------------------------------------------
insert into app.tasks
  (deal_id, title, description, status, priority, due_at, extra_data, organization_id)
select d.id, v.title, v.description, 'pending', v.priority,
       v.due_at::timestamptz,
       '{"src":"han_scenario_fix_2026-07-25"}'::jsonb,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.deals d
cross join (values
  ('Confirm whether the OEM licensee names can be disclosed without an NDA',
   'Omya·SMI 라이선스 계약에 상대방 명칭 공개 제한 조항이 있는지 확인. NDA 없는 HAN 제출물과 피치에서 실명 사용 가능 여부가 여기서 갈린다. 제한이 있으면 "글로벌 최대 탄산칼슘 생산사 중 2곳" 식 기술로 대체하고 실명은 실사 단계로 미룬다. 지원서 작성 착수 전 선결 사항 - 한 번 말하면 되돌릴 수 없다.',
   'urgent', '2026-08-05 09:00:00-05'),
  ('Rebuild the competition slide with incumbents as channel',
   'Omya·SMI 를 위협이 아니라 유통 채널로 재배치. 인커번트가 자체 개발 대신 우리 기술을 OEM 받는다는 사실 자체가 시장 검증의 최강 근거이며 제지사 오더보다 무겁다. 뒤쪽 경쟁 슬라이드에 묻지 말고 앞으로 끌어낼 것.',
   'high', '2026-08-12 09:00:00-05'),
  ('Draft the licensee dependency answer before it is asked',
   '숙련된 엔젤이 던질 유일하게 날카로운 질문은 "라이선시가 우회 개발해서 로열티를 끊으면?" 이다. 경쟁사 대체 리스크가 아니라 이것이 실질 리스크다. 특허 포지션과 성능 격차를 답으로 배치하고, 질문을 기다리지 말고 덱 안에서 먼저 처리.',
   'high', '2026-08-12 09:00:00-05')
) as v(title, description, priority, due_at)
where d.deal_name = 'Houston Angel Network - Sep 2026 pitch cycle'
  and d.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and d.deleted_at is null
  and not exists (
    select 1 from app.tasks t
    where t.deal_id = d.id and t.title = v.title and t.deleted_at is null
  );


-- ============================================================
-- VERIFY (read-only)
-- ============================================================

-- V1: checklist now 19 items, 3 new keys present
select count(*) as total_items
from app.campaign_materials
where campaign_id = 'd0000000-0000-4000-8000-0000000000fb';

select item_key, section, status, left(detail, 70) as detail_head
from app.campaign_materials
where campaign_id = 'd0000000-0000-4000-8000-0000000000fb'
  and item_key in ('elig_traction','elig_committee','elig_ip_boundary',
                   'elig_naming_rights','pitch_competition','pitch_lockin',
                   'pitch_valuation','pitch_qa')
order by sort_order;

-- V2: tasks now 14, with the naming-rights gate on 2026-08-05
select t.due_at, t.priority, t.title
from app.tasks t
join app.deals d on d.id = t.deal_id
where d.deal_name = 'Houston Angel Network - Sep 2026 pitch cycle'
  and t.deleted_at is null
order by t.due_at;
