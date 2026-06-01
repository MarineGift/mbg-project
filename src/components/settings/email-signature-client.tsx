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
  name: 'New signature',
  html_content: '<p>Best regards,<br/><strong>Your Name</strong><br/>MBG Inc.</p>',
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
    try { await upsertSignature({ id: cur.id, name: cur.name, html_content: cur.html_content, is_default: cur.is_default, organization_id: orgId } as any); toast.success('Saved.'); }
    catch (e) { toast.error('Save failed: ' + String(e)); }
    finally { setSaving(false); }
  }

  async function add() {
    try {
      const created = await upsertSignature({ ...BLANK, organization_id: orgId } as any);
      setSigs((p) => [...p, created]); setEditing(created.id);
    } catch (e) { toast.error('Create failed: ' + String(e)); }
  }

  async function del(id: string) {
    if (!confirm('Delete this signature?')) return;
    try {
      await deleteSignature(id);
      const rest = sigs.filter((s) => s.id !== id);
      setSigs(rest); setEditing(rest[0]?.id ?? null);
    } catch (e) { toast.error('Delete failed: ' + String(e)); }
  }

  async function setDefault(id: string) {
    try {
      await setDefaultSignature(id, orgId);
      setSigs((p) => p.map((s) => ({ ...s, is_default: s.id === id })));
      toast.success('Set as the default signature.');
    } catch (e) { toast.error('Update failed: ' + String(e)); }
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
            {s.is_default && <Badge variant="secondary" className="text-[10px] ml-1 px-1">Default</Badge>}
          </button>
        ))}
        <Button variant="ghost" size="sm" className="w-full justify-start text-xs mt-1" onClick={add}>
          <Plus className="h-3.5 w-3.5 mr-1" /> Add signature
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
                {cur.is_default ? 'Default signature' : 'Set default'}
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
                <TabsTrigger value="preview" className="text-xs h-7">Preview</TabsTrigger>
                <TabsTrigger value="plain" className="text-xs h-7">Plain text</TabsTrigger>
              </TabsList>
              <TabsContent value="html">
                <Textarea value={cur.html_content} onChange={(e) => upd('html_content', e.target.value)}
                  className="font-mono text-xs min-h-[220px] resize-none" placeholder="<p>Signature HTML...</p>" />
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
              <Button size="sm" onClick={save} disabled={saving}>{saving ? 'Saving...' : 'Save'}</Button>
            </div>
          </CardContent>
        </Card>
      ) : (
        <div className="flex items-center justify-center text-muted-foreground text-sm border rounded-md">
          Select a signature or create a new one
        </div>
      )}
    </div>
  );
}