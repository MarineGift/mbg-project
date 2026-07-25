-- ============================================================
-- fix_han_task_resequence.sql
-- Resequence the HAN pitch cycle task dates (2026-07-25)
-- Follows seed_houston_angel_network.sql + fix_han_competition_framing.sql
--
-- TWO ORDERING PROBLEMS BEING CORRECTED
--
--   1) The 100 USD fee was scheduled 2026-08-03, ahead of every gate.
--      The naming rights check (08-05) and the committee / IP boundary
--      work (08-07) can each kill the application. Spend moves after
--      the gates, to 08-08. Square checkout is online so a Saturday
--      is not a problem, and 6 days still remain before the 08-14
--      submission deadline.
--
--   2) Four high priority tasks sat on 2026-08-12, but they are serial,
--      not parallel. The competition reframe, the licensee dependency
--      answer and the valuation defence are all INPUTS to the 8 minute
--      deck. Building the deck first means building it twice.
--      Inputs move to 08-11, the deck build moves to 08-13.
--
-- RESULTING FLOW
--   08-05  naming rights confirmed      (gate)
--   08-07  committee + IP boundary      (gate)
--   08-08  pay the 100 USD fee          (spend, post gate)
--   08-10  warm path exploration
--   08-11  competition / dependency / valuation content locked
--   08-13  8 minute deck built
--   08-14  Dealum submission
--
-- Idempotent - re-running sets the same values. Editor safe.
-- Save as UTF-8 WITHOUT BOM.
-- ============================================================


-- ------------------------------------------------------------
-- 1) Fee payment moves behind the gates
-- ------------------------------------------------------------
update app.tasks t
set due_at = '2026-08-08 09:00:00-05'::timestamptz,
    description = '무료 readiness 도구(houston-angel-p8gvnhec.scoreapp.com)로 자가진단 후 Square 결제. 선결 조건 - 08-05 실명 공개 조항 확인과 08-07 딜커미티·IP 경계 확정이 모두 끝난 뒤에만 결제할 것. 두 게이트 중 하나라도 막히거나 Samia 회신에서 밸류에이션이 컷오프에 걸리면 지원 자체를 재검토한다. 결제해도 피치 기회나 투자는 보장되지 않는다. 영수증은 조달 비용으로 기록.',
    updated_at = now()
from app.deals d
where d.id = t.deal_id
  and d.deal_name = 'Houston Angel Network - Sep 2026 pitch cycle'
  and d.deleted_at is null
  and t.title = 'Run the HAN readiness scorecard and pay the 100 USD fee'
  and t.deleted_at is null;


-- ------------------------------------------------------------
-- 2) Deck inputs pulled forward to 08-11
-- ------------------------------------------------------------
update app.tasks t
set due_at = '2026-08-11 09:00:00-05'::timestamptz,
    updated_at = now()
from app.deals d
where d.id = t.deal_id
  and d.deal_name = 'Houston Angel Network - Sep 2026 pitch cycle'
  and d.deleted_at is null
  and t.deleted_at is null
  and t.title in (
    'Rebuild the competition slide with incumbents as channel',
    'Draft the licensee dependency answer before it is asked',
    'Prepare the 27M pre-money valuation defence'
  );


-- ------------------------------------------------------------
-- 3) Deck build pushed to 08-13
-- ------------------------------------------------------------
update app.tasks t
set due_at = '2026-08-13 09:00:00-05'::timestamptz,
    description = 'HAN 지정 순서 - Problem / Solution and value proposition / The Magic (IP) / Business model / Go to market / Competition / Team / Financials and key metrics / Progress to date / Raise and use of funds. Ver3.x 전체판 재사용 금지, 8분 전용 축약본으로 별도 제작. 선결 조건 - 08-11 의 경쟁 재배치·의존도 답변·밸류에이션 3종이 확정된 뒤 착수할 것. 순서를 뒤집으면 덱을 두 번 만들게 된다.',
    updated_at = now()
from app.deals d
where d.id = t.deal_id
  and d.deal_name = 'Houston Angel Network - Sep 2026 pitch cycle'
  and d.deleted_at is null
  and t.title = 'Build the 8 minute HAN cut of the deck in the prescribed 10 slide order'
  and t.deleted_at is null;


-- ============================================================
-- VERIFY (read-only) - expect 14 rows, no date before 08-05
-- except nothing, and 08-12 now empty
-- ============================================================
select t.due_at, t.priority, t.title
from app.tasks t
join app.deals d on d.id = t.deal_id
where d.deal_name = 'Houston Angel Network - Sep 2026 pitch cycle'
  and t.deleted_at is null
order by t.due_at, t.title;
