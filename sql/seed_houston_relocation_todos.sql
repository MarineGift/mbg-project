-- ============================================================
-- seed_houston_relocation_todos.sql
-- Relocation todos for campaign Houston HQ Relocation 2026Q3
-- Run AFTER fix_houston_hq_relocation_v2.sql (2026-07-25)
--
-- WHY THIS IS A SEPARATE FILE
--   app.tasks requires a NOT NULL deal_id and relocation work has no
--   counterparty deal, so these live in app.todo_items instead.
--   The repo carries no DDL for todo_items, so the priority check
--   constraint is unknown. Keeping the insert isolated means a
--   constraint failure here cannot roll back the campaign, checklist,
--   parties and notes in the main file.
--
-- RUN ORDER
--   1) Section 0 probes, ALONE. Read all three results.
--   2) Only if the probes look right, run section 1.
--
-- IF PROBE C SHOWS NO BOARD - stop, nothing will insert.
-- IF PROBE B SHOWS PRIORITY VALUES OTHER THAN high and medium -
--   stop and report them, the insert will otherwise violate a check.
--
-- Idempotent. Save as UTF-8 WITHOUT BOM.
-- ============================================================


-- ------------------------------------------------------------
-- 0) PROBES. Run these three alone, before section 1.
-- ------------------------------------------------------------

-- Probe A: does the campaign exist? Expect one row.
select id, name, status
from app.campaigns
where id = 'd0000000-0000-4000-8000-0000000000f9';

-- Probe B: which priority values does todo_items already accept?
--          Expect to see high and medium among them.
select coalesce(ti.priority, 'NULL') as priority_value, count(*) as rows_using
from app.todo_items ti
where ti.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
group by ti.priority
order by rows_using desc;

-- Probe C: boards and their non-done status options.
--          Zero rows means section 1 inserts nothing.
select b.id as board_id, b.name as board_name, b.kind, b.position,
       (select so.key from app.todo_status_options so
         where so.board_id = b.id and so.is_done = false
         order by so.position limit 1) as first_open_status,
       (select count(*) from app.todo_status_options so where so.board_id = b.id) as status_options
from app.todo_boards b
where b.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
order by b.position;


-- ------------------------------------------------------------
-- 1) Todos. Lands on the first board by position. Status is read
--    off that board rather than hard coded.
-- ------------------------------------------------------------
insert into app.todo_items
  (organization_id, board_id, title, description, status, priority, due_date, party_id, position, custom)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       b.id, v.title, v.description,
       coalesce((select so.key from app.todo_status_options so
                  where so.board_id = b.id and so.is_done = false
                  order by so.position limit 1), 'todo'),
       v.priority, v.due_date::date,
       (select p.id from app.parties p
         where p.party_name = v.party_name
           and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
           and p.deleted_at is null limit 1),
       v.pos,
       '{"src":"houston_hq_relocation_2026-07-25"}'::jsonb
from (select id from app.todo_boards
       where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
       order by position limit 1) b
cross join (values
  ('Apply to Greentown Houston as a desk-only member',
   '웻랩 불필요 확정에 따라 데스크 단독으로 신청. 2021년 요율 기준 데스크 월 450달러이며 랩 공간 없이 데스크만 받을 수 있다(현재가 확인 필요). 핵심 가치는 책상이 아니라 선발 자체다 - 기후테크 인큐베이터 심사 통과가 HAN 지원서와 New Climate Ventures·Fathom Fund 대화에서 신호로 작동한다. 주소도 Ion District 안이라 Fathom·Chevron Technology Ventures·Ara Partners 까지 도보 거리다. 심사에 시간이 걸리므로 9/2 이전 대비 조기 신청.',
   'high', '2026-07-31', 'Greentown Labs Houston', 10),
  ('Take The Cannon month to month as the landing pad',
   'Greentown 심사가 진행되는 동안의 즉시 착지점. 선발 절차가 없어 바로 입주 가능하다. Downtown 과 West Houston 요금·데이패스 조건을 비교하고 장기 약정에 묶이지 않게 월단위로 계약할 것. 현금이 빠듯하면 Cannon 단독 + Ion·Greentown 공개 행사 참석 조합도 실질적 대안이다.',
   'medium', '2026-08-05', 'The Cannon', 20),
  ('Restate the company as Houston based across all materials',
   'HAN 지원서·피치덱·Dealum 제출·아웃바운드 템플릿의 "Texas based" 를 "Houston based as of September 2, 2026" 으로 변경. 휴스턴 엔젤 네트워크 상대로는 가점이며 9/16 피치 시점에는 이미 로컬 기업이다. 오스틴은 투자자 대면 자료에서 전부 삭제.',
   'high', '2026-08-07', '', 30),
  ('Check the Korean cosmetics facility FDA registration and US agent',
   '화장품은 한국 생산·미국 판매 구조이므로 MoCRA 가 해외 시설 등록 의무로 적용된다. 미국 내 제조 시설 요건이 아니다. 한국 제조 시설의 FDA 등록 여부와 미국 대리인 지정 여부를 확인하고 미등록이면 착수. 2년마다 갱신, 변경 시 60일 내 갱신. 2024-07-01 부터 집행 중이며 미비 시 통관 보류 위험.',
   'high', '2026-08-17', '', 40),
  ('Fix the responsible person and plan the product listings',
   '제품 라벨에 이름이 올라가는 주체가 responsible person 이고 리스팅 의무를 진다. 미국 판매 법인이 라벨에 오르는지 먼저 확정. 시설 등록 Form 5066, 제품 리스팅 Form 5067(FEI·전성분, 연 1회 갱신), 제출은 Cosmetics Direct. FD&C Act 612조 소기업 면제 해당 여부도 규제 자문으로 확인 - 품목별 예외가 있어 가정은 위험하다.',
   'high', '2026-08-24', '', 50),
  ('Move the address of record and retire Austin',
   '등기 주소·우편 주소·은행·신고 기록을 휴스턴으로 이전. 오스틴은 운영 거점에서 제외하고 대외 자료에서 삭제한다.',
   'high', '2026-08-28', '', 60),
  ('Start the Houston and Galveston chemical corridor site scan',
   '향후 해양 바이오소재 흡수체 생산 부지 조사. Houston Ship Channel, Bayport, Texas City, Galveston County 를 훑고 기존 사업자 토링 방식과 자체 설비 방식을 조기 비교 - 자본 소요와 규제 부담 구조가 완전히 다르다. 한국발 원료의 휴스턴항 직수입 리드타임·착지원가도 함께 산출해 FCC 유닛 이코노믹스에 반영.',
   'medium', '2026-09-30', '', 70)
) as v(title, description, priority, due_date, party_name, pos)
where not exists (
  select 1 from app.todo_items ti
  where ti.title = v.title
    and ti.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    and ti.archived_at is null
);


-- ============================================================
-- VERIFY (read-only) - expect 7 rows, 07-31 through 09-30
-- ============================================================
select ti.due_date, ti.priority, ti.status, ti.title,
       (select p.party_name from app.parties p where p.id = ti.party_id) as linked_party
from app.todo_items ti
where ti.custom->>'src' = 'houston_hq_relocation_2026-07-25'
  and ti.archived_at is null
order by ti.due_date;
