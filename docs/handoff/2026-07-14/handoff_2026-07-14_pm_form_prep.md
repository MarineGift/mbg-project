# Handoff — 폼 데이터 정합성 + 발송 제외 확장 (2026-07-14 오후 세션)

앞 세션(handoff_2026-07-14_session_end.md, outcome 시스템 + /mailing/outcomes 페이지)에서 이어짐. 이 문서는 오후에 진행한 **폼 제출 준비 + 발송 제외 로직 확장** 작업의 종료 핸드오프.

---

## PART A — 오늘 오후 완료된 것

### 1. 발송 결과 뷰 확장 (완료 ✓ — 핵심)
`app.v_email_do_not_send` 뷰를 확장: 이제 **폼 제출(application_forms.status IN submitted/decided) + 답장/거절(reply_*/rejected_*/unsubscribe) 주소를 자동 제외**. 시퀀스 발송 경로는 이 뷰를 가드로 쓰므로 즉시 적용됨.
- 새 컬럼: `party_id`(폼은 이메일 없을 수 있어 party 단위 차단 가능), `is_follow_up`(reply_positive 표시)
- 기존 가드 무손상: `WHERE dns.email_lower = lower(candidate.email)` 그대로 작동
- **DROP+CREATE 방식** (CREATE OR REPLACE는 컬럼 재정렬 불가 → 42P16). 뷰라 데이터 손실 없음
- 검증됨: 폼 제출 2건(Azolla=info@azollaventures.com, Lowercarbon=email null→party_id 차단) + outcome 5건 = 총 7건 제외 확인
- 파일: `sql/20260714180000_extend_do_not_send_contacted.sql`
- **미결**: bulk-mail 경로(/mailing UI)는 아직 email_blocklist만 봄 → 이 뷰를 참조하도록 `src/lib/queries/bulk-mail.ts` 패치 필요(우선순위 낮음, P1 폼은 수동 웹폼이라 시퀀스 경로로 커버됨)

### 2. 폼 답변 $5M 구버전 → $3M 정합화 (완료 ✓)
답변 뱅크에 라운드 금액이 두 버전 혼재: 1955/3M/Lowercarbon에 **$5M @ $30M pre ($35M post)** 구버전이 per-field로 박혀 있었음. 10건(3사 × 필드) 정밀 교체.
- 근원은 answer_library 아니라 **per-field final_text 복사본** (library=0, field=10)
- $5M→$3M, $30M pre→$27M pre, $35M post→$30M post, use of funds 2M/1.5M/1.5M→1M/1M/1M
- 3M Ventures "One-line" 오매핑(480자 cost 텍스트)도 올바른 196자로 재바인딩
- **⚠️ Lowercarbon은 status=submitted** — 이미 $5M 버전 제출됨. DB는 고쳤으나 투자자는 구버전 받음. 스레드 재개 시 "adjusted to $3M at $27M pre" 한 줄 대응
- 파일: `sql/20260714160000_fix_stale_round_figures.sql` (스캔: 150000)

### 3. IP/Team 답변 NDA 익명화 (완료 ✓ — 핵심)
공개 웹폼 답변에 민감정보 노출: Marinepad(계열사 실명), $500K 이전 대가, 카운터파티 executive approval/level. **11개 필드 8종 텍스트** 익명화.
- **사실관계**: 현재 KR 특허는 한국 Marinepad 보유 → 미국 Marinebio Group으로 이전 중, 이전비용 $500K. 대표 주체는 Marinebio Group(미국)
- 익명화 규칙: `Marinepad`→"a Korean affiliate under common ownership", `$500,000 USD`→"contractually deferred consideration"(금액 제거), `executive approval/level`→"being documented"/제거. **사실 골격 유지**
- 원본 6종은 `answer_library`에 **disclosure_level='nda_only'**로 보관 (데이터룸/NDA 후 사용)
- 최종 검증 **0행** 확인 (Marinepad/$500K/executive approval/level 전부 소거)
- **⚠️ Lowercarbon은 IP 답변도 submitted** — 민감 버전 이미 제출됨(위와 동일 케이스)
- 파일: `sql/20260714220000_anonymize_ip_answers_v2.sql` (공개 익명화), `sql/20260714210002_preserve_nda_answers_v2.sql` (원본 nda_only 보관)

### 4. 삽질 방지 스키마 사실 (신규 확정)
- **`app.answer_library.created_by`**: NOT NULL인데 실제 DB에 default 없음(auth.uid()는 에디터에서 null) → INSERT 시 기존 행에서 복사: `(SELECT created_by FROM app.answer_library WHERE ... LIMIT 1)`
- **`app.answer_library`에 UNIQUE(org, answer_key) 제약 없음** (migration_025 파일엔 있으나 미적용) → `ON CONFLICT` 대신 `NOT EXISTS` 가드 사용
- answer_library 실제 컬럼에 migration_025에 없는 것 추가됨: `medium`(default 있음) 등
- **application_form_fields**: form_id, seq, label, max_length (NOT field_label/char_limit/sort_order)
- **application_field_answers**: field_id, final_text, char_count(GENERATED)
- disclosure_level은 answer_library에만 (answer_id 조인 필요)
- parties에 `preferred_contact_method`, `contact_form_url` 있음 (migration_027, generated types엔 없음)

---

## PART B — 파일 실행 순서 (DB 반영 완료분 + 조회용)

오늘 만든 SQL(sql/에 mover로 이동 → 커밋 대상). **이미 DB 적용됨 표시 있는 것은 재실행 금지**:

| 파일 | 성격 | DB 상태 |
|---|---|---|
| 20260714130000_seed_preflight_check.sql | 조회 | Seed 점검(active 67, bad_email 1, do_not_send 0, clean 66) |
| 20260714140000_form_submission_worklist.sql | 조회 | P1 제출 체크리스트 |
| 20260714150000_scan_stale_round_figures.sql | 조회 | $5M 스캔 |
| 20260714160000_fix_stale_round_figures.sql | UPDATE | **적용됨** (10건 교체) |
| 20260714180000_extend_do_not_send_contacted.sql | VIEW | **적용됨** (뷰 확장) |
| 20260714210002_preserve_nda_answers_v2.sql | INSERT | **적용됨** (nda_only 6종 보관) |
| 20260714220000_anonymize_ip_answers_v2.sql | UPDATE | **적용됨** (8종 익명화, 최종 0행) |
| (나머지 170000/190000/200000/210000/210001/210003/220001) | 조회·중간본 | 이력용 |

## PART C — 미결 사항 (우선순위)

1. **[7/20 전] Seed bad_email 1건 정리.** preflight Part 1 재실행해서 그 1건(no contact/empty/malformed 중 무엇)인지 확인 → cancel 또는 이메일 수정. active 67 중 clean 66
2. **① Brightfuture 회신(7/14 06:07) 분류** — 본문 확인 후 /mailing/outcomes 폼으로 기록 (새 폼 첫 실전 사용). 메일 커넥터 없어 Claude는 본문 접근 불가 → 사용자가 본문 제공 필요
3. **Lowercarbon 이중 노출 대응** — $5M + 민감 IP 둘 다 이미 submitted. 스레드 재개 시 정정 메시지
4. **bulk-mail 경로에 do-not-send 뷰 연결** (src/lib/queries/bulk-mail.ts 패치)
5. 신규 익명화 2건(advisory/valuation)은 nda_only 미보관 (우선순위 낮음)
6. Planet A/Eclipse 대체 컨택 발굴 (앞 핸드오프 이월)
7. 기후펀드 백필 70개 (이월)

## PART D — 컨벤션 (변동 없음)
- 소통 한국어 + 코드/SQL 영어. 콘솔 ASCII-only, 한국어 .md UTF-8 BOM
- Supabase SQL Editor: 문자열 내 세미콜론/`into` 금지, self-contained 문장, enum `::app.enrollment_status` 캐스트
- git: 두 머신 → 작업 전 `git pull --rebase origin marinebiogroup` 필수
- 파일 라우팅: tools\move-downloads.ps1 (프리픽스 규칙, *.sql → sql\)
- 여러 result set 스니펫은 마지막 것만 캡처됨 → 확인용은 단일 SELECT로 분리

---

## 파일 이동 + Finish

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

```powershell
cd C:\dev\mbg-project
git pull --rebase origin marinebiogroup
git status -sb
git add sql/ docs/handoff/
git commit -m "sql: 2026-07-14 PM - do-not-send view extension, form $5M fix, IP anonymization"
git push origin marinebiogroup
```

## 다음 세션 킥오프 (복붙)

```
mbg-project 이어가자. docs/handoff/2026-07-14/handoff_2026-07-14_pm_form_prep.md 기준.

오늘 우선순위:
1. Seed bad_email 1건 정리 (7/20 발송 전) - preflight Part 1 재실행해서 문제 enrollment 확인 후 cancel/수정
2. Brightfuture 회신 분류 - 사용자가 본문 제공하면 /mailing/outcomes 폼으로 기록
3. (선택) bulk-mail.ts에 v_email_do_not_send 연결

확정 사실:
- v_email_do_not_send 뷰가 폼 제출/답장까지 제외 (party_id + email_lower 양단위)
- 폼 답변 $5M→$3M 정합화 완료, IP 익명화 완료 (Marinepad/$500K/executive 소거, 원본 nda_only 보관)
- answer_library.created_by NOT NULL·default없음 → 기존행에서 복사, UNIQUE제약 없음 → NOT EXISTS 가드
- Lowercarbon은 $5M+민감IP 둘 다 이미 submitted (정정 필요)
```
