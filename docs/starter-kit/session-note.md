# 세션 노트 — Unsupported Server Component type: undefined

---

**오후 7:54**
Investigated undefined component error across multiple pages and imports

`dynamic` 적용 후에도 계속되면 다른 컴포넌트가 원인입니다. 전체 진단을 합니다.

Ran a command, read a file
Ran a command, read a file

---

### 실행 방법

PowerShell을 열고 아래 명령어를 복사해서 실행하세요.

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; & "$env:USERPROFILE\Downloads\Diag-Components.ps1" -ProjectRoot "C:\dev\mbg-project" | Tee-Object "$env:USERPROFILE\Downloads\diag.txt"
```

`diag.txt` 붙여넣어 주세요 — import 목록과 각 컴포넌트의 export 이름을 확인해서 어디서 `undefined`가 나오는지 정확히 찾겠습니다.

---

### 스크립트가 검사하는 항목

| # | 검사 항목 | 설명 |
|---|-----------|------|
| 1 | export 방식 | `default` / `named` / `mixed` / `re-export` 분류 |
| 2 | import ↔ export 불일치 | default import ↔ named-only 파일, named import ↔ 존재하지 않는 이름 |
| 3 | Barrel 파일 순환 참조 | `index.ts` re-export 체인 목록 |
| 4 | `next/dynamic` 사용 현황 | dynamic() 호출 위치 전수 확인 |
| 5 | `'use client'` 누락 | 훅·이벤트 핸들러 사용하면서 지시어 없는 파일 |
| 6 | 빈 파일 / export 없는 파일 | components / app 폴더 내 빈 컴포넌트 탐지 |

---

### 파일 위치

```
%USERPROFILE%\Downloads\Diag-Components.ps1   ← 스크립트
%USERPROFILE%\Downloads\diag.txt              ← 결과 출력
```
