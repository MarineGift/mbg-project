-- ============================================================
-- 20260620370023_investors_b8_intro_ko.sql
-- intro_ko (Korean) for the 4 batch-8 CVCs (source='investor_global_2026Q3_b8').
-- Separated from 370022 because Korean text is not ASCII -> keep the ASCII
--   here-string workflow for 370022 clean. This file is UTF-8 (BOM).
-- Apply in Supabase SQL Editor (the editor preserves UTF-8). Per-firm UPDATEs
--   to avoid the multi-row dollar-quote truncation seen earlier in the SQL Editor.
-- Idempotent (plain UPDATE; safe to re-run).
-- ============================================================

begin;

update app.parties set intro_ko='미쓰비시상사 전사 CVC(2025 설립, 약 USD 700M). 산업소재·에너지·모빌리티 전반 투자. MBG의 탄산칼슘 필러/바이오 기반 소재가 산업소재 포트폴리오 전환 테마와 부합.'
where party_name='MC Global Innovation' and source='investor_global_2026Q3_b8' and deleted_at is null;

update app.parties set intro_ko='도쿄 기반 첨단소재 기업(반도체/디스플레이 소재, 라이프사이언스), CVC 펀드 운영. 소재 혁신 중심이 MBG 기능성 미네랄/바이오소재 플랫폼과 부합.'
where party_name='JSR Corporation' and source='investor_global_2026Q3_b8' and deleted_at is null;

update app.parties set intro_ko='스미토모케미칼 CVC(케임브리지 MA 오피스). 첨단소재·헬스케어·지속가능 식품 투자. 지속가능성+소재 논지가 MBG 바이오 기반 필러와 부합.'
where party_name='Sumitomo Chemical' and source='investor_global_2026Q3_b8' and deleted_at is null;

update app.parties set intro_ko='아사히카세이 CVC(멘로파크, 2011~, 50+ 투자). 소재·에너지·탄소중립 스타트업 투자. Care for Earth 탈탄소 논지가 MBG 저탄소 미네랄 소재와 부합.'
where party_name='Asahi Kasei Corporate Venture Capital' and source='investor_global_2026Q3_b8' and deleted_at is null;

commit;

-- Verify: select party_name, left(intro_ko,20) from app.parties
--   where source='investor_global_2026Q3_b8' order by party_name;  -- expect 4 non-null
