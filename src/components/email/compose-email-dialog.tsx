// src/components/email/compose-email-dialog.tsx
// Compose Email Dialog
// - 3 modes: new / reply / template
// - Backward-compatible Props (accepts both old and new naming)
// - Attachment upload + signature toggle + AI reply generation
"use client";

import { useState, useRef } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import {
  Loader2,
  Send,
  Paperclip,
  X,
  Sparkles,
  Signature,
} from "lucide-react";
import {
  sendEmail,
  generateAIReply,
  type ComposePayload,
  type ComposeMode,
} from "@/lib/actions/email-compose";
import { createSupabaseBrowserClient } from "@/lib/supabase/client";
import { toast } from "sonner";

// ?????????????????????????????????????????????
// Props (accept both old and new naming for backward compatibility)
// ?????????????????????????????????????????????
interface ComposeEmailDialogProps {
  open: boolean;
  // Caller may use either onOpenChange (preferred) or onClose
  onOpenChange?: (open: boolean) => void;
  onClose?: () => void;

  // Required
  partyId: string;
  // Optional - defaults to "new" if not provided
  mode?: ComposeMode;

  // Optional contact info
  contactId?: string | null;
  contactName?: string | null;

  // Initial values: caller may use either defaultTo or recipientEmail
  defaultTo?: string;
  recipientEmail?: string;
  defaultSubject?: string;
  defaultBody?: string;
  templateId?: string;

  // Reply mode: caller may use either originalCommunicationId or replyToCommunicationId
  replyToMessageId?: string;
  threadId?: string;
  originalCommunicationId?: string;
  replyToCommunicationId?: string;

  // Reserved for future Template mode (UI to pick a template inside the dialog)
  templates?: unknown[];
  // Reserved for future signature loading
  orgId?: string;
}

interface AttachmentItem {
  file: File;
  storagePath: string | null;
  uploading: boolean;
  error?: string;
}

export function ComposeEmailDialog(props: ComposeEmailDialogProps) {
  // Normalize props
  const handleOpenChange = (next: boolean) => {
    props.onOpenChange?.(next);
    if (!next) props.onClose?.();
  };

  const effectiveMode: ComposeMode = props.mode ?? "new";
  const effectiveTo = props.defaultTo ?? props.recipientEmail ?? "";
  const effectiveOriginalCommunicationId =
    props.originalCommunicationId ?? props.replyToCommunicationId;

  const supabase = createSupabaseBrowserClient();

  const [to, setTo] = useState(effectiveTo);
  const [subject, setSubject] = useState(props.defaultSubject ?? "");
  const [body, setBody] = useState(props.defaultBody ?? "");
  const [useSignature, setUseSignature] = useState(true);
  const [attachments, setAttachments] = useState<AttachmentItem[]>([]);
  const [sending, setSending] = useState(false);
  const [generatingAI, setGeneratingAI] = useState(false);

  const fileInputRef = useRef<HTMLInputElement>(null);

  // ?? File select -> upload to Supabase Storage
  async function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? []);
    if (!files.length) return;

    const newItems: AttachmentItem[] = files.map((f) => ({
      file: f,
      storagePath: null,
      uploading: true,
    }));
    setAttachments((prev) => [...prev, ...newItems]);

    for (const item of newItems) {
      const path = `${props.partyId}/${Date.now()}-${item.file.name}`;
      const { error } = await supabase.storage
        .from("email-attachments")
        .upload(path, item.file, { upsert: false });

      setAttachments((prev) =>
        prev.map((a) =>
          a.file === item.file
            ? {
                ...a,
                uploading: false,
                storagePath: error ? null : path,
                error: error?.message,
              }
            : a,
        ),
      );

      if (error) toast.error(`Upload failed: ${item.file.name}`);
    }

    // Reset input so the same file can be picked again
    e.target.value = "";
  }

  function removeAttachment(index: number) {
    setAttachments((prev) => prev.filter((_, i) => i !== index));
  }

  // ?? AI reply generation
  async function handleGenerateAI() {
    if (!effectiveOriginalCommunicationId) {
      toast.error("Original message ID is missing.");
      return;
    }
    setGeneratingAI(true);
    try {
      const result = await generateAIReply({
        communicationId: effectiveOriginalCommunicationId,
        partyId: props.partyId,
        contactId: props.contactId,
        tone: "professional",
      });
      if (result.success && result.draft) {
        setBody(result.draft);
        toast.success("AI reply draft generated.");
      } else {
        toast.error(result.error ?? "AI generation failed.");
      }
    } finally {
      setGeneratingAI(false);
    }
  }

  // ?? Send
  async function handleSend() {
    if (!to.trim()) {
      toast.error("Please enter a recipient.");
      return;
    }
    if (!subject.trim()) {
      toast.error("Please enter a subject.");
      return;
    }
    if (!body.trim()) {
      toast.error("Please enter the body.");
      return;
    }

    const stillUploading = attachments.some((a) => a.uploading);
    if (stillUploading) {
      toast.error("Please wait for file uploads to finish.");
      return;
    }

    const attachmentPaths = attachments
      .filter((a) => a.storagePath)
      .map((a) => a.storagePath!);

    setSending(true);
    try {
      const payload: ComposePayload = {
        mode: effectiveMode,
        partyId: props.partyId,
        contactId: props.contactId ?? null,
        to: to.trim(),
        subject: subject.trim(),
        body,
        templateId: props.templateId,
        replyToMessageId: props.replyToMessageId,
        threadId: props.threadId,
        attachmentPaths,
        useSignature,
      };

      const result = await sendEmail(payload);

      if (result.success) {
        toast.success("Email sent.");
        handleOpenChange(false);
      } else {
        toast.error(result.error ?? "Send failed.");
      }
    } finally {
      setSending(false);
    }
  }

  // ?? Mode label (English)
  const modeLabel =
    effectiveMode === "reply"
      ? "Reply"
      : effectiveMode === "template"
        ? "Send from Template"
        : "New Email";

  return (
    <Dialog open={props.open} onOpenChange={handleOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] flex flex-col overflow-hidden">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Send className="h-4 w-4" />
            {modeLabel}
            {props.contactId && (
              <Badge variant="outline" className="text-xs font-normal">
                Contact linked
              </Badge>
            )}
          </DialogTitle>
        </DialogHeader>

        <div className="flex-1 overflow-y-auto space-y-4 pr-1">
          {/* To */}
          <div className="space-y-1">
            <Label htmlFor="to">To</Label>
            <Input
              id="to"
              value={to}
              onChange={(e) => setTo(e.target.value)}
              placeholder="recipient@example.com"
              type="email"
            />
          </div>

          {/* Subject */}
          <div className="space-y-1">
            <Label htmlFor="subject">Subject</Label>
            <Input
              id="subject"
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
              placeholder="Email subject"
            />
          </div>

          {/* Body */}
          <div className="space-y-1">
            <div className="flex items-center justify-between">
              <Label htmlFor="body">Body</Label>
              {effectiveMode === "reply" && effectiveOriginalCommunicationId && (
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
                  Generate AI draft
                </Button>
              )}
            </div>
            <Textarea
              id="body"
              value={body}
              onChange={(e) => setBody(e.target.value)}
              placeholder="Type your email body here..."
              className="min-h-[200px] font-mono text-sm"
            />
          </div>

          {/* Attachments */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label>Attachments</Label>
              <Button
                variant="outline"
                size="sm"
                className="h-7 text-xs"
                onClick={() => fileInputRef.current?.click()}
              >
                <Paperclip className="h-3 w-3 mr-1" />
                Add file
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
                    <span
                      className={`flex-1 truncate ${
                        att.error ? "text-destructive" : ""
                      }`}
                    >
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

          {/* Signature toggle */}
          <div className="flex items-center gap-3 rounded-md border px-3 py-2">
            <Signature className="h-4 w-4 text-muted-foreground" />
            <Label
              htmlFor="sig-toggle"
              className="flex-1 cursor-pointer text-sm"
            >
              Attach signature automatically
            </Label>
            <Switch
              id="sig-toggle"
              checked={useSignature}
              onCheckedChange={setUseSignature}
            />
          </div>
        </div>

        <DialogFooter className="border-t pt-3 mt-2">
          <Button
            variant="outline"
            onClick={() => handleOpenChange(false)}
            disabled={sending}
          >
            Cancel
          </Button>
          <Button onClick={handleSend} disabled={sending}>
            {sending ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Sending...
              </>
            ) : (
              <>
                <Send className="h-4 w-4 mr-2" />
                Send
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}