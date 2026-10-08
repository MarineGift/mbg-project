-- ############################################################
-- HOW TO RUN: click in the editor, Ctrl+A (SELECT ALL), then Run the WHOLE file.
-- ############################################################
-- migration_20261008_mentor_gender.sql
-- app.mentors.gender: male / female / unknown. Default unknown (shown as
-- Unconfirmed). Set male or female only once confirmed. Idempotent.

alter table app.mentors
  add column if not exists gender text not null default 'unknown';

alter table app.mentors drop constraint if exists mentors_gender_chk;

alter table app.mentors
  add constraint mentors_gender_chk check (gender in ('male', 'female', 'unknown'));

notify pgrst, 'reload schema';

select gender, count(*) as mentors
from app.mentors
group by gender
order by gender;
