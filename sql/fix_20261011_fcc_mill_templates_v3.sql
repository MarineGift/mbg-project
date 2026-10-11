-- ============================================================================
-- !!!  Ctrl+A (select ALL) then Run  !!!   (editor runs only highlighted text)
-- ============================================================================
-- fix_20261011_fcc_mill_templates_v3.sql
-- v3 of the 3 FCC paper-mill templates: adds a short introduction of FCC at
-- the top of each mail - an innovative filler that replaces expensive pulp,
-- and why it can (calcium carbonate bound with fine cellulose fibrils, so the
-- sheet keeps its strength at much higher filler content).
-- Everything else from v2 is kept (Korean mill proof, global filler makers,
-- tell your filler supplier, No Capex, reply for material, LinkedIn).
-- Names stay the same, so mail history and follow-up links are kept.
-- Last statement is a verification select.
-- ============================================================================

update app.email_templates t
set subject = v.subject,
    body_plain = v.body,
    body_html = null
from (values
(
  'FCC Mill 1 - Pulp cost (initial)',
  $t$Replace part of your pulp with filler - No Capex, proven in production$t$,
  $t$Hello,

I am {{sender_name}}, {{sender_title}} of {{sender_company}}.

FCC (Flexible Calcium Carbonate) is an innovative filler that replaces expensive pulp. It is calcium carbonate bound with fine cellulose fibrils, so the sheet keeps its strength at much higher filler content. More filler means less fiber, and fiber is the most expensive part of the furnish. FCC is our patented technology.

FCC is proven at mill scale:
- A leading Korean paper mill ran FCC on its paper machines and then placed orders for it.
- Based on those results, global top filler manufacturers have adopted FCC and now supply it through the PCC and GCC operations mills already use.

What it means for {{company_name}}:
- No Capex. FCC is produced by your filler supplier. There is no new equipment to buy and no new vendor to qualify.
- Less pulp per ton. Filler content can rise and take the place of fiber.
- Strength is kept. In published trials, FCC sheets at 60% ash matched or exceeded GCC sheets at 30% ash.

Two easy next steps:
1. Tell your current filler supplier that you would like to use FCC. A filler manufacturer working with FCC may then contact you directly.
2. Or simply reply to this e-mail, and we will send you the technical material.

You can also find background on FCC and our work on LinkedIn:
https://www.linkedin.com/in/yunyoung-heo-a2640a195/

If furnish and filler decisions sit with someone else, I would be grateful if you could forward this to your technical or procurement lead.

Best regards,

--
MarineBio Group Inc. | Houston, TX, USA
To stop receiving these emails, reply with "unsubscribe".$t$
),
(
  'FCC Mill 2 - Supplier sentence (follow-up)',
  $t$FCC at {{company_name}}: proven, No Capex, one message to your filler supplier$t$,
  $t$Hello,

A short follow-up on FCC (Flexible Calcium Carbonate), an innovative filler that replaces expensive pulp. Its fine cellulose fibrils keep the sheet strong at much higher filler content, so less fiber is needed per ton.

A leading Korean paper mill applied FCC in production and then ordered it, and global top filler manufacturers now supply it. For a mill, FCC replaces part of the pulp with No Capex: nothing to buy, nothing to install.

The only step is a message to your current PCC or GCC supplier:
"We would like to use FCC to replace part of our pulp."
A filler manufacturer working with FCC can then contact you.

If you would like the technical material first, reply to this e-mail and I will send it. Background is also on LinkedIn:
https://www.linkedin.com/in/yunyoung-heo-a2640a195/

Best regards,

--
MarineBio Group Inc. | Houston, TX, USA
To stop receiving these emails, reply with "unsubscribe".$t$
),
(
  'FCC Mill 3 - Last note (follow-up)',
  $t$Last note on FCC - who handles filler and furnish at {{company_name}}?$t$,
  $t$Hello,

I have written twice about FCC (Flexible Calcium Carbonate), an innovative filler that replaces expensive pulp in the sheet with No Capex. It is already running at a leading Korean paper mill and is supplied by global top filler manufacturers. I do not want to crowd your inbox, so this is my last note.

If lowering fiber cost is on your agenda, two options:
- Tell your filler supplier you want FCC, and a filler manufacturer can contact you.
- Or reply to this e-mail, and I will send the technical material.

And if someone else at {{company_name}} owns furnish and filler decisions, a name would help me a lot. Background is on LinkedIn:
https://www.linkedin.com/in/yunyoung-heo-a2640a195/

Thank you,

--
MarineBio Group Inc. | Houston, TX, USA
To stop receiving these emails, reply with "unsubscribe".$t$
)
) as v(name, subject, body)
where t.name = v.name
  and t.party_type = 'paper_mill';

select name, subject, left(body_plain, 260) as body_start, is_active
from app.email_templates
where name like 'FCC Mill %'
order by name;
