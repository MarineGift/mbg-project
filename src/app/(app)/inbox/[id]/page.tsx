// src/app/(app)/inbox/[id]/page.tsx
// Phase 22b: Inbox 상세 페이지 - fetchCommunicationDetail 적용
// "Message not found" 에러 수정
"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { ArrowLeft, Reply, Forward, Paperclip, Calendar } from "lucide-react";
import { ComposeEmailDialog } from "@/components/email/compose-email-dialog";
import { format } from "date-fns";
import { ko } from "date-fns/locale";

// fetchCommunicationDetail 반환 타입 (communications.ts에 맞게 조정)
interface CommunicationDetail {
  id: string;
  party_id: string;
  contact_id: string | null;
  direction: "inbound" | "outbound";
  channel: string;
  subject: string | null;
  body_html: string | null;
  body_text: string | null;
  from_address: string | null;
  to_address: string | null;
  message_id: string | null;
  thread_id: string | null;
  in_reply_to: string | null;
  attachment_paths: string[];
  status: string;
  sent_at: string | null;
  received_at: string | null;
  created_at: string;
  // joined
  party?: { id: string; name: string };
  contact?: { id: string; given_name: string; family_name: string } | null;
}

export default function InboxDetailPage() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;

  const [comm, setComm] = useState<CommunicationDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [replyOpen, setReplyOpen] = useState(false);

  useEffect(() => {
    if (!id) return;
    load();
  }, [id]);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`/api/communications/${id}`, { cache: "no-store" });
      if (!res.ok) {
        if (res.status === 404) {
          setError("Message not found");
          setLoading(false);
          return;
        }
        throw new Error(`HTTP ${res.status}`);
      }
      const json = await res.json();
      const result = json.data;
      if (!result) {
        setError("메시지를 찾을 수 없습니다.");
      } else {
        setComm(result as CommunicationDetail);
      }
    } catch (e: any) {
      setError(e.message ?? "조회 오류");
    } finally {
      setLoading(false);
    }
  }

  // ── Loading
  if (loading) {
    return (
      <div className="p-6 space-y-4 max-w-4xl mx-auto">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-4 w-full" />
        <Skeleton className="h-4 w-3/4" />
        <Skeleton className="h-64 w-full" />
      </div>
    );
  }

  // ── Error
  if (error || !comm) {
    return (
      <div className="p-6 max-w-4xl mx-auto">
        <Button variant="ghost" size="sm" onClick={() => router.back()} className="mb-4">
          <ArrowLeft className="h-4 w-4 mr-1" />
          뒤로
        </Button>
        <div className="rounded-lg border border-destructive/30 bg-destructive/5 p-6 text-center">
          <p className="text-sm text-destructive font-medium">{error ?? "메시지를 찾을 수 없습니다."}</p>
          <Button variant="outline" size="sm" className="mt-3" onClick={load}>
            다시 시도
          </Button>
        </div>
      </div>
    );
  }

  const timestamp = comm.received_at ?? comm.sent_at ?? comm.created_at;
  const hasAttachments = comm.attachment_paths?.length > 0;

  return (
    <div className="p-6 max-w-4xl mx-auto space-y-4">
      {/* 상단 네비 */}
      <div className="flex items-center justify-between">
        <Button variant="ghost" size="sm" onClick={() => router.back()}>
          <ArrowLeft className="h-4 w-4 mr-1" />
          받은편지함
        </Button>
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setReplyOpen(true)}
            disabled={!comm.from_address}
          >
            <Reply className="h-4 w-4 mr-1" />
            답장
          </Button>
        </div>
      </div>

      {/* 메시지 헤더 카드 */}
      <div className="rounded-lg border bg-card p-5 space-y-3">
        {/* 제목 */}
        <h1 className="text-xl font-semibold">
          {comm.subject ?? "(제목 없음)"}
        </h1>

        {/* 메타 정보 */}
        <div className="flex flex-wrap gap-x-6 gap-y-1 text-sm text-muted-foreground">
          <span>
            <span className="font-medium text-foreground">발신: </span>
            {comm.from_address ?? "—"}
          </span>
          <span>
            <span className="font-medium text-foreground">수신: </span>
            {comm.to_address ?? "—"}
          </span>
          {timestamp && (
            <span className="flex items-center gap-1">
              <Calendar className="h-3 w-3" />
              {format(new Date(timestamp), "yyyy.MM.dd HH:mm", { locale: ko })}
            </span>
          )}
        </div>

        {/* 배지 */}
        <div className="flex gap-2">
          <Badge variant={comm.direction === "inbound" ? "secondary" : "outline"}>
            {comm.direction === "inbound" ? "수신" : "발신"}
          </Badge>
          {comm.status && (
            <Badge variant="outline" className="capitalize">
              {comm.status}
            </Badge>
          )}
          {comm.party && (
            <Badge variant="outline">
              {comm.party.name}
            </Badge>
          )}
          {hasAttachments && (
            <Badge variant="outline" className="gap-1">
              <Paperclip className="h-3 w-3" />
              {comm.attachment_paths.length}개 첨부
            </Badge>
          )}
        </div>
      </div>

      {/* 첨부파일 목록 */}
      {hasAttachments && (
        <div className="rounded-lg border p-4">
          <p className="text-sm font-medium mb-2">첨부파일</p>
          <div className="space-y-1">
            {comm.attachment_paths.map((path, i) => (
              <div key={i} className="flex items-center gap-2 text-sm">
                <Paperclip className="h-3 w-3 text-muted-foreground" />
                <span className="text-muted-foreground">{path.split("/").pop()}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* 본문 */}
      <div className="rounded-lg border bg-card p-5">
        {comm.body_html ? (
          <div
            className="prose prose-sm max-w-none dark:prose-invert"
            dangerouslySetInnerHTML={{ __html: comm.body_html }}
          />
        ) : comm.body_text ? (
          <pre className="whitespace-pre-wrap text-sm font-sans">{comm.body_text}</pre>
        ) : (
          <p className="text-sm text-muted-foreground italic">본문 없음</p>
        )}
      </div>

      {/* 답장 Dialog */}
      {replyOpen && comm.from_address && (
        <ComposeEmailDialog
          open={replyOpen}
          onOpenChange={setReplyOpen}
          partyId={comm.party_id}
          contactId={comm.contact_id}
          mode="reply"
          defaultTo={comm.from_address}
          defaultSubject={
            comm.subject?.startsWith("Re:") ? comm.subject : `Re: ${comm.subject ?? ""}`
          }
          replyToMessageId={comm.message_id ?? undefined}
          threadId={comm.thread_id ?? undefined}
          originalCommunicationId={comm.id}
        />
      )}
    </div>
  );
}
