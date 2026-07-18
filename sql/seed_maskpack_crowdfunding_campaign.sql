-- ============================================================
-- seed_maskpack_crowdfunding_campaign.sql (2026-07-18)
-- Mask pack reward-crowdfunding campaign on the EXISTING crowdfunding
-- pipeline (research -> outreach -> application -> review -> live_campaign
-- -> funded / closed).
--
-- Creates:
--   (1) party_type 'cf_platform' (guarded, max(id)+1 pattern)
--   (2) parties: Indiegogo, Kickstarter, Wadiz (entity_type 'company')
--   (3) campaign d0000000-0000-4000-8000-0000000000fc  <- deals.campaign_id is NOT NULL
--   (4) deals: Indiegogo US (high) + Wadiz Korea (medium) at stage 'research'
--   (5) playbook instantiation via app.apply_stage_playbook(...)
--   (6) mask-pack-specific custom tasks (claims, OEM quotes, lead math,
--       DKIM/DMARC, US label pack, safety dossier, samples, nurture sequence)
--
-- Conventions: no BEGIN, no DO-blocks, self-contained statements,
-- NOT EXISTS guards (idempotent), org id explicit, stages resolved by code.
-- Run in the Supabase SQL Editor. Safe to re-run.
-- ============================================================

-- (1) party_type: cf_platform (guarded)
insert into app.party_types (id, code, display_name_en, display_name_ko, display_name_ja, sort_order, is_active)
select (select coalesce(max(id),0)+1 from app.party_types),
       'cf_platform', 'Crowdfunding Platform', '크라우드펀딩 플랫폼', 'クラウドファンディング',
       (select coalesce(max(sort_order),0)+1 from app.party_types), true
where not exists (select 1 from app.party_types where code = 'cf_platform');

-- (2) platform parties (guarded by domain_normalized)
insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, region, city,
   website, domain_normalized, source, intro_ko, intro_en)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'Indiegogo',
       (select id from app.party_types where code = 'cf_platform'),
       (select id from app.entity_types where code = 'company'),
       'US', 'California', 'San Francisco',
       'https://www.indiegogo.com', 'indiegogo.com', 'maskpack_seed_2026Q3',
       '리워드 크라우드펀딩 플랫폼. 뷰티, 웰니스 커뮤니티가 강하고 Flexible Funding과 InDemand 후속 판매를 지원.',
       'Reward crowdfunding platform, strong beauty and wellness community, flexible funding and InDemand post-campaign sales.'
where not exists (select 1 from app.parties p
                  where p.domain_normalized = 'indiegogo.com' and p.deleted_at is null);

insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, region, city,
   website, domain_normalized, source, intro_ko, intro_en)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'Kickstarter',
       (select id from app.party_types where code = 'cf_platform'),
       (select id from app.entity_types where code = 'company'),
       'US', 'New York', 'Brooklyn',
       'https://www.kickstarter.com', 'kickstarter.com', 'maskpack_seed_2026Q3',
       '리워드 크라우드펀딩 플랫폼. All-or-Nothing 방식, 최대 규모 백커 베이스. 2014년 규정 개정 이후 뷰티 제품 허용.',
       'Reward crowdfunding platform, all-or-nothing funding, largest backer base. Beauty products allowed since the 2014 rule change.'
where not exists (select 1 from app.parties p
                  where p.domain_normalized = 'kickstarter.com' and p.deleted_at is null);

insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, region, city,
   website, domain_normalized, source, intro_ko, intro_en)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, 'Wadiz',
       (select id from app.party_types where code = 'cf_platform'),
       (select id from app.entity_types where code = 'company'),
       'KR', 'Gyeonggi', 'Seongnam',
       'https://www.wadiz.kr', 'wadiz.kr', 'maskpack_seed_2026Q3',
       '국내 최대 리워드 크라우드펀딩 플랫폼. 뷰티 기획전과 소상공인 지원사업 운영.',
       'Leading Korean reward crowdfunding platform, dedicated beauty showcases and small-business support programs.'
where not exists (select 1 from app.parties p
                  where p.domain_normalized = 'wadiz.kr' and p.deleted_at is null);

-- (3) campaign (deterministic id ...fc, created_by = YunYoung)
insert into app.campaigns (id, organization_id, created_by, name, campaign_type, description, status, start_date)
select 'd0000000-0000-4000-8000-0000000000fc'::uuid,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       '551fc4a0-b365-47eb-bf2f-0c3f594001c0'::uuid,
       'Mask Pack Crowdfunding 2026',
       'crowdfunding',
       'Reward crowdfunding to finance the first mask pack production run. Primary: Indiegogo US (flexible funding plus InDemand). Secondary: Wadiz Korea. Lead-first strategy, goal USD 30K-50K.',
       'active',
       date '2026-07-18'
where not exists (select 1 from app.campaigns c
                  where c.id = 'd0000000-0000-4000-8000-0000000000fc'::uuid);

-- (4a) deal: Indiegogo US (primary, high)
insert into app.deals
  (party_id, pipeline_id, current_stage_id, campaign_id, deal_name, status, value_amount,
   value_currency, priority, source, extra_data, organization_id, stage_entered_at, created_at, updated_at)
select p.id,
       (select id from app.pipelines where code = 'crowdfunding'),
       (select s.id from app.stages s
          join app.pipelines pl on pl.id = s.pipeline_id
         where pl.code = 'crowdfunding' and s.code = 'research'),
       'd0000000-0000-4000-8000-0000000000fc'::uuid,
       'Mask Pack - Indiegogo US Campaign',
       'open', 40000, 'USD', 'high', 'maskpack_seed_2026Q3',
       '{"src":"maskpack_seed_2026Q3","track":"us_primary"}'::jsonb,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid, now(), now(), now()
from app.parties p
where p.domain_normalized = 'indiegogo.com' and p.deleted_at is null
  and not exists (select 1 from app.deals d
                  where d.party_id = p.id
                    and d.campaign_id = 'd0000000-0000-4000-8000-0000000000fc'::uuid
                    and d.deleted_at is null);

-- (4b) deal: Wadiz Korea (secondary, medium)
insert into app.deals
  (party_id, pipeline_id, current_stage_id, campaign_id, deal_name, status, value_amount,
   value_currency, priority, source, extra_data, organization_id, stage_entered_at, created_at, updated_at)
select p.id,
       (select id from app.pipelines where code = 'crowdfunding'),
       (select s.id from app.stages s
          join app.pipelines pl on pl.id = s.pipeline_id
         where pl.code = 'crowdfunding' and s.code = 'research'),
       'd0000000-0000-4000-8000-0000000000fc'::uuid,
       'Mask Pack - Wadiz Korea Campaign',
       'open', 30000000, 'KRW', 'medium', 'maskpack_seed_2026Q3',
       '{"src":"maskpack_seed_2026Q3","track":"kr_secondary"}'::jsonb,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid, now(), now(), now()
from app.parties p
where p.domain_normalized = 'wadiz.kr' and p.deleted_at is null
  and not exists (select 1 from app.deals d
                  where d.party_id = p.id
                    and d.campaign_id = 'd0000000-0000-4000-8000-0000000000fc'::uuid
                    and d.deleted_at is null);

-- (5) instantiate the research-stage playbook on both deals (function is idempotent)
select app.apply_stage_playbook(d.id, d.current_stage_id)
from app.deals d
where d.campaign_id = 'd0000000-0000-4000-8000-0000000000fc'::uuid
  and d.deleted_at is null;

-- (6) mask-pack-specific custom tasks on the Indiegogo deal
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
       ('research','Finalize FDA-safe claims copy (EN master)',
        'List allowed cosmetic claims (moisturizes, improves the appearance of fine lines) and banned drug claims (anti-acne, heals, repairs skin barrier). Lock the master EN copy before page design and platform review.',
        'high',5),
       ('research','Collect 3 OEM quotes: MOQ, unit cost, lead time',
        'Get quotes at 3 sheet mask OEM makers. Record MOQ, unit cost, production lead time, CGMP or ISO22716 status. These numbers drive the funding goal and the delivery promise.',
        'high',7),
       ('research','Back-calculate lead target and ad budget',
        'Goal amount -> needed email leads (3-5 pct list conversion, AOV about USD 40) -> Meta Ads budget (USD 1-3 per lead). Output: one-page funding math memo.',
        'high',5),
       ('research','US label pack: INCI, net contents, MoCRA contact',
        'Draft the pouch label: full INCI ingredient list, net contents (fl oz plus mL), distributor name with US address, Made in Korea origin marking, adverse event contact per MoCRA.',
        'medium',10),
       ('research','Safety substantiation dossier (EN)',
        'Compile patch test or HRIPT summaries plus a patent one-pager in English. MoCRA keeps the safety substantiation duty even under the small business exemption.',
        'medium',14),
       ('research','Photo-ready samples and pouch mockups (10-20 units)',
        'Short run only: final pouch design via print or sticker mockups, good enough to shoot hero photos and the campaign video.',
        'medium',14),
       ('outreach','Fix DKIM and DMARC before any consumer sends',
        'Publish DKIM, move DMARC beyond p=none, check PTR alignment. Consumer inbox placement depends on this. Reuse the sequence worker for lead nurture only after this passes.',
        'high',7),
       ('outreach','Build pre-launch nurture sequence in URM',
        'New opt-in lead sequence (separate track, not cold outreach): welcome, brand story, tech proof, early-bird offer, launch alert. Keep the do-not-send guard wired as usual.',
        'high',10)
     ) as v(stage_code, title, description, priority, due_days)
where d.deal_name = 'Mask Pack - Indiegogo US Campaign'
  and d.campaign_id = 'd0000000-0000-4000-8000-0000000000fc'::uuid
  and d.deleted_at is null
  and not exists (select 1 from app.tasks t
                  where t.deal_id = d.id and t.title = v.title and t.deleted_at is null);

-- (6b) Wadiz-specific task
insert into app.tasks
  (deal_id, stage_id, title, description, status, priority, due_at, extra_data, organization_id)
select d.id, d.current_stage_id,
       'Wadiz submission package check',
       '책임판매업 등록번호 반영, 국문 상세페이지 준비, 와디즈 우리동네 크라우드펀딩 지원사업 신청 검토.',
       'pending', 'medium', now() + make_interval(days => 14),
       '{"src":"maskpack_seed_2026Q3"}'::jsonb,
       'b25de8f2-1020-482f-9012-183f63883169'::uuid
from app.deals d
where d.deal_name = 'Mask Pack - Wadiz Korea Campaign'
  and d.campaign_id = 'd0000000-0000-4000-8000-0000000000fc'::uuid
  and d.deleted_at is null
  and not exists (select 1 from app.tasks t
                  where t.deal_id = d.id and t.title = 'Wadiz submission package check' and t.deleted_at is null);

-- ============================================================
-- VERIFY (run after the seed, read-only)
-- ============================================================

-- V1: campaign + deals (expect 2 deals at stage research)
select c.name as campaign, d.deal_name, s.code as stage, d.priority, d.value_amount, d.value_currency
from app.deals d
join app.campaigns c on c.id = d.campaign_id
join app.stages s on s.id = d.current_stage_id
where d.campaign_id = 'd0000000-0000-4000-8000-0000000000fc'::uuid and d.deleted_at is null
order by d.priority desc;

-- V2: task counts per deal (Indiegogo: playbook research tasks + 8 custom, Wadiz: playbook + 1)
select d.deal_name, count(*) filter (where t.extra_data ? 'pb_task') as playbook_tasks,
       count(*) filter (where t.extra_data->>'src' = 'maskpack_seed_2026Q3') as custom_tasks
from app.tasks t
join app.deals d on d.id = t.deal_id
where d.campaign_id = 'd0000000-0000-4000-8000-0000000000fc'::uuid
  and t.deleted_at is null
group by d.deal_name;

-- V3: platform parties present (expect 3)
select p.party_name, pt.code, p.country_code, p.domain_normalized
from app.parties p
join app.party_types pt on pt.id = p.party_type_id
where pt.code = 'cf_platform' and p.deleted_at is null
order by p.party_name;
