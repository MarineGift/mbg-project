===== C:\dev\mbg-project\src\lib\queries\email-signatures.ts =====
```ts
'use server';
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { cookies } from 'next/headers';

export interface EmailSignature {
  id: string;
  organization_id: string;
  name: string;
  html_content: string;
  is_default: boolean;
  created_at: string;
  updated_at: string;
}

export async function getSignatures(orgId: string): Promise<EmailSignature[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from('email_signatures').select('*').eq('organization_id', orgId)
    .order('is_default', { ascending: false });
  if (error) throw error;
  return data ?? [];
}

export async function getDefaultSignature(orgId: string): Promise<EmailSignature | null> {
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase
    .from('email_signatures').select('*')
    .eq('organization_id', orgId).eq('is_default', true).maybeSingle();
  return data;
}

export async function upsertSignature(
  sig: Partial<EmailSignature> & { organization_id: string }
): Promise<EmailSignature> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from('email_signatures').upsert(sig as unknown as never, { onConflict: 'id' }).select().single();
  if (error) throw error;
  return data;
}

export async function deleteSignature(id: string) {
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.from('email_signatures').delete().eq('id', id);
  if (error) throw error;
}

export async function setDefaultSignature(id: string, orgId: string) {
  const supabase = await createSupabaseServerClient();
  await supabase.from('email_signatures')
    .update({ is_default: false }).eq('organization_id', orgId).eq('is_default', true);
  const { error } = await supabase.from('email_signatures')
    .update({ is_default: true }).eq('id', id);
  if (error) throw error;
}
```

===== C:\dev\mbg-project\src\components\settings\email-signature-client.tsx =====
```ts
'use client';
import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Trash2, Plus, Star } from 'lucide-react';
import {
  upsertSignature, deleteSignature, setDefaultSignature,
  type EmailSignature,
} from '@/lib/queries/email-signatures';
import { toast } from 'sonner';

interface Props { orgId: string; initialSignatures: EmailSignature[] }

const BLANK = {
  name: '새 서명',
  html: '<p>감사합니다.<br/><strong>홍길동</strong><br/>MBG Inc.</p>',
  plain_text: '감사합니다.\n홍길동\nMBG Inc.',
  is_default: false,
};

export function EmailSignatureClient({ orgId, initialSignatures }: Props) {
  const [sigs, setSigs] = useState<EmailSignature[]>(initialSignatures);
  const [editing, setEditing] = useState<string | null>(initialSignatures[0]?.id ?? null);
  const [saving, setSaving] = useState(false);
  const cur = sigs.find((s) => s.id === editing);

  function upd(field: keyof EmailSignature, val: string | boolean) {
    setSigs((prev) => prev.map((s) => s.id === editing ? { ...s, [field]: val } : s));
  }

  async function save() {
    if (!cur) return;
    setSaving(true);
    try { await upsertSignature({ ...cur, organization_id: orgId }); toast.success('저장되었습니다.'); }
    catch (e) { toast.error('저장 실패: ' + String(e)); }
    finally { setSaving(false); }
  }

  async function add() {
    try {
      const created = await upsertSignature({ ...BLANK, organization_id: orgId } as any);
      setSigs((p) => [...p, created]); setEditing(created.id);
    } catch (e) { toast.error('생성 실패: ' + String(e)); }
  }

  async function del(id: string) {
    if (!confirm('서명을 삭제하시겠습니까?')) return;
    try {
      await deleteSignature(id);
      const rest = sigs.filter((s) => s.id !== id);
      setSigs(rest); setEditing(rest[0]?.id ?? null);
    } catch (e) { toast.error('삭제 실패: ' + String(e)); }
  }

  async function setDefault(id: string) {
    try {
      await setDefaultSignature(id, orgId);
      setSigs((p) => p.map((s) => ({ ...s, is_default: s.id === id })));
      toast.success('기본 서명으로 설정되었습니다.');
    } catch (e) { toast.error('설정 실패: ' + String(e)); }
  }

  const activeClass = 'bg-accent font-medium';
  const inactiveClass = 'hover:bg-muted';

  return (
    <div className="grid grid-cols-[220px_1fr] gap-4 min-h-[400px]">
      <div className="space-y-1 border-r pr-3">
        {sigs.map((s) => (
          <button key={s.id} onClick={() => setEditing(s.id)}
            className={'w-full text-left px-3 py-2 rounded-md text-sm flex items-center justify-between ' + (editing === s.id ? activeClass : inactiveClass)}>
            <span className="truncate">{s.name}</span>
            {s.is_default && <Badge variant="secondary" className="text-[10px] ml-1 px-1">기본</Badge>}
          </button>
        ))}
        <Button variant="ghost" size="sm" className="w-full justify-start text-xs mt-1" onClick={add}>
          <Plus className="h-3.5 w-3.5 mr-1" /> 새 서명 추가
        </Button>
      </div>

      {cur ? (
        <Card className="border-0 shadow-none">
          <CardHeader className="pb-2 flex flex-row items-center justify-between p-0 mb-3">
            <Input value={cur.name} onChange={(e) => upd('name', e.target.value)}
              className="max-w-[180px] h-8 text-sm" />
            <div className="flex items-center gap-1">
              <Button variant="ghost" size="sm" onClick={() => setDefault(cur.id)} disabled={cur.is_default}>
                <Star className={'h-4 w-4 mr-1 ' + (cur.is_default ? 'fill-yellow-400 text-yellow-400' : 'text-muted-foreground')} />
                {cur.is_default ? '기본 서명' : '기본으로'}
              </Button>
              <Button variant="ghost" size="sm" onClick={() => del(cur.id)}>
                <Trash2 className="h-4 w-4 text-destructive" />
              </Button>
            </div>
          </CardHeader>
          <CardContent className="p-0 space-y-3">
            <Tabs defaultValue="html">
              <TabsList className="h-8">
                <TabsTrigger value="html" className="text-xs h-7">HTML</TabsTrigger>
                <TabsTrigger value="preview" className="text-xs h-7">미리보기</TabsTrigger>
                <TabsTrigger value="plain" className="text-xs h-7">텍스트</TabsTrigger>
              </TabsList>
              <TabsContent value="html">
                <Textarea value={cur.html_content} onChange={(e) => upd('html_content', e.target.value)}
                  className="font-mono text-xs min-h-[220px] resize-none" placeholder="<p>서명 HTML...</p>" />
              </TabsContent>
              <TabsContent value="preview">
                <div className="border rounded-md p-4 min-h-[220px] text-sm bg-white"
                  dangerouslySetInnerHTML={{ __html: cur.html_content }} />
              </TabsContent>
              <TabsContent value="plain">
                <Textarea value={(cur as any).plain_text ?? ''} onChange={(e) => upd('plain_text' as any, e.target.value)}
                  className="font-mono text-xs min-h-[220px] resize-none" />
              </TabsContent>
            </Tabs>
            <div className="flex justify-end">
              <Button size="sm" onClick={save} disabled={saving}>{saving ? '저장 중...' : '저장'}</Button>
            </div>
          </CardContent>
        </Card>
      ) : (
        <div className="flex items-center justify-center text-muted-foreground text-sm border rounded-md">
          서명을 선택하거나 새로 만드세요
        </div>
      )}
    </div>
  );
}
```

