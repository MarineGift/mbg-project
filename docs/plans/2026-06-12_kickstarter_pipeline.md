# Kickstarter 파이프라인 테스트 설계 — 첨부파일(Google Drive) + Deal/Checklist/Task + 후원자 모집

작성: 2026-06-12 / source 태그: `kickstarter_pilot_2026Q3`

## 0. 진행 순서 (이번 세션 교훈 반영: 추측 금지, 스키마 먼저)

| 단계 | 내용 | 산출물 |
|---|---|---|
| Step 0 | `db/inspect/*.sql` 3개를 Supabase SQL Editor에서 실행 → 결과 붙여넣기 | 실제 스키마 확정 |
| Step 1 | `app.attachments` DDL + RLS (contact_profiles와 동일한 2계열 미러링) | SQL 1파일 |
| Step 2 | Kickstarter Deal + Checklist 4개 + Task ~18개 시드 | SQL 파일들 (1파일 = 1 statement) |
| Step 3 | 후원자 모집용 Campaign 생성 + 후보 contacts 연결 | SQL |
| Step 4 | UI: Task/Checklist 상세에 "Attachments" 패널 (Drive 링크 첨부) | TS/TSX 패치 |
| Step 5 | tsc --noEmit 0 에러 → commit → push (자동배포) | 배포 |

Step 0 결과가 나오기 전에는 컬럼명을 단정하지 않는다. (JJDC 세션에서 SQL 7회 깨진 원인 재발 방지)

## 1. 첨부파일 아키텍처 — Google Drive 연동

### 1.1 설계 원칙
- 파일 바이너리는 URM DB에 저장하지 않는다. Google Drive가 원본 저장소, URM은 **메타데이터 + 링크**만 보관.
- Checklist/Task 전용이 아니라 범용 폴리모픽: deal, party, contact에도 재사용 가능 (contact_profiles를 범용으로 만든 것과 같은 방침).

### 1.2 테이블 초안 (Step 0 결과 확인 후 확정)

```
app.attachments
  id               uuid PK default gen_random_uuid()
  organization_id  uuid NOT NULL
  entity_type      text NOT NULL CHECK (checklist / task / deal / party / contact)
  entity_id        uuid NOT NULL
  storage_provider text NOT NULL default 'google_drive' CHECK (google_drive / url)
  drive_file_id    text            -- Drive 링크에서 파싱
  file_url         text NOT NULL   -- webViewLink
  file_name        text NOT NULL
  mime_type        text
  note             text
  created_by       uuid
  created_at       timestamptz default now()
  deleted_at       timestamptz     -- soft delete (기존 컨벤션 동일)
```

- 인덱스: (organization_id, entity_type, entity_id) WHERE deleted_at IS NULL
- RLS: PERMISSIVE org 계열(current_organization_id / is_member_of_organization) + RESTRICTIVE rbac 계열(has_perm) — contact_profiles와 동일 패턴 미러링.

### 1.3 Drive 연동 단계 (점진)

| Phase | 방식 | 필요 작업 | 비고 |
|---|---|---|---|
| **1 (이번)** | Drive 공유 링크 붙여넣기 → file_id 파싱 + 메타 저장 | OAuth 스코프 추가 불필요. 즉시 동작 | 링크 정규식: `/d/([a-zA-Z0-9_-]+)` 또는 `id=` 쿼리 |
| 2 | Google Picker API로 파일 선택 | 기존 Google OAuth(캘린더 연동 완료)에 `drive.file` 스코프 추가 + re-consent | 권한은 Drive에 남고 URM은 선택된 파일만 접근 |
| 3 | URM에서 직접 업로드 → Deal별 Drive 폴더 | Drive API files.create + 폴더 자동 생성 | 선택사항 |

Phase 1만으로 "Kickstarter 준비 테스트"는 충분: 예산 시트, 영상 스토리보드, 리워드표를 Drive에 두고 Task에 링크 첨부.

## 2. Kickstarter Deal 구조 (시드 내용)

### Deal
- 이름: **Kickstarter — MarineBio 크라우드펀딩 (Pilot)**
- 단계: 준비(파이프라인 보드 첫 컬럼) / source: kickstarter_pilot_2026Q3
- deal_parties: MarineBio 자사 파티(있으면) 또는 테스트 파티

### Checklist 1 — 캠페인 준비
1. 펀딩 목표금액·예산 확정 (제작원가 + KS 수수료 5% + 결제수수료 3~5% + 배송비) — 첨부: 예산 .xlsx
2. 리워드 티어 설계 (Early Bird / 기본 / 번들 / 한정판) — 첨부: 리워드표
3. Kickstarter 계정 + 본인인증 + Stripe/은행 연결
4. 캠페인 스토리 작성 (영문 본문 + 한글 초안) — 첨부: 스토리 Doc
5. 메인 영상 제작 (2~3분, 스토리보드 → 촬영 → 편집) — 첨부: 스토리보드 PDF
6. 페이지 그래픽/제품 사진 제작
7. FAQ + Risks & Challenges 섹션 작성

### Checklist 2 — 프리런치 & 후원자 모집
1. Kickstarter 프리런치 페이지 공개 (Notify me 버튼)
2. 이메일 구독자 리스트 모집 (랜딩 + 뉴스레터)
3. SNS 티저 캠페인 (D-30 / D-14 / D-7 / D-1)
4. 보도자료 작성·배포
5. **URM 후원자 후보 Campaign 구성** ← 3장 참조

### Checklist 3 — 런칭 & 운영
1. 런칭 D-day 전 채널 동시 발송 (이메일 + SNS)
2. 첫 48시간 집중 푸시 (KS 알고리즘 노출 결정 구간)
3. 캠페인 업데이트 #1 발행 (목표 % 달성 공유)
4. 댓글/메시지 24시간 내 응답 체계

### Checklist 4 — 펀딩 종료 후
1. 백커 서베이 발송 (배송지/옵션 수집)
2. 생산·배송 일정 확정 및 업데이트 공지
3. 정산/회계 정리 (KS 수수료, 환율, 세무)

## 3. 후원자(Backer) 모집 — URM Campaign 활용

- 새 party_type을 만들지 않는다 (enum 5개로 정리한 것 유지). 후원자 후보는 **contacts**로 관리하고 **Campaign**으로 묶는다.
- Campaign: **Kickstarter Backers 2026Q3**
- 멤버 상태 흐름: lead(후보) → notified(프리런치 알림 동의) → pledged(후원 약정) → backed(결제 완료)
  - 기존 campaign 멤버 status 스키마가 다르면 그 값 체계를 따른다 (Step 0에서 확인).
- 테스트용 시드: 가상 후보 5~10명 contacts 생성 (source: kickstarter_pilot_2026Q3, 실데이터와 구분 — 나중에 source 태그로 일괄 soft-delete 가능).
- 기존 "투자자 디렉터리 멀티선택 → Add to Campaign" 플로우 재사용 가능.

## 4. UI 작업 (Step 4)

- `src/components/.../attachments-panel.tsx` (신규): Drive 링크 입력 → file_id 파싱 → 저장 → 리스트(파일명, mime 아이콘, 메모, 열기 링크, soft-delete)
- Task 상세 / Checklist 상세 / Deal 상세에 패널 장착
- 쿼리: contact_profiles 때와 동일하게 **임베드 대신 별도 select + in-memory join** (신규 테이블 스키마 캐시 리스크 회피)

## 5. 다음 메시지에서 할 일

`db/inspect/` 3개 SQL 실행 결과(테이블 목록 / 컬럼 / enum)를 붙여넣어 주면, 그걸 기준으로 Step 1~3 SQL 전체(1파일 1 statement, 명명 $tag$, UUID 정확 타겟팅)와 Step 4 UI 코드를 바로 생성한다.
