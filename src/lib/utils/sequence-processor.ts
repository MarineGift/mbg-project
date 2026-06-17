// src/lib/utils/sequence-processor.ts
// ============================================================
// Sequence processor.
//
// Sending is delegated to sendOutboundEmail() - the same path the reply /
// compose dialog and the bulk-mail sender use. The From account is chosen
// per sequence via app.email_sequences.from_account_id (an
// app.inbound_mailboxes id, i.e. the exact accounts the compose From dropdown
// lists). null -> the org default account. sendOutboundEmail handles account
// resolution, SMTP password decryption, per-account transport, signature,
// open-tracking and the communications row, so this file no longer builds its
// own transport or writes communications directly.
// ============================================================
import { createSupabaseAdminClient } from "@/lib/supabase/admin";
import { rpc } from "@/lib/rpc/typed-rpc";
import { renderMergeFields } from "@/lib/utils/merge-fields";
import { sendOutboundEmail } from "@/lib/email/send-outbound";

interface DueEnrollment {
  enrollment_id: string;
  organization_id: string;
  party_id: string;
  contact_id: string | null;
  sequence_id: string;
  step_id: string;
  step_order: number;
  step_subject: string;
  step_body: string;
  step_body_html: string | null;
  step_template_id: string | null;
  contact_email: string | null;
  contact_given_name: string | null;
  contact_family_name: string | null;
  party_name: string;
}

export async function processSequence(): Promise<{
  processed: number;
  sent: number;
  failed: number;
  skipped: number;
}> {
  const supabase = createSupabaseAdminClient();

  // Get due enrollments
  const { data: due, error: dueErr } = await rpc(supabase, "get_due_enrollments", {} as never);
  if (dueErr || !due) {
    console.error("[processSequence] get_due_enrollments error", dueErr);
    return { processed: 0, sent: 0, failed: 0, skipped: 0 };
  }

  const enrollments = (due as unknown as DueEnrollment[]) || [];
  let sent = 0,
    failed = 0,
    skipped = 0;
  const errors: Array<{ enrollment_id: string; error: string }> = [];

  // Per-sequence From account (app.inbound_mailboxes id). Fetched once per
  // distinct sequence so the live get_due_enrollments RPC does not change.
  // null -> sendOutboundEmail routes to the org default account.
  const seqAccountMap = new Map<string, string | null>();
  const distinctSeqIds = [...new Set(enrollments.map((e) => e.sequence_id))];
  if (distinctSeqIds.length > 0) {
    const { data: seqRows, error: seqErr } = await (
      supabase.schema("app").from("email_sequences") as unknown as {
        select: (cols: string) => {
          in: (
            col: string,
            vals: string[],
          ) => Promise<{ data: unknown; error: { message: string } | null }>;
        };
      }
    )
      .select("id, from_account_id")
      .in("id", distinctSeqIds);
    if (seqErr) {
      console.error("[processSequence] from_account_id lookup error", seqErr);
    }
    for (const row of (seqRows ?? []) as Array<{ id: string; from_account_id: string | null }>) {
      seqAccountMap.set(row.id, row.from_account_id ?? null);
    }
  }

  // Legacy fallback identity (only used when the org has no smtp-ready DB
  // accounts; sendOutboundEmail then falls back to the env TABS_MAILER path).
  const fallbackFromAddress = process.env.TABS_MAILER_USERNAME || "";
  const fallbackFromName = process.env.TABS_MAILER_FROM_NAME || "URM";
  const isMock = process.env.TABS_MAILER_USE_MOCK === "true";

  for (const e of enrollments) {
    try {
      if (!e.contact_email) {
        await (rpc as any)(supabase, "advance_enrollment", {
          p_enrollment_id: e.enrollment_id,
          p_status: "skipped",
        });
        skipped++;
        continue;
      }

      // Render merge fields
      const ctx = {
        contact: {
          given_name: e.contact_given_name || "",
          family_name: e.contact_family_name || "",
          email: e.contact_email,
        },
        party: { name: e.party_name },
      };
      const subject = unwrapMerge(renderMergeFields(e.step_subject || "", ctx as never));
      const bodyPlain = unwrapMerge(renderMergeFields(e.step_body || "", ctx as never));
      const bodyHtml = e.step_body_html
        ? unwrapMerge(renderMergeFields(e.step_body_html, ctx as never))
        : plainToHtml(bodyPlain);

      if (isMock) {
        console.log(`[MOCK SEND] ${e.contact_email} - ${subject}`);
        await (rpc as any)(supabase, "advance_enrollment", {
          p_enrollment_id: e.enrollment_id,
          p_status: "sent",
        });
        sent++;
        continue;
      }

      // Delegate to the shared outbound path. mailAccountId picks the From
      // account (same accounts as the compose dropdown); skipWhitelist because
      // a sequence is intentional outbound, not a reply-guarded send.
      const result = await sendOutboundEmail({
        supabase,
        organizationId: e.organization_id,
        to: e.contact_email,
        fromName: fallbackFromName,
        fromAddress: fallbackFromAddress,
        mailAccountId: seqAccountMap.get(e.sequence_id) ?? null,
        subject,
        bodyHtml,
        bodyText: bodyPlain,
        partyId: e.party_id,
        contactId: e.contact_id,
        useSignature: true,
        skipWhitelist: true,
        aiGenerated: false,
        externalData: {
          source: "sequence",
          sequence_id: e.sequence_id,
          step_id: e.step_id,
          enrollment_id: e.enrollment_id,
          step_order: e.step_order,
        },
        traceLabel: "sequence",
      });

      if (result.ok && result.communicationId) {
        await supabase
          .schema("app")
          .from("email_sequence_sends")
          .insert({
            enrollment_id: e.enrollment_id,
            step_id: e.step_id,
            communication_id: result.communicationId,
            sent_at: new Date().toISOString(),
            status: "sent",
          } as never);

        await (rpc as any)(supabase, "advance_enrollment", {
          p_enrollment_id: e.enrollment_id,
          p_status: "sent",
        });
        sent++;
      } else {
        const msg = result.errorMessage ?? `send ${result.status}`;
        console.error("[processSequence] send failed", e.enrollment_id, result.status, msg);
        errors.push({ enrollment_id: e.enrollment_id, error: `${result.status}: ${msg}` });
        await (rpc as any)(supabase, "advance_enrollment", {
          p_enrollment_id: e.enrollment_id,
          p_status: "failed",
        });
        failed++;
      }
    } catch (err) {
      const emsg = err instanceof Error ? `${err.message}` : String(err);
      console.error("[processSequence] unhandled error for enrollment", e.enrollment_id, err);
      errors.push({ enrollment_id: e.enrollment_id, error: emsg });
      failed++;
    }
  }

  return { processed: enrollments.length, sent, failed, skipped, errors };
}

// ============================================================
// Helpers
// ============================================================
function unwrapMerge(result: unknown): string {
  if (typeof result === "string") return result;
  if (
    result &&
    typeof result === "object" &&
    "rendered" in result &&
    typeof (result as { rendered: unknown }).rendered === "string"
  ) {
    return (result as { rendered: string }).rendered;
  }
  return "";
}

function plainToHtml(plain: string): string {
  if (!plain) return "";
  const escaped = plain
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
  return escaped
    .split(/\n\n+/)
    .map((p) => `<p>${p.replace(/\n/g, "<br/>")}</p>`)
    .join("\n");
}
