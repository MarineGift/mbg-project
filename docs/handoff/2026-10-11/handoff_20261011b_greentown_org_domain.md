# Handoff 2026-10-11 (b) — Greentown 세 번째 도메인 greentown.org

> (a) `handoff_20261011_greentown_dual_domain.md` 이후 추가분

## 1. 확인된 사실
- Chloe Rose 의 실제 새 주소는 **`chloe@greentown.org`** (greentownlabs.org 아님). 10-09 "Re: Quick Check-In" 이 이 주소.
- 그 메일은 우리 스레드 답장이라 thread 매칭으로 저장·연결됐을 뿐, 새 스레드였다면 게이트/연락처 매칭 실패.
- Greentown 스태프 도메인은 3개: `greentownlabs.com`, `greentownlabs.org`, `greentown.org`
- 커서 되돌리기(1829 → 1500) 후 재처리 정상. 남은 .org(greentownlabs.org) 메일은 없음.

## 2. 변경
| 파일 | 내용 |
|---|---|
| `fix_20261011b_greentown_org_domain.sql` | whitelist greentown.org, 폴더 match_domains 추가, Chloe alias 를 chloe@greentown.org 로 교정, 연락처 없이 저장된 옛 Greentown 메일에 contact 연결 |
| `investor-intro.ts` (patch_20261011b) | greentown.org 도 Greentown 스태프 도메인 — 스태프 메일이 Investors 로 오분류되지 않게 |

## 3. 실행
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_20261011b_greentown_org_domain.ps1
```
Supabase: `sql/fix_20261011b_greentown_org_domain.sql` Ctrl+A → Run
```powershell
cd C:\dev\mbg-project
git status -sb
git add src/lib/email/investor-intro.ts sql/fix_20261011b_greentown_org_domain.sql tools/patches/patch_20261011b_greentown_org_domain.ps1 docs/handoff
git commit -m "mail: greentown.org as third Greentown staff domain, Chloe alias fix"
git push origin marinebiogroup
```

## 4. 규칙
- 사용자가 말한 주소도 **DB/수신 기록으로 확인한 뒤** alias 로 넣는다 (이번엔 추정 주소 greentownlabs.org 가 틀렸음).
- 폴더 `match_domains` 에 조직의 모든 도메인을 넣는다. 형제 도메인 매칭은 로컬파트가 같을 때만 연락처를 찾으므로, 로컬파트가 다른 주소(crose@ ↔ chloe@)는 contact_emails alias 가 필요하다.
