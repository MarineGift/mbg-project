// src/components/email/compose-email-dialog.tsx
// Compose Email Dialog with 3 modes (tabs):
//   - Direct:    blank compose form
//   - Template:  select template + merge-field substitution
//   - AI Draft:  AI-generated reply (uses generateAIReply, reply mode only)
// All UI English, ASCII-clean.
"use client";

import { useState, useRef, useMemo, useEffect } from "react";
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
  FileText,
  PenLine,
  Info,
} from "lucide-react";
import {
  sendEmail,
  generateAIReply,
  type ComposePayload,
  type ComposeMode,
} from "@/lib/actions/email-compose";
import { sendOutboundManual } from "@/lib/actions/communications";
import {
  listOpenDealsForParty,
  type OpenDealOption,
} from "@/lib/actions/compose-recipients";
import { uploadAttachment, type UploadedAttachment } from "@/lib/actions/upload-attachment";
import { renderMergeFields } from "@/lib/utils/merge-fields";
import { toast } from "sonner";
import type { SendingAddressKind } from '@/types/email';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';

// Template shape (matches src/types/phase22a.ts > TemplateForCompose)
interface TemplateLite {
  id: string;
  name: string;
  category: string | null;
  subject: string | null;
  body_plain: string | null;
  body_html: string | null;
  module: string | null;
}

// Tabs
type TabId = "direct" | "template" | "ai";

// D6-7c-2: From kind selector options (same labels as compose-form.tsx)
// Display labels are user-facing; actual email resolved server-side from env.MAIL_<KIND>_*.
const SENDER_OPTIONS: Array<{ kind: SendingAddressKind; label: string }> = [
  { kind: 'shared',   label: 'Marinebio Group <contact@marinebiogroup.com>' },
  { kind: 'role',     label: 'CEO <ceo@marinebiogroup.com>' },
  { kind: 'personal', label: 'YunYoung Heo <yunyoung.heo@marinebiogroup.com>' },
];

interface ComposeEmailDialogProps {
  open: boolean;
  onOpenChange?: (open: boolean) => void;
  onClose?: () => void;
  /** Called after an email is actually sent (not on cancel/close). Use it to
   *  refresh the surrounding view so the new activity appears immediately. */
  onSent?: () => void;

  partyId?: string | null;
  mode?: ComposeMode;

  /** preselect a deal for engagement logging (optional) */
  dealId?: string | null;

  contactId?: string | null;
  contactName?: string | null;

  defaultTo?: string;
  recipientEmail?: string;
  defaultSubject?: string;
  defaultBody?: string;
  templateId?: string;

  replyToMessageId?: string;
  threadId?: string;
  originalCommunicationId?: string;
  replyToCommunicationId?: string;

  templates?: unknown[];
  orgId?: string;
  /** Initial tab to show when dialog opens (default: "direct") */
  initialTab?: "direct" | "template" | "ai";
}

interface AttachmentItem {
  file: File;
  storagePath: string | null;
  uploading: boolean;
  error?: string;
}

export function ComposeEmailDialog(props: ComposeEmailDialogProps) {
  const handleOpenChange = (next: boolean) => {
    props.onOpenChange?.(next);
    if (!next) props.onClose?.();
  };

  const effectiveMode: ComposeMode = props.mode ?? "new";
  const effectiveTo = props.defaultTo ?? props.recipientEmail ?? "";
  const effectiveOriginalCommunicationId =
    props.originalCommunicationId ?? props.replyToCommunicationId;
  const isReplyMode = effectiveMode === "reply" && !!effectiveOriginalCommunicationId;

  // Cast templates prop to typed array
  const templates = useMemo<TemplateLite[]>(
    () => (Array.isArray(props.templates) ? (props.templates as TemplateLite[]) : []),
    [props.templates],
  );

  // browser supabase client removed; uploads now go through the uploadAttachment server action

  // ?? Common form state ???????????????????????????????????
  const [activeTab, setActiveTab] = useState<TabId>(props.initialTab ?? "direct");
  const [to, setTo] = useState(effectiveTo);
  const [subject, setSubject] = useState(props.defaultSubject ?? "");
  const [body, setBody] = useState(props.defaultBody ?? "");
  const [useSignature, setUseSignature] = useState(true);
  const [fromKind, setFromKind] = useState<SendingAddressKind>('shared');
  const [attachments, setAttachments] = useState<AttachmentItem[]>([]);
  const [sending, setSending] = useState(false);

  // ?? Deal linkage (engagement auto-log) ??????????????????
  const NO_DEAL = "__none__";
  const [dealId, setDealId] = useState<string>(props.dealId ?? NO_DEAL);
  const [dealOptions, setDealOptions] = useState<OpenDealOption[]>([]);
  useEffect(() => {
    let cancelled = false;
    if (!props.open || !props.partyId) {
      setDealOptions([]);
      return;
    }
    // fresh open: reset to the preset (or none) before loading options
    setDealId(props.dealId ?? NO_DEAL);
    listOpenDealsForParty(props.partyId).then((res) => {
      if (cancelled || !res.ok) return;
      setDealOptions(res.deals);
      // auto-select when exactly one open deal and nothing preset
      setDealId((prev) =>
        prev !== NO_DEAL ? prev : res.deals.length === 1 ? (res.deals[0]?.dealId ?? NO_DEAL) : NO_DEAL,
      );
    });
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.open, props.partyId]);

  // ?? Template tab state ??????????????????????????????????
  const [selectedTemplateId, setSelectedTemplateId] = useState<string>(
    props.templateId ?? "",
  );

  // ?? AI tab state ????????????????????????????????????????
  const [aiTone, setAiTone] = useState<"professional" | "friendly" | "concise">(
    "professional",
  );
  const [generatingAI, setGeneratingAI] = useState(false);

  const fileInputRef = useRef<HTMLInputElement>(null);

  // ?? Template select handler ?????????????????????????????
  function handleTemplateSelect(templateId: string) {
    setSelectedTemplateId(templateId);
    if (!templateId) return;
    const t = templates.find((x) => x.id === templateId);
    if (!t) return;

    // Build merge-field context (best-effort with what we know on the client)
    const firstName =
      (props.contactName ?? "").trim().split(/\s+/)[0] ?? "";
    const data: Record<string, string> = {
      "contact.name": props.contactName ?? "",
      "contact.firstName": firstName,
      "contact.given_name": firstName,
    };

    setSubject(renderMergeFields(t.subject ?? "", data));
    setBody(renderMergeFields(t.body_plain ?? "", data));
    toast.success(`Template applied: ${t.name}`);
  }

  // ?? AI generate (reply mode only) ???????????????????????
  async function handleGenerateAI() {
    if (!isReplyMode || !effectiveOriginalCommunicationId) {
      toast.error("AI generation requires replying to an existing message.");
      return;
    }
    setGeneratingAI(true);
    try {
      const result = await generateAIReply({
        communicationId: effectiveOriginalCommunicationId,
        partyId: props.partyId ?? "",
        contactId: props.contactId,
        tone: aiTone,
      });
      if (result.success && result.draft) {
        setBody(result.draft);
        toast.success("AI draft generated.");
      } else {
        toast.error(result.error ?? "AI generation failed.");
      }
    } finally {
      setGeneratingAI(false);
    }
  }

  // ?? Attachments ?????????????????????????????????????????
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
      // Route through the uploadAttachment server action: it enforces the org-id
      // path prefix (storage RLS isolation) and whitelist-sanitizes the object key
      // via toStorageKeySegment, so spaces/brackets/Hangul cannot trigger "Invalid key".
      try {
        const fd = new FormData();
        fd.append("file", item.file);
        const uploaded = await uploadAttachment(fd);
        setAttachments((prev) =>
          prev.map((a) =>
            a.file === item.file
              ? { ...a, uploading: false, storagePath: uploaded.path }
              : a,
          ),
        );
      } catch (err) {
        const msg = err instanceof Error ? err.message : "upload failed";
        setAttachments((prev) =>
          prev.map((a) =>
            a.file === item.file
              ? { ...a, uploading: false, storagePath: null, error: msg }
              : a,
          ),
        );
        toast.error(`Upload failed: ${item.file.name}`);
      }
    }

    e.target.value = "";
  }

  function removeAttachment(index: number) {
    setAttachments((prev) => prev.filter((_, i) => i !== index));
  }

  // ?? Send ????????????????????????????????????????????????
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

    if (attachments.some((a) => a.uploading)) {
      toast.error("Please wait for file uploads to finish.");
      return;
    }

    const uploadedAttachments = attachments.filter((a) => a.storagePath);
    const attachmentPaths = uploadedAttachments.map((a) => a.storagePath!);
    const attachmentsMeta: UploadedAttachment[] = uploadedAttachments.map((a) => ({
      path: a.storagePath!,
      filename: a.file.name,
      size: a.file.size,
      mimeType: a.file.type || "application/octet-stream",
    }));

    // Determine final ComposeMode for the action
    // (template tab => "template" payload, ai tab + reply => "reply", direct + reply => "reply", else "new")
    const finalMode: ComposeMode =
      activeTab === "template"
        ? "template"
        : effectiveMode === "reply"
          ? "reply"
          : "new";

    setSending(true);
    try {
      let ok: boolean;
      let errMsg: string | undefined;

      if (props.partyId) {
        // Party-linked: full path (merge fields + template + signature).
        const payload: ComposePayload = {
          mode: finalMode,
          partyId: props.partyId,
          contactId: props.contactId ?? null,
          dealId: dealId !== NO_DEAL ? dealId : null,
          to: to.trim(),
          subject: subject.trim(),
          body,
          templateId:
            activeTab === "template" && selectedTemplateId
              ? selectedTemplateId
              : props.templateId,
          replyToMessageId: props.replyToMessageId,
          threadId: props.threadId,
          attachmentPaths,
          attachments: attachmentsMeta,
          useSignature,
          fromKind,
        };
        const result = await sendEmail(payload);
        ok = result.success;
        errMsg = result.error;
      } else {
        // No registered party (e.g. reply to an unknown sender). Use the proven
        // manual outbound path, which supports a null party. The 3-mode UI still
        // applies: Template/AI fill the body client-side; this just sends it.
        const result = await sendOutboundManual({
          fromKind,
          to: to.trim(),
          cc: undefined,
          subject: subject.trim(),
          bodyPlain: body,
          partyId: null,
          contactId: props.contactId ?? null,
          dealId: dealId !== NO_DEAL ? dealId : null,
          inReplyTo: props.replyToMessageId ?? null,
          threadId: props.threadId ?? null,
          attachments: attachmentsMeta,
        });
        if (result.ok) {
          ok = true;
          errMsg = undefined;
        } else {
          ok = false;
          errMsg = result.errorMessage ?? undefined;
        }
      }

      if (ok) {
        toast.success("Email sent.");
        props.onSent?.();
        handleOpenChange(false);
      } else {
        toast.error(errMsg ?? "Send failed.");
      }
    } finally {
      setSending(false);
    }
  }

  // ?? Header label ????????????????????????????????????????
  const modeLabel =
    effectiveMode === "reply"
      ? "Reply"
      : effectiveMode === "template"
        ? "Send from Template"
        : "New Email";

  // Group templates by category for the dropdown
  const templatesByCategory = useMemo(() => {
    const out: Record<string, TemplateLite[]> = {};
    for (const t of templates) {
      const cat = t.category ?? "General";
      (out[cat] ??= []).push(t);
    }
    return out;
  }, [templates]);

  // ?? Tab button helper ???????????????????????????????????
  const tabBtnClass = (id: TabId) =>
    `flex-1 inline-flex items-center justify-center gap-1.5 px-3 py-2 text-sm border-b-2 transition-colors ${
      activeTab === id
        ? "border-primary text-primary font-medium"
        : "border-transparent text-muted-foreground hover:text-foreground"
    }`;

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

        {/* D6-7c-2: From kind selector (shared across all tabs) */}
        <div className="space-y-1">
          <Label htmlFor="fromKind">From</Label>
          <Select value={fromKind} onValueChange={(v) => setFromKind(v as SendingAddressKind)}>
            <SelectTrigger id="fromKind">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {SENDER_OPTIONS.map((opt) => (
                <SelectItem key={opt.kind} value={opt.kind}>
                  {opt.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {/* Deal linkage: logs this email on the deal's Activity timeline */}
        {props.partyId && dealOptions.length > 0 && (
          <div className="space-y-1">
            <Label htmlFor="dealLink">Link to deal</Label>
            <Select value={dealId} onValueChange={setDealId}>
              <SelectTrigger id="dealLink">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value={NO_DEAL}>No deal (log on company only)</SelectItem>
                {dealOptions.map((d) => (
                  <SelectItem key={d.dealId} value={d.dealId}>
                    {d.dealName}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        )}

        {/* Tabs */}
        <div className="flex border-b -mx-6 px-6">
          <button
            type="button"
            className={tabBtnClass("direct")}
            onClick={() => setActiveTab("direct")}
          >
            <PenLine className="h-3.5 w-3.5" />
            Direct
          </button>
          <button
            type="button"
            className={tabBtnClass("template")}
            onClick={() => setActiveTab("template")}
          >
            <FileText className="h-3.5 w-3.5" />
            Template
          </button>
          <button
            type="button"
            className={tabBtnClass("ai")}
            onClick={() => setActiveTab("ai")}
          >
            <Sparkles className="h-3.5 w-3.5" />
            AI Draft
          </button>
        </div>

        <div className="flex-1 overflow-y-auto space-y-4 pr-1 pt-2">
          {/* Tab-specific top section */}
          {activeTab === "template" && (
            <div className="space-y-1">
              <Label htmlFor="template-select">Choose template</Label>
              {templates.length === 0 ? (
                <div className="rounded border bg-muted/30 px-3 py-2 text-xs text-muted-foreground flex items-center gap-1.5">
                  <Info className="h-3.5 w-3.5" />
                  No templates available. Create templates in Settings &gt; Email Templates.
                </div>
              ) : (
                <select
                  id="template-select"
                  value={selectedTemplateId}
                  onChange={(e) => handleTemplateSelect(e.target.value)}
                  className="w-full h-9 px-3 text-sm rounded-md border border-input bg-background focus:outline-none focus:ring-1 focus:ring-ring"
                >
                  <option value="">-- Select a template --</option>
                  {Object.entries(templatesByCategory).map(([cat, list]) => (
                    <optgroup key={cat} label={cat}>
                      {list.map((t) => (
                        <option key={t.id} value={t.id}>
                          {t.name}
                        </option>
                      ))}
                    </optgroup>
                  ))}
                </select>
              )}
              <p className="text-xs text-muted-foreground">
                Tokens like <code>{"{{contact.firstName}}"}</code> are replaced automatically when you pick a template.
              </p>
            </div>
          )}

          {activeTab === "ai" && (
            <div className="space-y-2 rounded-md border bg-violet-50/50 p-3">
              {isReplyMode ? (
                <>
                  <div className="flex items-center justify-between gap-2">
                    <Label htmlFor="ai-tone" className="text-xs">
                      Tone
                    </Label>
                    <select
                      id="ai-tone"
                      value={aiTone}
                      onChange={(e) =>
                        setAiTone(
                          e.target.value as "professional" | "friendly" | "concise",
                        )
                      }
                      className="h-7 px-2 text-xs rounded border border-input bg-background"
                    >
                      <option value="professional">Professional</option>
                      <option value="friendly">Friendly</option>
                      <option value="concise">Concise</option>
                    </select>
                  </div>
                  <Button
                    type="button"
                    size="sm"
                    onClick={handleGenerateAI}
                    disabled={generatingAI}
                    className="w-full bg-violet-600 hover:bg-violet-700 text-white"
                  >
                    {generatingAI ? (
                      <>
                        <Loader2 className="h-3.5 w-3.5 mr-1.5 animate-spin" />
                        Generating...
                      </>
                    ) : (
                      <>
                        <Sparkles className="h-3.5 w-3.5 mr-1.5" />
                        Generate AI reply
                      </>
                    )}
                  </Button>
                </>
              ) : (
                <div className="text-xs text-muted-foreground flex items-start gap-1.5">
                  <Info className="h-3.5 w-3.5 mt-0.5 shrink-0" />
                  <span>
                    AI Draft is available when replying to an inbound message.
                    Open the inbox or party timeline and click <strong>Reply</strong> on an existing email.
                  </span>
                </div>
              )}
            </div>
          )}

          {/* Common: To */}
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

          {/* Common: Subject */}
          <div className="space-y-1">
            <Label htmlFor="subject">Subject</Label>
            <Input
              id="subject"
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
              placeholder="Email subject"
            />
          </div>

          {/* Common: Body */}
          <div className="space-y-1">
            <Label htmlFor="body">Body</Label>
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