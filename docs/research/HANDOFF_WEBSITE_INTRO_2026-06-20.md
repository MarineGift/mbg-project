# HANDOFF — filler/paper_mill 홈페이지·회사소개 입력 작업 (2026-06-20)

> 이 문서는 새 세션에서 작업을 이어가기 위한 인계 문서다. **대화는 한국어**, 코드/SQL/콘솔 출력은 영어. 작업자는 단독 개발자(YunYoung), 두 대의 Windows(삼성 SS_LAPTOP-HEO / Lenovo), 로컬 repo `C:\Dev\mbg-project`.

---

## 0. 프로젝트 고정 정보
- Repo: `MarineGift/mbg-project` (PUBLIC), branch **`marinebiogroup`**, 로컬 `C:\Dev\mbg-project`
- Supabase project: `ogenmrgxwhpbfepeldqx`, **org_id = `b25de8f2-1020-482f-9012-183f63883169`**
- 소스 직접 읽기: `https://raw.githubusercontent.com/MarineGift/mbg-project/marinebiogroup/<path>` (route-group `(app)` → `%28app%29`)
- `party_types` lookup: 1 investor / 2 **paper_mill** / 3 **filler_supplier** / 4 buyer / 5 customer / 6 partner / 7 government_grant / 8 consultant / 9 crowdfunding_platform / 10 self / 11 other_supplier

## 1. 작업 워크플로우 (배치마다 동일)
1. Claude가 `YYYYMMDDHHMMSS_*.sql` 마이그레이션 + ASCII glob-mover `move_*.ps1` 생성 (outputs)
2. 사용자가 **Supabase SQL Editor**에 .sql 붙여넣어 실행 → 데이터 반영 ("Success. No rows returned" = UPDATE 정상). UPDATE가 많으면 verify SELECT가 결과를 보여줌
3. 사용자가 mover 실행 → 파일을 `supabase\migrations\`로 복사 후 `git add/commit/push origin marinebiogroup` (push=웹 자동배포)
   - mover 호출: `powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\move_*.ps1"`
4. verify CSV를 Claude에게 업로드 → 다음 배치

### 파일 인코딩 규칙 (중요)
- `.ps1` mover = **ASCII only** (PS 5.x가 UTF-8 no-BOM을 CP949로 깨뜨림 → 한글은 .ps1에 절대 금지)
- `.sql` = UTF-8 (no BOM) 허용 — SQL Editor에 붙여넣거나 mover가 **바이트 복사**만 하므로 안전 (PS 콘솔에 echo 안 함)
- `.md` 핸드오프 = **UTF-8 BOM** (`b'\xef\xbb\xbf' + data`)
- mover glob: `Get-ChildItem -Filter "$base*.sql"` (브라우저 " (1)" 접미사 허용), `Unblock-File`, `[System.IO.File]::Copy`

### 비파괴 enrichment 패턴
- `mineral_class = coalesce(d.mc, f.mineral_class)` (NULL이면 기존 유지)
- `notes = coalesce(f.notes,'') || E'\n[homepage 2026-06-20] ' || note` + 멱등 가드 `notes not like '%[homepage 2026-06-20]%'`
- website 칸에 메모가 있던 경우 → profile.notes로 `[ex-website-note 2026-06-20]` 태그로 보존 후 URL 입력
- 기존 팀 데이터(`market_role`,`supplier_type`,`evidence_level`,기존 notes)는 절대 덮어쓰지 않음(append만). intro_ko/en은 비어있어 overwrite OK
- UPDATE-first + INSERT-fallback(where not exists) 패턴

---

## 2. 지금까지 완료 (filler_supplier, type 3)
### intro/mineral_class/notes enrichment — **전체 완료** (HEAD `39a7dbb`)
- batch 7~13 적용+push 완료. type=3 전 ~239행에 intro_ko/en + mineral_class + 제지여부/공급처 notes
  - 7 JP5, 8 KR4, 9 IN9, 10 CN5, 11 글로벌 패밀리 일괄 170행(Omya42/SMI113/Imerys8/Carmeuse4/Sibelco3), 12 JP3+TR5, 13 나머지 38
- repo 마이그레이션: `20260620130000`~`190000_filler_supplier_profile_enrich_batch7..13.sql`

### website backfill (filler)
- **batch 14 = `20260620200000_filler_parties_website_families_batch14.sql`** : Omya→omya.com, SMI→mineralstech.com, Carmeuse→carmeuse.com, Sibelco→sibelco.com (이름 패턴, 메모는 notes 보존 후 URL). **★ 적용/verify 미확인 상태일 수 있음 — 새 세션 첫 확인 대상**

---

## 3. 진행 중: 홈페이지 없는 filler + paper_mill 채우기 (현재 작업)
"홈페이지 없음" 정의 = `website IS NULL OR website NOT ILIKE 'http%'` (website 칸에 메모가 든 행 포함)

### 현황 (discovery 결과)
- filler(type3): total 239, **no_website 129** (대부분 Omya/SMI/Carmeuse/Sibelco per-plant → batch14가 ~110 처리). 남은 진짜 독립계 ~19곳
- paper_mill(type2): total 1497, **no_website 1451, no_intro 1497**
- **우선순위 결정: supply-link 연결된 mill 먼저** (사용자 선택)

### party_supply_links 컬럼 (확인됨)
`id, filler_party_id, **mill_party_id**, link_type, confidence, active_since, active_until, volume_estimate, notes, extra_data, created_at, updated_at, deleted_at, organization_id, product_grade`
→ mill 쪽은 `mill_party_id` (paper_mill_party_id/party_id 없음)

### 연결 mill 중 홈페이지 없음 = **145곳** (count 확인)
discovery 쿼리:
```sql
select distinct p.id, p.party_name, p.website, p.country_code
from app.parties p
join app.party_supply_links sl on sl.mill_party_id = p.id
where p.party_type_id = 2
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and (p.website is null or p.website not ilike 'http%')
  and sl.deleted_at is null
order by p.party_name;   -- ★ "No limit"로 돌려 145행 전부 받을 것 (기본 100행 제한)
```

### mill 작업 방식
- `app.parties` 만 UPDATE: `website`(없을 때만) + `intro_ko`/`intro_en`. paper_mill_profile 불필요
- 대형 공개기업이라 **모회사 공식 도메인**으로 묶음 (mill site → parent corporate site)
- **제외**: `[Sector] ...` 행(섹터 placeholder, 실제 회사 아님). "Daehan Pulp"(website=`B`)는 대한제지(daehanpaper.com)와 동일사인지 불명 → 검증 후 결정

### mill batch 15 = `20260620210000_paper_mill_website_intro_batch15.sql` (★ 적용/verify 미확인)
연결 mill 26곳: 한국5(Hansol/Hansol Janghang/Moorim P&P/Moorim Paper/Hankuk) + Domtar4 + Mondi9 + Billerud3 + Holmen2 + Navigator3. 도메인 검증됨, intro 한·영.
- hansolpaper.com / moorimpnp.co.kr / moorimpaper.co.kr / hankukpaper.com / domtar.com / mondigroup.com / billerud.com / holmen.com / thenavigatorcompany.com

---

## 4. 남은 일 (다음 세션 TODO)
1. **batch 14·15 적용 확인** (verify CSV 받기): batch14=패밀리 with_url, batch15=with_url/with_intro/total=26
2. **연결 mill 나머지 ~119곳** (batch m2+): 도메인 검증 후 모회사별로 묶어 website+intro. 후보 대형사:
   Norske Skog(norskeskog.com)·Metsä Board(metsaboard.com)/Fibre(metsafibre.com)·Borregaard(borregaard.com)·Lenzing(lenzing.com)·Burgo(burgo.com)·Clearwater(clearwaterpaper.com)·Arctic Paper(arcticpaper.com)·ND Paper(ndpaper.com)·Nippon Paper(nipponpapergroup.com)·Chenming·Gold East/APP·Double A(doubleapaper.com)·Advance Agro·Phoenix Pulp·JK Paper(jkpaper.com)·Andhra Paper·Century Pulp&Paper·Ballarpur/BILT·Asia Symbol·Oji(Thailand)·CMPC·Arauco·Montes del Plata·Celulosa Argentina 등. 검증 안 되면 NULL 유지
   - ★ 전체 145행 목록을 "No limit"으로 먼저 확보(P~Z 미확인: Sappi/Smurfit/Stora Enso/Suzano/UPM/WestRock 등 추정)
3. **filler 독립계 ~19곳 website** (batch 15b): Graymont(graymont.com)·Calidra(calidra.com)·Lhoist Polska(lhoist.com)·Mississippi Lime(mississippilime.com)·Nordkalk(nordkalk.com)·IMI Fabi(imifabi.com)·터키 클러스터(Anadolu/Niğtaş/Mikron-S/Nidaş/Mikrokal)·Q-min·Kaolin Malaysia·Shiraishi Calcium Malaysia 등 — 자사 사이트 검증해서 입력, 안 되는 곳(EGM/Labtar/Calrock/CN Xianglong·Huayuan·Jinding)은 NULL 유지
4. (선택) paper_mill 비연결 mill(나머지 ~1,300곳)은 별도 우선순위 협의

---

## 5. 마이그레이션 타임스탬프 진행
마지막 push HEAD `39a7dbb` (batch13). 이후 생성: 14=`20260620200000`, 15=`20260620210000`. 다음은 `20260620220000`부터 이어서.
