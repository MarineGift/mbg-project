# Handoff — Paper Mill 중복 병합 결과 분석 + 3쌍 병합 (2026-07-05)

## probe 실행 결과 요약
| 섹션 | 결과 | 판정 |
|---|---|---|
| (0) party_type census | 실행됨 | paper_mill 코드만 유효 (buyer/filler/supplier/paper_company 등은 census에 없음) |
| (A) exact-dup | **5개 후보** (CSV 13) | → 아래 분석: **진짜 병합 3 / 병합 아님 2** |
| (B) same-domain | 대량 (CSV 14: KC 33, Smurfit 29, IP 23…) | **전부 "각 공장" 정상** — 병합 대상 아님 |
| (C) email-dup | **0행** (성공) | party 행에 이메일 없음 — 문제 없음 |
| (D) plant_supply_links | **42P01: 테이블 없음** | 024 마이그레이션 미적용 → **재지정할 supply-link 자식이 아예 없음** (병합 단순화) |

## (A) 5개 후보 정밀 분석
| key | 판정 | 근거 |
|---|---|---|
| **essity** (Essity / Essity AB) | ✅ **병합** | 같은 도시(Stockholm), AB는 HQ 스텁 중복. 소스 2개(v11_4 + se_paper) = 동일 엔티티 이중 임포트 |
| **holmen iggesund** (Holmen Iggesund / …Mill) | ✅ **병합** | 같은 도시(Iggesund), "Mill" 접미사만 차이 |
| **mondi neusiedler** (Mondi Neusiedler / …GmbH) | ✅ **병합** | GmbH 행이 "Munich"으로 잘못 위치. 웹 확인 결과 등기 공장은 **Ulmerfeld-Hausmening** → Hausmening 행을 canonical로 유지 |
| **holmen** (Holmen AB / Holmen Paper) | ❌ **병합 아님** | AB=그룹 HQ(Stockholm), Paper=제지 사업부(Norrköping). 3-tier 모델, 중복 아님 |
| **star** (Star Paper Mills Ltd / Star Paper Mill) | ❌ **병합 아님** | Abu Dhabi(UAE) vs Saharanpur(India) — **이름만 같은 별개 회사** |

→ **정규화 이름이 같아도 도시/tier가 다르면 병합 금지** 원칙이 그대로 작동. star가 그 방어선을 제대로 걸러줬습니다.

## 이번 세션 산출물 (2개)
| 파일 | 용도 |
|---|---|
| `fix_mill_merge_probe_fk.sql` | app.parties(id)를 참조하는 **모든 FK 테이블·컬럼** 나열 (READ ONLY). 투자사 병합 때와 동일 probe |
| `fix_mill_merge_3pairs.sql` | 3쌍 병합 (트랜잭션 + 가드 + dry-run + reparent 템플릿 + soft-delete + verify) |

## 실행 순서 (2단계 — FK 정확성 때문에 필수)
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
1. **PROBE 먼저**: Supabase에서 `fix_mill_merge_probe_fk.sql` 실행 → FK 목록 CSV 회신.
   (plant_supply_links는 없으니 안 나옵니다 — 정상. 대신 engagements/contacts/deals/paper_mill_profile 등이 나올 것)
2. 회신 받으면 `fix_mill_merge_3pairs.sql`의 **(3) REPARENT + (4) profile 섹션을 probe 결과로 확정**한 실행본을 만들어 드립니다.
3. 확정본을 Supabase에서 실행:
   - begin/commit으로 감쌈. (0) 가드가 6개 id의 존재·paper_mill·미삭제·keep≠merge를 검사, 실패 시 즉시 abort.
   - 마지막 verify가 **merge_still_active=0, keep_active=3**이면 `commit;`, 아니면 `rollback;`
   - soft-delete만 사용(복구 가능 + audit note). 디렉토리 paper_mill 수 3 감소.

## 병합 후 남는 확인 대상 (선택)
- **Holmen 3-tier 정리**: Holmen AB(HQ) ↔ Holmen Paper(division) ↔ Holmen Iggesund/Hallsta/Braviken(mill) 계층이 FK로 제대로 연결됐는지 별도 점검 권장 (병합 아님, 관계 정리)
- **star 별개회사**: 두 Star를 이름 충돌 회피 위해 party_name에 국가 접미사 추가 검토 (예: "Star Paper Mill (India)")

## ⚠ 이전 오류 정정
- probe (D)가 `party_supply_links.supplier_party_id`로 두 번 실패 → 실제는 `app.plant_supply_links` / `paper_mill_plant_id`+`filler_plant_id`인데 **그 테이블 자체가 아직 DB에 없음**(024 미적용). 메모리에 `party_supply_links`로 기록돼 있던 게 원인. 필요 시 메모리 정정 가능.

## 커밋 (finish block)
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/fix_mill_merge_probe_fk.sql sql/fix_mill_merge_3pairs.sql "docs/handoff/$(Get-Date -Format 'yyyy-MM-dd')/handoff_mill_merge.md"
git commit -m "feat(db): paper-mill dedupe - FK probe + 3-pair merge (essity, holmen iggesund, mondi neusiedler)"
git push origin marinebiogroup
```

## 인라인 mover (fallback)
```powershell
$dl = "$env:USERPROFILE\Downloads"
$map = @(
  @{f='fix_mill_merge_probe_fk*.sql'; d='C:\dev\mbg-project\sql\fix_mill_merge_probe_fk.sql'},
  @{f='fix_mill_merge_3pairs*.sql';   d='C:\dev\mbg-project\sql\fix_mill_merge_3pairs.sql'},
  @{f='handoff_mill_merge*.md';       d=('C:\dev\mbg-project\docs\handoff\' + (Get-Date -Format 'yyyy-MM-dd') + '\handoff_mill_merge.md')}
)
foreach ($m in $map) {
  $src = Get-ChildItem -Path $dl -Filter $m.f -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($src) {
    Unblock-File $src.FullName -ErrorAction SilentlyContinue
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($m.d)) | Out-Null
    [System.IO.File]::Copy($src.FullName, $m.d, $true); Remove-Item $src.FullName -Force
    Write-Host ("MOVED: " + $src.Name)
  } else { Write-Host ("SKIP (not found): " + $m.f) }
}
```

## 대기 중 (별개 트랙)
- 9c-1 이메일 SQL (`enrich_batch9c_kr_cany_emails.sql`) — 아직 미실행이면 실행
- Pangaea pre-meeting 이메일: **월 7/6 오전 발송** (수 7/8 9:30 PDT 미팅)
- 9c-2: US 14곳 리서치
