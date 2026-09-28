\xef\xbb\xbf# handoff_20260927i_mail_delete_notrigger

## 진단 결과
- 남은 2026년 이전 메일: 2,161건 (2026년 이후 3,918건)
- 실행 중/잠금 세션 없음, 인덱스 7개 모두 생성됨
- `app.communications` 사용자 트리거 8개: audit, touch_engagement, comm_log_engagement(ins/upd), auto_stage, auto_link_inbound_reply, ensure_investor_mail_folder, updated_at
- 결론: 행마다 트리거(특히 audit 전체 행 복사)가 돌아 삭제가 타임아웃

## 파일
`repair_20260927e_delete_mail_before_2026_notrigger.sql` (`sql\`)
- 트랜잭션 안에서만 사용자 트리거 OFF → 1000건 삭제 → 트리거 ON
- 실패 시 트리거 상태 포함 전체 롤백
- `remaining` = 0 될 때까지 반복 (약 3회), `disabled triggers (expect 0)` = 0 확인

## 부작용
- 이번 삭제분은 audit 기록 및 engagement 재집계 없음

## Push
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/repair_20260927e_delete_mail_before_2026_notrigger.sql sql/fix_20260927c_mail_delete_indexes.sql sql/repair_20260927c_delete_mail_before_2026_batch.sql docs/handoff
git commit -m "sql: delete pre-2026 email with user triggers off"
git push origin marinebiogroup
```
