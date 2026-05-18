// src/components/parties/party-communications-timeline.tsx
// Party Communications Timeline (forum-style threaded view)
// English-only UI, ASCII-clean source
"use client";

import { useState } from "react";
import {
  Mail,
  ArrowUpRight,
  ArrowDownLeft,
  Eye,
  MousePointerClick,
  CornerDownRight,
  Star,
  Sparkles,
  CheckCircle2,
  Clock,
  XCircle,
  MessageSquarePlus,
  ChevronDown,
  ChevronRight,
  FileText,
} from "lucide-react";
import { ComposeEmailDialog } from "@/components/email/compose-email-dialog";
import type {
  CommunicationTimelineItem,
  PartyCommunicationStats,
  TemplateForCompose,
} from "@/types/phase22a";

interface PartyCommunicationsTimelineProps {
  partyId: string;
  partyName: string;
  defaultContactEmail: string | null;
  defaultContactId: string | null;
  defaultContactName: string | null;
  items: CommunicationTimelineItem[];
  stats: PartyCommunicationStats;
  templates: TemplateForCompose[];
  orgId: string;
}

export function PartyCommunicationsTimeline(
  props: PartyCommunicationsTimelineProps,
) {
  const {
    partyId,
    defaultContactEmail,
    defaultContactId,
    defaultContactName,
    items,
    stats,
    templates,
    orgId,
  } = props;

  const [composeOpen, setComposeOpen] = useState(false);
  const [replyContext, setReplyContext] = useState<{
    messageId: string;
    communicationId: string;
    subject: string;
    contactEmail: string;
    contactId: string | null;
    contactName: string | null;
  } | null>(null);

  // Group items by thread
  const threads = new Map<string, CommunicationTimelineItem[]>();
  for (const item of items) {
    const key = item.thread_id || item.message_id || item.id;
    const list = threads.get(key) || [];
    list.push(item);
    threads.set(key, list);
  }
  for (const [k, arr] of threads) {
    arr.sort((a, b) => a.occurred_at.localeCompare(b.occurred_at));
    threads.set(k, arr);
  }
  const sortedThreads = Array.from(threads.entries()).sort(
    ([, a], [, b]) => {
      const aLatest = a[a.length - 1]?.occurred_at || "";
      const bLatest = b[b.length - 1]?.occurred_at || "";
      return bLatest.localeCompare(aLatest);
    },
  );

  const handleNewCompose = () => {
    setReplyContext(null);
    setComposeOpen(true);
  };

  const handleReply = (item: CommunicationTimelineItem) => {
    if (!item.message_id) return;
    setReplyContext({
      messageId: item.message_id,
      communicationId: item.id,
      subject: item.subject?.startsWith("Re:")
        ? item.subject
        : `Re: ${item.subject || ""}`,
      contactEmail:
        item.contact_email ||
        item.from_address ||
        defaultContactEmail ||
        "",
      contactId: item.contact_id || defaultContactId,
      contactName: item.contact_name || defaultContactName,
    });
    setComposeOpen(true);
  };

  return (
    <div className="bg-white rounded-lg border shadow-sm">
      {/* Header */}
      <div className="px-6 py-4 border-b">
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-lg font-semibold flex items-center gap-2">
            <Mail className="w-5 h-5" />
            Communications
          </h3>
          <button
            onClick={handleNewCompose}
            
            className="inline-flex items-center gap-1 px-3 py-1.5 bg-blue-600 text-white rounded-md text-sm hover:bg-blue-700 disabled:opacity-50"
          >
            <MessageSquarePlus className="w-4 h-4" />
            New Email
          </button>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-6 gap-2 text-center">
          <StatBox label="Total" value={stats.total} />
          <StatBox label="Sent" value={stats.sent} accent="blue" />
          <StatBox label="Received" value={stats.received} accent="green" />
          <StatBox label="Opened" value={stats.opened} accent="purple" />
          <StatBox label="Replied" value={stats.replied} accent="emerald" />
          <StatBox label="Threads" value={stats.threads} />
        </div>
      </div>

      {/* Timeline */}
      <div className="divide-y">
        {sortedThreads.length === 0 ? (
          <div className="px-6 py-12 text-center text-gray-500 text-sm">
            No emails yet. Click &quot;New Email&quot; above to start a conversation.
          </div>
        ) : (
          sortedThreads.map(([threadKey, threadItems]) => (
            <ThreadGroup
              key={threadKey}
              items={threadItems}
              onReply={handleReply}
            />
          ))
        )}
      </div>

      {/* Compose Dialog */}
      <ComposeEmailDialog
        open={composeOpen}
        onOpenChange={setComposeOpen}
        partyId={partyId}
        mode={replyContext ? "reply" : "new"}
        contactId={replyContext?.contactId ?? defaultContactId}
        contactName={replyContext?.contactName ?? defaultContactName}
        defaultTo={replyContext?.contactEmail || defaultContactEmail || ""}
        replyToMessageId={replyContext?.messageId}
        originalCommunicationId={replyContext?.communicationId}
        defaultSubject={replyContext?.subject}
        templates={templates}
        orgId={orgId}
      />
    </div>
  );
}

// ?????????????????? Sub: Stat box ??????????????????
function StatBox({
  label,
  value,
  accent,
}: {
  label: string;
  value: number;
  accent?: "blue" | "green" | "purple" | "emerald";
}) {
  const colors: Record<string, string> = {
    blue: "text-blue-600",
    green: "text-green-600",
    purple: "text-purple-600",
    emerald: "text-emerald-600",
  };
  const valueClass = accent ? colors[accent] : "text-gray-900";
  return (
    <div className="border rounded p-2 bg-gray-50">
      <div className={`text-lg font-semibold ${valueClass}`}>{value}</div>
      <div className="text-xs text-gray-500">{label}</div>
    </div>
  );
}

// ?????????????????? Sub: Thread group (collapsible) ??????????????????
function ThreadGroup({
  items,
  onReply,
}: {
  items: CommunicationTimelineItem[];
  onReply: (item: CommunicationTimelineItem) => void;
}) {
  const [expanded, setExpanded] = useState(items.length <= 3);
  const latest = items[items.length - 1];
  const firstItem = items[0];

  if (items.length === 1) {
    return (
      <div className="px-6 py-3">
        <MessageRow item={items[0]} onReply={onReply} />
      </div>
    );
  }

  return (
    <div className="px-6 py-3">
      {/* Thread header */}
      <button
        onClick={() => setExpanded(!expanded)}
        className="w-full flex items-center gap-2 mb-2 text-left hover:bg-gray-50 -mx-2 px-2 py-1 rounded"
      >
        {expanded ? (
          <ChevronDown className="w-4 h-4 text-gray-500" />
        ) : (
          <ChevronRight className="w-4 h-4 text-gray-500" />
        )}
        <div className="flex-1">
          <div className="font-medium text-sm">
            {firstItem.subject || "(no subject)"}
          </div>
          <div className="text-xs text-gray-500">
            {items.length} messages &middot; last activity{" "}
            {formatDate(latest.occurred_at)}
          </div>
        </div>
        <DirectionIcon direction={latest.direction} />
      </button>

      {/* Thread items */}
      {expanded && (
        <div className="ml-6 space-y-3 border-l-2 border-gray-100 pl-4">
          {items.map((item) => (
            <MessageRow
              key={item.id}
              item={item}
              onReply={onReply}
              compact={true}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// ?????????????????? Sub: Message row ??????????????????
function MessageRow({
  item,
  onReply,
  compact = false,
}: {
  item: CommunicationTimelineItem;
  onReply: (item: CommunicationTimelineItem) => void;
  compact?: boolean;
}) {
  const [expanded, setExpanded] = useState(false);
  const isOutbound = item.direction === "outbound";

  return (
    <div className="border rounded-md p-3 hover:bg-gray-50 transition">
      <div className="flex items-start gap-3">
        {/* Direction icon */}
        <div className="flex-shrink-0 mt-1">
          <DirectionIcon direction={item.direction} />
        </div>

        {/* Content */}
        <div className="flex-1 min-w-0">
          {/* Subject + status */}
          <div className="flex items-start justify-between gap-2 mb-1">
            <div className="flex-1 min-w-0">
              {!compact && (
                <div className="font-medium text-sm truncate">
                  {item.subject || "(no subject)"}
                </div>
              )}
              <div className="text-xs text-gray-600 flex flex-wrap items-center gap-2 mt-0.5">
                <span>
                  {isOutbound ? "->" : "<-"}{" "}
                  {item.contact_name ||
                    item.contact_email ||
                    (item.to_addresses || [])[0] ||
                    item.from_address ||
                    "Unknown"}
                </span>
                <span className="text-gray-400">&middot;</span>
                <span suppressHydrationWarning>
                  {formatDate(item.occurred_at)}
                </span>
                {item.ai_generated && (
                  <span className="inline-flex items-center gap-0.5 text-purple-600">
                    <Sparkles className="w-3 h-3" />
                    AI
                  </span>
                )}
                {item.template_id && (
                  <span className="inline-flex items-center gap-0.5 text-blue-600">
                    <FileText className="w-3 h-3" />
                    Template
                  </span>
                )}
              </div>
            </div>
            <div className="flex items-center gap-1 flex-shrink-0">
              <StatusBadges item={item} />
            </div>
          </div>

          {/* Body preview / expand */}
          {item.body_summary && !expanded && (
            <p className="text-sm text-gray-700 line-clamp-2 mt-1">
              {item.body_summary}
            </p>
          )}
          {expanded && (
            <div className="mt-2 p-3 bg-white border rounded text-sm">
              {item.body_html ? (
                <div
                  className="prose prose-sm max-w-none"
                  dangerouslySetInnerHTML={{ __html: item.body_html }}
                />
              ) : (
                <pre className="whitespace-pre-wrap font-sans">
                  {item.body_plain || "(no body)"}
                </pre>
              )}
            </div>
          )}

          {/* AI Classification (for inbound) */}
          {!isOutbound && item.ai_classification && (
            <AIClassificationBadge classification={item.ai_classification} />
          )}

          {/* Actions */}
          <div className="flex items-center gap-2 mt-2">
            <button
              onClick={() => setExpanded(!expanded)}
              className="text-xs text-gray-500 hover:text-gray-700"
            >
              {expanded ? "Collapse" : "Show body"}
            </button>
            {item.message_id && (
              <button
                onClick={() => onReply(item)}
                className="text-xs text-blue-600 hover:text-blue-700 inline-flex items-center gap-0.5"
              >
                <CornerDownRight className="w-3 h-3" />
                Reply
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

// ?????????????????? Direction icon ??????????????????
function DirectionIcon({ direction }: { direction: string }) {
  if (direction === "outbound") {
    return (
      <ArrowUpRight
        className="w-5 h-5 text-blue-500"
        aria-label="Outbound"
      />
    );
  }
  return (
    <ArrowDownLeft
      className="w-5 h-5 text-green-500"
      aria-label="Inbound"
    />
  );
}

// ?????????????????? Status badges ??????????????????
function StatusBadges({ item }: { item: CommunicationTimelineItem }) {
  const badges: Array<{
    icon: typeof Eye;
    label: string;
    color: string;
    title: string;
  }> = [];

  if (item.is_starred) {
    badges.push({
      icon: Star,
      label: "",
      color: "text-yellow-500",
      title: "Starred",
    });
  }

  if (item.direction === "outbound") {
    if (item.status === "failed" || item.status === "bounced") {
      badges.push({
        icon: XCircle,
        label: "Failed",
        color: "text-red-500",
        title: item.status,
      });
    } else if (item.sent_at) {
      badges.push({
        icon: CheckCircle2,
        label: "Sent",
        color: "text-blue-500",
        title: `Sent ${formatDate(item.sent_at)}`,
      });
    } else if (item.status === "draft") {
      badges.push({
        icon: Clock,
        label: "Draft",
        color: "text-gray-400",
        title: "Draft",
      });
    }

    if (item.opened_at) {
      badges.push({
        icon: Eye,
        label: "Opened",
        color: "text-purple-500",
        title: `Opened ${formatDate(item.opened_at)}`,
      });
    }
    if (item.clicked_at) {
      badges.push({
        icon: MousePointerClick,
        label: "Clicked",
        color: "text-emerald-500",
        title: `Clicked ${formatDate(item.clicked_at)}`,
      });
    }
    if (item.replied_at) {
      badges.push({
        icon: CornerDownRight,
        label: "Got reply",
        color: "text-green-600",
        title: `Reply ${formatDate(item.replied_at)}`,
      });
    }
  }

  return (
    <div className="flex items-center gap-1">
      {badges.map((b, i) => {
        const Icon = b.icon;
        return (
          <span
            key={i}
            title={b.title}
            className={`inline-flex items-center gap-0.5 text-xs ${b.color}`}
          >
            <Icon className="w-3.5 h-3.5" />
            {b.label && <span className="hidden lg:inline">{b.label}</span>}
          </span>
        );
      })}
    </div>
  );
}

// ?????????????????? AI Classification badge ??????????????????
function AIClassificationBadge({
  classification,
}: {
  classification: import("@/types/phase22a").AIClassification;
}) {
  const intent = classification.intent;
  if (!intent || intent === "unknown") return null;

  const intentMeta: Record<
    string,
    { label: string; color: string; bg: string }
  > = {
    interested: {
      label: "Interested",
      color: "text-green-700",
      bg: "bg-green-50",
    },
    not_now: {
      label: "Not now",
      color: "text-yellow-700",
      bg: "bg-yellow-50",
    },
    objection: {
      label: "Objection",
      color: "text-orange-700",
      bg: "bg-orange-50",
    },
    unsubscribe: {
      label: "Unsubscribe",
      color: "text-red-700",
      bg: "bg-red-50",
    },
    wrong_person: {
      label: "Wrong recipient",
      color: "text-gray-700",
      bg: "bg-gray-100",
    },
    question: {
      label: "Question",
      color: "text-blue-700",
      bg: "bg-blue-50",
    },
    auto_reply: {
      label: "Auto-reply",
      color: "text-gray-600",
      bg: "bg-gray-100",
    },
  };

  const meta = intentMeta[intent] || intentMeta.question;

  return (
    <div className="mt-2 flex flex-wrap items-center gap-2">
      <span
        className={`inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded ${meta.bg} ${meta.color}`}
      >
        <Sparkles className="w-3 h-3" />
        AI: {meta.label}
        {typeof classification.confidence === "number" && (
          <span className="opacity-60">
            ({Math.round(classification.confidence * 100)}%)
          </span>
        )}
      </span>
      {classification.summary && (
        <span className="text-xs text-gray-600 italic truncate max-w-md">
          {classification.summary}
        </span>
      )}
      {classification.suggested_action && (
        <span className="text-xs text-purple-700 bg-purple-50 px-2 py-0.5 rounded">
          Tip: {classification.suggested_action}
        </span>
      )}
    </div>
  );
}

// ?????????????????? Helpers ??????????????????
function formatDate(iso: string | null): string {
  if (!iso) return "";
  const d = new Date(iso);
  const now = Date.now();
  const diff = now - d.getTime();
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);

  if (hours < 1) {
    const mins = Math.floor(diff / 60000);
    return `${mins} min ago`;
  }
  if (hours < 24) return `${hours}h ago`;
  if (days < 7) return `${days}d ago`;
  return d.toLocaleDateString("en-US", {
    year: "2-digit",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}