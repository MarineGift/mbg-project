-- ============================================================
-- seed_maskpack_us_retail_assets.sql (2026-07-18)
-- Marine Pack specifics on top of playbook v2:
--   (1) party_type 'retailer' (guarded, max(id)+1 pattern)
--   (2) US clean beauty retail parties x6 (post-funded B2B targets and
--       copy research channels): Credo Beauty, The Detox Market,
--       Grove Collaborative, Ulta Beauty, Thrive Market, Sephora
--   (3) Marine Pack product tasks on the Indiegogo deal x4
--       (patents + NET cert one-pager, US model video re-edit,
--        thermal demo b-roll, clean beauty copy benchmark)
--
-- Run AFTER seed_crowdfunding_playbook_v2.sql.
-- Conventions: no BEGIN, no DO-blocks, NOT EXISTS guards, org id explicit.
-- Supabase SQL Editor. Re-runnable.
-- ============================================================

-- (1) party_type: retailer (guarded)
insert into app.party_types (id, code, display_name_en, display_name_ko, display_name_ja, sort_order, is_active)
select (select coalesce(max(id),0)+1 from app.party_types),
       'retailer', 'Retailer', '리테일러', '小売業者',
       (select coalesce(max(sort_order),0)+1 from app.party_types), true
where not exists (select 1 from app.party_types where code = 'retailer');

-- (2) US clean beauty retail parties (guarded by domain_normalized)
insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, region, city,
   website, domain_normalized, source, intro_ko, intro_en)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.party_name,
       (select id from app.party_types where code = 'retailer'),
       (select id from app.entity_types where code = 'company'),
       'US', v.region, v.city, v.website, v.domain_norm, 'us_clean_beauty_2026Q3',
       v.intro_ko, v.intro_en
from (values
  ('Credo Beauty','California','San Francisco','https://credobeauty.com','credobeauty.com',
   '클린뷰티 전문 버티컬 커머스 1위. Credo Clean Standard 성분 기준, 지속가능 패키징 가이드라인. 입점 브랜드 90 pct가 여성 주도 기업. funded 이후 B2B 1순위.',
   'Leading clean beauty vertical retailer. Credo Clean Standard ingredient bar, sustainable packaging guidelines. Top B2B target after the campaign.'),
  ('The Detox Market','California','Los Angeles','https://www.thedetoxmarket.com','thedetoxmarket.com',
   '클린뷰티 양대 산맥. 친환경, 윤리 생산 인디 브랜드 발굴에 강함. 신생 브랜드 입점 문턱이 상대적으로 낮음.',
   'Major clean beauty retailer, strong at discovering eco and ethical indie brands. Relatively open door to newer brands.'),
  ('Grove Collaborative','California','San Francisco','https://www.grove.co','grove.co',
   '친환경, 크루얼티프리 퍼스널케어 정기구독 플랫폼. B-Corp 인증. 구독 모델이라 소모품(마스크팩) 재구매와 궁합이 좋음.',
   'Eco and cruelty-free personal care subscription platform, B-Corp certified. Subscription model fits repeat-purchase mask products.'),
  ('Ulta Beauty','Illinois','Bolingbrook','https://www.ulta.com','ulta.com',
   '미국 최대 뷰티 유통. Conscious Beauty 전용관 운영. 지속가능 패키징 기준이 바이오 기반 소재 포함 - 해조 섬유와 직접 부합.',
   'Largest US beauty retailer. Runs the Conscious Beauty program. Its sustainable packaging bar includes bio-sourced material - a direct match to sea fiber.'),
  ('Thrive Market','California','Los Angeles','https://thrivemarket.com','thrivemarket.com',
   '유기농, 친환경 멤버십 온라인 마켓. 탄소중립 배송, 플라스틱 중립 정책. 에코 컨슈머 필수 채널.',
   'Membership-based organic and eco marketplace. Carbon-neutral delivery and plastic-neutral policy. Core eco consumer channel.'),
  ('Sephora','California','San Francisco','https://www.sephora.com','sephora.com',
   '대중 채널 중 클린뷰티 트래픽 최대. Clean at Sephora 및 Clean plus Planet Positive 배지 프로그램 운영.',
   'Highest clean beauty traffic among mass channels. Runs the Clean at Sephora and Clean plus Planet Positive badge programs.')
) as v(party_name, region, city, website, domain_norm, intro_ko, intro_en)
where not exists (select 1 from app.parties p
                  where p.domain_normalized = v.domain_norm and p.deleted_at is null);

-- (3) Marine Pack product tasks on the Indiegogo deal (guarded by title)
insert into app.tasks
  (deal_id, stage_id, title, description, status, priority, due_at, extra_data, organization_id)
select d.id,
       (select s.id from app.stages s
          join app.pipelines pl on pl.id = s.pipeline_id
         where pl.code = 'crowdfunding' and s.code = v.stage_code),
       v.title, v.description, 'pending', v.priority,
       now() + make_interval(days => v.due_days),
       '{"src":"maskpack_seed_2026Q3"}'::jsonb,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.deals d,
     (values
       ('research','Patents and NET cert one-pager (EN)',
        'Two registered sea fiber mask patents plus the Korea NET (New Excellent Technology) certification, condensed to a single English proof page for the campaign and B2B decks.',
        'high',7),
       ('research','Benchmark clean beauty copy (Credo, Ulta CB)',
        'Study top mask listings at Credo Beauty, The Detox Market and Ulta Conscious Beauty. Capture phrasing patterns (99.9 pct natural, biodegradable sea fiber, cruelty free) and feed the EN page copy.',
        'medium',7),
       ('application','Re-edit the US model video to the current design',
        'Reuse the existing US model footage. Swap pack shots and the end card to the new Marine Pack design, add EN captions, cut a 30-60 sec hero edit plus 15 sec ad cuts.',
        'high',10),
       ('application','Thermal demo b-roll: skin temperature drop',
        'Film a thermal camera clip showing the cooling effect on skin, referencing the Korean beauty show verification. Keep wording sensory and cosmetic (cools, soothes) - no medical claims.',
        'medium',10)
     ) as v(stage_code, title, description, priority, due_days)
where d.deal_name = 'Mask Pack - Indiegogo US Campaign'
  and d.campaign_id = 'd0000000-0000-4000-8000-0000000000fc'::uuid
  and d.deleted_at is null
  and not exists (select 1 from app.tasks t
                  where t.deal_id = d.id and t.title = v.title and t.deleted_at is null);

-- ============================================================
-- VERIFY (read-only)
-- ============================================================

-- V1: retailer parties (expect 6)
select p.party_name, p.city, p.domain_normalized
from app.parties p
join app.party_types pt on pt.id = p.party_type_id
where pt.code = 'retailer' and p.deleted_at is null
order by p.party_name;

-- V2: Marine Pack custom tasks on the Indiegogo deal (expect 12 total:
--     8 previous seed + 4 this seed)
select t.title, s.code as stage, t.priority, t.due_at::date
from app.tasks t
join app.deals d on d.id = t.deal_id
left join app.stages s on s.id = t.stage_id
where d.deal_name = 'Mask Pack - Indiegogo US Campaign'
  and t.extra_data->>'src' = 'maskpack_seed_2026Q3'
  and t.deleted_at is null
order by s.code, t.due_at;
