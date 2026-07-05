# Handoff — Introduction/Notes 중복 진단 & 제거 (2026-07-04)

## 상황
화면에 Introduction이 2개. 재구성한 최신 소스에는 각 1개뿐 → 두 원인 중 하나:
- **(A) 배포 지연**: 레이아웃 커밋(상단 이동)이 아직 라이브에 반영 안 됨 → 이전 배포는 하단 원본만, 새 배포는 상단만. 배포 전환기라면 캐시로 겹쳐 보일 수 있음
- **(B) 로컬 파일 중복**: 레이아웃 패치가 상단 추가는 했으나 하단 원본 삭제(L7) 앵커가 빗나가 두 블록이 파일에 공존

## 자가진단 패치 — `patch_dedupe_introduction.ps1`
실행하면 **파일 내 Introduction/Notes 개수를 먼저 출력**하고 분기:
- 개수 ≤ 1 → "(A) 배포 문제"로 판정, Railway 최신 커밋 배포 확인 + Ctrl+F5 안내 후 **파일 미변경**
- 개수 ≥ 2 → **두 번째(하단 원본) 블록 + 선행 Separator 제거**, 상단 1개만 유지 → BEFORE/AFTER 카운트 출력

멱등: 이미 1개면 아무것도 바꾸지 않음.

## 실행
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_dedupe_introduction.ps1
```
- "No duplicates ... OLD deploy" 출력 → 코드는 정상. Railway Deployments 탭에서 최신 커밋 상태 확인 후 하드 리프레시. (Failed면 로그 공유)
- "AFTER: Introduction=1" 출력 → npm run build → 아래 finish block

## 인라인 (동일 스크립트를 붙여넣기 원하면)
mover가 patch_*.ps1 을 tools\patches\ 로 라우팅하므로, 다운로드 후:
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_dedupe_introduction.ps1
```

## Finish block (파일이 변경된 경우에만)
```powershell
cd C:\dev\mbg-project
npm run build
git status -sb
git add src/components/parties/party-form.tsx docs/ tools/
git commit -m "fix(party-form): remove duplicate Introduction/Notes section (keep top copy)"
git push origin marinebiogroup
```
