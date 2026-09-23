# Handoff 2026-09-23 — AP Ventures Girven contact + follow-up mail

## 내용
- `sql/seed_20260923_apventures_girven_contact.sql` (NEW)
  - AP Ventures party(이름 정확 일치, 1건)에 `girven@apventures.com` contact 추가
  - party에 primary contact가 없을 때만 is_primary = true
  - `apventures.com` 도메인 whitelist 없으면 추가
  - 마지막 SELECT가 검증 (1행 기대, 0행이면 party 이름 불일치)
- 코드 변경 없음 (DB만)
- 2026-09-22 미팅(약 1시간) → 자료 요청 → 2026-09-23 업그레이드 자료 발송, NDA 후 추가 정보 제공

## TODO
- Girven 이름(first name) / 직함 확인 후 URM Edit에서 given_name, title_text 입력

## Mover
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1

## Push
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20260923_apventures_girven_contact.sql docs/handoff
git commit -m "seed: AP Ventures Girven contact"
git push origin marinebiogroup
