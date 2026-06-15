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
  searchRecipientContacts,
  type OpenDealOption,
  type RecipientContact,
} from "@/lib/actions/compose-recipients";
import { uploadAttachment, type UploadedAttachment } from "@/lib/actions/upload-attachment";
import {
  listMailAccountOptions,
  getReplyFromAccountId,
  type MailAccountOption,
} from "@/lib/actions/mail-account-options";
import { addWhitelistEntry } from "@/lib/actions/email-whitelist";
import { renderMergeFields } from "@/lib/utils/merge-fields";
import { getReplyRecipients, type ReplyRecipients } from "@/lib/actions/reply-recipients";
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
  // To-field contact picker (type-ahead over app.contacts). Picking a contact
  // sets both the address and a linked contactId (overrides props.contactId).
  const [selectedContactId, setSelectedContactId] = useState<string | null>(props.contactId ?? null);
  // Full record of the picked contact (type-ahead). Used to re-render merge
  // tokens client-side when a template is already applied.
  const [selectedContact, setSelectedContact] = useState<RecipientContact | null>(null);
  const [toResults, setToResults] = useState<RecipientContact[]>([]);
  const [toOpen, setToOpen] = useState(false);
  const [toSearching, setToSearching] = useState(false);
  const toDebounce = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [subject, setSubject] = useState(props.defaultSubject ?? "");
  // Step 4: CC recipients (comma/semicolon separated). Optional.
  const [cc, setCc] = useState("");
  const [body, setBody] = useState(props.defaultBody ?? "");
  const [useSignature, setUseSignature] = useState(true);
  const [fromKind, setFromKind] = useState<SendingAddressKind>('shared');
  // Step 4: DB mail accounts for the From dropdown (app.inbound_mailboxes).
  // Empty list -> legacy env-kind selector stays as the fallback UI.
  const [mailAccounts, setMailAccounts] = useState<MailAccountOption[]>([]);
  const [fromAccountId, setFromAccountId] = useState<string | null>(null);
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

  // Keep the linked contact in sync with the incoming prop when (re)opening.
  useEffect(() => {
    if (props.open) {
      setSelectedContactId(props.contactId ?? null);
      setSelectedContact(null);
      setRawTemplate(null);
      setCc("");
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.open]);

  // Step 4: load From accounts on open and preselect.
  // reply -> server-side routing rule (matches what the send core would pick);
  // new   -> is_default account.
  useEffect(() => {
    let cancelled = false;
    if (!props.open) return;
    (async () => {
      const res = await listMailAccountOptions();
      if (cancelled || !res.ok || res.accounts.length === 0) return;
      setMailAccounts(res.accounts);
      let preselect: string | null = null;
      if (props.replyToMessageId) {
        preselect = await getReplyFromAccountId(props.replyToMessageId);
      }
      if (cancelled) return;
      const defaultId = res.accounts.find((a) => a.isDefault)?.id ?? res.accounts[0]?.id ?? null;
      setFromAccountId(preselect ?? defaultId);
    })();
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.open, props.replyToMessageId]);

  // To-field type-ahead search (debounced). Typing clears any linked contact
  // until a result is picked, so a hand-typed address won't carry a stale id.
  function onToChange(value: string) {
    setTo(value);
    setSelectedContactId(null);
    setSelectedContact(null);
    if (toDebounce.current) clearTimeout(toDebounce.current);
    // Step 4: with multiple recipients, search only the segment being typed
    // (after the last comma/semicolon).
    const segments = value.split(/[,;]/);
    const q = (segments[segments.length - 1] ?? "").trim();
    if (q.length < 2) {
      setToResults([]);
      setToOpen(false);
      return;
    }
    toDebounce.current = setTimeout(async () => {
      setToSearching(true);
      const res = await searchRecipientContacts(q);
      setToSearching(false);
      if (res.ok) {
        setToResults(res.results);
        setToOpen(res.results.length > 0);
      }
    }, 200);
  }
  function pickToContact(c: RecipientContact) {
    // Step 4: replace the in-progress segment with the picked address,
    // keeping any recipients already entered before it.
    setTo((prev) => {
      const segments = prev.split(/[,;]/).map((s) => s.trim()).filter(Boolean);
      segments.pop(); // drop the partial query segment (may be empty)
      return [...segments, c.email].join(", ");
    });
    setSelectedContactId(c.contactId);
    setSelectedContact(c);
    setToResults([]);
    setToOpen(false);
    // A template is already applied: re-render subject/body from the raw
    // template with the freshly picked contact (overwrites manual edits).
    if (rawTemplate) {
      const data = buildMergeData(c);
      setSubject(renderMergeFields(rawTemplate.subject, data, { keepUnknown: true }));
      setBody(renderMergeFields(rawTemplate.body, data, { keepUnknown: true }));
      toast.success(`Merge fields updated for ${c.fullName}`);
    }
  }

  // ?? Template tab state ??????????????????????????????????
  const [selectedTemplateId, setSelectedTemplateId] = useState<string>(
    props.templateId ?? "",
  );
  // Raw (un-rendered) template kept so tokens can be re-rendered when the
  // recipient contact changes after the template was applied.
  const [rawTemplate, setRawTemplate] = useState<{ subject: string; body: string } | null>(null);

  // Sender constants for client-side preview of {{sender_*}} tokens.
  // Must match SENDER_* in src/lib/email/send-outbound.ts.
  const SENDER_MERGE: Record<string, string> = {
    sender_name: "YunYoung Heo",
    "sender.name": "YunYoung Heo",
    "my.name": "YunYoung Heo",
    sender_title: "Founder & CEO",
    "sender.title": "Founder & CEO",
    sender_company: "MarineBio Group",
    "sender.company": "MarineBio Group",
  };

  // Build the client-side merge map. Covers BOTH conventions:
  //   dot notation : {{contact.firstName}}, {{contact.given_name}}, {{party.name}}
  //   snake_case   : {{contact_first_name}}, {{company_name}}, {{fund_name}} (2026-06 set)
  // Only keys with real values are included; missing keys stay as visible
  // tokens (keepUnknown) so the server render pass can still fill them.
  function buildMergeData(contact: RecipientContact | null): Record<string, string> {
    const data: Record<string, string> = { ...SENDER_MERGE };

    const fullName = (contact?.fullName ?? props.contactName ?? "").trim();
    if (fullName) {
      const parts = fullName.split(/\s+/);
      const firstName = parts[0] ?? "";
      const lastName = parts.slice(1).join(" ");
      data["contact.name"] = fullName;
      data["contact.full_name"] = fullName;
      data["contact_name"] = fullName;
      data["contact_full_name"] = fullName;
      data["contact.firstName"] = firstName;
      data["contact.given_name"] = firstName;
      data["contact_first_name"] = firstName;
      if (lastName) {
        data["contact.family_name"] = lastName;
        data["contact_last_name"] = lastName;
        data["contact_family_name"] = lastName;
      }
    }
    if (contact?.email) {
      data["contact.email"] = contact.email;
      data["contact_email"] = contact.email;
    }
    if (contact?.title) {
      data["contact.title"] = contact.title;
      data["contact_title"] = contact.title;
    }
    if (contact?.partyName) {
      data["party.name"] = contact.partyName;
      data["party_name"] = contact.partyName;
      data["company_name"] = contact.partyName;
      data["fund_name"] = contact.partyName;
    }
    return data;
  }

  // ?? AI tab state ????????????????????????????????????????
  const [aiTone, setAiTone] = useState<"professional" | "friendly" | "concise">(
    "professional",
  );
  const [generatingAI, setGeneratingAI] = useState(false);

  // Reply scope: reply to the sender only, or reply all. Reply mode only.
  // Default is "all" (per product decision). Original recipients are fetched
  // from the source communication so the dialog stays self-contained.
  const [replyScope, setReplyScope] = useState<"sender" | "all">("all");
  const [replyRecipients, setReplyRecipients] = useState<ReplyRecipients | null>(null);

  // Reply-all mapping: original sender -> To; remaining To + Cc -> Cc, with the
  // sender removed from Cc and addresses de-duplicated case-insensitively. The
  // sending account is intentionally NOT removed (per product decision).
  function computeReplyAll(recips: ReplyRecipients): { to: string; cc: string } {
    const norm = (s: string) => s.trim().toLowerCase();
    const from = (recips.from ?? "").trim();
    const seen = new Set<string>();
    if (from) seen.add(norm(from));
    const ccList: string[] = [];
    for (const addr of [...recips.to, ...recips.cc]) {
      const a = (addr ?? "").trim();
      if (!a) continue;
      const key = norm(a);
      if (seen.has(key)) continue;
      seen.add(key);
      ccList.push(a);
    }
    return { to: from, cc: ccList.join(", ") };
  }

  function applyReplyScope(scope: "sender" | "all", recips: ReplyRecipients | null) {
    if (!recips) return;
    const from = (recips.from ?? "").trim();
    if (scope === "sender") {
      if (from) setTo(from);
      setCc("");
    } else {
      const { to: toVal, cc: ccVal } = computeReplyAll(recips);
      if (toVal) setTo(toVal);
      setCc(ccVal);
    }
  }

  function onChangeReplyScope(scope: "sender" | "all") {
    setReplyScope(scope);
    applyReplyScope(scope, replyRecipients);
  }

  // On open (reply mode), load original recipients and apply the default scope
  // so To/Cc are pre-filled for Reply all out of the box.
  useEffect(() => {
    let cancelled = false;
    if (!props.open || !isReplyMode || !effectiveOriginalCommunicationId) {
      setReplyRecipients(null);
      return;
    }
    setReplyScope("all");
    getReplyRecipients(effectiveOriginalCommunicationId).then((res) => {
      if (cancelled || !res.ok || !res.data) return;
      setReplyRecipients(res.data);
      applyReplyScope("all", res.data);
    });
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.open, effectiveOriginalCommunicationId, isReplyMode]);

  const fileInputRef = useRef<HTMLInputElement>(null);

  // ?? Template select handler ?????????????????????????????
  function handleTemplateSelect(templateId: string) {
    setSelectedTemplateId(templateId);
    if (!templateId) return;
    const t = templates.find((x) => x.id === templateId);
    if (!t) return;

    const raw = { subject: t.subject ?? "", body: t.body_plain ?? "" };
    setRawTemplate(raw);

    // Render with whatever is known client-side; unknown/missing tokens stay
    // visible and are resolved either when a contact is picked (re-render in
    // pickToContact) or server-side at send time (renderWithContext).
    const data = buildMergeData(selectedContact);
    setSubject(renderMergeFields(raw.subject, data, { keepUnknown: true }));
    setBody(renderMergeFields(raw.body, data, { keepUnknown: true }));
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
    // Step 4: multi-recipient To - validate each comma/semicolon-separated address.
    const toParts = to.split(/[,;]/).map((s) => s.trim()).filter(Boolean);
    const badAddress = toParts.find((p) => !/^\S+@\S+\.\S+$/.test(p));
    if (toParts.length === 0 || badAddress) {
      toast.error(badAddress ? `Invalid address: ${badAddress}` : "Please enter a recipient.");
      return;
    }
    // Step 4: CC is optional, but any entered address must be valid.
    const ccParts = cc.split(/[,;]/).map((s) => s.trim()).filter(Boolean);
    const badCc = ccParts.find((p) => !/^\S+@\S+\.\S+$/.test(p));
    if (badCc) {
      toast.error(`Invalid CC address: ${badCc}`);
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
      // First attempt. doSend returns a normalized result incl. whitelist info.
      let res = await doSend({ attachmentPaths, attachmentsMeta, finalMode });

      // Whitelist gate: offer to add the blocked address, then retry once.
      if (!res.ok && res.errorCode === "not_whitelisted") {
        const blocked = res.blockedRecipient || toParts[0] || "this recipient";
        const proceed = window.confirm(
          `${blocked} is not in your whitelist.\n\n` +
            `Add it to the whitelist and send? ` +
            `(Future emails from this address will also be allowed in.)`,
        );
        if (!proceed) {
          toast.error("Send cancelled.");
          return;
        }
        // Add the full address (kind='address') so only this sender is allowed,
        // not the entire domain.
        const add = await addWhitelistEntry(blocked, "address", "Added from compose");
        if (!add.ok) {
          toast.error(`Could not add to whitelist: ${add.error ?? "unknown error"}`);
          return;
        }
        toast.success(`${blocked} added to whitelist. Sending...`);
        res = await doSend({ attachmentPaths, attachmentsMeta, finalMode });
      }

      if (res.ok) {
        toast.success("Email sent.");
        props.onSent?.();
        handleOpenChange(false);
      } else {
        toast.error(res.errMsg ?? "Send failed.");
      }
    } finally {
      setSending(false);
    }
  }

  // Performs the actual send via the appropriate path and normalizes the result
  // so handleSend can react to the whitelist gate uniformly.
  async function doSend(args: {
    attachmentPaths: string[];
    attachmentsMeta: UploadedAttachment[];
    finalMode: ComposeMode;
  }): Promise<{
    ok: boolean;
    errMsg?: string;
    errorCode?: "not_whitelisted" | "database" | "send_failed" | string;
    blockedRecipient?: string;
  }> {
    const toParts = to.split(/[,;]/).map((s) => s.trim()).filter(Boolean);
    const ccParts = cc.split(/[,;]/).map((s) => s.trim()).filter(Boolean);

    if (props.partyId) {
      // Party-linked: full path (merge fields + template + signature).
      const payload: ComposePayload = {
        mode: args.finalMode,
        partyId: props.partyId,
        contactId: selectedContactId ?? props.contactId ?? null,
        dealId: dealId !== NO_DEAL ? dealId : null,
        to: toParts.join(","),
        subject: subject.trim(),
        body,
        cc: ccParts.length > 0 ? ccParts.join(",") : undefined,
        templateId:
          activeTab === "template" && selectedTemplateId
            ? selectedTemplateId
            : props.templateId,
        replyToMessageId: props.replyToMessageId,
        threadId: props.threadId,
        attachmentPaths: args.attachmentPaths,
        attachments: args.attachmentsMeta,
        useSignature,
        fromKind,
        mailAccountId: fromAccountId,
        aiGenerated: activeTab === "ai",
      };
      const result = await sendEmail(payload);
      return {
        ok: result.success,
        errMsg: result.error,
        errorCode: result.errorCode,
        blockedRecipient: result.blockedRecipient,
      };
    }

    // No registered party (e.g. reply to an unknown sender). Use the proven
    // manual outbound path, which supports a null party.
    const result = await sendOutboundManual({
      fromKind,
      mailAccountId: fromAccountId,
      to: toParts.join(","),
      cc: ccParts.length > 0 ? ccParts.join(",") : undefined,
      subject: subject.trim(),
      bodyPlain: body,
      partyId: null,
      contactId: selectedContactId ?? props.contactId ?? null,
      dealId: dealId !== NO_DEAL ? dealId : null,
      inReplyTo: props.replyToMessageId ?? null,
      threadId: props.threadId ?? null,
      attachments: args.attachmentsMeta,
      useSignature,
      aiGenerated: activeTab === "ai",
    });
    if (result.ok) return { ok: true };
    // sendOutboundManual does not echo the blocked address; fall back to To[0].
    return {
      ok: false,
      errMsg: result.errorMessage ?? undefined,
      errorCode: result.errorCode,
      blockedRecipient: toParts[0],
    };
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

        {/* Step 4: From account selector (DB accounts; legacy kind fallback when empty) */}
        <div className="space-y-1">
          <Label htmlFor="fromKind">From</Label>
          {mailAccounts.length > 0 ? (
            <Select
              value={fromAccountId ?? undefined}
              onValueChange={(v) => setFromAccountId(v)}
            >
              <SelectTrigger id="fromKind">
                <SelectValue placeholder="Select sender account" />
              </SelectTrigger>
              <SelectContent>
                {mailAccounts.map((a) => (
                  <SelectItem key={a.id} value={a.id}>
                    {a.displayName ? `${a.displayName} <${a.address}>` : a.address}
                    {a.isDefault ? " (default)" : ""}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          ) : (
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
          )}
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
                Tokens like <code>{"{{contact_first_name}}"}</code> and <code>{"{{company_name}}"}</code> are filled when you pick a template and a recipient; anything left is filled at send time.
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

          {/* Reply scope: reply to sender only vs reply all */}
          {isReplyMode && (
            <div className="space-y-1">
              <Label>Reply to</Label>
              <div className="inline-flex rounded-md border p-0.5 text-sm">
                <button
                  type="button"
                  onClick={() => onChangeReplyScope("sender")}
                  className={`rounded px-3 py-1 transition-colors ${
                    replyScope === "sender"
                      ? "bg-primary text-primary-foreground"
                      : "text-muted-foreground hover:text-foreground"
                  }`}
                >
                  Sender only
                </button>
                <button
                  type="button"
                  onClick={() => onChangeReplyScope("all")}
                  className={`rounded px-3 py-1 transition-colors ${
                    replyScope === "all"
                      ? "bg-primary text-primary-foreground"
                      : "text-muted-foreground hover:text-foreground"
                  }`}
                >
                  Reply all
                </button>
              </div>
              {replyScope === "all" &&
                replyRecipients &&
                replyRecipients.to.length + replyRecipients.cc.length === 0 && (
                  <p className="text-xs text-muted-foreground">
                    No other recipients on the original message.
                  </p>
                )}
            </div>
          )}

          {/* Common: To (with contact type-ahead) */}
          <div className="space-y-1">
            <Label htmlFor="to">To</Label>
            <div className="relative">
              <Input
                id="to"
                value={to}
                onChange={(e) => onToChange(e.target.value)}
                onFocus={() => toResults.length > 0 && setToOpen(true)}
                onBlur={() => setTimeout(() => setToOpen(false), 150)}
                placeholder="Search contacts or type emails (comma-separated)"
                type="text"
                autoComplete="off"
              />
              {toSearching && (
                <Loader2 className="absolute right-2 top-2.5 h-4 w-4 animate-spin text-muted-foreground" />
              )}
              {toOpen && toResults.length > 0 && (
                <div className="absolute z-30 left-0 right-0 top-full mt-1 max-h-56 overflow-y-auto rounded-md border bg-popover shadow-md">
                  {toResults.map((c) => (
                    <button
                      key={c.contactId}
                      type="button"
                      className="flex w-full flex-col px-3 py-1.5 text-left text-sm hover:bg-accent"
                      onMouseDown={(ev) => {
                        ev.preventDefault();
                        pickToContact(c);
                      }}
                    >
                      <span className="font-medium">
                        {c.fullName}
                        {c.title ? (
                          <span className="font-normal text-muted-foreground"> &middot; {c.title}</span>
                        ) : null}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        {c.email}
                        {c.partyName ? ` \u00b7 ${c.partyName}` : ''}
                      </span>
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Common: CC (optional, comma-separated; not whitelist-checked) */}
          <div className="space-y-1">
            <Label htmlFor="cc">Cc</Label>
            <Input
              id="cc"
              value={cc}
              onChange={(e) => setCc(e.target.value)}
              placeholder="Cc (optional, comma-separated)"
              type="text"
              autoComplete="off"
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