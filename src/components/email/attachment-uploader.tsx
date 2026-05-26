'use client';
import { useRef, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Paperclip, X, FileText, Loader2 } from 'lucide-react';
import { uploadAttachment, deleteAttachment, type UploadedAttachment } from '@/lib/actions/upload-attachment';
import { toast } from 'sonner';

interface Props {
  attachments: UploadedAttachment[];
  onChange: (attachments: UploadedAttachment[]) => void;
  disabled?: boolean;
}

function fmt(bytes: number) {
  if (bytes < 1024) return bytes + 'B';
  if (bytes < 1048576) return (bytes / 1024).toFixed(1) + 'KB';
  return (bytes / 1048576).toFixed(1) + 'MB';
}

export function AttachmentUploader({ attachments, onChange, disabled }: Props) {
  const ref = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);

  async function handleFiles(files: FileList | null) {
    if (!files || files.length === 0) return;
    setUploading(true);
    const done: UploadedAttachment[] = [];
    for (const f of Array.from(files)) {
      try {
        const fd = new FormData(); fd.append('file', f);
        done.push(await uploadAttachment(fd));
      } catch (e) { toast.error(f.name + ' 업로드 실패'); }
    }
    if (done.length > 0) { onChange([...attachments, ...done]); toast.success(done.length + '개 첨부 완료'); }
    setUploading(false);
    if (ref.current) ref.current.value = '';
  }

  async function remove(att: UploadedAttachment) {
    await deleteAttachment(att.path);
    onChange(attachments.filter((a) => a.path !== att.path));
  }

  return (
    <div className="space-y-1.5">
      {attachments.map((att) => (
        <div key={att.path} className="flex items-center gap-2 px-2.5 py-1.5 rounded-md bg-muted">
          <FileText className="h-3.5 w-3.5 text-muted-foreground flex-shrink-0" />
          <span className="flex-1 truncate text-xs">{att.filename}</span>
          <span className="text-xs text-muted-foreground">{fmt(att.size)}</span>
          <button type="button" onClick={() => remove(att)} disabled={disabled}
            className="text-muted-foreground hover:text-destructive">
            <X className="h-3.5 w-3.5" />
          </button>
        </div>
      ))}
      <input ref={ref} type="file" multiple className="hidden"
        onChange={(e) => handleFiles(e.target.files)} disabled={disabled || uploading} />
      <Button type="button" variant="ghost" size="sm" className="text-xs h-7 px-2"
        disabled={disabled || uploading} onClick={() => ref.current?.click()}>
        {uploading
          ? <Loader2 className="h-3.5 w-3.5 mr-1.5 animate-spin" />
          : <Paperclip className="h-3.5 w-3.5 mr-1.5" />}
        {uploading ? '업로드 중...' : '파일 첨부'}
      </Button>
    </div>
  );
}