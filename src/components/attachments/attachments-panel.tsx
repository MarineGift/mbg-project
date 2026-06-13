// src/components/attachments/attachments-panel.tsx
'use client';

import { useEffect, useRef, useState, useTransition } from 'react';
import {
  addAttachment,
  listAttachments,
  removeAttachment,
} from '@/app/actions/attachments';
import { mimeLabel, parseDriveLink } from '@/lib/attachments/drive';
import type { Attachment, AttachmentEntityType } from '@/types/attachments';

interface AttachmentsPanelProps {
  entityType: AttachmentEntityType;
  entityId: string;
  /** Optional server-fetched initial list; panel self-loads when omitted. */
  initialAttachments?: Attachment[];
  title?: string;
  /** Drive subfolder name under "URM Attachments" (e.g. the deal name). */
  folderLabel?: string;
}

const KIND_BADGE: Record<string, string> = {
  Sheet: 'bg-green-100 text-green-800',
  Doc: 'bg-blue-100 text-blue-800',
  Slides: 'bg-amber-100 text-amber-800',
  Folder: 'bg-slate-200 text-slate-700',
  PDF: 'bg-red-100 text-red-800',
  Image: 'bg-purple-100 text-purple-800',
  Link: 'bg-gray-100 text-gray-700',
  File: 'bg-gray-100 text-gray-700',
};

export default function AttachmentsPanel({
  entityType,
  entityId,
  initialAttachments,
  title = 'Attachments',
  folderLabel,
}: AttachmentsPanelProps) {
  const [items, setItems] = useState<Attachment[]>(initialAttachments ?? []);
  const [loaded, setLoaded] = useState(Boolean(initialAttachments));
  const [url, setUrl] = useState('');
  const [name, setName] = useState('');
  const [note, setNote] = useState('');
  const [formOpen, setFormOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const [isPending, startTransition] = useTransition();
  const [preview, setPreview] = useState<{ src: string; name: string } | null>(null);

  useEffect(() => {
    if (loaded) return;
    let cancelled = false;
    listAttachments(entityType, entityId).then((res) => {
      if (cancelled) return;
      if (res.error) setError(res.error);
      setItems(res.data);
      setLoaded(true);
    });
    return () => {
      cancelled = true;
    };
  }, [entityType, entityId, loaded]);

  const handleUrlChange = (value: string) => {
    setUrl(value);
    if (!name.trim()) {
      const parsed = parseDriveLink(value);
      if (parsed?.isGoogle && parsed.fileId) {
        setName(`${mimeLabel(parsed.mimeGuess)} (${parsed.fileId.slice(0, 8)}...)`);
      }
    }
  };

  const handleAdd = () => {
    setError(null);
    const parsed = parseDriveLink(url);
    if (!parsed) {
      setError('Paste a full http(s) link (Google Drive share link recommended).');
      return;
    }
    startTransition(async () => {
      const res = await addAttachment({
        entityType,
        entityId,
        url,
        fileName: name,
        description: note,
      });
      if (res.error) {
        setError(res.error);
        return;
      }
      if (res.data) setItems((prev) => [res.data as Attachment, ...prev]);
      setUrl('');
      setName('');
      setNote('');
      setFormOpen(false);
    });
  };

  const handleFileSelected = async (
    e: React.ChangeEvent<HTMLInputElement>
  ) => {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file) return;
    setError(null);
    setIsUploading(true);
    try {
      const form = new FormData();
      form.append('file', file);
      form.append('entityType', entityType);
      form.append('entityId', entityId);
      if (folderLabel) form.append('folderLabel', folderLabel);
      const res = await fetch('/api/attachments/upload', {
        method: 'POST',
        body: form,
      });
      const json = (await res.json()) as {
        data?: Attachment;
        error?: string;
      };
      if (!res.ok || !json.data) {
        setError(json.error ?? `Upload failed (${res.status})`);
        return;
      }
      setItems((prev) => [json.data as Attachment, ...prev]);
    } catch {
      setError('Upload failed. Check the network and try again.');
    } finally {
      setIsUploading(false);
    }
  };

  const handleRemove = (id: string) => {
    setError(null);
    startTransition(async () => {
      const res = await removeAttachment(id);
      if (res.error) {
        setError(res.error);
        return;
      }
      setItems((prev) => prev.filter((a) => a.id !== id));
    });
  };

  return (
    <section className="rounded-lg border border-gray-200 bg-white">
      <header className="flex items-center justify-between border-b border-gray-100 px-4 py-2.5">
        <h3 className="text-sm font-semibold text-gray-800">
          {title}
          {loaded && (
            <span className="ml-2 text-xs font-normal text-gray-400">
              {items.length}
            </span>
          )}
        </h3>
        <div className="flex items-center gap-1.5">
          <input
            ref={fileInputRef}
            type="file"
            className="hidden"
            onChange={handleFileSelected}
          />
          <button
            type="button"
            onClick={() => fileInputRef.current?.click()}
            disabled={isUploading}
            className="rounded-md bg-gray-900 px-2.5 py-1 text-xs font-medium text-white hover:bg-gray-700 disabled:opacity-50"
          >
            {isUploading ? 'Uploading...' : 'Upload file'}
          </button>
          <button
            type="button"
            onClick={() => setFormOpen((v) => !v)}
            className="rounded-md border border-gray-300 px-2.5 py-1 text-xs font-medium text-gray-700 hover:bg-gray-50"
          >
            {formOpen ? 'Cancel' : '+ Drive link'}
          </button>
        </div>
      </header>

      {formOpen && (
        <div className="space-y-2 border-b border-gray-100 bg-gray-50 px-4 py-3">
          <input
            type="url"
            value={url}
            onChange={(e) => handleUrlChange(e.target.value)}
            placeholder="https://drive.google.com/file/d/... or docs.google.com link"
            className="w-full rounded-md border border-gray-300 px-2.5 py-1.5 text-sm"
          />
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="File name (e.g. Kickstarter budget sheet)"
            className="w-full rounded-md border border-gray-300 px-2.5 py-1.5 text-sm"
          />
          <input
            type="text"
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="Note (optional)"
            className="w-full rounded-md border border-gray-300 px-2.5 py-1.5 text-sm"
          />
          <div className="flex justify-end">
            <button
              type="button"
              onClick={handleAdd}
              disabled={isPending || !url.trim()}
              className="rounded-md bg-gray-900 px-3 py-1.5 text-xs font-medium text-white hover:bg-gray-700 disabled:opacity-50"
            >
              {isPending ? 'Saving...' : 'Attach'}
            </button>
          </div>
        </div>
      )}

      {error && (
        <p className="px-4 py-2 text-xs text-red-600">{error}</p>
      )}

      <ul className="divide-y divide-gray-100">
        {!loaded && (
          <li className="px-4 py-3 text-xs text-gray-400">Loading...</li>
        )}
        {loaded && items.length === 0 && (
          <li className="px-4 py-3 text-xs text-gray-400">
            No attachments yet. Paste a Google Drive share link.
          </li>
        )}
        {items.map((a) => {
          const label = mimeLabel(a.mime_type);
          return (
            <li key={a.id} className="flex items-center gap-3 px-4 py-2.5">
              <span
                className={`shrink-0 rounded px-1.5 py-0.5 text-[10px] font-semibold ${
                  KIND_BADGE[label] ?? KIND_BADGE.File
                }`}
              >
                {label}
              </span>
              <div className="min-w-0 flex-1">
                {a.drive_file_id ? (
                  <button
                    type="button"
                    onClick={() =>
                      setPreview({
                        src: `https://drive.google.com/file/d/${a.drive_file_id}/preview`,
                        name: a.file_name,
                      })
                    }
                    title="Click to preview in URM"
                    className="block w-full truncate text-left text-sm font-medium text-blue-700 hover:underline"
                  >
                    {a.file_name}
                  </button>
                ) : (
                  <a
                    href={a.storage_path}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="block truncate text-sm font-medium text-blue-700 hover:underline"
                  >
                    {a.file_name}
                  </a>
                )}
                {a.description && (
                  <p className="truncate text-xs text-gray-500">
                    {a.description}
                  </p>
                )}
              </div>
              <span className="shrink-0 text-[11px] text-gray-400">
                {new Date(a.uploaded_at).toLocaleDateString()}
              </span>
              {a.drive_file_id && a.storage_path && (
                <a
                  href={a.storage_path}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="shrink-0 rounded px-1.5 py-0.5 text-xs text-gray-500 hover:bg-gray-100 hover:text-gray-800"
                >
                  Open
                </a>
              )}
              {a.drive_file_id && (
                <a
                  href={`/api/attachments/${a.id}/download`}
                  className="shrink-0 rounded px-1.5 py-0.5 text-xs text-gray-500 hover:bg-gray-100 hover:text-gray-800"
                >
                  Download
                </a>
              )}
              <button
                type="button"
                onClick={() => handleRemove(a.id)}
                disabled={isPending}
                className="shrink-0 rounded px-1.5 py-0.5 text-xs text-gray-400 hover:bg-red-50 hover:text-red-600 disabled:opacity-50"
                aria-label="Remove attachment"
              >
                Remove
              </button>
            </li>
          );
        })}
      </ul>

      {preview && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
          onClick={() => setPreview(null)}
        >
          <div
            className="flex h-[85vh] w-full max-w-4xl flex-col overflow-hidden rounded-lg bg-white shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between border-b border-gray-100 px-4 py-2.5">
              <span className="truncate text-sm font-semibold text-gray-800">
                {preview.name}
              </span>
              <button
                type="button"
                onClick={() => setPreview(null)}
                className="rounded px-2 py-0.5 text-sm text-gray-500 hover:bg-gray-100 hover:text-gray-800"
                aria-label="Close preview"
              >
                Close
              </button>
            </div>
            <iframe
              src={preview.src}
              title={preview.name}
              className="h-full w-full flex-1 border-0"
            />
          </div>
        </div>
      )}
    </section>
  );
}
