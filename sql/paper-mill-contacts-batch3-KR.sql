-- ============================================================
-- Paper Mill 연락처 보강 - Batch 3 (Korea / KR 독립사)
-- 전략: 메일 가능한 독립사 우선. (큰 그룹=FORM 확인됨: KC/IP/Stora Enso/Metsä.)
--
-- HIGH 3 : Moorim 3사 공통 공개 inbox moorim@moorim.co.kr -> INSERT
-- FORM 6 : Hansol 4 mill + Hansol Papertech + Hankuk Paper = 고객문의 폼(공개 영업 inbox 없음)
-- QUEUED(다음): Asia Paper(0b0e4378) / Hongwon Paper(c0ba6f65) / Daehan Pulp·Kleannara(da6ee20c)
--               + KR 무사이트 5곳(Kleannara, Ssangyong C&B, Yuhan-Kimberly x3)
--
-- contact_type_id=2. 멱등 가드 포함.
-- ============================================================

-- ---------- 블록 1: HIGH (Moorim 3사, 공통 inbox) ----------
insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text,
   is_primary, is_decision_maker, source)
select v.organization_id, v.party_id, v.contact_type_id, v.email,
       v.given_name, v.family_name, v.full_name, v.title_text,
       v.is_primary, v.is_decision_maker, v.source
from (values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'715e8a6c-9bc4-4e41-afdb-a1827dd887ee'::uuid,2,
   'moorim@moorim.co.kr',null,null,null,'Group/General inbox',true,false,'homepage'),  -- Moorim P&P (펄프)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'86c35de3-a0cd-4456-9054-70c9c3642722'::uuid,2,
   'moorim@moorim.co.kr',null,null,null,'Group/General inbox',true,false,'homepage'),  -- Moorim Paper (진주)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'4785853a-d459-4ff7-b3cf-c831d0e55183'::uuid,2,
   'moorim@moorim.co.kr',null,null,null,'Group/General inbox',true,false,'homepage')   -- Moorim SP (대구)
) as v(organization_id, party_id, contact_type_id, email,
       given_name, family_name, full_name, title_text,
       is_primary, is_decision_maker, source)
where not exists (
  select 1 from app.contacts c
  where c.party_id = v.party_id and lower(c.email)=lower(v.email) and c.deleted_at is null
);

-- ---------- 블록 2: FORM (Hansol x5 + Hankuk, 고객문의 폼) ----------
insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text,
   is_primary, is_decision_maker, source)
select v.organization_id, v.party_id, v.contact_type_id, v.email,
       v.given_name, v.family_name, v.full_name, v.title_text,
       v.is_primary, v.is_decision_maker, v.source
from (values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'b2d7898e-1571-44c8-8db5-ce5f74f55334'::uuid,2,
   null,null,null,null,'Form 입력 (고객문의)',false,false,'form'),  -- Hansol Cheonan
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'a02f872c-2f9e-4863-b271-4ab9741d6be2'::uuid,2,
   null,null,null,null,'Form 입력 (고객문의)',false,false,'form'),  -- Hansol Daejeon
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'890ae7ee-12ae-4889-be24-c1f2155dbad0'::uuid,2,
   null,null,null,null,'Form 입력 (고객문의)',false,false,'form'),  -- Hansol Janghang
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'5110d2b4-d248-4a0f-a6cc-9e0580dff060'::uuid,2,
   null,null,null,null,'Form 입력 (고객문의)',false,false,'form'),  -- Hansol Shintanjin
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'c318be29-8a39-4b42-a2dd-71f6085518cc'::uuid,2,
   null,null,null,null,'Form 입력 (고객문의)',false,false,'form'),  -- Hansol Papertech
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'028f9b56-3780-4bb2-91f4-ca3514025484'::uuid,2,
   null,null,null,null,'Form 입력 (고객문의)',false,false,'form')   -- Hankuk Paper Mfg (recruit@만 공개)
) as v(organization_id, party_id, contact_type_id, email,
       given_name, family_name, full_name, title_text,
       is_primary, is_decision_maker, source)
where not exists (
  select 1 from app.contacts c
  where c.party_id = v.party_id and c.source='form' and c.deleted_at is null
);
