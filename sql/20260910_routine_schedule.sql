-- ============================================================================
--  ⚠️  Ctrl+A  로 전체 선택 후  RUN  하세요 (SELECT ALL, then Run)
--      Supabase SQL Editor는 "선택된 텍스트만" 실행합니다.
--      일부만 드래그된 상태로 실행하면 relation "..." does not exist 오류가 납니다.
-- ============================================================================
--
--  20260910_routine_schedule.sql
--  일과표(Daily Routine) + 실행 체크 + 매일/주간/월간/연간 달성률 리포팅
--
--  구성
--    1. app.routine_blocks   – 반복되는 하루 일정 "계획"(시간블록 템플릿)
--    2. app.routine_logs     – 날짜별·블록별 "실제 수행" 체크 기록
--    3. RLS                  – 본인(조직+사용자) 행만 접근 (calendar_events 패턴)
--    4. 리포팅 뷰(6종)        – 계획 대비 실제(달성률)를 일/주/월/년/카테고리로 집계
--    5. 시드                  – 06:00~23:00 기본 일과표를 조직 소유자에게 1회 주입
--
--  멱등(idempotent): 여러 번 실행해도 안전 (IF NOT EXISTS / ON CONFLICT DO NOTHING)
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- 1. 계획 테이블: routine_blocks (반복되는 하루 시간블록)
-- ----------------------------------------------------------------------------
create table if not exists app.routine_blocks (
    id              uuid        primary key default gen_random_uuid(),
    organization_id uuid        not null references app.organizations(id) on delete cascade,
    user_id         uuid        not null references app.users(id)         on delete cascade,

    title           text        not null,                 -- 예: "업무 1 (집중 딥워크)"
    category        text        not null default 'other',  -- work/english/exercise/meal/rest/growth/personal/other
    start_time      time        not null,                  -- 예: 08:00
    end_time        time        not null,                  -- 예: 09:00

    -- 요일 비트마스크: bit0=일 .. bit6=토  (127 = 매일)
    weekday_mask    int         not null default 127,

    sort_order      int         not null default 0,
    active          boolean     not null default true,
    note            text,

    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),

    constraint routine_blocks_time_chk    check (end_time > start_time),
    constraint routine_blocks_weekday_chk check (weekday_mask between 1 and 127),
    -- 재실행 시 같은 블록 중복 삽입 방지 (시드 멱등성)
    constraint routine_blocks_uq unique (user_id, title, start_time)
);

create index if not exists idx_routine_blocks_user
    on app.routine_blocks (user_id, start_time);
create index if not exists idx_routine_blocks_org
    on app.routine_blocks (organization_id);

-- ----------------------------------------------------------------------------
-- 2. 실행 기록 테이블: routine_logs (날짜 × 블록 = 1행)
-- ----------------------------------------------------------------------------
create table if not exists app.routine_logs (
    id              uuid        primary key default gen_random_uuid(),
    organization_id uuid        not null references app.organizations(id) on delete cascade,
    user_id         uuid        not null references app.users(id)         on delete cascade,
    block_id        uuid        not null references app.routine_blocks(id) on delete cascade,

    log_date        date        not null,
    -- done: 완료 / partial: 부분 / skipped: 건너뜀
    status          text        not null default 'done'
                                check (status in ('done','partial','skipped')),
    actual_minutes  int,
    note            text,
    completed_at    timestamptz not null default now(),

    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),

    constraint routine_logs_uq unique (block_id, log_date)
);

create index if not exists idx_routine_logs_user_date
    on app.routine_logs (user_id, log_date);
create index if not exists idx_routine_logs_block
    on app.routine_logs (block_id);

-- ----------------------------------------------------------------------------
-- 3. updated_at 자동 갱신 트리거
-- ----------------------------------------------------------------------------
create or replace function app.routine_set_updated_at()
returns trigger
language plpgsql
as $fn$
begin
    new.updated_at := now();
    return new;
end
$fn$;

drop trigger if exists trg_routine_blocks_updated on app.routine_blocks;
create trigger trg_routine_blocks_updated
    before update on app.routine_blocks
    for each row execute function app.routine_set_updated_at();

drop trigger if exists trg_routine_logs_updated on app.routine_logs;
create trigger trg_routine_logs_updated
    before update on app.routine_logs
    for each row execute function app.routine_set_updated_at();

-- ----------------------------------------------------------------------------
-- 4. RLS — 본인(조직+사용자) 행만 (calendar_events / connections 패턴)
-- ----------------------------------------------------------------------------
alter table app.routine_blocks enable row level security;
alter table app.routine_logs   enable row level security;

drop policy if exists pol_routine_blocks_all on app.routine_blocks;
create policy pol_routine_blocks_all on app.routine_blocks
    for all
    using (
        organization_id = app.current_organization_id()
        and user_id = app.current_user_id()
    )
    with check (
        organization_id = app.current_organization_id()
        and user_id = app.current_user_id()
    );

drop policy if exists pol_routine_logs_all on app.routine_logs;
create policy pol_routine_logs_all on app.routine_logs
    for all
    using (
        organization_id = app.current_organization_id()
        and user_id = app.current_user_id()
    )
    with check (
        organization_id = app.current_organization_id()
        and user_id = app.current_user_id()
    );

-- ----------------------------------------------------------------------------
-- 5. 리포팅 뷰
--    security_invoker=true → 호출한 사용자의 RLS가 그대로 적용(본인 데이터만)
--
--    윈도우: 오늘 기준 과거 400일 ~ 미래 31일 (일/주/월/년 리포팅에 충분)
--    "계획된 발생일"을 generate_series로 펼치고 실제 로그를 LEFT JOIN하여
--    상태(done/partial/skipped/missed/pending/upcoming)를 계산.
-- ----------------------------------------------------------------------------

-- 5-1. 핵심 상태 뷰: (블록 × 날짜) 별 계획 vs 실제
create or replace view app.v_routine_status
with (security_invoker = true) as
with planned as (
    select
        b.id              as block_id,
        b.organization_id,
        b.user_id,
        b.title,
        b.category,
        b.start_time,
        b.end_time,
        g.d::date         as plan_date
    from app.routine_blocks b
    cross join generate_series(
        (current_date - interval '400 days')::date,
        (current_date + interval '31 days')::date,
        interval '1 day'
    ) as g(d)
    where b.active
      and (b.weekday_mask & (1 << extract(dow from g.d)::int)) <> 0
)
select
    p.organization_id,
    p.user_id,
    p.plan_date,
    p.block_id,
    p.title,
    p.category,
    p.start_time,
    p.end_time,
    l.id              as log_id,
    l.actual_minutes,
    l.note            as log_note,
    l.completed_at,
    case
        when l.status is not null            then l.status
        when p.plan_date <  current_date     then 'missed'
        when p.plan_date =  current_date     then 'pending'
        else 'upcoming'
    end               as status
from planned p
left join app.routine_logs l
    on l.block_id = p.block_id
   and l.log_date = p.plan_date;

-- 5-2. 기간 집계 헬퍼 매크로를 대신할 4개 뷰 (일/주/월/년)
--      denominator = 오늘까지 도래한(due) 계획 건수
--      adherence_pct = (done + partial*0.5) / due
create or replace view app.v_routine_adherence_daily
with (security_invoker = true) as
select
    user_id,
    plan_date                                                    as bucket,
    count(*) filter (where plan_date <= current_date)            as planned_due,
    count(*) filter (where status = 'done')                      as done,
    count(*) filter (where status = 'partial')                   as partial,
    count(*) filter (where status = 'skipped')                   as skipped,
    count(*) filter (where status = 'missed')                    as missed,
    round(100.0 * (count(*) filter (where status = 'done')
                   + 0.5 * count(*) filter (where status = 'partial'))
          / nullif(count(*) filter (where plan_date <= current_date), 0), 1) as adherence_pct
from app.v_routine_status
group by user_id, plan_date;

create or replace view app.v_routine_adherence_weekly
with (security_invoker = true) as
select
    user_id,
    date_trunc('week', plan_date)::date                          as bucket,
    count(*) filter (where plan_date <= current_date)            as planned_due,
    count(*) filter (where status = 'done')                      as done,
    count(*) filter (where status = 'partial')                   as partial,
    count(*) filter (where status = 'skipped')                   as skipped,
    count(*) filter (where status = 'missed')                    as missed,
    round(100.0 * (count(*) filter (where status = 'done')
                   + 0.5 * count(*) filter (where status = 'partial'))
          / nullif(count(*) filter (where plan_date <= current_date), 0), 1) as adherence_pct
from app.v_routine_status
group by user_id, date_trunc('week', plan_date);

create or replace view app.v_routine_adherence_monthly
with (security_invoker = true) as
select
    user_id,
    date_trunc('month', plan_date)::date                         as bucket,
    count(*) filter (where plan_date <= current_date)            as planned_due,
    count(*) filter (where status = 'done')                      as done,
    count(*) filter (where status = 'partial')                   as partial,
    count(*) filter (where status = 'skipped')                   as skipped,
    count(*) filter (where status = 'missed')                    as missed,
    round(100.0 * (count(*) filter (where status = 'done')
                   + 0.5 * count(*) filter (where status = 'partial'))
          / nullif(count(*) filter (where plan_date <= current_date), 0), 1) as adherence_pct
from app.v_routine_status
group by user_id, date_trunc('month', plan_date);

create or replace view app.v_routine_adherence_yearly
with (security_invoker = true) as
select
    user_id,
    date_trunc('year', plan_date)::date                          as bucket,
    count(*) filter (where plan_date <= current_date)            as planned_due,
    count(*) filter (where status = 'done')                      as done,
    count(*) filter (where status = 'partial')                   as partial,
    count(*) filter (where status = 'skipped')                   as skipped,
    count(*) filter (where status = 'missed')                    as missed,
    round(100.0 * (count(*) filter (where status = 'done')
                   + 0.5 * count(*) filter (where status = 'partial'))
          / nullif(count(*) filter (where plan_date <= current_date), 0), 1) as adherence_pct
from app.v_routine_status
group by user_id, date_trunc('year', plan_date);

-- 5-3. 카테고리별 달성률(전체 윈도우 기준: 운동/영어/업무 등 어디가 약한지)
create or replace view app.v_routine_adherence_category
with (security_invoker = true) as
select
    user_id,
    category,
    count(*) filter (where plan_date <= current_date)            as planned_due,
    count(*) filter (where status = 'done')                      as done,
    count(*) filter (where status = 'partial')                   as partial,
    count(*) filter (where status = 'skipped')                   as skipped,
    count(*) filter (where status = 'missed')                    as missed,
    round(100.0 * (count(*) filter (where status = 'done')
                   + 0.5 * count(*) filter (where status = 'partial'))
          / nullif(count(*) filter (where plan_date <= current_date), 0), 1) as adherence_pct
from app.v_routine_status
group by user_id, category;

-- ----------------------------------------------------------------------------
-- 6. 시드: 06:00~23:00 기본 일과표
--    대상 사용자 = 조직 소유자(owner)  [리포지토리 표준 시드 패턴]
--    실제 user_id를 코드에 박지 않고 app.users(owner)에서 해석하고,
--    조직 id도 같은 행에서 가져와 FK 정합성을 보장한다.
-- ----------------------------------------------------------------------------
do $seed$
declare
    v_org  uuid;
    v_user uuid;
begin
    select id, organization_id
      into v_user, v_org
      from app.users
     where is_owner = true and is_active = true
     order by created_at
     limit 1;

    if v_user is null then
        raise notice '시드 건너뜀: 활성 owner 사용자가 없습니다. 프론트엔드 "기본 일정표 불러오기" 버튼을 사용하세요.';
        return;
    end if;

    insert into app.routine_blocks
        (organization_id, user_id, title, category, start_time, end_time, weekday_mask, sort_order)
    values
        (v_org, v_user, '기상 및 식사, 샤워, 출근준비',          'personal', '06:00', '06:30', 127,  1),
        (v_org, v_user, '출근 – 영어 스피킹 (들으면서 말하기)',  'english',  '06:30', '07:00', 127,  2),
        (v_org, v_user, '명상 · 오늘의 할일 · 감사기도',          'personal', '07:00', '07:30', 127,  3),
        (v_org, v_user, '업무 준비 · 이메일 정리',                'work',     '07:30', '08:00', 127,  4),
        (v_org, v_user, '업무 1 (집중 딥워크)',                   'work',     '08:00', '09:00', 127,  5),
        (v_org, v_user, '업무 2',                                 'work',     '09:00', '10:00', 127,  6),
        (v_org, v_user, '휴식',                                   'rest',     '10:00', '10:15', 127,  7),
        (v_org, v_user, '업무 3',                                 'work',     '10:15', '11:30', 127,  8),
        (v_org, v_user, '영어 공부 (리딩 · 어휘)',                'english',  '11:30', '12:00', 127,  9),
        (v_org, v_user, '점심 및 휴식',                           'meal',     '12:00', '13:00', 127, 10),
        (v_org, v_user, '업무 4',                                 'work',     '13:00', '14:30', 127, 11),
        (v_org, v_user, '휴식',                                   'rest',     '14:30', '14:45', 127, 12),
        (v_org, v_user, '업무 5',                                 'work',     '14:45', '16:00', 127, 13),
        (v_org, v_user, '업무 6 · 미팅',                          'work',     '16:00', '17:00', 127, 14),
        (v_org, v_user, '업무 마무리 · 정리',                     'work',     '17:00', '18:00', 127, 15),
        (v_org, v_user, '저녁 식사',                              'meal',     '18:00', '19:00', 127, 16),
        (v_org, v_user, '운동',                                   'exercise', '19:00', '20:00', 127, 17),
        (v_org, v_user, '샤워 · 휴식',                            'rest',     '20:00', '20:30', 127, 18),
        (v_org, v_user, '영어 공부 (스피킹 · 섀도잉)',            'english',  '20:30', '21:30', 127, 19),
        (v_org, v_user, '자기계발 · 독서',                        'growth',   '21:30', '22:30', 127, 20),
        (v_org, v_user, '하루 리뷰 · 감사일기 · 내일 계획',       'personal', '22:30', '23:00', 127, 21)
    on conflict (user_id, title, start_time) do nothing;

    raise notice '시드 완료: user=% 블록 주입(중복 제외)', v_user;
end
$seed$;

commit;

-- ============================================================================
--  확인용 쿼리 (원하면 아래를 각각 실행)
--    select * from app.routine_blocks order by start_time;                    -- 계획 확인
--    select * from app.v_routine_adherence_daily   order by bucket desc;      -- 매일
--    select * from app.v_routine_adherence_weekly  order by bucket desc;      -- 주간
--    select * from app.v_routine_adherence_monthly order by bucket desc;      -- 월간
--    select * from app.v_routine_adherence_yearly  order by bucket desc;      -- 연간
--    select * from app.v_routine_adherence_category order by adherence_pct;   -- 카테고리별
-- ============================================================================
