# Patch 1 — {{contact.given_name}} 미치환 수정
# contact_id를 party page → ComposeEmailDialog → server action까지 전달

## 원인
party page에서 ComposeEmailDialog를 열 때 contactId가 전달되지 않아
renderWithContext 내부에서 contact 조회가 null로 처리됨.

---

## 1. src/app/(app)/[module]/parties/[id]/page.tsx

### 변경 전 (대략적인 기존 코드)
```tsx
// ComposeEmailDialog 호출 부분
<ComposeEmailDialog
  partyId={party.id}
  organizationId={organizationId}
/>
```

### 변경 후
```tsx
// 상단 import에 추가 (없으면)
'use client' // 이미 있으면 생략

// state 추가 (use client 컴포넌트 내부)
const [composeContactId, setComposeContactId] = useState<string | null>(null);
const [composeOpen, setComposeOpen] = useState(false);

// PartyCommunicationsTimeline에 onCompose 콜백 전달
<PartyCommunicationsTimeline
  partyId={party.id}
  organizationId={organizationId}
  onCompose={(contactId?: string) => {
    setComposeContactId(contactId ?? null);
    setComposeOpen(true);
  }}
/>

// ComposeEmailDialog
<ComposeEmailDialog
  open={composeOpen}
  onOpenChange={setComposeOpen}
  partyId={party.id}
  contactId={composeContactId}          // ← 추가
  organizationId={organizationId}
/>
```

---

## 2. src/components/parties/party-communications-timeline.tsx

### Props 타입에 onCompose 추가
```tsx
interface PartyCommunicationsTimelineProps {
  partyId: string;
  organizationId: string;
  onCompose?: (contactId?: string) => void;  // ← 추가
}

export function PartyCommunicationsTimeline({
  partyId,
  organizationId,
  onCompose,
}: PartyCommunicationsTimelineProps) {
```

### "이메일 작성" 버튼 클릭 핸들러
```tsx
// 기존 버튼 (연락처 목록의 이메일 아이콘 or 작성 버튼)
// 각 contact row에서
<Button
  size="sm"
  variant="ghost"
  onClick={() => onCompose?.(contact.id)}  // ← contact.id 전달
>
  <Mail className="h-4 w-4" />
</Button>

// 일반 "새 이메일" 버튼 (특정 contact 없이)
<Button onClick={() => onCompose?.()}>새 이메일 작성</Button>
```

---

## 3. src/components/email/compose-email-dialog.tsx

### Props 타입에 contactId 추가
```tsx
interface ComposeEmailDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  partyId: string;
  contactId?: string | null;   // ← 추가
  organizationId: string;
  mode?: 'new' | 'reply' | 'template';
  replyTo?: { messageId: string; subject: string; from: string };
}
```

### sendEmail / handleSend 호출 시 contactId 포함
```tsx
const result = await sendEmail({
  partyId,
  contactId: contactId ?? undefined,   // ← 추가
  organizationId,
  to: toAddress,
  subject,
  body: htmlBody,
  templateId: selectedTemplateId,
  mode,
  replyTo,
});
```

---

## 4. src/lib/actions/email-compose.ts

### sendEmail action 파라미터에 contactId 추가
```typescript
export interface SendEmailParams {
  partyId: string;
  contactId?: string;           // ← 추가
  organizationId: string;
  to: string;
  subject: string;
  body?: string;
  templateId?: string;
  mode: 'new' | 'reply' | 'template';
  replyTo?: { messageId: string; subject: string; from: string };
}

export async function sendEmail(params: SendEmailParams) {
  const {
    partyId,
    contactId,                  // ← 추가
    organizationId,
    to, subject, body, templateId, mode, replyTo,
  } = params;

  // renderWithContext 호출 시 contactId 전달 (이미 함수 시그니처에 있다면 그대로)
  const rendered = templateId
    ? await renderWithContext(templateId, { partyId, contactId })  // ← contactId 추가
    : { subject, html: body ?? '' };

  // ... 이하 기존 로직
}
```

### renderWithContext 함수 내부 확인
```typescript
// 기존 renderWithContext가 contactId를 받아 처리하는지 확인
// contact 조회 쿼리:
async function renderWithContext(
  templateId: string,
  context: { partyId: string; contactId?: string }
) {
  const supabase = createServerComponentClient({ cookies });

  // party 조회
  const { data: party } = await supabase
    .from('parties')
    .select('name, ...')
    .eq('id', context.partyId)
    .single();

  // contact 조회 — contactId가 없으면 party의 primary contact 사용
  let contact = null;
  if (context.contactId) {
    const { data } = await supabase
      .from('contacts')
      .select('given_name, family_name, email, title')
      .eq('id', context.contactId)
      .single();
    contact = data;
  } else {
    // fallback: 해당 party의 첫 번째 contact
    const { data } = await supabase
      .from('contacts')
      .select('given_name, family_name, email, title')
      .eq('party_id', context.partyId)
      .order('created_at')
      .limit(1)
      .single();
    contact = data;
  }

  // 치환
  let html = template.body_html ?? '';
  let subj = template.subject ?? '';

  // {{party.name}} 치환
  html = html.replaceAll('{{party.name}}', party?.name ?? '');
  subj = subj.replaceAll('{{party.name}}', party?.name ?? '');

  // {{contact.*}} 치환
  if (contact) {
    html = html.replaceAll('{{contact.given_name}}', contact.given_name ?? '');
    html = html.replaceAll('{{contact.family_name}}', contact.family_name ?? '');
    html = html.replaceAll('{{contact.email}}', contact.email ?? '');
    html = html.replaceAll('{{contact.title}}', contact.title ?? '');
    subj = subj.replaceAll('{{contact.given_name}}', contact.given_name ?? '');
  }

  return { subject: subj, html };
}
```
