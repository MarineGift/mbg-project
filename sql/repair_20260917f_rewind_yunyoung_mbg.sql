-- repair_20260917f_rewind_yunyoung_mbg.sql
-- Re-read yunyoung.heo@marinebiogroup.com from uid 418 (last known cursor before the
-- 2026-09-16 outage), because the BASF reply of 2026-09-16 was never stored.
-- Safe: already-stored mail is skipped by the message_id duplicate check.
update app.mailcarrier_state
   set last_processed_uid = 417,
       updated_at = now()
 where username = 'yunyoung.heo@marinebiogroup.com'
   and last_processed_uid > 417
returning username, kind, last_processed_uid;