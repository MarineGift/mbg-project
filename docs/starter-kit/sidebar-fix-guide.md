# Sidebar Fix — filler → filler_supplier

## 진단 (사용자 실행)

```powershell
# 사이드바 코드 확인
Get-Content "C:\dev\mbg-project\src\components\layout\sidebar.tsx" | Select-String "filler" -Context 2,2
```

## 가능한 코드 패턴 + 변경

### 패턴 A: 인라인 모듈 리스트

찾을 부분:
```tsx
{ key: 'filler', ... href: '/filler' ... }
```

변경:
```tsx
{ key: 'filler_supplier', ... href: '/filler_supplier' ... }
```

### 패턴 B: 별도 constants 파일에서 import

만약 사이드바가 `MODULES` 같은 배열을 import하면, 그 정의 파일 (e.g. `src/lib/constants/modules.ts`)을 같은 방식으로 변경.

### 패턴 C: 두 곳 분리 (PARTIES vs ENGAGEMENTS)

사용자 화면을 보면 사이드바에 PARTIES + ENGAGEMENTS 두 섹션이 있는데 각각 5개씩 module. **둘 다 변경** 필요할 수도.

## 가장 안전한 변경 명령

```powershell
cd C:\dev\mbg-project

# UTF-8 BOM 없이 사이드바 파일 안전 변경
$file = "src\components\layout\sidebar.tsx"
$content = [System.IO.File]::ReadAllText((Resolve-Path $file).Path, [System.Text.Encoding]::UTF8)

# 'filler' → 'filler_supplier' 정확한 매치 (분리된 단어)
# /filler → /filler_supplier  
# 'filler' (quote) → 'filler_supplier'
$content = $content -replace "'/filler'", "'/filler_supplier'"
$content = $content -replace '"/filler"', '"/filler_supplier"'
$content = $content -replace "key:\s*'filler'", "key: 'filler_supplier'"
$content = $content -replace 'key:\s*"filler"', 'key: "filler_supplier"'
$content = $content -replace "module:\s*'filler'", "module: 'filler_supplier'"
$content = $content -replace 'module:\s*"filler"', 'module: "filler_supplier"'

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Resolve-Path $file).Path, $content, $utf8NoBom)

# 확인
Select-String -Path $file -Pattern "filler"
```

⚠️ 이 명령은 'filler'라는 모든 문자열을 'filler_supplier'로 바꾸지 않습니다. 정확히 위 패턴만 매칭. 

## 사이드바 변경 후 검증

브라우저:
- 사이드바 "Filler Suppliers" 클릭
- URL: `localhost:3000/filler_supplier/engagements`
- Kanban: 6 cards (Contact → Contract)
