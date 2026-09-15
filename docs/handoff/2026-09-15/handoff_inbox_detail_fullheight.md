# HANDOFF - Inbox 상세 화면: 상단 여백 축소 + 메일 본문 전체 높이 표시

날짜: 2026-09-14 · 대상: URM Platform (`Marinegift/MBG-Project`, branch `marinebiogroup`)
화면: `/inbox/[id]` (예: urm.marinebiogroup.com/inbox/813619fc-...)

## 문제
- HTML 메일 본문 iframe 이 `min-h-[240px] max-h-[600px]` 에 높이 지정이 없어 실제로는 약 240px 박스 안에서만 스크롤됨.
- 상단에 Back 버튼 / 제목 / 메시지 수 / Deal picker 가 각각 한 줄씩 차지 + `p-6` 카드 패딩 → 본문이 화면 아래로 밀림.

## 변경 내용
| 파일 | 변경 |
|---|---|
| `src/components/inbox/email-html-frame.tsx` (신규) | 본문 iframe 을 **내용 높이에 맞춰 자동 확장**. 메일 전체가 페이지 스크롤 하나로 읽힘(내부 스크롤 박스 없음). 이미지 늦게 로드/창 크기 변경 시 재측정(ResizeObserver + load 이벤트 + 타이머). 측정 전·측정 불가 시 `max(420px, 100dvh-200px)` 로 크게 표시. |
| `src/app/(app)/inbox/[id]/page.tsx` | 페이지 패딩 `p-4 sm:p-6 space-y-4` → `px-2 py-2 sm:px-4 sm:py-3`. 별도 줄 Back 버튼 제거 → 뷰에 `backHref` 전달. |
| `src/components/inbox/communication-detail-view.tsx` | ① `←` 아이콘 + 제목 + "N messages" 를 **한 줄**로 ② 파티 배지/이름 + Deal picker 를 **한 줄**로 ③ 메시지 카드 헤더 `p-6` → `px-3 py-2` ④ 본문 영역 패딩 축소 ⑤ "Reply to this message" 버튼을 To/Message-ID 메타 줄 **오른쪽**으로 이동(별도 줄 제거) ⑥ 하단 Reply 카드 헤더 제거(한 줄) ⑦ plain-text 본문의 `max-h-[500px]` 제거(전체 표시) ⑧ 미사용 `CardTitle` import 제거 |

### 보안 메모
iframe sandbox 에 `allow-same-origin` 을 추가(부모가 높이를 읽기 위해). **`allow-scripts` 는 없음** → 메일 안의 스크립트는 여전히 실행 불가. 두 옵션을 함께 넣지 말 것(컴포넌트 주석에 명시).

## 적용

### A) 패치 실행 (권장 - 다운로드 파일 이동 불필요)
`patch_inbox_detail_fullheight.ps1` 을 받았다면:
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_inbox_detail_fullheight.ps1
```
`-File` 실행이 아무 출력 없이 끝나면(PS 5.x 간헐 현상) 아래 **인라인 블록 전체**를 PowerShell 창에 붙여넣기.

### B) 파일 이동만 (fallback, patch 파일 → tools\patches)
```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter 'patch_inbox_detail_fullheight*.ps1' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($src) { Unblock-File $src.FullName; $dst = 'C:\dev\mbg-project\tools\patches'; [System.IO.Directory]::CreateDirectory($dst) | Out-Null; [System.IO.File]::Copy($src.FullName, (Join-Path $dst 'patch_inbox_detail_fullheight.ps1'), $true); Write-Host "copied $($src.Name)" } else { Write-Host 'not found in Downloads' }
```

### C) 인라인 패치 블록 (그대로 붙여넣기)
멱등: 두 번 실행해도 `[SKIP]` 만 출력. 마지막 줄 `DONE: inbox detail patched` 확인.
```powershell
# patch_inbox_detail_fullheight.ps1
# Inbox detail: shrink top whitespace + auto-height email body (read full mail with page scroll).
# Idempotent. ASCII only. Run from anywhere; repo = C:\dev\mbg-project
$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Norm([string]$s) { return ($s -replace "`r`n", "`n") }
function Apply-Edit([string]$rel, [string]$old, [string]$new, [string]$label) {
  $p = [System.IO.Path]::Combine($repo, $rel)
  if (-not [System.IO.File]::Exists($p)) { Write-Host "[MISS] $rel not found"; return }
  $s = Norm ([System.IO.File]::ReadAllText($p, $utf8))
  $o = Norm $old; $n = Norm $new
  if ($n.Length -gt 0 -and $s.Contains($n)) { Write-Host "[SKIP] $label (already applied)"; return }
  $idx = $s.IndexOf($o)
  if ($idx -lt 0) { Write-Host "[SKIP] $label (already applied or anchor changed)"; return }
  if ($s.IndexOf($o, $idx + 1) -ge 0) { Write-Host "[WARN] $label anchor not unique - skipped"; return }
  $s = $s.Substring(0, $idx) + $n + $s.Substring($idx + $o.Length)
  [System.IO.File]::WriteAllText($p, $s, $utf8)
  Write-Host "[OK]   $label"
}

# 1) new component (always overwritten)
$compRel = 'src\components\inbox\email-html-frame.tsx'
$compPath = [System.IO.Path]::Combine($repo, $compRel)
[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($compPath)) | Out-Null
$comp = @'
'use client';

/**
 * EmailHtmlFrame - renders an HTML email body in a sandboxed iframe whose height
 * grows to fit the full message, so the email is read with the page's own scroll
 * (no small inner scroll box).
 *
 * Security: sandbox has NO `allow-scripts`, so nothing inside the email can execute.
 * `allow-same-origin` is added only so the parent can measure the content height.
 * (Never add allow-scripts together with allow-same-origin.)
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import { cn } from '@/lib/utils';

const MIN_HEIGHT = 200;
const ROOT_ID = 'mbg-email-root';
/** Used until the real content height is known (or if measuring is impossible). */
const FALLBACK_HEIGHT = 'max(420px, calc(100dvh - 200px))';

interface Props {
  html: string;
  className?: string;
  title?: string;
}

export function EmailHtmlFrame({ html, className, title = 'email-body' }: Props) {
  const frameRef = useRef<HTMLIFrameElement>(null);
  const cleanupRef = useRef<(() => void) | null>(null);
  const [height, setHeight] = useState<number | null>(null);

  const measure = useCallback(() => {
    const doc = frameRef.current?.contentDocument;
    if (!doc) return;
    const root = doc.getElementById(ROOT_ID);
    if (!root) return;
    const h = Math.max(
      root.offsetTop + root.offsetHeight,
      root.offsetTop + root.scrollHeight,
    );
    if (h > 0) {
      const next = Math.max(MIN_HEIGHT, Math.ceil(h) + 4);
      setHeight((prev) => (prev === next ? prev : next));
    }
  }, []);

  const setup = useCallback(() => {
    cleanupRef.current?.();
    cleanupRef.current = null;

    const frame = frameRef.current;
    const doc = frame?.contentDocument;
    if (!frame || !doc) return;

    measure();

    const timers = [100, 400, 1000, 2500].map((ms) => window.setTimeout(measure, ms));

    // Late-loading images change the height.
    const onAssetLoad = () => measure();
    doc.addEventListener('load', onAssetLoad, true);
    doc.addEventListener('error', onAssetLoad, true);

    let ro: ResizeObserver | null = null;
    const root = doc.getElementById(ROOT_ID);
    if (root && typeof ResizeObserver !== 'undefined') {
      ro = new ResizeObserver(() => measure());
      ro.observe(root);
    }

    // Width changes (sidebar toggle, window resize) re-flow the email.
    window.addEventListener('resize', onAssetLoad);

    cleanupRef.current = () => {
      timers.forEach((t) => window.clearTimeout(t));
      doc.removeEventListener('load', onAssetLoad, true);
      doc.removeEventListener('error', onAssetLoad, true);
      window.removeEventListener('resize', onAssetLoad);
      ro?.disconnect();
    };
  }, [measure]);

  // The iframe may finish loading before React hydrates (missed onLoad).
  useEffect(() => {
    if (frameRef.current?.contentDocument?.readyState === 'complete') setup();
    return () => {
      cleanupRef.current?.();
      cleanupRef.current = null;
    };
  }, [html, setup]);

  const srcDoc =
    '<base target="_blank">' +
    '<style>html,body{margin:0;padding:0;}</style>' +
    `<div id="${ROOT_ID}" style="display:flow-root;` +
    'font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;' +
    'font-size:14px;line-height:1.6;color:#111;padding:12px;' +
    'word-break:break-word;overflow-wrap:anywhere;">' +
    html +
    '</div>';

  return (
    <iframe
      ref={frameRef}
      title={title}
      sandbox="allow-same-origin allow-popups allow-popups-to-escape-sandbox"
      onLoad={setup}
      className={cn('block w-full rounded-md border border-border bg-white', className)}
      style={{ height: height != null ? `${height}px` : FALLBACK_HEIGHT }}
      srcDoc={srcDoc}
    />
  );
}
'@
[System.IO.File]::WriteAllText($compPath, (Norm $comp) + "`n", $utf8)
Write-Host "[OK]   wrote $compRel"

# edit 1
$old = @'
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
'@
$new = ''
Apply-Edit 'src\app\(app)\inbox\[id]\page.tsx' ($old + "`n") ($new ) 'edit 1'

# edit 2
$old = @'
    <div className="p-4 sm:p-6 space-y-4">
      <MarkThreadRead ids={threadIds} />
      <Button variant="ghost" size="sm" asChild>
        <Link href="/inbox">
          <ArrowLeft className="h-4 w-4 mr-1" />
          Back
        </Link>
      </Button>
      <CommunicationDetailView
'@
$new = @'
    <div className="px-2 py-2 sm:px-4 sm:py-3">
      <MarkThreadRead ids={threadIds} />
      <CommunicationDetailView
        backHref="/inbox"
'@
Apply-Edit 'src\app\(app)\inbox\[id]\page.tsx' ($old + "`n") ($new + "`n") 'edit 2'

# edit 3
$old = @'
  ChevronDown, ChevronRight, Eye, Send,
} from 'lucide-react';
'@
$new = @'
  ChevronDown, ChevronRight, Eye, Send, ArrowLeft,
} from 'lucide-react';
'@
Apply-Edit 'src\components\inbox\communication-detail-view.tsx' ($old ) ($new ) 'edit 3'

# edit 4
$old = @'
import { ComposeEmailDialog } from '@/components/email/compose-email-dialog';
'@
$new = @'
import { ComposeEmailDialog } from '@/components/email/compose-email-dialog';
import { EmailHtmlFrame } from '@/components/inbox/email-html-frame';
'@
Apply-Edit 'src\components\inbox\communication-detail-view.tsx' ($old + "`n") ($new + "`n") 'edit 4'

# edit 5
$old = @'
  timeZone?: string;
}

export function CommunicationDetailView({ thread, rootId, templates, openStatuses, timeZone }: Props) {
'@
$new = @'
  timeZone?: string;
  /** When set, a compact back arrow is shown next to the subject. */
  backHref?: string;
}

export function CommunicationDetailView({ thread, rootId, templates, openStatuses, timeZone, backHref }: Props) {
'@
Apply-Edit 'src\components\inbox\communication-detail-view.tsx' ($old ) ($new ) 'edit 5'

# edit 6
$old = @'
    <div className="space-y-3">
      {/* Thread header */}
      <div className="px-1 pb-1">
        <h1 className="text-lg font-semibold truncate">
          {threadSubject || <span className="italic text-muted-foreground">{t('noSubject')}</span>}
        </h1>
        <div className="flex items-center gap-2 mt-1 text-xs text-muted-foreground flex-wrap">
          {partyContext && <PartyTypeBadge partyType={partyContext.partyType} size="sm" />}
          {partyContext && (
            <Link
              href={`/${partyContext.partyType}/parties/${partyContext.id}`}
              className="hover:underline truncate text-primary"
            >
              {partyContext.name}
            </Link>
          )}
          <span className="ml-auto">
            {thread.length} {thread.length === 1 ? 'message' : 'messages'}
          </span>
        </div>
        {partyContext && (
          <div className="mt-2">
            <DealReassignPicker
              communicationId={root?.id ?? rootId}
              partyId={partyContext.id}
              currentDealId={root?.dealId ?? latest?.dealId ?? null}
            />
          </div>
        )}
      </div>
'@
$new = @'
    <div className="space-y-2">
      {/* Thread header (compact: back + subject + count on one row) */}
      <div className="px-1">
        <div className="flex items-center gap-1.5 min-w-0">
          {backHref && (
            <Button variant="ghost" size="icon" className="h-8 w-8 shrink-0" asChild>
              <Link href={backHref} aria-label="Back">
                <ArrowLeft className="h-4 w-4" />
              </Link>
            </Button>
          )}
          <h1 className="flex-1 min-w-0 text-base sm:text-lg font-semibold truncate">
            {threadSubject || <span className="italic text-muted-foreground">{t('noSubject')}</span>}
          </h1>
          <span className="shrink-0 text-xs text-muted-foreground">
            {thread.length} {thread.length === 1 ? 'message' : 'messages'}
          </span>
        </div>
        {partyContext && (
          <div className="flex items-center gap-2 mt-1 text-xs text-muted-foreground flex-wrap">
            <PartyTypeBadge partyType={partyContext.partyType} size="sm" />
            <Link
              href={`/${partyContext.partyType}/parties/${partyContext.id}`}
              className="hover:underline truncate text-primary"
            >
              {partyContext.name}
            </Link>
            <div className="ml-auto">
              <DealReassignPicker
                communicationId={root?.id ?? rootId}
                partyId={partyContext.id}
                currentDealId={root?.dealId ?? latest?.dealId ?? null}
              />
            </div>
          </div>
        )}
      </div>
'@
Apply-Edit 'src\components\inbox\communication-detail-view.tsx' ($old + "`n") ($new + "`n") 'edit 6'

# edit 7
$old = @'
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm">Reply</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-wrap gap-2 items-center">
'@
$new = @'
        <Card>
          <CardContent className="flex flex-wrap gap-2 items-center p-3">
'@
Apply-Edit 'src\components\inbox\communication-detail-view.tsx' ($old ) ($new ) 'edit 7'

# edit 8
$old = @'
        <CardHeader className="pb-3">
          <div className="flex items-start gap-2">
            {expanded ? (
'@
$new = @'
        <CardHeader className="px-3 py-2 sm:px-4">
          <div className="flex items-start gap-2">
            {expanded ? (
'@
Apply-Edit 'src\components\inbox\communication-detail-view.tsx' ($old ) ($new ) 'edit 8'

# edit 9
$old = @'
        <CardContent className="space-y-3 pt-0">
          {onReply && (
            <div className="flex justify-end">
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="h-7 text-xs"
                onClick={(e) => { e.stopPropagation(); onReply(); }}
              >
                <Send className="h-3 w-3 mr-1" />
                Reply to this message
              </Button>
            </div>
          )}
          {/* Metadata grid */}
          <div className="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 text-xs">
'@
$new = @'
        <CardContent className="space-y-2 px-2 pb-2 pt-0 sm:px-3 sm:pb-3">
          <div className="flex items-start gap-3 px-1">
          {/* Metadata grid */}
          <div className="flex-1 min-w-0 grid grid-cols-[auto_1fr] gap-x-3 gap-y-0.5 text-xs">
'@
Apply-Edit 'src\components\inbox\communication-detail-view.tsx' ($old ) ($new ) 'edit 9'

# edit 10
$old = @'
                <span className="text-destructive">{msg.errorMessage}</span>
              </>
            )}
          </div>
'@
$new = @'
                <span className="text-destructive">{msg.errorMessage}</span>
              </>
            )}
          </div>
          {onReply && (
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="h-7 text-xs shrink-0"
              onClick={(e) => { e.stopPropagation(); onReply(); }}
            >
              <Send className="h-3 w-3 mr-1" />
              Reply to this message
            </Button>
          )}
          </div>
'@
Apply-Edit 'src\components\inbox\communication-detail-view.tsx' ($old + "`n") ($new + "`n") 'edit 10'

# edit 11
$old = @'
            <iframe
              title="email-body"
              sandbox="allow-popups allow-popups-to-escape-sandbox"
              className="w-full rounded-md border border-border bg-white min-h-[240px] max-h-[600px]"
              srcDoc={
                '<base target="_blank">' +
                '<div style="font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;' +
                'font-size:14px;line-height:1.6;color:#111;padding:12px;' +
                'word-break:break-word;overflow-wrap:anywhere;">' +
                msg.bodyHtml +
                '</div>'
              }
            />
'@
$new = @'
            <EmailHtmlFrame html={msg.bodyHtml} />
'@
Apply-Edit 'src\components\inbox\communication-detail-view.tsx' ($old ) ($new ) 'edit 11'

# edit 12
$old = @'
rounded-md bg-muted/30 p-3 text-sm whitespace-pre-wrap leading-relaxed max-h-[500px] overflow-y-auto scrollbar-thin break-words
'@
$new = @'
rounded-md bg-muted/30 p-3 text-sm whitespace-pre-wrap leading-relaxed break-words
'@
Apply-Edit 'src\components\inbox\communication-detail-view.tsx' ($old ) ($new ) 'edit 12'

# edit 13
$old = @'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
'@
$new = @'
import { Card, CardContent, CardHeader } from '@/components/ui/card';
'@
Apply-Edit 'src\components\inbox\communication-detail-view.tsx' ($old ) ($new ) 'edit 13'

# verify
$v = [System.IO.File]::ReadAllText([System.IO.Path]::Combine($repo, 'src\components\inbox\communication-detail-view.tsx'))
if ($v.Contains('<EmailHtmlFrame') -and $v.Contains('backHref')) { Write-Host 'DONE: inbox detail patched' } else { Write-Host 'CHECK: patch incomplete - see messages above' }
```

## 확인 · 배포
```powershell
cd C:\dev\mbg-project
git status -sb
git add "src/app/(app)/inbox/[id]/page.tsx" src/components/inbox/communication-detail-view.tsx src/components/inbox/email-html-frame.tsx tools/patches/patch_inbox_detail_fullheight.ps1 docs/handoff
git commit -m "inbox detail: compact header + auto-height email body"
git push origin marinebiogroup
```
> push = Railway 자동 배포 → 바로 웹에 반영됨.

배포 후 체크:
1. 긴 뉴스레터 메일(예: Greentown 5 Things) → 본문이 잘리지 않고 끝까지 보이고, 페이지 스크롤 하나로 읽히는지
2. 이미지 많은 메일 → 이미지 로드 후 아래가 잘리지 않는지
3. 사이드바 접기/창 크기 변경 → 높이 재조정
4. 본문 링크 클릭 → 새 탭으로 열리는지
5. 모바일 폭 → 제목 줄 말줄임, Reply 버튼 줄바꿈 정상

## 검증 상태
- `tsc --noEmit`: 변경 파일 오류 0 (기존 오류 12건은 `schedule/*`, `parties/page.tsx`, `api/relay/mail` 에 이미 있던 것 - 이번 변경과 무관, `ignoreBuildErrors: true` 로 빌드 영향 없음).
- 패치 스크립트: 원본 파일에 13개 편집 전부 적용 → 결과가 검증본과 바이트 동일, 재실행 시 전부 SKIP(멱등) 확인.
- 미검증: 실제 브라우저 렌더(배포 후 위 체크리스트로 확인).

## 다음 개선 후보(선택)
- 상단 전역 TopBar(Today/Calendar) 를 상세 화면에서 숨기는 "읽기 모드" 토글.
- 스레드가 길 때 이전 메시지 일괄 접기/펼치기 버튼.
