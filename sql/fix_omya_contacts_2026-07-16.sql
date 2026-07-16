-- ============================================================
-- fix_omya_contacts_2026-07-16.sql
--
-- The derivation preview did its job. Of 16 rows matching the
-- ^[a-z]{2,}\.[a-z]{2,}$ pattern, FOURTEEN would have been wrong:
--   geral.celbi@altri.pt              -> "Geral Celbi"        geral is Portuguese for general
--   kontakt.sdt@leipa.de              -> "Kontakt Sdt"        kontakt is German for contact
--   info.jkpaper@jkmail.com           -> "Info Jkpaper"
--   marketing.itcpspd@itc.in          -> "Marketing Itcpspd"
--   communication.golbey@norskeskog.com -> "Communication Golbey"
--   info.saugbrugs@norskeskog.com     -> "Info Saugbrugs"
--   info.mpe@mitsubishi-paper.com     -> "Info Mpe"
-- The regex caught GENERIC PREFIXES WEARING A DOT. Running the bulk update
-- would have invented fourteen fictional people at real paper mills.
-- No bulk update. Only the two that are actually people.
--
--   f87eb652  edgar.habich@omya.com   Omya (HQ), Switzerland
--   1aaf22de  jaehoon.cho@omya.com    Omya (Korea) - evidence A, the KR number 1
--                                     FCC target per KFTC decision 2019-109
--
-- NO TITLE IS SET. A search found nothing on either person's role at Omya -
-- only unrelated namesakes. Inventing a title is how a CRM starts lying, and
-- title_text stays null until a primary source says otherwise.
--
-- uuid-targeted UPDATE on app.contacts. NOTHING IS INSERTED. IDEMPOTENT.
-- Columns per enrich_mlc_us_filler which inserted 13 contacts successfully.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) Omya (Korea) - jaehoon.cho@omya.com ----------
-- The only contact on the top KR licensing target. It has been sitting here
-- nameless, exactly as Sharad Mathur was.
update app.contacts c
set given_name  = coalesce(c.given_name, 'Jaehoon'),
    family_name = coalesce(c.family_name, 'Cho'),
    full_name   = coalesce(c.full_name, 'Jaehoon Cho'),
    is_primary  = true,
    notes = coalesce(c.notes, '') || E'\n[omya-contact 2026-07-16] Name taken from the address local-part, which follows Omya''s firstname.lastname convention. THE ONLY CONTACT ON OMYA KOREA - the number 1 KR FCC licensing target, confirmed by KFTC decision 2019-109 which names Omya Korea, Taekyung Industry and GMC as the paper-grade GCC slurry market, and by GMC''s own statement that foreign firms hold about 80 percent of the domestic GCC market. ROLE UNKNOWN - a search returned only unrelated namesakes, so title_text and department are deliberately left null rather than guessed. Check LinkedIn before outreach. A Korean name romanised this way, so the Hangul spelling is not asserted here either. Omya Korea - Seoul HQ plus five plants at Gunsan, Andong, Hambaek, Onsan and Jecheon.',
    updated_at = now()
where c.id = '1aaf22de-07f5-4697-96c8-572272bcd2d3'::uuid
  and c.deleted_at is null
  and coalesce(c.notes, '') not like '%[omya-contact 2026-07-16]%';

-- ---------- 2) Omya (HQ) - edgar.habich@omya.com ----------
update app.contacts c
set given_name  = coalesce(c.given_name, 'Edgar'),
    family_name = coalesce(c.family_name, 'Habich'),
    full_name   = coalesce(c.full_name, 'Edgar Habich'),
    is_primary  = true,
    notes = coalesce(c.notes, '') || E'\n[omya-contact 2026-07-16] Name taken from the address local-part, which follows Omya''s firstname.lastname convention. The only contact on Omya group HQ in Switzerland. ROLE UNKNOWN - nothing found in a public search, so title_text and department left null rather than guessed. Check LinkedIn before outreach.',
    updated_at = now()
where c.id = 'f87eb652-e68c-428b-ae8a-151b1869505f'::uuid
  and c.deleted_at is null
  and coalesce(c.notes, '') not like '%[omya-contact 2026-07-16]%';

-- ---------- 3) VERIFY ----------
-- select p.party_name, c.full_name, c.title_text, c.email, c.is_primary
-- from app.contacts c join app.parties p on p.id = c.party_id
-- where c.id in ('1aaf22de-07f5-4697-96c8-572272bcd2d3'::uuid,
--                'f87eb652-e68c-428b-ae8a-151b1869505f'::uuid);
-- expect Jaehoon Cho and Edgar Habich, title_text null on both


-- ---------- 4) THE REAL HEADLINE FROM THIS SCAN ----------
-- Only FOUR filler_supplier parties have any contact at all:
--   Mississippi Lime  13   - and MLC has exited PCC, so it is the lowest-value
--                            of the four
--   Specialty Minerals HQ  3
--   Omya (HQ)          1
--   Omya (Korea)       1
-- That is 18 contacts across the entire filler pipeline. Every other licensing
-- target has ZERO - Thiele, Imerys USA, Huber, IMI Fabi, Carmeuse, Taekyung BK,
-- Taekyung Industrial, GMC, Zantat, Okutama, Maruo, Bihoku, Shiraishi, and the
-- rest. The single best-covered company is the one that left the business.
-- Contact acquisition, not more enrichment, is the binding constraint on this
-- pipeline.


-- ---------- 5) THE GENERIC ONES - a labelling problem, not a naming one ----------
-- info.jkpaper@jkmail.com and friends are shared group inboxes, and several sit
-- on multiple sibling parties at once - info.saugbrugs on 3 Norske Skog rows,
-- marketing.itcpspd on 4 ITC rows, geral.celbi on 2 Altri rows, info.jkpaper on
-- 3 JK Paper rows. Enrolling those siblings in one sequence sends 3 or 4
-- near-identical cold emails to ONE inbox in the same window. With DKIM absent,
-- DMARC at p=none and a PTR mismatch already, that is a real deliverability
-- risk, not a theoretical one.
-- Correct fix is at the sequence layer - exclude generic locals, and dedupe
-- enrollments by email rather than by party. Send me the v_email_do_not_send
-- definition and I will write the patch instead of guessing at send logic.
