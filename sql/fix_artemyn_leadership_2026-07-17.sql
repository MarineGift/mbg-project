-- ============================================================
-- fix_artemyn_leadership_2026-07-17.sql
--
-- artemyn.com/en/pages/leadership publishes its entire executive committee and
-- supervisory board by name, with full biographies. Four of them have careers in
-- paper. No email addresses anywhere - every bio ends at the contact form.
--
-- THE TARGET IS CHRIS NUTBEEM.
--   VP Innovation and Marketing, and his bio places him "at the company's
--   primary technology centre in the South West of England" - that is Par Moor,
--   listed on the site's own map as the P&B Lab. 35 years in industrial minerals
--   innovation. His bio says he "champions a collaborative approach, engaging
--   closely with both industry partners and customers in the development
--   process" and drives "rapid decision-making in customer engagement".
--   A licensing conversation is precisely that, described in his own words.
--
-- THREE MORE WHO KNOW PAPER.
--   Mikael Breitenstein, VP EMEA. Finnish, Master's in Chemical Engineering from
--     Abo Akademi - the Nordic pulp and paper chemistry school. His bio says he
--     has served the paper, board and pulp industry FOR HIS ENTIRE CAREER. Joined
--     as VP Global Sales, became GM and VP EMEA in January 2025.
--   Peter Wheeler, VP APAC, Singapore, since August 2025. Holds a BACHELOR OF
--     TECHNOLOGY IN PULP AND PAPER plus a Master's in Chemistry. Spans R&D and
--     technical marketing through manufacturing. Closest door to Korea.
--   Mario Seixas, VP Americas. Chemistry at USP, MBA Toronto. Career began in
--     specialty polymers then minerals for paper. States his ambition is that
--     Artemyn "remains the supplier of choice for the Paper & Board customers".
--
-- THE WARNING IS IN THE CEO'S OWN BIO, and it decides the routing.
--   "At Artemyn, Nilesh is leading the company's expansion BEYOND ITS LEGACY IN
--    PAPER AND BOARD, unlocking new opportunities in high-potential sectors such
--    as paints, ceramics, fiberglass, cement, agriculture, and water treatment."
--   Nilesh Shah is a Chartered Accountant and CPA - a finance CEO, deliberately
--   diversifying AWAY from paper. To him paper is the legacy line.
--   So do NOT open at CEO level. Nutbeem, Breitenstein and Wheeler have their
--   careers invested in paper. The CEO is leaving it.
--   The read - and it IS a read, not a fact - is that FCC answers the question
--   the diversification is asking. A CEO diversifies out of paper because he
--   thinks paper is flat. A way to make the legacy line grow again is a story
--   that reaches him THROUGH the people who still own it. That is a hypothesis
--   about a stranger's motives, recorded as such, not something the site says.
--
-- NO CONTACT ROWS ARE CREATED, DELIBERATELY.
-- Not one email is published. A contact row with a null email cannot be
-- contacted, and it would inflate the one number this whole exercise turns on -
-- 4 of 242 filler parties have a contact. A contact you cannot email is not a
-- contact, and quietly making that number look better would be lying to the next
-- person who reads it. The names go in extra_data, where they are exactly what
-- they are - knowledge of who to ask for.
--
-- IDEMPOTENT. uuid-targeted. Nothing inserted, nothing deleted.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"leadership": {"source": "artemyn.com/en/pages/leadership", "source_type": "disclosure", "checked_at": "2026-07-17", "emails_published": false, "note": "Every biography ends at the contact form. No addresses anywhere on the page. LinkedIn is linkedin.com/company/artemyn.", "primary_target": {"name": "Chris Nutbeem", "title": "Vice President for Innovation and Marketing", "based": "the company primary technology centre in the South West of England - this is Par Moor, listed on the site map as the P&B Lab", "why": "35 years in industrial minerals innovation. His own bio says he engages closely with industry partners and customers in the development process, and drives rapid decision-making in customer engagement. That is a licensing conversation described in his words."}, "also_paper_literate": [{"name": "Mikael Breitenstein", "title": "Vice President for EMEA", "why": "Finnish, Master of Chemical Engineering from Abo Akademi. His bio states he has served the paper, board and pulp industry for his entire career. Joined as VP Global Sales, GM and VP EMEA since January 2025."}, {"name": "Peter Wheeler", "title": "Vice President for APAC", "based": "Singapore, since August 2025", "why": "Holds a Bachelor of Technology in Pulp and Paper and a Master in Chemistry. Expertise spans R&D and technical marketing through manufacturing. Closest door to Korea."}, {"name": "Mario Seixas", "title": "Vice President for Americas", "why": "Chemistry at Universidade Sao Paulo, MBA Toronto. Career began in specialty polymers then minerals for paper. States his ambition is that Artemyn remains the supplier of choice for Paper and Board customers."}], "do_not_open_here": {"name": "Nilesh Shah", "title": "Chief Executive Officer", "reason": "His own bio says he is leading the expansion BEYOND ITS LEGACY IN PAPER AND BOARD, toward paints, ceramics, fiberglass, cement, agriculture and water treatment. Chartered Accountant and CPA - a finance CEO diversifying away from paper. To him paper is the legacy line. Route through the people whose careers are in paper, not through him."}, "other_exec": [{"name": "Julien Remond", "title": "CFO", "note": "15+ years at Imerys, always inside what is now the Artemyn perimeter - kaolin at Capim and carbonates at Sao Paulo, Singapore and Paris"}, {"name": "Pierre Francois", "title": "VP Operations", "note": "now focused on the Brazil kaolin business, formerly industrial Director of the Carbonates division in Brazil"}, {"name": "Marcia Martins", "title": "VP Human Resources"}, {"name": "Hajer Bergaoui", "title": "VP IT"}], "supervisory_board": [{"name": "Michael Flacks", "title": "Chairman, Flacks Group"}, {"name": "James D. Gassenheimer", "title": "CEO, Flacks Group"}, {"name": "Christian Dreser", "title": "President, Artemyn", "note": "spelled Dreser in the page metadata and Dresser on the board card - confirm before writing to him"}, {"name": "Nilesh Shah", "title": "Chief Executive Officer"}]}, "approach_read": {"hypothesis": "The CEO diversifies out of paper because he judges paper flat. FCC is a way to make the legacy line grow without leaving it, which is a story that reaches a finance CEO THROUGH the people who still own paper rather than around them.", "status": "HYPOTHESIS about a stranger motives, not a fact from the site. Recorded so it can be argued with rather than absorbed.", "raised_at": "2026-07-17"}}'::jsonb,
    updated_at = now()
where f.party_id = '7868456a-bd64-4de2-9930-74cd21db8dea'::uuid
  and f.deleted_at is null
  and not (coalesce(f.extra_data, '{}'::jsonb) ? 'leadership');


-- ---------- VERIFY ----------
-- select p.party_name,
--        f.extra_data #>> '{leadership,primary_target,name}'  as target,
--        f.extra_data #>> '{leadership,primary_target,title}' as title,
--        f.extra_data #>> '{leadership,do_not_open_here,name}' as avoid,
--        f.extra_data #>> '{leadership,emails_published}'      as emails,
--        (select count(*) from app.contacts c
--         where c.party_id = p.id and c.deleted_at is null)    as contacts
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.id = '7868456a-bd64-4de2-9930-74cd21db8dea'::uuid;
-- contacts stays 0. That is honest - no email exists to hold.


-- ---------- WHAT TO DO WITH THIS ----------
-- Three routes, in order of directness.
--
-- 1. LINKEDIN. linkedin.com/company/artemyn. Chris Nutbeem is a named VP at a
--    900-person company - he is findable, and a connection note is not a cold
--    email. This is the only route here that reaches a specific human.
--
-- 2. THE FORM, addressed to him by name. The contact form's Subject dropdown is
--    still unread, and the fields are still not recorded. If the dropdown offers
--    a technology or partnership option, the filler_safe medium variant fits,
--    with "For the attention of Chris Nutbeem, VP Innovation and Marketing" as
--    the opening line. If it only offers sales, the form is the wrong door and
--    routing through it wastes the one approach.
--
-- 3. TAPPICON. Artemyn published an article about attending TAPPICon 2026 in the
--    US market. Conferences are where technology centre people talk to strangers
--    without a Subject dropdown in between.
--
-- The answer set is written and gated. What is missing is not words - it is one
-- look at that contact page, or one LinkedIn message.
