\xef\xbb\xbf# handoff_20260927j_mail_keep_12m

## 경과
- `repair_20260927e` (트리거 OFF 방식) 1회 실행 성공: 1,000건 삭제, 2026년 이전 1,161건 남음
- 지시 변경: 2026년 기준 → **최근 12개월 이내 메일만 보존**

## 파일
`repair_20260927f_delete_mail_older_12m.sql` (`sql\`)
- 기준: `occurred_at < now() - interval '12 months'` (현재 약 2025-09-27 이전)
- 2025-09-27 ~ 2025-12-31 메일은 이제 **보존** (이전 2026 기준 파일은 더 이상 실행하지 말 것)
- 1회 최대 1000건, `remaining` = 0 될 때까지 반복, `disabled triggers` = 0 확인
- 기준이 now() 기준 롤링이라 나중에 다시 실행하면 그 시점 기준으로 정리

## 부작용
- audit 기록·engagement 재집계 없음, Storage 첨부 파일 잔존, IMAP 미변경

## Push
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/repair_20260927f_delete_mail_older_12m.sql docs/handoff
git commit -m "sql: keep only last 12 months of email"
git push origin marinebiogroup
```
