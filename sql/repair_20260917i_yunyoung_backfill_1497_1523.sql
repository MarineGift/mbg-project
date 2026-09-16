-- repair_20260917i_yunyoung_backfill_1497_1523.sql
-- After the size guard is deployed: re-read from uid 1496. 1496 (13 MB) is skipped by the
-- guard, 1497-1523 are stored, already-stored mail is skipped by the message_id check.
update app.mailcarrier_state
   set last_processed_uid = 1495,
       updated_at = now()
 where username = 'yunyoung.heo@marinebiogroup.com'
   and last_processed_uid > 1495
returning username, last_processed_uid;