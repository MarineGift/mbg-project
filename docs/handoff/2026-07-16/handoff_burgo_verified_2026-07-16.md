# Handoff — Burgo는 오탐, 그런데 Saica는 더 무거워짐 (2026-07-16, 12차)

## 0. 블록 5 결과 — 스캔이 제대로 작동했습니다

**Saica가 목록에서 사라졌습니다** ✅ — fix가 먹었습니다.

남은 9행 중 8행은 정상이고, **Burgo 4행만 어긋나 보였습니다**:

```
website = https://www.burgo.com   ↔   email = info@burgogroup.com
```

**확인 결과 오탐입니다.** burgo.com/en/contacts 원문:

> Via Piave, 1 36077 Altavilla Vicentina (VI) Italy Tel. +39 0444 227811 **info@burgogroup.com**

**웹은 `burgo.com`, 메일은 `burgogroup.com`. 둘 다 진짜 Burgo 것입니다.** 회사가 웹과 메일에 다른 도메인을 쓰는 정상 구성입니다. 개인 주소는 `lastname.firstname@burgo.com` 형식이 82%입니다.

스캔을 "판정"이 아니라 **"사람이 볼 검토 리스트"**로 설계한 게 맞았습니다. 자동으로 고쳤으면 멀쩡한 4행을 망가뜨렸을 겁니다.

## 1. 🚨 그런데 이게 Saica 건을 더 무겁게 만듭니다

`info@burgogroup.com`은 **죽은 주소가 아닙니다.** Burgo가 실제로 읽는 **살아 있는 인박스**입니다.

Saica 행이 enroll됐다면 바운스로 조용히 끝나는 게 아니라, **경쟁사가 우리 제안을 읽었습니다.**

오발송 위험이 가정이 아니었습니다.

## 2. `fix_burgo_domain_verified_2026-07-16.sql` → `sql\`

1. **검증 사실을 4행 컨택 notes에 기록** — 다음에 누가(또는 제가) 다시 오탐으로 잡아서 `info@burgo.com`으로 "고치는" 걸 막습니다
2. **Burgo Group S.p.A. 보강** — burgo.com을 어차피 읽었으니:
   - 1905년 창업, 본사 Via Piave 1, 알타빌라 비첸티나(베네토), +39 0444 227811
   - **이탈리아 공장 11곳 + 벨기에 비르통 일관공장 1곳(Burgo Ardennes), 초지 라인 16개, 연산 약 300만 톤**
   - 그래픽용지·**컨테이너보드**·특수지(식품포장 포함) + 섬유원료·에너지
   - 그룹사: Mosaico(특수지), Burgo Distribuzione, Burgo Energia, Burgo North America(스탬퍼드 CT)
   - 2004년 Marchi 그룹과 합병
   - **컨테이너보드 확대 중이라고 밝히고 있어 필러 대화의 접점이 있습니다**
3. **로스터 불완전 기록** — DB에 Burgo 행이 **4개인데 실제 공장은 12곳**입니다

## 3. 안 한 것 — 이메일을 지어내지 않았습니다

제3자 디렉토리에 Burgo 임원 명단이 있습니다. 그중 FCC와 직접 관련된 사람들:

| 이름 | 직함 |
|---|---|
| **Stefano Carraro** | **R&D Director** |
| **Massimo Sobrero** | **Corporate Containerboard Sales Director** |
| Andrea Bettin | Corporate Procurement Director |
| Marco Tagliapietra | Group CFO, Legal & IT Director |

**Carraro(R&D) + Sobrero(컨테이너보드 영업)는 FCC 접근의 자연스러운 조합입니다.**

**그런데 넣지 않았습니다.** 이유:

- 출처가 **제3자 디렉토리**입니다 — provenance 어휘에서 `third_party`, 가장 약한 등급
- 디렉토리가 주는 건 이메일 **주소가 아니라 형식**입니다 ("82%가 lastname.firstname@burgo.com")
- **형식에서 `carraro.stefano@burgo.com`을 유도하는 건 추측입니다**

실존 회사의 실존 인물에게 **추측한 주소로 메일을 보내는 건 발신 도메인을 태우는 가장 빠른 길**입니다. 그리고 이 프로젝트는 이미 **DKIM 없음 / DMARC p=none / PTR 불일치** 상태입니다.

명단은 파일 5번 블록에 주석으로 남겼습니다. **1차 출처에서 확인되면 그때 넣으시죠.**

## 4. 이동 · 실행 · 마무리

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$moves = @(
  @{ Pattern = 'fix_burgo_domain_verified_2026-07-16*.sql'; Dest = (Join-Path $repo 'sql'); Name = 'fix_burgo_domain_verified_2026-07-16.sql' },
  @{ Pattern = 'handoff_burgo_verified_2026-07-16*.md';     Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_burgo_verified_2026-07-16.md' }
)

foreach ($m in $moves) {
  $src = Get-ChildItem -Path $dl -Filter $m.Pattern -File -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $src) { Write-Host ("SKIP  no match: " + $m.Pattern); continue }
  Unblock-File -Path $src.FullName
  [System.IO.Directory]::CreateDirectory($m.Dest) | Out-Null
  $target = [System.IO.Path]::Combine($m.Dest, $m.Name)
  [System.IO.File]::Copy($src.FullName, $target, $true)
  Remove-Item -LiteralPath $src.FullName -Force
  Write-Host ("OK    " + $src.Name + "  ->  " + $target)
}
Write-Host "DONE"
```

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/fix_burgo_domain_verified_2026-07-16.sql docs/handoff/2026-07-16/handoff_burgo_verified_2026-07-16.md
git commit -m "fix: Burgo website/mail domain split verified as correct (burgo.com web, burgogroup.com mail) - false positive recorded so it is not re-flagged; enrich Burgo Group (11+1 mills, ~3Mt/yr, containerboard expansion); no emails invented from a directory format"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 5. 오늘 스코어보드

| 유형 | 사례 | 상태 |
|---|---|---|
| 낡은 마케팅 | MLC, Zantat, 白石 | ✅ 처리 |
| 관련성 혼동 | Thiele (`fcc_fit ≠ paper_grade`) | ✅ 처리 |
| 구조적 중복 | Omya Korea, Taekyung ×2 | ✅ 처리 |
| | SMI/MTI 4행 | ⏳ 블록 1·2 대기 |
| 평가 누락 | JP top 5 | ✅ 처리 |
| 접근 불가 | SMI 컨택 3명 | ✅ 처리 (Sharad Mathur) |
| | 이름 없는 컨택 100+ | ⏳ 블록 4·5 대기 |
| 잘못된 연결 | Saica → Burgo | ✅ 처리 |
| **오탐** | **Burgo 도메인** | ✅ **검증 후 기록** |

**오탐도 처리해야 하는 결과입니다.** 기록 안 하면 다음 사람이 같은 조사를 반복하거나, 더 나쁘게는 "고쳐서" 망가뜨립니다.

## 6. 아직 안 받은 것 — 세 개

1. **`scan_us_smi_mti_structure` 블록 1·2** — 4행 병합의 전제. SMI는 FCC가 밀어내야 할 인커번트입니다
2. **`scan_bare_contacts` 블록 4·5** — **Omya (Korea) 이메일** + 이름 유도 미리보기. Omya Korea는 공정위 의결로 확정된 KR 1순위인데 컨택이 이름 없는 한 줄입니다
3. **일본 `has_ko` 5행**

**2번이 가장 값이 빨리 나옵니다** — 블록 4는 한 줄짜리 쿼리인데 KR 1순위의 유일한 컨택이 거기 있습니다.
