# HANDOFF — 2026-09-27 b: mailcarrier fromName 누락 수정 + Activate 오분류 원복

## 결과 확인 (backfill_20260927 실행 결과)
- Cooper Bates contact → Clean Energy Ventures (investor) 등록 OK
- Cooper Calendly 2건, Will 소개 메일 → Clean Energy Ventures / Investors OK
- Misneach, Strategic Ventures, Vinlav Group LLC 소개 메일도 subject_firm 으로 연결
- 오분류 1건: houston@activate.org "Thank you for supporting Activate Houston's Cohort 2026" (name_domain → Activate)

## 수정
1. `src/lib/email/mailcarrier.ts` — c333f02 에서 fromName 패치가 SKIP 됨 (다른 호출부에 같은 문자열이 있어 가드가 오판). resolveInvestorIntro 호출에 `fromName` 추가 → E2 이름 매칭 동작.
2. `src/lib/email/investor-intro.ts` — PLATFORM_HOSTS 에 `activate.org` 추가 (09-21 규칙 F 사고와 같은 발신처).
3. `sql/repair_20260927_revert_activate_name_domain.sql` — Activate 메일 태그/연결 원복. 마지막 SELECT 0행 기대.

## Push
cd C:\dev\mbg-project
git status -sb
git add src/lib/email/mailcarrier.ts src/lib/email/investor-intro.ts sql/repair_20260927_revert_activate_name_domain.sql docs/handoff
git commit -m "inbox: pass fromName to investor rules + block activate.org"
git push origin marinebiogroup
