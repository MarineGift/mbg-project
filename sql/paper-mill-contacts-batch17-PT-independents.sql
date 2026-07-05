-- ============================================================
-- Paper Mill 연락처 보강 - Batch 17 (포르투갈 독립사) [독립사 트랙 #2]
-- HIGH 5 (Altri): 그룹 본사 sede@altri.pt / Celbi geral.celbi@altri.pt (altri.pt, celbi.pt 공개)
--   · Altri Group/Caima Constância/Caima -> sede@altri.pt (그룹 일반)
--   · CELBI Figueira/Celbi -> geral.celbi@altri.pt
-- FORM 1: Renova(소비재 티슈, 공개 B2B inbox 없음)
-- 큐: Gescartao(Sonae) = 사이트 없음/Europac-DS Smith 편입 추정 -> 추후 확인
-- 멱등 가드 포함.
-- ============================================================

-- Altri 5 (HIGH)
insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text, is_primary, is_decision_maker, source)
select v.* from (values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'1634770c-644b-4940-8ff7-123e40056caa'::uuid,2, 'sede@altri.pt',null,null,null,'General inbox',true,false,'homepage'),  -- Altri Group
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'f0136dd9-8cb1-4c2a-8cc5-6c41feb4781c'::uuid,2, 'sede@altri.pt',null,null,null,'General inbox',true,false,'homepage'),  -- Altri Caima Constância
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'3589078d-6949-4636-a1cd-9aa0aee3198b'::uuid,2, 'sede@altri.pt',null,null,null,'General inbox',true,false,'homepage'),  -- Caima (Altri subsidiary)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'4ad06567-1803-4d74-ad14-ba1a19e8bcd9'::uuid,2, 'geral.celbi@altri.pt',null,null,null,'General inbox',true,false,'homepage'),  -- Altri CELBI Figueira da Foz
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'b9576e1c-d65d-4bfb-99d9-1965eb47ed87'::uuid,2, 'geral.celbi@altri.pt',null,null,null,'General inbox',true,false,'homepage')  -- Celbi (Altri subsidiary)
) as v(organization_id, party_id, contact_type_id, email,
       given_name, family_name, full_name, title_text, is_primary, is_decision_maker, source)
where not exists (
  select 1 from app.contacts c where c.party_id=v.party_id and lower(c.email)=lower(v.email) and c.deleted_at is null
);

-- Renova (FORM)
insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text, is_primary, is_decision_maker, source)
select v.* from (values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'beafc3f9-13c5-4578-841d-54b2e793d62a'::uuid,2, null,null,null,null,'Form 입력 (web contact form)',false,false,'form')  -- Renova
) as v(organization_id, party_id, contact_type_id, email,
       given_name, family_name, full_name, title_text, is_primary, is_decision_maker, source)
where not exists (
  select 1 from app.contacts c where c.party_id=v.party_id and c.source='form' and c.deleted_at is null
);
