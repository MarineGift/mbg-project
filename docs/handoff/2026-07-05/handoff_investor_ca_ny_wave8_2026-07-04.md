# Handoff — Wave 8: CA/NY 딥테크 + 생명과학 VC 시드 (2026-07-04)

## 배경
530개 현재 investor 목록과 대조 → CA/NY 주요 VC 대부분 이미 존재. **정말 없는 신규 12곳만** 시드.

## 시드 대상 (12곳, 전부 신규)
### 딥테크/인프라 (7)
| firm | HQ | sector |
|---|---|---|
| Point72 Ventures | NY | deep_tech, industrial (high) |
| True Ventures | SF | deep_tech, industrial (high) |
| 645 Ventures | NY | deep_tech, industrial |
| Great Oaks Venture Capital | NY | deep_tech, industrial |
| Contour Venture Partners | NY | deep_tech, industrial |
| Primary Venture Partners | NY | deep_tech, industrial |
| Base10 Partners | SF | deep_tech, industrial |

### 생명과학 (5)
| firm | HQ | sector |
|---|---|---|
| LifeSci Venture Partners | NY | life_science |
| LifeX Ventures | NY | life_science |
| Sands Capital Ventures | SF | life_science |
| SR One | Redwood City CA | life_science |
| Novo Holdings | SF 지사 | life_science (high) |

## 파일: `sql/seed_investor_ca_ny_wave8.sql`
- source: `web_research_2026Q3_ca_ny`
- 각 firm: ko/en intro(mbg fit 명시) + priority
- **멱등 dedup**: 이름/도메인 매칭 시 스킵 (이미 있으면 자동 제외)
- **sector focus를 정규화 코드로** 저장 후, 방금 만든 `sync_party_sector_focus` RPC로 investor_sector_focus 링크 생성
- interest_tags(레거시 jsonb)도 sector 미러 + sync_party_interest_tags 호출
- editor-safe 순수 statement

## 실행
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
→ Supabase에서 `seed_investor_ca_ny_wave8.sql` 실행 → (6) 검증에서 12곳(기존 존재분 제외) 확인
→ 디렉토리 Sector 필터(Deep Tech / Life Science)에 반영 확인

## 선행 조건
- **sync_party_sector_focus RPC가 이미 적용됨** (직전 A 작업, Supabase 실행 확인). (5)에서 이 RPC를 호출하므로 없으면 그 SELECT만 에러(무시 가능하나 sector 링크는 안 생김).

## Finish
```powershell
cd C:\dev\mbg-project
git add sql/ docs/ ; git commit -m "feat(db): seed wave8 - CA/NY deep-tech + life-science VCs (12 firms, normalized sectors)" ; git push origin marinebiogroup
```

## 정리 (투자사 트랙 전체)
- wave7: 한국 투자이력 미국 투자사 4곳
- wave8: CA/NY 딥테크+생명과학 12곳
- 중복 병합 31쌍 완료 (554→523)
- Sector focus 정규화 완료 (Interest Tags와 동일 방식)
