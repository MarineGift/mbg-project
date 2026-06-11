-- ============================================================
-- 20260612020000_investor_stage_templates_seed.sql
-- Seed stage_checklist_templates + stage_task_templates for the
-- Investors pipeline (7 stages, after won/lost removal).
--
-- Replace semantics: existing templates for investor-pipeline
-- stages are deleted first, then re-seeded.
--
-- NOTE: organization_id is set explicitly because the column
-- default app.current_organization_id() returns NULL when run
-- from the Supabase SQL Editor (no user JWT).
--
-- Stage ids (verified live, DIAG 2026-06-12):
--   cold_outreach    1147f55e-297d-4c82-b74d-0e7976a2db8e
--   reply_received   3a311827-dc9f-47f1-a6cd-3073ff985658
--   first_meeting    be415dbe-f07a-4869-9989-254f27e25b0c
--   due_diligence    5584bab5-765e-418e-8364-a0694b9e5564
--   followup_meeting 052a2fb2-82b1-4a79-ad62-3a6d6118c384
--   term_sheet       fc2949cc-97a4-481e-b191-5ee8176fc927
--   contract         47a72672-b603-47f1-a8a3-2724f3352166
-- ============================================================

begin;

-- 0) Wipe existing investor-pipeline templates (tasks first: FK)
delete from app.stage_task_templates
where stage_id in (select id from app.stages
                   where pipeline_id = 'de80525d-5537-4971-ad8f-d2080a8e65b0');

delete from app.stage_checklist_templates
where stage_id in (select id from app.stages
                   where pipeline_id = 'de80525d-5537-4971-ad8f-d2080a8e65b0');

-- 1) Checklist templates
insert into app.stage_checklist_templates
  (organization_id, stage_id, title, sort_order)
values
-- Cold outreach
('b25de8f2-1020-482f-9012-183f63883169','1147f55e-297d-4c82-b74d-0e7976a2db8e','Research firm thesis, portfolio and conflicts',10),
('b25de8f2-1020-482f-9012-183f63883169','1147f55e-297d-4c82-b74d-0e7976a2db8e','Identify the right partner and verify contact email',20),
('b25de8f2-1020-482f-9012-183f63883169','1147f55e-297d-4c82-b74d-0e7976a2db8e','Personalize intro email with one-pager attached',30),
('b25de8f2-1020-482f-9012-183f63883169','1147f55e-297d-4c82-b74d-0e7976a2db8e','Set follow-up reminder (T+7 if no reply)',40),
-- Reply received
('b25de8f2-1020-482f-9012-183f63883169','3a311827-dc9f-47f1-a6cd-3073ff985658','Classify reply: interested / pass / referral',10),
('b25de8f2-1020-482f-9012-183f63883169','3a311827-dc9f-47f1-a6cd-3073ff985658','Answer investor questions within 24 hours',20),
('b25de8f2-1020-482f-9012-183f63883169','3a311827-dc9f-47f1-a6cd-3073ff985658','Send deck (shareable version)',30),
('b25de8f2-1020-482f-9012-183f63883169','3a311827-dc9f-47f1-a6cd-3073ff985658','Propose meeting time slots',40),
-- First meeting
('b25de8f2-1020-482f-9012-183f63883169','be415dbe-f07a-4869-9989-254f27e25b0c','Research attendees (background, recent investments)',10),
('b25de8f2-1020-482f-9012-183f63883169','be415dbe-f07a-4869-9989-254f27e25b0c','Prepare deck, demo and anticipated Q&A',20),
('b25de8f2-1020-482f-9012-183f63883169','be415dbe-f07a-4869-9989-254f27e25b0c','Confirm meeting and send agenda',30),
('b25de8f2-1020-482f-9012-183f63883169','be415dbe-f07a-4869-9989-254f27e25b0c','Send recap and materials within 24 hours',40),
('b25de8f2-1020-482f-9012-183f63883169','be415dbe-f07a-4869-9989-254f27e25b0c','Record meeting notes in CRM',50),
-- Due diligence
('b25de8f2-1020-482f-9012-183f63883169','5584bab5-765e-418e-8364-a0694b9e5564','Open data room and grant access',10),
('b25de8f2-1020-482f-9012-183f63883169','5584bab5-765e-418e-8364-a0694b9e5564','Provide financial model and cap table',20),
('b25de8f2-1020-482f-9012-183f63883169','5584bab5-765e-418e-8364-a0694b9e5564','Prepare customer and technical reference list',30),
('b25de8f2-1020-482f-9012-183f63883169','5584bab5-765e-418e-8364-a0694b9e5564','Maintain DD question log',40),
('b25de8f2-1020-482f-9012-183f63883169','5584bab5-765e-418e-8364-a0694b9e5564','Weekly DD status check-in',50),
-- Follow-up meeting
('b25de8f2-1020-482f-9012-183f63883169','052a2fb2-82b1-4a79-ad62-3a6d6118c384','Address open concerns from due diligence',10),
('b25de8f2-1020-482f-9012-183f63883169','052a2fb2-82b1-4a79-ad62-3a6d6118c384','Update metrics and traction since first meeting',20),
('b25de8f2-1020-482f-9012-183f63883169','052a2fb2-82b1-4a79-ad62-3a6d6118c384','Prepare for partner / IC meeting',30),
('b25de8f2-1020-482f-9012-183f63883169','052a2fb2-82b1-4a79-ad62-3a6d6118c384','Confirm decision timeline',40),
-- Term sheet
('b25de8f2-1020-482f-9012-183f63883169','fc2949cc-97a4-481e-b191-5ee8176fc927','Review term sheet with legal counsel',10),
('b25de8f2-1020-482f-9012-183f63883169','fc2949cc-97a4-481e-b191-5ee8176fc927','Benchmark valuation and key clauses',20),
('b25de8f2-1020-482f-9012-183f63883169','fc2949cc-97a4-481e-b191-5ee8176fc927','Negotiate redlines',30),
('b25de8f2-1020-482f-9012-183f63883169','fc2949cc-97a4-481e-b191-5ee8176fc927','Obtain board / shareholder approval',40),
('b25de8f2-1020-482f-9012-183f63883169','fc2949cc-97a4-481e-b191-5ee8176fc927','Sign term sheet',50),
-- Contract
('b25de8f2-1020-482f-9012-183f63883169','47a72672-b603-47f1-a8a3-2724f3352166','Draft definitive agreements (SPA / SHA)',10),
('b25de8f2-1020-482f-9012-183f63883169','47a72672-b603-47f1-a8a3-2724f3352166','Complete closing conditions checklist',20),
('b25de8f2-1020-482f-9012-183f63883169','47a72672-b603-47f1-a8a3-2724f3352166','Complete KYC and confirm wire instructions',30),
('b25de8f2-1020-482f-9012-183f63883169','47a72672-b603-47f1-a8a3-2724f3352166','Collect all signatures',40),
('b25de8f2-1020-482f-9012-183f63883169','47a72672-b603-47f1-a8a3-2724f3352166','Confirm funds received and issue shares',50);

-- 2) Task templates (linked to a checklist item where natural)
insert into app.stage_task_templates
  (organization_id, stage_id, checklist_template_id, title, description,
   default_priority, due_in_days, sort_order)
values
-- Cold outreach
('b25de8f2-1020-482f-9012-183f63883169','1147f55e-297d-4c82-b74d-0e7976a2db8e',
 (select id from app.stage_checklist_templates where stage_id='1147f55e-297d-4c82-b74d-0e7976a2db8e' and title='Research firm thesis, portfolio and conflicts'),
 'Research investor fit','Check sector/stage focus, recent deals, portfolio conflicts and fund dry powder.','high',2,10),
('b25de8f2-1020-482f-9012-183f63883169','1147f55e-297d-4c82-b74d-0e7976a2db8e',
 (select id from app.stage_checklist_templates where stage_id='1147f55e-297d-4c82-b74d-0e7976a2db8e' and title='Personalize intro email with one-pager attached'),
 'Send personalized intro email','Tailor the opening to the firm thesis; attach one-pager; one clear CTA.','high',3,20),
('b25de8f2-1020-482f-9012-183f63883169','1147f55e-297d-4c82-b74d-0e7976a2db8e',
 (select id from app.stage_checklist_templates where stage_id='1147f55e-297d-4c82-b74d-0e7976a2db8e' and title='Set follow-up reminder (T+7 if no reply)'),
 'Follow up if no reply','Send a polite follow-up 7 days after the intro email.','medium',7,30),
-- Reply received
('b25de8f2-1020-482f-9012-183f63883169','3a311827-dc9f-47f1-a6cd-3073ff985658',
 (select id from app.stage_checklist_templates where stage_id='3a311827-dc9f-47f1-a6cd-3073ff985658' and title='Answer investor questions within 24 hours'),
 'Respond to investor reply','Acknowledge within 24h; answer questions or route the referral.','high',1,10),
('b25de8f2-1020-482f-9012-183f63883169','3a311827-dc9f-47f1-a6cd-3073ff985658',
 (select id from app.stage_checklist_templates where stage_id='3a311827-dc9f-47f1-a6cd-3073ff985658' and title='Propose meeting time slots'),
 'Schedule first meeting','Offer 2-3 time slots; send calendar invite with agenda.','high',3,20),
('b25de8f2-1020-482f-9012-183f63883169','3a311827-dc9f-47f1-a6cd-3073ff985658',
 null,
 'Log investor questions in deal notes','Record asked questions and concerns for DD preparation.','medium',2,30),
-- First meeting
('b25de8f2-1020-482f-9012-183f63883169','be415dbe-f07a-4869-9989-254f27e25b0c',
 (select id from app.stage_checklist_templates where stage_id='be415dbe-f07a-4869-9989-254f27e25b0c' and title='Prepare deck, demo and anticipated Q&A'),
 'Prepare pitch and Q&A sheet','Rehearse the deck; prepare answers for likely technical and market questions.','high',2,10),
('b25de8f2-1020-482f-9012-183f63883169','be415dbe-f07a-4869-9989-254f27e25b0c',
 (select id from app.stage_checklist_templates where stage_id='be415dbe-f07a-4869-9989-254f27e25b0c' and title='Send recap and materials within 24 hours'),
 'Send post-meeting recap email','Thank-you note, recap of discussion, requested materials attached.','high',1,20),
('b25de8f2-1020-482f-9012-183f63883169','be415dbe-f07a-4869-9989-254f27e25b0c',
 null,
 'Agree on next steps and timeline','Confirm what the investor needs to move to due diligence.','medium',3,30),
-- Due diligence
('b25de8f2-1020-482f-9012-183f63883169','5584bab5-765e-418e-8364-a0694b9e5564',
 (select id from app.stage_checklist_templates where stage_id='5584bab5-765e-418e-8364-a0694b9e5564' and title='Open data room and grant access'),
 'Set up data room access','Verify documents are current; grant investor-side access.','high',2,10),
('b25de8f2-1020-482f-9012-183f63883169','5584bab5-765e-418e-8364-a0694b9e5564',
 (select id from app.stage_checklist_templates where stage_id='5584bab5-765e-418e-8364-a0694b9e5564' and title='Maintain DD question log'),
 'Respond to outstanding DD requests','Keep response time under 3 business days per request.','high',3,20),
('b25de8f2-1020-482f-9012-183f63883169','5584bab5-765e-418e-8364-a0694b9e5564',
 (select id from app.stage_checklist_templates where stage_id='5584bab5-765e-418e-8364-a0694b9e5564' and title='Prepare customer and technical reference list'),
 'Collect and brief reference contacts','Confirm references are willing and briefed before sharing.','medium',5,30),
-- Follow-up meeting
('b25de8f2-1020-482f-9012-183f63883169','052a2fb2-82b1-4a79-ad62-3a6d6118c384',
 (select id from app.stage_checklist_templates where stage_id='052a2fb2-82b1-4a79-ad62-3a6d6118c384' and title='Prepare for partner / IC meeting'),
 'Prepare partner-meeting materials','Updated deck addressing DD findings and open concerns.','high',3,10),
('b25de8f2-1020-482f-9012-183f63883169','052a2fb2-82b1-4a79-ad62-3a6d6118c384',
 (select id from app.stage_checklist_templates where stage_id='052a2fb2-82b1-4a79-ad62-3a6d6118c384' and title='Update metrics and traction since first meeting'),
 'Send updated KPI one-pager','Fresh numbers since the first meeting; highlight momentum.','medium',2,20),
('b25de8f2-1020-482f-9012-183f63883169','052a2fb2-82b1-4a79-ad62-3a6d6118c384',
 (select id from app.stage_checklist_templates where stage_id='052a2fb2-82b1-4a79-ad62-3a6d6118c384' and title='Confirm decision timeline'),
 'Confirm IC date and decision process','Know exactly when and how the firm decides.','medium',5,30),
-- Term sheet
('b25de8f2-1020-482f-9012-183f63883169','fc2949cc-97a4-481e-b191-5ee8176fc927',
 (select id from app.stage_checklist_templates where stage_id='fc2949cc-97a4-481e-b191-5ee8176fc927' and title='Review term sheet with legal counsel'),
 'Legal review of term sheet','Full review of economics and control terms with counsel.','high',3,10),
('b25de8f2-1020-482f-9012-183f63883169','fc2949cc-97a4-481e-b191-5ee8176fc927',
 (select id from app.stage_checklist_templates where stage_id='fc2949cc-97a4-481e-b191-5ee8176fc927' and title='Negotiate redlines'),
 'Negotiation call on key terms','Valuation, board seats, liquidation preference, pro-rata.','high',5,20),
('b25de8f2-1020-482f-9012-183f63883169','fc2949cc-97a4-481e-b191-5ee8176fc927',
 (select id from app.stage_checklist_templates where stage_id='fc2949cc-97a4-481e-b191-5ee8176fc927' and title='Sign term sheet'),
 'Internal approval and signature','Board/shareholder sign-off, then execute the term sheet.','high',7,30),
-- Contract
('b25de8f2-1020-482f-9012-183f63883169','47a72672-b603-47f1-a8a3-2724f3352166',
 (select id from app.stage_checklist_templates where stage_id='47a72672-b603-47f1-a8a3-2724f3352166' and title='Draft definitive agreements (SPA / SHA)'),
 'Coordinate definitive agreement drafting','Drive SPA/SHA drafting with counsel; track turnarounds.','high',5,10),
('b25de8f2-1020-482f-9012-183f63883169','47a72672-b603-47f1-a8a3-2724f3352166',
 (select id from app.stage_checklist_templates where stage_id='47a72672-b603-47f1-a8a3-2724f3352166' and title='Complete closing conditions checklist'),
 'Clear closing conditions','Work through every condition precedent before signing.','high',7,20),
('b25de8f2-1020-482f-9012-183f63883169','47a72672-b603-47f1-a8a3-2724f3352166',
 (select id from app.stage_checklist_templates where stage_id='47a72672-b603-47f1-a8a3-2724f3352166' and title='Confirm funds received and issue shares'),
 'Confirm wire and issue share certificates','Verify funds received; issue shares; update cap table.','high',10,30);

commit;

-- Verify (expect 31 checklist rows / 21 task rows):
-- select s.code, count(c.id) as checklist_items
-- from app.stages s
-- left join app.stage_checklist_templates c on c.stage_id = s.id
-- where s.pipeline_id = 'de80525d-5537-4971-ad8f-d2080a8e65b0'
-- group by s.code, s.sort_order order by s.sort_order;
--
-- select s.code, count(t.id) as task_templates
-- from app.stages s
-- left join app.stage_task_templates t on t.stage_id = s.id
-- where s.pipeline_id = 'de80525d-5537-4971-ad8f-d2080a8e65b0'
-- group by s.code, s.sort_order order by s.sort_order;
