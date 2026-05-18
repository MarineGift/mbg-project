// src/components/email/compose-email-dialog.tsx
// Phase 22b: contact_id 전달 수정 + 첨부파일 UI + 서명 토글
"use client";

import { useState, useRef } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { Loader2, Send, Paperclip, X, Sparkles, Signature } from "lucide-react";
import { sendEmail, generateAIReply, type ComposePayload, type ComposeMode } from "@/lib/actions/email-compose";
import { createSupabaseBrowserClient } from "@/lib/supabase/client";
import { toast } from "sonner";

// ─────────────────────────────────────────────
// Props
// ─────────────────────────────────────────────
interface ComposeEmailDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;

  // 필수
  partyId: string;
  mode: ComposeMode;

  // Fix: contact_id 명시적 전달
  contactId?: string | null;

  // 초기값
  defaultTo?: string;
  defaultSubject?: string;
  defaultBody?: string;
  templateId?: string;

  // reply 모드
  replyToMessageId?: string;
  threadId?: string;
  originalCommunicationId?: string; // AI reply 생성용
}

// ─────────────────────────────────────────────
// Attachment item
// ─────────────────────────────────────────────
interface AttachmentItem {
  file: File;
  storagePath: string | null; // 업로드 완료 후 채워짐
  uploading: boolean;
  error?: string;
}

// ─────────────────────────────────────────────
// Component
// ─────────────────────────────────────────────
export function ComposeEmailDialog({
  open,
  onOpenChange,
  partyId,
  mode,
  contactId,
  defaultTo = "",
  defaultSubject = "",
  defaultBody = "",
  templateId,
  replyToMessageId,
  threadId,
  originalCommunicationId,
}: ComposeEmailDialogProps) {
  const supabase = createSupabaseBrowserClient();

  const [to, setTo] = useState(defaultTo);
  const [subject, setSubject] = useState(defaultSubject);
  const [body, setBody] = useState(defaultBody);
  const [useSignature, setUseSignature] = useState(true);
  const [attachments, setAttachments] = useState<AttachmentItem[]>([]);
  const [sending, setSending] = useState(false);
  const [generatingAI, setGeneratingAI] = useState(false);

  const fileInputRef = useRef<HTMLInputElement>(null);

  // ── 파일 선택 → Supabase Storage 업로드
  async function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? []);
    if (!files.length) return;

    // 즉시 목록에 추가 (uploading=true)
    const newItems: AttachmentItem[] = files.map((f) => ({
      file: f,
      storagePath: null,
      uploading: true,
    }));
    setAttachments((prev) => [...prev, ...newItems]);

    // 각 파일 업로드
    for (const item of newItems) {
      const path = `${partyId}/${Date.now()}-${item.file.name}`;
      const { error } = await supabase.storage
        .from("email-attachments")
        .upload(path, item.file, { upsert: false });

      setAttachments((prev) =>
        prev.map((a) =>
          a.file === item.file
            ? { ...a, uploading: false, storagePath: error ? null : path, error: error?.message }
            : a
        )
      );

      if (error) toast.error(`업로드 실패: ${item.file.name}`);
    }

    // input 초기화 (같은 파일 재선택 허용)
    e.target.value = "";
  }

  function removeAttachment(index: number) {
    setAttachments((prev) => prev.filter((_, i) => i !== index));
  }

  // ── AI 답장 생성
  async function handleGenerateAI() {
    if (!originalCommunicationId) {
      toast.error("원본 메시지 ID가 없습니다.");
      return;
    }
    setGeneratingAI(true);
    try {
      const result = await generateAIReply({
        communicationId: originalCommunicationId,
        partyId,
        contactId,
        tone: "professional",
      });
      if (result.success && result.draft) {
        setBody(result.draft);
        toast.success("AI 답장 초안이 생성되었습니다.");
      } else {
        toast.error(result.error ?? "AI 생성 실패");
      }
    } finally {
      setGeneratingAI(false);
    }
  }

  // ── 발송
  async function handleSend() {
    if (!to.trim()) { toast.error("수신 주소를 입력하세요."); return; }
    if (!subject.trim()) { toast.error("제목을 입력하세요."); return; }
    if (!body.trim()) { toast.error("본문을 입력하세요."); return; }

    // 업로드 중인 파일이 있으면 대기
    const stillUploading = attachments.some((a) => a.uploading);
    if (stillUploading) { toast.error("파일 업로드가 완료될 때까지 기다려 주세요."); return; }

    const attachmentPaths = attachments
      .filter((a) => a.storagePath)
      .map((a) => a.storagePath!);

    setSending(true);
    try {
      const payload: ComposePayload = {
        mode,
        partyId,
        contactId: contactId ?? null,   // ← Fix: 명시적 전달
        to: to.trim(),
        subject: subject.trim(),
        body,
        templateId,
        replyToMessageId,
        threadId,
        attachmentPaths,
        useSignature,
      };

      const result = await sendEmail(payload);

      if (result.success) {
        toast.success("이메일이 발송되었습니다.");
        onOpenChange(false);
      } else {
        toast.error(result.error ?? "발송 실패");
      }
    } finally {
      setSending(false);
    }
  }

  // ── 모드 레이블
  const modeLabel = mode === "reply" ? "답장" : mode === "template" ? "템플릿 발송" : "새 이메일";

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] flex flex-col overflow-hidden">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Send className="h-4 w-4" />
            {modeLabel}
            {contactId && (
              <Badge variant="outline" className="text-xs font-normal">
                contact 연결됨
              </Badge>
            )}
          </DialogTitle>
        </DialogHeader>

        <div className="flex-1 overflow-y-auto space-y-4 pr-1">
          {/* 수신 */}
          <div className="space-y-1">
            <Label htmlFor="to">수신</Label>
            <Input
              id="to"
              value={to}
              onChange={(e) => setTo(e.target.value)}
              placeholder="recipient@example.com"
              type="email"
            />
          </div>

          {/* 제목 */}
          <div className="space-y-1">
            <Label htmlFor="subject">제목</Label>
            <Input
              id="subject"
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
              placeholder="이메일 제목"
            />
          </div>

          {/* 본문 */}
          <div className="space-y-1">
            <div className="flex items-center justify-between">
              <Label htmlFor="body">본문</Label>
              {mode === "reply" && originalCommunicationId && (
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={handleGenerateAI}
                  disabled={generatingAI}
                  className="h-7 text-xs text-violet-600 hover:text-violet-700"
                >
                  {generatingAI ? (
                    <Loader2 className="h-3 w-3 mr-1 animate-spin" />
                  ) : (
                    <Sparkles className="h-3 w-3 mr-1" />
                  )}
                  AI 초안 생성
                </Button>
              )}
            </div>
            <Textarea
              id="body"
              value={body}
              onChange={(e) => setBody(e.target.value)}
              placeholder="이메일 본문을 입력하세요..."
              className="min-h-[200px] font-mono text-sm"
            />
          </div>

          {/* 첨부파일 */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label>첨부파일</Label>
              <Button
                variant="outline"
                size="sm"
                className="h-7 text-xs"
                onClick={() => fileInputRef.current?.click()}
              >
                <Paperclip className="h-3 w-3 mr-1" />
                파일 추가
              </Button>
            </div>
            <input
              ref={fileInputRef}
              type="file"
              multiple
              className="hidden"
              onChange={handleFileSelect}
            />
            {attachments.length > 0 && (
              <div className="space-y-1">
                {attachments.map((att, i) => (
                  <div
                    key={i}
                    className="flex items-center gap-2 rounded-md border px-3 py-1.5 text-sm"
                  >
                    {att.uploading ? (
                      <Loader2 className="h-3 w-3 animate-spin text-muted-foreground" />
                    ) : att.error ? (
                      <X className="h-3 w-3 text-destructive" />
                    ) : (
                      <Paperclip className="h-3 w-3 text-muted-foreground" />
                    )}
                    <span className={`flex-1 truncate ${att.error ? "text-destructive" : ""}`}>
                      {att.file.name}
                    </span>
                    <span className="text-xs text-muted-foreground">
                      {(att.file.size / 1024).toFixed(0)} KB
                    </span>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-5 w-5"
                      onClick={() => removeAttachment(i)}
                    >
                      <X className="h-3 w-3" />
                    </Button>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* 서명 토글 */}
          <div className="flex items-center gap-3 rounded-md border px-3 py-2">
            <Signature className="h-4 w-4 text-muted-foreground" />
            <Label htmlFor="sig-toggle" className="flex-1 cursor-pointer text-sm">
              서명 자동 첨부
            </Label>
            <Switch
              id="sig-toggle"
              checked={useSignature}
              onCheckedChange={setUseSignature}
            />
          </div>
        </div>

        <DialogFooter className="border-t pt-3 mt-2">
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={sending}>
            취소
          </Button>
          <Button onClick={handleSend} disabled={sending}>
            {sending ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                발송 중...
              </>
            ) : (
              <>
                <Send className="h-4 w-4 mr-2" />
                발송
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
