-- ============================================================================
-- !!!  Ctrl+A (select ALL) then Run  !!!   (editor runs only highlighted text)
-- ============================================================================
-- fix_20261011_fcc_mill_templates_drop_signoff.sql
-- The account signature ("Best regards, Yun-Young Heo, Founder & CEO ...") is
-- appended to every outbound mail, so the templates' own closing block
--   "Best regards," / "Thank you,"  +  "--"  +  "MarineBio Group Inc. | Houston, TX, USA"
-- printed a second sign-off. This removes that block from the 3 FCC mill
-- templates and keeps the unsubscribe line as the last line of the body.
-- Carriage returns are dropped first, so CRLF bodies match too.
-- Idempotent (a body without the block is left as is).
-- Last statement is a verification select.
-- ============================================================================

update app.email_templates t
set body_plain =
      replace(
        replace(replace(t.body_plain, chr(13), ''),
          chr(10) || chr(10) || 'Best regards,' || chr(10) || chr(10) || '--' || chr(10)
            || 'MarineBio Group Inc. | Houston, TX, USA' || chr(10),
          chr(10) || chr(10)),
        chr(10) || chr(10) || 'Thank you,' || chr(10) || chr(10) || '--' || chr(10)
          || 'MarineBio Group Inc. | Houston, TX, USA' || chr(10),
        chr(10) || chr(10))
where t.party_type = 'paper_mill'
  and t.name like 'FCC Mill %'
  and t.body_plain like '%MarineBio Group Inc. | Houston, TX, USA%';

select name,
       right(body_plain, 160) as body_end,
       (body_plain like '%Best regards,%') as still_has_best_regards
from app.email_templates
where name like 'FCC Mill %'
order by name;
