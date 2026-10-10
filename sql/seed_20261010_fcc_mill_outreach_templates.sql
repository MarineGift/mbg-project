-- ============================================================================
-- !!!  Ctrl+A (select ALL) then Run  !!!   (editor runs only highlighted text)
-- ============================================================================
-- seed_20261010_fcc_mill_outreach_templates.sql
-- FCC paper-mill outreach: 3 English templates (party_type = paper_mill)
--   FCC Mill 1 - Pulp cost (initial)
--   FCC Mill 2 - Supplier sentence (follow-up, +7 days)
--   FCC Mill 3 - Last note (follow-up, +14 days)
-- Idempotent: skips a template whose name already exists for the org.
-- Org is resolved as the org owning the most parties (single-tenant URM).
-- Result: one row per template (3 rows).
-- ============================================================================

insert into app.email_templates
  (organization_id, name, category, subject, body_plain, party_type, is_active)
select o.org_id, v.name, 'marketing', v.subject, v.body, 'paper_mill', true
from (
  select organization_id as org_id
  from app.parties
  group by organization_id
  order by count(*) desc
  limit 1
) o
cross join (values
(
  'FCC Mill 1 - Pulp cost (initial)',
  $t$Reduce pulp cost at {{company_name}}: ask your filler supplier for FCC$t$,
  $t$Hello,

I am {{sender_name}}, {{sender_title}} of {{sender_company}}. We developed FCC (Flexible Calcium Carbonate), a patented filler technology that lets a paper mill replace part of its pulp with filler.

We have just signed a supply agreement with a leading global filler manufacturer, so FCC is now available to mills through the PCC and GCC supply chain they already use.

Why it matters for {{company_name}}:

- Less pulp per ton. FCC is calcium carbonate bound with fine cellulose fibrils, so it can be loaded at higher levels and take the place of fiber, the most expensive part of the furnish.
- Strength is kept. The fibrils bond FCC with the fiber network, so tensile strength and bulk hold up at higher filler content. In published trials, FCC sheets at 60% ash matched or exceeded GCC sheets at 30% ash.
- No new equipment and no new vendor. FCC is produced by your existing filler supplier, on-site or delivered.

Getting started takes one step. Tell your filler supplier:
"We want to use FCC to replace part of our pulp. Please contact MarineBio Group (contact@marinebiogroup.com)."
We then work directly with them on the technology and the rollout at your mill.

If furnish and filler decisions sit with someone else, I would be grateful if you could forward this to your technical or procurement lead.

Best regards,

--
MarineBio Group Inc. | Houston, TX, USA
To stop receiving these emails, reply with "unsubscribe".$t$
),
(
  'FCC Mill 2 - Supplier sentence (follow-up)',
  $t$One sentence to send your filler supplier$t$,
  $t$Hello,

A short follow-up on FCC (Flexible Calcium Carbonate).

Mills can lower pulp use by raising filler content with FCC, and there is nothing to buy or install. The only step is a message to your PCC or GCC supplier:

"We would like to use FCC to replace part of our pulp. Please contact MarineBio Group at contact@marinebiogroup.com."

Our team then handles the technology transfer with your supplier.

Would a one-page technical summary be useful for your papermaking team at {{company_name}}?

Best regards,

--
MarineBio Group Inc. | Houston, TX, USA
To stop receiving these emails, reply with "unsubscribe".$t$
),
(
  'FCC Mill 3 - Last note (follow-up)',
  $t$Who handles filler and furnish cost at {{company_name}}?$t$,
  $t$Hello,

I have written twice about FCC, a filler technology that replaces part of the pulp in the sheet while keeping strength. I do not want to crowd your inbox, so this is my last note.

If lowering fiber cost is on your agenda for 2027, the next step is simple: ask your filler supplier to contact MarineBio Group (contact@marinebiogroup.com).

And if someone else at {{company_name}} owns furnish and filler decisions, a name would help me a lot.

Thank you,

--
MarineBio Group Inc. | Houston, TX, USA
To stop receiving these emails, reply with "unsubscribe".$t$
)
) as v(name, subject, body)
where not exists (
  select 1 from app.email_templates t
  where t.organization_id = o.org_id and t.name = v.name
)
;

select name, party_type, category, subject, is_active
from app.email_templates
where name like 'FCC Mill %'
order by name
;
