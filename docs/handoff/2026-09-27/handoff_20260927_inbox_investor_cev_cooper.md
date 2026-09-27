# HANDOFF — Cooper Bates (Clean Energy Ventures) 메일 Investors 미분류 수정 (2026-09-27)

## 증상
- `cbates@CleanEnergyVentures.com` (Cooper Bates, Clean Energy Ventures 이사) 의 Calendly 초대 메일 2건이 Inbox 에서 배지 없음 / "Sender is not a registered party".
- 같은 건의 Greentown 소개 메일 제목 `Introduction: Cooper Bates (Clean Energy Ventures) <> Yun-Young Heo (MarineBio Group)` 도 CEV 로 연결 안 됨.

## 원인
1. 규칙 D(`extractPairFirm`)가 괄호를 제외해서 `Person (Firm) <> Person (MarineBio Group)` 형태를 못 읽음.
2. 규칙 F(웹사이트 도메인)는 CEV party website 가 `cevg.com` 이라 `cleanenergyventures.com` 과 불일치 + Calendly 초대는 MarineBio 언급/In-Reply-To 가 없어 mentionsUs 탈락.
3. 규칙 E(같은 발신자 이전 investor 메일)는 소개 메일 발신자가 Greentown 직원이라 Cooper 주소로는 이력 없음.

## 수정 (코드, rule-based, AI 없음)
`src/lib/email/investor-intro.ts`
- D 확장: 괄호 소개 제목에서 상대편 회사명 추출 (양방향). Greentown 직원 발신 소개 메일도 investor party 1건 일치 시 해당 firm 으로 relink.
- **G (name_domain)**: 발신 도메인 라벨 == investor party 이름 정규화 (`cleanenergyventures` == "Clean Energy Ventures", Inc/LLC/Group 접미사 제거). 개인 발신자만, 플랫폼/웹메일/자사/Greentown 도메인 제외. mentionsUs 불필요 → 캘린더 초대도 잡힘.
- **E2 (intro_participant)**: 발신자 이름("Cooper Bates")이 최근 180일 investor 메일 제목에 있거나, 발신 주소가 그 메일 To/Cc 에 있으면 investor. 해당 메일 party 가 investor 면 그쪽, 아니면 제목 firm 으로 relink. 우리 이름(Heo/Yun Young)·자사/Greentown 도메인·역할 주소 제외.
`src/lib/email/mailcarrier.ts` — `fromName` 전달 (1줄).
테스트 12개 통과 (`src/__tests__/email/investor-intro.test.ts`).

## DB
`sql/backfill_20260927_investor_cev_cooper.sql` (Ctrl+A 후 Run)
1. Cooper Bates contact → Clean Energy Ventures investor party (title Director)
2. `cleanenergyventures.com` whitelist
3~5. 기존 메일에 D2 / G / E2 소급 적용 (미분류·mentor 연결 메일만, 자동발송 제외)
6. 검증 그리드: contact 1행 + 소급된 메일 목록. contact 행이 없으면 CEV party 이름이 "Clean Energy Ventures"/"...Group" 이 아니거나 type 이 investor 가 아님.

## 확인
- 직함 "이사" → `Director` 로 입력. 정확한 직함(Partner/Principal 등) 다르면 URM Edit 에서 수정.
- Venkat Madabat (VMBT Group LLC) 소개 스레드는 VMBT 가 investor party 가 아니면 변동 없음 (의도).

## Push
cd C:\dev\mbg-project
git status -sb
git add src/lib/email/investor-intro.ts src/lib/email/mailcarrier.ts src/__tests__/email/investor-intro.test.ts sql/backfill_20260927_investor_cev_cooper.sql docs/handoff
git commit -m "inbox: investor by intro participant + name-domain (Clean Energy Ventures / Cooper Bates)"
git push origin marinebiogroup
