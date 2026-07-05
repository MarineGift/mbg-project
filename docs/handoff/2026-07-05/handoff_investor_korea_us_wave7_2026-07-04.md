# Handoff — Wave 7: 한국 투자 이력 미국 투자사 시드 (2026-07-04)

## 배경
신문/리서치 기반으로 한국에 투자한 미국 투자사를 조사 → CRM에 없는 것만 멱등 시드.

## 조사 결과 (웹 리서치, 2026Q3)
| 투자사 | 한국 투자 사례 | CRM 상태 |
|---|---|---|
| Sequoia Capital | 쿠팡(2014 시리즈B 주도), 무신사, 컬리 | 이미 존재(병합됨) → 스킵 |
| Kleiner Perkins | 토스 2018 시리즈D 주도 | 이미 존재(병합됨) → 스킵 |
| Altos Ventures | 토스·쿠팡 초기, 크로스오버 | wave6 존재 → 스킵 |
| Goodwater/SBVA/Samsung Ventures | — | wave6/병합 존재 → 스킵 |
| **Ribbit Capital** | 토스 시리즈D 공동주도(핀테크) | **신규 추가** |
| **General Atlantic** | 아시아 그로스, 한국 성장기업 | **신규 추가** |
| **TPG** | 카카오모빌리티 등, 한국 전담팀 | **신규 추가** |
| **The Carlyle Group** | 카카오모빌리티 등 | **신규 추가** |

→ **신규 4곳만 삽입**. 나머지는 이름/도메인 dedup 가드로 자동 스킵.

## 파일: `sql/seed_investor_korea_us_backers_wave7.sql`
- source: `web_research_2026Q3_korea_us`
- 각 firm: ko/en intro(한국 투자 사례 명시) + priority(Ribbit/GA/TPG=high, Carlyle=medium)
- **멱등 dedup**: 정규화 이름 OR 도메인 매칭 시 삽입 안 함 → 방금 병합한 Sequoia 등과 재충돌 없음
- korea_cross_border 태그: 레거시 jsonb + sync RPC 양쪽
- editor-safe: do-block/temp 없음, 순수 statement

## 실행
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
→ Supabase에서 `seed_investor_korea_us_backers_wave7.sql` 실행 → (5) 검증에서 4곳(또는 기존 존재분 제외한 수) 확인
→ 디렉토리에서 korea_cross_border 태그로 필터해 확인

## 참고
- (4)의 sync RPC는 fix_sync_on_save_rpc.sql이 이미 적용돼 있으면 정규화 태그까지 즉시 반영. 없으면 그 문장만 에러(무시 가능) → all-in-one 재실행으로 흡수.
- TPG/Carlyle/General Atlantic은 VC라기보다 PE/그로스지만, 한국 투자 이력이 명확해 포함. 원치 않으면 해당 VALUES 행 삭제 후 재실행.

## Finish
```powershell
cd C:\dev\mbg-project
git add sql/ docs/ ; git commit -m "feat(db): seed wave7 - US investors with Korea history (Ribbit, General Atlantic, TPG, Carlyle), idempotent" ; git push origin marinebiogroup
```
