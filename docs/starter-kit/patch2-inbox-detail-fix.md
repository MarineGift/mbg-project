# Patch 2 — Inbox 상세 "Message not found" 수정
# fetchCommunicationDetail을 inbox detail page/component에 연결

---

## 1. src/lib/queries/communications.ts — fetchCommunicationDetail 확인

기존에 함수가 추가되어 있다면 아래와 같은 형태인지 확인:

```typescript
export async function fetchCommunicationDetail(messageId: string) {
  const supabase = createServerComponentClient({ cookies });

  const { data, error } = await supabase
    .from('communications')
    .select(`
      id,
      message_id,
      thread_id,
      in_reply_to,
      subject,
      body_html,
      body_text,
      from_address,
      to_addresses,
      cc_addresses,
      occurred_at,
      direction,
      status,
      contact_id,
      party_id,
      contacts (
        id,
        given_name,
        family_name,
        email
      ),
      parties (
        id,
        name
      )
    `)
    .eq('id', messageId)
    .single();

  if (error) throw error;
  return data;
}
```

**주의**: `.eq('id', messageId)` — URL param이 UUID인지, message_id 문자열인지 확인 필요.
- inbox 목록에서 클릭 시 전달하는 값이 `comm.id` (UUID)이면 → `.eq('id', messageId)`
- `comm.message_id` (IMAP Message-ID 헤더)이면 → `.eq('message_id', messageId)`

---

## 2. Inbox 상세 페이지 생성/수정

### 파일 위치 (없으면 생성)
`src/app/(app)/inbox/[id]/page.tsx`

```tsx
import { fetchCommunicationDetail } from '@/lib/queries/communications';
import { notFound } from 'next/navigation';
import { format } from 'date-fns';
import { ko } from 'date-fns/locale';
import { ArrowLeft, Mail, User, Building2 } from 'lucide-react';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader } from '@/components/ui/card';

interface Props {
  params: { id: string };
}

export default async function InboxDetailPage({ params }: Props) {
  let comm;
  try {
    comm = await fetchCommunicationDetail(params.id);
  } catch {
    notFound();
  }

  if (!comm) notFound();

  const contact = Array.isArray(comm.contacts)
    ? comm.contacts[0]
    : comm.contacts;
  const party = Array.isArray(comm.parties)
    ? comm.parties[0]
    : comm.parties;

  return (
    <div className="max-w-3xl mx-auto p-6 space-y-4">
      {/* 상단 네비게이션 */}
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="sm" asChild>
          <Link href="/inbox">
            <ArrowLeft className="h-4 w-4 mr-1" />
            받은편지함
          </Link>
        </Button>
        <Badge variant={comm.direction === 'inbound' ? 'secondary' : 'default'}>
          {comm.direction === 'inbound' ? '수신' : '발신'}
        </Badge>
      </div>

      <Card>
        <CardHeader className="space-y-2 pb-3">
          <h1 className="text-xl font-semibold">{comm.subject ?? '(제목 없음)'}</h1>
          <div className="text-sm text-muted-foreground space-y-1">
            <div className="flex items-center gap-2">
              <Mail className="h-3.5 w-3.5" />
              <span>
                {comm.direction === 'inbound'
                  ? `보낸 사람: ${comm.from_address}`
                  : `받는 사람: ${(comm.to_addresses as string[])?.join(', ')}`}
              </span>
            </div>
            {contact && (
              <div className="flex items-center gap-2">
                <User className="h-3.5 w-3.5" />
                <span>{contact.given_name} {contact.family_name}</span>
              </div>
            )}
            {party && (
              <div className="flex items-center gap-2">
                <Building2 className="h-3.5 w-3.5" />
                <span>{party.name}</span>
              </div>
            )}
            <div className="text-xs">
              {format(new Date(comm.occurred_at), 'PPP HH:mm', { locale: ko })}
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {comm.body_html ? (
            <div
              className="prose prose-sm max-w-none"
              dangerouslySetInnerHTML={{ __html: comm.body_html }}
            />
          ) : (
            <pre className="whitespace-pre-wrap text-sm">{comm.body_text}</pre>
          )}
        </CardContent>
      </Card>

      {/* 스레드 메시지가 있으면 나중에 확장 */}
    </div>
  );
}
```

---

## 3. Inbox 목록에서 링크 연결 확인

`src/app/(app)/inbox/page.tsx` 또는 inbox list 컴포넌트에서
각 행 클릭 시 `/inbox/${comm.id}` 로 이동하는지 확인:

```tsx
// 기존 onClick 혹은 href
href={`/inbox/${comm.id}`}
// 또는
router.push(`/inbox/${comm.id}`)
```

---

## 4. 에러 발생 위치 추가 확인

만약 상세 페이지가 이미 존재하는데 에러가 나는 경우:

```typescript
// communications.ts의 fetchCommunicationDetail 상단에 로그 추가
export async function fetchCommunicationDetail(id: string) {
  console.log('[fetchCommunicationDetail] id:', id);  // 디버그용
  const supabase = createServerComponentClient({ cookies });

  const { data, error } = await supabase
    .from('communications')
    .select('...')
    .eq('id', id)
    .single();

  console.log('[fetchCommunicationDetail] result:', data, 'error:', error);
  if (error) throw new Error(`Communication not found: ${id} — ${error.message}`);
  return data;
}
```

→ 서버 터미널에서 실제 id 값과 에러 메시지 확인
