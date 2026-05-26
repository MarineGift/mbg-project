# v5.9 Step C-3 — Pipeline Stages Admin UI 설치 가이드

## 파일 4개 복사

```powershell
cd $env:USERPROFILE\Downloads

# 1. 서버 액션
copy C3-actions-pipeline-stages.ts `
     "C:\dev\mbg-project\src\lib\actions\pipeline-stages.ts"

# 2. settings/pipelines 폴더 생성
mkdir "C:\dev\mbg-project\src\app\(app)\settings\pipelines"

# 3. 페이지 + 클라이언트 컴포넌트
copy C3-page.tsx                    `
     "C:\dev\mbg-project\src\app\(app)\settings\pipelines\page.tsx"
copy C3-PipelinesAdminClient.tsx    `
     "C:\dev\mbg-project\src\app\(app)\settings\pipelines\PipelinesAdminClient.tsx"
copy C3-StageFormDialog.tsx         `
     "C:\dev\mbg-project\src\app\(app)\settings\pipelines\StageFormDialog.tsx"
```

## 직접 접근 — 사이드바 링크 없이도 동작

dev server 시작 후 브라우저에서 즉시 접근 가능:

```
http://localhost:3000/settings/pipelines
```

## 사이드바에 메뉴 추가 (선택)

현재 사이드바에 "Settings" 또는 "Admin" 섹션이 보이지 않으면 추가 필요.

### 위치 확인
```powershell
Get-ChildItem "C:\dev\mbg-project\src\components\layout\" -Filter "*.tsx"
Get-Content "C:\dev\mbg-project\src\components\layout\sidebar.tsx" | Select-String "nav|Settings" -Context 0,1
```

### 일반적인 추가 위치
sidebar 컴포넌트에 다음 같이 추가:

```tsx
// 일반적인 nav config 패턴
const navItems = [
  { href: '/dashboard',  label: 'Dashboard' },
  { href: '/inbox',      label: 'Inbox' },
  { href: '/drafts',     label: 'AI Drafts' },
  { href: '/tasks',      label: 'Tasks' },
  // ... 추가 ↓
  { href: '/settings/pipelines', label: 'Pipeline Stages', section: 'admin' },
]
```

또는 별도 "Settings" 섹션을 만들어:

```tsx
<div className="mt-auto pt-4 border-t">
  <Link href="/settings/pipelines" className="flex items-center gap-2 px-3 py-2 hover:bg-accent rounded-md">
    <Settings className="h-4 w-4" />
    <span className="text-sm">Settings</span>
  </Link>
</div>
```

## 검증

1. `http://localhost:3000/settings/pipelines` 접속
2. 5개 module의 cards가 보임:
   - Investors (6 stages, 한국어)
   - Paper Companies (6 stages, 한국어)
   - Partners (6 stages, 한국어)
   - Customers (6 stages, 한국어)
   - **Filler Suppliers (8 stages, 영어)** ← [SAMPLE]
3. 각 stage row의 actions: ↑ ↓ ✏ 🗑
4. "Add Stage" 버튼 → modal 열림

## 잘 작동하면 할 수 있는 작업

### 1. 한국어 stages → 영어로 변경
4개 module의 한국어 stages를 영어로 편집 (Edit 버튼):
- 리드 → Lead
- 자격검증 → Qualified
- 제안 → Proposal
- 협상 → Negotiation
- 🏆 성공 → Won
- 실패 → Lost

### 2. module별 stages 차별화
사용자가 원하는 module별 다른 흐름으로 customize:
- paper_mill: Contact → Spec Review → Sample → Mill Trial → Quote → Contract → Won/Lost
- partner: Initial Contact → Joint Planning → MoU → Active/Inactive
- investor: Contact → Pitch → DD → Term Sheet → Closing → Funded/Passed

### 3. 색상 / 확률 조정
각 stage의 색상 (color picker) + 확률 (0-100%) UI에서 즉시 변경

### 4. Stage 추가/삭제
필요한 만큼 자유롭게 추가/삭제 가능
