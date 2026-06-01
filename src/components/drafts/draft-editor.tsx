'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { Save, Loader2, FileDiff, Pencil } from 'lucide-react';
import { toast } from 'sonner';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { DiffViewer } from './diff-viewer';
import { saveDraftEdits } from '@/lib/actions/drafts';
import type { DraftDetail } from '@/types/draft-detail';
import { cn } from '@/lib/utils';

interface Props {
  draft: DraftDetail;
  readOnly?: boolean;
}

type ViewMode = 'edit' | 'diff';

export function DraftEditor({ draft, readOnly = false }: Props) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [mode, setMode] = useState<ViewMode>('edit');

  // initial value: the edited version if present, otherwise the AI original
  const initialSubject = draft.finalSubject ?? draft.subject ?? '';
  const initialBody = draft.finalBodyPlain ?? draft.bodyPlain;

  const [subject, setSubject] = useState(initialSubject);
  const [body, setBody] = useState(initialBody);

  const isDirty =
    subject !== initialSubject || body !== initialBody;

  const onSave = () => {
    if (!isDirty || readOnly) return;
    startTransition(async () => {
      const result = await saveDraftEdits({
        draftId: draft.id,
        subject: subject || null,
        bodyPlain: body,
      });
      if (result.ok) {
        toast.success('Draft saved');
        router.refresh();
      } else {
        toast.error(result.errorMessage ?? 'Failed to save draft');
      }
    });
  };

  return (
    <Card>
      <CardHeader className="pb-3 flex flex-row items-center justify-between">
        <CardTitle className="text-sm">Reply</CardTitle>
        <div className="flex items-center gap-1">
          <Button
            variant={mode === 'edit' ? 'secondary' : 'ghost'}
            size="sm"
            onClick={() => setMode('edit')}
          >
            <Pencil className="h-3.5 w-3.5" />
            Edit
          </Button>
          <Button
            variant={mode === 'diff' ? 'secondary' : 'ghost'}
            size="sm"
            onClick={() => setMode('diff')}
          >
            <FileDiff className="h-3.5 w-3.5" />
            Diff
          </Button>
        </div>
      </CardHeader>

      <CardContent className="space-y-4">
        {mode === 'edit' ? (
          <>
            <div className="space-y-2">
              <Label htmlFor="draft-subject" className="text-xs">
                Subject
              </Label>
              <Input
                id="draft-subject"
                value={subject}
                onChange={(e) => setSubject(e.target.value)}
                disabled={readOnly || isPending}
                placeholder="(no subject)"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="draft-body" className="text-xs">
                Body
              </Label>
              <Textarea
                id="draft-body"
                value={body}
                onChange={(e) => setBody(e.target.value)}
                disabled={readOnly || isPending}
                rows={14}
                className="font-mono"
              />
              <p className="text-xs text-muted-foreground tabular-nums">
                {body.length} chars
                {draft.editDistance != null && (
                  <span className="ml-2">
                    · saved edit distance: {draft.editDistance}
                  </span>
                )}
              </p>
            </div>
          </>
        ) : (
          <DiffViewer original={draft.bodyPlain} edited={body} />
        )}

        <div className="flex items-center justify-between">
          <p
            className={cn(
              'text-xs',
              isDirty
                ? 'text-orange-600 dark:text-orange-400'
                : 'text-muted-foreground',
            )}
          >
            {isDirty ? 'Unsaved changes' : 'No unsaved changes'}
          </p>
          {!readOnly && (
            <Button
              onClick={onSave}
              disabled={!isDirty || isPending}
              size="sm"
            >
              {isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Save className="h-4 w-4" />
              )}
              Save Draft
            </Button>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
